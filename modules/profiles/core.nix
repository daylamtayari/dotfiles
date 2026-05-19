# modules/profiles/core.nix — base CLI package set.
#
# Unconditional (no my.profiles flag): every host gets it; cross-platform.
# Curated from this VM's explicitly-installed Arch packages (`paru -Qe`),
# excluding:
#   - system / Qubes / desktop packages — stay pacman-managed (see Phase 6 notes)
#   - tools owned by a dedicated module: git, delta, gh, kitty, neovim, ranger,
#     zsh, zoxide
{ pkgs, ... }:

{
  # Make Home Manager-installed fonts visible to applications.
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
    # Fonts — kitty's font_family + the nvim / ranger devicons
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    dejavu_fonts
  ];
}
