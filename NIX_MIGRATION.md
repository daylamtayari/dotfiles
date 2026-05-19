# Nix Home Manager Migration

Reference document and status tracker for migrating this repository from
**chezmoi** to a **Nix flake + Home Manager** (with **nix-darwin** for macOS).

> This file is the canonical plan. A fresh agent picking up the migration
> should read this top-to-bottom, then check the **Status** section at the
> bottom for the next unfinished phase.

---

## Goal

Replace chezmoi as the dotfile *and* package manager with a single Nix flake so that:

- The same package set and dotfiles are reproducible across every machine.
- Package management no longer depends on Arch (`pacman`/AUR) or Homebrew.
- Per-host differences (OS glue, per-machine toolchains) are declarative.

## Decisions (locked in)

- **Engine:** Nix flake + Home Manager. macOS hosts additionally use nix-darwin
  for OS-level settings and the Homebrew-cask bridge.
- **Flakes**, not channels — a committed `flake.lock` is what makes "same
  packages everywhere" actually hold.
- **Track `nixpkgs-unstable`** (home-manager `master`), not a stable release
  branch. `flake.lock` still pins an exact commit for reproducibility;
  `nix flake update` rolls it forward.
- **Standalone Home Manager** on Linux (Arch / Qubes); **nix-darwin-managed
  Home Manager** on macOS.
- **Refactor as we migrate:** use HM-native modules (`programs.zsh`,
  `programs.git`, `programs.kitty`, `programs.ranger`) where they cover the
  need. Neovim stays a **source-symlinked tree** — lazy.nvim does not translate
  cleanly to Nix and translating it is explicitly out of scope.
- **Identical base config** on every host; per-host files are thin overlays.
- **Per-host toolchains via feature flags** under the `my.*` option namespace
  (options + `lib.mkIf`), not bare profile imports.
- Migration is done **in place** in this repo (`~/.local/share/chezmoi`) on the
  `nix` branch. chezmoi continuity on un-migrated hosts is **not** maintained —
  git history (`pre-nix-snapshot`, see below) is the rollback path.
- **Unfree packages are allowed** system-wide (`config.allowUnfree = true` in
  `flake.nix`) — required for terraform (BUSL-licensed).

## Host matrix

| Flake name | Machine | Manager | Notes |
|---|---|---|---|
| `dev` | Qubes VM running Arch | standalone HM | **Pilot host.** Qubes GPG glue. |
| `cyber` | Qubes VM running Arch | standalone HM | Qubes GPG glue; `security` profile. |
| `work` | work macOS | nix-darwin + HM | `dev` + `security` profiles; GUI apps via Homebrew. |

Flake names are arbitrary labels for `home-manager switch --flake .#<name>`;
they do **not** need to match the system `hostname`.

## Nix on Qubes

A Qubes AppVM's root filesystem (`/`) is **volatile** — derived from the
template and reset on every shutdown; only `/home`, `/usr/local`, and `/rw`
persist. This affects more than `/nix`:

- `/nix` (the store) is on the volatile root.
- A **multi-user (daemon) install** also writes the `nix-daemon` systemd unit,
  the `nixbld` build users (`/etc/passwd`, `/etc/group`), and `/etc/profile.d`
  snippets — all on the volatile root. Persisting `/nix` alone is **not enough**
  for daemon mode.

**Decision:** install Nix **single-user** (`--no-daemon`) **per AppVM**. A
single-user install confines everything to `/nix` + `$HOME` — no daemon, no
`/etc` build users — so only `/nix` needs persisting (`$HOME` already does).

Per-AppVM setup:

1. `sudo mkdir -p /rw/config/qubes-bind-dirs.d`
2. `echo "binddirs+=( /nix )" | sudo tee /rw/config/qubes-bind-dirs.d/50_nix.conf`
3. Reboot the VM — activates the bind-dir and wipes any prior volatile-root
   install (clean slate). `/nix` is now persistent in the private volume.
4. `sh <(curl -L https://nixos.org/nix/install) --no-daemon`
5. Enable flakes: `~/.config/nix/nix.conf` →
   `experimental-features = nix-command flakes`.

Each Qubes host (`dev`, `cyber`) then owns an independent, persistent store.

## Target repo layout

