# PLC Bridge Setup and Usage Guide

This guide explains how to properly set up and run the PLC Bridge with the frappe_docker project.

## Important: Correct Docker Compose Command Structure

**The project uses `compose.yaml` as the base compose file.**

### Complete Setup Command

To run the full system with PLC Bridge and OpenPLC for macOS M-series chips:

```bash
docker-compose -f compose.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.traefik.yaml up -d
```

### Command Breakdown

1. **`compose.yaml`** - Base Frappe/ERPNext compose configuration
2. **`overrides/compose.mac-m4.yaml`** - Overrides for macOS M-series chips
3. **`overrides/compose.redis.yaml`** - Adds Redis services
4. **`overrides/compose.mariadb.yaml`** - Adds MariaDB service
5. **`overrides/compose.openplc.yaml`** - Adds OpenPLC simulator service
6. **`overrides/compose.plc-bridge.yaml`** - Adds PLC Bridge service
7. **`overrides/compose.traefik.yaml`** - Adds Traefik proxy service

## Services Included

When running the complete setup, you get these services:

- **Core Frappe Services**: backend, frontend, db, redis-cache, redis-queue, websocket, scheduler, queue-long, queue-short, configurator, create-site
- **OpenPLC Service**: openplc (PLC simulator)
- **PLC Bridge Service**: plc-bridge (real-time communication bridge)

## Environment Variables Required

Create a `.env` file in the project root with:

```bash
# Required for PLC Bridge
FRAPPE_API_KEY=your_api_key_here
FRAPPE_API_SECRET=your_api_secret_here

# Optional PLC Bridge settings
PLC_POLL_INTERVAL=1.0
PLC_LOG_LEVEL=INFO
```

## Service Dependencies

The PLC Bridge service:
- Depends on `backend` (Frappe) being started
- Depends on `openplc` being healthy
- Exposes port 7654 for SSE (Server-Sent Events)
- Provides real-time signal monitoring and control

## Verification Commands

### Check all services are running:
```bash
docker-compose -f compose.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.traefik.yaml ps
```

### View PLC Bridge logs:
```bash
docker-compose -f compose.yaml -f overrides/compose.mac-m4.yaml -f overrides/compose.redis.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.traefik.yaml logs plc-bridge
```

### Test PLC Bridge API:
```bash
curl http://localhost:7654/signals
```

## Individual Service Management

### Start only PLC Bridge (after base services):
```bash
docker-compose -f pwd.yml -f overrides/compose.plc-bridge.yaml up -d plc-bridge
```

### Stop PLC Bridge:
```bash
docker-compose -f pwd.yml -f overrides/compose.plc-bridge.yaml stop plc-bridge
```

### Rebuild PLC Bridge:
```bash
docker-compose -f pwd.yml -f overrides/compose.plc-bridge.yaml build plc-bridge
```

## Troubleshooting

### Common Issues

1. **Port 7654 already in use**
   ```bash
   # Find and kill processes using the port
   lsof -i :7654
   kill -9 <PID>
   ```

2. **API Key/Secret not set**
   - Ensure `.env` file exists with proper credentials
   - Generate API keys in Frappe: User > API Access > Generate Keys

3. **OpenPLC not accessible**
   - Verify OpenPLC is running: `docker-compose ... ps openplc`
   - Check OpenPLC logs: `docker-compose ... logs openplc`

### Health Checks

The PLC Bridge includes health checks that verify:
- SSE server is responding on port 7654
- `/signals` endpoint is accessible

## Integration with Frappe

The PLC Bridge integrates with Frappe through:

1. **API Endpoints**: Uses Frappe REST API to fetch signal configurations
2. **Real-time Updates**: Publishes signal changes back to Frappe
3. **Event Logging**: Logs all PLC events to Frappe for audit trails
4. **Action Execution**: Triggers Frappe Server Scripts based on signal changes

## Development

For development with live code changes:

```bash
# Add volume mount for live development
docker-compose -f pwd.yml -f overrides/compose.plc-bridge.yaml -f docker-compose.dev.yml up -d
```

Where `docker-compose.dev.yml` contains:
```yaml
services:
  plc-bridge:
    volumes:
      - ./epibus/plc/bridge:/app
```

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frappe    │◄──►│ PLC Bridge  │◄──►│   OpenPLC   │
│  (Backend)  │    │  (Port 7654)│    │ (Port 502)  │
│             │    │             │    │ Web: 8080   │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                   ▲
       │                   │
       ▼                   ▼
┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Web UI    │
│ (Port 8080) │    │   (SSE)     │
└─────────────┘    └─────────────┘
```

**Port Details:**
- **Frappe Frontend**: Port 8080 (HTTP)
- **PLC Bridge SSE**: Port 7654 (HTTP/SSE)
- **OpenPLC MODBUS**: Port 502 (MODBUS TCP)
- **OpenPLC Web Interface**: Port 8080 (HTTP)

## Next Steps

1. Set up your `.env` file with API credentials
2. Run the complete setup command
3. Access Frappe at http://localhost:8080
4. Configure Modbus connections and signals in Frappe
5. Monitor real-time data via PLC Bridge SSE endpoint