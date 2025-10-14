{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.3.3";
    sha256 = "sha256-OIf5GZt8pVPQDQ89mFa1e165e65N1X307D9HQ23fASQ=";
  };
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.3.3";
  src = efs-utils_src + "/src/proxy";
  cargoLock.lockFile = src + "/Cargo.lock";
  nativeBuildInputs = [ pkgs.pkg-config pkgs.openssl.dev pkgs.libssh.dev ];
}