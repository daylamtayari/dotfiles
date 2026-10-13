# nixos/work/default.nix — work NixOS machine (system side).
#
# configuration.nix and hardware-configuration.nix are copied verbatim from the
# machine's /etc/nixos — they hold the bootloader, disks, hostname, desktop and
# system.stateVersion chosen at install time. Shared system config lives in
# ../common.nix; the Home Manager side is hosts/work.nix (shared with the Mac).
{ user, ... }:

{
  imports = [
    ./configuration.nix # imports ./hardware-configuration.nix itself
    ../common.nix
  ];

  # Docker daemon — the dev profile installs only the docker clients on Linux
  # and expects the system to provide the daemon.
  virtualisation.docker.enable = true;
  users.users.${user}.extraGroups = [ "docker" ];

  # Mullvad — core.nix installs the GUI; it needs the system daemon to connect.
  services.mullvad-vpn.enable = true;

  # 1Password — the system modules (not a plain package) are needed for the
  # polkit unlock prompt, browser integration and `op` CLI integration.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user ];
  };
}
