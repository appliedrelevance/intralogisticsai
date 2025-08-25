PROGRAM TrafficLightController

VAR
    pedestrian_ns_button AT %IX0.0 : BOOL;
    pedestrian_ew_button AT %IX0.1 : BOOL;
    emergency_override AT %IX0.2 : BOOL;
    system_enable AT %IX0.3 : BOOL;
    manual_reset AT %IX0.4 : BOOL;
    
    ns_red_light AT %QX0.0 : BOOL;
    ns_yellow_light AT %QX0.1 : BOOL;
    ns_green_light AT %QX0.2 : BOOL;
    ew_red_light AT %QX0.3 : BOOL;
    ew_yellow_light AT %QX0.4 : BOOL;
    ew_green_light AT %QX0.5 : BOOL;
    ped_ns_walk AT %QX0.6 : BOOL;
    ped_ns_dont_walk AT %QX0.7 : BOOL;
    ped_ew_walk AT %QX1.0 : BOOL;
    ped_ew_dont_walk AT %QX1.1 : BOOL;
    
    system_state AT %MW0 : INT;
    ns_green_cycles AT %MW1 : INT;
    ew_green_cycles AT %MW2 : INT;
    ped_ns_cycles AT %MW3 : INT;
    ped_ew_cycles AT %MW4 : INT;
    emergency_activations AT %MW5 : INT;
    total_runtime_seconds AT %MW6 : INT;
END_VAR

VAR
    timer_main : TON;
    timer_yellow : TON;
    timer_ped : TON;
    timer_emergency : TON;
    runtime_timer : TON;
    
    green_time_ns : TIME := T#30000MS;
    green_time_ew : TIME := T#25000MS;
    yellow_time : TIME := T#5000MS;
    ped_walk_time : TIME := T#15000MS;
    ped_clear_time : TIME := T#10000MS;
    emergency_flash_time : TIME := T#500MS;
    
    STATE_NS_GREEN : INT := 1;
    STATE_NS_YELLOW : INT := 2;
    STATE_EW_GREEN : INT := 3;
    STATE_EW_YELLOW : INT := 4;
    STATE_PED_NS_WALK : INT := 5;
    STATE_PED_NS_CLEAR : INT := 6;
    STATE_PED_EW_WALK : INT := 7;
    STATE_PED_EW_CLEAR : INT := 8;
    STATE_EMERGENCY : INT := 9;
    
    ped_ns_request : BOOL := FALSE;
    ped_ew_request : BOOL := FALSE;
    emergency_active : BOOL := FALSE;
    emergency_flash_state : BOOL := FALSE;
    
    ped_ns_btn_prev : BOOL := FALSE;
    ped_ew_btn_prev : BOOL := FALSE;
    emergency_btn_prev : BOOL := FALSE;
    
    (* System Status *)
    system_running : BOOL;
    emergency_mode : BOOL;
    fault_status : BOOL;
END_VAR

VAR_IN_OUT
    (* Statistics for MODBUS Register Access *)
    cycle_count_total : INT;
    avg_cycle_time : INT;
    last_emergency_time : TIME;
END_VAR

(* Main Program Logic *)

(* Initialize system on first run *)
IF system_state = 0 AND system_enable THEN
    system_state := STATE_NS_GREEN;
    ns_green_cycles := 0;
    ew_green_cycles := 0;
    ped_ns_cycles := 0;
    ped_ew_cycles := 0;
    emergency_activations := 0;
    total_runtime_seconds := 0;
END_IF;

