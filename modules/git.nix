# modules/git.nix — programs.git, ported from dot_gitconfig.tmpl.
#
# Qubes split-GPG (`gpg.program`) is NOT set here. It is host-specific and
# lives in modules/qubes.nix, gated by `my.host.qubes`.
{ lib, ... }:

let
  # The commit email is read from $GIT_EMAIL at evaluation time so it is
  # never committed to the repo and can differ per machine (personal vs
  # work). This means switches must be run impure:
  #
  #   GIT_EMAIL=you@example.com home-manager switch --flake .#dev --impure
  #
  # A plain (pure) switch evaluates builtins.getEnv to "", which would write
  # an empty user.email — so always pass --impure with GIT_EMAIL set.
  gitEmail = builtins.getEnv "GIT_EMAIL";
in
{
  programs.git = {
    enable = true;

    userName = "Daylam Tayari";
    userEmail = gitEmail;

    # delta as pager + interactive diff filter. `delta.enable` installs
    # pkgs.delta and sets `core.pager = delta` (covering diff/log/reflog/show,
    # which the old gitconfig listed individually) plus
    # `interactive.diffFilter = "delta --color-only"`. The old config also
    # carried `--features=interactive`, but that referenced an undefined delta
    # feature and was a no-op, so it is dropped.
    delta.enable = true;

    extraConfig = {
      commit.gpgSign = true;
      tag.forceSignAnnotated = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = false;
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