```
~/.local/share/chezmoi/              # path kept; chezmoi semantics removed
├── flake.nix                        # inputs + outputs (one per host)
├── flake.lock                       # committed — created on first `nix` run
├── home.nix                         # shared base; imports modules + profiles
├── modules/
│   ├── shell.nix                    # programs.zsh + p10k + plugins + aliases
│   ├── git.nix                      # programs.git + delta + signing
│   ├── nvim.nix                     # xdg.configFile."nvim".source = ./config/nvim
│   ├── kitty.nix                    # programs.kitty
│   ├── ranger.nix                   # programs.ranger + devicons plugin
│   ├── gh.nix                       # programs.gh
│   ├── misc.nix                     # standalone configs: aws, pycodestyle, VSCodium
│   ├── qubes.nix                    # my.host.qubes — split-GPG + inter-VM aliases
│   ├── aerospace.nix                # AeroSpace WM (macOS only)
│   └── profiles/                    # package-set modules
│       ├── core.nix                 # base CLI packages (unconditional)
│       ├── core-gui.nix             # base GUI apps, Linux-only (unconditional)
│       ├── dev.nix                  # dev toolchain (my.profiles.dev)
│       ├── security.nix             # cyber toolkit (my.profiles.security)
│       ├── pers.nix                 # personal apps (my.profiles.pers)
│       └── i3.nix                   # i3 + rofi + polybar (my.profiles.i3) — scaffold
├── hosts/
│   ├── dev.nix                      # Qubes VM (Arch)
│   ├── cyber.nix                    # Qubes VM (Arch)
│   └── work.nix                     # work macOS (HM side)
├── darwin/
│   └── common.nix                   # shared nix-darwin system config (casks, keymap)
└── config/                          # raw dotfile trees, symlinked via xdg.configFile
    ├── nvim/                         # moved verbatim from dot_config/nvim
    ├── kitty/
    ├── ranger/
    ├── zsh/                          # aliases dir, functions.zsh, p10k.zsh
    ├── wget/                         # wgetrc
    ├── VSCodium/                     # product.json
    ├── aws/                          # config → ~/.aws/config
    ├── aerospace/                    # aerospace.toml + bring-workspace.sh
    └── pycodestyle
```

## Conventions

- **All custom options live under the `my.*` namespace** so they never collide
  with HM/nixpkgs option names. Examples:
  - `my.profiles.dev.enable` / `my.profiles.security.enable`
  - `my.host.qubes` (toggles the Qubes GPG glue)
- **Feature-flag pattern:** every profile module is *always imported* (so its
  options exist on every host) but only *enabled* on hosts that flip
  `my.profiles.<x>.enable = true`. Disabled modules contribute nothing to the
  build closure.
- **`home.username` / `home.homeDirectory` are per-host** (they live in
  `hosts/*.nix`), since the login account differs across machines and macOS
  uses `/Users/...`.
- Platform branches use `pkgs.stdenv.isLinux` / `pkgs.stdenv.isDarwin` for the
  rare package that differs or does not exist on one OS.

## chezmoi → Home Manager translation map

| chezmoi today | Home Manager equivalent |
|---|---|
| `.chezmoidata/packages.yaml` → `pacman`/`paru` | `home.packages` in `modules/profiles/{core,core-gui,dev,security,pers}.nix` |
| `run_once_oh-my-zsh.sh` (clones OMZ + p10k + plugins) | `programs.zsh.oh-my-zsh.enable` + packaged `zsh-powerlevel10k`, `zsh-syntax-highlighting`, `zsh-autosuggestions` |
| `dot_zshenv.tmpl` env exports | `home.sessionVariables` |
| `dot_gitconfig.tmpl` | `programs.git` (`userEmail`, `signing`, `delta`, `extraConfig`) |
| Qubes conditional templates | per-host module gated by `my.host.qubes` |
| `.chezmoiexternal.toml` ranger_devicons + git submodule | `programs.ranger.plugins` or pinned `fetchFromGitHub` |
| `pyenv` / `eval "$(pyenv init)"` | keep in `programs.zsh.initExtra`, or move to Nix-managed Python later |
| Arch `pacman` install scripts | stays system-side; HM does not manage system packages on non-NixOS |
| NvChad lua tree | `xdg.configFile."nvim".source = ./config/nvim` — no translation |
| `dot_config/gh/config.yml` | `programs.gh` (`settings`) |
| `dot_aws/config`, `dot_config/{wget,pycodestyle,VSCodium}` | `home.file` / `xdg.configFile` symlinks — no HM module |

Notable package-name mappings to verify in nixpkgs: `git-delta` → `delta`,
`dust` → `du-dust`, `okkular` (typo) → `kdePackages.okular`, `neofetch` →
consider `fastfetch`, `pavucontrol` → Linux-only.

---

## Phases

### Phase 0 — Prep (manual, per host)

