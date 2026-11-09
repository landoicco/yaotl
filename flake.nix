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
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          # luacheck and stylua are pinned here so CI runs the same versions
          packages = [ pkgs.love pkgs.gh pkgs.luajitPackages.luacheck pkgs.stylua ];
          shellHook = ''
            echo "Yaotl dev shell"
            echo "💘 love ${pkgs.love.version}"
            echo "🐙 gh ${pkgs.gh.version}"
            echo "🔍 luacheck ${pkgs.luajitPackages.luacheck.version}"
            echo "🎨 stylua ${pkgs.stylua.version}"
            echo "Run the game with: love ."
            echo "Check the code with: luacheck . && stylua --check ."
          '';
        };
      });
    };
}
