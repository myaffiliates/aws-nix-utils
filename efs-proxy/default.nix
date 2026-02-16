{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub, runCommand }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
  
  # Patch source to downgrade aws-lc-rs to avoid aws-lc-fips-sys
  patched-src = runCommand "efs-proxy-src-patched" {} ''
    cp -r ${efs-utils_src}/src/proxy $out
    chmod -R +w $out
    
    # Downgrade aws-lc-rs to 1.9.0 which doesn't have aws-lc-fips-sys dependency
    sed -i 's/aws-lc-rs = { version = "1.11.0", features = \["fips"\] }/aws-lc-rs = "1.9.0"/g' $out/Cargo.toml
    
    # Update Cargo.lock to change aws-lc-rs from 1.11.0 to 1.9.0
    sed -i 's/name = "aws-lc-rs"[[:space:]]*\nversion = "1.11.0"/name = "aws-lc-rs"\nversion = "1.9.0"/g' $out/Cargo.lock
    
    # Remove aws-lc-fips-sys package entry from Cargo.lock
    # This is a multi-line block, so we use awk
    awk '
      BEGIN { skip = 0 }
      /^\[\[package\]\]$/ { 
        # Start capturing the package block
        block = $0 "\n"
        in_package = 1
        next
      }
      in_package {
        block = block $0 "\n"
        if (/^name = "aws-lc-fips-sys"/) {
          skip = 1
        }
        if (/^$/ || /^\[\[/) {
          # End of package block
          if (!skip) {
            printf "%s", block
          }
          skip = 0
          in_package = 0
          block = ""
          if (/^\[\[/) {
            # This is the start of next package
            block = $0 "\n"
            in_package = 1
          }
        }
        next
      }
      { print }
    ' $out/Cargo.lock > $out/Cargo.lock.tmp && mv $out/Cargo.lock.tmp $out/Cargo.lock
  '';
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.4.1";
  src = patched-src;
  
  cargoHash = "sha256-2oP0rlSdzIcffl5PNuGKwr5vQLhn6IPvTTOTfw8yWdA=";

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

  doCheck = false;
}