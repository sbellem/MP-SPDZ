{ sources ? import ./sources.nix, pkgs ? import sources.nixpkgs { }}:
with pkgs;

let
  # TODO look into using cleanSource, etc to reduce the size of src
  # refs:
  #   https://github.com/NixOS/nix/issues/358
  #   https://github.com/NixOS/nixpkgs/blob/943c10325bbb8cc49fc17d08d1ce190606d44c33/lib/sources.nix#L29-L51
  #   https://stackoverflow.com/questions/39372157/how-to-use-nix-shell-properly-and-avoid-dumping-very-large-path/39493330#39493330
  #src = if lib.inNixShell then null else ../.;
  src = builtins.filterSource (p: t: lib.cleanSourceFilter p t && baseNameOf p != "mpir") ../.;
  #ntl105 = import ./ntl.nix { inherit stdenv lib fetchurl perl gmp gf2x; };
in
  stdenvNoCC.mkDerivation {
    inherit src;
    name = "paper-example";
    dontConfigure = true;
    # Set CONFIG.mine, to be sure the config is as expected for this build.
    # Add additional config below, e.g.:
    #
    # preBuild = ''
    #   echo USE_NTL = 1 > CONFIG.mine
    #   echo MY_CFLAGS += -DVERBOSE >> CONFIG.mine
    #   echo MY_CFLAGS += -DDEBUG_NETWORKING >> CONFIG.mine
    #   echo MY_CFLAGS += -DDEBUG_MAC >> CONFIG.mine
    #   echo MY_CFLAGS += -DDEBUG_FILE >> CONFIG.mine
    # '';
    #
    # NOTE NTL is required
    preBuild = ''
      echo USE_NTL = 1 > CONFIG.mine
    '';
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
      ntl
      openssl
      perl
      texinfo
      which
      yasm
      #ntl105
    ];
    buildFlags = ["paper-example.x"];
    installPhase = ''
      mkdir -p $out
      cp paper-example.x $out/paper-example.x
      '';
    dontFixup = true;
}
