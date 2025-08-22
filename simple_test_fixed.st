PROGRAM simple_test
  VAR
    input_switch AT %IX0.0 : BOOL;     (* Digital input 0 *)
    output_light AT %QX0.0 : BOOL;    (* Digital output 0 *)
    counter AT %MW0 : INT := 0;        (* Memory word 0 *)
    timer_val AT %MW1 : INT := 0;      (* Memory word 1 *)
  END_VAR

  (* Simple logic: light follows switch *)
  output_light := input_switch;
  
  (* Counter increments every scan *)
  counter := counter + 1;
  IF counter > 1000 THEN
    counter := 0;
  END_IF;
  
  (* Timer value for testing *)
  timer_val := timer_val + 1;
  IF timer_val > 500 THEN
    timer_val := 0;
  END_IF;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#100ms,PRIORITY := 0);
    PROGRAM Inst0 WITH Main : simple_test;
  END_RESOURCE
END_CONFIGURATION