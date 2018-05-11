;config file for main.asm
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
    extern  delayMillis
    extern  Transmit
    extern  Receive
    extern  processThrusterStream
    extern  ESCinit
    extern  peripheralInit
    
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
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    #define sensorInterval  (d'250') ;=time interval in between every sensor reading
				    ;=5 sec/(time to receive 4 packets + time in
				    ;between receiving 4 packets)
    
    __CONFIG _CONFIG1,    _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _WDTE_OFF & _PWRTE_ON & _FOSC_HS & _FCMEN_OFF & _IESO_OFF
    
    ;Variables accessible in all banks:
    MULTIBANK	    UDATA_SHR
    transData	    RES	1	;Data to be transmitted via UART
    receiveData	    RES	1	;Data received via UART
    state	    RES	1	;Direction "state" of ROV
    forwardSpeed    RES	1	;value to be placed in CCPR1L
    reverseSpeed    RES	1	;value to be placed in CCPR2L
    upDownSpeed	    RES	1	;value to be placed in CCPR3L
    
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