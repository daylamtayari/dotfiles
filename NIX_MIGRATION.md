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
| `pers` | personal macOS | nix-darwin + HM | |
| `work` | work macOS | nix-darwin + HM | |

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
│   ├── tools.nix                    # base CLI package list
│   ├── qubes.nix                    # my.host.qubes — split-GPG + inter-VM aliases
│   └── profiles/
│       ├── dev.nix                  # opt-in dev toolchain (my.profiles.dev)
│       └── security.nix             # opt-in cyber toolkit (my.profiles.security)
├── hosts/
│   ├── dev.nix                      # Qubes VM (Arch)
│   ├── cyber.nix                    # Qubes VM (Arch)
│   ├── pers.nix                     # personal macOS (HM side)
│   └── work.nix                     # work macOS (HM side)
├── darwin/
│   ├── pers.nix                     # nix-darwin system config (brew casks, defaults)
│   └── work.nix
└── config/                          # raw dotfile trees, symlinked via xdg.configFile
    ├── nvim/                         # moved verbatim from dot_config/nvim
    ├── kitty/
    ├── ranger/
    └── zsh/                          # aliases dir, functions.zsh, p10k.zsh
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
| `.chezmoidata/packages.yaml` → `pacman`/`paru` | `home.packages = with pkgs; [ ... ]` in `modules/tools.nix` |
| `run_once_oh-my-zsh.sh` (clones OMZ + p10k + plugins) | `programs.zsh.oh-my-zsh.enable` + packaged `zsh-powerlevel10k`, `zsh-syntax-highlighting`, `zsh-autosuggestions` |
| `dot_zshenv.tmpl` env exports | `home.sessionVariables` |
| `dot_gitconfig.tmpl` | `programs.git` (`userEmail`, `signing`, `delta`, `extraConfig`) |
| Qubes conditional templates | per-host module gated by `my.host.qubes` |
| `.chezmoiexternal.toml` ranger_devicons + git submodule | `programs.ranger.plugins` or pinned `fetchFromGitHub` |
| `pyenv` / `eval "$(pyenv init)"` | keep in `programs.zsh.initExtra`, or move to Nix-managed Python later |
| Arch `pacman` install scripts | stays system-side; HM does not manage system packages on non-NixOS |
| NvChad lua tree | `xdg.configFile."nvim".source = ./config/nvim` — no translation |

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

### Phase 5 — Add macOS (`pers`, `work`)

1. Add the `nix-darwin` input to `flake.nix`.
2. Install Nix on `pers` (Determinate installer), then nix-darwin.
3. `darwin/pers.nix` — `homebrew.casks` for GUI apps absent from nixpkgs, plus
   any declarative `system.defaults.*`.
4. `darwinConfigurations.pers` wires `darwin/pers.nix` +
   `home-manager.darwinModules.home-manager` + `home.nix` + `hosts/pers.nix`.
5. Verify shell/git/nvim/tools on `pers`; repeat for `work`.

### Phase 6 — Decommission chezmoi

1. `git rm -r dot_aws dot_config dot_zshenv.tmpl dot_gitconfig.tmpl .chezmoi* run_once_* run_onchange_*`.
2. Remove the ranger devicons submodule (`.gitmodules`, `.git/modules/`).
3. Uninstall chezmoi per host (`pacman -R chezmoi` / `brew uninstall chezmoi`).

### Phase 7 — Fill in profiles

Populate `modules/profiles/dev.nix` and `modules/profiles/security.nix` with the
real toolchains. Touches only those two files.

---

## Branching & rollback

- All migration work on the `nix` branch; merge to `main` only after Phase 5
  (all four hosts confirmed working).
- `pre-nix-snapshot` branch is the chezmoi-era rollback point — keep indefinitely.
- **Per-phase rollback:** `home-manager generations` + `home-manager switch
  --rollback`.
- **Whole-migration rollback:** `git checkout pre-nix-snapshot && chezmoi apply`.
  The Nix install itself is inert without `home-manager switch`.
- **Qubes hosts (`dev`, `cyber`):** root is volatile — see *Nix on Qubes*. The
  Nix store must be persisted (bind-dir) before anything else. Test in a
  throwaway VM clone.

## Open items

- Confirm `home.username` / `home.homeDirectory` for the macOS hosts (`pers`,
  `work`). Qubes hosts are `user` / `/home/user`.
- Phase 7: decide concrete `dev` and `security` profile package lists.

Resolved: `dev` **does** use the Qubes GPG wrapper — `modules/qubes.nix` now
applies the split-GPG glue whenever `my.host.qubes = true`.

## Status

- [ ] **Phase 0** — pilot chosen (`dev`); flake confirmed working. First Nix
      install was daemon-mode and did not persist (`/nix` on volatile root).
      Redo as single-user + `/nix` bind-dir (see *Nix on Qubes*), then create
      the `pre-nix-snapshot` branch.
- [x] **Phase 1** — flake scaffold verified on `dev`:
      `home-manager switch --flake .#dev` succeeds. (Persistence of the Nix
      install itself is a Phase 0 item — see above.)
- [x] **Phase 2** — core modules written: `tools`, `git`, `shell`, `kitty`,
      `ranger`, `nvim`, plus `modules/qubes.nix` (the `my.host.qubes` flag,
      brought forward from Phase 4). Config trees moved to `config/`; imports
      uncommented in `home.nix`. Per-module `home-manager switch --flake .#dev`
      verification is still pending — blocked on Phase 0 (no persistent Nix
      install yet).
- [ ] **Phase 3** — profile flag scaffolding. `modules/profiles/dev.nix` is
      done (`my.profiles.dev` — terraform + pnpm) and enabled on `dev`;
      `modules/profiles/security.nix` still to do.
- [ ] **Phase 4** — `cyber` host. Qubes split-GPG glue + aliases are already
      done (`modules/qubes.nix`); remaining: `hosts/cyber.nix`, profile flags,
      throwaway-VM test.
- [ ] **Phase 5** — macOS hosts.
- [ ] **Phase 6** — decommission chezmoi.
- [ ] **Phase 7** — fill in profiles.
