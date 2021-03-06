{ stdenv, libsodium, fetchFromGitHub, wget, pkgconfig, autoreconfHook, openssl, db62, boost
, zlib, gtest, gmock, callPackage, gmp, qt4, utillinux, protobuf, qrencode, libevent
, withGui }:

let libsnark     = callPackage ./libsnark { inherit boost openssl; };
    librustzcash = callPackage ./librustzcash {};
in
with stdenv.lib;
stdenv.mkDerivation rec {

  name = "zcash" + (toString (optional (!withGui) "d")) + "-" + version;
  version = "1.0.11";

  src = fetchFromGitHub {
    owner = "zcash";
    repo  = "zcash";
    rev = "v${version}";
    sha256 = "09474jdhsg30maqrwfxigbw3llqi8axhh82lz3a23ii2gj68ni55";
  };

  enableParallelBuilding = true;

  buildInputs = [ pkgconfig gtest gmock gmp libsnark autoreconfHook openssl wget db62 boost zlib
                  protobuf libevent libsodium librustzcash ]
                  ++ optionals stdenv.isLinux [ utillinux ]
                  ++ optionals withGui [ qt4 qrencode ];

  configureFlags = [ "LIBSNARK_INCDIR=${libsnark}/include/libsnark"
                     "--with-boost-libdir=${boost.out}/lib"
                   ] ++ optionals withGui [ "--with-gui=qt4" ];

  patchPhase = ''
    sed -i"" '/^\[LIBSNARK_INCDIR/d'               configure.ac
    sed -i"" 's,-lboost_system-mt,-lboost_system,' configure.ac
    sed -i"" 's,-fvisibility=hidden,,g'            src/Makefile.am
  '';

  postInstall = ''
    cp zcutil/fetch-params.sh $out/bin/zcash-fetch-params
  '';

  meta = {
    description = "Peer-to-peer, anonymous electronic cash system";
    homepage = https://z.cash/;
    maintainers = with maintainers; [ rht ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
