# Intralogistics Learning Lab - HMI Visualization System

This directory contains the comprehensive Human-Machine Interface (HMI) visualization files for the Intralogistics Learning Lab CODESYS project. The HMI system provides modern, intuitive control and monitoring screens that replicate the functionality of the Unitronics ladder logic system with enhanced visualization capabilities.

## Overview

The HMI system consists of 6 main visualization screens designed to provide complete control and monitoring of the automated storage and retrieval system:

1. **MainOverview** - Central dashboard with system status and navigation
2. **ConveyorControl** - Individual conveyor controls and monitoring  
3. **StorageRobot** - 12-bin rack visualization and robot control
4. **RFIDSystem** - RFID reader status and tag identification
5. **SafetyDiagnostics** - Safety systems, alarms, and diagnostics
6. **ManualControl** - Manual operation modes for maintenance/testing

## Screen Descriptions

### 1. MainOverview.visualization
**Main System Dashboard**

**Features:**
- Real-time system status indicators (Running, Stopped, Error, Manual modes)
- Emergency stop and safety system status
- Conveyor system overview with individual status lights
- Storage robot position and operational status
- Current pick operation status (Assembly, Receiving, Warehouse)
- Performance metrics (cycle counter, total picks, error count, uptime)
- Navigation buttons to all sub-screens

**Key Variables Monitored:**
- `GVL_Internal.System_State` - Overall system state
- `GVL_Internal.Emergency_Stop_Active` - E-stop status
- `GVL_IO.Conveyor1_Motor` through `GVL_IO.Conveyor4_Motor` - Conveyor status
- `GVL_MODBUS.Pick_To_*_In_Process/Complete` - Operation status
- `GVL_MODBUS.Cycle_Counter`, `Error_Count`, `Uptime_Seconds` - Performance metrics

### 2. ConveyorControl.visualization
**Conveyor System Control Interface**

**Features:**
- Individual conveyor control panels (4 conveyors)
- Start/Stop buttons for each conveyor
- Photo-electric sensor status indicators
- Conveyor speed displays
- Auto/Manual mode selection
- System-wide Start All/Stop All controls
- Real-time sensor feedback visualization

**Key Variables Controlled:**
- `GVL_Internal.Conveyor*_Run_Request` - Individual conveyor control
- `GVL_Internal.Conveyor_Auto_Mode` - Auto/manual mode toggle
- `GVL_IO.PE_Sensor_Conv*_Entry/Exit` - Sensor status monitoring
- `GVL_MODBUS.Conveyor*_Speed` - Speed monitoring

### 3. StorageRobot.visualization
**Storage Robot & Bin Management**

**Features:**
- Visual 12-bin storage rack layout (4 rows x 3 columns)
- Interactive bin selection (bins 1-12)
- Robot status display (position, state, target bin)
- Gripper status and manual control
- Pick operation status indicators
- Manual robot movement controls
- Clear all bin selections function

**Key Variables Controlled:**
- `GVL_MODBUS.Pick_Bin_01` through `Pick_Bin_12` - Bin selection
- `GVL_IO.Robot_*` commands - Robot movement and gripper control
- `GVL_Internal.Robot_State`, `Robot_Target_Bin` - Robot status
- Pick operation status monitoring

### 4. RFIDSystem.visualization
**RFID Reader Management**

**Features:**
- Dual RFID reader status (Assembly & Receiving stations)
- Real-time tag presence indicators
- Tag ID displays with hexadecimal formatting
- Reader status codes (Idle, Reading, Valid, Error)
- Manual reader enable/disable controls
- RFID system statistics and read counters
- Communication status monitoring
- Last tag identification display

**Key Variables Monitored:**
- `GVL_IO.RFID_Reader*_Ready/Tag_Present` - Reader status
- `GVL_MODBUS.RFID_Reader*_Tag_ID/Status` - Tag data and status
- `GVL_Internal.RFID*_Processing/Read_Timer` - Processing status

### 5. SafetyDiagnostics.visualization
**Safety Systems & Diagnostics**

**Features:**
- Emergency stop status with prominent visual indication
- Safety circuit monitoring (gate, light curtain status)
- Visual beacon control panel (Green, Yellow, Red, Buzzer)
- Beacon pattern display and manual testing
- System diagnostics (error codes, timers, performance counters)
- Active alarm and event monitoring
- Error reset functionality
- Real-time safety input status

