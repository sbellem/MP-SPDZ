{ sources ? import ./nix/sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  src = ./.;
in
  stdenvNoCC.mkDerivation {
    inherit src;
    name = "random-shamir";
    dontConfigure = true;
    buildInputs = [
      autoconf
      automake
      boost
      clang-tools
      gcc9
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
    buildFlags = ["random-shamir.x"];
    installPhase = ''
      mkdir -p $out
      cp random-shamir.x $out/random-shamir.x
      '';
    dontFixup = true;
}
