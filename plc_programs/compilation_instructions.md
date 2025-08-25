# Traffic Light Controller - Compilation and Testing Instructions

## OpenPLC Compilation Steps

### Step 1: Access OpenPLC Web Interface

1. Start the lab environment:
   ```bash
   cd /Volumes/Berthold/Code/active/intralogisticsai
   ./deploy.sh lab
   ```

2. Get OpenPLC port and access web interface:
   ```bash
   ./get-openplc-port.sh
   ```
   Open `http://localhost:[port]` in your browser

3. Login with default credentials:
   - Username: `openplc`
   - Password: `openplc`

### Step 2: Upload and Compile Program

1. Navigate to **Programs** → **ST Editor**

2. Create new program:
   - Click **"New Program"**
   - Program Name: `TrafficLightController`
   - Description: `4-Way Intersection Traffic Light Controller`

3. Copy the complete ST code from `traffic_light_controller.st`

4. **IMPORTANT**: Verify OpenPLC compliance:
   - No comments on variable declaration lines
   - Proper VAR section separation
   - All timer functions use standard IEC 61131-3 syntax
   - CASE statements properly structured

5. Click **"Compile"** - should show **"Compilation successful"**

### Step 3: Hardware Configuration

1. Navigate to **Hardware** → **Blank Programs**

2. Select **"traffic_light_controller.st"** from dropdown

3. Configure I/O mapping:

   **Digital Inputs:**
   ```
   %IX0.0 ← Location: 0  (Pedestrian NS Button)
   %IX0.1 ← Location: 1  (Pedestrian EW Button) 
   %IX0.2 ← Location: 2  (Emergency Override)
   %IX0.3 ← Location: 3  (System Enable)
   %IX0.4 ← Location: 4  (Manual Reset)
   ```

   **Digital Outputs:**
   ```
   %QX0.0 → Location: 0  (NS Red Light)
   %QX0.1 → Location: 1  (NS Yellow Light)
   %QX0.2 → Location: 2  (NS Green Light)
   %QX0.3 → Location: 3  (EW Red Light)
   %QX0.4 → Location: 4  (EW Yellow Light)
   %QX0.5 → Location: 5  (EW Green Light)
   %QX0.6 → Location: 6  (Pedestrian NS Walk)
   %QX0.7 → Location: 7  (Pedestrian NS Don't Walk)
   %QX1.0 → Location: 8  (Pedestrian EW Walk)
   %QX1.1 → Location: 9  (Pedestrian EW Don't Walk)
   %QX1.2 → Location: 10 (System Running)
   %QX1.3 → Location: 11 (Emergency Mode)
   %QX1.4 → Location: 12 (Fault Status)
   ```

4. Click **"Save Configuration"**

### Step 4: Start PLC Runtime

1. Navigate to **Runtime** → **Start PLC**

2. Click **"Start PLC"** button

3. Verify status shows **"PLC is running"**

## Testing Procedures

### Test 1: Basic Operation Verification

1. **Monitor Tab**: Navigate to **Monitoring** → **Monitor Variables**

2. **Initial State Check**:
   - `system_state` should be `1` (NS_GREEN)
   - `ns_green_light` should be `TRUE`
   - `ew_red_light` should be `TRUE`
   - `system_running` should be `TRUE`

3. **Timing Verification**:
   - Wait 30 seconds, state should change to `2` (NS_YELLOW)
   - Wait 5 seconds, state should change to `3` (EW_GREEN)
   - Continue monitoring full cycle

### Test 2: Pedestrian Button Testing

1. **Setup**: Set `pedestrian_ns_button` to `TRUE` during NS_GREEN phase

2. **Expected Behavior**:
   - At end of NS_GREEN, should transition to `STATE_PED_EW_WALK` (7)
   - `ped_ew_walk` should become `TRUE` for 15 seconds
   - Then `STATE_PED_EW_CLEAR` (8) for 10 seconds
   - Finally transition to `STATE_NS_GREEN` (1)

3. **Verify Counters**: `ped_ew_cycles` should increment

### Test 3: Emergency Override Testing

1. **Activation**: Set `emergency_override` to `TRUE`

2. **Expected Behavior**:
   - `system_state` changes to `9` (EMERGENCY)
   - `emergency_mode` becomes `TRUE`
   - All lights flash red at 500ms intervals
   - `emergency_activations` counter increments

