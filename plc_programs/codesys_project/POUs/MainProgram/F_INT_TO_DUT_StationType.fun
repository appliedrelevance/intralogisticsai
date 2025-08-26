FUNCTION F_INT_TO_DUT_StationType : DUT_StationType
VAR_INPUT
    input_value : INT;      // Integer input to convert
END_VAR

(* Convert integer to DUT_StationType enumeration *)
CASE input_value OF
    0: F_INT_TO_DUT_StationType := DUT_StationType.STATION_NONE;
    1: F_INT_TO_DUT_StationType := DUT_StationType.STATION_RECEIVING;
    2: F_INT_TO_DUT_StationType := DUT_StationType.STATION_ASSEMBLY;
    3: F_INT_TO_DUT_StationType := DUT_StationType.STATION_WAREHOUSE;
    ELSE
        F_INT_TO_DUT_StationType := DUT_StationType.STATION_NONE;
END_CASE