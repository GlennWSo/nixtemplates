{
  description = "flake for rust dev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    crane,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {inherit system overlays;};
        rust =
          pkgs.rust-bin.selectLatestNightlyWith
          (toolchain:
            toolchain.default.override {
              extensions = ["rust-src"];
              targets = [];
            });
        craneLib = (crane.mkLib pkgs).overrideToolchain (_p: rust);

        commonRust = {
          src = craneLib.cleanCargoSource ./.;
          buildInputs = with pkgs; [
            # Add extra build inputs here, etc.
            # openssl
            pkgs.ripgrep
          ];
          nativeBuildInputs = with pkgs; [
            # Add extra native build inputs here, etc.
            # pkg-config
          ];
          # Build *just* the cargo dependencies, so we can reuse
          # all of that work (e.g. via cachix) when running in CI
        };
        cargoArtifacts = craneLib.buildDepsOnly (commonRust
          // {
            # Additional arguments specific to this derivation can be added here.
            # Be warned that using `//` will not do a deep copy of nested
            # structures
            pname = "mycrate-deps";
          });
      in rec {
        packages.default = packages.hello;
        devShells.default = craneLib.devShell {
          inputsFrom = [packages.hello];
        };
        packages.hello = craneLib.buildPackage (commonRust
          // {
            inherit cargoArtifacts;
          });
      }
    );
}
