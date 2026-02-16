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
    pkgs.cmake
    pkgs.perl
  ];

  buildInputs = [
    pkgs.openssl
  ];

  OPENSSL_DIR = pkgs.openssl.dev;
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";

  # Disable hardening
  hardeningDisable = [ "fortify" ];

  # Remove FIPS feature and aws-lc-fips-sys dependency
  # aws-lc-fips-sys 0.13.9 has compilation issues with modern toolchains
  postPatch = ''
    # Remove fips feature flag from aws-lc-rs dependency
    sed -i 's/aws-lc-rs = { version = "1.11.0", features = \["fips"\] }/aws-lc-rs = { version = "1.11.0" }/g' Cargo.toml
    
    # Remove aws-lc-fips-sys entries from Cargo.lock entirely
    # Use awk to remove package sections that have name = "aws-lc-fips-sys"
    awk '
      /^\[\[package\]\]$/ { in_package = 1; package_start = NR }
      in_package && /^name = "aws-lc-fips-sys"/ { skip_package = 1 }
      in_package && NR > package_start && /^\[\[package\]\]$/ { 
        in_package = 1; 
        package_start = NR; 
        skip_package = 0 
      }
      !skip_package { print }
      /^$/ && skip_package { skip_package = 0 }
    ' Cargo.lock > Cargo.lock.tmp && mv Cargo.lock.tmp Cargo.lock
  '';

  doCheck = false;
}