let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
  ntl105 = with pkgs; import ./nix/ntl.nix { inherit stdenv lib fetchurl perl gmp; };
in with pkgs;
mkShell {
  inherit ntl105;
  buildInputs = [
    autoconf
    automake
    boost
    clang-tools
    gnum4
    libsodium
    libtool
    mpir
    ntl105
    openssl
    perl
    python3
    texinfo
    which
    yasm
  ];
}
