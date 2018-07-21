;Receive PWM values from topside via UART, decode packets and send PWM value to 
;appropriate thruster ESCs (Main file for ROV)

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
    banksel	w_copy
    movwf       w_copy           ;save off current W register contents
    movf	STATUS,w         ;move status register into W register
    movwf	status_copy      ;save off contents of STATUS register
    movf	PCLATH,W
    movwf       pclath_copy
    
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
    ;Handle sensor reading interval
    banksel	sensorCtr
    incf	sensorCtr, f	;Increment sensor counter every uart reception
    movlw	sensorInterval
    xorwf	sensorCtr, w	;Ready to read sensors yet?
    btfsc	STATUS, Z
    bsf		sensorFlag, 0
    
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
    banksel	readyThrust
    bsf		readyThrust, 1	    ;set readyThrustFlag
    goto	isrEnd
;Get the directional "state" of ROV
stateData
    movfw	receiveData
    movwf	state
    movlw	.1
    banksel	UartReceiveCtr
    movwf	UartReceiveCtr	;restart UART reception counter
    goto	isrEnd
;***************************END UART RECEIVE INTERRUPT**************************
;restore pre-ISR values to registers
isrEnd
    banksel	pclath_copy
    movf	pclath_copy,W
    movwf	PCLATH
    movf	status_copy,w   ;retrieve copy of STATUS register
    movwf	STATUS          ;restore pre-isr STATUS register contents
    swapf	w_copy,f
    swapf	w_copy,w        ;restore pre-isr W register contents
    banksel	PIE1
    bsf		PIE1, RCIE	;enable UART receive interrupts
    
    retfie                      ;return from interrupt

.main    code	
start:
    pagesel	peripheralInit
    call	peripheralInit	    ;initialize peripherals
    pagesel$
    movlw	b'00100000'
		 ;--1-----	;Enable USART receive interrupt (RCIE=1)
    banksel	PIE1
    movwf	PIE1 
    movlw	.10
    pagesel	delayMillis
    call	delayMillis
    pagesel$
    movlw	.2
    movwf	transData
    pagesel	Transmit
    call	Transmit	    ;Let control Box know that everything is
    pagesel$			    ;initialized
    ;TESTING
;testTemp
    ;pagesel	getTemp
    ;call	getTemp		;read temperature data
    ;pagesel$
    ;movlw	.3		;Send code for temperature data
    ;movwf	transData
    ;pagesel	Transmit
    ;call	Transmit
    ;pagesel$
    ;movlw	.10
    ;pagesel	delayMillis
    ;call	delayMillis	;Delay before sending Temp data
    ;pagesel$
    ;banksel	TempF
    ;movfw	TempF
    ;movwf	transData
    ;pagesel	Transmit
    ;call	Transmit	;Send temperature reading
    ;pagesel$
    ;movlw	.255
    ;pagesel	delayMillis
    ;call	delayMillis
    ;goto	testTemp
    ;END TESTING
mainLoop
checkThrusters
    banksel	readyThrust
    btfsc	readyThrust, 1
    goto	processStream
    goto	mainLoop
processStream
    pagesel	processThrusterStream
    call	processThrusterStream
    pagesel$
    ;TESTING
    ;goto	mainLoop
    ;END TESTING
    ;Check to see if we need to read sensors (Do this only after processing a thruster stream)
    btfss	sensorFlag, 0	;Ready to read?
    goto	mainLoop	;No reloop
    
    banksel	PIE1
    bcf		PIE1, RCIE	;Disable UART receive interrupts
    pagesel	getTemp
    call	getTemp		;read temperature data
    pagesel$
    movlw	.3		;Send code for temperature data
    movwf	transData
    pagesel	Transmit
    call	Transmit
    pagesel$
    movlw	.10
    pagesel	delayMillis
    call	delayMillis	;Delay before sending Temp data
    pagesel$
    banksel	TempF
    movfw	TempF
    movwf	transData
    pagesel	Transmit
    call	Transmit	;Send temperature reading
    pagesel$
    movlw	.50
    pagesel	delayMillis
    call	delayMillis	
    pagesel$
    banksel	sensorCtr
    clrf	sensorCtr	;clear counter
    clrf	sensorFlag	;clear flag
    banksel	PIE1
    bsf		PIE1, RCIE	;Enable UART receive interrupts
    
    goto	mainLoop
    
    END                       
































