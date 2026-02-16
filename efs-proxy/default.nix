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
    pkgs.clang
  ];

  buildInputs = [
    pkgs.openssl
  ];

  OPENSSL_DIR = pkgs.openssl.dev;
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";

  # Disable hardening - aws-lc-fips-sys fails with fortify enabled
  hardeningDisable = [ "fortify" "format" ];

  # Use clang instead of GCC for aws-lc-fips-sys
  # GCC 14+ has issues with FIPS module compilation
  # See: https://github.com/aws/aws-lc-rs/issues/569
  CC = "${pkgs.clang}/bin/clang";
  
  # Tell aws-lc-fips-sys to use clang
  AWS_LC_FIPS_SYS_CC = "${pkgs.clang}/bin/clang";

  # Remove FIPS feature from efs-proxy Cargo.toml
  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                'aws-lc-rs = { version = "1.11.0" }'
  '';

  doCheck = false;
}