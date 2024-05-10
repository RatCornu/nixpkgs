{ config, pkgs, lib, ... }:

let
  cfg = config.services.syncyomi;
  inherit (lib) mkEnableOption mkIf mkOption types;

  format = pkgs.formats.toml { };
in
{
  options = {
    services.syncyomi = {
      enable = mkEnableOption "SyncYomi, a self-hosted server to sync your Tachiyomi/Mihon library effortlessly.";

      package = lib.mkPackageOptionMD pkgs "syncyomi" { };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/syncyomi";
        example = "/var/data/mangas";
        description = ''
          The path to the data directory in which SyncYomi will store its data.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "syncyomi";
        example = "alice";
        description = ''
          User account under which SyncYomi runs.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "syncyomi";
        example = "medias";
        description = ''
          Group under which SyncYomi runs.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to open the firewall for the port in {option}`services.syncyomi.settings.server.port`.
        '';
      };

      settings = mkOption {
        description = ''
          Configuration to write to {file}`config.toml`.
          See <https://github.com/syncyomi/syncyomi/blob/v1.1.1/config.toml> for more information.
        '';
        default = { };
        example = {
          host = "127.0.0.1";
          port = 8080;
          DatabaseType = "postgres";
        };
        type = types.submodule {
          freeformType = format.type;
          options = {
            host = mkOption {
              type = types.str;
              default = "localhost";
              example = "0.0.0.0";
              description = ''
                The host SyncYomi will bind to.
              '';
            };

            port = mkOption {
              type = types.port;
              default = 8282;
              example = 8080;
              description = ''
                The port SyncYomi will listen to.
              '';
            };

            DatabaseType = mkOption {
              type = types.enum [ "sqlite" "postgres" ];
              default = "sqlite";
              example = "postgres";
              description = ''
                Database type to use. It can be either SQLite or PostgreSQL.
                Settings starting with "Postgres" will only be used if this is set to "postgres".
              '';
            };

            PostgresHost = mkOption {
              type = types.str;
              default = "localhost";
              example = "192.168.1.2";
              description = ''
                Host on which the PostreSQL database is located.
              '';
            };

            PostgresPort = mkOption {
              type = types.str;
              default = "5432";
              example = "5434";
              description = ''
                The port on which PostgreSQL listens to.
              '';
            };


            PostgresDatabase = mkOption {
              type = types.str;
              default = "syncyomi";
              example = "mangas";
              description = ''
                The name of the PostgreSQL database.
              '';
            };

            PostgresUser = mkOption {
              type = types.str;
              default = "syncyomi";
              example = "mangas";
              description = ''
                The user PostgreSQL will be used with.
              '';
            };

            # Note : this is not a real upstream option.
            PostgresPassFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/run/secrets/syncyomi-pass";
              description = ''
                The path to the file containing the password of the PostgreSQL user.
              '';
            };

            baseUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/SyncYomi/";
              description = ''
                Custom base URL eg /tachiyomi/ to serve in subdirectory.
                Not needed for subdomain, or by accessing with the :port directly.
              '';
            };

            logPath = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/SyncYomi.log";
              example = "/var/log/syncyomi";
              description = ''
                SyncYomi logs file.
              '';
            };

            logLevel = mkOption {
              type = types.enum [ "ERROR" "DEBUG" "INFO" "WARN" "TRACE" ];
              default = "DEBUG";
              example = "INFO";
              description = ''
                The logging verbosity of SyncYomi.
              '';
            };

            logMaxBackups = mkOption {
              type = types.int;
              default = 3;
              example = 10;
              description = ''
                Max amount of old log files.
              '';
            };

            checkForUpdates = mkOption {
              type = types.bool;
              default = true;
              example = false;
              description = ''
                Will automatically check for updates.
              '';
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.settings.port ];

    users.groups.syncyomi = mkIf (cfg.group == "syncyomi") { };
    users.users.syncyomi = mkIf (cfg.user == "syncyomi") {
      description = "SyncYomi daemon user.";

      isSystemUser = true;
      group = cfg.group;
    };

    services.postgresql = mkIf (cfg.settings.DatabaseType == "postgres") {
      enable = true;

      ensureDatabases = [ cfg.settings.PostgresDatabase ];
      ensureUsers = [{
        name = cfg.settings.PostgresUser;
        ensureDBOwnership = mkIf (cfg.settings.PostgresUser == cfg.settings.PostgresDatabase) true;
      }];

      authentication = mkIf (cfg.settings.PostgresHost == "localhost") (lib.mkOverride 10 ''
        host ${cfg.settings.PostgresDatabase} ${cfg.settings.PostgresUser} 127.0.0.1/32 ${if cfg.settings.PostgresPassFile == null then "trust" else "scram-sha-256"}
      '');
    };

    systemd.services.syncyomi =
      let
        configFile = format.generate "config.toml" (lib.pipe cfg.settings [
          (settings: lib.recursiveUpdate settings {
            PostgresPassFile = null;
            PostgresPass = if cfg.settings.PostgresPassFile == null then null else "$SYNCYOMI_POSTGRES_PASS";
          })
          (lib.filterAttrsRecursive (_: v: v != null))
        ]);
      in
      {
        description = "A self-hosted server to sync your Tachyiomi/Mihon library effortlessly";

        wantedBy = [ "multi-user.target" ];
        wants = [ "syslog.target" "network-online.target" ];
        after = [ "syslog.target" "network-online.target" ];

        script = ''
          ${lib.optionalString (cfg.settings.PostgresPassFile != null) ''
            export SYNCYOMI_POSTGRES_PASS="$(<${cfg.settings.PostgresPassFile})"
          ''}
          ${lib.getExe pkgs.envsubst} -i ${configFile} -o ${cfg.dataDir}/config.toml
          ${lib.getExe cfg.package} --config=${cfg.dataDir}
        '';

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          Type = "simple";
          Restart = "on-failure";

          StateDirectory = mkIf (cfg.dataDir == "/var/lib/syncyomi") "syncyomi";
          WorkingDirectory = cfg.dataDir;
        };
      };
  };

  meta = {
    maintainers = with lib.maintainers; [ ratcornu ];
  };
}

