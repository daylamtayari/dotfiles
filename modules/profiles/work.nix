# modules/profiles/work.nix — opt-in work applications.
#
# Always imported so `my.profiles.work.enable` exists on every host; enabled
# on both `work` hosts (macOS and NixOS). On macOS slack is a Homebrew cask
# (darwin/common.nix); on NixOS 1Password is a system module (nixos/common.nix).
{ config, lib, pkgs, ... }:

{
  options.my.profiles.work.enable =
    lib.mkEnableOption "work applications";

  config = lib.mkIf config.my.profiles.work.enable {
    home.packages = with pkgs; [
      librewolf
      thunderbird
    ]
    # spotify's nixpkgs package is Linux-only; on macOS it is a Homebrew cask.
    # super-productivity's nixpkgs build aborts on macOS 26 (Tahoe): its
    # Electron build links nixpkgs' libuv, which is built without -DNDEBUG so
    # the kqueue assert(errno == EINTR) stays live and aborts under the build's
    # fd load (libuv#976). On macOS it is a Homebrew cask instead.
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      spotify
      super-productivity
      slack # unfree, x86_64-linux only; Homebrew cask on macOS
    ];

    programs.zsh.initContent = lib.mkAfter ''
      [[ -f "$HOME/.work.zsh" ]] && source "$HOME/.work.zsh"
    '';
  };
}
