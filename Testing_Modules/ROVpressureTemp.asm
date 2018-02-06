;Test use of I2C module for PIC16F1937

    list		p=16f1937	;list directive to define processor
    #include		<p16f1937.inc>		; processor specific variable definitions
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
	
    #define BANK0            (h'000')
    #define BANK1            (h'080')
    #define BANK2	     (h'100')
    #define BANK3	     (h'180')
    ;Commands for Temp/Pressure Module
    #define convertT	     (d'72')    ;start 12 bit Temperature conversion
    #define convertP	     (d'88')    ;start 12 bit Pressure conversion
    #define ADCread	     (d'0')	    ;Read out ADC result
    #define deviceAddrWrite  (b'11101100')
    #define deviceAddrRead   (b'11101101')
    #define deviceReset	     (d'30')
    
    global	delayMillis
    global	Tref	;C5
    global	TEMPSENS
    global	D2
    global	sixByteNum
    global	deeT
    global	loopCount
	global	product16
	global	mCand16
    
    extern  displayHeaders
    extern  LCDInit
    extern  getTemp
	
	
    __CONFIG _CONFIG1,    _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _WDTE_OFF & _PWRTE_ON & _FOSC_XT & _FCMEN_OFF & _IESO_OFF

;Context saving variables:
CONTEXT		    UDATA_SHR
w_temp		    RES	    1	; variable used for context saving
status_temp	    RES	    1	; variable used for context saving
pclath_temp	    RES	    1

;General Variables
GENVAR		    UDATA_SHR
cnt1Millis	    RES	    1
userMillis	    RES	    1

	   
;Non-shared variables
GENVAR1		    UDATA
SENS		    RES	    2	;Pressure Secnsitivity (2 bytes) from PROM
OFF				RES	    2	;Pressure Offset (2 bytes) from PROM
TCS				RES	    2	;Temp coeff of pressure sensitivity (2 bytes) from PROM
TCO				RES	    2	;Temp coeff of pressure offset (2 bytes) from PROM
Tref		    RES	    2	;Reference temperature (2 bytes) from PROM
TEMPSENS	    RES	    2	;Temp coeff of temperature (2 bytes) from PROM	
i2cByteToSend	RES	    1
D1				RES	    3	;Pressure value from ADC read of slave (3 bytes)
D2				RES	    3	;Temperature value from ADC read of slave (3 bytes)
coeffCPY	    RES	    2	;shadow register for copying PROM coefficients
adcCPY		    RES	    3	;shadow register for copying temp/press ADC values
tOrP		    RES	    1	;flag used to determine whether we read temp
							;or pressure data (0=pressure, 1=temperature)
sixByteNum	    RES		6
deeT		    RES		4   ;dT=signed 32 bit int
loopCount	    RES		1   ;counter for multiplication loops
product16		RES		4	;Holds both 16bit multiplier (lower 2 bytes)
							;and product for 16x16 multiplication routine.
							;lsb of product16= lsb of multiplier = control for 
							;multiplication routine
mCand16			RES		2	;16 bit multiplicand for 16x16 	multiplication routine						

;**********************************************************************
    ORG		0x000	
    pagesel		start	; processor reset vector
    goto		start	; go to beginning of program
INT_VECTOR:
    ORG		0x004		; interrupt vector location
INTERRUPT:
;******************************SUBROUTINES**************************************
;variable length mllisecond delay (number of millis needed is already in work register)
delayMillis
    movwf	userMillis	;user defined number of milliseconds
startDly
    banksel	TMR0
    clrf	TMR0
waitTmr0
    movfw	TMR0
    xorlw	.125		;125 * 8uS = 1mS
    btfss	STATUS, Z
    goto	waitTmr0
    decfsz	userMillis, f	;reached user defined milliseconds yet?
    goto	startDly
    
    retlw	0
;***************************I2C subroutines*************************************
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
    retlw	0                   ;ACK received, exit
;Receive 16 bit values from slave device
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
;Receive 24 bit values from slave device
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
    
sensorData
;*************Get ADC value for temp or press conversion from slave*************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Give slave command for 12 bit uncompensated Temp (D2) or Pressure (D1) conversion
    banksel	tOrP
    btfss	tOrP, 0	    ;0=pressure, 1=temperature
    goto	pressure
temperature
    movlw	.88	    ;cmd for 12 bit temp conv.
    goto	getData
pressure
    movlw	.72
getData
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend	
    call	I2CStop
    ;wait 18 mS for conversion to complete
    movlw	.18
    call	delayMillis
    ;write command
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    
    ;Give slave command to perform ADC read
    movlw	b'00000000'	    ;cmd for ADC read
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    
    call	I2CStop
    ;read command
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend	
    call	threeByteReceive    ;receive temp (D2) data
    
    retlw	0

start:

    banksel BANK1
    ;Set PORTS to output
    movlw   b'00000000'		     
    movwf   (TRISA ^ BANK1)
    movlw   b'00000000'
    movwf   (TRISB ^ BANK1)
    movlw   b'00011000'
	     ;---11---		:I2C, SDA and SCL as inputs
    movwf   (TRISC ^ BANK1)
    movlw   b'00000000'
    movwf   (TRISD ^ BANK1)
    movlw   b'00000000'
    movwf   (TRISE ^ BANK1)
    
    banksel ANSELA
    movlw   b'00000000'
    movwf   ANSELA
    clrf    ANSELB                    
    clrf    ANSELD
    clrf    ANSELE
  
    movlw   b'01101000'
    banksel OSCCON
    movwf   OSCCON
   
