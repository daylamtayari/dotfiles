# home.nix — shared base configuration imported by every host.
#
# Phase 1 keeps this intentionally minimal:
#   - Phase 2 uncomments the module imports below.
#   - Phase 3 adds the profile modules (modules/profiles/*).
# See NIX_MIGRATION.md for the full plan.
#
# Per-host values (home.username, home.homeDirectory, profile flags) live in
# hosts/<name>.nix, NOT here.
{ ... }:

{
  imports = [
    # Phase 2 — core modules:
    # ./modules/tools.nix
    # ./modules/git.nix
    # ./modules/shell.nix
    # ./modules/kitty.nix
    # ./modules/ranger.nix
    # ./modules/nvim.nix

    # Phase 3 — profile flag modules (always imported; enabled per host):
    # ./modules/profiles/dev.nix
    # ./modules/profiles/security.nix
  ];

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