1. Pilot host = `dev` (Qubes VM running Arch — safe to break / clone).
2. **Qubes: persist `/nix` first.** Add the `/nix` bind-dir and reboot before
   installing — see *Nix on Qubes* above.
3. Install Nix **single-user**: `sh <(curl -L https://nixos.org/nix/install) --no-daemon`.
4. Verify flakes work: `nix run nixpkgs#hello`.
5. Snapshot rollback point: `git branch pre-nix-snapshot main && git push origin pre-nix-snapshot`.

### Phase 1 — Scaffold the flake  ← *current*

1. Branch `nix` off `main`.
2. `flake.nix` — inputs `nixpkgs` + `home-manager`; one `homeConfigurations.dev`
   output via a `mkHome` helper. (nix-darwin input added in Phase 5.)
3. `home.nix` — minimal: `home.stateVersion`, `programs.home-manager.enable`,
   commented-out `imports` block for the Phase 2 modules.
4. `hosts/dev.nix` — imports `home.nix`, sets `home.username` /
   `home.homeDirectory`.
5. **Verify on the `dev` host:** `nix run home-manager -- switch --flake .#dev`
   succeeds and is effectively a no-op.

### Phase 2 — Core modules (build on `dev`, one at a time)

Run `home-manager switch --flake .#dev` after each module; each is independently
verifiable. Switches must be **impure** with `GIT_EMAIL` set —
`GIT_EMAIL=… home-manager switch --flake .#dev --impure` — because `git.nix`
reads the commit email from `$GIT_EMAIL` so it is never committed to the repo.

1. `modules/tools.nix` — port the base CLI list from `.chezmoidata/packages.yaml`.
2. `modules/git.nix` — `programs.git` (email, name, signing, delta, `insteadOf`).
3. `modules/shell.nix` — `programs.zsh` (oh-my-zsh, plugins, p10k), aliases,
   `home.sessionVariables` replacing `dot_zshenv.tmpl`.
4. `modules/kitty.nix` — `programs.kitty`.
5. `modules/ranger.nix` — `programs.ranger` + devicons plugin.
6. `modules/nvim.nix` — move `dot_config/nvim/` → `config/nvim/`; symlink via
   `xdg.configFile`; add `pkgs.neovim`.
7. Uncomment the module imports in `home.nix`. Verify a fresh shell on `dev`.

### Phase 3 — Profile flag scaffolding

1. Create `modules/profiles/dev.nix` and `modules/profiles/security.nix` with
   `my.profiles.<x>.enable` options but empty package lists.
2. Import both unconditionally from `home.nix`.
3. Flip `my.profiles.dev.enable = true` in `hosts/dev.nix` (no behavior change
   yet — lists are empty).

### Phase 4 — Add `cyber` (Qubes)

1. `hosts/cyber.nix` — imports `home.nix`; enables `dev` + `security` profiles.
2. Qubes glue: `gpg.program = "qubes-gpg-client-wrapper"`,
   `QUBES_GPG_DOMAIN = "gpg"`, Qubes aliases.
3. Set up Nix-store persistence + install Nix (see *Nix on Qubes*).
4. Test in a fresh/cloned VM.

### Phase 5 — Add macOS (`work`)

1. Add the `nix-darwin` input to `flake.nix`.
2. Install Nix on the `work` Mac (Determinate installer), then nix-darwin.
3. `darwin/common.nix` — shared nix-darwin system config: `homebrew.casks`,
   `system.keyboard` remaps, etc.
4. `darwinConfigurations.work` wires `darwin/common.nix` +
   `home-manager.darwinModules.home-manager` + `home.nix` + `hosts/work.nix`.
5. Verify shell/git/nvim/tools on `work`
   (`darwin-rebuild switch --flake .#work --impure`).

### Phase 6 — Decommission chezmoi

1. Remove the leftover chezmoi sources. By this phase `dot_config/` holds only
   `chezmoi/` and the dead `zsh/` files — the real configs were migrated to
   `config/` + modules in Phase 2, and `dot_aws/` is already gone:
   `git rm -r dot_config dot_zshenv.tmpl dot_gitconfig.tmpl .chezmoi* run_once_* run_onchange_*`.
2. `.gitmodules` is removed with step 1. Stale **local** `.git/` submodule
   state also remains from this repo's pre-chezmoi *dotbot* era: `.git/config`
   `submodule.*` sections and `.git/modules/{dotbot,oh-my-zsh,ranger}`. No tree
   has gitlinks referencing them, so this is local-only cruft — clear with
   `git config --remove-section` + `rm -rf .git/modules/*` when convenient.
3. Uninstall chezmoi per host (`pacman -R chezmoi` / `brew uninstall chezmoi`).

