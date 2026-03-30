{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  writeText,
  jq,
  conf ? { },
}:

let
  configOverrides = writeText "cinny-config-overrides.json" (builtins.toJSON conf);
in

buildNpmPackage (finalAttrs: {
  pname = "sable";
  version = "1.13.1";

  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1W7kcVpmSQ0y057CKouzEeOhcptWxBjkNDfe53U+3g8=";
  };

  npmDeps = null;
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) version src;
    pname = "sable";
    hash = "sha256-bWTjXJ1XJuJflqmJACZwpKZwxctdK1C174Nhym9nYRI=";
    fetcherVersion = 3;
  };

  npmConfigHook = pnpmConfigHook;
  npmRebuildFlags = [
    "--ignore-scripts"
  ];

  nativeBuildInputs = [
    jq
    pnpm
  ];

  installPhase = ''
    runHook preInstall

    cp -r dist $out
    mv $out/config.json $out/config_default.json
    jq -s '.[0] * .[1]' $out/config_default.json "${configOverrides}" > $out/config.json

    runHook postInstall
  '';

  meta = {
    description = "An almost stable Matrix client.";
    homepage = "https://app.sable.moe/";
    maintainers = with lib.maintainers; [
      ratcornu
    ];
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.all;
  };
})
