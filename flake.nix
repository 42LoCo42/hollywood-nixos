{
  outputs = { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        py = pkgs.python3.pkgs;
        inherit (pkgs.lib) makeBinPath;
        inherit (pkgs.lib.fileset) toSource unions;

        speedometer = py.buildPythonApplication rec {
          pname = "speedometer";
          version = "2.9-unstable-2024-03-28";

          src = pkgs.fetchFromGitHub {
            owner = "wardi";
            repo = pname;
            rev = "890df21b3a041a3ccb1594a68f913e03cf264955";
            hash = "sha256-mk/c0HFqpmWC+8IZkfN1vr3Jk0Ysar48a/Yr/5rpvk0=";
          };

          pyproject = true;

          build-system = with py; [
            setuptools
          ];

          dependencies = with py; [
            psutil
            setuptools # import pkg_resources at runtime
            urwid
          ];
        };

        hollywood = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "hollywood";
          version = "2.0";

          src = toSource {
            root = ./.;
            fileset = unions [
              ./bin
              ./lib
              ./share
            ];
          };

          nativeBuildInputs = with pkgs; [
            makeWrapper
          ];

          installPhase = ''
            cp -r $src $out
            chmod -R +w $out

            # TODO currently broken :(
            rm -rf $out/{bin,lib,share{,/man/man1}}/wallstreet*

            wrapProgram $out/bin/${pname} \
              --prefix PATH : ${makeBinPath deps}
          '';

          meta = {
            description = "Generate panes of technical melodrama";
            homepage = "https://a.hollywood.computer";
            mainProgram = pname;
          };
        };

        deps = with pkgs; with py; [
          # multiple
          ccze
          coreutils
          findutils
          procps # pkill
          tmux

          # lib/hollywood/<name>
          apg
          atop
          bmon
          cmatrix
          htop
          jp2a
          mplayer
          speedometer
          tree

          man-db # lib/hollywood/man
          moreutils # lib/hollywood/errno
          openssh # lib/hollywood/sshart
          pygments # lib/hollywood/code
          util-linux # lib/hollywood/hexdump
        ];
      in
      rec {
        packages = {
          inherit hollywood speedometer;
          default = hollywood;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ packages.default ];
          packages = deps;
        };
      });
}
