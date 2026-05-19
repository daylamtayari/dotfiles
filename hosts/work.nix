# hosts/work.nix — work macOS host (nix-darwin + Home Manager).
#
# home.username / home.homeDirectory are set by the nix-darwin Home Manager
# integration (from the account in flake.nix), so this overlay only selects
# toolchain profiles. macOS system config is shared in darwin/common.nix.
{ ... }:

{
  imports = [ ../home.nix ];

  my.profiles.dev.enable = true;
  my.profiles.security.enable = true;
  my.profiles.work.enable = true;
}
