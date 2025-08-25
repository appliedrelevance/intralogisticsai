# Traffic Light Controller - MODBUS Address Mapping

## Overview
This document provides the MODBUS register mapping for the Traffic Light Controller program, compatible with EpiBus integration.

## Digital Inputs (Coil Addresses)
| Address | Variable Name | Description | Type |
|---------|---------------|-------------|------|
| %IX0.0  | pedestrian_ns_button | Pedestrian crossing button North-South | BOOL |
| %IX0.1  | pedestrian_ew_button | Pedestrian crossing button East-West | BOOL |
| %IX0.2  | emergency_override | Emergency override button | BOOL |
| %IX0.3  | system_enable | System enable switch | BOOL |
| %IX0.4  | manual_reset | Manual reset button | BOOL |

## Digital Outputs (Coil Addresses)
| Address | Variable Name | Description | Type |
|---------|---------------|-------------|------|
| %QX0.0  | ns_red_light | North-South Red Light | BOOL |
| %QX0.1  | ns_yellow_light | North-South Yellow Light | BOOL |
| %QX0.2  | ns_green_light | North-South Green Light | BOOL |
| %QX0.3  | ew_red_light | East-West Red Light | BOOL |
| %QX0.4  | ew_yellow_light | East-West Yellow Light | BOOL |
| %QX0.5  | ew_green_light | East-West Green Light | BOOL |
| %QX0.6  | ped_ns_walk | Pedestrian NS Walk Signal | BOOL |
| %QX0.7  | ped_ns_dont_walk | Pedestrian NS Don't Walk Signal | BOOL |
| %QX1.0  | ped_ew_walk | Pedestrian EW Walk Signal | BOOL |
| %QX1.1  | ped_ew_dont_walk | Pedestrian EW Don't Walk Signal | BOOL |
| %QX1.2  | system_running | System Running Status | BOOL |
| %QX1.3  | emergency_mode | Emergency Mode Active | BOOL |
| %QX1.4  | fault_status | Fault Status Indicator | BOOL |

## Analog/Integer Registers (Holding Registers)
| Address | Variable Name | Description | Type | Range |
|---------|---------------|-------------|------|-------|
| %MW0    | system_state | Current system state | INT | 0-9 |
| %MW1    | ns_green_cycles | NS Green cycle counter | INT | 0-32767 |
| %MW2    | ew_green_cycles | EW Green cycle counter | INT | 0-32767 |
| %MW3    | ped_ns_cycles | Pedestrian NS cycle counter | INT | 0-32767 |
| %MW4    | ped_ew_cycles | Pedestrian EW cycle counter | INT | 0-32767 |
| %MW5    | emergency_activations | Emergency activation counter | INT | 0-32767 |
| %MW6    | total_runtime_seconds | Total runtime in seconds | INT | 0-32767 |
| %MW7    | cycle_count_total | Total cycle counter | INT | 0-32767 |
| %MW8    | avg_cycle_time | Average cycle time in seconds | INT | 0-32767 |

## Configuration Registers (Input Registers)
| Address | Variable Name | Description | Type | Default |
|---------|---------------|-------------|------|---------|
| %MW100  | green_time_ns_ms | NS Green time in milliseconds | INT | 30000 |
| %MW101  | green_time_ew_ms | EW Green time in milliseconds | INT | 25000 |
| %MW102  | yellow_time_ms | Yellow time in milliseconds | INT | 5000 |
| %MW103  | ped_walk_time_ms | Pedestrian walk time in milliseconds | INT | 15000 |
| %MW104  | ped_clear_time_ms | Pedestrian clearance time in milliseconds | INT | 10000 |
| %MW105  | emergency_flash_time_ms | Emergency flash time in milliseconds | INT | 500 |

## State Machine States
| State Code | State Name | Description |
|------------|------------|-------------|
| 0 | INIT | System initialization |
| 1 | STATE_NS_GREEN | North-South Green phase |
| 2 | STATE_NS_YELLOW | North-South Yellow phase |
| 3 | STATE_EW_GREEN | East-West Green phase |
| 4 | STATE_EW_YELLOW | East-West Yellow phase |
| 5 | STATE_PED_NS_WALK | Pedestrian NS Walk phase |
| 6 | STATE_PED_NS_CLEAR | Pedestrian NS Clearance phase |
| 7 | STATE_PED_EW_WALK | Pedestrian EW Walk phase |
| 8 | STATE_PED_EW_CLEAR | Pedestrian EW Clearance phase |
| 9 | STATE_EMERGENCY | Emergency mode |

## EpiBus Integration
Use the following Python code to integrate with EpiBus in Frappe:

```python
# Example EpiBus signal configuration
signals = [
    {
        "signal_name": "traffic_ns_red",
        "signal_type": "Digital Output",
        "modbus_address": "0.0",
        "description": "North-South Red Light"
    },
    {
        "signal_name": "traffic_system_state", 
        "signal_type": "Analog Input",
        "modbus_address": "0",
        "description": "Current Traffic Light State"
    },
    {
        "signal_name": "ped_ns_button",
        "signal_type": "Digital Input", 
        "modbus_address": "0.0",
        "description": "Pedestrian North-South Button"
    }
]
```

## MODBUS TCP Configuration
- **IP Address**: 192.168.1.100 (OpenPLC container)
- **Port**: 502
- **Unit ID**: 1
- **Function Codes**: 
  - Read Coils (01): Digital inputs/outputs
  - Read Discrete Inputs (02): Status bits
  - Read Holding Registers (03): Configuration/statistics
  - Read Input Registers (04): Real-time data
  - Write Single Coil (05): Control commands
  - Write Single Register (06): Configuration updates