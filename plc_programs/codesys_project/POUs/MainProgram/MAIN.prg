PROGRAM MAIN
VAR
    (* System control variables *)
    System_Initialize       : BOOL := TRUE;     // System initialization flag
    System_Enable           : BOOL := FALSE;    // System enable
    System_Reset            : BOOL := FALSE;    // System reset
    Manual_Mode_Request     : BOOL := FALSE;    // Manual mode request
    
    (* Function block instances *)
    FB_Safety               : FB_SafetySystem;          // Safety system
    FB_Conveyors            : FB_ConveyorSystem;        // Conveyor system
    FB_Robot                : FB_StorageRobot;          // Storage robot
    FB_PickControl          : FB_PickOperationControl;  // Pick operation control
    FB_RFID                 : FB_RFIDSystem;            // RFID system
    FB_Beacons              : FB_BeaconControl;         // Beacon control
    
    (* Robot data structure *)
    Robot_Data              : DUT_RobotData;            // Robot data
    
    (* System status variables *)
    System_Ready            : BOOL;                     // System ready for operation
    All_Systems_OK          : BOOL;                     // All systems OK
    Any_System_Error        : BOOL;                     // Any system error
    
    (* Timing variables *)
    Cycle_Counter           : DINT := 0;                // Main cycle counter
    Uptime_Counter          : INT := 0;                 // Uptime counter
    Heartbeat_Counter       : INT := 0;                 // Heartbeat counter
    
    (* HMI interface variables *)
    HMI_System_Start        : BOOL := FALSE;            // HMI start command
    HMI_System_Stop         : BOOL := FALSE;            // HMI stop command
    HMI_System_Reset        : BOOL := FALSE;            // HMI reset command
    HMI_Manual_Mode         : BOOL := FALSE;            // HMI manual mode
    
    (* Initialize timer *)
    Init_Timer              : TON;                      // Initialization timer
    Init_Complete           : BOOL := FALSE;            // Initialization complete
END_VAR

