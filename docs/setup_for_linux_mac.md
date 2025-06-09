# How to install ERPNext on Linux/Mac using Frappe Docker

## Quick Setup

### Step 1: Clone the repository

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

### Step 2: Create environment file

```bash
cp example.env .env
```

Edit the `.env` file to ensure these settings:

```bash
# Database password (required)
DB_PASSWORD=123

# Comment out external database settings (we use containerized services)
# DB_HOST=
# DB_PORT=
# REDIS_CACHE=
# REDIS_QUEUE=
```

### Step 3: Start the services

For **Mac M-series (ARM64)**:
```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

For **Linux/Mac Intel (x86_64)**:
```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  up -d
```

### Step 4: Create a site

Wait for the configurator to complete, then create a site:

```bash
# Check that configurator completed successfully
docker compose logs configurator

# Create site with ERPNext
docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext
```

### Step 5: Access the application

Find the assigned port:

```bash
docker compose ps
```

Access Frappe/ERPNext at `http://localhost:[assigned_port]` with:
- **Username**: Administrator
- **Password**: admin

## Architecture

This setup provides:

- **Frontend**: Nginx proxy with dynamic port assignment
- **Backend**: Frappe application server
- **Database**: MariaDB 10.6 with persistent storage
- **Cache/Queue**: Redis services for caching and job processing
- **Queue Workers**: Background job processing
- **Scheduler**: Automated task scheduling
- **WebSocket**: Real-time communication

## Platform-Specific Notes

### Mac M-series (ARM64)

The `compose.mac-m4.yaml` override provides:
- `platform: linux/arm64` for all services
- Optimized for Apple Silicon performance
- Automatic port assignment to prevent conflicts

### Linux/Intel Mac (x86_64)

Uses standard `linux/amd64` platform for compatibility.

## Troubleshooting

### Common Issues

1. **Database connection errors**
   ```bash
   # Ensure .env has correct DB_PASSWORD
   cat .env | grep DB_PASSWORD
   ```

2. **Site creation fails**
   ```bash
   # Reset volumes and restart
   docker compose down --volumes
   docker volume rm frappe_docker_db-data frappe_docker_sites
   ```

3. **Services not starting**
   ```bash
   # Check logs
   docker compose logs configurator
   docker compose logs backend
   ```

### Complete Reset

If you encounter persistent issues:

```bash
# Stop and remove everything
docker compose down --volumes
docker volume rm frappe_docker_db-data frappe_docker_sites frappe_docker_redis-queue-data

# Start fresh
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

## Additional Services

To add PLC integration and industrial automation:

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

This adds:
- **OpenPLC**: PLC simulator for industrial automation
- **PLC Bridge**: Real-time MODBUS communication service

## Support

For issues:
- Check service logs: `docker compose logs [service_name]`
- Verify .env configuration
- Ensure Docker has sufficient resources (4GB+ RAM recommended)
- Review [Frappe Docker documentation](https://github.com/frappe/frappe_docker)