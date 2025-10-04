# On-Site Deployment Guide

## Network Configuration

### Server (Ubuntu)
- **Interface:** enp1s0 (ethernet)
- **Static IP:** 192.168.0.100
- **Gateway:** 192.168.0.1
- **Subnet:** 192.168.0.0/24
- **DNS:** 192.168.0.1 (local router)

### PLC
- **IP Address:** 192.168.0.11
- **Port:** 502
- **Protocol:** MODBUS TCP

## Pre-Deployment Steps

1. **Connect ethernet cable** to router
2. **Verify network connection:**
   ```bash
   ip addr show enp1s0
   # Should show: inet 192.168.0.100/24
   ```

3. **Test PLC connectivity:**
   ```bash
   nc -zv 192.168.0.11 502
   # Should show: Connection succeeded
   ```

## Frappe MODBUS Connection Configuration

In ERPNext, configure the MODBUS Connection with:
- **Host:** `192.168.0.11` (for direct connection to PLC)
- **Port:** `502`
- **Device Type:** PLC

**Note:** Use the actual PLC IP, not `host.docker.internal`, since the PLC is on the same network.

## Client Workstation Setup

### Windows Clients
1. Edit `C:\Windows\System32\drivers\etc\hosts` (as Administrator)
2. Add line:
   ```
   192.168.0.100 intralogistics.lab dashboard.intralogistics.lab
   ```
3. Access: http://intralogistics.lab

### Mac/Linux Clients
1. Edit `/etc/hosts`:
   ```bash
   sudo nano /etc/hosts
   ```
2. Add line:
   ```
   192.168.0.100 intralogistics.lab dashboard.intralogistics.lab
   ```
3. Access: http://intralogistics.lab

## Starting the System

```bash
cd /home/intralogisticsuser/intralogisticsai
sg docker -c "./deploy.sh"
```

## Verifying Services

```bash
# Check all containers are running
sg docker -c "docker compose ps"

# Test web interface
curl http://intralogistics.lab

# Test PLC connection from PLC Bridge
sg docker -c "docker exec intralogisticsai-plc-bridge-1 python -c \"from pymodbus.client import ModbusTcpClient; client = ModbusTcpClient(host='192.168.0.11', port=502); print(f'PLC Connected: {client.connect()}'); client.close()\""
```

## Access Points

- **ERPNext:** http://intralogistics.lab
- **Traefik Dashboard:** http://dashboard.intralogistics.lab:8080
- **Login:** Administrator / admin
- **PLC Bridge API:** http://192.168.0.100:7654

## Important Notes

- System is configured for **isolated LAN** (no internet required)
- All Docker images are pre-built and cached
- All apps (frappe, erpnext, epibus, epitag) are built from local sources
- **See OFFLINE_BUILD.md** for complete offline deployment instructions
- PLC must be accessible at 192.168.0.11:502
- Router/switch at 192.168.0.1 should provide DHCP for client workstations

## Apps Included

The custom `frappe-epibus:latest` image includes:
- **frappe**: Framework (v15)
- **erpnext**: ERP system (v15)
- **epibus**: Industrial automation and MODBUS integration
- **epitag**: Tag management system

## Troubleshooting

### Network not accessible
```bash
# Check ethernet connection
ip addr show enp1s0

# Ping gateway
ping 192.168.0.1

# Restart network
echo "intralogistics" | sudo -S nmcli connection down "netplan-enp1s0"
echo "intralogistics" | sudo -S nmcli connection up "netplan-enp1s0"
```

### Cannot connect to PLC
```bash
# Test from host
nc -zv 192.168.0.11 502

# Test from container
sg docker -c "docker exec intralogisticsai-plc-bridge-1 ping 192.168.0.11"
```

### Services not starting
```bash
# Check logs
sg docker -c "docker compose logs"

# Restart services
sg docker -c "./deploy.sh stop"
sg docker -c "./deploy.sh"
```
