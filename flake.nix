{
  description = "Rust MCP SDK development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Rust overlay（最新 Rust が必要な場合に便利）
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            pkg-config
            # Rust toolchain
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" ];
            })
          ];

          # Rust SDK と依存の Cargo ビルド用
          RUST_SRC_PATH = "${pkgs.rustPackages.rustc.src}";
        };

        # Package set（必要なら apps を定義）
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "rust-mcp-sdk-app";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs; [
            (rust-bin.stable.latest.default)
          ];

          cargoBuild = {
            release = false;
          };

          # ビルド/インストール手順
          buildPhase = ''
            export CARGO_HOME="$PWD/.cargo"
            mkdir -p $CARGO_HOME
            cargo build
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp target/debug/rust-mcp-sdk-app $out/bin/
          '';
        };
      }
    );
}

