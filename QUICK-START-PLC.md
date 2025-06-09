# Quick Start: PLC Bridge with Frappe Docker

## Complete Setup Command

Use the full compose + overrides approach for the complete PLC-integrated system:

```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

## Environment Setup

Create `.env` file in project root (copy from example.env):

```bash
cp example.env .env
```

Edit the `.env` file and ensure these settings:

```bash
# Database password (required)
DB_PASSWORD=123

# Comment out external database settings (we use containerized MariaDB/Redis)
# DB_HOST=
# DB_PORT=
# REDIS_CACHE=
# REDIS_QUEUE=

# Optional PLC Bridge settings
FRAPPE_API_KEY=your_api_key_here
FRAPPE_API_SECRET=your_api_secret_here
PLC_POLL_INTERVAL=1.0
PLC_LOG_LEVEL=INFO
```

## Site Creation

After containers start, create a Frappe site:

```bash
# Wait for services to be healthy, then create site
docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext
```

## Service Access

- **Frappe/ERPNext**: http://localhost:[dynamic_port] (Administrator/admin)
- **OpenPLC Web Interface**: http://localhost:[dynamic_port] 
- **OpenPLC MODBUS**: Port 502 (MODBUS TCP)
- **PLC Bridge API**: http://localhost:7654/signals
- **PLC Bridge SSE**: http://localhost:7654/events

Use `docker compose ps` to find the dynamic port assignments.

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