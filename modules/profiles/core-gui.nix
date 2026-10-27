# modules/profiles/core-gui.nix — base GUI applications.
#
# Split: packages with native macOS nixpkgs builds (firefox / nomacs / obsidian)
# are unconditional; the rest are Linux-only, and macOS picks up the ones it
# needs as Homebrew casks in darwin/common.nix (vlc, ungoogled-chromium).
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # unfree. Electron only uses the Secret Service keyring on desktops it
    # recognises (GNOME, KDE, …); under sway it falls back to unencrypted
    # "basic text" storage, so point it at gnome-keyring explicitly.
    (obsidian.override {
      commandLineArgs = lib.optionalString stdenv.hostPlatform.isLinux "--password-store=gnome-libsecret";
    })
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    # firefox is Linux-only here; on macOS it comes from the Homebrew cask in
    # darwin/common.nix. The nixpkgs Firefox build is unsigned, so apps that
    # verify a browser's code signature won't recognise it on macOS.
    firefox
    ungoogled-chromium
    vlc
    nomacs # image viewer
    kdePackages.okular # PDF viewer
    libreoffice-fresh
    pavucontrol # audio control
    thunar
  ];
}
