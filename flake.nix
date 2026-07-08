{
  description = "Jump Desktop (macOS viewer/client) — unofficial Nix package, auto-updated from upstream";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Upstream ships a single universal macOS .app; list both Apple archs.
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      lib = nixpkgs.lib;
      forSystems = lib.genAttrs systems;
      # Jump Desktop is proprietary; allow it to build without external env vars.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      overlays.default = final: _prev: {
        jump-desktop = final.callPackage ./pkgs/jump-desktop { };
      };

      packages = forSystems (
        system:
        let
          jump-desktop = (pkgsFor system).callPackage ./pkgs/jump-desktop { };
        in
        {
          inherit jump-desktop;
          default = jump-desktop;
        }
      );

      apps = forSystems (
        system:
        let
          pkgs = pkgsFor system;
          pkg = self.packages.${system}.jump-desktop;
          open = pkgs.writeShellScript "jump-desktop-open" ''
            exec /usr/bin/open "${pkg}/Applications/Jump Desktop.app" "$@"
          '';
        in
        {
          default = {
            type = "app";
            program = "${open}";
            meta.description = "Open Jump Desktop";
          };
        }
      );

      checks = forSystems (system: {
        build = self.packages.${system}.jump-desktop;
      });

      formatter = forSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
