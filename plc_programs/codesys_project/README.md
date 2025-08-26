# CODESYS Intralogistics Learning Lab Project

## Overview

This CODESYS project provides a complete industrial automation solution for the Intralogistics Learning Lab. It simulates a sophisticated warehouse automation system with storage robot control, conveyor management, RFID tracking, and safety systems integrated with ERP systems via MODBUS communication.

## System Architecture

### Core Components
- **Storage Robot Control**: 12-bin automated storage and retrieval system
- **Conveyor System**: 4 conveyors with photo-electric sensors and automatic control
- **RFID Integration**: 2 RFID readers for item tracking and identification
- **Safety Systems**: Emergency stop, safety gates, light curtains, and beacon control
- **ERP Integration**: MODBUS TCP communication for enterprise system integration

### Key Features
- **Modular Design**: Function blocks for each major system component
- **Safety-First**: Comprehensive safety system with multiple interlocks
- **Real-time Communication**: MODBUS TCP server on port 502
- **Scalable Architecture**: Easily extensible for additional equipment
- **Educational Focus**: Well-documented code suitable for learning industrial automation

## Project Structure

```
codesys_project/
├── README.md                          # This file
├── IntralogisticsLab.project          # Main CODESYS project file
├── Device.devdesc.xml                 # Device configuration
├── ModbusMapping.xml                  # MODBUS address mapping
├── 
├── GVLs/                              # Global Variable Lists
│   ├── GVL_IO.var                     # Physical I/O variables
│   ├── GVL_MODBUS.var                 # MODBUS communication variables
│   └── GVL_Internal.var               # Internal system variables
│
├── DUTs/                              # Data Type Definitions
│   ├── DUT_SystemState.dut            # System state enumeration
│   ├── DUT_RobotState.dut             # Robot state enumeration
│   ├── DUT_ConveyorStatus.dut         # Conveyor status enumeration
│   ├── DUT_RFIDStatus.dut             # RFID status enumeration
│   ├── DUT_StationType.dut            # Station type enumeration
│   ├── DUT_ConveyorData.dut           # Conveyor data structure
│   ├── DUT_RobotData.dut              # Robot data structure
│   └── DUT_RFIDData.dut               # RFID data structure
│
└── POUs/                              # Program Organization Units
    ├── MainProgram/
    │   ├── MAIN.prg                   # Main program
    │   └── F_INT_TO_DUT_StationType.fun # Utility function
    │
    ├── ConveyorControl/
    │   ├── FB_ConveyorControl.fub     # Individual conveyor control
    │   └── FB_ConveyorSystem.fub      # Complete conveyor system
    │
    ├── RobotControl/
    │   ├── FB_StorageRobot.fub        # Storage robot control
    │   └── FB_PickOperationControl.fub # Pick operation management
    │
    ├── Communication/
    │   ├── FB_RFIDReader.fub          # Individual RFID reader
    │   └── FB_RFIDSystem.fub          # Complete RFID system
    │
    └── SafetySystems/
        ├── FB_SafetySystem.fub        # Safety system management
        └── FB_BeaconControl.fub       # Status beacon control
```

## Installation Guide

### Prerequisites
- CODESYS V3.5 SP19 or later
- CODESYS Control for Linux SL runtime
- Network access for MODBUS TCP communication

### Step 1: Import Project
1. Open CODESYS Development System
2. Select **File > Open Project**
3. Navigate to `IntralogisticsLab.project` and open
4. Wait for project to load completely

### Step 2: Configure Device
1. In the project tree, double-click **Device (IntralogisticsLab_PLC)**
2. Verify communication settings:
   - Gateway: 192.168.1.1 (or your network gateway)
   - Network Adapter: eth0 (or appropriate interface)
   - MODBUS TCP Port: 502

### Step 3: Compile Project
1. Select **Build > Build** (F7)
2. Check for compilation errors in the Messages window
3. Resolve any errors before proceeding

### Step 4: Download to PLC
1. Connect to your CODESYS runtime target
2. Select **Online > Login** (F4)
3. Select **Online > Download** 
4. Confirm download when prompted
5. Select **Debug > Start** (F5) to begin execution

### Step 5: Configure I/O Mapping
1. Verify physical I/O connections match the device configuration
2. Test emergency stop and safety circuits before operation
3. Configure MODBUS client connections as needed

## MODBUS Communication

### Server Configuration
- **Port**: 502 (standard MODBUS TCP)
- **Unit ID**: 1
- **Max Connections**: 5
- **Timeout**: 5 seconds

### Key MODBUS Addresses

#### Process Control (Coils 1000-1008)
- **1000**: PLC_CYCLE_STOPPED
- **1001**: PLC_CYCLE_RUNNING  
- **1002**: PICK_ERROR
- **1003**: PICK_TO_ASSEMBLY_IN_PROCESS
- **1004**: PICK_TO_ASSEMBLY_COMPLETE
- **1005**: PICK_TO_RECEIVING_IN_PROCESS
- **1006**: PICK_TO_RECEIVING_COMPLETE
- **1007**: PICK_TO_WAREHOUSE_IN_PROCESS
- **1008**: PICK_TO_WAREHOUSE_COMPLETE

#### Bin Selection (Coils 2000-2011) - ERP Controlled
- **2000-2011**: PICK_BIN_01 through PICK_BIN_12

#### Station Control (Coils 2020-2023) - ERP Controlled
- **2020**: TO_RECEIVING_STA_1
- **2021**: FROM_RECEIVING_STA_1
- **2022**: TO_ASSEMBLY_STA_2
- **2023**: FROM_ASSEMBLY_STA_2

