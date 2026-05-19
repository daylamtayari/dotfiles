# modules/profiles/core-gui.nix — base GUI applications.
#
# Split: packages with native macOS nixpkgs builds (firefox / nomacs / obsidian)
# are unconditional; the rest are Linux-only, and macOS picks up the ones it
# needs as Homebrew casks in darwin/common.nix (vlc, ungoogled-chromium).
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    firefox
    obsidian # unfree
  ]
  ++ lib.optionals stdenv.isLinux [
    ungoogled-chromium
    vlc
    nomacs # image viewer
    kdePackages.okular # PDF viewer
    libreoffice-fresh
    pavucontrol # audio control
  ];
}
