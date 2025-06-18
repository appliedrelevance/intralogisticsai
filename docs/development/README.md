# Development Guide

Guide for developers contributing to IntralogisticsAI or creating custom integrations.

## Development Environment

### Quick Setup with VS Code DevContainers

**Recommended approach for development:**
```bash
# Clone repository
git clone https://github.com/appliedrelevance/intralogisticsai
cd intralogisticsai

# Setup DevContainer
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode

# Open in VS Code
code .
# Then: "Reopen in Container"
```

### Manual Development Setup
```bash
# Start development environment
docker compose -f .devcontainer/docker-compose.yml up -d

# Access development container
docker exec -it devcontainer-frappe-1 bash

# Inside container - install apps
cd frappe-bench
bench get-app --branch version-15 erpnext
bench --site development.localhost install-app erpnext
bench --site development.localhost install-app epibus
```

## Project Structure

```
intralogisticsai/
├── compose.yaml                 # Base Docker Compose
├── overrides/                   # Deployment configurations
│   ├── compose.lab.yaml        # Training lab setup
│   ├── compose.openplc.yaml    # OpenPLC integration
│   └── compose.plc-bridge.yaml # PLC Bridge service
├── epibus/                      # EpiBus app source
│   ├── epibus/                 # Core app code
│   ├── frontend/               # React dashboard
│   └── plc/                    # PLC integration services
├── docs/                        # Documentation
├── development/                 # Development tools
└── deploy.sh                   # Deployment script
```

## Code Style Guidelines

### Python (EpiBus Backend)
- **Indentation**: Tabs
- **Quotes**: Double quotes
- **Line Length**: 110 characters
- **Naming**: PascalCase (classes), snake_case (functions/variables)
- **Imports**: stdlib → third-party → local
- **Error Handling**: Use EpinomyLogger for exceptions

### TypeScript (Frontend)
- **Indentation**: 2 spaces
- **Quotes**: Single quotes
- **Components**: Functional with TypeScript interfaces
- **Naming**: PascalCase (components), camelCase (functions/variables)
- **Error Handling**: Try/catch with state management

## Development Workflows

### Backend Development (EpiBus)
```bash
# Access backend container
docker compose exec backend bash

# Navigate to EpiBus app
cd apps/epibus

# Run tests
python -m unittest discover epibus.tests

# Run specific test
python -m epibus.tests.test_modbus_action_conditions

# Install in development mode
bench --site development.localhost install-app epibus --force
```

### Frontend Development
```bash
# Navigate to frontend directory
cd epibus/frontend

# Install dependencies
npm install

# Start development server
npm run start

# Build for production
npm run build

# Run tests
npm test
```

### Database Development
```bash
# Create new site for testing
docker compose exec backend bench new-site test.localhost \
  --admin-password admin \
  --db-root-password 123 \
  --install-app erpnext \
  --install-app epibus

# Database migrations
docker compose exec backend bench --site test.localhost migrate

# Backup/restore
docker compose exec backend bench --site test.localhost backup
docker compose exec backend bench --site test.localhost restore [backup-file]
```

## Testing

### Unit Tests
```bash
# Run all EpiBus tests
python -m unittest discover epibus.tests

# Run specific test module
python -m unittest epibus.tests.test_modbus_connection

# Run with coverage
python -m coverage run -m unittest discover
python -m coverage report
```

### Integration Tests
```bash
# Test MODBUS connectivity
python -c "
from pymodbus.client import ModbusTcpClient
client = ModbusTcpClient('openplc', 502)
print('MODBUS Connected:', client.connect())
"

# Test EpiBus API
curl http://localhost:8000/api/method/epibus.api.plc.get_signals
```

### Performance Testing
```bash
# Monitor resource usage
docker stats

# Test concurrent connections
ab -n 100 -c 10 http://localhost:8000/

# Database performance
docker compose exec backend bench --site test.localhost execute \
  "SELECT COUNT(*) FROM tabItem"
```

## Creating Custom Apps

### New Frappe App
```bash
# Inside backend container
bench new-app my_custom_app

# Install on site
bench --site development.localhost install-app my_custom_app

# Create DocType
bench --site development.localhost console
# Then in console:
# frappe.get_doc({"doctype": "DocType", "name": "My Custom DocType"}).insert()
```

