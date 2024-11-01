{ lib, stdenv, pkgs, fetchFromGitHub }:

with pkgs.python3Packages;
buildPythonApplication rec {
  pname = "efs-utils";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "efs-utils";
    rev = "v${version}";
    sha256 = "sha256-ijicIxyYAYRrE3gip3b70kJwarnr/TSpsgkHH/tvM6o=";
  };
  buildInputs = [ botocore mock pytest ];

  propagatedBuildInputs = [ pkgs.stunnel pkgs.openssl pkgs.systemd pkgs.which pkgs.nfs-utils pkgs.coreutils-full ];

  format = "other";

  patchPhase = ''
    sed -i -e 's|"/sbin:/usr/sbin:/usr/local/sbin:/root/bin:/usr/local/bin:/usr/bin:/bin"|"${lib.makeBinPath propagatedBuildInputs}"|; s|/sbin/mount|${pkgs.nfs-utils}/bin/mount|; s|/var/run/|/run/|' src/mount_efs/__init__.py
    sed -i -e 's|"/sbin:/usr/sbin:/usr/local/sbin:/root/bin:/usr/local/bin:/usr/bin:/bin"|"${lib.makeBinPath propagatedBuildInputs}"|; s|/sbin/mount|${pkgs.nfs-utils}/bin/mount|; s|/var/run/|/run/|' src/watchdog/__init__.py
  '';
  buildPhase = "";

  installPhase = ''
    mkdir -p $out/etc
    mkdir -p $out/sbin
    mkdir -p $out/man
    cp dist/efs-utils.conf $out/etc
    cp dist/efs-utils.crt $out/etc

    cp src/mount_efs/__init__.py $out/sbin/mount.efs
    cp src/watchdog/__init__.py $out/sbin/amazon-efs-mount-watchdog

    mkdir -p $out/man
    cp  man/mount.efs.8 $out/man
  '';

  meta = with lib; {
    description = "Utilities for Amazon Elastic File System";
    homepage = "https://github.com/aws/efs-utils";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
