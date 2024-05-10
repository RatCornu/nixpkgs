# SyncYomi {#module-services-syncyomi}

A self-hosted server to sync your Tachyiomi/Mihon library effortlessly.

## Basic usage {#module-services-syncyomi-basic-usage}

By default, the module will execute SyncYomi with its web UI and a SQLite database:

```nix
{
  services.syncyomi = {
    enable = true;
  };
}
```

It will run the systemd service `syncyomi.service` in the data directory
declared with `services.syncyomi.dataDir`.

To run it behind a reverse-proxy, here is a basic example with Nginx:

```nix
{ config, ... }:

{
  services.syncyomi = {
    enable = true

  settings = {
    host = "localhost";
    DatabaseType = "sqlite";
    logMaxBackups = 10;
  };

  services.nginx = {
    enable = true;

    virtualHosts."syncyomi.domain.tld" = {
      enableACME = true;
      forceSSL = true;
      recommendedProxySettings = true;
      
      locations."/" = {
        proxyPass = "http://${config.services.syncyomi.settings.host}:${toString config.services.syncyomi.settings.port}";
      };
    };
  };
}
```

## Setup with PostgreSQL {#module-services-syncyomi-setup-with-postgresql}

You can also use PostgreSQL instead of SQLite. It is recommanded for the PostgreSQL user, the PostgreSQL database name and the service user to be equal.

```nix
{
  services.syncyomi = {
    enable = true;

    settings = {
      host = "localhost";
      DatabaseType = "postgres";
      PostgresHost = "localhost";
      PostgresPort = "5432";
    };
  };
}
```
