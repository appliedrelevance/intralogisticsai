# Troubleshooting Guide

Solutions for common issues when deploying and using IntralogisticsAI.

## Quick Diagnostics

### Check System Status
```bash
# Verify all services are running
docker compose ps

# Check service health
docker compose ps --filter "status=running"

# View recent logs
docker compose logs --tail=50
```

### Test Core Services
```bash
# Test web interface
curl -I http://localhost:$(docker compose port frontend 8080 | cut -d: -f2)

# Test MODBUS TCP
telnet localhost 502

# Test EpiBus API
curl http://localhost:8000/api/method/epibus.api.plc.get_signals
```

## Deployment Issues

### Permission Denied Errors
```bash
# Issue: Cannot execute deploy.sh
chmod +x deploy.sh

# Issue: Docker permission denied (Linux)
sudo usermod -aG docker $USER
# Then logout and login again
```

### Port Conflicts
```bash
# Find what's using a port
sudo lsof -i :80
sudo lsof -i :502

# Kill conflicting process
sudo kill -9 [PID]

# Or use different ports in .env
HTTP_PUBLISH_PORT=8080
OPENPLC_MODBUS_PORT=5020
```

### Docker Issues
```bash
# Docker daemon not running
sudo systemctl start docker  # Linux
open -a Docker               # Mac

# Insufficient resources
# Increase Docker Desktop memory to 8GB+
# Docker Desktop → Preferences → Resources

# Clear Docker cache
docker system prune -a
docker volume prune
```

## Database Problems

### Connection Failures
```bash
# Check database container
docker compose logs db

# Verify environment variables
grep DB_ .env

# Common fix: Reset database
docker compose down --volumes
docker volume rm intralogisticsai_db-data
./deploy.sh [your-option]
```

### Site Creation Errors
```bash
# Check site creation logs
docker compose logs create-site

# Manual site creation
docker compose exec backend bench new-site intralogistics.localhost \
  --admin-password admin \
  --db-root-password 123 \
  --install-app erpnext

# Install EpiBus manually
docker compose exec backend bench --site intralogistics.localhost install-app epibus
```

### Database Corruption
```bash
# Complete database reset
docker compose down --volumes
docker volume rm intralogisticsai_db-data intralogisticsai_sites
./deploy.sh [your-option]

# Restore from backup (if available)
docker compose exec backend bench --site intralogistics.localhost restore [backup-file]
```

## Network and Connectivity

### Can't Access Web Interface
```bash
# Check frontend port mapping
docker compose ps frontend

# Test internal connectivity
docker compose exec backend curl http://frontend:8080

# Verify firewall (Linux)
sudo ufw status
sudo ufw allow 80/tcp

# Check hosts file (for lab deployment)
cat /etc/hosts | grep intralogistics.lab
```

### MODBUS Connection Issues
```bash
# Test CODESYS container
docker compose exec codesys netstat -tlnp | grep 502

# Test from backend
docker compose exec backend python3 -c "
from pymodbus.client import ModbusTcpClient
client = ModbusTcpClient('codesys', 502)
print('Connected:', client.connect())
"

# Check MODBUS logs
docker compose logs codesys | grep -i modbus
```

### Lab Domain Resolution
```bash
# Test DNS resolution
nslookup intralogistics.lab

# Manual hosts file entry (temporary fix)
sudo echo "192.168.1.100 intralogistics.lab" >> /etc/hosts
sudo echo "192.168.1.100 codesys.lab" >> /etc/hosts

# Router DNS configuration needed for permanent fix
```

## Service-Specific Issues

### Frontend (Nginx) Problems
```bash
# Check nginx configuration
docker compose exec frontend nginx -t

# View nginx logs
docker compose logs frontend

# Restart frontend
docker compose restart frontend

# Check upstream connections
docker compose exec frontend ping backend
```

### Backend (Frappe) Issues
```bash
# Check Python errors
docker compose logs backend | grep -i error

# Access backend console
docker compose exec backend bench --site intralogistics.localhost console

# Restart workers
docker compose restart queue-long queue-short scheduler

# Check bench status
docker compose exec backend bench --site intralogistics.localhost doctor
```

### CODESYS Problems
```bash
# Check CODESYS web interface
curl -I http://localhost:$(docker compose port codesys 8080 | cut -d: -f2)

# View CODESYS logs
docker compose logs codesys

# Restart CODESYS
docker compose restart codesys

# Rebuild CODESYS image
docker compose build codesys
```

### PLC Bridge Issues
```bash
# Check PLC Bridge connectivity
curl http://localhost:7654/signals

# View bridge logs
docker compose logs plc-bridge

# Test bridge to CODESYS connection
docker compose exec plc-bridge telnet codesys 502

# Restart bridge
docker compose restart plc-bridge
```

## Mac-Specific Issues

### ARM64 Compatibility
```bash
# Verify platform settings
docker compose config | grep platform

# Should show: platform: linux/arm64
# If not, ensure you're using compose.mac-m4.yaml override
```

### Performance Issues
```bash
# Increase Docker Desktop resources
# Docker Desktop → Preferences → Resources
# RAM: 8GB minimum
# CPU: 4 cores minimum

# Check Activity Monitor for resource usage
# Close unnecessary applications
```

