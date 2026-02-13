{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
in

pkgs.rustPlatform.buildRustPackage (rec {
  pname = "efs-proxy";
  version = "2.4.1";
  src = efs-utils_src + "/src/proxy";
  cargoLock.lockFile = src + "/Cargo.lock";

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

  # Work around aws-lc-fips-sys build issues on x86_64
  NIX_CFLAGS_COMPILE = if stdenv.hostPlatform.isx86_64 then 
    "-Wno-error=array-bounds -Wno-error=stringop-overflow -Wno-error -Wno-array-bounds -Wno-stringop-overflow" 
    else "";
  
  hardeningDisable = if stdenv.hostPlatform.isx86_64 then [ "fortify" ] else [];
  
  # Set CMAKE flags for aws-lc-fips-sys build
  AWS_LC_FIPS_SYS_CMAKE_BUILDER_VERBOSE = if stdenv.hostPlatform.isx86_64 then "1" else null;
  CFLAGS = if stdenv.hostPlatform.isx86_64 then 
    "-Wno-error=array-bounds -Wno-error=stringop-overflow -Wno-error" 
    else null;

  doCheck = false;
})