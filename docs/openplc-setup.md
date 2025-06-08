# OpenPLC Simulator Setup

This guide covers setting up the OpenPLC simulator as part of your Frappe Docker environment. OpenPLC provides a complete PLC (Programmable Logic Controller) simulation environment that integrates with the EpiBus module for industrial automation and logistics education.

## What's New

**Simplified Setup**: The OpenPLC integration now uses the official OpenPLC_v3 Dockerfile directly, eliminating the need for custom container images. This ensures:

- **Always Up-to-Date**: Uses the latest official OpenPLC release
- **Simplified Maintenance**: No custom Dockerfile to maintain
- **Better Compatibility**: Direct compatibility with official OpenPLC documentation
- **Auto-Generated Ports**: Web interface uses auto-generated ports to avoid conflicts

## Overview

The OpenPLC integration provides:

- **Complete PLC Runtime Environment**: Full-featured OpenPLC simulator with web-based programming interface
- **MODBUS TCP Server**: Industry-standard MODBUS communication protocol on port 502
- **Web Management Interface**: Browser-based configuration and monitoring on auto-generated port
- **Persistent Storage**: Program files, logs, and configurations are preserved across container restarts
- **EpiBus Integration**: Ready for connection with Frappe's EpiBus module for warehouse automation scenarios

## Port Configuration

The OpenPLC container exposes two essential ports:

| Port | Protocol | Purpose | Access URL |
|------|----------|---------|------------|
| Auto-generated | HTTP | Web Interface | Check `docker port <container>` for actual port |
| 502 | TCP | MODBUS Server | `modbus://localhost:502` |

### Port Mapping Details

- **Web Interface Port**: Auto-generated to avoid conflicts with other services. Use `docker port` command to find the actual port
- **Port 502 (MODBUS TCP)**: Direct mapping for standard MODBUS communication, used by EpiBus and external MODBUS clients

## Quick Setup

### Basic OpenPLC Setup

To add OpenPLC to your existing Frappe Docker setup:

```bash
# Generate configuration with OpenPLC
docker compose -f compose.yaml \
  -f overrides/compose.openplc.yaml \
  config > ~/gitops/docker-compose.yml

# Start containers
docker compose --project-name <project-name> -f ~/gitops/docker-compose.yml up -d
```

### Setup with MariaDB, Redis, and OpenPLC

For a complete development environment:

```bash
# Generate configuration
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  config > ~/gitops/docker-compose.yml

# Start containers
docker compose --project-name <project-name> -f ~/gitops/docker-compose.yml up -d
```

### Setup with HTTPS and OpenPLC

For production with SSL certificates:

```bash
# Ensure LETSENCRYPT_EMAIL and SITES are set in .env
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.https.yaml \
  -f overrides/compose.openplc.yaml \
  config > ~/gitops/docker-compose.yml

# Start containers
docker compose --project-name <project-name> -f ~/gitops/docker-compose.yml up -d
```

## Environment Variables

Configure OpenPLC behavior by setting these variables in your `.env` file:

### OpenPLC-Specific Variables

```bash
# Port for OpenPLC Modbus TCP server (default: 502)
OPENPLC_MODBUS_PORT=502

# Internal web port (container port, default: 8080)
OPENPLC_WEB_PORT=8080

# Logging level for OpenPLC runtime (INFO, DEBUG, WARNING, ERROR)
OPENPLC_LOG_LEVEL=INFO
```

**Note**: The web interface uses an auto-generated external port to avoid conflicts. Use `docker port <container-name>` to find the actual port.

### Example .env Configuration

```bash
# Copy example environment file
cp example.env .env

# Edit the file to include OpenPLC settings
nano .env
```

The `example.env` file already includes OpenPLC configuration with sensible defaults.

## Access URLs

After starting the containers, access the services at:

### OpenPLC Web Interface
- **URL**: Use `docker port <container-name>` to find the auto-generated port, then access `http://localhost:<port>`
- **Default Login**:
  - Username: `openplc`
  - Password: `openplc`

**Finding the Web Interface Port**:
```bash
# Find the auto-generated port
docker port <project-name>-openplc-1 8080

# Example output: 0.0.0.0:52889
# Then access: http://localhost:52889
```

### MODBUS TCP Connection
- **Host**: `localhost` (or your Docker host IP)
- **Port**: `502`
- **Protocol**: MODBUS TCP

### Frappe/ERPNext Interface
- **URL**: Use `docker compose ps` to find the auto-assigned port for the frontend service

## Container Health Monitoring

The OpenPLC container includes health checks that verify:

- Web interface accessibility on port 8080 (internal)
- Service startup completion (60-second grace period)
- Automatic restart on failure

Monitor container health:

```bash
# Check container status
docker compose --project-name <project-name> ps

# View OpenPLC logs
docker compose --project-name <project-name> logs openplc

# Follow real-time logs
docker compose --project-name <project-name> logs -f openplc
```

## Data Persistence

OpenPLC data is persisted in the `openplc-data` Docker volume, which includes:

- **Program Files**: Structured Text (ST) programs and compiled binaries
- **Configuration**: Runtime settings and hardware configurations
- **Logs**: System and runtime logs for debugging
- **Upload Directory**: User-uploaded programs and libraries

