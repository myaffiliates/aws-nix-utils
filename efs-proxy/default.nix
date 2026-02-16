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

  # Environment variables to bypass aws-lc-fips-sys FIPS module compilation
  # These are respected by aws-lc-fips-sys build.rs
  preBuild = ''
    export AWS_LC_FIPS_SYS_PREBUILT_NASM=1
    export AWS_LC_FIPS_SYS_NO_ASM=1  
  '';

  # Remove FIPS feature from efs-proxy Cargo.toml
  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                'aws-lc-rs = { version = "1.11.0" }'
  '';

  doCheck = false;
}