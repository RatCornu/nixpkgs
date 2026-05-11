{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.spliit;
in
{
  options.services.spliit = with lib; {
    enable = mkEnableOption "Spliit bill-splitting web application";
    package = mkPackageOption pkgs "spliit" { };
    settings = mkOption {
      type = types.submodule {
        freeformType = with types; attrsOf str;
        options = {
          PORT = mkOption {
            type = types.port;
            default = 3000;
            example = 7000;
            description = "The port to use.";
          };
          ADDRESS = mkOption {
            type = types.str;
            default = "127.0.0.1";
            example = "0.0.0.0";
            description = "The address to listen on.";
          };
        };
      };
      example = literalExpression ''
        {
          PORT = 7000;
          NEXT_PUBLIC_ENABLE_RECEIPT_EXTRACT = true;
        }
      '';
      default = {
        PORT = 3000;
      };
      description = ''
        Environment variables settings for spliit. See <https://github.com/spliit-app/spliit?tab=readme-ov-file#opt-in-features> for the possible options.
        Secrets should use `secretFile` option instead.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "spliit";
      description = "User account under which Spliit runs.";
    };

    group = mkOption {
      type = types.str;
      default = "spliit";
      description = "Group under which Spliit runs.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the specified port.";
    };

    configureNginx = mkOption {
      type = types.bool;
      default = false;
      description = "Configure nginx as a reverse proxy for Spliit.";
    };

    host = mkOption {
      type = lib.types.str;
      description = "Domain on which nginx will serve Spliit";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        A secret file to be sourced for the environment variables settings.
        Place `S3_UPLOAD_KEY`, `OPENAI_API_KEY` and other settings that should not end up in the Nix store here.
      '';
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Create the PostgreSQL database and database user locally.
        '';
      };
      name = mkOption {
        type = types.str;
        default = "spliit";
        description = "Database name.";
      };
      user = mkOption {
        type = types.str;
        default = "spliit";
        description = "Database user.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.spliit = {
      description = "Spliit bill-splitting web application";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optional cfg.database.createLocally "postgresql.service";
      requires = lib.mkIf cfg.database.createLocally [ "postgresql.service" ];

      environment = lib.mkMerge [
        (lib.mapAttrs (_: toString) cfg.settings)
      ];

      serviceConfig = {
        Type = "simple";
        StateDirectory = "spliit";
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
        EnvironmentFile = cfg.environmentFile;
        User = cfg.user;
        Group = cfg.group;
        DynamicUser = true;

        # Hardening
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # required for Node.js JIT
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
          # Required for connecting to database sockets,
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
        ];
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        UMask = "0077";
      };
    };

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];
    };

    services.nginx = lib.mkIf cfg.configureNginx {
      enable = true;
      virtualHosts = {
        ${cfg.host} = {
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString cfg.settings.PORT}";
            };
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.settings.PORT ];
  };

  meta = {
    maintainers = with lib.maintainers; [ ratcornu ];
  };
}
