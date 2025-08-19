# IntralogisticsAI Documentation

Welcome to the comprehensive documentation for IntralogisticsAI - the industrial automation platform for modern logistics education and training.

## 📖 Documentation Structure

### 🚀 Getting Started
- **[Quick Start Guide](deployment/quick-start.md)** - Get up and running in minutes
- **[Mac M-Series Setup](deployment/mac-m4.md)** - Apple Silicon specific instructions
- **[Training Lab Setup](deployment/lab-setup.md)** - Multi-workstation lab configuration

### 🏭 Industrial Integration
- **[EpiBus Integration](epibus/README.md)** - MODBUS TCP and ERP automation
- **[OpenPLC Programming](openplc/README.md)** - PLC simulation and programming
- **[API Documentation](epibus/api.md)** - Advanced integration reference

### 🛠️ Development & Maintenance
- **[Development Setup](development/README.md)** - Development and customization
- **[Troubleshooting](troubleshooting/README.md)** - Common issues and solutions

## 🎯 Choose Your Path

### For Educators
1. **[Lab Setup Guide](deployment/lab-setup.md)** - Configure training environment
2. **[EpiBus Integration](epibus/README.md)** - Connect ERP to industrial devices  
3. **[OpenPLC Programming](openplc/README.md)** - Teach PLC programming concepts

### For Students
1. **[Quick Start Guide](deployment/quick-start.md)** - Basic deployment
2. **[EpiBus Integration](epibus/README.md)** - Learn industrial automation
3. **[OpenPLC Programming](openplc/README.md)** - Practice ladder logic

### For Developers
1. **[Development Setup](development/README.md)** - Local development environment
2. **[API Documentation](epibus/api.md)** - Integration and customization
3. **[Troubleshooting](troubleshooting/README.md)** - Debug and resolve issues

## 🏗️ System Architecture

IntralogisticsAI combines multiple technologies:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ERPNext ERP   │◄──►│     EpiBus      │◄──►│   OpenPLC PLC   │
│   Business      │    │   Integration   │    │   Simulator     │
│   Management    │    │     Layer       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Real Hardware  │
                    │  PLCs, Sensors, │
                    │   Conveyors     │
                    └─────────────────┘
```

## 🚦 Deployment Options

### Training Lab Environment
```bash
./deploy.sh lab
```
- Custom domains: `intralogistics.lab`, `openplc.lab`
- Multi-workstation support
- Real hardware integration

### Complete Industrial Stack  
```bash
./deploy.sh with-plc
```
- Full automation features
- OpenPLC simulator included
- PLC Bridge for real-time communication

### Basic ERP
```bash
./deploy.sh
```
- Standard ERPNext deployment
- No industrial features

## 📚 Learning Resources

### Industrial Automation Concepts
- **MODBUS TCP Protocol** - Understanding industrial communication
- **PLC Programming** - Ladder logic and function blocks
- **ERP Integration** - Connecting business and industrial systems
- **Real-time Systems** - Managing live data flows

### Practical Exercises
1. **Basic ERP Operations** - Items, customers, sales orders
2. **PLC Programming** - Create simple control programs
3. **MODBUS Communication** - Connect ERP to PLC signals
4. **Automation Workflows** - Trigger actions from business events
5. **Real Hardware** - Integrate with actual industrial devices

## 🆘 Getting Help

### Quick References
- **[Troubleshooting Guide](troubleshooting/README.md)** - Solve common issues
- **Service Logs**: `docker compose logs [service-name]`
- **Port Mappings**: `docker compose ps`

### Common Commands
```bash
# Check deployment status
docker compose ps

# View service logs
docker compose logs backend
docker compose logs openplc

# Restart services
docker compose restart

# Complete reset
docker compose down --volumes
./deploy.sh [option]
```

### Support Channels
- **GitHub Issues**: [Report bugs and feature requests](https://github.com/appliedrelevance/intralogisticsai/issues)
- **Documentation**: This guide and linked resources
- **Community**: Industrial automation and ERPNext forums

## 🔄 Updates and Maintenance

### Regular Updates (With Internet)
```bash
# Pull latest changes
git pull origin main

# Update images
docker compose pull

# Redeploy
./deploy.sh [your-option]
```

### Airgapped Updates
```bash
# Save images for transfer
docker save frappe/erpnext > erpnext.tar

# Load on target system
docker load < erpnext.tar
```

---

## 🏢 About IntralogisticsAI

IntralogisticsAI is developed by [Applied Relevance](https://appliedrelevance.com) for educational and industrial applications. It bridges the gap between enterprise software and industrial automation, making advanced logistics concepts accessible for learning and implementation.

**Ready to get started?** Choose your deployment option and follow the relevant guide above!

---

*Last updated: {{ "now" | date: "%Y-%m-%d" }}*