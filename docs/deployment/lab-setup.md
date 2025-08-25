# Training Lab Setup Guide

## Network Architecture

### Physical Setup
- **Ubuntu Server**: Docker host running IntralogisticsAI
- **4 Windows NUCs**: Student workstations
- **Wi-Fi Router**: Airgapped network with occasional internet access
- **MODBUS Devices**: Real PLCs connected via Ethernet

### Network Configuration

#### Router DNS Setup
Configure your router to resolve lab domains to the Ubuntu server:

```
intralogistics.lab  -> 192.168.1.100  (Ubuntu server IP)
codesys.lab         -> 192.168.1.100  (Same server)
traefik.lab         -> 192.168.1.100  (Same server)
```

#### IP Address Scheme (Example)
```
Ubuntu Server:    192.168.1.100
Windows NUC 1:    192.168.1.101
Windows NUC 2:    192.168.1.102
Windows NUC 3:    192.168.1.103
Windows NUC 4:    192.168.1.104
Real PLC 1:       192.168.1.200
Real PLC 2:       192.168.1.201
```

## Deployment

### On Ubuntu Server

1. **Deploy the lab environment:**
   ```bash
   cd intralogisticsai
   ./deploy.sh lab
   ```

2. **Verify services:**
   ```bash
   docker compose ps
   curl -I http://intralogistics.lab
   ```

### Router Configuration

1. **DNS Settings** (varies by router):
   - Add A records for `*.lab` domains pointing to Ubuntu server
   - Or configure DNS override/local DNS

2. **DHCP Reservations** (recommended):
   - Reserve IP addresses for all devices
   - Ensures consistent networking

## Student Access

### Web Interfaces
- **Main ERP**: http://intralogistics.lab
- **PLC Simulator**: http://codesys.lab  
- **Network Status**: http://traefik.lab

### Login Credentials
- **IntralogisticsAI**: Username `Administrator`, Password `admin`
- **CODESYS**: Username `codesys`, Password `codesys`

## MODBUS Configuration

### Simulator Mode (Default)
- **Host**: `codesys` (internal Docker network)
- **Port**: `502`
- **Access**: http://codesys.lab

### Real PLC Mode
Configure EpiBus to connect to real devices:

1. **Access EpiBus settings** in IntralogisticsAI
2. **Add PLC connections**:
   - **PLC 1**: `192.168.1.200:502`
   - **PLC 2**: `192.168.1.201:502`

## Troubleshooting

### DNS Issues
```bash
# Test from Windows NUC
nslookup intralogistics.lab

# Should return: 192.168.1.100
```

### Network Connectivity
```bash
# Test from Ubuntu server
ping 192.168.1.101  # NUC 1
ping 192.168.1.200  # PLC 1

# Test MODBUS connectivity
telnet 192.168.1.200 502
```

### Service Issues
```bash
# Check all services
docker compose ps

# View logs
docker compose logs frontend
docker compose logs plc-bridge
```

## Updates (Airgapped Environment)

### Preparation (With Internet)
```bash
# Pull latest images
docker compose pull

# Save images for offline transfer
docker save frappe/erpnext > erpnext.tar
docker save traefik:v2.11 > traefik.tar
```

### Deployment (Airgapped)
```bash
# Load images
docker load < erpnext.tar
docker load < traefik.tar

# Redeploy
./deploy.sh lab
```

## Lab Exercise Ideas

1. **ERP Basics**: Create items, customers, sales orders
2. **PLC Programming**: Ladder logic in CODESYS
3. **MODBUS Communication**: Connect ERP to PLC signals
4. **Automation**: Trigger PLC actions from ERP events
5. **Real Hardware**: Connect to actual conveyor/robot systems