### Custom MODBUS Integration
```python
# Example custom MODBUS handler
import frappe
from epibus.modbus.connection import ModbusConnection

class CustomModbusHandler:
    def __init__(self, connection_name):
        self.connection = frappe.get_doc("Modbus Connection", connection_name)
    
    def read_custom_data(self):
        """Custom data reading logic"""
        # Implement your custom MODBUS reading
        pass
    
    def process_data(self, data):
        """Process and store data in custom DocType"""
        custom_doc = frappe.get_doc({
            "doctype": "Custom Data Log",
            "timestamp": frappe.utils.now(),
            "data": data
        })
        custom_doc.insert()
```

## Debugging

### Backend Debugging
```bash
# Enable debug mode
export DEVELOPER_MODE=1

# View logs
docker compose logs -f backend

# Access Python debugger
docker compose exec backend bench --site development.localhost console

# Check configuration
docker compose exec backend bench --site development.localhost show-config
```

### Frontend Debugging
```bash
# Enable React dev tools
npm run start

# View browser console for errors
# Use React DevTools browser extension

# Debug API calls
curl -X GET http://localhost:8000/api/method/epibus.api.plc.get_signals \
  -H "Authorization: token [api-key]:[api-secret]"
```

### Network Debugging
```bash
# Test container networking
docker compose exec backend ping openplc
docker compose exec backend telnet openplc 502

# Check port mappings
docker compose ps

# Monitor network traffic
docker compose exec backend tcpdump -i eth0 port 502
```

## Contributing Guidelines

### Code Contributions
1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Follow code style** guidelines above
4. **Add tests** for new functionality
5. **Update documentation** as needed
6. **Submit pull request** with clear description

### Documentation Contributions
1. **Update relevant docs** in `docs/` folder
2. **Follow Markdown standards**
3. **Include code examples** where helpful
4. **Test documentation** by following your own instructions

### Bug Reports
1. **Use GitHub Issues** with bug report template
2. **Include system information** (OS, Docker version, etc.)
3. **Provide reproduction steps**
4. **Include relevant logs** from `docker compose logs`

## Release Process

### Version Management
```bash
# Update version in apps
# For EpiBus: epibus/hooks.py
app_version = "1.2.0"

# Create git tag
git tag v1.2.0
git push origin v1.2.0
```

### Building Release Images
```bash
# Build custom image with latest changes
./development/build-epibus-image.sh

# Tag for release
docker tag frappe-epibus:latest frappe-epibus:v1.2.0

# Push to registry (if applicable)
docker push frappe-epibus:v1.2.0
```

### Documentation Updates
```bash
# Update version references in documentation
# Update CHANGELOG.md
# Update README.md if needed
```

## Environment Variables

### Development Environment
```bash
# .env for development
DEVELOPER_MODE=1
FRAPPE_API_KEY=your_dev_key
FRAPPE_API_SECRET=your_dev_secret
DB_PASSWORD=123
LOG_LEVEL=DEBUG
```

### Custom Configuration
```bash
# Custom apps
CUSTOM_IMAGE=your-registry/frappe-custom
CUSTOM_TAG=dev

# PLC settings
PLC_POLL_INTERVAL=0.5
PLC_LOG_LEVEL=DEBUG
OPENPLC_LOG_LEVEL=DEBUG
```

## Performance Optimization

### Database Optimization
```bash
# Optimize MariaDB settings in overrides
# Add to compose.mariadb.yaml:
command: >
  --innodb-buffer-pool-size=2G
  --innodb-log-file-size=512M
  --max-connections=1000
```

### Caching Optimization
```bash
# Redis memory optimization
# Increase Redis memory limit
# Enable Redis persistence for development
```

### Development Speed
```bash
# Use local volumes for faster file sync
# Enable Docker BuildKit
export DOCKER_BUILDKIT=1

# Use multi-stage builds
# Cache dependencies in Docker layers
```

---

**Need Help?** Check the [Troubleshooting Guide](../troubleshooting/README.md) or create a GitHub issue for development-specific questions.