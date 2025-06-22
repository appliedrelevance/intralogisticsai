# SSL Certificate Issues - Troubleshooting Guide

## Problem: "Your connection is not private" / ERR_CERT_AUTHORITY_INVALID

This error occurs when the SSL certificate is invalid, self-signed, or doesn't match the domain being accessed.

## Quick Fix - Use the Built-in Web Deployment

The easiest way to deploy with proper HTTPS is to use the built-in `web` deployment mode:

```bash
# Stop any existing deployment
./deploy.sh stop

# Deploy with HTTPS for your domain
./deploy.sh web intralogisticsai.online
```

This automatically configures:
- ✅ Let's Encrypt SSL certificates
- ✅ Multiple subdomains (root, dashboard, openplc)
- ✅ HTTP to HTTPS redirects
- ✅ Proper Traefik configuration

## Manual Configuration

If you need to manually configure HTTPS, follow these steps:

### 1. Configure Environment Variables

Update your `.env` file:

```bash
# Set your domain
WEB_DOMAIN=intralogisticsai.online

# Set valid Let's Encrypt email
LETSENCRYPT_EMAIL=admin@intralogisticsai.online
ACME_EMAIL=admin@intralogisticsai.online

# Configure sites (for multi-domain certificates)
SITES="`intralogisticsai.online`,`dashboard.intralogisticsai.online`,`openplc.intralogisticsai.online`"
```

### 2. Deploy with HTTPS Override

```bash
# Stop existing services
./deploy.sh stop

# Deploy with web configuration (includes HTTPS)
./deploy.sh web
```

Or manually with compose:

```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.openplc.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.web.yaml \
  -f overrides/compose.create-site-web.yaml \
  up -d
```

## Common Issues and Solutions

### 1. Domain Not Resolving

**Problem**: Domain doesn't point to your server.

**Check DNS**:
```bash
nslookup intralogisticsai.online
nslookup dashboard.intralogisticsai.online
nslookup openplc.intralogisticsai.online
```

**Solution**: Update your DNS records to point all subdomains to your server's public IP.

### 2. Invalid Let's Encrypt Email

**Problem**: Let's Encrypt requires a valid email address.

**Solution**: Update `.env` with a real email address:
```bash
LETSENCRYPT_EMAIL=your-real-email@domain.com
ACME_EMAIL=your-real-email@domain.com
```

### 3. Certificate Generation Failed

**Check certificate status**:
```bash
# View Traefik logs
docker compose logs proxy

# Check certificate storage
docker compose exec proxy ls -la /letsencrypt/
```

**Solution**: Force certificate regeneration:
```bash
# Stop services
./deploy.sh stop

# Remove old certificates
docker volume rm intralogisticsai_letsencrypt

# Redeploy
./deploy.sh web intralogisticsai.online
```

### 4. Firewall Blocking HTTPS

**Problem**: Ports 80 and 443 are blocked.

**Check ports**:
```bash
# Check if ports are open
sudo ufw status
telnet intralogisticsai.online 443

# Test locally
curl -I https://intralogisticsai.online
```

**Solution**: Open required ports:
```bash
sudo ufw allow 80/tcp   # HTTP (needed for Let's Encrypt)
sudo ufw allow 443/tcp  # HTTPS
```

## Development/Testing Solutions

### Option 1: Use HTTP for Local Development

```bash
# Deploy without HTTPS for local testing
./deploy.sh with-plc

# Access via HTTP
http://localhost:8080
```

### Option 2: Accept Self-Signed Certificate

For testing purposes only:

1. **In Chrome/Brave**: Click "Advanced" → "Proceed to site (unsafe)"
2. **Add exception**: Go to `chrome://flags/#allow-insecure-localhost`
3. **Use incognito mode**: Sometimes bypasses certificate caching

### Option 3: Local Domain Setup

```bash
# Add to /etc/hosts for local testing
echo "127.0.0.1 intralogistics.localhost" | sudo tee -a /etc/hosts

# Update .env for local development
WEB_DOMAIN=intralogistics.localhost

# Deploy locally
./deploy.sh web intralogistics.localhost
```

## Accessing Your Application

After successful HTTPS deployment, your application will be available at:

- **Main Dashboard**: https://dashboard.intralogisticsai.online
- **Root Domain**: https://intralogisticsai.online
- **OpenPLC Interface**: https://openplc.intralogisticsai.online

## Troubleshooting Commands

### Check Current Configuration
```bash
# View current environment
grep -E "(WEB_DOMAIN|LETSENCRYPT|ACME)" .env

# Check running services
docker compose ps

# View Traefik configuration
docker compose logs proxy | grep -i certificate
```

### Test SSL Certificate
```bash
# Test SSL certificate
openssl s_client -connect intralogisticsai.online:443 -servername intralogisticsai.online

# Check certificate expiry
echo | openssl s_client -connect intralogisticsai.online:443 2>/dev/null | openssl x509 -noout -dates
```

### Monitor Certificate Generation
```bash
# Watch certificate generation in real-time
docker compose logs -f proxy

# Check certificate files
docker compose exec proxy ls -la /letsencrypt/
```

## Production Deployment Checklist

Before deploying to production:

- [ ] DNS records point to your server's public IP
- [ ] Firewall allows ports 80 and 443
- [ ] Valid email address set in LETSENCRYPT_EMAIL
- [ ] WEB_DOMAIN configured correctly
- [ ] Server has sufficient resources (8GB+ RAM)

