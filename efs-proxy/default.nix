{ lib, stdenv, pkgs, pkg-config, fetchFromGitHub, writeTextFile }:

let
  efs-utils_src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v2.4.1";
    sha256 = "sha256-3GfrBY9h0ALwn9E2LwfxKgT8QdMoiBRGgzFZQN3ujKQ=";
  };
  
  # Stub build script for aws-lc-fips-sys on x86_64
  aws-lc-fips-sys-stub-build = writeTextFile {
    name = "aws-lc-fips-sys-build-stub.rs";
    text = ''
fn main() {
    // FIPS module build disabled on x86_64 due to glibc 2.40+ / GCC 14+ incompatibility
    // The delocator tool fails with: ".data section found in module"
    println!("cargo:warning=aws-lc-fips-sys: FIPS module build disabled");
}
    '';
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

  # On x86_64: patch source BEFORE cargo vendors dependencies
  # This ensures aws-lc-fips-sys has a stubbed build.rs in the vendor dir
  postUnpack = lib.optionalString stdenv.hostPlatform.isx86_64 ''
    echo "Patching aws-lc-fips-sys for x86_64"
    if find "$sourceRoot" -path "*/aws-lc-fips-sys-*/build.rs" | grep -q .; then
      cp ${aws-lc-fips-sys-stub-build} "$(find "$sourceRoot" -path "*/aws-lc-fips-sys-*/build.rs" | head -1)"
    fi
    
    # Also patch Cargo.toml to remove fips feature
    substituteInPlace $sourceRoot/Cargo.toml \
      --replace 'aws-lc-rs = { version = "1.11.0", features = ["fips"] }' \
                'aws-lc-rs = { version = "1.11.0" }'
  '';

  doCheck = false;
}