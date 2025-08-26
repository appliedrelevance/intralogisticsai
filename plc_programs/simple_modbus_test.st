PROGRAM PLC_PRG
VAR
    ModbusSlaveRequestHandler_TCP: ModbusSlaveRequestHandler_TCP;
    ServerStatus: BOOL := FALSE;
    TestCounter: UINT := 0;
    
    (* Test coils for bin selection *)
    Bin01_Selected AT %QX100.0: BOOL;
    Bin02_Selected AT %QX100.1: BOOL;
    Bin03_Selected AT %QX100.2: BOOL;
    Bin04_Selected AT %QX100.3: BOOL;
    
    (* Test registers *)
    SystemStatus AT %QW200: UINT;
    RobotPosition AT %QW201: UINT;
END_VAR

(* Main program loop *)
TestCounter := TestCounter + 1;
IF TestCounter > 1000 THEN
    TestCounter := 0;
END_IF

(* Update test registers *)
SystemStatus := 1; (* System running *)
RobotPosition := TestCounter;

(* Simple MODBUS TCP server *)
ModbusSlaveRequestHandler_TCP(
    Enable := TRUE,
    Address := '0.0.0.0',
    Port := 502,
    pMemoryArea := ADR(%MB0),
    uiMemoryAreaSize := 1000
);

ServerStatus := ModbusSlaveRequestHandler_TCP.xReady;