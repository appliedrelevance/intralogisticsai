# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## High-Level Architecture

This repository implements a sophisticated containerized Frappe/ERPNext deployment with integrated industrial automation capabilities. The architecture combines:

### Core Business Platform
- **Frappe Framework**: Python web application framework
- **ERPNext**: Open-source ERP built on Frappe
- **MariaDB/PostgreSQL**: Database backend
- **Redis**: Caching and queue management
- **Nginx**: Reverse proxy and static file serving

### Industrial Automation Integration
- **EpiBus**: Custom Frappe app providing MODBUS/TCP communication capabilities
- **PLC Bridge**: Real-time communication service between Frappe and PLCs
- **React Dashboard**: Modern frontend for monitoring industrial processes

### Multi-Service Docker Architecture
The system uses a sophisticated Docker Compose override system allowing modular service configuration:

```bash
# Base services
compose.yaml

# Database options
overrides/compose.mariadb.yaml
overrides/compose.postgres.yaml

# Caching
overrides/compose.redis.yaml

# Industrial automation
overrides/compose.plc-bridge.yaml

# Platform-specific
overrides/compose.mac-m4.yaml  # ARM64 optimization
```

## ⚠️ CRITICAL: Always Use deploy.sh Script

**NEVER use `docker compose` commands directly!** This project requires specific environment variables and orchestration that only the deploy.sh script handles correctly.

### Container Management Rules
- ✅ **START/DEPLOY**: `./deploy.sh`
- ✅ **STOP**: `./deploy.sh stop` 
- ✅ **RESTART**: `./deploy.sh stop` followed by `./deploy.sh`
- ❌ **NEVER**: `docker compose up`, `docker compose down`, `docker compose restart`

### Why deploy.sh is Required
The deploy script handles:
- Custom image environment variables (`CUSTOM_IMAGE`, `CUSTOM_TAG`, `PULL_POLICY`)
- Complex Docker Compose override file orchestration
- Platform-specific configurations (ARM64 vs x86_64)
- EpiBus installation and site configuration
- Network and dependency management

**Manual docker compose commands WILL FAIL** because they don't have the required environment context.

## Essential Commands

### Lab Deployment
```bash
# Deploy complete lab environment
./deploy.sh

# Force rebuild of custom images
./deploy.sh --rebuild

# Stop and cleanup
./deploy.sh stop
```

The lab deployment automatically includes:
- Frappe/ERPNext ERP system
- EpiBus industrial integration app (automatically built and installed)
- MODBUS TCP server (port 502)
- PLC Bridge for real-time communication
- Traefik reverse proxy with custom domains
- Complete setup wizard automation
### Access Points

- **ERPNext Web Interface**: `http://intralogistics.lab`
- **Traefik Dashboard**: `http://dashboard.intralogistics.lab`
- **MODBUS TCP**: `localhost:502` (industrial communication)
- **PLC Bridge SSE**: `localhost:7654` (real-time events)
- **Login Credentials**: Username `Administrator`, Password `admin`

### Business Data Import & Backup

**NEW: Pre-configured Backup Workflow**
The repository now includes clean backups with business data that bypass the setup wizard entirely:

```bash
# Import business data from CSV files (if starting fresh)
./scripts/import_all_data.sh

# Restore pre-configured backup (recommended)
./scripts/restore_clean_backup.sh

# Create new clean backup after changes
docker compose exec backend bench --site intralogistics.lab backup --with-files
```

**Available Business Data:**
- **Companies**: Global Trade and Logistics (GTAL)
- **Item Groups**: 3D Printed Parts, Hardware, Products, Templates
- **Warehouses**: Hierarchical structure (All Warehouses → Picking, Receiving, Shipping, Storage)
- **Items**: 200+ product catalog including keychains, bracelets, 3D printed components
- **Item Attributes**: Color and Size variants with values

### Site Operations
```bash
# Install EpiBus app on existing site
docker compose exec backend bench --site intralogistics.lab install-app epibus

# Access backend container
docker compose exec backend bash

# Check service status
docker compose ps
```

