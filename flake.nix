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

    # ranger_devicons plugin. `flake = false` makes the input a plain source
    # tree; flake.lock pins the exact commit and `nix flake update` rolls it
    # forward. Replaces the chezmoi `.chezmoiexternal.toml` git-repo external.
    ranger-devicons = {
      url = "github:alexanderjeurissen/ranger_devicons";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      # macOS account name — sourced from $USER at evaluation time since it
      # differs per machine. darwin builds must therefore be run impure:
      #   darwin-rebuild switch --flake .#work --impure
      darwinUser = builtins.getEnv "USER";

      # Standalone Home Manager configuration for a Linux host.
      # `inputs` is threaded through extraSpecialArgs so modules can reach
      # non-flake inputs (e.g. ranger-devicons) as a module argument.
      mkHome = { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            hostModule
          ];
        };

      # nix-darwin system (with Home Manager) for a macOS host.
      mkDarwin = hostModule:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; user = darwinUser; };
          modules = [
            ./darwin/common.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.${darwinUser} = import hostModule;
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
    };
}
