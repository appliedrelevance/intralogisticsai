# Mac M-Series (ARM64) Deployment Guide

IntralogisticsAI is fully optimized for Apple Silicon Macs with automatic ARM64 configuration.

## Prerequisites

- **Docker Desktop for Mac** with Apple Silicon support
- **8GB+ RAM** recommended for complete stack
- **Git** for repository cloning

## Installation

### 1. Setup
```bash
git clone https://github.com/appliedrelevance/intralogisticsai
cd intralogisticsai
cp example.env .env
```

### 2. Deploy (Automatic ARM64 Detection)
```bash
# Training lab deployment (recommended)
./deploy.sh lab

# Or complete PLC stack
./deploy.sh with-plc
```

The deployment script automatically detects Mac ARM64 and applies the `compose.mac-m4.yaml` override.

## ARM64 Optimizations

### Automatic Platform Configuration
- **ARM64 Platform**: All services use `linux/arm64`
- **Native Performance**: Optimized for Apple Silicon
- **Dynamic Ports**: Prevents conflicts with automatic port assignment

### Mac-Specific Features
```yaml
services:
  frontend:
    platform: linux/arm64
    ports:
      - "0:8080"  # Dynamic port assignment
```

## Service Access

After deployment:
```bash
# Check assigned ports
docker compose ps

# Services will show:
# frontend: 0.0.0.0:32768->8080/tcp (example)
# openplc:  0.0.0.0:32769->8080/tcp (example)
```

**Access URLs:**
- **Main Interface**: http://localhost:[frontend-port]
- **OpenPLC**: http://localhost:[openplc-port]

## Troubleshooting

### Docker Desktop Issues
```bash
# Verify Docker is running
docker info

# Check Apple Silicon support
docker version | grep -i arch
```

### Performance Optimization
1. **Increase Docker Desktop RAM** to 8GB+ in Preferences
2. **Enable VirtioFS** for better file system performance
3. **Disable Docker Scout** if not needed

### Common Mac Issues

**Port Conflicts:**
```bash
# If you get port binding errors
sudo lsof -i :80  # Check what's using port 80
# Kill conflicting processes or use different ports
```

**Resource Limits:**
```bash
# Check Docker resource usage
docker stats

# Increase limits in Docker Desktop → Preferences → Resources
```

**Build Issues:**
```bash
# Clear Docker cache if builds fail
docker system prune -a
docker volume prune
```

## Development Setup

For Mac-specific development:
```bash
# Use development containers
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode

# Open in VS Code
code .
# Then: "Reopen in Container"
```

## Lab Environment on Mac

Perfect for instructor laptops running training labs:
```bash
./deploy.sh lab

# Configure local DNS
sudo echo "127.0.0.1 intralogistics.lab" >> /etc/hosts
sudo echo "127.0.0.1 openplc.lab" >> /etc/hosts
sudo echo "127.0.0.1 traefik.lab" >> /etc/hosts
```

## Performance Tips

1. **Use Rosetta 2 Emulation** only if needed for x86 images
2. **Close unnecessary apps** during deployment for more RAM
3. **Monitor Activity Monitor** for CPU/memory usage
4. **Use SSD storage** for Docker volumes (default on Mac)

## Platform Verification

Verify ARM64 deployment:
```bash
# Check platform configuration
docker compose config | grep platform

# Should show: platform: linux/arm64
```

---

**Note:** The deployment script automatically handles Mac ARM64 configuration. No manual platform settings required!