### Development Workflows
```bash
# Development container setup (VSCode DevContainers)
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode
# Open in VSCode and "Reopen in Container"

# Manual development setup
docker compose -f .devcontainer/docker-compose.yml up -d
docker exec -it devcontainer-frappe-1 bash

# Install apps for development
cd frappe-bench
bench get-app --branch version-15 erpnext
bench --site development.localhost install-app erpnext
bench --site development.localhost install-app epibus
```

### Environment Configuration
```bash
# Required .env settings
cp example.env .env

# Essential variables:
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1


# IMPORTANT: Comment out external DB/Redis settings when using containerized services
# DB_HOST=
# DB_PORT=
# REDIS_CACHE=
# REDIS_QUEUE=
```

## Key Architectural Concepts

### Docker Compose Override System
The project uses a modular override system allowing flexible service combinations:
- **Base**: Core Frappe/ERPNext services (compose.yaml)
- **Database**: Choose MariaDB or PostgreSQL
- **Caching**: Redis services for performance
- **Industrial**: PLC Bridge for automation
- **Platform**: ARM64 optimizations for Mac M-series

### Lab Domain System
The lab deployment uses custom domain routing via Traefik:
- ERPNext: `intralogistics.lab`
- Traefik Dashboard: `dashboard.intralogistics.lab`
- MODBUS TCP: Fixed port 502
- PLC Bridge SSE: Port 7654

### EpiBus Industrial Integration
The EpiBus app provides:
- **MODBUS Communication**: Real-time PLC data exchange
- **Document Automation**: Frappe document events trigger PLC actions
- **Signal Monitoring**: Web-based dashboard for industrial signals
- **Event Logging**: Complete audit trail of industrial operations

### Platform Considerations
**Mac M-series (ARM64)**:
- Requires `compose.arm64.yaml` override
- Uses `platform: linux/arm64` for all services
- Optimized for Apple Silicon performance

**Linux/Intel (x86_64)**:
- Uses standard `linux/amd64` platform
- No additional platform overrides needed

## Testing and Quality

### Service Health Checks
```bash
# Check all service status
docker compose ps

# View service logs
docker compose logs configurator
docker compose logs backend
docker compose logs plc-bridge

# Test MODBUS connectivity
docker compose exec plc-bridge python -c "from pymodbus.client import ModbusTcpClient; client = ModbusTcpClient('localhost', 502); print(client.connect())"
```

### Database Operations
```bash
# Reset database (complete wipe)
docker compose down --volumes
docker volume rm frappe_docker_db-data frappe_docker_sites frappe_docker_redis-queue-data

# Database backup
docker compose exec backend bench --site localhost backup

# Database restore
docker compose exec backend bench --site localhost restore /path/to/backup
```

## Critical Implementation Details

### Service Dependencies
Services start in specific order managed by health checks:
1. Database (MariaDB/PostgreSQL)
2. Redis (cache and queue)
3. Configurator (initial setup)
4. Backend, Queue Workers, Scheduler
5. Frontend (Nginx proxy)
6. PLC Bridge (depends on Backend)

### Volume Management
- **sites**: Persistent Frappe sites data
- **db-data**: Database persistence
- **redis-queue-data**: Queue persistence
- **epibus**: EpiBus app source (development)

### Network Architecture
All services communicate via `frappe_network` Docker network with service discovery by service name.

### Security Considerations
- Database passwords in .env file
- API keys for PLC Bridge automatically generated
- .roo/ directory in .gitignore (contains API keys)
- No secrets in git history

## Troubleshooting Common Issues

### Container Issues
```bash
# Service stuck in spinning state
docker compose restart queue-long queue-short scheduler

# Database connection errors
# Check .env file - ensure external DB settings are commented when using containerized services

# Complete reset
docker compose down --volumes
docker volume prune
```

### Industrial Automation Issues
```bash
# PLC Bridge connection errors
docker compose logs plc-bridge

# MODBUS communication failures
docker compose exec plc-bridge telnet localhost 502
```

This architecture represents a unique integration of enterprise business software with industrial automation capabilities, requiring careful attention to service orchestration and multi-protocol communication.