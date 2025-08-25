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

## EpiBus Installation Issue

After fixing the Gateway Timeout and CSS issues, you may find that the EpiBus application is not installed on the site.

### Symptoms
- EpiBus application missing from installed apps list
- EpiBus functionality not available in the system

### Root Cause
The site creation process was only installing ERPNext but not EpiBus.

### Solution
Updated both `overrides/compose.create-site-web.yaml` and `overrides/compose.create-site.yaml` to include EpiBus installation:

```yaml
# Before
bench new-site --install-app erpnext --set-default ${WEB_DOMAIN} --force;

# After
bench new-site --install-app erpnext --install-app epibus --set-default ${WEB_DOMAIN} --force;
```

## SSL/HTTPS Configuration

For production deployments, SSL/HTTPS should be enabled for security.

### Features Added
- Let's Encrypt automatic SSL certificate generation
- HTTP to HTTPS redirects for all services
- SSL support for main domain and CODESYS subdomain
- Proper certificate resolver configuration

### Configuration
Updated `overrides/compose.web.yaml` with:

```yaml
services:
  proxy:
    command:
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
      - --certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
    ports:
      - "443:443"    # HTTPS
    volumes:
      - letsencrypt:/letsencrypt

  frontend:
    labels:
      # HTTPS router
      - traefik.http.routers.frontend-https.entrypoints=websecure
      - traefik.http.routers.frontend-https.tls=true
      - traefik.http.routers.frontend-https.tls.certresolver=letsencrypt
      # HTTP to HTTPS redirect
      - traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https
      - traefik.http.routers.frontend-http.middlewares=redirect-to-https
```

### Environment Variables
Add to your `.env` file:
```bash
ACME_EMAIL=your-email@domain.com
WEB_DOMAIN=your-domain.com
```

## CODESYS Subdomain Resolution

Fixed CODESYS subdomain routing by ensuring the service is on the correct network.

### Solution
Added network configuration to CODESYS service:

```yaml
services:
  codesys:
    networks:
      - frappe_network
    labels:
      # Both HTTP and HTTPS routers configured
      - traefik.http.routers.codesys-https.rule=Host(`codesys.${WEB_DOMAIN}`)
```

## Related Files

- `overrides/compose.web.yaml` - Contains proxy, SSL, and network fixes
- `overrides/compose.create-site-web.yaml` - Contains EpiBus installation for web deployment
- `overrides/compose.create-site.yaml` - Contains EpiBus installation for local deployment
- `example.env` - Contains required environment variables
- `deploy.sh` - Uses the correct override files for web deployments

## Complete Fix Summary

The complete solution addresses:
1. ✅ Gateway Timeout (Traefik middleware + network configuration)
2. ✅ CSS/Asset loading (automatic asset building during site creation)
3. ✅ EpiBus installation (added to site creation process)
4. ✅ SSL/HTTPS support (Let's Encrypt integration)
5. ✅ CODESYS subdomain resolution (network configuration)

All fixes are now permanent and committed to the repository for repeatable deployments.