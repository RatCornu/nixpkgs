{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  openssl,
  prisma_6,
  prisma-engines_6,
  nixosTests,
}:

buildNpmPackage rec {
  pname = "spliit";
  version = "1.19.1";

  src = fetchFromGitHub {
    owner = "spliit-app";
    repo = "spliit";
    tag = version;
    hash = "sha256-a2xz91g2tCkW+Si5mN2VQ29BE1PXHg4BBNdYt/gnIUs=";
  };

  npmDepsHash = "sha256-XBaFjoJpB6jE97G4hADdHRyywUn8gcgY0fb3DpV3NsE=";

  nativeBuildInputs = [
    prisma_6
  ];

  buildInputs = [
    openssl
  ];

  env = {
    # Mock values for build
    POSTGRES_PRISMA_URL = "postgresql://postgres:1234@db";
    POSTGRES_URL_NON_POOLING = "postgresql://postgres:1234@db";
  };

  preBuild = ''
    prisma generate
  '';

  postBuild = ''
    rm -r .next/cache
  '';

  postInstall = ''
    cp -r .next $out/lib/node_modules/spliit2/
    rm -r $out/lib/node_modules/spliit2/{scripts,src}
    makeWrapper $out/lib/node_modules/spliit2/node_modules/.bin/next $out/bin/spliit \
      --chdir $out/lib/node_modules/spliit2 \
      --set PRISMA_SCHEMA_ENGINE_BINARY ${lib.getExe' prisma-engines_6 "schema-engine"} \
      --set PRISMA_QUERY_ENGINE_BINARY ${lib.getExe' prisma-engines_6 "query-engine"} \
      --set PRISMA_QUERY_ENGINE_LIBRARY ${lib.getLib prisma-engines_6}/lib/libquery_engine.node \
      --set NEXT_TELEMETRY_DISABLED 1 \
      --run "$out/lib/node_modules/spliit2/node_modules/.bin/prisma migrate deploy" \
      --add-flags start \
  '';

  # Skip postinstall which runs prisma commands
  npmFlags = [ "--ignore-scripts" ];
  npmPruneFlags = [
    "--ignore-scripts"
    "--omit=optional"
    "--omit=dev"
  ];

  passthru.tests = {
    inherit (nixosTests) spliit;
  };

  meta = {
    changelog = "https://github.com/spliit-app/spliit/releases/tag/${src.tag}";
    description = "Web UI for sharing expenses with your friends and family, a free and Open Source Alternative to Splitwise";
    homepage = "https://spliit.app/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ratcornu ];
    mainProgram = "spliit";
  };
}
