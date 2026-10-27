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
      google-chrome
      rclone
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
      zoom-us # unfree; Homebrew cask on macOS
    ];

    programs.zsh.initContent = lib.mkAfter ''
      [[ -f "$HOME/.work.zsh" ]] && source "$HOME/.work.zsh"
    '';

    # Mount Google Drive at ~/GoogleDrive. Expects a `gdrive` remote in
    # ~/.config/rclone/rclone.conf (`rclone config`). PATH includes
    # /run/wrappers/bin for NixOS's setuid fusermount3 wrapper.
    systemd.user.services.rclone-gdrive = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "rclone mount of Google Drive";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "notify";
        Environment = [ "PATH=/run/wrappers/bin" ];
        # Clear a stale mount left by an unclean stop ("-" ignores failure
        # when nothing is mounted), then ensure the mountpoint exists.
        ExecStartPre = [
          "-/run/wrappers/bin/fusermount3 -uz %h/GoogleDrive"
          "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive"
          "--vfs-cache-mode full"
          "--vfs-cache-max-size 30G"
          "--vfs-cache-max-age 72h"
          # Change polling invalidates modified directories, so listings can
          # be cached indefinitely instead of expiring and re-fetching.
          "--dir-cache-time 9999h"
          "--poll-interval 1m"
          # Remote control on a private socket (%t is 0700) for the warmup.
          "--rc --rc-no-auth --rc-addr unix://%t/rclone-gdrive.sock"
        ];
        # Prime the directory cache in the background once the mount is up.
        ExecStartPost = lib.concatStringsSep " " [
          "${pkgs.rclone}/bin/rclone rc --unix-socket %t/rclone-gdrive.sock"
          "vfs/refresh recursive=true _async=true"
        ];
        # Lazy unmount so a shell sitting in the mount doesn't block stopping.
        ExecStop = "/run/wrappers/bin/fusermount3 -uz %h/GoogleDrive";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
