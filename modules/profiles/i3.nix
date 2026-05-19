# modules/profiles/i3.nix — opt-in i3 + rofi + polybar desktop (Linux / X11).
#
# Scaffold only: the `my.profiles.i3.enable` flag exists and installs the three
# tools, but the actual configuration (i3 keybinds, rofi theme, polybar bars)
# is to be completed later. No host enables it yet.
{ config, lib, pkgs, ... }:

{
  options.my.profiles.i3.enable =
    lib.mkEnableOption "i3 + rofi + polybar desktop";

  config = lib.mkIf config.my.profiles.i3.enable {
    home.packages = with pkgs; [
      i3
      rofi
      polybar
    ];
    # TODO: xsession.windowManager.i3, programs.rofi, services.polybar
  };
}
