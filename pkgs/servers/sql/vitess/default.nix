{ lib
, buildGoModule
, fetchFromGitHub
, go_1_17
}:

let
  name = "vitess";
  version = "12.0.0";
in
buildGoModule {
  pname = name;
  inherit version;

  src = fetchFromGitHub {
    owner = "vitessio";
    repo = name;
    rev = "v${version}";
    sha256 = "mH5zPv0p5+JcvIyU8rdU7bgvO+GghMGugd4hYUP1dME=";
  };

  vendorSha256 = "oq9xmVEwbUXZEdUoP6URC0kWdQdKjSP+rm/ucJ3ZaMg=";

  goPackage = go_1_17;

  meta = with lib; {
    description = "Vitess is a database clustering system for horizontal scaling of MySQL";
    homepage = "https://vitess.io/";
    license = licenses.asl20;
    maintainers = with maintainers; [ alexnortung ];
    platforms = [ "x86_64-linux" ];
  };
}
