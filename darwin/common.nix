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

  # GUI applications installed via Homebrew. Homebrew itself must already be
  # installed on the host (Phase 5 setup).
  homebrew = {
    enable = true;
    casks = [
      "raycast"
    ];
    onActivation.cleanup = "none"; # do not touch brews not declared here
  };

  # Modifier-key remapping. `command → fn` is wired below as a worked example;
  # add the rest of the remaps as { Src; Dst; } pairs. The integers are IOKit
  # HID usage codes (Nix hex literals):
  #   left command 0x7000000E3   left control 0x7000000E0
  #   left option  0x7000000E2   caps lock    0x700000039
  #   fn / globe   0xFF00000003
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      # left Command → Fn (Globe)
      {
        HIDKeyboardModifierMappingSrc = 0x7000000E3;
        HIDKeyboardModifierMappingDst = 0xFF00000003;
      }
    ];
  };

  # Use traditional scroll direction — disable macOS "natural" scrolling so it
  # matches Linux and Windows.
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
}
