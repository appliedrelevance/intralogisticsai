# OpenPLC Integration with Frappe Docker

This document explains how to run OpenPLC as a service alongside Frappe in the frappe_docker environment.

## Overview

OpenPLC is now integrated as a Docker service that runs alongside Redis, MariaDB, and Frappe services. It provides:

- **Web Interface**: OpenPLC web-based programming and monitoring interface
- **MODBUS TCP Server**: Industrial protocol support for PLC communication
- **Persistent Storage**: Configuration and programs are preserved across container restarts

## Quick Start

### 1. Start OpenPLC Service

```bash
# Start OpenPLC alongside other frappe_docker services
docker-compose -f compose.yaml -f overrides/compose.openplc.yaml up -d
```

### 2. Access OpenPLC Web Interface

- **URL**: http://localhost:[auto-generated-port] (check `docker-compose ps` for the actual port)
- **Default Credentials**:
  - Username: `openplc`
  - Password: `openplc`

### 3. MODBUS TCP Access

- **Host**: `localhost` (or container name `openplc` from other containers)
- **Port**: `502`
- **Protocol**: MODBUS TCP

## Configuration

### Environment Variables

You can customize OpenPLC behavior using environment variables in a `.env` file:

```bash
# OpenPLC Log Level (default: INFO)
OPENPLC_LOG_LEVEL=INFO
```

**Note**: The web interface uses an auto-generated port to avoid development conflicts. Use `docker-compose ps` to find the actual port. MODBUS TCP uses the standard port 502.

### Service Configuration

The OpenPLC service is configured in `overrides/compose.openplc.yaml`:

- **Build Context**: Uses the existing `OpenPLC_v3/` directory
- **Persistent Storage**: Volume `openplc-data` for configuration and programs
- **Health Checks**: Automatic monitoring of service health
- **Network**: Connected to the same network as other frappe_docker services

## Integration with Frappe

### Network Connectivity

OpenPLC runs on the same Docker network as Frappe services, enabling:

- **Internal Communication**: Other containers can reach OpenPLC at `openplc:8080` (web) and `openplc:502` (MODBUS)
- **External Access**: Host machine can access via `localhost:[auto-generated-port]` (web) and `localhost:502` (MODBUS)

### Data Exchange

You can integrate OpenPLC with Frappe applications by:

1. **MODBUS Communication**: Use Python MODBUS libraries in Frappe to read/write PLC data
2. **REST API**: OpenPLC provides REST endpoints for programmatic access
3. **Database Integration**: Store PLC data in Frappe DocTypes for reporting and analysis

## Service Management

### Start Only OpenPLC

```bash
docker-compose -f compose.yaml -f overrides/compose.openplc.yaml up -d openplc
```

### View OpenPLC Logs

```bash
docker-compose -f compose.yaml -f overrides/compose.openplc.yaml logs -f openplc
```

### Stop OpenPLC

```bash
docker-compose -f compose.yaml -f overrides/compose.openplc.yaml stop openplc
```

### Rebuild OpenPLC

```bash
docker-compose -f compose.yaml -f overrides/compose.openplc.yaml build --no-cache openplc
```

## Persistent Data

OpenPLC data is stored in the `openplc-data` Docker volume, which includes:

- **Programs**: Ladder logic and structured text programs
- **Configuration**: Hardware settings and communication parameters
- **Database**: Runtime data and historical information

### Backup Data

```bash
# Create backup of OpenPLC data
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar czf /backup/openplc-backup.tar.gz -C /data .
```

### Restore Data

```bash
# Restore OpenPLC data from backup
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar xzf /backup/openplc-backup.tar.gz -C /data
```

## Troubleshooting

### Service Won't Start

1. Check if ports are available:
   ```bash
   netstat -ln | grep -E ':(8081|502)'
   ```

2. View service logs:
   ```bash
   docker-compose -f compose.yaml -f overrides/compose.openplc.yaml logs openplc
   ```

### Web Interface Not Accessible

1. Verify service is running:
   ```bash
   docker-compose -f compose.yaml -f overrides/compose.openplc.yaml ps openplc
   ```

2. Check health status:
   ```bash
   docker-compose -f compose.yaml -f overrides/compose.openplc.yaml exec openplc /workdir/entrypoint.sh health
   ```

### MODBUS Connection Issues

1. Test MODBUS connectivity:
   ```bash
   # Install modbus tools
   pip install pymodbus

   # Test connection
   python -c "from pymodbus.client.sync import ModbusTcpClient; client = ModbusTcpClient('localhost', 502); print('Connected:', client.connect())"
   ```

## Development

### Custom Programs

1. Access the web interface at http://localhost:[auto-generated-port] (check `docker-compose ps` for the actual port)
2. Navigate to "Programs" section
3. Create new ladder logic or structured text programs
4. Compile and run programs on the virtual PLC

### Integration Examples

Example Python code for Frappe integration:

```python
# In a Frappe DocType method
from pymodbus.client.sync import ModbusTcpClient

def read_plc_data(self):
    """Read data from OpenPLC via MODBUS TCP"""
    client = ModbusTcpClient('openplc', 502)
    
    if client.connect():
        # Read holding registers
        result = client.read_holding_registers(0, 10)
        if not result.isError():
            return result.registers
    
    client.close()
    return None
```

## Security Considerations

- **Default Credentials**: Change default OpenPLC credentials after first login
- **Network Access**: Consider firewall rules for production deployments
- **HTTPS**: Configure reverse proxy with SSL for production web access
- **Authentication**: Integrate with Frappe's authentication system if needed

## Support

For OpenPLC-specific issues:
- **Documentation**: https://openplc.com/
- **GitHub**: https://github.com/thiagoralves/OpenPLC_v3

For integration issues with frappe_docker:
- Check the `overrides/compose.openplc.yaml` configuration
- Review container logs for error messages
- Ensure network connectivity between services