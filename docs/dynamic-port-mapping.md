# Dynamic Port Mapping in Frappe Docker

This document explains the dynamic port mapping implementation across the Frappe Docker composition to eliminate port conflicts and improve portability.

## Overview

Dynamic port mapping allows Docker to automatically assign available ports to services, preventing conflicts when running multiple instances or when specific ports are already in use by other applications.

## What Changed

### Port Mapping Conversion

All static port mappings have been converted to dynamic mappings using the format `"0:internal_port"` where `0` tells Docker to auto-assign an available port.

**Before (Static):**
```yaml
ports:
  - "8080:8080"  # Always tries to use port 8080
```

**After (Dynamic):**
```yaml
ports:
  - "0:8080"     # Auto-assigns available port -> internal port 8080
```

### Files Modified

1. **`overrides/compose.noproxy.yaml`**
   - Frontend service: `"${HTTP_PUBLISH_PORT:-0}:8080"`

2. **`overrides/compose.traefik.yaml`**
   - Traefik service: `"${HTTP_PUBLISH_PORT:-0}:80"`

3. **`overrides/compose.traefik-ssl.yaml`**
   - Traefik HTTPS service: `"${HTTPS_PUBLISH_PORT:-0}:443"`

4. **`overrides/compose.openplc.yaml`** (already implemented)
   - OpenPLC web interface: `"8080"` (shorthand for `"0:8080"`)
   - OpenPLC MODBUS TCP: `"502:502"` (kept static for protocol compliance)

### Documentation Updates

- **`README.md`**: Updated to mention using `docker compose ps` to find ports
- **`docs/setup_for_linux_mac.md`**: Updated port mapping and instructions
- **`docs/openplc-setup.md`**: Updated Frappe/ERPNext access instructions

## Benefits

### 1. **Eliminates Port Conflicts**
- No more "port already in use" errors
- Multiple instances can run simultaneously
- Development and production can coexist

### 2. **Improved Portability**
- Works on any system regardless of port availability
- No need to modify configurations for different environments
- Easier CI/CD deployment

### 3. **Better Developer Experience**
- No manual port management required
- Automatic conflict resolution
- Simplified multi-instance testing

## Finding Service Ports

### Using Docker Compose
```bash
# Show all services and their ports
docker compose ps

# Example output:
# NAME                    COMMAND                  SERVICE    STATUS    PORTS
# project-frontend-1      "nginx-entrypoint.sh"   frontend   Up        0.0.0.0:52341->8080/tcp
# project-openplc-1       "/docker-entrypoint.…"   openplc    Up        0.0.0.0:52342->8080/tcp, 502:502/tcp
```

### Using Docker Port Command
```bash
# Get specific service port
docker port <container-name> <internal-port>

# Examples:
docker port project-frontend-1 8080
# Output: 0.0.0.0:52341

docker port project-openplc-1 8080
# Output: 0.0.0.0:52342
```

### Using Existing Scripts
The `get-openplc-port.sh` script already works with dynamic ports and provides a convenient way to find OpenPLC service information.

## Environment Variable Override

You can still specify static ports when needed by setting environment variables:

```bash
# Force specific ports (use with caution)
export HTTP_PUBLISH_PORT=8080
export HTTPS_PUBLISH_PORT=443

# Then start services
docker compose -f compose.yaml -f overrides/compose.noproxy.yaml up -d
```

## Protocol-Specific Considerations

### Static Ports (Kept for Protocol Compliance)

Some services maintain static port mappings for protocol requirements:

- **MODBUS TCP (Port 502)**: Industry standard requires port 502
- **Database ports**: Internal communication doesn't need external exposure

### Dynamic Ports (Converted for Flexibility)

- **Web interfaces**: HTTP/HTTPS services that can work on any port
- **Development services**: Services primarily used during development

## Migration Guide

### For Existing Deployments

1. **Check current port usage:**
   ```bash
   docker compose ps
   ```

2. **Update any hardcoded references:**
   - Scripts that assume specific ports
   - Documentation with static port references
   - External service configurations

3. **Restart services to apply changes:**
   ```bash
   docker compose down
   docker compose up -d
   ```

4. **Update bookmarks/shortcuts:**
   - Use `docker compose ps` to find new ports
   - Update browser bookmarks
   - Update API endpoint configurations

### For New Deployments

No special action required - dynamic ports work out of the box.

## Troubleshooting

### Service Not Accessible

1. **Check if service is running:**
   ```bash
   docker compose ps <service-name>
   ```

2. **Find the assigned port:**
   ```bash
   docker compose ps
   # or
   docker port <container-name> <internal-port>
   ```

3. **Check service logs:**
   ```bash
   docker compose logs <service-name>
   ```

### Port Still Conflicts

If you're using environment variables to force specific ports and still getting conflicts:

1. **Check what's using the port:**
   ```bash
   # Linux/Mac
   lsof -i :<port-number>
   
   # Windows
   netstat -ano | findstr :<port-number>
   ```

2. **Use different port or let Docker auto-assign:**
   ```bash
   unset HTTP_PUBLISH_PORT  # Remove forced port
   docker compose up -d     # Let Docker auto-assign
   ```

## Best Practices

### 1. **Use Dynamic Ports for Development**
- Let Docker handle port assignment
- Use `docker compose ps` to find ports
- Update scripts to query ports dynamically

### 2. **Use Static Ports for Production (When Needed)**
- Set environment variables for predictable ports
- Use reverse proxy/load balancer for external access
- Document port assignments

### 3. **Script Port Discovery**
```bash
#!/bin/bash
# Example: Get frontend port dynamically
FRONTEND_PORT=$(docker compose port frontend 8080 | cut -d: -f2)
echo "Frontend available at: http://localhost:$FRONTEND_PORT"
```

### 4. **Health Checks and Service Discovery**
- Use container names for inter-service communication
- Implement health checks that work with dynamic ports
- Use service discovery tools for complex deployments

## Related Documentation

- [OpenPLC Integration](README-OpenPLC.md)
- [Setup for Linux/Mac](docs/setup_for_linux_mac.md)
- [Port-based Multi-tenancy](docs/port-based-multi-tenancy.md)
- [Environment Variables](docs/environment-variables.md)