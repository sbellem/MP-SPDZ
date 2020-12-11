{ sources ? import ./nix/sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  # TODO look into using cleanSource, etc to reduce the size of src
  # refs:
  #   https://github.com/NixOS/nix/issues/358
  #   https://github.com/NixOS/nixpkgs/blob/943c10325bbb8cc49fc17d08d1ce190606d44c33/lib/sources.nix#L29-L51
  #   https://stackoverflow.com/questions/39372157/how-to-use-nix-shell-properly-and-avoid-dumping-very-large-path/39493330#39493330
  #src = ./.;
  src = if lib.inNixShell then null else ./.;
  # src = builtins.filterSource (p: t: lib.cleanSourceFilter p t && baseNameOf p != "mpir") ./.;
  ntl105 = import ./nix/ntl.nix { inherit stdenv lib fetchurl perl gmp; };
in
  stdenvNoCC.mkDerivation {
    inherit src;
    name = "paper-example";
    dontConfigure = true;
    # TODO Edit CONFIG.mine, to be sure the config is as expected for this build
    # preBuild = ''
    #   echo USE_NTL = 1 > CONFIG.mine
    #   echo MY_CFLAGS = ...
    # ''
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
    #postBuild = ''
    #  bash Scripts/setup-ssl.sh 2
    #'';
    installPhase = ''
      mkdir -p $out
      cp paper-example.x $out/paper-example.x
      '';
    dontFixup = true;
}