3. **Deactivation**: Set `emergency_override` to `FALSE`
   - Should return to `STATE_NS_GREEN` (1)
   - Normal operation resumes

### Test 4: MODBUS Communication Testing

Using Python with pymodbus library:

```python
from pymodbus.client import ModbusTcpClient

# Connect to OpenPLC
client = ModbusTcpClient('localhost', port=502)
client.connect()

# Read current state
result = client.read_holding_registers(0, 1)  # Read system_state
print(f"System State: {result.registers[0]}")

# Read traffic light status
coils = client.read_coils(0, 13)  # Read all outputs
print(f"NS Red: {coils.bits[0]}")
print(f"NS Yellow: {coils.bits[1]}")
print(f"NS Green: {coils.bits[2]}")

# Simulate pedestrian button press
client.write_coil(0, True)  # Press NS pedestrian button
time.sleep(1)
client.write_coil(0, False) # Release button

# Read statistics
stats = client.read_holding_registers(1, 8)
print(f"NS Green Cycles: {stats.registers[0]}")
print(f"Total Runtime: {stats.registers[5]} seconds")

client.close()
```

### Test 5: EpiBus Integration Testing

1. **Setup EpiBus Signals** in Frappe:
   ```python
   # Create traffic light signals
   signals = [
       {"signal_name": "traffic_ns_red", "modbus_address": "0.0"},
       {"signal_name": "traffic_state", "modbus_address": "0"},
       {"signal_name": "ped_button_ns", "modbus_address": "0.0"}
   ]
   ```

2. **Test Signal Reading**:
   ```python
   import frappe
   from epibus.api.plc import read_signal
   
   # Read current traffic light state
   state = read_signal("traffic_state")
   print(f"Current state: {state}")
   
   # Read light status
   ns_red = read_signal("traffic_ns_red")
   print(f"NS Red Light: {ns_red}")
   ```

3. **Test Signal Writing**:
   ```python
   from epibus.api.plc import write_signal
   
   # Simulate emergency button
   write_signal("emergency_override", True)
   time.sleep(5)
   write_signal("emergency_override", False)
   ```

## Common Compilation Issues and Solutions

### Issue 1: Timer Function Errors
**Error**: `TON function not recognized`
**Solution**: Ensure timer declarations use proper syntax:
```st
timer_main : TON;
timer_main(IN:=TRUE, PT:=T#30000MS);
```

### Issue 2: CASE Statement Errors
**Error**: `Invalid CASE syntax`
**Solution**: Ensure proper CASE structure:
```st
CASE system_state OF
    1: (* State logic *)
    2: (* State logic *)
    ELSE
        (* Default case *)
END_CASE;
```

### Issue 3: Variable Declaration Errors
**Error**: `Variable not declared`
**Solution**: Ensure all variables are in proper VAR sections:
- `VAR` for internal variables
- `VAR_INPUT` for inputs
- `VAR_OUTPUT` for outputs
- `VAR_IN_OUT` for bidirectional

### Issue 4: Time Constant Errors
**Error**: `Invalid time constant`
**Solution**: Use proper TIME format: `T#30000MS` or `T#30S`

## Performance Monitoring

Monitor these key metrics during operation:

1. **Cycle Times**: Verify timing matches configuration
2. **Memory Usage**: Check PLC memory consumption
3. **Scan Time**: Should be < 10ms for responsive operation
4. **Communication Latency**: MODBUS response time < 100ms
5. **Error Counters**: Should remain at zero during normal operation

## Safety Considerations

1. **Emergency Override**: Always test emergency function first
2. **Fail-Safe Operation**: Verify system defaults to safe state on power loss
3. **Input Validation**: Test with invalid input combinations
4. **Timing Verification**: Ensure minimum/maximum timing constraints
5. **Communication Fault**: Test behavior when MODBUS communication fails

## Integration with Physical Hardware

When connecting to real traffic light hardware:

1. **Output Drivers**: Use appropriate relay/contactor modules
2. **Input Isolation**: Implement proper input isolation circuits
3. **Power Supply**: Ensure adequate 24VDC supply for I/O modules
4. **Safety Circuits**: Implement hardware emergency stop circuits
5. **Status Monitoring**: Add lamp failure detection circuits

This traffic light controller provides a complete, production-ready solution for intersection control with full MODBUS integration capabilities.