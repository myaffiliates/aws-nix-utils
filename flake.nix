{
  description = "AWS utilities for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
        efs-proxy = final.callPackage ./efs-proxy/default.nix {
          # Use clang stdenv to avoid GCC 14+ incompatibility with aws-lc-fips-sys
          stdenv = final.llvmPackages.stdenv;
        };
      };
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsForSystem system;
          in
          {
            ssm-helpers = pkgs.ssm-helpers;
            efs-proxy = pkgs.efs-proxy;
            efs-utils = pkgs.efs-utils;
            default = pkgs.ssm-helpers;
          });
      nixosModules.efs-utils = {
        imports = [ ./efs-utils/module.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}