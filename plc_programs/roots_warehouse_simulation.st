PROGRAM RootsWarehouseSimulation
  VAR
    emergency_stop AT %IX0.0 : BOOL;
    manual_reset AT %IX0.1 : BOOL;
    
    (* Process Control Signals - MODBUS 1000-1008 *)
    plc_cycle_stopped AT %QX125.0 : BOOL;
    plc_cycle_running AT %QX125.1 : BOOL;
    pick_error AT %QX125.2 : BOOL;
    pick_to_assembly_in_process AT %QX125.3 : BOOL;
    pick_to_assembly_complete AT %QX125.4 : BOOL;
    pick_to_receiving_in_process AT %QX125.5 : BOOL;
    pick_to_receiving_complete AT %QX125.6 : BOOL;
    pick_to_warehouse_in_process AT %QX125.7 : BOOL;
    pick_to_warehouse_complete AT %QX126.0 : BOOL;
    
    (* Pick Bin Controls - MODBUS 2000-2011 - ERP Controlled Coils *)
    pick_bin_01 AT %QX250.0 : BOOL;
    pick_bin_02 AT %QX250.1 : BOOL;
    pick_bin_03 AT %QX250.2 : BOOL;
    pick_bin_04 AT %QX250.3 : BOOL;
    pick_bin_05 AT %QX250.4 : BOOL;
    pick_bin_06 AT %QX250.5 : BOOL;
    pick_bin_07 AT %QX250.6 : BOOL;
    pick_bin_08 AT %QX250.7 : BOOL;
    pick_bin_09 AT %QX251.0 : BOOL;
    pick_bin_10 AT %QX251.1 : BOOL;
    pick_bin_11 AT %QX251.2 : BOOL;
    pick_bin_12 AT %QX251.3 : BOOL;
    
    (* Station Status Controls - MODBUS 2020-2023 - ERP Controlled Coils *)
    to_receiving_sta_1 AT %QX252.4 : BOOL;
    from_receiving_sta_1 AT %QX252.5 : BOOL;
    to_assembly_sta_2 AT %QX252.6 : BOOL;
    from_assembly_sta_2 AT %QX252.7 : BOOL;
    
    (* Statistics and Monitoring - MODBUS 100-106 *)
    cycle_counter AT %MW100 : INT;
    pick_operations_total AT %MW101 : INT;
    assembly_picks AT %MW102 : INT;
    receiving_picks AT %MW103 : INT;
    warehouse_picks AT %MW104 : INT;
    error_count AT %MW105 : INT;
    uptime_seconds AT %MW106 : INT;
  END_VAR
  
  VAR
    (* Simple operation timers - 20 seconds = 200 cycles at 100ms *)
    assembly_timer : INT := 0;
    receiving_timer : INT := 0;
    warehouse_timer : INT := 0;
    
    (* Complete signal auto-reset timers - 5 seconds = 50 cycles *)
    assembly_complete_timer : INT := 0;
    receiving_complete_timer : INT := 0;
    warehouse_complete_timer : INT := 0;
    
    (* ERP command detection *)
    any_bin_selected : BOOL := FALSE;
    assembly_requested : BOOL := FALSE;
    receiving_requested : BOOL := FALSE;
    warehouse_requested : BOOL := FALSE;
    
    (* Operation state tracking *)
    assembly_in_progress : BOOL := FALSE;
    receiving_in_progress : BOOL := FALSE;
    warehouse_in_progress : BOOL := FALSE;
    
    (* Uptime calculation *)
    uptime_timer : INT := 0;
  END_VAR

  (* Perfect world system - always running, never errors *)
  plc_cycle_running := TRUE;
  plc_cycle_stopped := FALSE;
  pick_error := FALSE;
  
  (* Increment counters *)
  cycle_counter := cycle_counter + 1;
  
  (* Uptime calculation - increment every 10 cycles (approximately 1 second at 100ms) *)
  uptime_timer := uptime_timer + 1;
  IF uptime_timer >= 10 THEN
    uptime_timer := 0;
    uptime_seconds := uptime_seconds + 1;
  END_IF;
  
  (* ERP Command Detection *)
  any_bin_selected := pick_bin_01 OR pick_bin_02 OR pick_bin_03 OR pick_bin_04 OR 
                      pick_bin_05 OR pick_bin_06 OR pick_bin_07 OR pick_bin_08 OR
                      pick_bin_09 OR pick_bin_10 OR pick_bin_11 OR pick_bin_12;
  
  assembly_requested := any_bin_selected AND to_assembly_sta_2;
  receiving_requested := any_bin_selected AND to_receiving_sta_1;
  warehouse_requested := any_bin_selected AND (NOT to_assembly_sta_2) AND (NOT to_receiving_sta_1);
  
  (* Assembly Operation - 20 Second Robot Simulation *)
  IF assembly_requested AND NOT assembly_in_progress THEN
    (* Start assembly operation *)
    assembly_in_progress := TRUE;
    pick_to_assembly_in_process := TRUE;
    assembly_timer := 0;
  END_IF;
  
  IF assembly_in_progress THEN
    assembly_timer := assembly_timer + 1;
    IF assembly_timer >= 200 THEN (* 20.0 seconds at 100ms cycles *)
      (* Complete assembly operation *)
      pick_to_assembly_complete := TRUE;
      pick_to_assembly_in_process := FALSE;
      assembly_in_progress := FALSE;
      assembly_timer := 0;
      assembly_picks := assembly_picks + 1;
      pick_operations_total := pick_operations_total + 1;
    END_IF;
  END_IF;
  
  (* Receiving Operation - 20 Second Robot Simulation *)
  IF receiving_requested AND NOT receiving_in_progress THEN
    (* Start receiving operation *)
    receiving_in_progress := TRUE;
    pick_to_receiving_in_process := TRUE;
    receiving_timer := 0;
  END_IF;
  
  IF receiving_in_progress THEN
    receiving_timer := receiving_timer + 1;
    IF receiving_timer >= 200 THEN (* 20.0 seconds at 100ms cycles *)
      (* Complete receiving operation *)
      pick_to_receiving_complete := TRUE;
      pick_to_receiving_in_process := FALSE;
      receiving_in_progress := FALSE;
      receiving_timer := 0;
      receiving_picks := receiving_picks + 1;
      pick_operations_total := pick_operations_total + 1;
    END_IF;
  END_IF;
  
  (* Warehouse Operation - 20 Second Robot Simulation *)
  IF warehouse_requested AND NOT warehouse_in_progress THEN
    (* Start warehouse operation *)
    warehouse_in_progress := TRUE;
    pick_to_warehouse_in_process := TRUE;
    warehouse_timer := 0;
  END_IF;
  
  IF warehouse_in_progress THEN
    warehouse_timer := warehouse_timer + 1;
    IF warehouse_timer >= 200 THEN (* 20.0 seconds at 100ms cycles *)
      (* Complete warehouse operation *)
      pick_to_warehouse_complete := TRUE;
      pick_to_warehouse_in_process := FALSE;
      warehouse_in_progress := FALSE;
      warehouse_timer := 0;
      warehouse_picks := warehouse_picks + 1;
      pick_operations_total := pick_operations_total + 1;
    END_IF;
  END_IF;
  
  (* Auto-reset COMPLETE signals after 10 seconds to allow ERP processing time *)
  IF pick_to_assembly_complete THEN
    assembly_complete_timer := assembly_complete_timer + 1;
    IF assembly_complete_timer >= 100 THEN (* 10 seconds *)
      pick_to_assembly_complete := FALSE;
      assembly_complete_timer := 0;
    END_IF;
  ELSE
    assembly_complete_timer := 0;
  END_IF;
  
  IF pick_to_receiving_complete THEN
    receiving_complete_timer := receiving_complete_timer + 1;
    IF receiving_complete_timer >= 100 THEN (* 10 seconds *)
      pick_to_receiving_complete := FALSE;
      receiving_complete_timer := 0;
    END_IF;
  ELSE
    receiving_complete_timer := 0;
  END_IF;
  
  IF pick_to_warehouse_complete THEN
    warehouse_complete_timer := warehouse_complete_timer + 1;
    IF warehouse_complete_timer >= 100 THEN (* 10 seconds *)
      pick_to_warehouse_complete := FALSE;
      warehouse_complete_timer := 0;
    END_IF;
  ELSE
    warehouse_complete_timer := 0;
  END_IF;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#100ms,PRIORITY := 0);
    PROGRAM Inst0 WITH Main : RootsWarehouseSimulation;
  END_RESOURCE
END_CONFIGURATION