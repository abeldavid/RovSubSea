;config file for math.asm
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
    global  mul32
    global  getTemp
    global  TempF
    global  TempC
    global  negFlag
    global  negFaren
    
    extern  TEMPSENS
    extern  Tref
    extern  D2
    extern  D1
    extern  sensorData
    extern  tOrP
    extern  adcCPY
    extern  slaveReset
    
    
    ;Non-shared variables
    GENVAR1	    UDATA
    product32   RES	8   ;64 bit 
    mpcand32    RES	4   ;32 bit multiplicand for multiplication routine.
    loopCount   RES	1   ;counter mul/div routines
    negFlag	RES	1   ;bit 0 of this is set is operation results in neg number
    deeT	RES	4   ;32 bit signed int
    ;32 bit div variables
    remainder	RES	5   ;33 number (Remainder for div32 routine)
    divisor	RES	4   ;divisor
    Q		RES	5   ;dividend/quotient
    TempC	RES	5   ;Final value for temperature (Celsius) reading (signed value)
			    ;LSB of TempC holds value to be displayed
    TempF	RES	1   ;Final value for temperature (Farenheit) (signed value)
    negFaren    RES	1   ;Flag used to indicate a negative temp in Farenheit
			    ;if bit 0 = 1 then negative
    