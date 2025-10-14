{ lib, stdenv, pkgs, fetchFromGitHub }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.3.3";
    sha256 = "sha256-OIf5GZt8pVPQDQ89mFa1e165e65N1X307D9HQ23fASQ=";
  };
  src_file = efs-utils_src + "/src/proxy/Cargo.lock" // pkgs.lib.cleanSource ./.;
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.3.3";
  src = src_folder;
  cargoLock.lockFile = src_file;
}
