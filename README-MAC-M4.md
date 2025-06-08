# Frappe Docker for Mac M4 (ARM64) Setup Guide

This guide provides Mac M4-specific instructions for running Frappe/ERPNext on Apple Silicon systems using stable version 15 with MariaDB database.

## 🚀 Quick Start

### Prerequisites

1. **Docker Desktop for Mac** with Apple Silicon support
2. **Docker Compose** (included with Docker Desktop)
3. **Git** (for cloning the repository)

### Installation

1. Clone the repository and navigate to the directory:
   ```bash
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```

2. Create the environment configuration file:
   ```bash
   cp example.env .env
   ```

3. Edit the `.env` file with the following configuration:
   ```bash
   ERPNEXT_VERSION=version-15
   DB_PASSWORD=123
   HTTP_PUBLISH_PORT=55001
   FRAPPE_SITE_NAME_HEADER=intralogistics.localhost
   PROXY_READ_TIMEOUT=120s
   CLIENT_MAX_BODY_SIZE=50m
   UPSTREAM_REAL_IP_ADDRESS=127.0.0.1
   UPSTREAM_REAL_IP_HEADER=X-Forwarded-For
   UPSTREAM_REAL_IP_RECURSIVE=off
   ```

4. Start the services:
   ```bash
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml up -d
   ```

5. Create a new site:
   ```bash
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench new-site intralogistics.localhost --no-mariadb-socket --admin-password admin --db-root-password 123
   ```

6. Install ERPNext on the site:
   ```bash
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site intralogistics.localhost install-app erpnext
   ```

7. Access your ERPNext installation at: http://intralogistics.localhost:55001
   - **Username**: Administrator
   - **Password**: admin

## 📁 Configuration Files

### 1. `.env` - Environment Configuration
- **Purpose**: Defines stable version 15 and site configuration
- **Key Settings**:
  - `ERPNEXT_VERSION=version-15` - Uses stable version 15 (ERPNext 15.64.1, Frappe 15.69.3)
  - `DB_PASSWORD=123` - Database password
  - `HTTP_PUBLISH_PORT=55001` - Fixed port for consistent access
  - `FRAPPE_SITE_NAME_HEADER=intralogistics.localhost` - Site domain

### 2. `overrides/compose.mac-m4.yaml` - ARM64 Platform Override
- **Purpose**: Configures all services for ARM64 compatibility
- **Key Features**:
  - Sets `platform: linux/arm64` for all services
  - Ensures ARM64-compatible image usage
  - Optimizes network settings for Mac M4

### 3. `overrides/compose.redis.yaml` - Redis Services
- **Purpose**: Adds Redis cache and queue services
- **Features**:
  - Separate Redis instances for cache and queue
  - Persistent storage for queue data
  - Proper service dependencies

### 4. `overrides/compose.mariadb.yaml` - MariaDB Database
- **Purpose**: Provides MariaDB database service
- **Features**:
  - MariaDB 10.6 with UTF8MB4 support
  - Health checks for proper startup sequencing
  - Persistent database storage
  - Configured for Frappe/ERPNext requirements

## 🔧 Docker Compose Commands

### Service Management
```bash
# Start all services
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml up -d

# Stop all services
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml down

# View service status
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml ps

# View logs for all services
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml logs -f

# View logs for specific service
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml logs -f frontend
```

### Site Operations
```bash
# Create a new site
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench new-site SITE_NAME --no-mariadb-socket --admin-password ADMIN_PASSWORD --db-root-password DB_PASSWORD

# Install ERPNext on a site
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site SITE_NAME install-app erpnext

# Access backend shell
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bash

# Access bench console
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site SITE_NAME console

# Access MariaDB directly
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec db mysql -u root -p
```

## 🏗️ Architecture Details

### ARM64 Compatibility
- All services configured with `platform: linux/arm64`
- Uses stable ERPNext version 15 images with ARM64 support
- Optimized for Apple Silicon performance

### Service Configuration
- **Frontend**: Nginx proxy running on port 55001
- **Backend**: Frappe application server
- **WebSocket**: Real-time communication service
- **Queue Workers**: Background job processing (short and long)
- **Scheduler**: Cron-like task scheduling
- **Configurator**: Initial setup and configuration
- **Redis Cache**: Session and cache storage
- **Redis Queue**: Background job queue
- **Database**: MariaDB 10.6 database server

