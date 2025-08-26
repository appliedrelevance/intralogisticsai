# CODESYS Intralogistics Lab - Installation Guide

## Quick Start Checklist

- [ ] CODESYS V3.5 SP19+ installed
- [ ] CODESYS Control for Linux SL runtime available
- [ ] Network connectivity established
- [ ] Safety systems verified
- [ ] I/O hardware connected
- [ ] Project imported and compiled
- [ ] Device configured and online
- [ ] MODBUS communication tested

## Detailed Installation Steps

### 1. Prerequisites Verification

#### Software Requirements
- **CODESYS Development System V3.5 SP19 or later**
- **CODESYS Control for Linux SL runtime**
- **Network access** for MODBUS TCP communication
- **Compatible operating system**: Windows 10/11, Linux, or macOS

#### Hardware Requirements
- **Minimum 4GB RAM** for development environment
- **10GB free disk space** for CODESYS installation and projects
- **Ethernet interface** for PLC communication
- **USB/Serial interface** for initial PLC configuration

### 2. CODESYS Development Environment Setup

#### Installing CODESYS
1. Download CODESYS V3.5 from [www.codesys.com](https://www.codesys.com)
2. Run installer with administrator privileges
3. Select **Complete Installation** for full feature set
4. Install required device packages:
   - CODESYS Control for Linux SL
   - MODBUS library
   - Visualization components (optional)

#### License Configuration
1. Open CODESYS Development System
2. Navigate to **Tools > Licenses**
3. Install appropriate licenses for your deployment
4. Verify runtime license for target device

### 3. Target Device Preparation

#### Linux Runtime Setup
```bash
# Install CODESYS Control for Linux SL
sudo dpkg -i codesyscontrol_4.11.0.0_amd64.deb

# Start CODESYS runtime service
sudo systemctl enable codesyscontrol.service
sudo systemctl start codesyscontrol.service

# Verify service status
sudo systemctl status codesyscontrol.service
```

#### Network Configuration
```bash
# Configure static IP (recommended)
sudo nano /etc/netplan/01-network-manager-all.yaml

# Example configuration:
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8]

# Apply configuration
sudo netplan apply
```

### 4. Project Import and Configuration

#### Import Project Files
1. Extract project archive to working directory
2. Open CODESYS Development System
3. Select **File > Open Project**
4. Navigate to `IntralogisticsLab.project`
5. Click **Open** and wait for project to load

#### Device Configuration
1. In project tree, expand **Device**
2. Double-click **IntralogisticsLab_PLC**
3. Configure communication settings:

```
Communication Settings:
- Gateway: 192.168.1.1 (match your network)
- Network Adapter: eth0 (or appropriate interface)  
- Update Rate: 100ms
- Communication Cycle: 10ms

MODBUS Settings:
- MODBUS TCP Port: 502
- MODBUS RTU Port: /dev/ttyS0 (if using serial)
- Timeout: 5000ms
- Max Connections: 5

Task Configuration:
- Main Task Cycle: 100ms
- Priority: 0 (highest)
- Watchdog: 500ms
```

### 5. I/O Configuration and Wiring

#### Digital Input Wiring
| Address | Signal Name | Description | Terminal | Wire Color |
|---------|-------------|-------------|----------|------------|
| %IX0.0 | Emergency_Stop | Emergency stop (NC) | X1.1 | Red |
| %IX0.1 | Manual_Reset | Reset button (NO) | X1.2 | Green |
| %IX0.2 | Start_Button | Start button (NO) | X1.3 | Blue |
| %IX0.3 | Stop_Button | Stop button (NO) | X1.4 | Yellow |

#### Conveyor Sensor Wiring
| Address | Signal Name | Terminal | Sensor Type |
|---------|-------------|----------|-------------|
| %IX1.0 | PE_Sensor_Conv1_Entry | X2.1 | Diffuse |
| %IX1.1 | PE_Sensor_Conv1_Exit | X2.2 | Diffuse |
| %IX1.2 | PE_Sensor_Conv2_Entry | X2.3 | Diffuse |
| %IX1.3 | PE_Sensor_Conv2_Exit | X2.4 | Diffuse |

#### Digital Output Wiring
| Address | Signal Name | Description | Terminal | Load |
|---------|-------------|-------------|----------|------|
| %QX0.0 | System_Running | Status indicator | Y1.1 | LED/24V |
| %QX0.1 | System_Error | Error indicator | Y1.2 | LED/24V |
| %QX1.0 | Conveyor1_Motor | Motor contactor | Y2.1 | Relay/24V |
| %QX1.1 | Conveyor2_Motor | Motor contactor | Y2.2 | Relay/24V |

#### Power Supply Requirements
- **24VDC supply**: 10A minimum for I/O and auxiliary loads
- **120/240VAC supply**: For motor contactors and drives
- **UPS backup**: Recommended for critical systems
- **Isolation**: All I/O circuits galvanically isolated

### 6. Safety System Configuration

#### Emergency Stop Circuit
```
E-Stop Button (NC) → Safety Relay → PLC Input %IX0.0
                  ↓
            Motor Contactors (Force Open)
                  ↓
            Safety System Reset Required
```

#### Safety System Verification
1. Test emergency stop button operation
2. Verify safety relay functionality  
3. Check motor contactor force-open contacts
4. Test manual reset sequence
5. Document safety circuit response times

**CRITICAL**: Safety systems must be tested and certified before operation with personnel present.

### 7. Compilation and Download

#### Project Compilation
1. Select **Build > Clean All** (Ctrl+Shift+F7)
2. Select **Build > Build** (F7)
3. Review Messages window for errors/warnings
4. Resolve any compilation issues before proceeding

#### Common Compilation Issues
- **Missing libraries**: Install required CODESYS libraries
- **Syntax errors**: Check structured text syntax
- **Variable conflicts**: Verify variable declarations
- **Function block errors**: Check FB interface definitions

#### Download to PLC
1. Configure PLC connection:
   - Protocol: Ethernet
   - IP Address: 192.168.1.100 (target device IP)
   - Port: 1217 (default CODESYS port)

2. Connect to PLC:
   - Select **Online > Login** (F4)
   - Wait for connection establishment
   - Verify device information matches

3. Download application:
   - Select **Online > Download** 
   - Choose **Download all** when prompted
   - Wait for download completion
   - Start application with **Debug > Start** (F5)

### 8. MODBUS Communication Setup

#### MODBUS Server Configuration
The PLC automatically starts MODBUS TCP server on port 502. Verify with:

```bash
# Check if MODBUS port is listening
netstat -an | grep :502

# Expected output:
tcp6       0      0 :::502                  :::*                    LISTEN
```

#### Client Connection Testing
Use MODBUS testing tools to verify communication:

```python
# Python example using pymodbus
from pymodbus.client.sync import ModbusTcpClient

client = ModbusTcpClient('192.168.1.100', port=502)
connection = client.connect()

if connection:
    # Read cycle counter (register 100)
    result = client.read_holding_registers(100, 1, unit=1)
    print(f"Cycle Counter: {result.registers[0]}")
    
    # Read bin selection status (coils 2000-2011)
    result = client.read_coils(2000, 12, unit=1)
    print(f"Bin Status: {result.bits}")
    
client.close()
```

### 9. System Testing and Commissioning

#### Functional Testing Sequence
1. **Power-on Test**
   - Verify all LEDs and indicators
   - Check system startup sequence
   - Confirm safety circuit operation

2. **I/O Testing**
   - Test all input devices
   - Verify output operation
   - Check sensor response and timing

3. **Communication Testing**
   - Verify MODBUS connectivity
   - Test read/write operations
   - Check register mapping accuracy

4. **Safety System Testing**
   - Test emergency stop operation
   - Verify safety reset sequence
   - Check interlock functionality

5. **Operational Testing**
   - Test pick operation sequences
   - Verify conveyor automatic control
   - Check RFID reader integration

#### Performance Verification
- **Scan time**: Should be < 50ms consistently
- **Communication latency**: MODBUS response < 100ms
- **Safety response**: Emergency stop < 500ms
- **Memory usage**: < 80% of available memory

### 10. Integration with ERP Systems

#### EpiBus Configuration
The system integrates with EpiBus for ERP communication:

1. Configure EpiBus connection:
   - Host: 192.168.1.100 (PLC IP address)
   - Port: 502
   - Device Type: PLC
   - Update Interval: 1000ms

2. Configure signal mappings in EpiBus:
   - Bin selection signals (coils 2000-2011)
   - Station control signals (coils 2020-2023)
   - Process status signals (coils 1000-1008)
   - Statistics registers (100-111)

### 11. Maintenance and Monitoring

#### Regular Maintenance Tasks
- Monitor system performance metrics
- Check I/O device functionality
- Verify communication stability
- Update software as needed
- Test safety systems periodically

#### Troubleshooting Tools
- CODESYS Online monitoring
- MODBUS diagnostic utilities
- System log analysis
- Performance counters
- Error code interpretation

### 12. Documentation and Training

#### Required Documentation
- **As-built drawings** showing actual wiring
- **I/O configuration** with terminal assignments  
- **Safety circuit** diagrams and test procedures
- **MODBUS mapping** with register descriptions
- **Operating procedures** for normal and emergency situations

#### Training Requirements
- **Operators**: Basic system operation and safety
- **Maintenance**: I/O troubleshooting and replacement
- **Engineers**: Full system modification and programming
- **Safety**: Emergency procedures and lockout/tagout

## Post-Installation Checklist

- [ ] All I/O devices tested and functional
- [ ] Safety systems tested and documented
- [ ] MODBUS communication verified
- [ ] ERP integration confirmed
- [ ] Performance metrics within specifications
- [ ] Documentation complete and delivered
- [ ] Personnel training completed
- [ ] System acceptance signed off

## Support Contacts

- **Technical Support**: Contact your CODESYS system integrator
- **Safety Questions**: Consult qualified safety engineer
- **ERP Integration**: Contact EpiBus support team
- **Emergency**: Follow site emergency procedures

---

**IMPORTANT**: This installation must be performed by qualified personnel familiar with industrial automation safety practices. Always follow local electrical codes and safety regulations.