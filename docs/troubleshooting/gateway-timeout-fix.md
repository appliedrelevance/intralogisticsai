# Gateway Timeout Fix

## Problem Description

When deploying the application using `./deploy.sh web`, users may encounter a "504 Gateway Timeout" error when accessing the website. This issue is caused by two main problems:

1. **Missing Traefik middleware**: Frappe requires the correct `Host` header to serve the appropriate site
2. **Network isolation**: Traefik proxy and frontend containers were on different Docker networks

## Root Cause

The original `overrides/compose.web.yaml` configuration was missing:
- Traefik middleware to forward the correct `Host` header
- Network configuration to ensure all containers use the same network

## Solution

The fix involves updating `overrides/compose.web.yaml` with:

### 1. Traefik Middleware Configuration

```yaml
services:
  frontend:
    labels:
      # ... existing labels ...
      - traefik.http.middlewares.frontend-headers.headers.customrequestheaders.Host=${WEB_DOMAIN:-intralogisticsai.online}
      - traefik.http.routers.frontend-http.middlewares=frontend-headers
```

### 2. Network Configuration

```yaml
services:
  proxy:
    # ... existing config ...
    networks:
      - frappe_network

networks:
  frappe_network:
    external: true
    name: frappe_network
```

## Verification

After applying the fix, verify the deployment works:

```bash
# Test the website
curl -I http://your-domain.com/

# Should return HTTP/1.1 200 OK instead of 504 Gateway Timeout
```

## Prevention

This fix is now included in the repository's `overrides/compose.web.yaml` file, so future deployments using `./deploy.sh web` will automatically include these fixes.

## Technical Details

- **Middleware**: Ensures Frappe receives the correct hostname to serve the right site
- **Network**: Ensures Traefik can communicate with the frontend container
- **Service Discovery**: Traefik automatically discovers the correct IP address when containers are on the same network

## Asset Synchronization Issue

After fixing the Gateway Timeout, you may encounter missing CSS/JS files (unstyled pages). This happens when assets aren't properly synchronized between backend and frontend containers.

### Symptoms
- Website loads but appears unstyled
- CSS/JS files return 404 errors
- Different asset hashes between containers

### Solution
1. Rebuild assets in backend container:
   ```bash
   docker exec backend-container bench --site your-site.com build
   ```

2. Synchronize assets to frontend container:
   ```bash
   # Copy CSS files
   docker cp backend-container:/path/to/assets/css/. /tmp/css_files/
   docker cp /tmp/css_files/. frontend-container:/path/to/assets/css/
   
   # Copy JS files
   docker cp backend-container:/path/to/assets/js/. /tmp/js_files/
   docker cp /tmp/js_files/. frontend-container:/path/to/assets/js/
   ```

3. Verify assets are accessible:
   ```bash
   curl -I http://your-domain.com/assets/frappe/dist/css/website.bundle.HASH.css
   ```

## Related Files

- `overrides/compose.web.yaml` - Contains the fix
- `deploy.sh` - Uses the correct override files for web deployments