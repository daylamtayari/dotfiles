# modules/git.nix — programs.git + programs.delta, ported from
# dot_gitconfig.tmpl.
#
# Qubes split-GPG (`gpg.program`) is NOT set here. It is host-specific and
# lives in modules/qubes.nix, gated by `my.host.qubes`.
{ config, lib, ... }:

let
  # The commit email is read from $GIT_EMAIL at evaluation time so it is never
  # committed to the repo and can differ per machine (personal vs work). This
  # means switches must be run impure:
  #
  #   GIT_EMAIL=you@example.com home-manager switch --flake .#dev --impure
  #
  # A plain (pure) switch evaluates builtins.getEnv to "", which would write an
  # empty user.email — so always pass --impure with GIT_EMAIL set.
  gitEmail = builtins.getEnv "GIT_EMAIL";

  # Un-tracked, machine-local git config — the git equivalent of
  # ~/.config/aws/local.conf (see modules/misc.nix). Work-profile settings
  # (signing keys, per-host identities, internal host url rewrites, corporate
  # insteadOf rules) go here so they stay out of the git tree and out of the
  # world-readable Nix store.
  gitLocal = "${config.xdg.configHome}/git/local.conf";

  # Comment-only starter file, copied into place on first activation. Kept as a
  # store file rather than an inline heredoc so activation needs no shell
  # quoting and cannot be broken by indentation.
  gitLocalTemplate = builtins.toFile "gitconfig-local-template" ''
    # Machine-local git config — NOT tracked in the dotfiles repo.
    #
    # Included at the end of ~/.config/git/config by modules/git.nix, so
    # anything set here overrides the tracked defaults. git reads it live:
    # edits take effect immediately, with no rebuild.
    #
    # Put work-profile / per-host settings here, e.g.:
    #
    # [user]
    #     email = you@work.example.com
    #     signingkey = ssh-ed25519 AAAA...
    #
    # [url "git@git.internal.example.com:"]
    #     insteadOf = https://git.internal.example.com/
  '';
in
{
  programs.git = {
    enable = true;

    # All git config lives under `settings` — the Home Manager schema that
    # replaced the userName / userEmail / extraConfig options.
    settings = {
      user.name = "Daylam Tayari";
      user.email = gitEmail;
      commit.gpgSign = true;
      tag.forceSignAnnotated = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      branch.autosetupRebase = "always";
      url."git@github.com:".insteadOf = "https://github.com/";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      ".node_modules"
    ];

    # Unlike the AWS CLI, git has a real `include` directive, so no
    # assemble-at-activation step is needed — the overlay is read live and
    # edits take effect immediately, with no rebuild.
    #
    # Home Manager renders `includes` with lib.mkAfter, i.e. at the very end of
    # ~/.config/git/config. Since git applies config in file order with last
    # value winning, local.conf can override anything set above — including
    # user.email. A missing include path is silently ignored by git, so the
    # file is optional.
    includes = [ { path = gitLocal; } ];
  };

  # Seed local.conf with a commented template the first time, purely for
  # discoverability — git does not need the file to exist. This only ever
  # creates it when absent, so hand edits are never clobbered.
  home.activation.gitLocalConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    gitLocal="${gitLocal}"
    if [ -e "$gitLocal" ]; then
      :
    elif [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would seed template $gitLocal"
    else
      mkdir -p "$(dirname "$gitLocal")"
      # 0600, and writable: the store copy is read-only, so -m matters here.
      install -m 600 ${gitLocalTemplate} "$gitLocal"
    fi
  '';

  # delta is its own module now. `enableGitIntegration` wires it in as git's
  # pager + interactive diff filter, and must be set explicitly (the old
  # automatic enablement is deprecated).
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
