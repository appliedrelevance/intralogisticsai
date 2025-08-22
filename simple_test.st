PROGRAM simple_test
  VAR
    input_switch : BOOL;        (* %IX0.0 *)
    output_light : BOOL;        (* %QX0.0 *)
    counter : INT := 0;         (* Internal counter *)
    timer1 : TON;               (* Timer *)
  END_VAR

  (* Simple logic: light follows switch *)
  output_light := input_switch;
  
  (* Counter increments every scan *)
  counter := counter + 1;
  IF counter > 1000 THEN
    counter := 0;
  END_IF;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#100ms,PRIORITY := 0);
    PROGRAM Inst0 WITH Main : simple_test;
  END_RESOURCE
END_CONFIGURATION