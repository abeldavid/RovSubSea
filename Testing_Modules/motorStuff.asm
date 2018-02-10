;Various routines for motor/ESC related tasks
    
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    extern  state
    extern  forwardSpeed
    extern  reverseSpeed
    extern  upDownSpeed
    extern  readyThrust
    extern  delayMillis
    extern  transData
    extern  Transmit
    
    global  processThrusterStream
    global  ESCinit
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    
GENVAR		UDATA
initCounter	RES	1	;counter for initializing ESCs
    
;**************Send PWM signals to thrusters************************************
;Once all four UART thruster data packets have been received, send PWM signals
;to thrusters
.stream	    code
processThrusterStream
    ;check directional state of ROV
    movfw	state
    
    ;use lookup table to get AND values for PORTD
    call	stateLookUp
    banksel	PORTD
    movwf	PORTD	    ;place AND value in PORTD
    
    movfw	forwardSpeed
    banksel	CCPR1L
    movwf	CCPR1L
    
    movfw	reverseSpeed
    banksel	CCPR2L
    movwf	CCPR2L
    
    movfw	upDownSpeed
    banksel	CCPR3L
    movwf	CCPR3L
    
    bcf		readyThrust, 1	;clear readyThrustFlag

    retlw	0
    
;*******************Lookup Table to get ANDing values for PORTD ****************
.lookUp	    code
stateLookUp
    addwf   PCL, f
    retlw   b'11000011'	    ;0 forward (T1/T2 FWD, T3/T4 REV)
    retlw   b'00111100'	    ;1 reverse (T3/T4 FWD, T1/T2 REV)
    retlw   b'10100101'	    ;2 traverse right (T1/T3 FWD, T2/T4 REV)
    retlw   b'01011010'	    ;3 traverse left (T2/T4 FWD, T1/T3 REV)
    retlw   b'01101001'	    ;4 rotate clockwise (T1/T4 FWD, T2/T3 REV)
    retlw   b'10010110'	    ;5 rotate counter-clockwise (T2/T3 FWD, T1/T4 REV)
    retlw   b'00001111'	    ;6 up/down (T1/T4 FWD, T2/T3 REV)
    retlw   b'00001111'	    ;7 stop
    
;******Initialize ESCs with stoped signal (1500uS) for four seconds*************
.escInit    code
ESCinit
    movlw	b'00001111'
    banksel	PORTD
    movwf	PORTD
    movlw	.16
    banksel	initCounter
    movwf	initCounter	;16 calls to delayMillis at 250ms each = 4 sec
    movlw	.95		;1500uS pulse width
    banksel	CCPR2L		;ESC #2
    movwf	CCPR2L
    banksel	CCPR1L		;ESC #1
    movwf	CCPR1L
    banksel	CCPR3L
    movwf	CCPR3L
beginInit
    movlw	.250
    call	delayMillis
    banksel	initCounter
    decf	initCounter, f
    movlw	.0
    xorwf	initCounter, w
    btfss	STATUS, Z
    goto	beginInit
    banksel	PORTD
    clrf	PORTD
    movlw	.2
    movwf	transData
    call	Transmit
    retlw	0

    END