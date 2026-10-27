# nixos/common.nix — shared NixOS system configuration. Per-machine hardware,
# boot and desktop settings live in nixos/<host>/; per-host Home Manager
# settings live in hosts/<host>.nix.
{ pkgs, user, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
  # Workarounds for nixpkgs-unstable breakage; see overlays/default.nix.
  # home-manager.useGlobalPkgs is set in flake.nix, so HM packages get these too.
  nixpkgs.overlays = import ../overlays;

  # Login shell. HM's programs.zsh configures zsh but cannot register it in
  # /etc/shells or set the account's shell — that has to happen system-side.
  programs.zsh.enable = true;
  # Completions for HM-installed packages (useUserPackages puts them in the
  # per-user profile, which zsh only searches if /share/zsh is linked).
  environment.pathsToLink = [ "/share/zsh" ];

  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # FUSE-backed /bin and /usr/bin that resolve to whatever is on PATH, so
  # third-party scripts with hardcoded #!/bin/bash etc. work.
  services.envfs.enable = true;

  # Distrust these root CAs in the system trust store. System-level option —
  # Home Manager has no equivalent, so it can't live in home.nix.
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];

  # Stub dynamic loader so prebuilt generic-linux binaries (mason.nvim LSPs and
  # formatters, npm/pip wheels with native bits) can run.
  programs.nix-ld.enable = true;

  environment.systemPackages = [ pkgs.git ];
}
