{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  git,
  yarn-berry,
  yarnConfigHook,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "SableCall";
  version = "1.1.4";

  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "sable-call";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1mx5+sJryC0szveb7mad/D09UJx1gKCBVjAYbHlG/E0=";
  };

  matrixJsSdkRevision = "6e3efef0c5f660df47cf00874927dec1c75cc3cf";
  matrixJsSdkOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.offlineCache}/checkouts/${finalAttrs.matrixJsSdkRevision}/yarn.lock";
    hash = "sha256-YvXmPWHt3qL9z8uap0/faKi5OId6zZ0ISiMT3x6ARx8=";
  };

  dontYarnInstallDeps = true;
  preConfigure = ''
    cp -r $offlineCache writable
    chmod u+w -R writable
    pushd writable/checkouts/${finalAttrs.matrixJsSdkRevision}/
    mkdir -p .git/{refs,objects}
    echo ${finalAttrs.matrixJsSdkRevision} > .git/HEAD
    SKIP_YARN_COREPACK_CHECK=1 offlineCache=$matrixJsSdkOfflineCache yarnConfigHook
    SKIP_YARN_COREPACK_CHECK=1 yarn build
    popd
    offlineCache=writable
    export YARN_CHECKSUM_BEHAVIOR=ignore
  '';

  missingHashes = ./missing-hashes.json;
  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes;
    hash = "sha256-llcj70XJ6/3YdaVyE5bVle2CO3zzFglIsjwQeTa+RvE=";
  };

  nativeBuildInputs = [
    git
    yarn-berry.yarnBerryConfigHook
    yarnConfigHook
    nodejs
  ];

  buildPhase = ''
    runHook preBuild
    ${lib.getExe yarn-berry} build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r dist/* $out

    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/element-hq/element-call/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://github.com/element-hq/element-call";
    description = "Group calls powered by Matrix";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ kilimnik ];
  };
})
