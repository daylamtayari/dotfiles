# hosts/cyber.nix — Qubes VM running Arch Linux.
#
# Thin per-host overlay: imports the shared base and sets only what is
# specific to this machine. Runs the dev + security toolchains.
{ ... }:

{
  imports = [ ../home.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  # Qubes AppVM — split-GPG and the inter-VM aliases (modules/qubes.nix).
  my.host.qubes = true;

  # Toolchains (modules/profiles/*).
  my.profiles.dev.enable = true;
  my.profiles.security.enable = true;
}
