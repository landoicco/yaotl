{
  description = "Yaotl - LÖVE2D game";

  # Uses the nixpkgs already registered on your system, avoiding a new download
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: rec {
        # Only the checks, so CI does not download the editors
        # luacheck and stylua are pinned here so CI runs the same versions
        lint = pkgs.mkShellNoCC {
          packages = [ pkgs.luajitPackages.luacheck pkgs.stylua ];
        };

        default = pkgs.mkShellNoCC {
          inputsFrom = [ lint ];
          packages = [ pkgs.love pkgs.gh pkgs.tiled pkgs.imagemagick ];
          shellHook = ''
            echo ""
            echo "━━━━━━━━━━━━━━ 🧟 Yaotl dev shell ━━━━━━━━━━━━━━"
            echo ""
            echo "  Dev"
            echo "    💘 love         ${pkgs.love.version}"
            echo "    🐙 gh           ${pkgs.gh.version}"
            echo "    🗺️  tiled        ${pkgs.tiled.version}"
            echo "    🖼️  imagemagick  ${pkgs.imagemagick.version}"
            echo ""
            echo "  Lint (also in CI, via .#lint)"
            echo "    🔍 luacheck     ${pkgs.luajitPackages.luacheck.version}"
            echo "    🎨 stylua       ${pkgs.stylua.version}"
            echo ""
            echo "  Commands"
            echo "    love .                            run the game"
            echo "    luacheck . && stylua --check .    check the code"
            echo "    tiled maps/sandbox.tmx            edit the sandbox map"
            echo ""
          '';
        };
      });
    };
}
