# Copied and adapted from:
# https://github.com/NixOS/nixpkgs/blob/58edcdc6baba122cfb1c04c6ba6680486c28adfa/pkgs/development/libraries/ntl/default.nix
{ stdenv
, lib
, fetchurl
, perl
, gmp
, gf2x ? null
# I asked the ntl maintainer weather or not to include gf2x by default:
# > If I remember correctly, gf2x is now thread safe, so there's no reason not to use it.
, withGf2x ? true
, tune ? false # tune for current system; non reproducible and time consuming
}:

assert withGf2x -> gf2x != null;

stdenv.mkDerivation rec {
  pname = "ntl";
  version = "10.5.0";

  src = fetchurl {
    url = "https://www.shoup.net/ntl/ntl-${version}.tar.gz";
    sha256 = "1lmldaldgfr2b2a6585m3np5ds8bq1bis2s1ajycjm49vp4kc2xr";
  };

  buildInputs = [
    gmp
  ];

  nativeBuildInputs = [
    perl # needed for ./configure
  ];

  sourceRoot = "${pname}-${version}/src";

  enableParallelBuilding = true;

  dontAddPrefix = true; # DEF_PREFIX instead

  configureFlags = [
    "DEF_PREFIX=$(out)"
    "SHARED=on" # genereate a shared library (as well as static)
    "NATIVE=off" # don't target code to current hardware (reproducibility, portability)
    "TUNE=${
      if tune then
        "auto"
      else if stdenv.targetPlatform.isx86 then
        "x86" # "chooses options that should be well suited for most x86 platforms"
      else
        "generic" # "chooses options that should be OK for most platforms"
    }"
    "CXX=c++"

  ] ++ lib.optionals withGf2x [
    "NTL_GF2X_LIB=on"
    "GF2X_PREFIX=${gf2x}"
  ];
  
  doCheck = true; # takes some time

  meta = with lib; {
    description = "A Library for doing Number Theory";
    longDescription = ''
      NTL is a high-performance, portable C++ library providing data
      structures and algorithms for manipulating signed, arbitrary
      length integers, and for vectors, matrices, and polynomials over
      the integers and over finite fields.
    '';
    # Upstream contact: maintainer is victorshoup on GitHub. Alternatively the
    # email listed on the homepage.
    homepage = "http://www.shoup.net/ntl/";
    # also locally at "${src}/doc/tour-changes.html";
    changelog = "https://www.shoup.net/ntl/doc/tour-changes.html";
    maintainers = with maintainers; [ timokau ];
    license = licenses.gpl2Plus;
    platforms = platforms.all;
  };
}
