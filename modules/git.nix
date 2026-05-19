# modules/git.nix — programs.git + programs.delta, ported from
# dot_gitconfig.tmpl.
#
# Qubes split-GPG (`gpg.program`) is NOT set here. It is host-specific and
# lives in modules/qubes.nix, gated by `my.host.qubes`.
{ ... }:

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
      pull.rebase = false;
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };

  # delta is its own module now. `enableGitIntegration` wires it in as git's
  # pager + interactive diff filter, and must be set explicitly (the old
  # automatic enablement is deprecated).
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
