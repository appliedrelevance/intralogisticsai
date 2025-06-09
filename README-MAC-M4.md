# Frappe Docker for Mac M4 (ARM64) Setup Guide

This guide provides Mac M4-specific configuration for running Frappe Docker with ARM64 compatibility and automatic port assignment.

## 🚀 Quick Start

### Prerequisites

1. **Docker Desktop for Mac** with Apple Silicon support
2. **Git** (for cloning the repository)

### Installation

1. Clone the repository and navigate to the directory:
   
   ```bash
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```

2. Create environment file:
   
   ```bash
   cp example.env .env
   ```

3. Start the complete system:
   
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

4. Create a Frappe site:
   
   ```bash
   docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext
   ```

5. Find your access port:
   
   ```bash
   docker compose ps
   ```

## 📁 Mac M4 Specific Configuration

### `overrides/compose.mac-m4.yaml` - ARM64 Configuration

This override file provides:

- **ARM64 Platform**: Sets `platform: linux/arm64` for all services
- **Ephemeral Ports**: Prevents port conflicts with `"0:8080"` mapping
- **Optimized Images**: Uses ARM64-compatible Frappe/ERPNext images
- **Performance Tuning**: Mac-specific environment variables

### Key Features

- **Automatic Port Assignment**: Docker assigns available ports to prevent conflicts
- **ARM64 Compatibility**: All services run natively on Apple Silicon
- **No Manual Port Configuration**: System finds free ports automatically

## 🔧 Usage Commands

### Setup and Management

```bash
# Full setup with all services
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d

# Stop all services
docker compose down

# View service status
docker compose ps

# View logs
docker compose logs configurator
docker compose logs backend
```

### Site Management

```bash
# Create new site
docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123

# Install ERPNext
docker compose exec backend bench --site localhost install-app erpnext

# Set default site
docker compose exec backend bench use localhost
```

## 🏗️ Architecture Details

### ARM64 Compatibility

- All services configured with `platform: linux/arm64`
- Uses Frappe/ERPNext v15.64.1 with ARM64 support
- Optimized for Apple Silicon performance

### Service Stack

- **Frontend**: Nginx proxy (dynamically assigned port)
- **Backend**: Frappe application server
- **WebSocket**: Real-time communication service
- **Queue Workers**: Background job processing (long and short)
- **Scheduler**: Cron-like task scheduling
- **Configurator**: Initial setup and configuration
- **Database**: MariaDB 10.6 with persistent storage
- **Cache/Queue**: Redis services for caching and job queues
- **OpenPLC**: PLC simulator for industrial automation
- **PLC Bridge**: Real-time MODBUS communication service

### Port Management

- **Dynamic Assignment**: Frontend port is automatically assigned
- **Internal Communication**: Services communicate via Docker network
- **No Conflicts**: System avoids port collisions automatically

## 🔍 Troubleshooting

### Common Issues

1. **Docker not running**
   
   ```bash
   # Check Docker status
   docker info
   
   # Start Docker Desktop if needed
   open -a Docker
   ```

2. **Database connection errors**
   
   ```bash
   # Ensure .env file has correct settings
   cat .env | grep DB_PASSWORD
   
   # Reset database if needed
   docker compose down --volumes
   docker volume rm frappe_docker_db-data frappe_docker_sites
   ```

3. **ARM64 compatibility issues**
   
   ```bash
   # Verify platform configuration
   docker compose config | grep platform
   ```

4. **Services not starting**
   
   ```bash
   # Check service logs
   docker compose logs configurator
   docker compose logs backend
   
   # Verify all services are healthy
   docker compose ps
   ```

### Database Reset

If you encounter persistent database issues:

```bash
# Complete reset
docker compose down --volumes
docker volume rm frappe_docker_db-data frappe_docker_sites frappe_docker_redis-queue-data

# Restart fresh
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

## 📊 Service Ports

| Service    | Internal Port | External Port        | Access                    |
| ---------- | ------------- | -------------------- | ------------------------- |
| Frontend   | 8080          | Dynamically assigned | Frappe/ERPNext web UI     |
| Backend    | 8000          | Internal only        | Application server        |
| WebSocket  | 9000          | Internal only        | Real-time communication   |
| Database   | 3306          | Internal only        | MariaDB                   |
| Redis      | 6379          | Internal only        | Cache and queue           |
| OpenPLC    | 8080          | Dynamically assigned | PLC web interface         |
| MODBUS     | 502           | 502                  | PLC MODBUS TCP server     |
| PLC Bridge | 7654          | 7654                 | Bridge API and SSE        |

## 🔐 Security Considerations

- Database password is configurable via `.env` file
- Services are isolated within Docker network
- Only necessary ports are exposed externally
- All internal communication uses service names

## 📝 Environment Configuration

### Required `.env` Settings

```bash
# Database password (required)
DB_PASSWORD=123

# ERPNext version
ERPNEXT_VERSION=v15.64.1

# Comment out external database settings (using containerized services)
# DB_HOST=
# DB_PORT=
# REDIS_CACHE=
# REDIS_QUEUE=
```

### Optional Settings

```bash
# Custom images
CUSTOM_IMAGE=your-registry/frappe-custom
CUSTOM_TAG=your-tag

# PLC Bridge configuration
FRAPPE_API_KEY=your_api_key_here
FRAPPE_API_SECRET=your_api_secret_here
PLC_POLL_INTERVAL=1.0
PLC_LOG_LEVEL=INFO

# OpenPLC settings
OPENPLC_WEB_PORT=8081
OPENPLC_MODBUS_PORT=502
OPENPLC_LOG_LEVEL=INFO
```

## 🆘 Support

For Mac M4-specific issues:

1. Ensure Docker Desktop is configured for Apple Silicon
2. Verify all services show `platform: linux/arm64`
3. Check Docker Desktop resource allocation (4GB+ RAM recommended)
4. Review service logs for specific error messages

For general Frappe Docker issues:

- [Frappe Docker Documentation](https://github.com/frappe/frappe_docker)
- [Frappe Community Forum](https://discuss.frappe.io/)

## 📄 License

This configuration follows the same license as the main Frappe Docker project.