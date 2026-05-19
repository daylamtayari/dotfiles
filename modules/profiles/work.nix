# modules/profiles/work.nix — opt-in work applications.
#
# Always imported so `my.profiles.work.enable` exists on every host; enabled
# on the `work` host. This profile is for nixpkgs-packaged work tools — the
# work GUI apps slack / zoom / 1Password are Homebrew casks (darwin/common.nix).
{ config, lib, pkgs, ... }:

{
  options.my.profiles.work.enable =
    lib.mkEnableOption "work applications";

  config = lib.mkIf config.my.profiles.work.enable {
    home.packages = with pkgs; [
      super-productivity
    ]
    # spotify's nixpkgs package is Linux-only; on macOS it is a Homebrew cask.
    ++ lib.optionals stdenv.isLinux [
      spotify
    ];
  };
}
