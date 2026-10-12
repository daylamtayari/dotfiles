# hosts/work.nix — work hosts: macOS (nix-darwin + Home Manager) and NixOS.
#
# Shared by darwinConfigurations.work and nixosConfigurations.work.
# home.username / home.homeDirectory are set by the nix-darwin / NixOS Home
# Manager integration (from the account in flake.nix), so this overlay only
# selects toolchain profiles. System config lives in darwin/common.nix and
# nixos/common.nix respectively.
{ ... }:

{
  imports = [ ../home.nix ];

  my.profiles.dev.enable = true;
  my.profiles.security.enable = true;
  my.profiles.work.enable = true;
}
