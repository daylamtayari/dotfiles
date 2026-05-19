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

  # GUI applications installed via Homebrew casks.
  homebrew = {
    enable = true;
    casks = [
      "raycast"
      "slack"
      "zoom"
      "1password"
    ];
    onActivation.cleanup = "none"; # do not touch brews not declared here
  };

  # Modifier-key remap for the bottom-left key cluster. Physical
  # fn|ctrl|option|command is remapped to send command|ctrl|fn|option, so
  # AeroSpace's `alt` (Option) mod sits under the thumb. See the header of
  # config/aerospace/aerospace.toml for the rationale. Integers are IOKit HID
  # usage codes (Nix hex literals):
  #   fn / globe 0xFF00000003   control 0x7000000E0
  #   option     0x7000000E2    command 0x7000000E3
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      { HIDKeyboardModifierMappingSrc = 0xFF00000003; HIDKeyboardModifierMappingDst = 0x7000000E3; } # fn → command
      { HIDKeyboardModifierMappingSrc = 0x7000000E2; HIDKeyboardModifierMappingDst = 0xFF00000003; } # option → fn
      { HIDKeyboardModifierMappingSrc = 0x7000000E3; HIDKeyboardModifierMappingDst = 0x7000000E2; } # command → option
    ];
  };

  # Use traditional scroll direction — disable macOS "natural" scrolling so it
  # matches Linux and Windows.
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
}
