# Frappe Docker for Mac M4 (ARM64) Setup Guide

This guide provides Mac M4-specific configuration files and scripts for running Frappe Docker with ARM64 compatibility and port collision prevention.

## 🚀 Quick Start

### Prerequisites

1. **Docker Desktop for Mac** with Apple Silicon support
2. **Docker Buildx** (included with Docker Desktop)
3. **Git** (for cloning the repository)

### Installation

1. Clone the repository and navigate to the directory:
   
   ```bash
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```

2. Run the Mac M4 setup script:
   
   ```bash
   ./setup-mac-m4.sh
   ```

3. Get your access URL:
   
   ```bash
   ./get-access-url.sh
   ```

## 📁 Mac M4 Specific Files

### 1. `.env` - Environment Configuration

- **Purpose**: Optimized environment variables for Mac M4
- **Key Features**:
  - Uses `ERPNEXT_VERSION=latest` for ARM64 compatibility
  - Secure database password generation
  - Ephemeral port assignment to prevent conflicts
  - Mac-optimized performance settings

### 2. `overrides/compose.mac-m4.yaml` - Docker Compose Override

- **Purpose**: ARM64 platform configuration for all services
- **Key Features**:
  - Sets `platform: linux/arm64` for all services
  - Configures ephemeral port assignment for frontend
  - Optimizes network settings for Mac M4
  - Ensures ARM64-compatible image usage

### 3. `setup-mac-m4.sh` - Setup Script

- **Purpose**: Automated setup and deployment script
- **Features**:
  - Docker and Buildx availability checks
  - ARM64 buildx builder configuration
  - Service startup with proper error handling
  - Port discovery and access URL generation
  - Colored output for better user experience

### 4. `get-access-url.sh` - Access Helper Script

- **Purpose**: Discover dynamically assigned ports and service status
- **Features**:
  - Dynamic port discovery
  - Service health checking
  - Log viewing capabilities
  - Comprehensive service status reporting

## 🔧 Usage Commands

### Setup and Management

```bash
# Full setup (recommended for first time)
./setup-mac-m4.sh

# Build ARM64 images only
./setup-mac-m4.sh build

# Start services only
./setup-mac-m4.sh start

# Stop all services
./setup-mac-m4.sh stop

# Check service status
./setup-mac-m4.sh status
```

### Access and Monitoring

```bash
# Get access URL and service status
./get-access-url.sh

# Check detailed service status
./get-access-url.sh status

# View frontend service logs
./get-access-url.sh logs

# View specific service logs
./get-access-url.sh logs backend

# Perform health check
./get-access-url.sh health

# Show help
./get-access-url.sh help
```

### Manual Docker Compose Commands

```bash
# Start services with Mac M4 overrides
docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml up -d

# Stop services
docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml down

# View service status
docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml ps

# View logs
docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml logs -f frontend
```

## 🏗️ Architecture Details

### ARM64 Compatibility

- All services configured with `platform: linux/arm64`
- Uses latest ERPNext images with ARM64 support
- Docker Buildx configured for ARM64 builds
- Optimized for Apple Silicon performance

### Port Management

- **Ephemeral Port Assignment**: Prevents conflicts with existing services
- **Dynamic Discovery**: Scripts automatically find assigned ports
- **Flexible Configuration**: Easy to override ports if needed

### Service Configuration

- **Frontend**: Nginx proxy with ARM64 optimization
- **Backend**: Frappe application server
- **WebSocket**: Real-time communication service
- **Queue Workers**: Background job processing
- **Scheduler**: Cron-like task scheduling
- **Configurator**: Initial setup and configuration

## 🔍 Troubleshooting

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
   # Check what's using ports
   lsof -i :8080
   
   # The setup uses ephemeral ports to avoid this
   ./get-access-url.sh
   ```

3. **ARM64 compatibility issues**
   
   ```bash
   # Verify platform
   docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml config | grep platform
   
   # Rebuild with ARM64
   ./setup-mac-m4.sh build
   ```

4. **Services not starting**
   
   ```bash
   # Check service logs
   ./get-access-url.sh logs
   
   # Check individual service
   ./get-access-url.sh logs configurator
   ```

### Performance Optimization

1. **Docker Desktop Settings**:
   
   - Allocate at least 4GB RAM
   - Enable VirtioFS for better file sharing performance
   - Use Apple Virtualization Framework

2. **Mac M4 Specific**:
   
   - Ensure Rosetta 2 is installed: `softwareupdate --install-rosetta`
   - Close unnecessary applications to free up resources

## 📊 Service Ports

| Service   | Internal Port | External Port        |
| --------- | ------------- | -------------------- |
| Frontend  | 8080          | Dynamically assigned |
| Backend   | 8000          | Internal only        |
| WebSocket | 9000          | Internal only        |
| Database  | 3306          | Internal only        |
| Redis     | 6379          | Internal only        |

## 🔐 Security Considerations

- Database password is set to a secure default in `.env`
- Services are isolated within Docker network
- Only frontend port is exposed externally
- All internal communication uses service names

## 📝 Customization

### Custom Images

Edit `.env` file:

```bash
CUSTOM_IMAGE=your-registry/frappe-custom
CUSTOM_TAG=your-tag
```

### Custom Ports

Edit `.env` file:

```bash
HTTP_PUBLISH_PORT=8080  # Set specific port instead of ephemeral
```

### Additional Overrides

Create additional override files in `overrides/` directory and include them:

```bash
docker compose -f compose.yaml -f overrides/compose.mac-m4.yaml -f overrides/your-custom.yaml up -d
```

## 🆘 Support

For issues specific to Mac M4 setup:

1. Check the troubleshooting section above
2. Review service logs: `./get-access-url.sh logs`
3. Verify Docker Desktop configuration
4. Ensure all prerequisites are met

For general Frappe Docker issues:

- [Frappe Docker Documentation](https://github.com/frappe/frappe_docker)
- [Frappe Community Forum](https://discuss.frappe.io/)

## 📄 License

This configuration follows the same license as the main Frappe Docker project.