# modules/aerospace.nix — AeroSpace tiling window manager (macOS only).
#
# `programs.aerospace` asserts on non-Darwin platforms, so everything is
# guarded — on the Linux hosts this module contributes nothing. The config and
# the bring-workspace helper are kept verbatim under config/aerospace/.
{ pkgs, lib, ... }:

{
  programs.aerospace = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    # The TOML sets `start-at-login = true`; the module requires that to be
    # backed by a launchd agent, so launchd.enable must be true to match.
    launchd.enable = true;
    settings = builtins.fromTOML (builtins.readFile ../config/aerospace/aerospace.toml);
  };

  # Helper referenced by the alt-ctrl-N "bring workspace to this monitor"
  # bindings in aerospace.toml.
  xdg.configFile."aerospace/bring-workspace.sh" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ../config/aerospace/bring-workspace.sh;
    executable = true;
  };
}
