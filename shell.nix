let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    autoconf
    automake
    boost
    clang-tools
    gnum4
    libsodium
    libtool
    mpir
    openssl
    perl
    texinfo
    which
    yasm
  ];
}
