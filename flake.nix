{
  description = "Daylam Tayari's dotfiles — Nix flake + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      # The master branch tracks nixpkgs-unstable.
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Installs/manages the Homebrew installation itself on macOS hosts, so
    # Homebrew is present even on a fresh Mac.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # ranger_devicons plugin. `flake = false` makes the input a plain source
    # tree; flake.lock pins the exact commit and `nix flake update` rolls it
    # forward. Replaces the chezmoi `.chezmoiexternal.toml` git-repo external.
    ranger-devicons = {
      url = "github:alexanderjeurissen/ranger_devicons";
      flake = false;
    };

    # pyenv-virtualenv plugin. Not packaged in nixpkgs, so it is pulled as a
    # plain source tree and symlinked into ~/.pyenv/plugins by
    # modules/profiles/dev.nix; flake.lock pins the commit.
    pyenv-virtualenv = {
      url = "github:pyenv/pyenv-virtualenv";
      flake = false;
    };

    # nvim-mcp — the MCP server that exposes a running Neovim to Claude Code
    # and opencode. Its flake ships the Rust server as a package, which is why
    # we take the binary from here rather than from lazy.nvim's
    # `build = "cargo install --path ."`: that build cannot link under this
    # host's Nix toolchain (aws-lc-sys fails with `ld: library not found for
    # -liconv`). The lazy.nvim spec still provides the plugin's Lua half.
    #
    # nixpkgs is deliberately NOT `follows`-ed here: the flake pins its own
    # nixpkgs plus a fenix Rust toolchain, and repointing it would force a
    # from-source rebuild of the toolchain instead of reusing the binary cache.
    nvim-mcp.url = "github:linw1995/nvim-mcp";

    # CrowdStrike Falcon sensor (user-mode/eBPF) for the work NixOS machine.
    # The flake ships only the module and packaging; the proprietary .deb is
    # supplied from the local store (see nixos/work/falcon-sensor.nix).
    falcon-sensor = {
      url = "git+ssh://git@github.com/tayari-liftoff/falcon-sensor-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-homebrew, ... }@inputs:
    let
      # macOS account name. `darwin-rebuild` runs under sudo, so $USER is
      # "root" — fall back to $SUDO_USER, which sudo sets to the real account.
      # darwin builds must be run impure for these getEnv calls to resolve.
      darwinUser =
        let sudoUser = builtins.getEnv "SUDO_USER";
        in if sudoUser != "" then sudoUser else builtins.getEnv "USER";

      # Standalone Home Manager configuration for a Linux host.
      # `inputs` is threaded through extraSpecialArgs so modules can reach
      # non-flake inputs (e.g. ranger-devicons) as a module argument.
      mkHome = { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = import ./overlays;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            hostModule
          ];
        };

      # nix-darwin system (with Home Manager + Homebrew) for a macOS host.
      mkDarwin = hostModule:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; user = darwinUser; };
          modules = [
            ./darwin/common.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # Move any pre-existing unmanaged file that a managed symlink would
              # clobber to <file>.backup instead of aborting the switch (e.g. the
              # opencode.jsonc that opencode created before we managed it). Only
              # fires on first-time collisions; once HM owns the symlink there is
              # nothing to back up.
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.${darwinUser} = import hostModule;
            }
          ];
        };

      # NixOS system (with Home Manager) for a Linux host. `nixosModule` is the
      # machine's system config (nixos/<host>/), `hostModule` its HM overlay.
      # The account name is passed explicitly — NixOS declares the user itself
      # in nixos/common.nix, so it is not read from the environment.
      mkNixos = { system, user, nixosModule, hostModule }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            nixosModule
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.${user} = import hostModule;
            }
          ];
        };
    in
    {
      homeConfigurations = {
        dev = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/dev.nix;
        };

        cyber = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/cyber.nix;
        };
      };

      darwinConfigurations = {
        work = mkDarwin ./hosts/work.nix;
      };

      # Shares hosts/work.nix with the Mac, so both work machines run the same
      # profiles. Same `work` label: nixos-rebuild only looks in
      # nixosConfigurations, darwin-rebuild only in darwinConfigurations.
      nixosConfigurations = {
        work = mkNixos {
          system = "x86_64-linux";
          user = "dtayari";
          nixosModule = ./nixos/work;
          hostModule = ./hosts/work.nix;
        };
      };
    };
}
