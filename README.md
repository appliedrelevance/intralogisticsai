[![Build Stable](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_stable.yml)
[![Build Develop](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml/badge.svg)](https://github.com/frappe/frappe_docker/actions/workflows/build_develop.yml)

Everything about [Frappe](https://github.com/frappe/frappe) and [ERPNext](https://github.com/frappe/erpnext) in containers, with integrated industrial automation capabilities through EpiBus.

# Getting Started

To get started you need [Docker](https://docs.docker.com/get-docker/), [docker-compose](https://docs.docker.com/compose/), and [git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git) setup on your machine. For Docker basics and best practices refer to Docker's [documentation](http://docs.docker.com).

Once completed, chose one of the following two sections for next steps.

### Setup Development Environment

First clone the repo:

```sh
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

### Quick Start with EpiBus Integration

This setup includes industrial automation capabilities through EpiBus, OpenPLC, and PLC Bridge integration.

#### Step 1: Build Custom Image with EpiBus

```sh
# Build custom Docker image with EpiBus included
./development/build-epibus-image.sh
```

#### Step 2: Configure Environment

Copy and configure environment file:

```sh
cp example.env .env
# Edit .env to set:
# CUSTOM_IMAGE=frappe-epibus
# CUSTOM_TAG=latest
# PULL_POLICY=never
```

#### Step 3: Start All Services (Including OpenPLC and PLC Bridge)

For Mac M-series (ARM64):
```sh
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.mac-m4.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  up -d
```

For x86_64 systems:
```sh
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  up -d
```

#### Step 4: Create Site with EpiBus Integration

```sh
# Wait for services to be ready, then create site
# CRITICAL: Use --mariadb-user-host-login-scope=% for Docker network compatibility
docker compose exec backend \
  bench new-site intralogistics.localhost \
  --admin-password admin \
  --db-root-password 123 \
  --mariadb-user-host-login-scope=% \
  --install-app erpnext \
  --install-app epibus
```

## Access the Application

1. **Find the frontend port**: Use `docker compose ps` to find the auto-assigned port for the frontend service
2. **Access web interface**: Open `http://localhost:<port>/` in your browser
3. **Login credentials**: Username: `Administrator`, Password: `admin`

To view container logs:
```sh
docker compose logs -f configurator
docker compose logs -f backend
```

### Access Industrial Automation Features

- **EpiBus Dashboard**: Navigate to "EpiBus" module after login
- **OpenPLC Web Interface**: Use `./get-openplc-port.sh` to get port number
- **PLC Bridge API**: Available on port 7654 for real-time PLC communication
- **MODBUS Communication**: Monitor and control PLC signals through EpiBus interface

### Troubleshooting

If you encounter database connection issues after restarting containers, run:
```sh
# Get current backend container IP
BACKEND_IP=$(docker compose exec backend hostname -i)
# Grant database access (adjust user/password as needed)
docker compose exec db mysql -u root -p123 -e "GRANT ALL PRIVILEGES ON *.* TO 'site_user'@'$BACKEND_IP'; FLUSH PRIVILEGES;"
```

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
