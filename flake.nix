{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
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
          ${system}.default =
            pkgs.mkShell { buildInputs = with pkgs; [ (tex pkgs) emacs-nox ]; };
        };
      mkdoc = system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          ${system}.default = pkgs.stdenvNoCC.mkDerivation {
            name = "resume";
            src = ./.;
            nativeBuildInputs = with pkgs; [ (tex pkgs) emacs-nox ];
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = with pkgs; [ noto-fonts ];
            };
            buildPhase = builtins.readFile ./build.sh;
            installPhase = ''
              mkdir -p $out
              echo $out
              cp resume.{tex,pdf} $out/
            '';
          };
        };
      container = let pkgs = import nixpkgs { system = "x86_64-linux"; };
      in pkgs.dockerTools.buildImage {
        name = "resume-builder";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "resume-builder";
          paths = with pkgs; [
            (tex pkgs)
            emacs-nox
            # not needed by us but makes github happy
            coreutils
          ];
          pathsToLink = [ "/share" "/bin" ];
        };
      };
    in {
      devShells = nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs { }
        (map mkshell supportedSystems);
      packages = nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs { }
        (map mkdoc supportedSystems);
      inherit container;

      pushImage = let
        f = system:
          let pkgs = import nixpkgs { inherit system; };
          in {
            ${system} = pkgs.writeShellScriptBin "push-image" ''
              set -euo pipefail
              ${pkgs.skopeo}/bin/skopeo copy \
                --dest-creds $DOCKER_USERNAME:$DOCKER_PASSWORD \
                --dest-tls-verify=false \
                --insecure-policy \
                docker-archive://${container} \
                docker://docker.io/kero18/resume-builder:latest
            '';
          };
      in nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs { } (map f supportedSystems);
    };
}
