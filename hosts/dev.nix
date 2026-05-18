# hosts/dev.nix — Qubes VM running Arch Linux (pilot host).
#
# Thin per-host overlay: imports the shared base and sets only what is
# specific to this machine.
{ ... }:

{
  imports = [ ../home.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  # Phase 3 will enable per-host toolchain profiles here, e.g.:
  # my.profiles.dev.enable = true;
}
