;Receive PWM values from topside via UART, decode packets and send PWM value to 
;appropriate thruster ESCs

    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    #include	<main.inc>		; include file for main.asm
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
;**********************************************************************
.reset code	0x000	
    pagesel	start	    ;processor reset vector
    goto	start	    ;go to beginning of program
INT_VECTOR:
.Interupt code	0x004		    ;interrupt vector location
INTERRUPT:

    movwf       w_copy           ;save off current W register contents
    movf	STATUS,w         ;move status register into W register
    movwf	status_copy      ;save off contents of STATUS register
    movf	PCLATH,W
    movwf       pclath_copy
    banksel	PIE1
    bcf		PIE1, RCIE	 ;disable UART receive interrupts
	
    ;Determine source of interrupt
    btfsc	INTCON, IOCIF	 ;change on PORTB?
    goto	PORTBchange
    banksel	PIR1
    btfsc	PIR1, RCIF	 ;UART receive interrupt?
    goto	UartReceive
    goto	isrEnd
    ;determine source of PORTB interrupt
PORTBchange
    banksel	IOCBF
    btfsc	IOCBF, 0         ;Leak?
    goto	LEAK
    goto	isrEnd
;*********************LEAK DETECTOR INTERRUPT***********************************
LEAK
    movlw	.1		;1 = code for Leak
    movwf	transData
    pagesel	Transmit
    call	Transmit
    pagesel$
    pagesel	Transmit
    call	Transmit
    pagesel$
    pagesel	Transmit
    call	Transmit
    pagesel$
    banksel	TXSTA
    bcf		TXSTA, TX9D	;clear sensor data flag
    banksel	IOCBF
    bcf		IOCBF, 0	;clear leak flag
    banksel	IOCBP
    bcf		IOCBP, 0	;Leak has already been detected so disable IOC 
				;for PORTB, 0 so ROV can still be controlled and
				;surfaced
    goto	isrEnd
    
;*********************BEGIN UART INTERRUPT**************************************
UartReceive
    pagesel	Receive
    call	Receive
    pagesel$
    ;1)Get "state" of ROV direction signal
    ;Check if UART packet contains a valid value for "state" (1-7)
    movlw	.8		;max number for "state"=7
    subwf	receiveData, w	;subtract 8 from value in UART packet
    btfss	STATUS, C	;(C=0 is neg number) (valid result=neg #)
    goto	stateData
    ;If UartReceiveCtr is "1" then get forward speed
    movlw	.1
    banksel	UartReceiveCtr
    xorwf	UartReceiveCtr, w
    btfss	STATUS, Z
    goto	checkReverseSpeed   ;Not "1" so proceed
    banksel	UartReceiveCtr
    incf	UartReceiveCtr, f   ;increment UART reception counter
    movfw	receiveData	    ;Place data packet value into forwardSpeed
    movwf	forwardSpeed
    goto	isrEnd
    ;If UartReceiveCtr is "2" then get reverse speed
checkReverseSpeed
    movlw	.2
    banksel	UartReceiveCtr
    xorwf	UartReceiveCtr, w
    btfss	STATUS, Z
    goto	checkUpDownSpeed   ;Not "1" so proceed
    banksel	UartReceiveCtr
    incf	UartReceiveCtr, f   ;increment UART reception counter
    movfw	receiveData	    ;Place data packet value into forwardSpeed
    movwf	reverseSpeed
    goto	isrEnd
    ;finally, get Up/Down speed
checkUpDownSpeed
    movfw	receiveData	    ;Place data packet value into forwardSpeed
    movwf	upDownSpeed
    bsf		readyThrust, 1	    ;set readyThrustFlag
    goto	isrEnd
;Get the directional "state" of ROV
stateData
    movlw	.1
    banksel	UartReceiveCtr
    movwf	UartReceiveCtr	;restart UART reception counter
    movfw	receiveData
    movwf	state
    goto	isrEnd
;***************************END UART RECEIVE INTERRUPT**************************
;restore pre-ISR values to registers
isrEnd
    banksel	PIE1
    bsf		PIE1, RCIE	;enable UART receive interrupts
    movf	pclath_copy,W
    movwf	PCLATH
    movf	status_copy,w   ;retrieve copy of STATUS register
    movwf	STATUS          ;restore pre-isr STATUS register contents
    swapf	w_copy,f
    swapf	w_copy,w        ;restore pre-isr W register contents
    retfie                      ;return from interrupt

.main    code	
start:
    pagesel	peripheralInit
    call	peripheralInit	    ;initialize peripherals
    pagesel$
    
mainLoop
    banksel	readyThrust
    btfsc	readyThrust, 1
    goto	processStream
    goto	mainLoop
processStream
    pagesel	processThrusterStream
    call	processThrusterStream
    pagesel$
    goto	mainLoop
  
    END                       
































