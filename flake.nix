{
  description = "Example of nix-x-cabal";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-x-cabal.url = "github:bglgwyng/nix-x-cabal";

    haskell-hackage-org-index = {
      url = "file+https://hackage.haskell.org/01-index.tar.gz";
      flake = false;
    };
    haskell-hackage-org-root = {
      url = "file+https://hackage.haskell.org/root.json";
      flake = false;
    };

    uwu = {
      url = "github:bglgwyng/uwu";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      imports = [
        inputs.nix-x-cabal.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = rest@{ config, self', inputs', pkgs, system, ... }:
        let
          haskellPackages = pkgs.haskell.packages.ghc9101;
          default-repositories = {
            "hackage.haskell.org" = {
              url = "http://hackage.haskell.org/";
              index = inputs.haskell-hackage-org-index;
              root = inputs.haskell-hackage-org-root;
            };
          };
        in
        {
          # https://github.com/bglgwyng/nix-x-cabal/issues/2
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (_: _: { testu01 = null; })
            ];
          };

          cabal-projects.example1 = {
            root = ./example1;
            inherit haskellPackages;
            repositories = default-repositories;
          };

          cabal-projects.example2 = {
            root = ./example2;
            inherit haskellPackages;
            repositories = default-repositories // {
              local.packages = [ inputs.uwu ];
            };
          };


          cabal-projects.example3 = {
            root = ./example3;
            inherit haskellPackages;
            repositories = default-repositories;
            extra-buildInputs = [ pkgs.pkg-config pkgs.xz ];
            packages-overlays = [
              (_: super: {
                zlib = super.zlib.override { zlib = pkgs.zlib; };
              })
            ];
          };

          packages.example1 = config.cabal-projects.example1.packages.example1;
          packages.example2 = config.cabal-projects.example2.packages.example2;
          packages.example3 = config.cabal-projects.example3.packages.example3;

          devShells.default = pkgs.mkShell {
            packages = with config.cabal-projects.example1; [ ghc cabal-install ];
          };
        };
    };
}
