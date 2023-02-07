{
  description = "AWS utilities for Nix";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      overlay = self: super: { };
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
      };
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsForSystem system;
          in
          {
            ssh-helpers = pkgs.ssm-helpers;
            default = pkgs.ssm-helpers;
          });
    };
}
