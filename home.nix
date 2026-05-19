# home.nix — shared base configuration imported by every host.
{ ... }:

{
  imports = [
    # Core modules:
    ./modules/git.nix
    ./modules/shell.nix
    ./modules/kitty.nix
    ./modules/ranger.nix
    ./modules/nvim.nix
    ./modules/gh.nix
    ./modules/misc.nix

    # Qubes configuration for Qubes VMs
    ./modules/qubes.nix

    # macOS configuration (guarded to Darwin)
    ./modules/aerospace.nix

    # Package-set modules
    ./modules/profiles/core.nix
    ./modules/profiles/core-gui.nix
    ./modules/profiles/dev.nix
    ./modules/profiles/security.nix
    ./modules/profiles/pers.nix
    ./modules/profiles/work.nix
    ./modules/profiles/i3.nix
  ];

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
