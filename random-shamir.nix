{ sources ? import ./nix/sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  src = builtins.path {
    path = ./.;
  };
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
      mkdir -p $out/bin $out/lib
      cp random-shamir.x $out/bin/
      cp libSPDZ.so $out/lib/
    '';
    dontFixup = true;
}
