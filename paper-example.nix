{ sources ? import ./nix/sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  src = ./.;
  ntl105 = import ./nix/ntl.nix { inherit stdenv lib fetchurl perl gmp; };
in
  stdenvNoCC.mkDerivation {
    inherit src;
    name = "paper-example";
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
      ntl105
    ];
    buildFlags = ["paper-example.x"];
    postBuild = ''
      bash Scripts/setup-ssl.sh 2
    '';
    installPhase = ''
      mkdir -p $out
      cp paper-example.x $out/paper-example.x
      '';
    dontFixup = true;
}