### Phase 7 — Fill in profiles

Package sets live in `modules/profiles/`: `core.nix` / `core-gui.nix`
(unconditional) and `dev.nix` / `security.nix` / `pers.nix` (gated by
`my.profiles.<name>.enable`). All five are populated — `core`, `core-gui`,
`dev`, `pers` from the `dev` VM and `security` from the `cyber` VM (its
package list diffed against `dev` to isolate the security-only tools).

---

## Branching & rollback

- All migration work on the `nix` branch; merge to `main` only after Phase 5
  (all hosts — `dev`, `cyber`, `work` — confirmed working).
- `pre-nix-snapshot` branch is the chezmoi-era rollback point — keep indefinitely.
- **Per-phase rollback:** `home-manager generations` + `home-manager switch
  --rollback`.
- **Whole-migration rollback:** `git checkout pre-nix-snapshot && chezmoi apply`.
  The Nix install itself is inert without `home-manager switch`.
- **Qubes hosts (`dev`, `cyber`):** root is volatile — see *Nix on Qubes*. The
  Nix store must be persisted (bind-dir) before anything else. Test in a
  throwaway VM clone.

## Open items

- Complete the `i3` profile (i3 / rofi / polybar configuration) and AeroSpace
  `settings` — both are scaffolded but not yet configured.
- Fill in the remaining macOS modifier-key remaps in `darwin/common.nix`
  (`command → fn` is wired as the first one).

Resolved: `dev` **does** use the Qubes GPG wrapper — `modules/qubes.nix` now
applies the split-GPG glue whenever `my.host.qubes = true`. The macOS account
name is sourced from `$USER` at switch time (impure), so it needs no entry.

## Status

- [ ] **Phase 0** — pilot chosen (`dev`); flake confirmed working. First Nix
      install was daemon-mode and did not persist (`/nix` on volatile root).
      Redo as single-user + `/nix` bind-dir (see *Nix on Qubes*), then create
      the `pre-nix-snapshot` branch.
- [x] **Phase 1** — flake scaffold verified on `dev`:
      `home-manager switch --flake .#dev` succeeds. (Persistence of the Nix
      install itself is a Phase 0 item — see above.)
- [x] **Phase 2** — core modules written: `tools`, `git`, `shell`, `kitty`,
      `ranger`, `nvim`, plus `gh` (`programs.gh`), `misc` (aws / pycodestyle /
      VSCodium) and `modules/qubes.nix` (the `my.host.qubes` flag, brought
      forward from Phase 4). All of `dot_config/` and `dot_aws/` is migrated
      except the chezmoi-only leftovers. Config trees moved to `config/`;
      imports uncommented in `home.nix`. Per-module
      `home-manager switch --flake .#dev` verification is still pending —
      blocked on Phase 0 (no persistent Nix install yet).
- [x] **Phase 3** — profile flag scaffolding done: `modules/profiles/dev.nix`
      (`my.profiles.dev` — terraform + pnpm) and `modules/profiles/security.nix`
      (`my.profiles.security` — empty, populated in Phase 7) are both imported
      from `home.nix`; `dev` enables the `dev` profile.
- [x] **Phase 4** — `cyber` host added: `hosts/cyber.nix` (Qubes; enables
      `my.host.qubes` and the `dev` + `security` profiles) plus its `flake.nix`
      output. Remaining is host-side and manual: persist `/nix` and install Nix
      on the `cyber` VM (see *Nix on Qubes*), then verify in a throwaway clone.
- [x] **Phase 5** — macOS `work` host wired (repo side): `nix-darwin` +
      `nix-homebrew` inputs, `darwinConfigurations.work`, `darwin/common.nix`
      (Homebrew casks raycast/slack/zoom/1password, Cmd/Option/Fn keymap),
      `hosts/work.nix` (dev + security profiles), `modules/aerospace.nix`
      (config + bring-workspace.sh from `config/aerospace/`). Remaining is
      host-side/manual — install Nix + nix-darwin on the Mac, then
      `darwin-rebuild switch --flake .#work --impure`.
- [x] **Phase 6** — chezmoi decommissioned early: all 13 chezmoi source files
      removed, the repo is now a pure Nix flake. Still pending: uninstall the
      `chezmoi` binary per host, and clear the local `.git/` dotbot-era
      submodule cruft (step 2 above).
- [x] **Phase 7** — profiles populated: `core`, `core-gui`, `dev`, `pers` from
      the `dev` VM and `security` from the `cyber` VM. The `i3` profile is
      scaffolded for later. (Work GUI apps are Homebrew casks, not a profile.)
