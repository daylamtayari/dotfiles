# modules/profiles/core-gui.nix — base GUI applications.
#
# Unconditional, but Linux-only: on macOS these come from Homebrew casks
# (darwin/*.nix, Phase 5), so the list is guarded. General-purpose GUI apps
# wanted on every host.
{ pkgs, lib, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    firefox
    ungoogled-chromium
    vlc
    nomacs # image viewer
    kdePackages.okular # PDF viewer
    libreoffice-fresh
    obsidian # unfree
    pavucontrol # audio control
  ]);
}
