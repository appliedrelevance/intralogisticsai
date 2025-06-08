# OpenPLC Integration with Frappe Docker

This repository now includes OpenPLC as a containerized service by building a custom Docker image from the official OpenPLC source code, ensuring ARM64 compatibility and running alongside Frappe, Redis, and MariaDB.

## Quick Start

### 1. Start All Services (including OpenPLC)

```bash
# For Mac M4/ARM64 systems:
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml up -d

# For other systems:
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml up -d
```

### 2. Access OpenPLC Web Interface

- **URL**: http://localhost:[auto-generated-port] (check `docker-compose ps` for the actual port)
- **Default Login**:
  - Username: `openplc`
  - Password: `openplc`

### 3. MODBUS TCP Access

- **Host**: `localhost` (or `openplc` from other containers)
- **Port**: `502`

## What's Included

### Files Added/Modified

- **`overrides/compose.openplc.yaml`** - Docker Compose override for OpenPLC service
- **`docs/openplc-integration.md`** - Comprehensive integration documentation

### Service Configuration

The OpenPLC service:
- ✅ Builds custom Docker image from official OpenPLC source code for ARM64 compatibility
- ✅ Exposes web interface on auto-generated port (avoids development conflicts)
- ✅ Provides MODBUS TCP server on port 502
- ✅ Uses persistent storage for programs and configuration
- ✅ Includes health checks and proper restart policies
- ✅ Connects to the same network as other frappe_docker services

## Environment Variables

Customize in your `.env` file:

```bash
# OpenPLC Log Level (default: INFO)
OPENPLC_LOG_LEVEL=INFO
```

**Note**: The web interface uses an auto-generated port to avoid development conflicts. Use `docker-compose ps` to find the actual port, or run `./get-openplc-port.sh` for a convenient summary. MODBUS TCP uses the standard port 502.

## Service Management

```bash
# For Mac M4/ARM64 systems:
# Start only OpenPLC
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml up -d openplc

# View OpenPLC logs
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml logs -f openplc

# Stop OpenPLC
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml stop openplc

# Rebuild OpenPLC image (if needed)
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml build openplc

# For other systems:
# Start only OpenPLC
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml up -d openplc

# View OpenPLC logs
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml logs -f openplc

# Stop OpenPLC
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml stop openplc

# Rebuild OpenPLC image (if needed)
docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml build openplc
```

## Integration with Frappe

### Network Connectivity

- **Internal**: Other containers can reach OpenPLC at `openplc:8080` (web) and `openplc:502` (MODBUS)
- **External**: Host machine can access via `localhost:[auto-generated-port]` (web) and `localhost:502` (MODBUS)

### Example Python Integration

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

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Frappe      │    │     OpenPLC     │    │     Redis       │
│   (Backend)     │◄──►│   (PLC Runtime) │    │    (Cache)      │
│   Port: 8000    │    │ Port: auto-gen  │    │   Port: 6379    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     MariaDB     │
                    │   (Database)    │
                    │   Port: 3306    │
                    └─────────────────┘
```

## Persistent Data

OpenPLC data is stored in the `openplc-data` Docker volume:
- Ladder logic programs
- Configuration settings
- Runtime data
- Historical information

### Backup/Restore

```bash
# Backup
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar czf /backup/openplc-backup.tar.gz -C /data .

# Restore
docker run --rm -v openplc-data:/data -v $(pwd):/backup alpine tar xzf /backup/openplc-backup.tar.gz -C /data
```

## Troubleshooting

### Image Issues

If the OpenPLC image fails to build or start:

1. Check available disk space for image building
2. Ensure Docker has sufficient memory allocated
3. Try rebuilding the image:
   ```bash
   # For Mac M4/ARM64:
   docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml build --no-cache openplc
   
   # For other systems:
   docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml build --no-cache openplc
   ```

### Service Issues

1. **Web interface not accessible**:
   ```bash
   # Check if service is running (Mac M4/ARM64)
   docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.openplc.yaml ps openplc
   
   # Check if service is running (other systems)
   docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml ps openplc
   
   # Check logs for issues (use same compose command as above based on your system)
   docker-compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml logs openplc
   ```

2. **MODBUS connection issues**:
   ```bash
   # Test MODBUS connectivity
   python -c "from pymodbus.client.sync import ModbusTcpClient; client = ModbusTcpClient('localhost', 502); print('Connected:', client.connect())"
   ```

## Documentation

- **[Complete Integration Guide](docs/openplc-integration.md)** - Detailed documentation
- **[OpenPLC Official Docs](https://openplc.com/)** - OpenPLC documentation
- **[Frappe Docker](https://github.com/frappe/frappe_docker)** - Base frappe_docker project

## Security Notes

- Change default OpenPLC credentials after first login
- Consider firewall rules for production deployments
- Use HTTPS/SSL for production web access
- Integrate with Frappe's authentication system if needed

---

**Status**: ✅ Ready for use - OpenPLC service builds from official source code and is fully functional