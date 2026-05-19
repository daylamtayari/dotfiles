# modules/qubes.nix — Qubes OS glue.
#
# Always imported so that `my.host.qubes` exists on every host; it contributes
# nothing unless a host sets `my.host.qubes = true`. Qubes AppVMs reach GPG
# keys through split-GPG (a separate backend qube) rather than a local keyring,
# and have inter-VM file-copy helpers.
#
# This is the abstraction point for all Qubes-specific configuration — `dev`
# and (Phase 4) `cyber` enable it with a single flag.
{ config, lib, ... }:

{
  options.my.host.qubes =
    lib.mkEnableOption "Qubes OS split-GPG glue and inter-VM aliases";

  config = lib.mkIf config.my.host.qubes {
    # Sign git commits/tags through the split-GPG client wrapper instead of a
    # local gpg binary (ported from the Qubes branch of dot_gitconfig.tmpl).
    programs.git.extraConfig.gpg.program = "qubes-gpg-client-wrapper";

    # Backend qube that holds the GPG private keys.
    home.sessionVariables.QUBES_GPG_DOMAIN = "gpg";

    # Route bare `gpg` through split-GPG, plus inter-VM file helpers
    # (ported from aliases/qubes.zsh.tmpl).
    programs.zsh.shellAliases = {
      gpg = "qubes-gpg-client";
      qc = "qvm-copy";
      qm = "qvm-move";
    };
  };
}
