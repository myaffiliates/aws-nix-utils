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

  # Disable hardening - aws-lc-fips-sys fails with fortify enabled
  hardeningDisable = [ "fortify" "format" ];

  # Pass flags to CMake to suppress errors for aws-lc build
  # The cmake crate respects CFLAGS/CXXFLAGS environment variables
  CFLAGS = "-Wno-error -Wno-stringop-overflow -Wno-array-bounds";
  CXXFLAGS = "-Wno-error -Wno-stringop-overflow -Wno-array-bounds";
  
  # Also try passing to CMAKE directly
  CMAKE_C_FLAGS = "-Wno-error -Wno-stringop-overflow -Wno-array-bounds";
  CMAKE_CXX_FLAGS = "-Wno-error -Wno-stringop-overflow -Wno-array-bounds";

  doCheck = false;
}