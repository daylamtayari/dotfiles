# modules/profiles/core.nix — base CLI package set.
#
# Unconditional (no my.profiles flag): every host gets it; cross-platform.
# Curated from this VM's explicitly-installed Arch packages (`paru -Qe`),
# excluding:
#   - system / Qubes / desktop packages — stay pacman-managed (see Phase 6 notes)
#   - tools owned by a dedicated module: git, delta, gh, kitty, neovim, ranger,
#     zsh, zoxide
{ config, pkgs, lib, ... }:

{
  # fontconfig — Linux only. The font packages below are Linux-only too, so on
  # macOS there is nothing for it to do; disabling it keeps anything
  # font-related out of the darwin evaluation.
  fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;

  home.packages = with pkgs; [
    # Archives
    _7zip-zstd
    atool
    unzip
    unrar # unfree
    zip
    # Search / view / file-preview (several also back ranger's scope.sh)
    bat
    eza
    fd
    ripgrep
    fzf
    jq
    jless
    tabiew
    glow
    tree
    highlight
    w3m
    hexyl
    mediainfo
    ffmpeg
    ffmpegthumbnailer
    imagemagick
    odt2txt
    igrep
    # System / disk monitors
    btop
    bottom # btm
    htop
    duf
    dust # dust
    procs
    erdtree # erd
    libqalculate
    # Networking
    curlie
    httpie
    wget
    whois
    dnsutils # dig, nslookup, …
    gping
    proxychains-ng
    # Misc CLI
    coreutils # GNU rm/ls/cp/… — same binary & syntax on macOS and Linux
    gnupg
    tmux
    vim # plain-vim fallback; the real editor is modules/nvim.nix
    vifm
    sd
    tokei
    minisign
    rsync
    xclip
    yt-dlp
    fastfetch # replaces the unmaintained neofetch
    onefetch
  ]
  # Mullvad — Linux only. nixpkgs inherits mullvad-vpn's meta.platforms from
  # electron, which claims aarch64-darwin, but the derivation hardcodes
  # `npmBuildScript = "pack:linux"`, so the macOS build packages a Linux
  # Electron tree and dies renaming dist/linux-arm64-unpacked/electron.
  # On macOS it comes from the Homebrew cask (darwin/common.nix).
  # Skipped on work hosts, which use Tailscale instead (the two fight over
  # routing/firewall rules).
  ++ lib.optionals (stdenv.hostPlatform.isLinux && !config.my.profiles.work.enable) [
    mullvad-vpn
  ]
  # Fonts — Linux only. nixpkgs font packages drag glibc into their build
  # closure, which has no aarch64-darwin platform; on macOS fonts come from
  # Homebrew casks (darwin/common.nix). Covers kitty's font_family and the
  # nvim / ranger devicons.
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    dejavu_fonts
    # Common web/Electron UI font stacks name these ahead of any bundled
    # webfont; without them apps fall through to unhinted webfonts.
    roboto
    inter
  ];
}
