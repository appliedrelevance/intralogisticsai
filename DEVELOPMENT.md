# Development Guide for Intralogistics AI

This guide explains how to develop and modify the Intralogistics AI system with live editing capabilities.

## Development vs Production

### Production Deployment
- Uses `./deploy.sh lab` for complete industrial automation stack
- Code is baked into Docker images
- Requires rebuilds for code changes
- Optimized for stability and performance

### Development Deployment  
- Uses `./dev.sh` for development environment
- Code is mounted as live volumes from host
- Changes reflect immediately (Python requires restart)
- Enables rapid iteration and debugging

## Quick Start - Development Mode

```bash
# Start development environment
./dev.sh

# View logs
docker compose logs -f plc-bridge

# Restart service after code changes
docker compose restart plc-bridge
```

## Development Environment Features

### ✅ Live Editing Enabled For:
- **PLC Bridge**: `./epibus/plc/bridge/` → Container `/app/`
- **EpiBus App**: `./epibus/` → Container `/workspace/epibus/`  
- **CODESYS Projects**: `./plc_programs/` → Container `/plc_programs/`

### 🔧 Development Access Points:
- **PLC Bridge Dashboard**: http://localhost:7654
- **Enhanced Connection Details**: Shows actual PLC connection status
- **ERP System**: http://intralogistics.lab  
- **MODBUS TCP**: localhost:502
- **CODESYS Gateway**: localhost:1217

## File Structure & Editing

### PLC Bridge Development
**Location**: `./epibus/plc/bridge/`

Key files you can edit:
- `bridge.py` - Main PLC Bridge logic
- `config.py` - Configuration handling
- `requirements.txt` - Python dependencies

**After changes**: `docker compose restart plc-bridge`

### EpiBus App Development  
**Location**: `./epibus/epibus/`

Key files you can edit:
- `doctype/` - Frappe DocTypes (MODBUS Connection, Signal, etc.)
- `api/` - API endpoints
- `hooks.py` - Frappe hooks
- `templates/` - Web page templates

**After changes**: EpiBus changes require Frappe restart or bench restart

### CODESYS Projects
**Location**: `./plc_programs/`

- `codesys_project/` - Complete CODESYS project for Windows IDE
- `*.st` - Individual Structured Text programs
- `test_*.py` - MODBUS test scripts

## Development Commands

### Container Management
```bash
# Start development environment
./dev.sh

# Stop all services
docker compose down

# View service status  
docker compose ps

# View logs (follow)
docker compose logs -f [service-name]

# Shell access
docker compose exec [service-name] bash
```

### Service Restarts (After Code Changes)
```bash
# PLC Bridge (after Python changes)
docker compose restart plc-bridge

# Backend (after EpiBus changes)  
docker compose restart backend

# Full restart
docker compose down && ./dev.sh
```

### Testing & Debugging
```bash
# Test MODBUS connectivity
python3 plc_programs/test_modbus_docker.py

# Test PLC Bridge API
curl http://localhost:7654/signals
curl http://localhost:7654/connections

# View PLC Bridge logs
docker compose logs -f plc-bridge
```

## Common Development Tasks

### Adding Connection Details to PLC Bridge Dashboard

**Example completed**: We enhanced the PLC Bridge dashboard to show detailed connection information including:
- Connection target (host:port)
- Connection status (Connected/Failed/Unknown)
- Success/error counters
- Last error messages

**Files modified**:
- `epibus/plc/bridge/bridge.py` - Added `/connections` endpoint and enhanced dashboard HTML
- Changes were applied **without rebuilding containers** thanks to volume mounts

### Creating New MODBUS Signals
1. Edit `./epibus/epibus/fixtures/modbus_connection.json`
2. Add signals to EpiBus via the web interface
3. PLC Bridge automatically picks up new signals on restart

### Testing CODESYS Integration
1. Edit CODESYS projects in `./plc_programs/codesys_project/`
2. Deploy via Windows PC with CODESYS Development System
3. Connect to `localhost:1217` from CODESYS IDE

## Development Environment Architecture

```
Host File System          Docker Containers
├── epibus/plc/bridge/  →  plc-bridge:/app (live mount)
├── epibus/             →  backend:/workspace/epibus (live mount) 
├── plc_programs/       →  codesys:/plc_programs (live mount)
└── .env                →  Environment variables
```

### Docker Compose Files Used in Development:
- `compose.yaml` - Base services
- `overrides/compose.mariadb.yaml` - Database  
- `overrides/compose.redis.yaml` - Caching
- `overrides/compose.codesys.yaml` - PLC runtime
- `overrides/compose.plc-bridge.yaml` - PLC Bridge service
- `overrides/compose.development.yaml` - **Development volume mounts**
- `overrides/compose.mac-m4.yaml` - Mac ARM64 optimizations (if applicable)

## Troubleshooting Development Issues

### PLC Bridge Won't Start
```bash
# Check logs
docker compose logs plc-bridge

# Common issues:
# 1. Permission errors on entrypoint.sh
chmod +x epibus/plc/bridge/entrypoint.sh

# 2. Python syntax errors
# Fix in ./epibus/plc/bridge/bridge.py then restart

# 3. Missing dependencies  
# Add to ./epibus/plc/bridge/requirements.txt
```

### EpiBus Changes Not Reflecting
```bash
# EpiBus requires bench restart
docker compose exec backend bench --site intralogistics.localhost migrate
docker compose restart backend
```

### CODESYS Connection Issues
- Check MODBUS server is running: `docker compose logs codesys`  
- Verify port 502 is mapped: `docker compose ps | grep codesys`
- Test connectivity: `nc -zv localhost 502`

## Switching Back to Production

When you're done developing:
```bash
# Stop development environment
docker compose down

# Return to production deployment
./deploy.sh lab
```

## Best Practices

### Code Changes
- ✅ Make small, incremental changes
- ✅ Test changes immediately with `docker compose restart [service]`
- ✅ Use `docker compose logs -f [service]` to monitor
- ✅ Commit working changes frequently

### Volume Mounts
- ✅ Development volumes are **read-write** for live editing
- ✅ Log directories remain persistent across restarts
- ✅ Production uses baked images for stability

### Performance
- 🔧 Development has more verbose logging (`DEBUG` level)
- 🔧 Development polls more frequently for testing
- 🔧 Production optimized for efficiency and stability

This development environment solves the fundamental issue of not being able to edit container files from the host, enabling rapid iteration and debugging without container rebuilds.