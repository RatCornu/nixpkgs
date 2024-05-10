{ fetchFromGitHub
, buildDotnetModule
, dotnetCorePackages
}:

buildDotnetModule rec {
  pname = "ShokoServer";
  version = "4.2.2";

  src = fetchFromGitHub {
    owner = "ShokoAnime";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-lWI81sRSYs/CukyylwssB96kxSqxMFxiD30WW2xi05s=";
    fetchSubmodules = true;
  };

  projectFile = "Shoko.CLI/Shoko.CLI.csproj";
  nugetDeps = ./deps.nix;

  dotnet-sdk = with dotnetCorePackages; combinePackages [ sdk_6_0 sdk_7_0 sdk_8_0 ];
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  dotnetInstallFlags = [ "-r" "linux-x64" "-f" "net8.0" ];
}
