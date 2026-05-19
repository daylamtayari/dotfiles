# modules/profiles/dev.nix — opt-in development toolchain.
#
# Always imported so `my.profiles.dev.enable` exists on every host; it
# contributes packages only on hosts that set `my.profiles.dev.enable = true`
# (currently `dev`, and `cyber` in Phase 4).
{ config, lib, pkgs, ... }:

{
  options.my.profiles.dev.enable =
    lib.mkEnableOption "development toolchain (terraform, pnpm)";

  config = lib.mkIf config.my.profiles.dev.enable {
    home.packages = with pkgs; [
      terraform # unfree (BUSL) — allowed via config.allowUnfree in flake.nix
      pnpm
    ];
  };
}
