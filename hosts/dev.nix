# hosts/dev.nix — Qubes VM running Arch Linux (pilot host).
#
# Thin per-host overlay: imports the shared base and sets only what is
# specific to this machine.
{ ... }:

{
  imports = [ ../home.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  # Qubes AppVM — use split-GPG and the inter-VM aliases (modules/qubes.nix).
  my.host.qubes = true;

  # Development toolchain (modules/profiles/dev.nix).
  my.profiles.dev.enable = true;
}
