# modules/aerospace.nix — AeroSpace tiling window manager (macOS only).
#
# AeroSpace itself is installed as a Homebrew cask (darwin/common.nix); this
# module only manages its config on Darwin. The config and the bring-workspace
# helper are kept verbatim under config/aerospace/. `start-at-login = true` in
# aerospace.toml makes AeroSpace register itself as a login item, so no launchd
# agent is needed. On the Linux hosts this module contributes nothing.
{ pkgs, lib, ... }:

{
  # AeroSpace reads $XDG_CONFIG_HOME/aerospace/aerospace.toml (i.e.
  # ~/.config/aerospace/aerospace.toml) — same path home-manager used to write.
  xdg.configFile."aerospace/aerospace.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = ../config/aerospace/aerospace.toml;
  };

  # Helper referenced by the alt-ctrl-N "bring workspace to this monitor"
  # bindings in aerospace.toml.
  xdg.configFile."aerospace/bring-workspace.sh" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = ../config/aerospace/bring-workspace.sh;
    executable = true;
  };
}
