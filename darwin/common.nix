# darwin/common.nix — shared nix-darwin system configuration for the macOS
# hosts (pers, work). Per-host Home Manager settings live in hosts/<host>.nix.
{ pkgs, lib, user, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple Silicon; Intel = x86_64-darwin
  nixpkgs.config.allowUnfree = true;
  # Workarounds for nixpkgs-unstable breakage; see overlays/default.nix.
  # home-manager.useGlobalPkgs is set in flake.nix, so HM packages get these too.
  nixpkgs.overlays = import ../overlays;

  # Nix itself is managed by the Determinate installer (see NIX_MIGRATION.md),
  # so nix-darwin must not manage the daemon.
  nix.enable = false;

  # nix-darwin state version — read the changelog before bumping.
  system.stateVersion = 6;

  # Skip building the offline HTML manual + `darwin-help` script. When nixpkgs
  # is ahead of nix-darwin master (both track unstable/master), nixpkgs's
  # `nixos-render-docs` can drop CLI flags that nix-darwin still passes — e.g.
  # `--toc-depth` was renamed to `--sidebar-depth`, breaking the manual build.
  # Re-enable once nix-darwin catches up.
  documentation.enable = false;
  system.tools.darwin-uninstaller.enable = false;

  # The macOS account this configuration targets ($USER at eval time).
  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";

  # Homebrew itself is installed and managed by nix-homebrew, so it is present
  # even on a fresh Mac; `autoMigrate` adopts an already-installed Homebrew
  # rather than failing.
  nix-homebrew = {
    enable = true;
    user = user;
    autoMigrate = true;
  };

  # Homebrew packages. `brews` are CLI formulae, `casks` are GUI apps. Several
  # are here because their nixpkgs packages are Linux-only (see dev.nix /
  # security.nix / work.nix); the rest are Mac GUI apps.
  homebrew = {
    enable = true;
    enableZshIntegration = true;
    taps = [
      "nikitabobko/tap" # provides the aerospace cask
    ];
    brews = [
      "ike-scan" # security.nix — nixpkgs package is Linux-only
      "dependency-check" # not in nixpkgs at all
      "massdns"
      "john"
    ];
    casks = [
      "nikitabobko/tap/aerospace" # tiling WM — from nikitabobko/tap; config managed by modules/aerospace.nix
      "firefox" # core-gui.nix — Mozilla-signed build (the nixpkgs Firefox is unsigned)
      "raycast"
      "slack"
      "zoom" # work.nix — zoom-us from nixpkgs on NixOS
      "spotify" # work.nix — nixpkgs package is Linux-only
      "super-productivity" # work.nix — nixpkgs Electron build aborts on macOS 26 (libuv#976)
      "vlc" # core-gui.nix — nixpkgs vlc skipped on macOS
      "ungoogled-chromium" # core-gui.nix — nixpkgs chromium skipped on macOS
      "altair-graphql-client" # dev.nix — nixpkgs altair is x86_64-linux only
      "dash" # dev.nix — macOS counterpart to zeal (Zeal has no macOS build)
      "veracrypt" # security.nix — nixpkgs package is Linux-only
      "bloodhound" # security.nix — Linux-only; cask is deprecated upstream
      "mullvad-vpn" # core.nix — nixpkgs build is Linux-only despite its meta.platforms
      "tailscale-app" # work tailnet — standalone app (menu bar + bundled CLI); needs a system extension, so not from nixpkgs
      # Nerd Font for kitty's font_family + the nvim / ranger devicons
      # (the nixpkgs font packages are Linux-only — see core.nix).
      "burp-suite"
      "font-fira-code-nerd-font"
      "font-symbols-only-nerd-font"
    ];
    onActivation.cleanup = "none"; # do not touch brews not declared here
    onActivation.autoUpdate = true; # `brew update` on each rebuild
    onActivation.upgrade = true; # `brew upgrade` outdated brews/casks on each rebuild
  };

  # Modifier-key remap for the bottom-left key cluster. Physical
  # fn|ctrl|option|command is remapped to send command|ctrl|fn|option, so
  # AeroSpace's `alt` (Option) mod sits under the thumb. See the header of
  # config/aerospace/aerospace.toml for the rationale. Values are IOKit HID
  # usage codes as decimal integers (Nix has no hex literal):
  #   fn / globe  0xFF00000003 = 1095216660483
  #   control     0x7000000E0  = 30064771296
  #   option      0x7000000E2  = 30064771298
  #   command     0x7000000E3  = 30064771299
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      { HIDKeyboardModifierMappingSrc = 1095216660483; HIDKeyboardModifierMappingDst = 30064771299; } # fn → command
      { HIDKeyboardModifierMappingSrc = 30064771298; HIDKeyboardModifierMappingDst = 1095216660483; } # option → fn
      { HIDKeyboardModifierMappingSrc = 30064771299; HIDKeyboardModifierMappingDst = 30064771298; } # command → option
    ];
  };

  # Use traditional scroll direction — disable macOS "natural" scrolling so it
  # matches Linux and Windows.
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
}
