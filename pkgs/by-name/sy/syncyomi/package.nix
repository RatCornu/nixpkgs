{ lib
, fetchFromGitHub
, buildGoModule
, stdenvNoCC
, makeWrapper
, pkg-config
, moreutils
, nodePackages
, esbuild
, cacert
, jq
, tzdata
}:

let
  pname = "syncyomi";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-90MA62Zm9ouaf+CnYsbOm/njrUui21vW/VrwKYfsCZs=";
  };

  pnpm-deps = stdenvNoCC.mkDerivation {
    pname = "${pname}-pnpm-deps";
    inherit version;

    src = "${src}/web";

    nativeBuildInputs = [
      jq
      moreutils
      nodePackages.pnpm
      cacert
    ];

    installPhase = ''
      export HOME=$(mktemp -d)
      pnpm config set store-dir $out
      pnpm install --ignore-scripts

      rm -rf $out/v3/tmp
      for f in $(find $out -name "*.json"); do
        sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
        jq --sort-keys . $f | sponge $f
      done
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-FI0m0JOkx/nSvA39utbg6Tz3m4qC30LRmDkbWkIS6UI=";
  };
in

buildGoModule rec {
  inherit pname version src;

  vendorHash = "sha256-/rpT6SatIZ+GVzmVg6b8Zy32pGybprObotyvEgvdL2w=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  ESBUILD_BINARY_PATH = "${lib.getExe (esbuild.override {
    buildGoModule = args: buildGoModule (args // rec {
      version = "0.17.19";
      src = fetchFromGitHub {
        owner = "evanw";
        repo = "esbuild";
        rev = "v${version}";
        hash = "sha256-PLC7OJLSOiDq4OjvrdfCawZPfbfuZix4Waopzrj8qsU=";
      };
      vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
    });
  })}";

  preBuild = ''
    cd web 
    export HOME=$(mktemp -d)
    pnpm config set store-dir ${pnpm-deps}
    pnpm install --ignore-scripts --offline
    chmod -R +w node_modules
    pnpm build
    cd ..
  '';

  nativeBuildInputs = [
    makeWrapper
    nodePackages.pnpm
    pkg-config
  ];

  buildInputs = [
    jq
    tzdata
  ];

  meta = with lib; {
    description = "A self-hosted server to sync your Tachyiomi/Mihon library effortlessly";
    longDescription = ''
      SyncYomi is an open-source project designed to offer a seamless synchronization experience for your Tachiyomi manga reading progress and library across multiple devices. This server can be self-hosted, allowing you to sync your Tachiyomi library effortlessly.
    '';
    homepage = "https://github.com/syncyomi/syncyomi";
    downloadPage = "https://github.com/syncyomi/syncyomi/releases";
    changelog = "https://github.com/syncyomi/syncyomi/releases/tag/v${version}";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ratcornu ];
    mainProgram = "SyncYomi";
  };
}
