{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
in

# aws-lc-fips-sys 0.13.9 has known build failures with modern toolchains
# See: https://github.com/aws/aws-lc-rs/issues/569
# Only build on platforms where it works
if stdenv.hostPlatform.isAarch64 then
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

    hardeningDisable = [ "fortify" ];

    doCheck = false;
  }
else
  # Stub package for unsupported platforms
  pkgs.runCommand "efs-proxy-unsupported" {} ''
    mkdir -p $out/bin
    cat > $out/bin/efs-proxy << 'EOF'
#!/bin/sh
echo "efs-proxy not available on this platform due to aws-lc-fips-sys build issues" >&2
exit 1
EOF
    chmod +x $out/bin/efs-proxy
  ''