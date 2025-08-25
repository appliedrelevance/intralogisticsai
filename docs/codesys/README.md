# CODESYS Integration Guide

CODESYS is integrated as a containerized PLC simulator providing MODBUS TCP connectivity for industrial automation training and testing.

## Overview

CODESYS provides:
- **PLC Simulator**: Full ladder logic programming environment
- **MODBUS TCP Server**: Port 502 for industrial communication
- **Web Interface**: Programming and monitoring interface
- **ARM64 Support**: Native Apple Silicon compatibility

## Deployment

### With Complete Stack
```bash
# Training lab with CODESYS
./deploy.sh lab
# Access: http://codesys.lab

# Or complete PLC stack
./deploy.sh with-plc
# Access: http://localhost:[port] (shown in output)
```

### CODESYS Only
```bash
# If you only need PLC simulation
./deploy.sh with-epibus
# Includes EpiBus but excludes PLC Bridge
```

## Access Points

### Lab Environment
- **Web Interface**: http://codesys.lab
- **MODBUS TCP**: codesys:502 (from containers) or localhost:502

### Standard Deployment
- **Web Interface**: http://localhost:[port] (check `docker compose ps`)
- **MODBUS TCP**: localhost:502

### Default Credentials
- **Username**: `codesys`
- **Password**: `codesys`

## Programming CODESYS

### 1. Access Web Interface
Login to the CODESYS web interface using the credentials above.

### 2. Create Ladder Logic Program
```
|--[%IX0.0]--[%IX0.1]--(%QX0.0)--|
|                                |
|--[%IX0.2]--NOT--(%QX0.1)-------|
```

### 3. Configure I/O
- **Digital Inputs**: %IX0.0, %IX0.1, %IX0.2...
- **Digital Outputs**: %QX0.0, %QX0.1, %QX0.2...
- **Analog Inputs**: %IW0, %IW1, %IW2...
- **Analog Outputs**: %QW0, %QW1, %QW2...

### 4. Start Runtime
Click "Start PLC" to activate the MODBUS TCP server on port 502.

## Integration with EpiBus

### MODBUS Connection Setup
In IntralogisticsAI, navigate to EpiBus → MODBUS Connections:

1. **Create New Connection**:
   - **Name**: CODESYS Simulator
   - **Host**: `codesys` (internal) or `localhost` (external)
   - **Port**: `502`
   - **Unit ID**: `1`

2. **Configure Signals**:
   - **Digital Input**: Address 0, Function Code 2 (Read Discrete Inputs)
   - **Digital Output**: Address 0, Function Code 1 (Read Coils)
   - **Analog Input**: Address 0, Function Code 4 (Read Input Registers)
   - **Analog Output**: Address 0, Function Code 3 (Read Holding Registers)

### Python Integration Example
```python
# From Frappe backend
from pymodbus.client import ModbusTcpClient

def read_plc_sensors():
    """Read sensor data from CODESYS"""
    client = ModbusTcpClient('codesys', 502)
    
    if client.connect():
        # Read digital inputs (discrete inputs)
        digital_inputs = client.read_discrete_inputs(0, 8)
        
        # Read analog inputs (input registers) 
        analog_inputs = client.read_input_registers(0, 4)
        
        client.close()
        
        return {
            'digital': digital_inputs.bits if not digital_inputs.isError() else [],
            'analog': analog_inputs.registers if not analog_inputs.isError() else []
        }
    
    return None

def control_plc_outputs(outputs):
    """Write output data to CODESYS"""
    client = ModbusTcpClient('codesys', 502)
    
    if client.connect():
        # Write digital outputs (coils)
        client.write_coils(0, outputs.get('digital', []))
        
        # Write analog outputs (holding registers)
        client.write_registers(0, outputs.get('analog', []))
        
        client.close()
        return True
    
    return False
```

## MODBUS Address Mapping

### CODESYS to MODBUS Mapping
| CODESYS Variable | MODBUS Address | Function Code | Description |
|------------------|----------------|---------------|-------------|
| %IX0.0 | 0 | 2 | Digital Input 0 |
| %QX0.0 | 0 | 1 | Digital Output 0 |
| %IW0 | 0 | 4 | Analog Input 0 |
| %QW0 | 0 | 3 | Analog Output 0 |

### Function Codes
- **1**: Read Coils (Digital Outputs)
- **2**: Read Discrete Inputs (Digital Inputs)
- **3**: Read Holding Registers (Analog Outputs)
- **4**: Read Input Registers (Analog Inputs)

## Real Hardware Integration

For connecting to real PLCs instead of CODESYS:

### 1. Configure Real PLC Connection
In EpiBus → MODBUS Connections:
- **Host**: `192.168.1.200` (real PLC IP)
- **Port**: `502`
- **Unit ID**: `1` (depends on PLC configuration)

### 2. Switch Between Simulator and Real
Use EpiBus connection management to easily switch between:
- **Development**: CODESYS simulator
- **Production**: Real PLC hardware

## Troubleshooting

### Service Issues
```bash
# Check CODESYS status
docker compose ps codesys

# View logs
docker compose logs codesys

# Restart CODESYS
docker compose restart codesys
```

### MODBUS Connectivity
```bash
# Test MODBUS connection
telnet localhost 502

# Test from Python
python3 -c "
from pymodbus.client import ModbusTcpClient
client = ModbusTcpClient('localhost', 502)
print('Connected:', client.connect())
client.close()
"
```

### Common Issues

**Web interface not accessible:**
- Check port mapping: `docker compose ps`
- Verify container is healthy: look for "healthy" status

**MODBUS connection refused:**
- Ensure PLC runtime is started in CODESYS web interface
- Check firewall settings
- Verify port 502 is not blocked

**Program not running:**
- Upload and compile ladder logic program first
- Click "Start PLC" to begin runtime execution
- Check CODESYS logs for compilation errors

## Advanced Configuration

### Persistent Data
CODESYS programs and settings are stored in Docker volumes:
```bash
# Backup CODESYS data
docker run --rm -v intralogisticsai_codesys-data:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/codesys-backup.tar.gz -C /data .

# Restore CODESYS data
docker run --rm -v intralogisticsai_codesys-data:/data \
  -v $(pwd):/backup alpine \
  tar xzf /backup/codesys-backup.tar.gz -C /data
```

### Environment Variables
Configure in `.env` file:
```bash
# CODESYS settings
OPENPLC_WEB_PORT=8081
OPENPLC_MODBUS_PORT=502
OPENPLC_LOG_LEVEL=INFO
```

## Learning Resources

### CODESYS Programming
1. **Ladder Logic Basics**: Learn standard ladder logic programming
2. **I/O Configuration**: Understand input/output addressing
3. **Timer/Counter Functions**: Use built-in timer and counter blocks
4. **Function Blocks**: Create reusable function blocks

### Industrial Integration
1. **MODBUS Protocol**: Understand MODBUS TCP/IP communication
2. **EpiBus Configuration**: Set up connections and signals
3. **Automation Workflows**: Link ERP events to PLC actions
4. **Real Hardware**: Progress from simulation to real PLCs

---

**Next Steps**: See [Lab Setup Guide](../deployment/lab-setup.md) for multi-workstation configuration with CODESYS integration.