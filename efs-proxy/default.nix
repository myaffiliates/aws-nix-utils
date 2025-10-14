{ lib, stdenv, pkgs, fetchFromGitHub }:
let
  manifest = (pkgs.lib.importTOML ${src}/src/proxy/Cargo.toml).package;
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = manifest.name;
  version = manifest.version;
  src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v${version}";
    sha256 = "sha256-OIf5GZt8pVPQDQ89mFa1e165e65N1X307D9HQ23fASQ=";
  };
  cargoLock.lockFile = ${src}/src/proxy/Cargo.lock;
}