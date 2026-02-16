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

  # On x86_64, stub out the aws-lc-fips-sys build after cargo vendor
  # aws-lc-fips-sys 0.13.9 fails with glibc 2.40+ / GCC 14+ on x86_64
  postUnpack = lib.optionalString stdenv.hostPlatform.isx86_64 ''
    echo "=== Patching aws-lc-fips-sys build.rs to stub FIPS ==="
    find $sourceRoot -name "aws-lc-fips-sys-*/build.rs" -type f | while read buildrs; do
      echo "Found: $buildrs"
      cat > "$buildrs" << 'BUILDRS'
fn main() {
    println!("cargo:warning=aws-lc-fips-sys FIPS build disabled on x86_64 (glibc 2.40+ incompatibility)");
    
    // Stub out the build entirely - aws-lc-rs will build without FIPS on x86_64
    println!("cargo:rustc-cfg=aws_lc_fips_sys_stub");
}
BUILDRS
    done
  '';

  # Remove FIPS feature from efs-proxy on x86_64
  postPatch = lib.optionalString stdenv.hostPlatform.isx86_64 ''
    substituteInPlace Cargo.toml \
      --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                'aws-lc-rs = { version = "1.11.0" }'
  '';

  # Work around aws-lc-fips-sys build issues on x86_64
  hardeningDisable = lib.optionals stdenv.hostPlatform.isx86_64 [ "fortify" ];

  doCheck = false;
}