;************************Configure timer************************************
    ;With 4Mhz external crystal, FOSC is not divided by 4.
    ;Therefore each instruction is 1/4 of a microsecond (250*10^-9 sec.)
    movlw	b'11000100'	
		 ;1-------	WPUEN=0, all weak pull-ups are disabled
		 ;-1------	INTEDG=1, Interrupt on rising edge of INT pin
		 ;--0-----	TMR0CS=0, TMR0 clock source=internal instruction
			        ;	  (FOSC/4)
		 ;---0----	;TMR0SE=0, disregard
		 ;----0---	;PSA=0, prescaler assigned to TMR0 module
		 ;-----100	;PS<2:0> = 00, TMRO increments once every 32
				;instruction cycles 
				;Every instruction cycle is 250*10^-9 sec (4Mhz), 
				;therefore TMR0 increments once every 32 * 250*10^-9 sec
				;or once every 8uS
    banksel	OPTION_REG	
    movwf	OPTION_REG
    
    ;4Mhz external crystal:
    movlw	b'00000000'
    banksel	OSCCON
    movwf	OSCCON
    ;*********************Configure I2C*****************************************
    movlw	.255	;SCL pin clock period=FOSC/(4*(SSPADD+1))
				;SSPADD=103.
				;Baud=(4*10^6) / (4*(103+1)) = 9600 bps
    banksel	SSPADD
    movwf	SSPADD
    
    movlw	b'00101000'
		 ;-0------	;SSPOV=receive overflow indicator (read data in 
				;sspbuf before new data comes in to prevent error.
				;Check and clear to ensure sspbuf can be updated
		 ;--1-----	;SSPEN=1 (Enable I2C serial port)
		 ;----1000	;1000 = I2C Master Mode. 
				;Clock=FOSC/(4*(SSPADD+1))
    banksel	SSPCON1
    movwf	SSPCON1
    
    movlw	b'10000000'
		 ;1-------	'SMP=1, data sampled at end of data output time
				;slew rate control in 100kHz mode
    banksel	SSPSTAT
    movwf	SSPSTAT
    
    clrf	cnt1Millis	
    clrf	userMillis
    banksel	PORTD
    clrf	PORTD
    movlw	.10
    call	delayMillis
    call	LCDInit
;Reset sequence for slave device
slaveReset
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for device write
    
    movlw	deviceReset	    ;command for device reset
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for device reset
    call	I2CStop		    ;send stop condition
    
;Get PROM Coefficients
    ;*********************SENS (C1)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    
    ;Send address to be read
    movlw	.160		    ;addr for SENS (C1)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read SENS (C1)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into SENS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	SENS+1
    movfw	coeffCPY	    ;low bytes
    movwf	SENS
    ;*********************OFF (C2)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Send address to be read
    movlw	.162		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read OFF (C2)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into OFF
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	OFF+1
    movfw	coeffCPY	    ;low bytes
    movwf	OFF
    ;*********************TCS (C3)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Send address to be read
    movlw	.164		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read TCS (C3)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into TCS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TCS+1
    movfw	coeffCPY	    ;low bytes
    movwf	TCS
    ;*********************TCO (C4)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Send address to be read
    movlw	.166		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read TCO (C4)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into TCO
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TCO+1
    movfw	coeffCPY	    ;low bytes
    movwf	TCO
    ;*********************Tref (C5)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Send address to be read
    movlw	.168		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read Tref (C5)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into Tref
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	Tref+1
    movfw	coeffCPY	    ;low bytes
    movwf	Tref
    ;*********************TEMPSENS (C6)*********************************************
    call	I2Cstart
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend
    ;Send address to be read
    movlw	.170		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	I2CStop
    ;read TEMPSENS (C6)
    call	I2Cstart
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    call	I2Csend		    ;send command for PROM read
    call	twoByteReceive	    ;receive SENS (C1) data
    ;place coeffCPY into TEMPSENS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TEMPSENS+1
    movfw	coeffCPY	    ;low bytes
    movwf	TEMPSENS
;*******************Done getting PROM coefficients******************************    
;******************Get ADC values for temp and press****************************
    banksel	tOrP
    clrf	tOrP
    ;First get temperature
    banksel	tOrP
    bsf		tOrP, 0		    ;1=temperature ADC reading
    call	sensorData	    ;perform temperature reading
    ;place result of temperature ADC read into D2
    banksel	adcCPY+2
    movfw	adcCPY+2	    ;MSBytes
    movwf	D2+2
    movfw	adcCPY+1
    movwf	D2+1
    movfw	adcCPY
    movwf	D2
    banksel	tOrP
    clrf	tOrP		    ;0=Pressure ADC reading
    call	sensorData	    ;perform pressure reading
    
    ;place result of pressure ADC read into D1
    banksel	adcCPY+2
    movfw	adcCPY+2	    ;MSBytes
    movwf	D1+2
    movfw	adcCPY+1
    movwf	D1+1
    movfw	adcCPY
    movwf	D1
    
    ;display "Temp:" and "Press:" headers on LCD
    call	displayHeaders
    pagesel	getTemp
    call	getTemp
    pagesel$
mainLoop
    
finito
    goto    finito
    END                       




















