{
  lib,
  fetchFromGitHub,
  flutter332,
  stdenv,

  alsa-lib,
  ffmpeg,
  lcms,
  libass,
  libbluray,
  libcaca,
  libdisplay-info,
  libdovi,
  libdrm,
  libdvdnav,
  libdvdread,
  libepoxy,
  libgbm,
  libplacebo,
  libpulseaudio,
  libuchardet,
  libunwind,
  libva,
  libvdpau,
  lua,
  mujs,
  mpv,
  nv-codec-headers-12,
  openal,
  pipewire,
  rubberband,
  shaderc,
  vulkan-headers,
  vulkan-loader,
  xorg,
  zimg,
}:

let
  flutter = flutter332;
in

flutter.buildFlutterApplication {
  pname = "fladder";
  version = "0.7.0-unstable-2025-06-12";

  src = fetchFromGitHub {
    owner = "DonutWare";
    repo = "Fladder";
    rev = "f3e920ac79b18132f2d1944f3f29743959cdbb70";
    hash = "sha256-SfRu1IHpIsKajOMg3sxOXqOoRuDdSY1hZtgeuqgU0oc=";
  };

  targetFlutterPlatform = "web";

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  buildInputs = [
    alsa-lib
    ffmpeg
    lcms
    libass
    libbluray
    libcaca
    libdisplay-info
    libdovi
    libdrm
    libdvdnav
    libdvdread
    libepoxy
    libgbm
    libplacebo
    libpulseaudio
    libuchardet
    libunwind
    libva
    libvdpau
    lua
    mujs
    mpv
    nv-codec-headers-12
    openal
    pipewire
    rubberband
    shaderc
    vulkan-headers
    vulkan-loader
    xorg.libXpresent
    xorg.libXScrnSaver
    zimg
  ];

  customSourceBuilders = {
    volume_controller =
      { version, src, ... }:
      stdenv.mkDerivation rec {
        pname = "volume_controller";
        inherit version src;
        inherit (src) passthru;

        postPatch = ''
          substituteInPlace linux/CMakeLists.txt \
            --replace-fail '# ALSA dependency for volume control' 'find_package(PkgConfig REQUIRED)' \
            --replace-fail 'find_package(ALSA REQUIRED)' 'pkg_check_modules(ALSA REQUIRED alsa)'
        '';

        installPhase = ''
          runHook preInstall

          mkdir $out
          cp -r ./* $out/

          runHook postInstall
        '';
      };
  };

  fixupPhase = ''
    runHook preFixup

    sed -i 's;base href="/";base href="$out";' $out/index.html

    runHook postFixup
  '';

  meta = with lib; {
    description = "A Simple Jellyfin Frontend built on top of Flutter.";
    homepage = "https://github.com/DonutWare/Fladder";
    downloadPage = "https://github.com/DonutWare/Fladder/releases";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ratcornu ];
    mainProgram = "Fladder";
  };
}
