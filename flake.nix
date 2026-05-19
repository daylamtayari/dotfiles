{
  description = "Daylam Tayari's dotfiles — Nix flake + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ranger_devicons plugin. `flake = false` makes the input a plain source
    # tree; flake.lock pins the exact commit and `nix flake update` rolls it
    # forward. Replaces the chezmoi `.chezmoiexternal.toml` git-repo external.
    ranger-devicons = {
      url = "github:alexanderjeurissen/ranger_devicons";
      flake = false;
    };

    # Added in Phase 5 for the macOS hosts (pers, work):
    # nix-darwin = {
    #   # The master branch tracks nixpkgs-unstable.
    #   url = "github:nix-darwin/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # Build a standalone Home Manager configuration for a Linux host.
      # `inputs` is threaded through extraSpecialArgs so modules can reach
      # non-flake inputs (e.g. ranger-devicons) as a module argument.
      mkHome = { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            # Allow unfree packages system-wide (e.g. terraform, BUSL-licensed).
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            hostModule
          ];
        };
    in
    {
      homeConfigurations = {
        dev = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/dev.nix;
        };

        # Phase 4 — Qubes Arch template.
        # cyber = mkHome {
        #   system = "x86_64-linux";
        #   hostModule = ./hosts/cyber.nix;
        # };
      };

      # Phase 5 — macOS hosts via nix-darwin.
      # darwinConfigurations = {
      #   pers = nix-darwin.lib.darwinSystem { ... };
      #   work = nix-darwin.lib.darwinSystem { ... };
      # };
    };
}
