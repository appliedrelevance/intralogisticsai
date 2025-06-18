# IntralogisticsAI

**Industrial Automation Platform for Modern Logistics**

IntralogisticsAI is a comprehensive industrial automation platform that combines enterprise resource planning (ERP) with real-time programmable logic controller (PLC) integration. Built on the proven Frappe/ERPNext foundation, it delivers seamless connectivity between business processes and industrial automation systems.

## 🚀 Features

- **Enterprise ERP**: Complete business management with Frappe/ERPNext
- **Industrial Integration**: Real-time PLC communication via MODBUS TCP
- **Visual Programming**: OpenPLC environment for ladder logic development
- **Real-time Monitoring**: Live dashboard for industrial signals and processes
- **Containerized Deployment**: Docker-based architecture for easy scaling
- **Educational Ready**: Perfect for logistics and automation education

## 🏗️ Architecture

IntralogisticsAI integrates multiple components:

- **EpiBus**: Custom Frappe app providing MODBUS/TCP communication
- **OpenPLC**: Industrial programming environment with MODBUS TCP server
- **PLC Bridge**: Real-time communication service between ERP and PLCs
- **React Dashboard**: Modern frontend for monitoring industrial processes

## 🚦 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- [Git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git)
- 8GB+ RAM recommended

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
   ./deploy.sh with-plc
   ```

The deployment script will:
- ✅ Build custom Docker images with EpiBus integration
- ✅ Deploy Frappe/ERPNext ERP system
- ✅ Install and configure EpiBus automation app
- ✅ Start OpenPLC simulator with MODBUS TCP server
- ✅ Initialize PLC Bridge for real-time communication
- ✅ Create site (`intralogistics.localhost`) with admin user
- ✅ Configure all networking and dependencies

## 🌐 Access Points

After deployment, access the platform:

- **IntralogisticsAI Web Interface**: `http://localhost:[port]` (shown in deployment output)
- **OpenPLC Programming Environment**: `http://localhost:[port]` (shown in deployment output)
- **Login Credentials**: Username `Administrator`, Password `admin`
- **OpenPLC Credentials**: Username `openplc`, Password `openplc`

## 📊 Using the Platform

### ERP Operations
1. Access the web interface and login
2. Navigate to standard ERPNext modules (Sales, Inventory, etc.)
3. Use the **EpiBus** module for industrial automation features

### PLC Programming
1. Access OpenPLC web interface
2. Create ladder logic programs
3. Upload and start programs to activate MODBUS TCP server
4. Monitor real-time I/O through the web interface

### Industrial Integration
1. Configure MODBUS connections in EpiBus
2. Define signal mappings between ERP and PLC
3. Set up automated actions triggered by ERP events
4. Monitor real-time data flow in the dashboard

## 🔧 Deployment Options

**Complete Industrial Stack (Recommended)**
```bash
./deploy.sh with-plc
```
Includes ERP, PLC simulator, and all automation features.

**EpiBus Only**
```bash
./deploy.sh with-epibus
```
ERP with automation capabilities, no PLC simulator.

**Basic ERP**
```bash
./deploy.sh
```
Standard Frappe/ERPNext without industrial features.

## 🛠️ Development

For development and customization:

```bash
# View service logs
docker compose logs -f backend
docker compose logs -f plc-bridge
docker compose logs -f openplc

# Access backend container
docker compose exec backend bash

# Reset and redeploy
docker compose down --volumes
./deploy.sh with-plc
```

## 📚 Documentation

- [OpenPLC Integration Guide](README-OpenPLC.md)
- [EpiBus API Documentation](epibus/README.md)
- [PLC Bridge Setup](docs/plc-bridge-setup.md)
- [Troubleshooting Guide](docs/troubleshoot.md)

## 🎓 Educational Use

IntralogisticsAI is designed for educational institutions teaching:
- Industrial automation and control systems
- Logistics and supply chain management
- Enterprise resource planning (ERP)
- MODBUS communication protocols
- Docker containerization and microservices

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project builds upon several open-source components:
- [Frappe Framework](https://github.com/frappe/frappe) (MIT License)
- [ERPNext](https://github.com/frappe/erpnext) (GPL v3)
- [OpenPLC](https://openplcproject.com/) (GPL v3)

See [LICENSE](LICENSE) for complete license information.

## 🏢 About

IntralogisticsAI is developed by [Applied Relevance](https://appliedrelevance.com) for educational and industrial applications. It bridges the gap between enterprise software and industrial automation, making advanced logistics concepts accessible for learning and implementation.

---

**Ready to revolutionize your industrial automation education?** 🚀

[Get started with IntralogisticsAI](https://github.com/appliedrelevance/intralogisticsai) today!