#### Statistics (Holding Registers 100-111)
- **100**: CYCLE_COUNTER
- **101**: PICK_OPERATIONS_TOTAL
- **102**: ASSEMBLY_PICKS
- **103**: RECEIVING_PICKS
- **104**: WAREHOUSE_PICKS
- **105**: ERROR_COUNT
- **106**: UPTIME_SECONDS
- **107**: SYSTEM_STATUS
- **108**: CURRENT_BIN_SELECTION
- **109**: ROBOT_POSITION_X
- **110**: ROBOT_POSITION_Y
- **111**: ROBOT_POSITION_Z

## Operation Guide

### Starting the System
1. Ensure all safety circuits are functional
2. Press the **Start Button** or set HMI_System_Start = TRUE
3. System will initialize and move to READY state
4. Green beacon will illuminate when ready for operation

### Pick Operation Sequence
1. ERP system sets desired bin selection (coils 2000-2011)
2. ERP system sets target station (coils 2020-2023)
3. PLC detects selection and begins pick operation
4. Robot moves to selected bin position
5. Robot picks item and moves to target station
6. Operation complete signal is set (coils 1004/1006/1008)
7. Complete signal auto-resets after 10 seconds

### Manual Mode
1. Set HMI_Manual_Mode = TRUE
2. Yellow beacon will illuminate
3. Conveyors operate in manual mode
4. Robot operations still follow ERP commands
5. Safety systems remain active

### Emergency Stop Recovery
1. Address cause of emergency stop
2. Reset safety systems if needed
3. Press **Manual Reset** button
4. Wait for safety reset sequence (3 seconds)
5. System returns to normal operation

## System States

### Robot States
- **ROBOT_IDLE**: Robot at home position, ready for operation
- **ROBOT_MOVING_TO_BIN**: Robot moving to selected bin
- **ROBOT_AT_BIN**: Robot positioned at bin
- **ROBOT_PICKING**: Robot picking item from bin
- **ROBOT_MOVING_TO_STATION**: Robot moving to target station
- **ROBOT_AT_STATION**: Robot at station position
- **ROBOT_PLACING**: Robot placing item at station
- **ROBOT_RETURNING_HOME**: Robot returning to home position
- **ROBOT_ERROR**: Robot error state

### System Status Codes (Register 107)
- **0**: SYSTEM_STOPPED - System stopped/not running
- **1**: SYSTEM_STARTING - System initializing
- **2**: SYSTEM_RUNNING - System running normally
- **3**: SYSTEM_STOPPING - System shutting down
- **4**: SYSTEM_ERROR - System error state
- **5**: SYSTEM_MANUAL - System in manual mode

## Safety Features

### Emergency Stop System
- Hardware emergency stop button (IX0.0)
- Software emergency stop monitoring
- Immediate shutdown of all motion
- Beacon indication (flashing red)
- Audio alarm activation

### Safety Interlocks
- Safety gate monitoring
- Light curtain supervision
- Robot collision avoidance
- Conveyor overload protection
- Communication timeout monitoring

### Beacon Status Indication
- **Green (Solid)**: System ready
- **Green (Flashing)**: Operation active
- **Yellow (Solid)**: Manual mode
- **Yellow (Flashing)**: System error
- **Red (Flashing)**: Emergency/safety fault
- **Pattern**: System stopped

## Troubleshooting

### Common Issues

#### Communication Errors
- Verify network connectivity
- Check MODBUS port 502 accessibility
- Confirm client connection parameters
- Monitor connection timeout settings

#### Robot Not Responding
- Check robot enable signal (QX2.0)
- Verify home position sensor (IX2.0)
- Check for error conditions (IX2.5)
- Reset robot system if needed

#### Conveyor Issues
- Verify motor outputs (QX1.0-QX1.3)
- Check photo-electric sensors (IX1.0-IX1.7)
- Test in manual mode first
- Check for fault conditions

#### Safety System Faults
- Verify emergency stop circuit
- Check safety gate closure
- Test light curtain operation
- Perform safety system reset

### Diagnostic Features
- Real-time status monitoring via MODBUS
- Error code reporting (register 105)
- System uptime tracking (register 106)
- Performance counters and statistics

## Development and Customization

### Adding New Equipment
1. Define new I/O points in GVL_IO.var
2. Create appropriate data structures in DUTs/
3. Develop function blocks for equipment control
4. Update main program to include new equipment
5. Add MODBUS mappings if needed

### Modifying Operation Sequences
1. Edit relevant function blocks (FB_PickOperationControl, etc.)
2. Update timing parameters as needed
3. Test thoroughly before deployment
4. Update documentation

### Safety System Modifications
**WARNING**: Safety system changes require qualified personnel and thorough testing. Always maintain safety integrity levels.

## Educational Applications

This project demonstrates:
- **Industrial Automation Concepts**: State machines, timers, safety systems
- **Communication Protocols**: MODBUS TCP implementation
- **System Integration**: ERP to PLC communication
- **Safety Engineering**: Emergency stop systems, risk assessment
- **Structured Programming**: Function blocks, data structures, modular design
- **Project Organization**: Professional development practices

## Support and Documentation

For technical support or questions about this project:
- Review the inline code comments for detailed explanations
- Check the CODESYS documentation for platform-specific features
- Consult industrial automation safety standards (ISO 13849, IEC 62061)
- Contact your CODESYS system integrator for deployment assistance

## Version History

- **v1.0** (2025-08-25): Initial release with complete functionality
  - Storage robot control (12 bins)
  - 4-conveyor system with automatic control
  - 2-RFID reader integration
  - Comprehensive safety systems
  - MODBUS TCP communication
  - Beacon control and status indication

---

**Important Safety Notice**: This system includes safety-critical functions. Always ensure proper safety circuit implementation and testing before operation with personnel present.