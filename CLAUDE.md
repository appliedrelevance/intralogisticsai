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
- **OpenPLC**: PLC simulator for development and testing
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
overrides/compose.openplc.yaml
overrides/compose.plc-bridge.yaml

# Platform-specific
overrides/compose.mac-m4.yaml  # ARM64 optimization
```

## ⚠️ CRITICAL: Always Use deploy.sh Script

**NEVER use `docker compose` commands directly!** This project requires specific environment variables and orchestration that only the deploy.sh script handles correctly.

### Container Management Rules
- ✅ **START/DEPLOY**: `./deploy.sh lab` (or other deploy options)
- ✅ **STOP**: `./deploy.sh stop` 
- ✅ **RESTART**: `./deploy.sh stop` followed by `./deploy.sh lab`
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

### Complete Industrial Automation Setup (Mac M-series ARM64)
```bash
# STEP 1: Build custom image with EpiBus (required for complete functionality)
./development/build-epibus-image.sh

# STEP 2: Configure environment for custom image
export CUSTOM_IMAGE=frappe-epibus
export CUSTOM_TAG=latest
export PULL_POLICY=never

# STEP 3: Deploy complete stack with EpiBus integration
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.create-site.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d

# STEP 4: Install EpiBus on the created site (after deployment completes)
docker compose exec backend bench --site intralogistics.localhost install-app epibus

# Standard setup without PLC integration
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.mac-m4.yaml \
  up -d
```

### Complete Industrial Automation Setup (Linux/Intel Mac x86_64)
```bash
# STEP 1: Build custom image with EpiBus (required for complete functionality)
./development/build-epibus-image.sh

# STEP 2: Configure environment for custom image
export CUSTOM_IMAGE=frappe-epibus
export CUSTOM_TAG=latest
export PULL_POLICY=never

# STEP 3: Deploy complete stack with EpiBus integration
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.create-site.yaml \
  up -d

# STEP 4: Install EpiBus on the created site (after deployment completes)
docker compose exec backend bench --site intralogistics.localhost install-app epibus
```

## Complete Deployment Overview

The above commands deploy a **complete industrial automation stack** including:

✅ **Frappe/ERPNext ERP System** - Business platform with web interface  
✅ **EpiBus Industrial App** - Custom Frappe app for industrial integration  
✅ **OpenPLC Simulator** - Industrial PLC programming environment  
✅ **MODBUS TCP Server** - Industrial communication protocol (port 502)  
✅ **PLC Bridge Service** - Real-time data exchange between PLC and ERP  
✅ **MariaDB Database** - Persistent data storage  
✅ **Redis Cache/Queue** - Performance optimization  
✅ **Automatic Site Creation** - Site `intralogistics.localhost` created automatically  

### Verification Steps

After deployment, verify the system is working:

```bash
# Check all services are healthy
docker compose ps

# Test ERPNext web interface (note the dynamic port)
curl -I http://localhost:$(docker ps | grep frontend | sed 's/.*:\([0-9]*\)->8080.*/\1/')/ 
# Should return HTTP 200 OK

# Test OpenPLC web interface  
curl -I http://localhost:$(docker ps | grep openplc | sed 's/.*:\([0-9]*\)->8080.*/\1/')/ 
# Should return HTTP 302 (redirect to login)

# Test EpiBus API integration
curl http://localhost:$(docker ps | grep frontend | sed 's/.*:\([0-9]*\)->8080.*/\1/')/api/method/epibus.api.plc.get_signals
# Should return {"message":[]} (empty signals list for fresh installation)
```

### Access Points

- **ERPNext Web Interface**: `http://localhost:[dynamic-port]` (check port with `docker compose ps`)
- **OpenPLC Web Interface**: `http://localhost:[dynamic-port]` (check port with `docker compose ps`)  
- **MODBUS TCP**: `localhost:502` (industrial communication)
- **PLC Bridge SSE**: `localhost:7654` (real-time events)
- **Login Credentials**: Username `Administrator`, Password `admin`

### Site Operations
```bash
# Create new site with ERPNext
docker compose exec backend bench new-site intralogistics.localhost --admin-password admin --db-root-password 123 --install-app erpnext

# Install EpiBus app on existing site
docker compose exec backend bench --site intralogistics.localhost install-app epibus

# Access backend container
docker compose exec backend bash

# Check service status
docker compose ps
```

### OpenPLC Operations
```bash


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
- **Industrial**: OpenPLC and PLC Bridge for automation
- **Platform**: ARM64 optimizations for Mac M-series

### Dynamic Port Assignment
Services use dynamic port mapping to prevent conflicts:
- Frontend: Auto-assigned port (check with `docker compose ps`)
- OpenPLC Web: Auto-assigned port (use `get-openplc-port.sh`)
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
- Requires `compose.mac-m4.yaml` override
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
docker compose exec plc-bridge python -c "from pymodbus.client import ModbusTcpClient; client = ModbusTcpClient('openplc', 502); print(client.connect())"
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
6. OpenPLC (if using industrial features)
7. PLC Bridge (depends on OpenPLC and Backend)

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

# OpenPLC not accessible
./get-openplc-port.sh
# Check if port is properly mapped

# MODBUS communication failures
docker compose exec plc-bridge telnet openplc 502
```

This architecture represents a unique integration of enterprise business software with industrial automation capabilities, requiring careful attention to service orchestration and multi-protocol communication.