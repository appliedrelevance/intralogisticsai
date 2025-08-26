(*
Simple CODESYS Structured Text Program
Intralogistics Learning Lab - Basic MODBUS TCP Server
Provides basic I/O simulation compatible with ERP integration
*)

PROGRAM PLC_PRG
VAR
    (* Conveyor System Variables *)
    Conveyor1_Run: BOOL := FALSE;           (* Address 40001 *)
    Conveyor1_Speed: INT := 0;              (* Address 40002 *)
    Conveyor1_Status: BOOL := FALSE;        (* Address 40003 *)
    
    Conveyor2_Run: BOOL := FALSE;           (* Address 40004 *)
    Conveyor2_Speed: INT := 0;              (* Address 40005 *)
    Conveyor2_Status: BOOL := FALSE;        (* Address 40006 *)
    
    (* Storage Robot Variables *)
    Robot_Position_X: INT := 0;             (* Address 40007 *)
    Robot_Position_Y: INT := 0;             (* Address 40008 *)
    Robot_Position_Z: INT := 0;             (* Address 40009 *)
    Robot_Gripper_Open: BOOL := FALSE;      (* Address 40010 *)
    Robot_Busy: BOOL := FALSE;              (* Address 40011 *)
    
    (* RFID System Variables *)
    RFID_Station1_Active: BOOL := FALSE;    (* Address 40012 *)
    RFID_Station1_TagID: DWORD := 0;        (* Address 40013-40014 *)
    RFID_Station2_Active: BOOL := FALSE;    (* Address 40015 *)
    RFID_Station2_TagID: DWORD := 0;        (* Address 40016-40017 *)
    
    (* Safety System *)
    Emergency_Stop: BOOL := FALSE;          (* Address 40018 *)
    Safety_OK: BOOL := TRUE;                (* Address 40019 *)
    System_Ready: BOOL := FALSE;            (* Address 40020 *)
    
    (* Simulation Timers *)
    Cycle_Timer: TIME;
    Robot_Move_Timer: TIME;
    
    (* Internal simulation variables *)
    Simulation_Active: BOOL := TRUE;
    Cycle_Count: INT := 0;
END_VAR

(* Main Program Logic *)

(* System Ready Logic *)
System_Ready := Safety_OK AND NOT Emergency_Stop;

(* Conveyor Control Logic *)
IF System_Ready THEN
    IF Conveyor1_Run THEN
        Conveyor1_Status := TRUE;
        IF Conveyor1_Speed = 0 THEN
            Conveyor1_Speed := 50;  (* Default speed *)
        END_IF
    ELSE
        Conveyor1_Status := FALSE;
        Conveyor1_Speed := 0;
    END_IF
    
    IF Conveyor2_Run THEN
        Conveyor2_Status := TRUE;
        IF Conveyor2_Speed = 0 THEN
            Conveyor2_Speed := 50;  (* Default speed *)
        END_IF
    ELSE
        Conveyor2_Status := FALSE;
        Conveyor2_Speed := 0;
    END_IF
ELSE
    (* Emergency stop - halt all conveyors *)
    Conveyor1_Status := FALSE;
    Conveyor1_Speed := 0;
    Conveyor2_Status := FALSE;
    Conveyor2_Speed := 0;
END_IF

(* Robot Simulation Logic *)
IF System_Ready AND NOT Robot_Busy THEN
    (* Simple position simulation *)
    IF Cycle_Count MOD 100 = 0 THEN
        Robot_Position_X := Robot_Position_X + 10;
        IF Robot_Position_X > 1000 THEN
            Robot_Position_X := 0;
        END_IF
    END_IF
    
    IF Cycle_Count MOD 150 = 0 THEN
        Robot_Position_Y := Robot_Position_Y + 5;
        IF Robot_Position_Y > 500 THEN
            Robot_Position_Y := 0;
        END_IF
    END_IF
    
    (* Gripper simulation *)
    IF Cycle_Count MOD 200 = 0 THEN
        Robot_Gripper_Open := NOT Robot_Gripper_Open;
    END_IF
END_IF

(* RFID Simulation Logic *)
IF System_Ready THEN
    IF Cycle_Count MOD 300 = 0 THEN
        RFID_Station1_Active := NOT RFID_Station1_Active;
        IF RFID_Station1_Active THEN
            RFID_Station1_TagID := RFID_Station1_TagID + 1;
            IF RFID_Station1_TagID = 0 THEN
                RFID_Station1_TagID := 1000;  (* Start from 1000 *)
            END_IF
        END_IF
    END_IF
    
    IF Cycle_Count MOD 350 = 0 THEN
        RFID_Station2_Active := NOT RFID_Station2_Active;
        IF RFID_Station2_Active THEN
            RFID_Station2_TagID := RFID_Station2_TagID + 1;
            IF RFID_Station2_TagID = 0 THEN
                RFID_Station2_TagID := 2000;  (* Start from 2000 *)
            END_IF
        END_IF
    END_IF
END_IF

(* Cycle counter for simulation timing *)
Cycle_Count := Cycle_Count + 1;
IF Cycle_Count > 32000 THEN
    Cycle_Count := 0;
END_IF

END_PROGRAM

(*
MODBUS TCP Server Configuration:
- Port: 502
- Unit ID: 1
- Function Codes: 3 (Read Holding Registers), 6 (Write Single Register), 16 (Write Multiple Registers)

Register Map:
40001: Conveyor1_Run (BOOL)
40002: Conveyor1_Speed (INT)
40003: Conveyor1_Status (BOOL)
40004: Conveyor2_Run (BOOL)
40005: Conveyor2_Speed (INT)
40006: Conveyor2_Status (BOOL)
40007: Robot_Position_X (INT)
40008: Robot_Position_Y (INT)
40009: Robot_Position_Z (INT)
40010: Robot_Gripper_Open (BOOL)
40011: Robot_Busy (BOOL)
40012: RFID_Station1_Active (BOOL)
40013-40014: RFID_Station1_TagID (DWORD)
40015: RFID_Station2_Active (BOOL)
40016-40017: RFID_Station2_TagID (DWORD)
40018: Emergency_Stop (BOOL)
40019: Safety_OK (BOOL)
40020: System_Ready (BOOL)
*)