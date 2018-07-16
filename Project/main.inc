;config file for main.asm
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
    extern  delayMillis
    extern  Transmit
    extern  Receive
    extern  processThrusterStream
    extern  ESCinit
    extern  peripheralInit
    extern  getTemp	    ;routine to read temp data
    extern  slaveReset
    
    global  forwardSpeed
    global  reverseSpeed
    global  upDownSpeed
    global  transData
    global  receiveData
    global  state
    global  readyThrust
    global  UartReceiveCtr
    global  userMillis
    global  sensorCtr
    global  sensorFlag
    global  fwdSpool
    global  revSpool
    global  upDnSpool
    ;math.asm
    global  product32
    global  mpcand32
    global  loopCount
    global  negFlag
    global  deeT
    global  remainder
    global  divisor
    global  Q
    global  TempC
    global  TempF
    global  negFaren
    ;ms5837.asm
    global  tOrP
    global  SENS
    global  OFF
    global  TCS
    global  TCO
    global  Tref
    global  TEMPSENS
    global  D1
    global  D2
    ;serial.asm
    global  i2cByteToSend   
    global  coeffCPY	    
    global  adcCPY	    
    
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    #define sensorInterval  (d'200') ;=time interval in between every sensor reading
				    ;=5 sec/(time to receive 4 packets + time in
				    ;between receiving 4 packets)
    
    ; CONFIG1
; __config 0x9C2
    __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
; __config 0xDDFF
    __CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_OFF & _BORV_LO & _LVP_OFF
    
    ;Variables accessible in all banks:
    MULTIBANK	    UDATA_SHR
    transData	    RES	1	;Data to be transmitted via UART
    receiveData	    RES	1	;Data received via UART
    state	    RES	1	;Direction "state" of ROV
    forwardSpeed    RES	1	;value to be placed in CCPR1L
    reverseSpeed    RES	1	;value to be placed in CCPR2L
    upDownSpeed	    RES	1	;value to be placed in CCPR3L
    fwdSpool	    RES	1	;used for spooling up fwd spinning thrusters
    revSpool	    RES	1	;used for spooling up rev spinning thrusters
    upDnSpool	    RES	1	;used for spooling up T5/T6 (up/down movement)
    
    ;General Variables
    GENVAR	    UDATA
    UartReceiveCtr  RES	1	;counter for number of UART receptions
    readyThrust	    RES	1	;flag to be set when all 4 UART thruster data packets 
				;have been received
    userMillis	    RES	1
    w_copy	    RES 1	;variable used for context saving (work reg)
    status_copy	    RES 1	;variable used for context saving (status reg)
    pclath_copy	    RES 1	;variable used for context saving (pclath copy)
    sensorCtr	    RES	1	;Incremented on every UART receive interrupt.
				;At 5 sec, sensors are read
    sensorFlag	    RES	1	;1=read sensors, 0=don't read sensors
    ;***********************For math.asm****************************************
    product32	    RES	8   ;64 bit 
    mpcand32	    RES	4   ;32 bit multiplicand for multiplication routine.
    loopCount	    RES	1   ;counter mul/div routines
    negFlag	    RES	1   ;bit 0 of this is set is operation results in neg number
    deeT	    RES	4   ;32 bit signed int
    ;32 bit div variables
    remainder	    RES	5   ;33 number (Remainder for div32 routine)
    divisor	    RES	4   ;divisor
    Q		    RES	5   ;dividend/quotient
    TempC	    RES	5   ;Final value for temperature (Celsius) reading (signed value)
			    ;LSB of TempC holds value to be displayed
    TempF	    RES	1   ;Final value for temperature (Farenheit) (signed value)
    negFaren	    RES	1   ;Flag used to indicate a negative temp in Farenheit
			    ;if bit 0 = 1 then negative
    ;*************************For ms5837.asm************************************
    tOrP	RES 1	;flag used to determine whether we read temp
			;or pressure data (0=pressure, 1=temperature)
    SENS	RES 2	;Pressure Secnsitivity (2 bytes) from PROM
    OFF		RES 2	;Pressure Offset (2 bytes) from PROM
    TCS		RES 2	;Temp coeff of pressure sensitivity (2 bytes) from PROM
    TCO		RES 2	;Temp coeff of pressure offset (2 bytes) from PROM
    Tref	RES 2	;Reference temperature (2 bytes) from PROM
    TEMPSENS	RES 2	;Temp coeff of temperature (2 bytes) from PROM
    D1		RES 3	;Pressure value from ADC read of slave (3 bytes)
    D2		RES 3	;Temperature value from ADC read of slave (3 bytes)
    ;**************************For serial.asm
    i2cByteToSend   RES	1
    coeffCPY	    RES	2   ;shadow register for copying PROM coefficients
    adcCPY	    RES	3   ;shadow register for copying temp/press ADC values