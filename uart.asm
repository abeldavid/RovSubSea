;Various subroutines for UART opertations and data-stream processing
    
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    extern  forwardSpeed
    extern  reverseSpeed
    extern  upDownSpeed
    extern  transData
    extern  receiveData
    
    global  Transmit
    global  Receive
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
   
;***********************UART Tansmit Routine************************************
.transmit   code		
Transmit
wait_trans
    banksel	PIR1
    btfss	PIR1, TXIF	;Is TX buffer full? (1=empty, 0=full)
    goto	wait_trans	;wait until it is empty
    movfw	transData	
    banksel	TXREG
    movwf	TXREG		;data to be transmitted loaded into TXREG
				;and then automatically loaded into TSR
    retlw	0
;*****************UART Receive Routine******************************************    
.receive    code
Receive
    banksel	PIR1
wait_receive
    btfss	PIR1, RCIF	;Is RX buffer full? (1=full, 0=notfull)
    goto	wait_receive	;wait until it is full
    banksel	RCSTA
    bcf		RCSTA, CREN
    banksel	RCREG
    movfw	RCREG		;Place data from RCREG into "receiveData"
    movwf	receiveData
    banksel	PIR1
    bcf	        PIR1, RCIF	    ;clear UART receive interrupt flag
    banksel	RCSTA
    bsf		RCSTA, CREN
    retlw	0
   
    END
