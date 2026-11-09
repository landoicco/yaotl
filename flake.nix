{
  description = "Zombies in Love - LÖVE2D game";

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
          packages = [ pkgs.love pkgs.gh ];
          shellHook = ''
            echo "Zombies in Love dev shell"
            echo "💘 love ${pkgs.love.version}"
            echo "🐙 gh ${pkgs.gh.version}"
            echo "Run the game with: love ."
          '';
        };
      });
    };
}
