{
  description = "Hyprland + Quickshell desktop for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      quickshell,
      ...
    }:
    let
      lib = nixpkgs.lib;

      # Every hosts/<name>/ with a host.nix becomes nixosConfigurations.<name>.
      hostNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory" && builtins.pathExists ./hosts/${name}/host.nix) (
          builtins.readDir ./hosts
        )
      );

      mkHost =
        name:
        let
          host = import ./hosts/${name}/host.nix;
        in
        lib.nixosSystem {
          system = host.system or "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            self.nixosModules.default
            home-manager.nixosModules.home-manager
            ./hosts/${name}/configuration.nix
            {
              networking.hostName = lib.mkDefault name;
              dotfiles.user = host.user;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.${host.user} = {
                  imports = [
                    self.homeManagerModules.default
                    ./hosts/${name}/home.nix
                  ];
                  home.username = host.user;
                  home.homeDirectory = "/home/${host.user}";
                };
              };
            }
          ];
        };
    in
    {
      nixosModules.default = {
        imports = [ ./modules/nixos.nix ];
        # `nix shell nixpkgs#foo` and <nixpkgs> resolve to the nixpkgs the system was built from.
        nix.registry.nixpkgs.flake = nixpkgs;
        nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
      };

      homeManagerModules.default = { lib, pkgs, ... }: {
        imports = [ ./modules/home.nix ];
        dotfiles.quickshellPackage = lib.mkDefault (
          quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
            pkgs.qt6.qtsvg
            pkgs.qt6.qtimageformats
            pkgs.qt6.qtmultimedia
            pkgs.qt6.qt5compat
          ]
        );
      };

      nixosConfigurations = lib.genAttrs hostNames mkHost;

      formatter = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
