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
  
  # Patch Cargo.toml on x86_64 to remove FIPS feature
  # aws-lc-fips-sys 0.13.9 fails with glibc 2.40+ / GCC 14+
  postPatch = lib.optionalString stdenv.hostPlatform.isx86_64 ''
    substituteInPlace Cargo.toml \
      --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                'aws-lc-rs = { version = "1.11.0" }'
  '';
  
  # Use cargoHash for x86_64 (patched), cargoLock for others
  ${if stdenv.hostPlatform.isx86_64 then "cargoHash" else "cargoLock"} = 
    if stdenv.hostPlatform.isx86_64 
    then "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
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