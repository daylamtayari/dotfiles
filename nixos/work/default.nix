# nixos/work/default.nix — work NixOS machine (system side).
#
# configuration.nix and hardware-configuration.nix are copied verbatim from the
# machine's /etc/nixos — they hold the bootloader, disks, hostname, desktop and
# system.stateVersion chosen at install time. Shared system config lives in
# ../common.nix; the Home Manager side is hosts/work.nix (shared with the Mac).
{ pkgs, user, ... }:

{
  imports = [
    ./configuration.nix # imports ./hardware-configuration.nix itself
    ../common.nix
  ];

  # Sway desktop. The compositor is system-side (PAM for swaylock, polkit, xdg
  # portals, a session entry for the display manager); its config, rofi,
  # Waybar and kanshi come from the HM profile (modules/profiles/sway.nix).
  # Enabled here rather than in hosts/work.nix, which the Mac shares.
  programs.sway = {
    enable = true;
    # SwayFX — drop-in Sway fork that adds rounded corners (picom's job on i3).
    package = pkgs.swayfx;
  };
  home-manager.users.${user}.my.profiles.sway.enable = true;

  # Boot straight to a login prompt that launches Sway (the install chose "No
  # desktop", so there is no other display manager to conflict with).
  # --remember pre-fills the last username.
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
  };

  # Audio — a "No desktop" install leaves it out, and Sway does not provide
  # it. PipeWire with the PulseAudio shim, so pavucontrol (core-gui.nix) works.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

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
