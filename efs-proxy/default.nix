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

  # Patch aws-lc-fips-sys CMakeLists.txt to remove -Werror before cargo vendors
  postUnpack = ''
    echo "Patching aws-lc-fips-sys to remove -Werror..."
    
    # Find and patch aws-lc-fips-sys CMakeLists.txt files
    find "$sourceRoot" -path "*/aws-lc-fips-sys-*/aws-lc/CMakeLists.txt" -type f | while read cmakelists; do
      echo "Patching: $cmakelists"
      sed -i 's/-Werror//g' "$cmakelists"
    done
    
    # Also patch any CMakeLists.txt that might have WARNINGS_AS_ERRORS
    find "$sourceRoot" -path "*/aws-lc-fips-sys-*/CMakeLists.txt" -type f | while read cmakelists; do
      echo "Patching: $cmakelists"
      sed -i 's/-Werror//g; s/WARNINGS_AS_ERRORS.*ON/WARNINGS_AS_ERRORS OFF/g' "$cmakelists"
    done
  '';

  doCheck = false;
}