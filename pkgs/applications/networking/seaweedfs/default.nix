{ lib
, fetchFromGitHub
, buildGoModule
, testers
, seaweedfs
}:

buildGoModule rec {
  pname = "seaweedfs";
  version = "3.73";

  src = fetchFromGitHub {
    owner = "seaweedfs";
    repo = "seaweedfs";
    rev = version;
    hash = "sha256-5CgkpL0nBLKojKPSfkYxh8F5Ub+yWhfmOsKC5qQ4QaE=";
  };

  vendorHash = "sha256-rj5BbbT3/IBtPZ1MqbwC9TNp+N9ec90Anear2AWBZZU=";

  subPackages = [ "weed" ];

  ldflags = [
    "-w"
    "-s"
    "-X github.com/seaweedfs/seaweedfs/weed/util.COMMIT=N/A"
  ];

  tags = [
    "elastic"
    "gocdk"
    "sqlite"
    "ydb"
    "tikv"
  ];

  preBuild = ''
    export GODEBUG=http2client=0
  '';

  preCheck = ''
    # Test all targets.
    unset subPackages

    # Remove unmaintained tests ahd those that require additional services.
    rm -rf unmaintained test/s3
  '';

  passthru.tests.version = testers.testVersion {
    package = seaweedfs;
    command = "weed version";
  };

  meta = with lib; {
    description = "Simple and highly scalable distributed file system";
    homepage = "https://github.com/chrislusf/seaweedfs";
    maintainers = with maintainers; [ azahi cmacrae wozeparrot ];
    mainProgram = "weed";
    license = licenses.asl20;
  };
}
