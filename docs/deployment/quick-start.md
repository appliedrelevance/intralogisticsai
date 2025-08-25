# Quick Start Guide

Get IntralogisticsAI running in minutes with automated deployment.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- [Git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git)
- 8GB+ RAM recommended

## Installation

### 1. Clone Repository
```bash
git clone https://github.com/appliedrelevance/intralogisticsai
cd intralogisticsai
```

### 2. Configure Environment
```bash
cp example.env .env
# The .env file is pre-configured with optimal settings
```

### 3. Deploy

Choose your deployment type:

#### Complete Training Lab (Recommended)
```bash
./deploy.sh lab
```
**Access:** 
- Main ERP: http://intralogistics.lab
- CODESYS: http://codesys.lab  
- Network Dashboard: http://traefik.lab

#### Complete Industrial Stack
```bash
./deploy.sh with-plc
```
**Access:** http://localhost:[port] (shown in output)

#### Basic ERP Only
```bash
./deploy.sh
```

## First Login

**Credentials:**
- **Username:** `Administrator`  
- **Password:** `admin`
- **CODESYS:** `codesys` / `codesys`

## Getting Started

1. **Login** to the web interface
2. **Explore ERPNext** - Create items, customers, sales orders
3. **Access EpiBus** - Navigate to EpiBus workspace in sidebar
4. **Configure PLCs** - Set up MODBUS connections to your devices
5. **Create Automation** - Link ERP events to PLC actions

## Service Verification

```bash
# Check all services
docker compose ps

# View logs
docker compose logs backend
docker compose logs codesys

# Test PLC connectivity
curl http://localhost:7654/signals  # PLC Bridge API
```

## Troubleshooting

### Reset Everything
```bash
docker compose down --volumes
./deploy.sh [your-option]
```

### Check Ports
```bash
docker compose ps
# Look for port mappings like 0.0.0.0:32768->8080/tcp
```

### Common Issues
- **Site creation fails:** Check DB_PASSWORD in .env file
- **Can't access web:** Wait 2-3 minutes for full startup
- **PLC connection errors:** Verify MODBUS TCP settings in EpiBus

## Next Steps

- **Training Lab:** See [Lab Setup Guide](lab-setup.md) for multi-workstation configuration
- **Real PLCs:** Configure IP addresses in EpiBus MODBUS settings
- **Development:** See [Development Guide](../development/README.md)

---

**Need Help?** Check the [Troubleshooting Guide](../troubleshooting/README.md) or view logs with `docker compose logs [service-name]`.