(* System Initialization *)
IF System_Initialize AND NOT Init_Complete THEN
    Init_Timer(IN := TRUE, PT := T#2s);
    
    (* Reset all MODBUS registers during initialization *)
    GVL_MODBUS.Cycle_Counter := 0;
    GVL_MODBUS.Pick_Operations_Total := 0;
    GVL_MODBUS.Assembly_Picks := 0;
    GVL_MODBUS.Receiving_Picks := 0;
    GVL_MODBUS.Warehouse_Picks := 0;
    GVL_MODBUS.Error_Count := 0;
    GVL_MODBUS.Uptime_Seconds := 0;
    GVL_MODBUS.System_Status := 0; (* Stopped *)
    
    (* Initialize robot data *)
    Robot_Data.Current_State := DUT_RobotState.ROBOT_IDLE;
    Robot_Data.Target_Bin := 0;
    Robot_Data.Target_Station := DUT_StationType.STATION_NONE;
    Robot_Data.Position_X := 0;
    Robot_Data.Position_Y := 0;
    Robot_Data.Position_Z := 0;
    
    IF Init_Timer.Q THEN
        Init_Complete := TRUE;
        System_Initialize := FALSE;
        Init_Timer(IN := FALSE);
    END_IF
END_IF

(* Only run main program after initialization *)
IF NOT Init_Complete THEN
    RETURN;
END_IF

(* Input processing *)
System_Reset := GVL_IO.Manual_Reset OR HMI_System_Reset;
Manual_Mode_Request := HMI_Manual_Mode;

(* System enable logic *)
IF HMI_System_Start AND NOT System_Enable THEN
    System_Enable := TRUE;
ELSIF HMI_System_Stop OR NOT FB_Safety.Safety_OK THEN
    System_Enable := FALSE;
END_IF

(* Call Safety System - HIGHEST PRIORITY *)
FB_Safety(
    System_Enable := System_Enable,
    Manual_Reset := System_Reset,
    Bypass_Mode := FALSE
);

(* Only proceed if safety system is OK *)
IF NOT FB_Safety.Safety_OK THEN
    (* Emergency shutdown - disable all systems *)
    System_Enable := FALSE;
    GVL_MODBUS.System_Status := 4; (* Error state *)
    
    (* Reset all operation flags *)
    GVL_MODBUS.PLC_Cycle_Running := FALSE;
    GVL_MODBUS.PLC_Cycle_Stopped := TRUE;
    
ELSE
    (* Safety OK - proceed with normal operation *)
    
    (* Call Conveyor System *)
    FB_Conveyors(
        System_Enable := System_Enable,
        Manual_Mode := Manual_Mode_Request,
        Reset_All := System_Reset
    );
    
    (* Call Pick Operation Control *)
    FB_PickControl(
        System_Enable := System_Enable,
        Reset_Command := System_Reset
    );
    
    (* Determine robot pick request and target *)
    IF FB_PickControl.Pick_Active THEN
        (* Robot control based on current pick operation *)
        FB_Robot(
            Enable := System_Enable,
            Reset_Command := System_Reset,
            Pick_Request := TRUE,
            Target_Bin := GVL_MODBUS.Current_Bin_Selection,
            Target_Station := INT_TO_DUT_StationType(
                SEL(GVL_MODBUS.To_Assembly_Sta_2, 
                    SEL(GVL_MODBUS.To_Receiving_Sta_1, 
                        DUT_StationType.STATION_WAREHOUSE, 
                        DUT_StationType.STATION_RECEIVING),
                    DUT_StationType.STATION_ASSEMBLY)),
            Manual_Mode := Manual_Mode_Request,
            Robot_Data := Robot_Data
        );
    ELSE
        (* No pick operation - robot idle *)
        FB_Robot(
            Enable := System_Enable,
            Reset_Command := System_Reset,
            Pick_Request := FALSE,
            Target_Bin := 0,
            Target_Station := DUT_StationType.STATION_NONE,
            Manual_Mode := Manual_Mode_Request,
            Robot_Data := Robot_Data
        );
    END_IF
    
    (* Call RFID System *)
    FB_RFID(
        System_Enable := System_Enable,
        Reset_All := System_Reset,
        Manual_Mode := Manual_Mode_Request
    );
    
    (* Update system status *)
    IF System_Enable THEN
        IF FB_PickControl.Pick_Active THEN
            GVL_MODBUS.System_Status := 2; (* Running *)
        ELSE
            GVL_MODBUS.System_Status := 1; (* Ready *)
        END_IF
    ELSE
        GVL_MODBUS.System_Status := 0; (* Stopped *)
    END_IF
    
END_IF

(* Call Beacon Control - Always active for status indication *)
FB_Beacons(
    System_Running := System_Enable,
    System_Error := Any_System_Error,
    Safety_OK := FB_Safety.Safety_OK,
    Manual_Mode := Manual_Mode_Request,
    Pick_Active := FB_PickControl.Pick_Active,
    Enable_Audio := TRUE
);

(* System status calculations *)
System_Ready := FB_Safety.Safety_OK AND 
                FB_Conveyors.System_OK AND 
                FB_RFID.System_OK AND 
                NOT FB_Robot.Error;

All_Systems_OK := System_Ready AND System_Enable;

Any_System_Error := FB_Safety.Emergency_Stop OR 
                   FB_Conveyors.Any_Fault OR 
                   FB_RFID.Any_Error OR 
                   FB_Robot.Error;

(* Update global system status *)
GVL_IO.System_Running := All_Systems_OK;
GVL_IO.System_Error := Any_System_Error;
GVL_Internal.System_State := GVL_MODBUS.System_Status;
GVL_Internal.Manual_Mode_Active := Manual_Mode_Request;

(* Cycle counter and timing *)
Cycle_Counter := Cycle_Counter + 1;
GVL_MODBUS.Cycle_Counter := TO_INT(Cycle_Counter MOD 32767);

(* Uptime calculation - increment every 10 cycles (approximately 1 second at 100ms) *)
Uptime_Counter := Uptime_Counter + 1;
IF Uptime_Counter >= 10 THEN
    Uptime_Counter := 0;
    IF System_Enable THEN
        GVL_MODBUS.Uptime_Seconds := GVL_MODBUS.Uptime_Seconds + 1;
    END_IF
END_IF

(* Heartbeat counter *)
Heartbeat_Counter := Heartbeat_Counter + 1;
IF Heartbeat_Counter >= 5 THEN (* 500ms heartbeat *)
    Heartbeat_Counter := 0;
    GVL_Internal.Heartbeat_Timer := NOT GVL_Internal.Heartbeat_Timer;
END_IF

(* Error counting *)
IF Any_System_Error THEN
    GVL_MODBUS.Error_Count := GVL_MODBUS.Error_Count + 1;
END_IF

(* HMI reset logic *)
IF HMI_System_Reset THEN
    HMI_System_Reset := FALSE; (* Reset HMI command *)
END_IF