### File Sharing Problems
```bash
# Enable VirtioFS in Docker Desktop
# Docker Desktop → Preferences → Experimental Features

# Check file sharing permissions
# Docker Desktop → Preferences → Resources → File Sharing
```

## EpiBus Configuration Issues

### MODBUS Connection Errors
```bash
# Test connection in EpiBus
# Go to MODBUS Connection → Test Connection

# Check connection parameters
# Verify host, port, unit ID

# Debug connection
docker compose exec backend python3 -c "
import frappe
frappe.init(site='intralogistics.localhost')
conn = frappe.get_doc('Modbus Connection', 'Your Connection Name')
print(conn.test_connection())
"
```

### Signal Reading Problems
```bash
# Verify signal configuration
# Check MODBUS address and function code

# Test signal manually
docker compose exec backend python3 -c "
import frappe
from pymodbus.client import ModbusTcpClient
frappe.init(site='intralogistics.localhost')
client = ModbusTcpClient('codesys', 502)
client.connect()
result = client.read_discrete_inputs(0, 1)  # Address 0, count 1
print('Result:', result.bits if not result.isError() else 'Error')
"
```

### Action Not Triggering
```bash
# Check document hooks
docker compose logs backend | grep -i "modbus action"

# Verify warehouse configuration
# Ensure MODBUS Action warehouse matches Stock Entry

# Test action manually
docker compose exec backend bench --site intralogistics.localhost console
# In console:
# action = frappe.get_doc("Modbus Action", "Your Action Name")
# action.execute_script()
```

## Performance Issues

### Slow Response Times
```bash
# Check resource usage
docker stats

# Optimize database
docker compose exec backend bench --site intralogistics.localhost optimize-database

# Clear cache
docker compose exec backend bench --site intralogistics.localhost clear-cache

# Restart services
docker compose restart
```

### High Memory Usage
```bash
# Check memory per service
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Reduce worker processes (if needed)
# Edit .env: WORKER_COUNT=2

# Increase swap space (Linux)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Database Performance
```bash
# Check slow queries
docker compose exec db mysqldumpslow /var/log/mysql/mysql-slow.log

# Optimize tables
docker compose exec backend bench --site intralogistics.localhost mariadb
# In MariaDB: OPTIMIZE TABLE tab[TableName];

# Update table statistics
docker compose exec db mysqlcheck -u root -p123 --auto-repair --optimize --all-databases
```

## Data and Configuration Issues

### Lost Configuration
```bash
# Backup current configuration
docker compose exec backend bench --site intralogistics.localhost backup

# Export specific doctypes
docker compose exec backend bench --site intralogistics.localhost export-doc \
  "Modbus Connection" --name "Your Connection"

# Import configuration
docker compose exec backend bench --site intralogistics.localhost import-doc [file.json]
```

### Permission Errors
```bash
# Reset user permissions
docker compose exec backend bench --site intralogistics.localhost console
# In console:
# user = frappe.get_doc("User", "your.email@domain.com")
# user.add_roles("System Manager")
# user.save()

# Reset to Administrator
docker compose exec backend bench --site intralogistics.localhost set-admin-password admin
```

### Corrupted Data
```bash
# Validate data integrity
docker compose exec backend bench --site intralogistics.localhost doctor

# Rebuild search index
docker compose exec backend bench --site intralogistics.localhost rebuild-global-search

# Clear cache and restart
docker compose exec backend bench --site intralogistics.localhost clear-cache
docker compose restart backend
```

## Emergency Procedures

### Complete System Reset
```bash
# WARNING: This will delete all data
docker compose down --volumes
docker system prune -a
docker volume prune

# Remove all volumes
docker volume rm $(docker volume ls -q | grep intralogisticsai)

# Fresh deployment
./deploy.sh [your-option]
```

### Service Recovery
```bash
# Restart specific service
docker compose restart [service-name]

# Recreate service
docker compose up -d --force-recreate [service-name]

# Rebuild and restart
docker compose build [service-name]
docker compose up -d [service-name]
```

### Network Reset
```bash
# Recreate networks
docker compose down
docker network prune
docker compose up -d
```

## Getting Additional Help

### Log Collection
```bash
# Collect all logs
docker compose logs > intralogistics-logs.txt

# Collect system information
docker version > system-info.txt
docker compose version >> system-info.txt
uname -a >> system-info.txt
```

### Debug Information
```bash
# Service status
docker compose ps > service-status.txt

# Configuration dump
docker compose config > compose-config.yaml

# Environment variables
env | grep -E "(DOCKER|COMPOSE)" > environment.txt
```

### Support Channels
1. **GitHub Issues**: [Create detailed bug report](https://github.com/appliedrelevance/intralogisticsai/issues)
2. **Documentation**: Review relevant guide in docs/ folder
3. **Community Forums**: ERPNext and Docker communities
4. **Educational Support**: Contact your instructor or system administrator

### Creating Effective Bug Reports
Include the following information:
- Operating system and version
- Docker and Docker Compose versions
- Deployment command used (`./deploy.sh [option]`)
- Error messages from logs
- Steps to reproduce the issue
- Expected vs actual behavior

---

**Still having issues?** Create a GitHub issue with the log collection and debug information above.