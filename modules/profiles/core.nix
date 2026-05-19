# modules/profiles/core.nix — base CLI package set.
#
# Unconditional (no my.profiles flag): every host gets it; cross-platform.
# Curated from this VM's explicitly-installed Arch packages (`paru -Qe`),
# excluding:
#   - system / Qubes / desktop packages — stay pacman-managed (see Phase 6 notes)
#   - tools owned by a dedicated module: git, delta, gh, kitty, neovim, ranger,
#     zsh, zoxide
{ pkgs, lib, ... }:

{
  # Make Home Manager-installed fonts visible to applications (Linux).
  fonts.fontconfig.enable = true;

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
    # Networking
    curlie
    httpie
    wget
    whois
    dnsutils # dig, nslookup, …
    gping
    proxychains-ng
    # Misc CLI
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
  # Fonts — Linux only. nixpkgs font packages drag glibc into their build
  # closure, which has no aarch64-darwin platform; on macOS fonts come from
  # Homebrew casks (darwin/common.nix). Covers kitty's font_family and the
  # nvim / ranger devicons.
  ++ lib.optionals stdenv.isLinux [
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    dejavu_fonts
  ];
}