(* Runtime Counter - Increment every second *)
runtime_timer(IN:=system_enable, PT:=T#1000MS);
IF runtime_timer.Q THEN
    runtime_timer(IN:=FALSE);
    runtime_timer(IN:=TRUE);
    total_runtime_seconds := total_runtime_seconds + 1;
END_IF;

(* Edge Detection for Pedestrian Buttons *)
IF pedestrian_ns_button AND NOT ped_ns_btn_prev THEN
    ped_ns_request := TRUE;
END_IF;
ped_ns_btn_prev := pedestrian_ns_button;

IF pedestrian_ew_button AND NOT ped_ew_btn_prev THEN
    ped_ew_request := TRUE;
END_IF;
ped_ew_btn_prev := pedestrian_ew_button;

(* Edge Detection for Emergency Override *)
IF emergency_override AND NOT emergency_btn_prev THEN
    emergency_active := TRUE;
    emergency_activations := emergency_activations + 1;
    last_emergency_time := TIME();
END_IF;
emergency_btn_prev := emergency_override;

(* Emergency Override Logic *)
IF emergency_active AND emergency_override THEN
    system_state := STATE_EMERGENCY;
    emergency_mode := TRUE;
ELSIF emergency_active AND NOT emergency_override THEN
    emergency_active := FALSE;
    emergency_mode := FALSE;
    system_state := STATE_NS_GREEN;
    timer_main(IN:=FALSE);
END_IF;

(* Manual Reset *)
IF manual_reset THEN
    system_state := STATE_NS_GREEN;
    ped_ns_request := FALSE;
    ped_ew_request := FALSE;
    emergency_active := FALSE;
    emergency_mode := FALSE;
    timer_main(IN:=FALSE);
    timer_yellow(IN:=FALSE);
    timer_ped(IN:=FALSE);
    timer_emergency(IN:=FALSE);
END_IF;

(* Main State Machine *)
CASE system_state OF

    STATE_NS_GREEN:
        (* North-South Green Light *)
        ns_red_light := FALSE;
        ns_yellow_light := FALSE;
        ns_green_light := TRUE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        (* Pedestrian Signals *)
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := TRUE;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := TRUE;
        
        (* Timer for green phase *)
        timer_main(IN:=TRUE, PT:=green_time_ns);
        
        IF timer_main.Q THEN
            timer_main(IN:=FALSE);
            ns_green_cycles := ns_green_cycles + 1;
            cycle_count_total := cycle_count_total + 1;
            
            (* Check for pedestrian request *)
            IF ped_ew_request THEN
                system_state := STATE_PED_EW_WALK;
                ped_ew_request := FALSE;
            ELSE
                system_state := STATE_NS_YELLOW;
            END_IF;
        END_IF;

    STATE_NS_YELLOW:
        (* North-South Yellow Light *)
        ns_red_light := FALSE;
        ns_yellow_light := TRUE;
        ns_green_light := FALSE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        timer_yellow(IN:=TRUE, PT:=yellow_time);
        
        IF timer_yellow.Q THEN
            timer_yellow(IN:=FALSE);
            system_state := STATE_EW_GREEN;
        END_IF;

    STATE_EW_GREEN:
        (* East-West Green Light *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := FALSE;
        ew_yellow_light := FALSE;
        ew_green_light := TRUE;
        
        (* Pedestrian Signals *)
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := TRUE;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := TRUE;
        
        timer_main(IN:=TRUE, PT:=green_time_ew);
        
        IF timer_main.Q THEN
            timer_main(IN:=FALSE);
            ew_green_cycles := ew_green_cycles + 1;
            cycle_count_total := cycle_count_total + 1;
            
            (* Check for pedestrian request *)
            IF ped_ns_request THEN
                system_state := STATE_PED_NS_WALK;
                ped_ns_request := FALSE;
            ELSE
                system_state := STATE_EW_YELLOW;
            END_IF;
        END_IF;

    STATE_EW_YELLOW:
        (* East-West Yellow Light *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := FALSE;
        ew_yellow_light := TRUE;
        ew_green_light := FALSE;
        
        timer_yellow(IN:=TRUE, PT:=yellow_time);
        
        IF timer_yellow.Q THEN
            timer_yellow(IN:=FALSE);
            system_state := STATE_NS_GREEN;
        END_IF;

    STATE_PED_NS_WALK:
        (* Pedestrian North-South Walk Phase *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        ped_ns_walk := TRUE;
        ped_ns_dont_walk := FALSE;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := TRUE;
        
        timer_ped(IN:=TRUE, PT:=ped_walk_time);
        
        IF timer_ped.Q THEN
            timer_ped(IN:=FALSE);
            ped_ns_cycles := ped_ns_cycles + 1;
            system_state := STATE_PED_NS_CLEAR;
        END_IF;

    STATE_PED_NS_CLEAR:
        (* Pedestrian North-South Clearance Phase *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := TRUE;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := TRUE;
        
        timer_ped(IN:=TRUE, PT:=ped_clear_time);
        
        IF timer_ped.Q THEN
            timer_ped(IN:=FALSE);
            system_state := STATE_EW_GREEN;
        END_IF;

    STATE_PED_EW_WALK:
        (* Pedestrian East-West Walk Phase *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := TRUE;
        ped_ew_walk := TRUE;
        ped_ew_dont_walk := FALSE;
        
        timer_ped(IN:=TRUE, PT:=ped_walk_time);
        
        IF timer_ped.Q THEN
            timer_ped(IN:=FALSE);
            ped_ew_cycles := ped_ew_cycles + 1;
            system_state := STATE_PED_EW_CLEAR;
        END_IF;

    STATE_PED_EW_CLEAR:
        (* Pedestrian East-West Clearance Phase *)
        ns_red_light := TRUE;
        ns_yellow_light := FALSE;
        ns_green_light := FALSE;
        ew_red_light := TRUE;
        ew_yellow_light := FALSE;
        ew_green_light := FALSE;
        
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := TRUE;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := TRUE;
        
        timer_ped(IN:=TRUE, PT:=ped_clear_time);
        
        IF timer_ped.Q THEN
            timer_ped(IN:=FALSE);
            system_state := STATE_NS_GREEN;
        END_IF;

    STATE_EMERGENCY:
        (* Emergency Mode - Flash All Red *)
        timer_emergency(IN:=TRUE, PT:=emergency_flash_time);
        
        IF timer_emergency.Q THEN
            timer_emergency(IN:=FALSE);
            emergency_flash_state := NOT emergency_flash_state;
        END_IF;
        
        IF emergency_flash_state THEN
            ns_red_light := TRUE;
            ns_yellow_light := FALSE;
            ns_green_light := FALSE;
            ew_red_light := TRUE;
            ew_yellow_light := FALSE;
            ew_green_light := FALSE;
        ELSE
            ns_red_light := FALSE;
            ns_yellow_light := FALSE;
            ns_green_light := FALSE;
            ew_red_light := FALSE;
            ew_yellow_light := FALSE;
            ew_green_light := FALSE;
        END_IF;
        
        (* Pedestrian signals off during emergency *)
        ped_ns_walk := FALSE;
        ped_ns_dont_walk := emergency_flash_state;
        ped_ew_walk := FALSE;
        ped_ew_dont_walk := emergency_flash_state;

END_CASE;

(* System Status *)
system_running := system_enable AND (system_state > 0);
fault_status := NOT system_enable OR (system_state = 0);

(* Calculate Average Cycle Time *)
IF cycle_count_total > 0 THEN
    avg_cycle_time := total_runtime_seconds / cycle_count_total;
ELSE
    avg_cycle_time := 0;
END_IF;

END_PROGRAM