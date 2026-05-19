# darwin/common.nix — shared nix-darwin system configuration for the macOS
# hosts (pers, work). Per-host Home Manager settings live in hosts/<host>.nix.
{ pkgs, lib, user, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin"; # Apple Silicon; Intel = x86_64-darwin
  nixpkgs.config.allowUnfree = true;

  # Nix itself is managed by the Determinate installer (see NIX_MIGRATION.md),
  # so nix-darwin must not manage the daemon.
  nix.enable = false;

  # nix-darwin state version — read the changelog before bumping.
  system.stateVersion = 6;

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
    brews = [
      "checksec" # dev.nix — nixpkgs package is Linux-only
      "ike-scan" # security.nix — nixpkgs package is Linux-only
      "dependency-check" # not in nixpkgs at all
    ];
    casks = [
      "raycast"
      "slack"
      "zoom"
      "1password"
      "spotify" # work.nix — nixpkgs package is Linux-only
      "altair-graphql-client" # dev.nix — nixpkgs altair is x86_64-linux only
      "dash" # dev.nix — macOS counterpart to zeal (Zeal has no macOS build)
      "veracrypt" # security.nix — nixpkgs package is Linux-only
      "bloodhound" # security.nix — Linux-only; cask is deprecated upstream
      # Nerd Font for kitty's font_family + the nvim / ranger devicons
      # (the nixpkgs font packages are Linux-only — see core.nix).
      "font-fira-code-nerd-font"
      "font-symbols-only-nerd-font"
    ];
    onActivation.cleanup = "none"; # do not touch brews not declared here
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
