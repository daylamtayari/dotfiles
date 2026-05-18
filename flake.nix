{
  description = "Daylam Tayari's dotfiles — Nix flake + Home Manager (Phase 1: scaffold)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Added in Phase 5 for the macOS hosts (pers, work):
    # nix-darwin = {
    #   # The master branch tracks nixpkgs-unstable.
    #   url = "github:nix-darwin/nix-darwin";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Build a standalone Home Manager configuration for a Linux host.
      mkHome = { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
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
