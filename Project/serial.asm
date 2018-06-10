;Various subroutines for UART opertations and data-stream processing
    
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    #include	<i2c.inc>
    
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

   
;***********************UART Tansmit Routine************************************
.serial   code		
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
    
;******************************I2C Routines*************************************
;Send START condition and wait for it to complete
I2Cstart
    banksel	SSPCON2
    bsf		SSPCON2, SEN
    btfsc	SSPCON2, SEN
    goto	$-1
    ;call	waitMSSP
    retlw	0
    
;Send STOP condition and wait for it to complete
I2CStop
    banksel	SSPCON2
    bsf		SSPCON2, PEN
    btfsc	SSPCON2, PEN	    ;PEN auto cleared by hardware when finished
    goto	$-1
    ;call	waitMSSP
    retlw	0
    
;Send RESTART condition and wait for it to complete
I2Crestart
    banksel	SSPCON2
    bsf		SSPCON2, RSEN
    btfsc	SSPCON2, RSEN	    ;RSEN auto cleared by hardware when finished
    goto	$-1
    ;call	waitMSSP
    retlw	0
    
;I2C wait routine   
waitMSSP
    banksel	SSPSTAT
    btfsc	SSPSTAT, 2	;(1=transmit in progress, 0=no trans in progress
    goto	$-1		;trans in progress so wait
    banksel	SSPCON2
    movfw	SSPCON2		;get copy of SSPCON2
    andlw	b'00011111'	;mask out bits that specify something going on
				;ACEKN, RCEN, PEN, RSEN, SEN = 1 then wait
    btfss	STATUS, Z	;0=all good, proceed
    goto	$-3		;1=not done doing something so retest and wait
    retlw	0
    
    ;Send ACK to slave (master is in receive mode)
sendACK
    banksel	SSPCON2
    bcf		SSPCON2, ACKDT  ;(0=ACK will be sent)
    bsf		SSPCON2, ACKEN	;(ACK is now sent)
    call	waitMSSP
    retlw	0
    
;Send NACK to slave (master is in receive mode)
sendNACK
    banksel	SSPCON2
    bsf		SSPCON2, ACKDT  ;(1=NACK will be sent)
    bsf		SSPCON2, ACKEN	;(NACK is now sent)
    btfsc	SSPCON2, ACKEN	;ACKEN cleared by hardware once ACK/NACK sent
    goto	$-1
    ;call	waitMSSP
    retlw	0
    
;Enable Receive Mode
enReceive
    banksel	SSPCON2
    bsf		SSPCON2, RCEN
    btfss	SSPCON2, RCEN
    goto	$-1
    call	waitMSSP
    retlw	0
    
;I2C failure routine
I2CFail
    banksel	SSPCON2
    bsf		SSPCON2, PEN	;Send stop condition
    call	waitMSSP
    retlw	0
    
    ;Send a byte of (command or data) via I2C    
sendI2Cbyte
    banksel	SSPBUF
    movwf	SSPBUF		;byte is already in work register
    banksel	SSPSTAT
    btfsc	SSPSTAT, 2	;wait till buffer is full (when RW=1=transfer complete)
    goto	$-1		;not full, wait here
    call	waitMSSP
    retlw	0
    
;Write to slave device    
I2Csend;checking of ACK status giving problems after giving slave command to perform ADC read
    banksel	SSPCON2
    bsf		SSPCON2, ACKSTAT    ;set ACKSTAT (1=ACK not received)
    ;Send data and check for error, wait for it to complete
    banksel	i2cByteToSend
    movfw	i2cByteToSend
    call	sendI2Cbyte	    ;load data into buffer
    banksel	SSPCON2
    btfsc	SSPCON2, ACKSTAT    ;ACKSTAT=1 if ACK not received from slave
    goto	$-1	            ;ACK not received
    retlw	0  
    
;***************Receive 16 bit values from slave device*************************
twoByteReceive
    ;MSByte
    call	sendACK
    call	enReceive
    call	waitMSSP
    banksel	SSPBUF
    movfw	SSPBUF
    banksel	coeffCPY+1
    movwf	coeffCPY+1
    ;LSByte
    call	sendACK
    call	enReceive
    call	waitMSSP
    banksel	SSPBUF
    movfw	SSPBUF
    banksel	coeffCPY
    movwf	coeffCPY
    call	sendNACK
    call	I2CStop
    retlw	0
;********************End twoByteReceive Routine*********************************
    
;****************Receive 24 bit values from slave device************************
threeByteReceive
    ;MSByte
    call	sendACK
    call	enReceive
    call	waitMSSP
    banksel	SSPBUF
    movfw	SSPBUF
    banksel	adcCPY+2
    movwf	adcCPY+2
    ;2nd byte
    call	sendACK
    call	enReceive
    banksel	SSPCON2
    call	waitMSSP
    banksel	SSPBUF
    movfw	SSPBUF
    banksel	adcCPY+1
    movwf	adcCPY+1
    ;LSByte
    call	sendACK
    call	enReceive
    call	waitMSSP
    banksel	SSPBUF
    movfw	SSPBUF
    banksel	adcCPY
    movwf	adcCPY
    call	sendNACK
    call	I2CStop
    retlw	0
;***********************End threeByteReceive Routine****************************
   
    END