### Version Information
- **ERPNext**: 15.64.1 (stable)
- **Frappe**: 15.69.3 (stable)
- **Redis**: 6.2-alpine
- **MariaDB**: 10.6
- **Platform**: linux/arm64

## 🔍 Troubleshooting

### Version Issues

1. **Avoid unstable version 16**
   ```bash
   # Always use version-15 in .env file
   ERPNEXT_VERSION=version-15
   
   # If you accidentally used latest or version-16, recreate containers
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml down
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml pull
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml up -d
   ```

2. **Check current versions**
   ```bash
   # Check ERPNext version
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench version
   
   # Check Frappe version
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --version
   ```

### Common Issues

1. **Docker not running**
   ```bash
   # Check Docker status
   docker info
   
   # Start Docker Desktop if needed
   open -a Docker
   ```

2. **Port conflicts**
   ```bash
   # Check what's using port 55001
   lsof -i :55001
   
   # Change port in .env file if needed
   HTTP_PUBLISH_PORT=55002
   ```

3. **ARM64 compatibility issues**
   ```bash
   # Verify platform configuration
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml config | grep platform
   
   # Pull ARM64 images
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml pull
   ```

4. **Services not starting**
   ```bash
   # Check service logs
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml logs configurator
   
   # Check all service status
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml ps
   ```

5. **Site creation fails**
   ```bash
   # Check database connectivity
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site intralogistics.localhost mariadb
   
   # Check MariaDB service health
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec db mysqladmin ping -h localhost -p
   
   # Verify database password in .env matches the one used in site creation
   ```

6. **Cannot access site**
   ```bash
   # Check if site exists
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site intralogistics.localhost list-apps
   
   # Check frontend logs
   docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml logs frontend
   ```

### Performance Optimization

1. **Docker Desktop Settings**:
   - Allocate at least 4GB RAM
   - Enable VirtioFS for better file sharing performance
   - Use Apple Virtualization Framework

2. **Mac M4 Specific**:
   - Ensure sufficient disk space (at least 10GB free)
   - Close unnecessary applications to free up resources
   - Consider increasing Docker Desktop memory allocation for large datasets

## 📊 Service Ports

| Service | Internal Port | External Port | Access |
|---------|---------------|---------------|---------|
| Frontend | 8080 | 55001 | http://intralogistics.localhost:55001 |
| Backend | 8000 | Internal only | - |
| WebSocket | 9000 | Internal only | - |
| MariaDB | 3306 | Internal only | - |
| Redis Cache | 6379 | Internal only | - |
| Redis Queue | 6379 | Internal only | - |

## 🔐 Security Considerations

- Database password is configurable in `.env` file
- Services are isolated within Docker network
- Only frontend port is exposed externally
- All internal communication uses service names
- Default admin password should be changed after first login

## 📝 Customization

### Custom Domain
Edit `.env` file:
```bash
FRAPPE_SITE_NAME_HEADER=your-domain.localhost
HTTP_PUBLISH_PORT=8080  # Change port if needed
```

Then create site with the new domain:
```bash
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench new-site your-domain.localhost --no-mariadb-socket --admin-password admin --db-root-password 123
```

### Custom Images
Edit `.env` file:
```bash
CUSTOM_IMAGE=your-registry/frappe-custom
CUSTOM_TAG=your-tag
```

### Additional Apps
```bash
# Install additional Frappe apps
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench get-app APP_NAME
docker compose -f compose.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.mac-m4.yaml exec backend bench --site SITE_NAME install-app APP_NAME
```

## 🆘 Support

For issues specific to Mac M4 setup:
1. Check the troubleshooting section above
2. Verify you're using stable version 15 (`ERPNEXT_VERSION=version-15`)
3. Review service logs for specific error messages
4. Ensure all prerequisites are met

For general Frappe Docker issues:
- [Frappe Docker Documentation](https://github.com/frappe/frappe_docker)
- [Frappe Community Forum](https://discuss.frappe.io/)

## 📄 License

This configuration follows the same license as the main Frappe Docker project.