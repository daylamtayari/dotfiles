# modules/aerospace.nix — AeroSpace tiling window manager (macOS only).
#
# `programs.aerospace` asserts on non-Darwin platforms, so the whole block is
# guarded — on the Linux hosts this module contributes nothing. The detailed
# AeroSpace config (programs.aerospace.settings) is left for a later pass.
{ pkgs, lib, ... }:

{
  programs.aerospace = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    launchd.enable = true; # start AeroSpace at login
    # settings = { ... };  # TODO: gaps, mode, key bindings
  };
}