## Security Best Practices

- **Never use self-signed certificates in production**
- **Keep certificates updated** (Let's Encrypt auto-renews)
- **Monitor certificate expiry dates**
- **Use strong passwords** for all accounts
- **Keep your server updated** with security patches

## Getting Help

If SSL issues persist:

1. **Check logs**: `docker compose logs proxy > ssl-debug.log`
2. **Verify DNS**: Use online DNS checkers
3. **Test connectivity**: `curl -v https://your-domain.com`
4. **Review configuration**: Compare with working examples
5. **Create GitHub issue**: Include logs and configuration details

## Related Documentation

- [Main Troubleshooting Guide](README.md)
- [Deployment Quick Start](../deployment/quick-start.md)
- [Environment Variables](../archive-frappe-docker/environment-variables.md)

### 4. DNS Not Pointing to Server

**Problem**: Domain doesn't resolve to your server's IP address.

**Check DNS resolution**:
```bash
# Check if domain resolves to your server
nslookup dashboard.intralogisticsai.online

# Check from external source
dig dashboard.intralogisticsai.online
```

**Solution**: Update DNS records to point to your server's public IP address.

### 5. Firewall Blocking HTTPS

**Problem**: Port 443 (HTTPS) is blocked by firewall.

**Check and fix firewall**:
```bash
# Check if port 443 is open
sudo ufw status
telnet dashboard.intralogisticsai.online 443

# Open HTTPS port
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp  # Needed for Let's Encrypt challenge
```

## Development/Testing Solutions

### Option 1: Use HTTP Instead of HTTPS

For local development, you can bypass SSL entirely:

```bash
# Use HTTP deployment
docker compose -f compose.yaml -f overrides/compose.web.yaml up -d

# Access via HTTP
http://localhost:8080
```

### Option 2: Accept Self-Signed Certificate

For testing with self-signed certificates:

1. **In Chrome/Brave**: Click "Advanced" → "Proceed to dashboard.intralogisticsai.online (unsafe)"
2. **Add permanent exception**: Go to `chrome://flags/#allow-insecure-localhost` and enable it
3. **Use incognito mode**: Sometimes helps bypass certificate caching

### Option 3: Use Local Domain

Configure for local development:

```bash
# Update .env for local development
WEB_DOMAIN=intralogistics.localhost
SITES="intralogistics.localhost"
FRAPPE_SITE_NAME_HEADER=intralogistics.localhost

# Add to hosts file
echo "127.0.0.1 intralogistics.localhost" | sudo tee -a /etc/hosts

# Deploy without HTTPS
docker compose -f compose.yaml -f overrides/compose.web.yaml up -d

# Access via
http://intralogistics.localhost:8080
```

## Production Deployment Steps

For a proper production deployment with valid SSL:

### Step 1: Configure Domain and Email
```bash
# Update .env file
WEB_DOMAIN=dashboard.intralogisticsai.online
SITES="dashboard.intralogisticsai.online"
LETSENCRYPT_EMAIL=admin@yourdomain.com
ACME_EMAIL=admin@yourdomain.com
```

### Step 2: Ensure DNS is Configured
```bash
# Verify DNS points to your server
nslookup dashboard.intralogisticsai.online
# Should return your server's public IP
```

### Step 3: Deploy with HTTPS
```bash
# Clean deployment
docker compose down --volumes
docker volume prune

# Deploy with HTTPS
docker compose -f compose.yaml -f overrides/compose.https.yaml up -d
```

### Step 4: Monitor Certificate Generation
```bash
# Watch logs for certificate generation
docker compose logs -f proxy

# Check certificate status
docker compose exec proxy ls -la /letsencrypt/
```

## Troubleshooting Commands

### Check Current Configuration
```bash
# View current compose configuration
docker compose -f compose.yaml -f overrides/compose.https.yaml config

# Check Traefik configuration
docker compose exec proxy traefik version
```

### Test SSL Certificate
```bash
# Test SSL certificate
openssl s_client -connect dashboard.intralogisticsai.online:443 -servername dashboard.intralogisticsai.online

# Check certificate expiry
echo | openssl s_client -connect dashboard.intralogisticsai.online:443 2>/dev/null | openssl x509 -noout -dates
```

### Debug Let's Encrypt Issues
```bash
# Check Let's Encrypt logs
docker compose logs proxy | grep -i acme

# Test Let's Encrypt connectivity
curl -I https://acme-v02.api.letsencrypt.org/directory
```

## Quick Fix for Immediate Access

If you need immediate access and can't wait for proper SSL setup:

```bash
# 1. Stop current deployment
docker compose down

# 2. Deploy without HTTPS
docker compose -f compose.yaml -f overrides/compose.web.yaml up -d

# 3. Access via HTTP
# http://localhost:8080 (if running locally)
# http://your-server-ip:8080 (if running on server)
```

## Security Considerations

- **Never use self-signed certificates in production**
- **Always use valid SSL certificates for public-facing applications**
- **Keep certificates updated and monitor expiry dates**
- **Use strong passwords and secure your server**

## Getting Help

If you continue to have SSL issues:

1. Check the main troubleshooting guide: `docs/troubleshooting/README.md`
2. Collect logs: `docker compose logs > ssl-debug.log`
3. Create a GitHub issue with your configuration and logs
4. Include your domain, deployment method, and error messages