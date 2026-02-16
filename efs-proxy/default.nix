{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub, runCommand }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
  
  # Patch source to remove FIPS feature from aws-lc-rs
  patched-src = runCommand "efs-proxy-src-patched" {} ''
    cp -r ${efs-utils_src}/src/proxy $out
    chmod -R +w $out
    
    # Downgrade aws-lc-rs to 1.9.0 which doesn't have aws-lc-fips-sys dependency
    # Version 1.11.0 unconditionally depends on aws-lc-fips-sys even without fips feature
    sed -i 's/aws-lc-rs = { version = "1.11.0", features = \["fips"\] }/aws-lc-rs = "1.9.0"/g' $out/Cargo.toml
  '';
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.4.1";
  src = patched-src;
  
  cargoHash = "sha256-NNKsFcLIj6FefZBvxEvpLdK0jBknl/M7n4Y7qARhE10=";

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