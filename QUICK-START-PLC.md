# Quick Start: PLC Bridge with Frappe Docker

## ⚠️ IMPORTANT: Use pwd.yml as Base File

This project uses `pwd.yml` as the base compose file, **NOT** `compose.yaml`.

## Complete Setup Commands

### 1. Basic Frappe/ERPNext Only
```bash
docker-compose -f pwd.yml up -d
```

### 2. With OpenPLC Simulator
```bash
docker-compose -f pwd.yml -f overrides/compose.openplc.yaml up -d
```

### 3. Complete Setup: Frappe + OpenPLC + PLC Bridge
```bash
docker-compose -f pwd.yml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml up -d
```

## Environment Setup

Create `.env` file in project root:
```bash
# Required for PLC Bridge
FRAPPE_API_KEY=your_api_key_here
FRAPPE_API_SECRET=your_api_secret_here

# Optional
PLC_POLL_INTERVAL=1.0
PLC_LOG_LEVEL=INFO
```

## Service Access

- **Frappe/ERPNext**: http://localhost:8080 (admin/admin)
- **OpenPLC Web Interface**: http://localhost:8080 (admin/admin)
- **OpenPLC MODBUS**: Port 502 (MODBUS TCP)
- **PLC Bridge API**: http://localhost:7654/signals
- **PLC Bridge SSE**: http://localhost:7654/events

## Quick Verification

```bash
# Check all services
docker-compose -f pwd.yml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml ps

# Test PLC Bridge
curl http://localhost:7654/signals

# View logs
docker-compose -f pwd.yml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml logs plc-bridge
```

## File Structure

```
frappe_docker/
├── pwd.yml                           # Base compose file
├── overrides/
│   ├── compose.openplc.yaml         # OpenPLC service
│   └── compose.plc-bridge.yaml      # PLC Bridge service
└── epibus/plc/bridge/               # PLC Bridge source code
    ├── bridge.py                    # Main application
    ├── Dockerfile                   # Container definition
    └── requirements.txt             # Python dependencies
```

## Common Issues

1. **Wrong base file**: Always use `pwd.yml`, not `compose.yaml`
2. **Missing API keys**: Set `FRAPPE_API_KEY` and `FRAPPE_API_SECRET` in `.env`
3. **Port conflicts**: Ensure ports 7654 and 8080 are available

For detailed documentation, see [docs/plc-bridge-setup.md](docs/plc-bridge-setup.md)