{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub, runCommand }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
  
  # On x86_64, patch source to remove FIPS dependency
  src = if stdenv.hostPlatform.isx86_64 then
    runCommand "efs-proxy-patched" {} ''
      cp -r ${efs-utils_src}/src/proxy $out
      chmod -R +w $out
      
      # Remove FIPS feature from aws-lc-rs
      substituteInPlace $out/Cargo.toml \
        --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                  'aws-lc-rs = { version = "1.11.0" }'
    ''
  else
    efs-utils_src + "/src/proxy";
in

pkgs.rustPlatform.buildRustPackage rec {
  pname = "efs-proxy";
  version = "2.4.1";
  inherit src;
  
  # Use cargoHash for x86_64 (patched), cargoLock for others
  ${if stdenv.hostPlatform.isx86_64 then "cargoHash" else "cargoLock"} = 
    if stdenv.hostPlatform.isx86_64 
    then "sha256-gOJmZ0CDvdgnJxLtXyTwWm0zLEPUGgEO/8D8YPHegSw="
    else { lockFile = src + "/Cargo.lock"; };

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
  hardeningDisable = lib.optionals stdenv.hostPlatform.isx86_64 [ "fortify" ];

  doCheck = false;
}