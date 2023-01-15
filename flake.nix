{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      emacs = pkgs:
        with pkgs;
        ((emacsPackagesFor emacs-nox).emacsWithPackages
          (epkgs: with epkgs; [ org ]));
      tex = pkgs:
        (pkgs.texlive.combine {
          inherit (pkgs.texlive)
          # core
            scheme-basic xetex
            # packages
            enumitem etoolbox fontawesome5 parskip titlesec xcolor;
        });
      mkshell = system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          ${system}.default = pkgs.mkShell { buildInputs = [ (tex pkgs) ]; };
        };
      mkdoc = system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          ${system}.default = pkgs.stdenvNoCC.mkDerivation {
            name = "resume";
            src = ./.;
            nativeBuildInputs = [ (tex pkgs) ];
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = with pkgs; [ noto-fonts ];
            };
            buildPhase = ''
              ${emacs pkgs}/bin/emacs --batch -Q      \
                --visit helper.org --load init.el     \
                --visit resume.org                    \
                --eval '(org-latex-export-to-latex)'  \

              xelatex resume.tex -interaction=nonstopmode
              # latexmk                                 \
              #   -interaction=nonstopmode              \
              #   -pdf                                  \
              #   -xelatex                              \
              #   -outdir="$PWD"                        \
              #   resume.tex
            '';
            installPhase = ''
              mkdir -p $out
              echo $out
              cp resume.{tex,pdf} $out/
            '';
          };
        };
    in {
      devShells = nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs { }
        (map mkshell supportedSystems);
      packages = nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs { }
        (map mkdoc supportedSystems);
    };
}
