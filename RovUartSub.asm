;Receive PWM values from topside via UART, decode packets and send PWM value to 
;appropriate thruster ESCs

    list		p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')

    __CONFIG _CONFIG1,    _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _WDTE_OFF & _PWRTE_ON & _FOSC_HS & _FCMEN_OFF & _IESO_OFF

;Context saving variables:
CONTEXT	UDATA_SHR
userMillis	RES	1
w_copy		RES     1	;variable used for context saving (work reg)
status_copy	RES     1	;variable used for context saving (status reg)
pclath_copy	RES     1	;variable used for context saving (pclath copy)
transData	RES	1	;Data to be transmitted via UART
receiveData	RES	1	;Data received via UART
state		RES	1	;Direction "state" of ROV
forwardSpeed	RES	1	;value to be placed in CCPR1L
reverseSpeed	RES	1	;value to be placed in CCPR2L
upDownSpeed	RES	1	;value to be placed in CCPR3L
;General Variables
GENVAR	UDATA
initCounter	RES	1	;counter for initializing ESCs

;**********************************************************************
    ORG		0x000	
    pagesel		start	    ;processor reset vector
    goto		start	    ;go to beginning of program
INT_VECTOR:
    ORG		0x004		    ;interrupt vector location
INTERRUPT:
    movwf       w_copy           ;save off current W register contents
    movf	STATUS,w         ;move status register into W register
    movwf	status_copy      ;save off contents of STATUS register
    movf	PCLATH,W
    movwf       pclath_copy
	
    ;Determine source of interrupt
    banksel	PIR1
    btfsc	PIR1, RCIF	    ;receive interrupt?
    goto	UartReceive
	
