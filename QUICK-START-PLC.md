# Quick Start: EpiBus + PLC Integration with Frappe Docker

## Prerequisites

- Docker and Docker Compose installed
- Git installed
- At least 4GB available RAM

## Step-by-Step Setup

### 1. Clone and Build Custom Image

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker

# Build custom Docker image with EpiBus
./development/build-epibus-image.sh
```

### 2. Environment Configuration

```bash
# Copy environment file and configure
cp example.env .env

# Edit .env file to set:
# CUSTOM_IMAGE=frappe-epibus
# CUSTOM_TAG=latest
# PULL_POLICY=never
# DB_PASSWORD=123
```

### 3. Start Services

For Mac M-series (ARM64):
```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

For x86_64 systems:
```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  up -d
```

### 4. Create Site with EpiBus

```bash
# Wait for services to be ready (about 2-3 minutes)
docker compose exec backend \
  bench new-site mysite.localhost \
  --admin-password admin \
  --db-root-password 123 \
  --install-app erpnext \
  --install-app epibus
```

## Access the Application

### 1. Find Your Port

```bash
# Check which port the frontend is using
docker compose ps
```

### 2. Open Web Interface

- **URL**: `http://localhost:[port]/` (port from previous step)
- **Username**: `Administrator`
- **Password**: `admin`

### 3. Access EpiBus Features

After logging in:
- Navigate to **EpiBus** workspace from the sidebar
- Configure **Modbus Connections** for your PLCs
- Set up **Modbus Signals** for I/O mapping
- Create **Modbus Actions** for automation workflows

## Optional: Add PLC Simulation

To add OpenPLC simulator and PLC Bridge for testing:

```bash
# Stop current services
docker compose down

# Restart with PLC services
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

This adds:
- **OpenPLC Web Interface**: Check port with `./get-openplc-port.sh`
- **PLC Bridge API**: Port 7654 for real-time communication
- **MODBUS TCP Server**: Port 502 for PLC communication

## Service Access

- **Frappe/ERPNext with EpiBus**: http://localhost:[dynamic_port] (Administrator/admin)
- **EpiBus Workspace**: Available in Frappe desk after login
- **OpenPLC Web Interface**: http://localhost:[dynamic_port] (openplc/openplc)
- **OpenPLC MODBUS**: Port 502 (MODBUS TCP)
- **PLC Bridge API**: http://localhost:7654/signals
- **PLC Bridge SSE**: http://localhost:7654/events

Use `docker compose ps` to find the dynamic port assignments or run `./get-openplc-port.sh` for OpenPLC details.

## Quick Verification

```bash
# Check all services
docker compose ps

# Test PLC Bridge
curl http://localhost:7654/signals

# View configurator logs
docker compose logs configurator

# View backend logs
docker compose logs backend
```

## File Structure

```
frappe_docker/
├── compose.yaml                     # Base compose file
├── .env                            # Environment variables
├── overrides/
│   ├── compose.mariadb.yaml        # MariaDB database
│   ├── compose.redis.yaml          # Redis cache/queue
│   ├── compose.openplc.yaml        # OpenPLC service
│   ├── compose.plc-bridge.yaml     # PLC Bridge service
│   └── compose.mac-m4.yaml         # Mac ARM64 support
└── epibus/plc/bridge/              # PLC Bridge source code
    ├── bridge.py                   # Main application
    ├── Dockerfile                  # Container definition
    └── requirements.txt            # Python dependencies
```

## Common Issues

1. **Missing .env file**: Copy from example.env and set DB_PASSWORD
2. **Database connection errors**: Ensure DB_HOST/DB_PORT are commented out in .env
3. **Site creation fails**: Database may have wrong credentials - wipe volumes and restart
4. **Port not found**: Use `docker compose ps` to find dynamic port assignments

## Troubleshooting

If you encounter database issues, completely reset:

```bash
# Stop and remove everything
docker compose down --volumes

# Remove database volumes
docker volume rm frappe_docker_db-data frappe_docker_sites

# Restart fresh
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.mac-m4.yaml up -d
```

For detailed documentation, see [docs/plc-bridge-setup.md](docs/plc-bridge-setup.md)