### Backup and Restore

```bash
# Create backup of OpenPLC data
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar czf /backup/openplc-backup.tar.gz -C /data .

# Restore from backup
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar xzf /backup/openplc-backup.tar.gz -C /data
```

## Troubleshooting

### Common Port Conflicts

**Problem**: Cannot access OpenPLC web interface
```bash
# Find the auto-generated port
docker port <project-name>-openplc-1 8080

# Check if container is running
docker compose ps openplc

# Check container logs
docker compose logs openplc
```

**Problem**: Port 502 already in use (common with other MODBUS services)
```bash
# Check port usage
sudo netstat -tlnp | grep :502

# Change MODBUS port in .env
OPENPLC_MODBUS_PORT=5020
```

### Container Startup Issues

**Problem**: OpenPLC container fails to start
```bash
# Check container logs
docker compose logs openplc

# Common solutions:
# 1. Ensure ports are available
# 2. Check Docker daemon is running
# 3. Verify .env file configuration
# 4. Restart Docker service
```

**Problem**: Health check failures
```bash
# Find the auto-generated port first
OPENPLC_PORT=$(docker port <project-name>-openplc-1 8080 | cut -d: -f2)

# Check if web interface is responding
curl -f http://localhost:$OPENPLC_PORT/login

# If failing, check internal container health
docker compose exec openplc curl -f http://localhost:8080/login
```

### Network Connectivity

**Problem**: Cannot connect to MODBUS from external clients
```bash
# Test MODBUS connectivity
telnet localhost 502

# Check firewall settings (Linux)
sudo ufw status
sudo ufw allow 502

# Check Docker network
docker network ls
docker network inspect <network-name>
```

## EpiBus Integration

The OpenPLC container is configured to work seamlessly with the EpiBus module:

### Connection Configuration

In EpiBus MODBUS settings:
- **Host**: `openplc` (container name) or `localhost` (from host)
- **Port**: `502`
- **Unit ID**: `1` (default)

### Environment Variables for EpiBus

The configurator service automatically sets these variables when OpenPLC is enabled:

```yaml
OPENPLC_HOST: openplc
OPENPLC_PORT: 502
OPENPLC_WEB_PORT: 8081
```

### Sample PLC Programs

The OpenPLC container includes sample programs for logistics scenarios:

1. **Intralogistics Simulator**: Warehouse automation with conveyor belts and sensors
2. **Beachside PSM**: Port simulation with cranes and container handling

Access these through the OpenPLC web interface under "Programs" section.

## Advanced Configuration

### Custom OpenPLC Programs

Upload your own Structured Text programs:

1. Find the OpenPLC web interface port: `docker port <project-name>-openplc-1 8080`
2. Access the web interface at `http://localhost:<port>`
3. Navigate to "Programs" → "Upload Program"
4. Select your `.st` file and upload
5. Compile and start the program

### Runtime Configuration

Modify runtime behavior through environment variables:

```bash
# Enable debug mode
OPENPLC_DEBUG=true

# Custom runtime port (if different from MODBUS port)
OPENPLC_RUNTIME_PORT=502

# Web interface port (internal container port)
OPENPLC_WEB_PORT=8080
```

### Integration with External Systems

Connect external MODBUS clients:

```python
# Python example using pymodbus
from pymodbus.client.sync import ModbusTcpClient

client = ModbusTcpClient('localhost', port=502)
result = client.read_holding_registers(0, 10, unit=1)
print(result.registers)
client.close()
```

## Security Considerations

### Default Credentials

**Important**: Change default OpenPLC credentials in production:

1. Find the web interface port: `docker port <project-name>-openplc-1 8080`
2. Access web interface at `http://localhost:<port>`
3. Login with `openplc`/`openplc`
4. Navigate to "Settings" → "Users"
5. Change default password

### Network Security

- OpenPLC ports are exposed to localhost by default
- For production, consider using reverse proxy or VPN
- Implement firewall rules for MODBUS port 502
- Use HTTPS for web interface in production environments

### Container Security

The OpenPLC container runs with:
- Non-root user where possible
- Minimal attack surface
- Health checks for monitoring
- Automatic restart on failure

## Performance Tuning

### Resource Allocation

Monitor and adjust container resources:

```bash
# Check resource usage
docker stats openplc

# Limit CPU and memory (in compose override)
services:
  openplc:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### Logging Configuration

Control log verbosity:

```bash
# Set log level in .env
OPENPLC_LOG_LEVEL=WARNING  # Reduces log volume

# View logs with timestamps
docker compose logs -t openplc
```

## Next Steps

1. **Create First Site**: Follow [site operations](./site-operations.md#setup-new-site) to set up Frappe
2. **Install EpiBus**: Add the EpiBus app to your site for MODBUS integration
3. **Configure MODBUS Connection**: Set up EpiBus to connect to OpenPLC
4. **Upload PLC Programs**: Use the sample logistics programs or create your own
5. **Test Integration**: Verify communication between EpiBus and OpenPLC

For more information on EpiBus configuration, refer to the EpiBus documentation in the `epibus/` directory.