UartReceive
    banksel	PIE1
    bcf		PIE1, RCIE	    ;disable UART receive interrupts
    call	Receive
    
    ;Get "state" of ROV direction signal
    ;Make sure UART packet contains a valid value for "state"
    movlw	.9		;max number for state = 8
    subwf	receiveData, w  ;subtract 9 from value in UART packet
    btfss       STATUS, C	;(C=0 is neg #) (valid result = neg #)
    goto	stateData       ;packet contains a valid value for "state"
	
    ;Get forward speed
    movlw	.95	        ;min number for forwardData=95 (for this purpose)
    subwf	receiveData, w  ;subtract 95 from value in UART packet
    btfsc	STATUS, C	;(C=0 is neg #) (valid result = pos #)
    goto	forwardData
	
    ;Get reverse speed
    movlw	.95		;min number for reverseData=95 (for this purpose)
    subwf	receiveData, w  ;subtract 95 from value in UART packet
    btfss	STATUS, C	;(C=0 is neg #) (valid result = neg #)
    goto	reverseData
	
    ;Get up/down speed
    
    goto	upDownData
	
stateData
    movfw	receiveData
    movwf	state
    goto	isrEnd
	
forwardData
    movfw	receiveData
    movwf	forwardSpeed
    goto	isrEnd
	
reverseData
    movfw	receiveData
    movwf	reverseSpeed
    goto	isrEnd
	
upDownData
    movfw	receiveData
    movwf	upDownSpeed
    ;call	processThrusterStream
	
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
    
processThrusterStream
    ;check state of direction signal
    ;check for forward state
    movlw	.1
    xorwf	state, w
    btfsc	STATUS, Z
    goto	forward
    ;check for reverse state
    movlw	.2
    xorwf	state, w
    btfsc	STATUS, Z
    goto	reverse
    ;check for traverse right state
    movlw	.3
    xorwf	state, w
    btfsc	STATUS, Z
    goto	traverseRight
    ;check for traverse left state
    movlw	.4
    xorwf	state, w
    btfsc	STATUS, Z
    goto	traverseLeft
    ;check for clockwise rotation state
    movlw	.5
    xorwf	state, w
    btfsc	STATUS, Z
    goto	clockwise
    ;check for counter-clockwise rotation state
    movlw	.6
    xorwf	state, w
    btfsc	STATUS, Z
    goto	counterClockwise
    ;check for up/down state
    movlw	.7
    xorwf	state, w
    btfsc	STATUS, Z
    goto	upDown
    ;check for stopped state
    movlw	.8
    xorwf	state, w
    btfsc	STATUS, Z
    goto	stop
    
forward
    movlw	b'11000011'
		 ;----0011	;AND thrusters 1/2 on FWD logic IC (CCPR1L/P1A)
		 ;1100----	;AND thrusters 3/4 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
reverse
    movlw	b'00111100'
		 ;----1100	;AND thrusters 3/4 on FWD logic IC (CCPR1L/P1A)
		 ;0011----	;AND thrusters 1/2 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
traverseRight
    movlw	b'10100101'	
		 ;----0101	;AND thrusters 1/3 on FWD logic IC (CCPR1L/P1A)
		 ;1010----	;AND thrusters 2/4 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
traverseLeft
    movlw	b'01011010'
		 ;----1010	;AND thrusters 2/4 on FWD logic IC (CCPR1L/P1A)
		 ;0101----	;AND thrusters 1/3 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
counterClockwise
    movlw	b'10010110'
		 ;----0110	;AND thrusters 2/3 on FWD logic IC (CCPR1L/P1A)
		 ;1001----	;AND thrusters 1/4 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
clockwise
    movlw	b'01101001'	
		 ;----1001	;AND thrusters 1/4 on FWD logic IC (CCPR1L/P1A)
		 ;0110----	;AND thrusters 2/3 on REV logic IC (CCPR2L/P2A)
    banksel	PORTD
    movwf	PORTD
    goto	values
upDown
    banksel	PORTD
    movlw	b'00001111'	;stop all horizontal movement
    goto	values
stop
    movlw	b'00001111'
    banksel	PORTD
    movwf	PORTD
    goto	values
values
    movfw	forwardSpeed
    banksel	CCPR1L
    movwf	CCPR1L
    movfw	reverseSpeed
    banksel	CCPR2L
    movwf	CCPR2L
    movfw	upDownSpeed		;stop up/down thrusters
    banksel	CCPR3L
    movwf	CCPR3L
    retlw	0
	
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
    
;Initialize ESCs with stoped signal (1500uS) for four seconds
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
    retlw	0
	
;*************************UART SUBROUTINES**************************************
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
    banksel	    PIR1
    bcf	            PIR1, RCIF	    ;clear UART receive interrupt flag
    banksel	RCSTA
    bsf		RCSTA, CREN
    retlw	0
    
    
;*************************END UART SUBROUTINES**********************************
	
start:
    banksel BANK1
    ;Set PORTS to output
    movlw   b'00000000'		
    movwf   (TRISA ^ BANK1)
    movlw   b'00000000'		    
    movwf   (TRISB ^ BANK1)
    movlw   b'11000000'		;PORTC, 7 = RX pin for UART         
    movwf   (TRISC ^ BANK1)
    movlw   b'00000000'
    movwf   (TRISD ^ BANK1)	    
    movlw   b'00000000'
    movwf   (TRISE ^ BANK1)
    
    ;Configure timer
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
    
    movlw	b'00100000'
		 ;--1-----	;Enable USART receive interrupt (RCIE=1)
    banksel	PIE1
    movwf	PIE1
    
    ;4Mhz external crystal:
    movlw	b'00000000'
    banksel	OSCCON
    movwf	OSCCON
    
;***************Configure PWM***********************************************
    movlw	b'00000111'     ; configure Timer2:
		; -----1--          turn Timer2 on (TMR2ON = 1)
		; ------10          prescale = 16 (T2CKPS = 10)
    banksel	T2CON           ; -> TMR2 increments every 16 us
    movwf	T2CON
    movlw	.250            ; PR2 = 250
    banksel	PR2             ; -> period = 250*16uS=4mS
    movwf	PR2             ; -> PWM frequency = 250 Hz
    ;Configure CCP1, CCP2 and CCP3 to be based off of TMR2:
    banksel	CCPTMRS0
    movlw	b'11000000'
		 ;--00----	;CCP3 based off of TMR2
		 ;----00--	;CCP2 based off of TMR2
		 ;------00	;CCP1 based off of TMR2
    movwf	CCPTMRS0	    
    ;configure CCP1, CCP2 and CCP3:
    movlw	b'00001100'     
		; 00------          single output (P1M = 00 -> CCP1 active)
		; --00----          DC1B = 00 -> LSBs of PWM duty cycle = 00
		; ----1100          PWM mode: all active-high (CCP1M = 1100)
    banksel	CCP1CON         ; -> single output (CCP1) mode, active-high
    movwf	CCP1CON
    banksel	CCP2CON
    movwf	CCP2CON
    banksel	CCP3CON
    movwf	CCP3CON
    
    ;initialize ESC:
    call	ESCinit
    
;******************************CONFIGURE UART:**********************************
    ;Configure Baud rate
    movlw	b'01000000' 
    banksel	SPBRG
    movwf	SPBRG	    
    
    movlw	b'00000011'
    banksel	SPBRGH
    movwf	SPBRGH
    
    banksel	BAUDCON
    movlw	b'00001000'
		 ;----1---	BRG16 (16 bit baud rate generator)
    movwf	BAUDCON
    
    ;Enable Transmission:
    movlw	b'00100000'
		 ;-0------  :8-bit transmission (TX9 = 0)
		 ;--1-----  :Enable transmission (TXEN = 1)
		 ;---0----  :Asynchronous mode (SYNC = 0)
		 ;-----0--  :Low speed baud rate (BRGH = 0)
    banksel	TXSTA
    movwf	TXSTA
		 
    ;Enable Reception:
    movlw	b'10010000'
		 ;1-------  :Serial port enabled (SPEN = 1)
		 ;-0------  :8-bit reception (RX9 = 0)
		 ;---1----  :Enable receiver (CREN = 1)
		 ;----0---  :Disable address detection (ADDEN = 0)
    ;			     all bytes are received and 9th bit can be used as
    ;			     parity bit
    banksel	RCSTA
    movwf	RCSTA
    movlw	d'20'
    call	delayMillis
    banksel	PORTB
    clrf	PORTB
    
    ;enable interrupts
    movlw	b'11001000'
	         ;1-------	;Enable global interrupts (GIE=1)
		 ;-1------	;Enable peripheral interrupts (PEIE=1)
		 ;--0-----	;Disable TMR0 interrupts (TMROIE=0)
		 ;---0----	;Disable RBO/INT external interrupt (INTE=1)
		 ;----1---	;Enable interrupt on change for PORTB (IOCIE=0)
    movwf	INTCON
    
;*******************************************************************************

    banksel	ANSELB
    clrf	ANSELA
    clrf	ANSELB
    clrf	ANSELD
    clrf	ANSELE
    
    ;initial "state" is stopped
    ;movlw	.8
    ;movwf	state

mainLoop
    call	processThrusterStream
    goto	mainLoop
   
    END                       






























