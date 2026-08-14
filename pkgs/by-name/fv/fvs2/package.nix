{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
}:
let
  core = fetchFromGitHub {
    owner = "fvs-lab";
    repo = "core";
    tag = "v0.1.2";
    hash = "sha256-vEQhV9wInqxgJlSyhgp0BV5VaYBJVtqcPrdN2NP33i4=";
  };
in
buildGoModule (finalAttrs: {
  pname = "fvs2";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "fvs-lab";
    repo = "fvs2";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QUSAhHepM27ixwcbez0bSBRPMLXUpxjmfRYWJiAOH04=";
  };

  vendorHash = "sha256-9Zri8PkMZ7J5q2CxxOpOE0lrPmw1cSJjmvJurtWRnbM=";

  # Needed for build time tests
  nativeBuildInputs = [ git ];

  preBuild = ''
    cp -r ${core} ../core
  '';

  __structuredAttrs = true;

  meta = {
    description = "Standalone CLI for FVS v2";
    homepage = "https://github.com/fvs-lab/fvs2";
    license = lib.licenses.mit;
    mainProgram = "fvs2";
    maintainers = [ lib.maintainers.Gliczy ];
    platforms = lib.platforms.linux;
  };
})
