# IntralogisticsAI

**Industrial Automation Platform for Modern Logistics**

IntralogisticsAI is a comprehensive industrial automation platform that combines enterprise resource planning (ERP) with real-time programmable logic controller (PLC) integration. Built on the proven Frappe/ERPNext foundation, it delivers seamless connectivity between business processes and industrial automation systems.

## 🚀 Features

- **Enterprise ERP**: Complete business management with Frappe/ERPNext
- **Industrial Integration**: Real-time PLC communication via MODBUS TCP
- **Real-time Monitoring**: Live dashboard for industrial signals and processes
- **Containerized Deployment**: Docker-based architecture for easy scaling
- **Educational Ready**: Perfect for logistics and automation education

## 🏗️ Architecture

IntralogisticsAI integrates multiple components:

- **EpiBus**: Custom Frappe app providing MODBUS/TCP communication
- **PLC Bridge**: Real-time communication service between ERP and PLCs
- **React Dashboard**: Modern frontend for monitoring industrial processes

## 🚦 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- [Git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git)
- 8GB+ RAM recommended

**Windows Users:**
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) with WSL2 backend
- [Windows Subsystem for Linux 2 (WSL2)](https://docs.microsoft.com/en-us/windows/wsl/install)
- [Git for Windows](https://gitforwindows.org/) or use Git within WSL2
- See [Windows Installation Guide](docs/deployment/windows-setup.md) for detailed setup instructions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/appliedrelevance/intralogisticsai
   cd intralogisticsai
   ```

2. **Configure environment**
   ```bash
   cp example.env .env
   # The .env file is pre-configured with optimal settings
   ```

3. **Deploy the complete stack**
   ```bash
   # Complete industrial automation platform
   ./deploy.sh with-plc
   
   # Training lab environment with custom domains
   ./deploy.sh lab
   
   # Web deployment with real domains
   ./deploy.sh web [yourdomain.com]
   ```

The deployment script will:
- ✅ Auto-detect your platform (macOS Intel/ARM, Linux) 
- ✅ Build custom Docker images with EpiBus integration (with smart caching)
- ✅ Deploy Frappe/ERPNext ERP system with network resilience
- ✅ Install and configure EpiBus automation app (with retry logic)
- ✅ Start CODESYS simulator with MODBUS TCP server
- ✅ Initialize PLC Bridge for real-time communication
- ✅ Create site (`intralogistics.localhost`) with admin user
- ✅ Configure all networking and dependencies

**First deployment**: ~5-10 minutes  
**Subsequent deployments**: ~1-2 minutes (using cached images)

## 🌐 Access Points

After deployment, access the platform:

- **IntralogisticsAI Web Interface**: `http://localhost:[port]` (shown in deployment output)
- **CODESYS Programming Environment**: `http://localhost:[port]` (shown in deployment output)
- **Login Credentials**: Username `Administrator`, Password `admin`
- **CODESYS Credentials**: Username `codesys`, Password `codesys`

## 📊 Using the Platform

### ERP Operations
1. Access the web interface and login
2. Navigate to standard ERPNext modules (Sales, Inventory, etc.)
3. Use the **EpiBus** module for industrial automation features

### PLC Programming
1. Access CODESYS web interface
2. Create ladder logic programs
3. Upload and start programs to activate MODBUS TCP server
4. Monitor real-time I/O through the web interface

### Industrial Integration
1. Configure MODBUS connections in EpiBus
2. Define signal mappings between ERP and PLC
3. Set up automated actions triggered by ERP events
4. Monitor real-time data flow in the dashboard

## 🔧 Deployment Options

The deployment script includes smart image caching and cross-platform support with automatic retry logic for network issues.

### Training Lab Environment (Recommended for Education)
```bash
# Quick deployment (uses cached images)
./deploy.sh lab

# Force rebuild (rebuilds all images)
./deploy.sh lab --rebuild
```
Complete training lab with custom domains and real PLC connectivity:
- **ERPNext Interface**: `http://intralogistics.lab`
- **CODESYS Simulator**: `http://codesys.intralogistics.lab`  
- **Traefik Dashboard**: `http://dashboard.intralogistics.lab`
- **MODBUS TCP**: `localhost:502` (for real PLC connections)
- **PLC Bridge**: `localhost:7654` (real-time events)

*Configure local domains in `/etc/hosts`:*
```
127.0.0.1 intralogistics.lab codesys.intralogistics.lab dashboard.intralogistics.lab
```

### Web Deployment (Production)
```bash
# Deploy with default domain (intralogisticsai.online)
./deploy.sh web

# Deploy with custom domain
./deploy.sh web yourdomain.com

# Force rebuild
./deploy.sh web yourdomain.com --rebuild
```
Production deployment with real domain and subdomains:
- **ERPNext Interface**: `http://yourdomain.com`
- **CODESYS Simulator**: `http://codesys.yourdomain.com`  
- **Traefik Dashboard**: `http://dashboard.yourdomain.com`
- **MODBUS TCP**: `yourdomain.com:502` (for real PLC connections)
- **PLC Bridge**: `yourdomain.com:7654` (real-time events)

### Complete Industrial Stack
```bash
# Smart deployment with caching
./deploy.sh with-plc

# Force fresh build
./deploy.sh with-plc --rebuild
```
Includes ERP, PLC simulator, and all automation features with platform-aware optimizations.

### EpiBus Only
```bash
./deploy.sh with-epibus
```
ERP with automation capabilities, no PLC simulator.

### Basic ERP
```bash
./deploy.sh
```
Standard Frappe/ERPNext without industrial features.

### Deployment Features

- ✅ **Smart Image Caching**: Skips rebuilds when images exist (5-10min → 1-2min)
- ✅ **Cross-Platform Support**: Auto-detects macOS (Intel/ARM) and Linux
- ✅ **Network Resilience**: 3-attempt retry logic for network timeouts
- ✅ **Docker Health Checks**: Automatic Docker restart if needed
- ✅ **Robust EpiBus Installation**: 60-attempt retry with intelligent backoff

### Deployment Flags

```bash
# View all options and examples
./deploy.sh --help

# Force rebuild of custom images
./deploy.sh lab --rebuild
./deploy.sh with-plc --force-rebuild
```

## 🛠️ Development

For development and customization:

```bash
# View service logs
docker compose logs -f backend
docker compose logs -f plc-bridge
docker compose logs -f codesys

# Access backend container
docker compose exec backend bash

# Reset and redeploy
docker compose down --volumes
./deploy.sh with-plc
```

## 📚 Documentation

- **[Complete Documentation](docs/README.md)** - Full documentation index
- **[Quick Start Guide](docs/deployment/quick-start.md)** - Get running in minutes
- **[Training Lab Setup](docs/deployment/lab-setup.md)** - Multi-workstation configuration
- **[EpiBus Integration](docs/epibus/README.md)** - Industrial automation guide
- **[CODESYS Programming](docs/codesys/README.md)** - PLC simulation and programming
- **[Troubleshooting](docs/troubleshooting/README.md)** - Common issues and solutions

## 🎓 Educational Use

IntralogisticsAI is designed for educational institutions teaching:
- Industrial automation and control systems
- Logistics and supply chain management
- Enterprise resource planning (ERP)
- MODBUS communication protocols
- Docker containerization and microservices


## 📄 License

This project builds upon several open-source components:
- [Frappe Framework](https://github.com/frappe/frappe) (MIT License)
- [ERPNext](https://github.com/frappe/erpnext) (GPL v3)
- [CODESYS](https://codesysproject.com/) (GPL v3)

See [LICENSE](LICENSE) for complete license information.

## 🏢 About

IntralogisticsAI is developed by [Applied Relevance](https://appliedrelevance.com) for educational and industrial applications. It bridges the gap between enterprise software and industrial automation, making advanced logistics concepts accessible for learning and implementation.

---

**Ready to revolutionize your industrial automation education?** 🚀

[Get started with IntralogisticsAI](https://github.com/appliedrelevance/intralogisticsai) today!