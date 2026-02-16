{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.4.1";
  src = efs-utils_src + "/src/proxy";
  
  cargoLock = { lockFile = src + "/Cargo.lock"; };

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.go
    pkgs.cmakeMinimal
    pkgs.perl
  ];

  buildInputs = [
    pkgs.openssl
  ];

  OPENSSL_DIR = pkgs.openssl.dev;
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";

  # Disable hardening on all platforms - aws-lc-fips-sys fails with fortify
  hardeningDisable = [ "fortify" "format" ];

  # Suppress compilation errors from aws-lc on x86_64
  CFLAGS = lib.optionalString stdenv.hostPlatform.isx86_64 
    "-Wno-error=stringop-overflow -Wno-stringop-overflow -Wno-error";

  CXXFLAGS = lib.optionalString stdenv.hostPlatform.isx86_64
    "-Wno-error=stringop-overflow -Wno-stringop-overflow -Wno-error";

  doCheck = false;
}