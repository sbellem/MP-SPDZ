{
  description = "mp-spdz programs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        LIBCLANG_PATH = "${pkgs.llvmPackages_11.libclang.lib}/lib";

        mkPkg = {
          pname,
          version,
          cargoSha256,
          buildAndTestSubdir,
        }:
          pkgs.stdenv.mkDerivation {
            inherit LIBCLANG_PATH;

            pname = pname;
            version = version;

            src = builtins.path {
              path = ./.;
              name = "${pname}-${version}";
            };

            nativeBuildInputs = with pkgs; [
              clang_11
              llvmPackages_11.libclang.lib
            ];
          };

        # pkgs
        malicious-shamir-party = {
          pname = "malicious-shamir-party";
          version = "0.1.0dev";
        };
      in
        with pkgs; {
          packages.random-shamir = stdenv.mkDerivation rec {
            inherit LIBCLANG_PATH;

            pname = "random-shamir";
            version = "0.1.0dev";

            src = builtins.path {
              path = ./.;
              name = "${pname}-${version}";
            };

            nativeBuildInputs = with pkgs; [
              clang_11
              llvmPackages_11.libclang.lib
            ];
            dontConfigure = true;
            buildInputs = [
              autoconf
              automake
              boost
              clang-tools
              gcc9
              git
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
          };
          buildFlags = ["random-shamir.x"];
          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp random-shamir.x $out/bin/
            cp libSPDZ.so $out/lib/
          '';
          dontFixup = true;

          defaultPackage = self.packages.${system}.random-shamir;

          devShell = mkShell {
            inherit LIBCLANG_PATH;

            buildInputs = [
              autoconf
              automake
              boost
              clang_11
              diffoscope
              exa
              fd
              gcc
              gnum4
              libsodium
              libtool
              llvmPackages_11.libclang.lib
              mpir
              openssl
              perl
              pkg-config
              protobuf
              texinfo
              unixtools.whereis
              which
              yasm
            ];

            shellHook = ''
              alias ls=exa
              alias find=fd
            '';
          };
        }
    );
}
