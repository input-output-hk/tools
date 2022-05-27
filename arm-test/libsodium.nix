{ stdenv, lib, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "libsodium-1.0.18";

  src = fetchFromGitHub {
    owner = "input-output-hk";
    repo = "libsodium";
    rev = "11bb20dba02b013bf1d83e3c16c51eab2ff07efc";
    sha256 = "1h9fcwra610vmh0inkdkqs3bfs83xl5dk146dqx440wwh9pn4n4w";
  };

  nativeBuildInputs = [ autoreconfHook ];

  configureFlags = "--enable-static --disable-shared --disable-pie --disable-ssp";

  outputs = [ "out" "dev" ];

  hardeningEnable = [ "pic" ];
  hardeningDisable = [ "pie" "stackprotector" ];


  # separateDebugInfo = stdenv.isLinux && stdenv.hostPlatform.libc != "musl";

  enableParallelBuilding = true;

  doCheck = true;

  meta = with lib; {
    description = "A modern and easy-to-use crypto library";
    homepage = "http://doc.libsodium.org/";
    license = licenses.isc;
    maintainers = [ "tdammers" "nclarke" ];
    platforms = platforms.all;
  };
}
