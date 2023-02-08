{ lib, stdenv, pkgs, fetchFromGitHub, buildGoModule, ... }:

let
  pname = "ssm-helpers";
  version = "1.2.0";
in
buildGoModule {
  pname = pname;
  version = version;

  src = fetchFromGitHub {
    owner = "disneystreaming";
    repo = "ssm-helpers";
    rev = "v${version}";
    sha256 = "sha256-/Fg5ooKiFiZD7aVY8jU5oVnscKcQy5OOWp0q1Woag94=";
  };

  patches = [ ./env-creds.diff ];

  vendorHash = "sha256-PI7ukhLuEqYtFp1MlWwgbq0oAt02Z/D2oGhAtXclTGc=";
  doCheck = false;

  meta = with lib; {
    description = "Help manage AWS systems manager with helpers";
    homepage = "https://github.com/disneystreaming/ssm-helpers";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
