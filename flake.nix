{
  description = "AWS utilities for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
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
        efs-proxy =
          let
            base = final.callPackage ./efs-proxy/default.nix { };
          in
          if final.stdenv.hostPlatform.system == "x86_64-linux" then
            base.overrideAttrs (old: {
              NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "")
                + " -Wno-error=stringop-overflow -Wno-stringop-overflow"
                + " -Wno-error=array-bounds -Wno-array-bounds"
                + " -Wno-error";
              CMAKE_ARGS = (old.CMAKE_ARGS or "") + " -DOPENSSL_NO_ASM=1";
              AWS_LC_FIPS_SYS_CMAKE_ARGS = (old.AWS_LC_FIPS_SYS_CMAKE_ARGS or "")
                + " -DOPENSSL_NO_ASM=1";
              hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "fortify" ];
            })
          else 
            base.overrideAttrs (old: {
              NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "")
                + " -Wno-error=stringop-overflow";
              hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "fortify" ];
            });
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
