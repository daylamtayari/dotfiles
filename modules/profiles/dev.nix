# modules/profiles/dev.nix — opt-in development toolchain.
#
# Always imported so `my.profiles.dev.enable` exists on every host; contributes
# packages only where a host enables it (currently `dev` and `cyber`).
#
# Curated from this dev VM's explicitly-installed Arch packages (`paru -Qe`).
{ config, lib, pkgs, ... }:

let
  # gitall — runs a command in every git repo below a directory, in parallel.
  # errexit is dropped from bashOptions on purpose: gitall reports a failing
  # command per-repo (red header) instead of aborting the whole run.
  gitall = pkgs.writeShellApplication {
    name = "gitall";
    runtimeInputs = with pkgs; [ coreutils findutils gnugrep ];
    bashOptions = [ "nounset" ];
    text = lib.removePrefix "#!/usr/bin/env bash\n"
      (builtins.readFile ../scripts/gitall.sh);
  };
in
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
      python3
      # julia-bin (upstream's official binary) rather than `julia`: the source
      # build has no aarch64-darwin binary cache and its bundled OpenBLAS test
      # suite fails on Apple silicon. Same version, all three platforms.
      julia-bin
      php
      nodejs # provides npm
      pnpm
      poetry
      clang
      jython
      pyenv # the pyenv shell init lives in modules/shell.nix
      virtualenv
      pipenv
      # Build / VCS
      cmake
      gradle
      maven
      gdb
      git-lfs
      gitall
      mercurial
      lazygit
      pre-commit
      isort
      black
      pylint
      bandit
      # Cloud / infra
      terraform # unfree (BUSL)
      awscli2
      google-cloud-sdk
      # Container clients. On Linux they hit the system-side Docker daemon; on
      # macOS (which can't run a container daemon natively) they talk to Podman
      # over DOCKER_HOST — the Podman engine itself is added in the darwin block
      # below. See modules/shell.nix for the DOCKER_HOST wiring.
      docker
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
      mermaid-cli
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
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      net-tools
      cifs-utils
      checksec
      altair # nixpkgs altair (GraphQL client) is x86_64-linux only
      zeal # Linux/Windows only; Dash is the macOS counterpart
    ]
    # macOS-only — the container engine. Linux hosts use the system-side Docker
    # daemon, so the docker clients above suffice there; on macOS Podman runs a
    # rootless Linux VM (`podman machine`) that those clients target.
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      podman
      podman-compose
    ];

    # macOS: bring the Podman VM up automatically so the docker/podman clients
    # work without a manual `podman machine start`. This is a LaunchAgent, so it
    # runs at login rather than literal boot — the right scope for a rootless
    # per-user VM. `|| true` swallows the harmless "already running" error when
    # re-logging in without a reboot. Linux uses the system daemon, so Darwin-only.
    launchd.agents.podman-machine = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments =
          [ "/bin/sh" "-c" "${pkgs.podman}/bin/podman machine start || true" ];
        RunAtLoad = true;
        # `podman machine start` forks gvproxy + vfkit (the VM itself) and then
        # exits. launchd reaps a job's whole process group once the main process
        # exits, which would kill the VM the instant it came up — so disown the
        # group and let those helpers outlive the starter. No KeepAlive: the
        # starter is meant to exit, and launchd would otherwise respawn it in a
        # loop.
        AbandonProcessGroup = true;
        StandardOutPath = "/tmp/podman-machine-start.log";
        StandardErrorPath = "/tmp/podman-machine-start.log";
      };
    };
  };
}
