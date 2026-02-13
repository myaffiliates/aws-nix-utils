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

  doCheck = false;
} // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
  OPENSSL_NO_ASM = "1";
  AWS_LC_FIPS_SYS_NO_ASM = "1";
  AWS_LC_SYS_NO_ASM = "1";
  AWS_LC_FIPS_SYS_CMAKE_ARGS = "-DOPENSSL_NO_ASM=1 -DMY_ASSEMBLER_IS_TOO_OLD_FOR_AVX=1 -DMY_ASSEMBLER_IS_TOO_OLD_FOR_512AVX=1";
  AWS_LC_SYS_CMAKE_ARGS = "-DOPENSSL_NO_ASM=1 -DMY_ASSEMBLER_IS_TOO_OLD_FOR_AVX=1 -DMY_ASSEMBLER_IS_TOO_OLD_FOR_512AVX=1";
})