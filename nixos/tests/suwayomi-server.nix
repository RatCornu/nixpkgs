{ lib, runTest }:

{
  without-webui = runTest {
    name = "suwayomi-server-without-webui";

    nodes.machine =
      { pkgs, ... }:
      {
        services.suwayomi-server = {
          enable = true;
          settings = {
            server = {
              port = 1234;
              webUIEnabled = false;
            };
          };
        };
      };

    testScript = ''
      machine.wait_for_unit("suwayomi-server.service")
      machine.wait_for_open_port(1234)
    '';

    meta.maintainers = with lib.maintainers; [ ratcornu ];
  };

  without-auth = runTest {
    name = "suwayomi-server-without-auth";

    nodes.machine =
      { pkgs, ... }:
      {
        services.suwayomi-server = {
          enable = true;
          settings.server = {
            port = 1234;
            webUIFlavor = "Custom";
          };
        };
      };

    testScript = ''
      machine.wait_for_unit("suwayomi-server.service")
      machine.wait_for_open_port(1234)
      machine.succeed("curl --fail http://localhost:1234/")
    '';

    meta.maintainers = with lib.maintainers; [ ratcornu ];
  };

  with-auth = runTest {
    name = "suwayomi-server-with-auth";

    nodes.machine =
      { pkgs, ... }:
      {
        services.suwayomi-server = {
          enable = true;

          settings.server = {
            port = 1234;
            basicAuthEnabled = true;
            basicAuthUsername = "alice";
            basicAuthPasswordFile = pkgs.writeText "snakeoil-pass.txt" "pass";
            webUIFlavor = "Custom";
          };
        };
      };

    testScript = ''
      machine.wait_for_unit("suwayomi-server.service")
      machine.wait_for_open_port(1234)
      machine.succeed("curl --fail -u alice:pass http://localhost:1234/meta")
    '';

    meta.maintainers = with lib.maintainers; [ ratcornu ];
  };
}
