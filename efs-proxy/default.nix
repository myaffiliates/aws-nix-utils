{ lib, stdenv, pkgs, fetchFromGitHub }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.3.3";
  src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v${version}";
    sha256 = "sha256-OIf5GZt8pVPQDQ89mFa1e165e65N1X307D9HQ23fASQ=";
  };
  cargoLock.lockFile = ${src}/src/proxy/Cargo.lock;
}