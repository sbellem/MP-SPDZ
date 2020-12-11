{ sources ? import ./nix/sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  src = ./.;
in
  stdenvNoCC.mkDerivation {
    inherit src;
    name = "paper-example-shamir";
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
    buildFlags = ["paper-example-shamir.x"];
    postBuild = ''
      bash Scripts/setup-ssl.sh 3
    '';
    installPhase = ''
      mkdir -p $out
      cp paper-example-shamir.x $out/paper-example-shamir.x
      '';
    dontFixup = true;
}
