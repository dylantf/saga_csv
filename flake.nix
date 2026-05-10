{
  description = "sesh-importer polyglot dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # saga.url = "github:dylantf/saga";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      # saga,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # For building the rust NIF
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            openssl

            erlang
            rebar3

            # saga.packages.${system}.default
          ];

          shellHook = ''
            export RUST_SRC_PATH="${pkgs.rustPlatform.rustLibSrc}"
            echo "sesh-importer dev shell"
          '';
        };
      }
    );
}
