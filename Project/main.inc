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
    extern  TempF	    ;Holds temp value in Farenheit
    extern  slaveReset
    extern  TempC
    
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