# modules/tools.nix — base package set.
#
# Ported from .chezmoidata/packages.yaml (the Arch `official` list), plus a few
# tools that the zsh aliases reference but that were missing from packages.yaml
# (bottom, gping, jless, glow, yt-dlp, nomacs, vlc) and the Nerd Font that
# kitty and the nvim/ranger devicons assume.
#
# Packages that have a dedicated Home Manager module are installed by that
# module instead, and are intentionally omitted here:
#
#   git    -> modules/git.nix    (programs.git)
#   delta  -> modules/git.nix    (programs.git.delta)
#   kitty  -> modules/kitty.nix  (programs.kitty)
#   zsh    -> modules/shell.nix  (programs.zsh)
#   ranger -> modules/ranger.nix (programs.ranger)
#   neovim -> modules/nvim.nix   (home.packages)
#
# Development-only tools (terraform, pnpm) live in modules/profiles/dev.nix.
{ pkgs, lib, ... }:

{
  # Make Home Manager-installed fonts visible to applications.
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Utilities
    bat
    bottom # "btm"
    btop
    duf
    du-dust # "dust"
    erdtree # provides the `erd` binary
    eza
    fd
    ffmpeg
    fzf
    glow
    gping
    igrep # interactive ripgrep TUI
    imagemagick
    jless
    jq
    fastfetch # replaces "neofetch" (unmaintained upstream, dropped from nixpkgs)
    onefetch
    procs
    ripgrep
    sd
    tokei
    wget
    yt-dlp
    # Languages
    go
    lua
    # Fonts — required by kitty's font_family and the nvim/ranger devicons.
    nerd-fonts.fira-code
  ]
  # GUI / Linux-only applications. macOS installs GUI apps via Homebrew casks
  # (darwin/*.nix, Phase 5), so guard these to Linux hosts.
  ++ lib.optionals stdenv.isLinux [
    firefox
    kdePackages.okular # "okkular" in packages.yaml was a typo
    pavucontrol
    nomacs
    vlc
  ];
}
