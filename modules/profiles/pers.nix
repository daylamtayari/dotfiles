# modules/profiles/pers.nix — opt-in personal applications.
#
# Always imported so `my.profiles.pers.enable` exists on every host; enabled
# only on the personal host (`pers`, added in Phase 5). This dev VM carries no
# personal packages, so the list below is just a seed.
{ config, lib, pkgs, ... }:

{
  options.my.profiles.pers.enable =
    lib.mkEnableOption "personal applications";

  config = lib.mkIf config.my.profiles.pers.enable {
    home.packages = with pkgs; [
      discord # unfree
      thunderbird
      texliveFull # large — swap for texlive.combined.scheme-medium if not all needed
    ];
  };
}
