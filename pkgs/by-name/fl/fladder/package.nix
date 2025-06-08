{
  lib,
  fetchFromGitHub,
  flutter329,
  ffmpeg,
  lcms,
  libass,
  libdovi,
  libdvdnav,
  libdvdread,
  libunwind,
  libplacebo,
  mpv-unwrapped,
  pkg-config,
  shaderc,
  vulkan-headers,
  vulkan-loader,

  targetFlutterPlatform ? "linux",
}:

flutter329.buildFlutterApplication rec {
  pname = "fladder";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "DonutWare";
    repo = "Fladder";
    rev = "v${version}";
    hash = "sha256-zu7Ip3slAwx3J1OkCVfm3wYjgT5HP2KYmeug36aoVUA=";
  };

  inherit targetFlutterPlatform;

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    ffmpeg.dev
    lcms.dev
    libass.dev
    libdovi
    libdvdnav
    libdvdread
    libunwind.dev
    libplacebo
    mpv-unwrapped.dev
    shaderc.dev
    vulkan-headers
    vulkan-loader
  ];
}
