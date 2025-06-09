[![Build Stable](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml)
[![Build Develop](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml)

Everything about [Frappe](https://github.com/frappe/frappe) and [ERPNext](https://github.com/frappe/erpnext) in containers.

# Getting Started

To get started you need [Docker](https://docs.docker.com/get-docker/), [docker-compose](https://docs.docker.com/compose/), and [git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git) setup on your machine. For Docker basics and best practices refer to Docker's [documentation](http://docs.docker.com).

Once completed, chose one of the following two sections for next steps.

### Try in Play With Docker

To play in an already set up sandbox, in your browser, click the button below:

<a href="https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/frappe/frappe_docker/main/pwd.yml">
  <img src="https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png" alt="Try in PWD"/>
</a>

### Setup Development Environment

First clone the repo:

```sh
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

Start the full stack with PLC integration:

```sh
# Start with MariaDB, Redis, OpenPLC, PLC Bridge, and Mac M4 support
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

**Note**: Do NOT use `pwd.yml` - it is deprecated and not compatible with this PLC-integrated setup.

### ARM64 Architecture (Mac M-series)

The `compose.mac-m4.yaml` override automatically handles ARM64 platform configuration. No additional setup required.

## Final steps

Wait for 5 minutes for ERPNext site to be created or check container logs before opening browser. Use `docker compose ps` to find the auto-assigned port for the frontend service. (username: `Administrator`, password: `admin`)

To view container logs:
```sh
docker compose logs -f configurator
```

Use helper scripts:
- `./get-openplc-port.sh` - Get OpenPLC web interface port

Don't worry about some initial error messages, services take time to become ready.

# Documentation

### [Frequently Asked Questions](https://github.com/frappe/frappe_docker/wiki/Frequently-Asked-Questions)

### [Production](#production)

- [List of containers](docs/list-of-containers.md)
- [Single Compose Setup](docs/single-compose-setup.md)
- [Environment Variables](docs/environment-variables.md)
- [Dynamic Port Mapping](docs/dynamic-port-mapping.md)
- [Single Server Example](docs/single-server-example.md)
- [Setup Options](docs/setup-options.md)
- [Site Operations](docs/site-operations.md)
- [Backup and Push Cron Job](docs/backup-and-push-cronjob.md)
- [Port Based Multi Tenancy](docs/port-based-multi-tenancy.md)
- [Migrate from multi-image setup](docs/migrate-from-multi-image-setup.md)
- [running on linux/mac](docs/setup_for_linux_mac.md)
- [TLS for local deployment](docs/tls-for-local-deployment.md)

### [Industrial Automation](#industrial-automation)

- [OpenPLC Integration](README-OpenPLC.md)
- [OpenPLC Setup Guide](docs/openplc-integration.md)
- [PLC Bridge Setup and Usage](docs/plc-bridge-setup.md)

### [Custom Images](#custom-images)

- [Custom Apps](docs/custom-apps.md)
- [Custom Apps with podman](docs/custom-apps-podman.md)
- [Build Version 10 Images](docs/build-version-10-images.md)

### [Development](#development)

- [Development using containers](docs/development.md)
- [Bench Console and VSCode Debugger](docs/bench-console-and-vscode-debugger.md)
- [Connect to localhost services](docs/connect-to-localhost-services-from-containers-for-local-app-development.md)

### [Troubleshoot](docs/troubleshoot.md)

# Contributing

If you want to contribute to this repo refer to [CONTRIBUTING.md](CONTRIBUTING.md)

This repository is only for container related stuff. You also might want to contribute to:

- [Frappe framework](https://github.com/frappe/frappe#contributing),
- [ERPNext](https://github.com/frappe/erpnext#contributing),
- [Frappe Bench](https://github.com/frappe/bench).
