{
  description = "AWS utilities for Nix";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      pkgsForSystem = system: (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
        ];
      });
    in
    {
      overlays.default = final: prev: {
        ssm-helpers = final.callPackage ./ssm-helpers/default.nix { };
        efs-utils = final.callPackage ./efs-utils/default.nix { };
      };
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsForSystem system;
          in
          {
            ssm-helpers = pkgs.ssm-helpers;
            efs-utils = pkgs.efs-utils;
            default = pkgs.ssm-helpers;
          });
      nixosModules.efs-utils = {
        imports = [ ./efs-utils/module.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