**Key Variables Monitored:**
- `GVL_Internal.Emergency_Stop_Active`, `Safety_Circuit_OK` - Safety status
- `GVL_Internal.Error_Code`, `Last_Error_Code` - Error tracking
- `GVL_IO.Green_Beacon`, `Yellow_Beacon`, `Red_Beacon` - Visual indicators
- `GVL_Internal.Safety_Gate_Closed`, `Light_Curtain_Clear` - Safety inputs

### 6. ManualControl.visualization
**Manual Operation & Testing Interface**

**Features:**
- Manual/Auto mode selection with safety warnings
- Individual robot control (enable, movement, gripper)
- Individual conveyor manual control
- I/O simulation for testing (start/stop/e-stop buttons)
- Manual beacon control for testing
- System reset and recovery functions
- Emergency reset with safety override
- Current system status display

**Key Variables Controlled:**
- `GVL_Internal.Manual_Mode_Active` - Mode selection
- All robot and conveyor manual controls
- Safety system overrides for testing
- System initialization and reset functions

## Technical Implementation

### Variable Binding
All HMI screens are dynamically bound to the global variable lists:
- **GVL_IO.var** - Physical I/O points
- **GVL_Internal.var** - Internal system variables  
- **GVL_MODBUS.var** - MODBUS communication registers

### Visual Design Standards
- **Colors:**
  - Green (65280) - Normal/Running status
  - Red (255) - Error/Alarm conditions
  - Yellow (16776960) - Warning/Manual mode
  - Gray (12632256) - Inactive/Disabled
  - Blue (14277081) - Navigation buttons

- **Fonts:**
  - Arial Bold 16pt - Main titles
  - Arial Bold 12pt - Panel titles
  - Arial 10pt - Standard labels
  - Courier New - Numeric displays and tag IDs

### Navigation System
- Consistent back button on all screens
- Main overview serves as central hub
- Screen names match visualization file names
- Button-based navigation between all screens

### Dynamic Elements
- Real-time color changes based on variable states
- Dynamic text content using expression binding
- Conditional visibility for status messages
- Animated indicators for system activity

## Safety Features

### Visual Safety Indicators
- Emergency stop status prominently displayed on all screens
- Red background for critical alarms
- Safety circuit status monitoring
- Manual mode warnings and restrictions

### Safety Interlocks
- Manual control screen includes safety warnings
- Emergency reset functions with proper safeguards
- Safety system status verification before operations
- Clear indication of manual mode activation

## MODBUS Integration

The HMI system fully integrates with the MODBUS mapping:
- **Registers 100-111** - System status and statistics
- **Registers 200-210** - RFID data
- **Registers 300-320** - Conveyor status
- **Coils 1000-1008** - Process control signals
- **Coils 2000-2023** - Bin and station controls

## Installation and Configuration

### CODESYS Integration
1. Import all `.visualization` files into the CODESYS project
2. Ensure all referenced global variable lists are present
3. Verify variable bindings match your I/O configuration
4. Set MainOverview as the startup visualization

### Screen Resolution
- Designed for 1200x800 resolution
- Scalable for different display sizes
- Touch-screen compatible interface design

### Testing Procedures
1. **Offline Testing** - Use CODESYS simulation mode
2. **Variable Simulation** - Test all dynamic elements
3. **Navigation Testing** - Verify all screen transitions
4. **Safety Testing** - Confirm safety indicator functionality

## Maintenance and Troubleshooting

### Common Issues
- **Variable Not Found** - Check GVL imports and spelling
- **Screen Not Loading** - Verify XML syntax and element IDs
- **Colors Not Changing** - Check expression syntax in dynamic properties
- **Navigation Broken** - Confirm visualization names match file names

### Customization Guidelines
- Maintain consistent color scheme across screens
- Keep safety-critical elements prominently visible
- Test all changes in simulation before deployment
- Document any modifications to variable bindings

## Educational Use

This HMI system is designed for educational purposes in the Intralogistics Learning Lab, providing:
- Realistic industrial HMI experience
- Integration of modern visualization with PLC control
- Hands-on learning for automation students
- Safe environment for testing and experimentation

The system demonstrates industry-standard HMI design principles while maintaining educational accessibility and safety features appropriate for laboratory use.