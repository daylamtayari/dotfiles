# modules/profiles/dev.nix — opt-in development toolchain.
#
# Always imported so `my.profiles.dev.enable` exists on every host; contributes
# packages only where a host enables it (currently `dev` and `cyber`).
#
# Curated from this dev VM's explicitly-installed Arch packages (`paru -Qe`).
{ config, lib, pkgs, ... }:

{
  options.my.profiles.dev.enable =
    lib.mkEnableOption "development toolchain";

  config = lib.mkIf config.my.profiles.dev.enable {
    home.packages = with pkgs; [
      # Languages / runtimes
      go
      gopls
      golangci-lint
      lua
      luarocks
      ruby
      rustup
      julia
      php
      nodejs # provides npm
      pnpm
      dotnet-sdk
      clang
      jython
      pyenv # the pyenv shell init lives in modules/shell.nix
      # Build / VCS
      cmake
      gradle
      maven
      gdb
      git-lfs
      mercurial
      lazygit
      # Cloud / infra
      terraform # unfree (BUSL)
      awscli2
      google-cloud-sdk
      docker # the daemon is system-side on non-NixOS
      docker-compose
      docker-buildx
      act # run GitHub Actions locally
      # Databases (client tools; run the servers via docker or the system)
      mariadb
      postgresql
      # Tooling
      air # Go live-reload
      claude-code
      cloc
      hyperfine
      hugo
      pandoc
      gnuplot
      semgrep
      hexedit
      htmlq
      csvkit
      csvlens
            #xsv
      lighttpd
      android-tools
      powershell
      texliveFull # large — swap for texlive.combined.scheme-medium if not all needed
      # GUI developer tools
      dbeaver-bin
      vscodium
      mongodb-compass # unfree
      drawio
      bruno # API client
      # Remote access
      remmina
      freerdp # RDP backend for remmina
      # System / networking utilities
      man-db
      bind # named + dig / host / nsupdate
      inetutils
      ipinfo
    ]
    # Linux-only — excluded on macOS. checksec / altair have Homebrew
    # equivalents (darwin/common.nix); net-tools / cifs-utils (macOS has BSD
    # equivalents) and zeal (no macOS build at all) do not.
    ++ lib.optionals stdenv.isLinux [
      net-tools
      cifs-utils
      checksec
      altair # nixpkgs altair (GraphQL client) is x86_64-linux only
      zeal # Linux/Windows only; Dash is the macOS counterpart
    ];
  };
}
