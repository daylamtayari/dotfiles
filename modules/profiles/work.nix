# modules/profiles/work.nix — opt-in work applications.
#
# Always imported so `my.profiles.work.enable` exists on every host; enabled
# on the `work` host. These are macOS GUI apps installed from nixpkgs — if a
# darwin build is unreliable, the alternative is a Homebrew cask in
# darwin/common.nix (see NIX_MIGRATION.md).
{ config, lib, pkgs, ... }:

{
  options.my.profiles.work.enable =
    lib.mkEnableOption "work applications";

  config = lib.mkIf config.my.profiles.work.enable {
    home.packages = with pkgs; [
      slack
      zoom-us # zoom
      _1password-gui # 1Password desktop app
    ];
  };
}
