# ERPNext Stock Module to Factory Automation Guide

## Table of Contents
1. [ERPNext Stock Fundamentals](#erpnext-stock-fundamentals)
2. [The Warehouse Terminology Problem](#the-warehouse-terminology-problem)
3. [Document Types and Triggers](#document-types-and-triggers)
4. [ModBus Connection - The Signal Registry](#modbus-connection---the-signal-registry)
5. [Server Script Logic](#server-script-logic)
6. [Complete Signal Flow Mapping](#complete-signal-flow-mapping)
7. [Workflow Examples](#workflow-examples)
8. [Troubleshooting Guide](#troubleshooting-guide)

---

## ERPNext Stock Fundamentals

### The Core Concept: ERPNext Tracks "What is Where"

ERPNext's Stock Module is fundamentally an **inventory tracking system** that maintains a record of:
- **What items exist** (Item Master)
- **Where they are located** (Warehouse locations)
- **How many are in each location** (Stock quantities)
- **How they move between locations** (Stock transactions)

In a traditional business setting, this might track products in different rooms, shelves, or buildings. In our **industrial automation context**, we're tracking items as they move between different **stations in a factory layout**.

### Key Stock Module Components

**Items**: Physical products that need to move around the factory
- Examples: "Ball Chain Keychain", "White Wallet Front & Base", "Adult Purple & White Globe"
- Each item has a unique Item Code and can exist in multiple locations

**Warehouses**: Every possible location where inventory can exist  
- In ERPNext, ALL locations are called "warehouses" (more on this terminology problem below)
- Examples in our system: "Storage Bin 1", "Receiving Area", "Pick and Pack Area"

**Stock Levels**: The quantity of each item in each warehouse location
- ERPNext maintains real-time counts: "Storage Bin 3 contains 5 Ball Chain Keychains"
- When items move, these counts automatically update

**Stock Transactions**: The actual movement records
- Every time an item moves from Location A to Location B, a document must be submitted
- This creates an audit trail of all inventory movements

---

## The Warehouse Terminology Problem

### The Frustrating Reality

**ERPNext calls EVERYTHING a "warehouse"** - and yes, this is confusing and stupid, but it's unchangeable. In our factory automation context, understanding this terminology is crucial for students.

### What ERPNext "Warehouses" Actually Represent

In our intralogistics system, an ERPNext "warehouse" can be:

| ERPNext Warehouse Name | Physical Reality | Robot/HMI Equivalent |
|------------------------|------------------|----------------------|
| **Storage Bin 1** | Physical storage compartment #1 | HMI "B1" button |
| **Storage Bin 2** | Physical storage compartment #2 | HMI "B2" button |
| **Receiving Area** | Incoming goods station | HMI "TO RECEIVING STATION" |
| **Pick and Pack Area** | Assembly/manufacturing station | HMI "TO PICK&PACK STATION" |
| **Shipping Area** | Outbound goods station | Robot staging zone |

### The Key Insight

When a student selects "Storage Bin 3" as a warehouse in ERPNext, they are **commanding the robot to interact with physical storage compartment #3**. The "warehouse" is not a building - it's a **specific location in the factory layout** where the robot can pick or place items.

### Why This Matters

Students often struggle because they think:
- ❌ "I'm moving inventory between different buildings"
- ❌ "This is just software - it doesn't affect the real world"

But the reality is:
- ✅ "I'm commanding a robot to physically move items between stations"
- ✅ "My ERPNext document submission triggers real hardware"

---

## Document Types and Triggers

### The Movement Requirement: Documents Drive Action

In ERPNext, **you cannot move inventory without submitting a document**. This isn't just a software rule - in our system, it's what triggers the physical robot movements.

### Primary Document Types

#### 1. Stock Entry Documents
**Purpose**: Generic item movements between any two warehouses
**When to Use**: Moving items between storage locations, restocking, transfers
**What Happens**: 
- Student fills out source warehouse, destination warehouse, items, quantities
- Upon submission, server scripts check the warehouses involved
- Appropriate robot movement sequence is triggered

**Example Stock Entry Fields:**
```
Source Warehouse: Storage Bin 3
Target Warehouse: Receiving Area  
Item: Ball Chain Keychain
Quantity: 2
```

#### 2. Pick List Documents  
**Purpose**: Specialized for manufacturing/assembly workflows
**When to Use**: Picking items for production orders, assembly sequences
**What Happens**:
- System generates pick instructions for specific items
- Script extracts bin number from warehouse name
- Triggers assembly movement sequences

**Example Pick List Structure:**
```
Pick List ID: PICK-001
Locations:
  - Warehouse: Pick Bin 01
  - Item: White Wallet Front & Base  
  - Quantity: 1
```

### Document Submission Events

When a student clicks **"Submit"** on either document type:

1. **ERPNext Event**: `on_submit` event fires for the document
2. **Server Script Activation**: EpiBus monitors for these events
3. **Warehouse Analysis**: Script examines source/destination warehouses
4. **MODBUS Signal Generation**: Appropriate signals are written to PLC
5. **Physical Robot Action**: Robot receives commands and moves items
6. **HMI Display Update**: Panel shows active signals and robot status

### The Critical Understanding

**Every document submission in ERPNext can trigger physical robot movement.** Students aren't just updating software records - they're issuing commands to factory automation equipment.

---

## ModBus Connection - The Signal Registry

### The Central Role

The **ModBus Connection** doctype serves as the **Rosetta Stone** of the entire system. It translates between:
- ERPNext business logic (warehouse names, document events)
- MODBUS protocol (numeric addresses, boolean values)  
- PLC programming (IEC addresses like %QX1.5)
- HMI visualization (button states, status indicators)

### Connection Configuration

**Device Definition:**
- **Device Name**: "Roots Intralogistics Learning Lab"
- **Device Type**: "PLC" 
- **Host**: localhost (PLC simulation running in container)
- **Port**: 502 (standard MODBUS TCP port)
- **Enabled**: Must be checked for system to communicate

### The Signal Registry Table

The ModBus Connection contains a child table with **30+ defined signals**, each with:

| Field | Purpose | Example |
|-------|---------|---------|
| **Signal Name** | Human-readable identifier | "PICK BIN 01" |
| **Signal Type** | MODBUS data type | "Digital Output Coil" |
| **MODBUS Address** | Numeric protocol address | 11 |
| **PLC Address** | IEC 61131-3 format | "%QX1.3" |
| **Current Value** | Real-time signal state | TRUE/FALSE |

### Critical Signal Categories

#### 1. System Status Signals
Control and monitor overall PLC state:

| Signal Name | MODBUS Addr | HMI Display | Purpose |
|-------------|-------------|-------------|---------|
| `PLC_CYCLE_STOPPED` | 0 | "PLC CYCLE STOPPED" | System halt indicator |
| `PLC_CYCLE_RUNNING` | 1 | "PLC CYCLE RUNNING" | System operational |  
| `PICK_ERROR` | 2 | "PICK ERROR" | Error condition flag |

#### 2. Bin Selection Signals  
Command robot to interact with specific storage locations:

| Signal Name | MODBUS Addr | PLC Address | HMI Display |
|-------------|-------------|-------------|-------------|
| `PICK BIN 01` | 11 | %QX1.3 | "B1" button |
| `PICK BIN 02` | 12 | %QX1.4 | "B2" button |
| `PICK BIN 03` | 13 | %QX1.5 | "B3" button |
| `PICK BIN 04` | 14 | %QX1.6 | "B4" button |
| ... | ... | ... | ... |
| `PICK BIN 12` | 22+ | %QX2.6+ | "B12" button |

#### 3. Operation Status Signals
Provide feedback on robot operation progress:

| Signal Name | MODBUS Addr | HMI Display |
|-------------|-------------|-------------|
| `PICK_TO_RECEIVING_IN_PROCESS` | 3 | "PICK TO RECEIVING IN PROC" |
| `PICK_TO_RECEIVING_COMPLETE` | 4 | "PICK TO RECEIVING COMPLETE" |
| `PICK_TO_PICK&PACK_IN_PROCESS` | 5 | "PICK TO PICK&PACK IN PROC" |
| `PICK_TO_PICK&PACK_COMPLETE` | 6 | "PICK TO PICK&PACK COMPLETE" |
| `PICK_TO_STORAGE_IN_PROCESS` | 7 | "PICK TO STORAGE IN PROCESS" |
| `PICK_TO_STORAGE_COMPLETE` | 8 | "PICK TO STORAGE COMPLETE" |

#### 4. Movement Command Signals
Direct robot movement between stations:

| Signal Name | HMI Display | Purpose |
|-------------|-------------|---------|
| `TO_RECEIVING_STA_1` | "TO RECEIVING STATION" | Move item to receiving area |
| `FROM_RECEIVING` | "FROM RECEIVING STATION" | Pick item from receiving |
| `TO_ASSEMBLY_STA_1` | "TO PICK&PACK STATION" | Move item to assembly |
| `FROM_ASSEMBLY` | "FROM PICK&PACK STATION" | Pick item from assembly |

### The Translation Process

When a server script executes:
```python
device.write_signal("PICK BIN 03", True)
```

The ModBus Connection:
1. **Looks up** signal "PICK BIN 03" in its registry
2. **Finds** MODBUS address 13, PLC address %QX1.5  
3. **Writes** boolean TRUE to MODBUS address 13
4. **PLC receives** signal at %QX1.5 and updates internal state
5. **HMI displays** "B3" button lighting up red
6. **Robot** physically moves to storage bin #3

This makes the ModBus Connection the **central nervous system** connecting ERPNext business logic to physical automation.

---

## Server Script Logic

### Two Different Approaches

The EpiBus system uses **two different approaches** for translating ERPNext document events into robot commands. Understanding both is crucial for students.

### Approach A: Generic Warehouse Trigger Script

**File**: `trigger_modbus_signal_script.py`
**Purpose**: General-purpose script that can work with any warehouse
**Trigger**: Stock Entry document events

#### How It Works:
```python
# Get the target warehouse from Modbus Action parameters
target_warehouse = modbus_context['params'].get('Warehouse')

# Check if the submitted document has items from this warehouse
warehouse_items = [
    item for item in modbus_context['target'].items 
    if item.s_warehouse == target_warehouse  # s_warehouse = source warehouse
]

if warehouse_items:
    # Toggle the associated signal
    modbus_context['signal'].toggle_location_pin()
```

#### Key Characteristics:
- **Flexible**: Can be configured for any warehouse through Modbus Action parameters
- **Simple**: Just toggles a signal when items move FROM the configured warehouse
- **Generic**: Uses `toggle_location_pin()` method rather than specific signal writes

#### Usage Pattern:
1. Student creates Stock Entry moving items FROM "Storage Bin 1" 
2. Script detects items with `s_warehouse = "Storage Bin 1"`
3. Script toggles the signal associated with Storage Bin 1
4. Robot receives signal and performs configured action

### Approach B: Specific Movement Scripts

**File**: Server scripts in `fixtures/server_script.json`
**Purpose**: Hardcoded robot movement sequences
**Trigger**: Specific movement types (staging to receiving, assembly operations, etc.)

#### Pattern 1: "Staging to Receiving" Script
```python
# Get bin number from parameters
bin_number = params.get('bin_number')  # e.g., "03"

# Check if PLC is running
cycle_running = device.read_signal("CYCLE_RUNNING")
if not cycle_running:
    frappe.throw("PLC cycle not running")

# Write TWO signals for movement sequence
device.write_signal(f"PICK_BIN_{bin_number}", True)    # e.g., "PICK_BIN_03" 
device.write_signal("TO_RECEIVING_STA_1", True)        # Destination signal
```

#### Pattern 2: "Receiving to Staging" Script  
```python
bin_number = params.get('bin_number')

# Write TWO signals for reverse movement
device.write_signal(f"PICK_BIN_{bin_number}", True)    # Pick from bin
device.write_signal("FROM_RECEIVING", True)            # Source signal
```

#### Pattern 3: "Pick List to Assembly" Script
```python
# Extract bin number from Pick List warehouse name
pick_list = frappe.get_doc("Pick List", frappe.form_dict.doc)
warehouse = pick_list.locations[0].warehouse
bin_number = warehouse.replace("Pick Bin ", "")        # "Pick Bin 01" → "01"

# Write assembly movement signals  
device.write_signal(f"PICK_BIN_{bin_number}", True)    # e.g., "PICK_BIN_01"
device.write_signal("TO_ASSEMBLY_STA_1", True)         # Assembly destination
```

### Key Differences Between Approaches

| Aspect | Approach A (Generic) | Approach B (Specific) |
|--------|---------------------|----------------------|
| **Flexibility** | Configurable through parameters | Hardcoded movement patterns |
| **Signal Method** | `signal.toggle_location_pin()` | Direct `device.write_signal()` calls |
| **Signal Count** | Single signal toggle | Multiple coordinated signals |
| **Robot Action** | Simple on/off command | Complex movement sequences |
| **Configuration** | Through Modbus Action setup | Embedded in script code |

### Movement Signal Patterns

All Approach B scripts follow the **two-signal pattern**:

1. **Bin Selection Signal**: `PICK_BIN_{number}` - tells robot which storage location
2. **Direction Signal**: `TO_RECEIVING_STA_1`, `FROM_ASSEMBLY`, etc. - tells robot where to move

**Examples:**
- Moving from Storage Bin 3 to Receiving: `PICK_BIN_03=TRUE` + `TO_RECEIVING_STA_1=TRUE`
- Moving from Assembly to Storage Bin 5: `PICK_BIN_05=TRUE` + `FROM_ASSEMBLY=TRUE`
- Pick List for Assembly from Bin 1: `PICK_BIN_01=TRUE` + `TO_ASSEMBLY_STA_1=TRUE`

### Pre-Flight Safety Checks

All Approach B scripts include safety verification:
```python
# Always check if PLC cycle is running
cycle_running = device.read_signal("CYCLE_RUNNING") 
if not cycle_running:
    frappe.throw("PLC cycle not running")
```

This prevents robot commands when the system is stopped, avoiding potential hardware issues.

### Status Monitoring Script

The **"Monitor Sequence"** script provides operation feedback:
```python
# Check for error conditions
error_state = device.read_signal("PICK_ERROR")
if error_state:
    frappe.throw("Pick error detected")

# Read completion status  
to_receiving = device.read_signal("PICK_TO_RECEIVING_COMPLETE")
to_staging = device.read_signal("PICK_TO_STAGING_COMPLETE") 
to_assembly = device.read_signal("PICK_TO_ASSEMBLY_COMPLETE")

# Report current operation status
if to_receiving:
    status = "Staging to receiving complete"
elif to_staging:
    status = "Movement to staging complete"
elif to_assembly:
    status = "Staging to assembly complete"
else:
    status = "Sequence in progress"
```

This allows the system to track robot operation progress and notify users of completion.

---

## Complete Signal Flow Mapping

### The ERPNext → Robot Command Chain

Understanding how ERPNext documents translate to physical robot movements requires following the complete signal chain:

**ERPNext Document → Server Script → MODBUS Signals → PLC → HMI → Robot Action**

### Stock Entry Movement Examples

#### Example 1: Storage Bin to Receiving Area

**Student Action:**
```
Stock Entry Document:
Source Warehouse: Storage Bin 3  
Target Warehouse: Receiving Area
Item: Ball Chain Keychain
Quantity: 2
```

**Signal Flow:**
1. **Document Submit**: Student clicks "Submit" on Stock Entry
2. **Server Script**: "Staging to Receiving" script triggers  
3. **Signal Generation**: 
   - `device.write_signal("PICK_BIN_03", True)`
   - `device.write_signal("TO_RECEIVING_STA_1", True)`
4. **MODBUS Protocol**: 
   - Address 13 (`PICK_BIN_03`) = TRUE
   - Address ?? (`TO_RECEIVING_STA_1`) = TRUE  
5. **HMI Display**: 
   - "B3" button lights red
   - "TO RECEIVING STATION" indicator activates
6. **Robot Action**: Physical movement from storage bin #3 to receiving station

#### Example 2: Pick List for Assembly

**Student Action:**
```
Pick List Document:
Pick List ID: PICK-001
Location: Pick Bin 01
Item: White Wallet Front & Base
Quantity: 1
```

**Signal Flow:**
1. **Document Submit**: Student submits Pick List
2. **Server Script**: "Pick List to Assembly" script triggers
3. **Warehouse Parsing**: Script extracts "01" from "Pick Bin 01"
4. **Signal Generation**:
   - `device.write_signal("PICK_BIN_01", True)`  
   - `device.write_signal("TO_ASSEMBLY_STA_1", True)`
5. **MODBUS Protocol**:
   - Address 11 (`PICK_BIN_01`) = TRUE
   - Address ?? (`TO_ASSEMBLY_STA_1`) = TRUE
6. **HMI Display**:
   - "B1" button lights red  
   - "TO PICK&PACK STATION" indicator activates
7. **Robot Action**: Physical movement from bin #1 to assembly station

### ERPNext Warehouse to Signal Mapping

| ERPNext Warehouse | Script Logic | MODBUS Signals | HMI Display |
|------------------|--------------|-----------------|-------------|
| **Storage Bin 1** | Extract "1" → "01" | `PICK_BIN_01=TRUE` | "B1" lights red |
| **Storage Bin 2** | Extract "2" → "02" | `PICK_BIN_02=TRUE` | "B2" lights red |  
| **Storage Bin 3** | Extract "3" → "03" | `PICK_BIN_03=TRUE` | "B3" lights red |
| **Receiving Area** | Destination target | `TO_RECEIVING_STA_1=TRUE` | "TO RECEIVING STATION" |
| **Pick and Pack Area** | Assembly target | `TO_ASSEMBLY_STA_1=TRUE` | "TO PICK&PACK STATION" |

### Movement Direction Logic

The system uses **source + destination** signal combinations:

**From Storage to Receiving:**
- Source: `PICK_BIN_{number}=TRUE` (which storage bin)
- Destination: `TO_RECEIVING_STA_1=TRUE` (receiving station)  
- Robot: Pick from bin, move to receiving

**From Receiving to Storage:**  
- Source: `FROM_RECEIVING=TRUE` (receiving station)
- Destination: `PICK_BIN_{number}=TRUE` (which storage bin)
- Robot: Pick from receiving, move to bin

**From Storage to Assembly:**
- Source: `PICK_BIN_{number}=TRUE` (which storage bin)
- Destination: `TO_ASSEMBLY_STA_1=TRUE` (assembly station)
- Robot: Pick from bin, move to assembly

### Status Feedback Loop

The system provides real-time status through completion signals:

| Operation | In-Process Signal | Completion Signal | HMI Indicator |
|-----------|------------------|-------------------|---------------|
| **To Receiving** | `PICK_TO_RECEIVING_IN_PROCESS` | `PICK_TO_RECEIVING_COMPLETE` | "PICK TO RECEIVING COMPLETE" |
| **To Assembly** | `PICK_TO_ASSEMBLY_IN_PROCESS` | `PICK_TO_ASSEMBLY_COMPLETE` | "PICK TO PICK&PACK COMPLETE" |
| **To Storage** | `PICK_TO_STORAGE_IN_PROCESS` | `PICK_TO_STORAGE_COMPLETE` | "PICK TO STORAGE COMPLETE" |

This allows students to track robot operation progress and know when movements are finished.

---

## Workflow Examples

### Example 1: Simple Storage Transfer

**Scenario**: Student needs to move 3 Ball Chain Keychains from Storage Bin 2 to Receiving Area

#### Step 1: Create Stock Entry
```
ERPNext Navigation: Stock → Stock Entry → New

Fields:
- Stock Entry Type: Material Transfer
- Source Warehouse: Storage Bin 2  
- Target Warehouse: Receiving Area
- Item: Ball Chain Keychain
- Quantity: 3
```

#### Step 2: Document Submission  
Student clicks **"Submit"** button

**What Happens Behind the Scenes:**
1. ERPNext fires `on_submit` event for Stock Entry document
2. EpiBus server script "Staging to Receiving" detects movement pattern
3. Script extracts bin number: "Storage Bin 2" → "02"
4. Script verifies PLC is running: `device.read_signal("CYCLE_RUNNING")`

#### Step 3: Robot Command Generation
```python
# Server script executes:
device.write_signal("PICK_BIN_02", True)    # Target storage bin #2
device.write_signal("TO_RECEIVING_STA_1", True)  # Destination: receiving
```

#### Step 4: Physical System Response  
**HMI Panel Changes:**
- "B2" button lights up red (bin selection active)
- "TO RECEIVING STATION" indicator lights red (destination active)  
- Robot status shows "MOVE IN PROC" (operation starting)

**Robot Action:**
- Robot physically moves to Storage Bin 2  
- Robot picks up items from bin #2
- Robot transports items to Receiving Area station
- Robot places items at receiving station

#### Step 5: Operation Completion
**Status Signals Update:**
- `PICK_TO_RECEIVING_IN_PROCESS` becomes TRUE (operation active)
- `PICK_TO_RECEIVING_COMPLETE` becomes TRUE (operation finished)

**HMI Panel Shows:**
- "PICK TO RECEIVING COMPLETE" indicator lights green
- Robot status returns to idle/ready state

**ERPNext Inventory Update:**
- Storage Bin 2: Ball Chain Keychain quantity decreases by 3
- Receiving Area: Ball Chain Keychain quantity increases by 3

### Example 2: Manufacturing Pick List

**Scenario**: Student needs to pick items for assembly work order

#### Step 1: Create Pick List  
```
ERPNext Navigation: Manufacturing → Pick List → New

Work Order: WO-001 (White Wallet Assembly)
Auto-Generated Locations:
- Pick Bin 01: White Wallet Front & Base (Qty: 1)
- Pick Bin 03: Ball Chain (Qty: 1) 
- Pick Bin 05: Key Ring (Qty: 1)
```

#### Step 2: Process First Pick Location
Student clicks **"Submit"** on Pick List

**Server Script Logic:**
```python
# Pick List to Assembly script executes:
pick_list = frappe.get_doc("Pick List", document_id)
warehouse = pick_list.locations[0].warehouse  # "Pick Bin 01"
bin_number = warehouse.replace("Pick Bin ", "")  # "01"

# Generate robot commands for first location:
device.write_signal("PICK_BIN_01", True)       # Pick from bin #1
device.write_signal("TO_ASSEMBLY_STA_1", True)  # Destination: assembly
```

#### Step 3: Multi-Location Processing
For each location in the Pick List, the system:
1. Extracts bin number from warehouse name
2. Commands robot to that specific bin
3. Directs robot to assembly station  
4. Waits for completion before next pick

**Sequential Robot Actions:**
1. **First Pick**: Bin 01 → Assembly (White Wallet Front & Base)
2. **Second Pick**: Bin 03 → Assembly (Ball Chain)  
3. **Third Pick**: Bin 05 → Assembly (Key Ring)

#### Step 4: Assembly Station Ready
**Result**: All required components are now at the assembly station, ready for manufacturing process.

### Example 3: Error Handling

**Scenario**: Student attempts movement when PLC is stopped

#### The Problem
Student creates Stock Entry but PLC system is not running.

#### Server Script Safety Check
```python
# All movement scripts include this check:
cycle_running = device.read_signal("CYCLE_RUNNING")
if not cycle_running:
    frappe.throw("PLC cycle not running")
```

#### User Experience  
- **ERPNext Error**: "PLC cycle not running" message appears
- **HMI Status**: "PLC CYCLE STOPPED" indicator shows red
- **Robot Action**: No movement occurs (safety protected)

#### Resolution Steps
1. Check HMI panel for system status
2. Restart PLC cycle if safe to do so
3. Retry Stock Entry submission
4. Verify robot movement occurs

### Example 4: Status Monitoring

**Scenario**: Student wants to track robot operation progress

#### Using Monitor Sequence Script
```python
# Monitor script reads current operation status:
to_receiving = device.read_signal("PICK_TO_RECEIVING_COMPLETE")
to_assembly = device.read_signal("PICK_TO_ASSEMBLY_COMPLETE")
to_storage = device.read_signal("PICK_TO_STORAGE_COMPLETE")

if to_receiving:
    status = "Staging to receiving complete"
elif to_assembly:
    status = "Staging to assembly complete"  
else:
    status = "Sequence in progress"
```

#### Student Monitoring Workflow
1. **Submit** Stock Entry/Pick List
2. **Check HMI** for signal activation (B1-B12, station indicators)
3. **Watch Robot** physically perform movement
4. **Verify Completion** when HMI shows "COMPLETE" status
5. **Confirm Inventory** updated in ERPNext

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Robot Doesn't Move After Document Submission

**Symptoms:**
- Stock Entry/Pick List submitted successfully in ERPNext
- No robot movement observed
- HMI panel shows no signal changes

**Troubleshooting Steps:**

1. **Check PLC Status**
   - Look at HMI panel for "PLC CYCLE RUNNING" indicator
   - If showing "PLC CYCLE STOPPED", restart PLC cycle
   - Verify system is not in error state

2. **Verify MODBUS Connection**
   - Check ModBus Connection document is enabled
   - Verify host (localhost) and port (502) settings
   - Test connection from ERPNext: ModBus Connection → Test Connection

3. **Check Server Script Assignment**
   - Verify Modbus Action is configured for the warehouse involved
   - Check server script is linked and enabled
   - Review script parameters match warehouse names

4. **Review Document Submission**  
   - Confirm document status is "Submitted" (not Draft or Cancelled)
   - Check source warehouse matches configured triggers
   - Verify item quantities are greater than zero

#### Issue 2: Wrong Robot Movement

**Symptoms:**
- Robot moves to incorrect bin or station
- HMI shows different signals than expected
- Wrong items picked or delivered

**Troubleshooting Steps:**

1. **Verify Warehouse Name Mapping**
   - Check exact spelling of warehouse names in Stock Entry
   - Confirm "Storage Bin 3" maps to "PICK_BIN_03" signal
   - Review bin number extraction logic in scripts

2. **Check Signal Configuration**  
   - Open ModBus Connection document
   - Verify signal names match script calls exactly
   - Check MODBUS addresses are sequential and correct

3. **Review Server Script Logic**
   - Examine bin number parsing: `warehouse.replace("Pick Bin ", "")`
   - Verify signal writing calls: `device.write_signal("PICK_BIN_03", True)`
   - Check movement direction signals are correct

#### Issue 3: HMI Panel Shows Signals But Robot Doesn't Move

**Symptoms:**  
- HMI panel correctly displays activated signals (B1-B12, stations)
- Robot remains stationary
- No error indicators on HMI

**Troubleshooting Steps:**

1. **Check Robot System Status**
   - Verify robot is powered and initialized
   - Check robot is not in manual mode
   - Confirm robot is connected to PLC system

2. **Verify PLC-to-Robot Communication**
   - Check physical connections between PLC and robot controller
   - Review robot program is loaded and running  
   - Verify robot safety systems are not active

3. **Review Signal Timing**
   - Some robots require signals to be held for minimum duration
   - Check if signals are being reset too quickly
   - Verify robot has completed previous operation before new command

#### Issue 4: Inventory Counts Don't Match Physical Reality

**Symptoms:**
- ERPNext shows different quantities than physically present
- Stock levels incorrect after robot movements
- Discrepancies between bins/stations

**Troubleshooting Steps:**

1. **Verify Document Completion**
   - Check all Stock Entries are properly submitted
   - Confirm no documents stuck in Draft status
   - Review document dates and sequences

2. **Check Robot Operation Completion**
   - Verify HMI shows "COMPLETE" status for all movements
   - Confirm robot actually placed items at destination
   - Check for dropped or misplaced items

3. **Perform Physical Stock Reconciliation**
   - Count actual items in each bin/station
   - Create Stock Reconciliation document in ERPNext
   - Update system quantities to match reality

4. **Review Error Recovery**
   - Check for any "PICK_ERROR" signals that occurred
   - Verify error conditions were properly resolved
   - Confirm robot recovered to known good state

#### Issue 5: MODBUS Communication Errors

**Symptoms:**
- "Connection timeout" or "MODBUS error" messages
- Intermittent robot responses
- HMI panel showing outdated information

**Troubleshooting Steps:**

1. **Check Network Connectivity**
   - Verify MODBUS TCP connection: `telnet localhost 502`
   - Check PLC simulation container is running
   - Review Docker network configuration

2. **Verify MODBUS Settings**
   - Confirm MODBUS addresses don't conflict
   - Check signal types match PLC configuration
   - Review timeout and retry settings

3. **Check System Resources**
   - Verify sufficient CPU/memory for PLC simulation
   - Check for other processes using port 502
   - Review Docker container health status

### Prevention Best Practices

#### For Students:
1. **Always verify PLC status** before submitting documents
2. **Check HMI panel** for signal confirmation after submission  
3. **Wait for completion signals** before creating new movements
4. **Use correct warehouse names** exactly as configured
5. **Monitor robot physically** to confirm expected actions

#### For System Administrators:
1. **Regularly backup** MODBUS Connection signal configurations
2. **Test server scripts** after any warehouse changes
3. **Monitor PLC connection** health and performance
4. **Keep signal documentation** synchronized with physical system
5. **Implement error logging** for troubleshooting support

This troubleshooting guide helps maintain reliable operation of the ERPNext-to-robot automation system.