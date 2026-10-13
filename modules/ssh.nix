# modules/ssh.nix — shared SSH client config.
{ config, lib, ... }:

let
  # Un-tracked, machine-local SSH config — the SSH equivalent of
  # ~/.config/git/local.conf (see modules/git.nix). Per-host blocks (internal
  # hostnames, jump hosts, usernames, identity files) go here so they stay out
  # of the git tree and out of the world-readable Nix store.
  sshLocal = "${config.xdg.configHome}/ssh/local.conf";

  # Comment-only starter file, copied into place on first activation.
  sshLocalTemplate = builtins.toFile "ssh-local-template" ''
    # Machine-local SSH config — NOT tracked in the dotfiles repo.
    #
    # Included at the top of ~/.ssh/config by modules/ssh.nix. ssh uses the
    # FIRST value it finds for each option, so anything set here overrides the
    # tracked defaults. ssh reads it live: edits take effect immediately, with
    # no rebuild.
    #
    # Put work-profile / per-host settings here, e.g.:
    #
    # Host bastion
    #     HostName bastion.internal.example.com
    #     User you
  '';
in
{
  programs.ssh = {
    enable = true;
    # Don't inject Home Manager's legacy defaults into `Host *` (the option is
    # deprecated); set anything needed explicitly instead.
    enableDefaultConfig = false;

    # Home Manager renders `includes` as `Include` lines at the very top of
    # ~/.ssh/config, before any Host block. Since ssh applies first value
    # wins (the opposite of git), that placement is what lets local.conf
    # override the tracked config. A missing include path is silently ignored
    # by ssh, so the file is optional.
    includes = [ sshLocal ];
  };

  # Seed local.conf with a commented template the first time, purely for
  # discoverability. Only ever creates it when absent, so hand edits are never
  # clobbered.
  home.activation.sshLocalConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    sshLocal="${sshLocal}"
    if [ -e "$sshLocal" ]; then
      :
    elif [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would seed template $sshLocal"
    else
      mkdir -p "$(dirname "$sshLocal")"
      # 0600: ssh refuses config files writable by others.
      install -m 600 ${sshLocalTemplate} "$sshLocal"
    fi
  '';
}
