;Receive PWM values from topside via UART, decode packets and send PWM value to 
;appropriate thruster ESCs

    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
    
    extern  delayMillis
    extern  Transmit
    extern  Receive
    extern  processThrusterStream
    extern  ESCinit
    
    global  forwardSpeed
    global  reverseSpeed
    global  upDownSpeed
    global  transData
    global  receiveData
    global  state
    global  readyThrust
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')

    __CONFIG _CONFIG1,    _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _WDTE_OFF & _PWRTE_ON & _FOSC_HS & _FCMEN_OFF & _IESO_OFF

;Variables accessible in all banks:
MULTIBANK	UDATA_SHR
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
readyThrust	RES	1	;flag to be set when all 4 UART thruster data packets 
				;have been received
;General Variables
GENVAR		UDATA
UartReceiveCtr	RES	1	;counter for number of UART receptions

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
		; ------11          prescale = 64 (T2CKPS = 11)
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
    pagesel	delayMillis
    call	delayMillis
    pagesel$
    banksel	PORTB
    clrf	PORTB
    
    banksel	UartReceiveCtr
    clrf	UartReceiveCtr
    clrf	readyThrust
    
    ;initialize ESC:
    call	ESCinit
    
    ;*******************Enable interrupts***************************************
    movlw	b'11001000'
	         ;1-------	;Enable global interrupts (GIE=1)
		 ;-1------	;Enable peripheral interrupts (PEIE=1)
		 ;--0-----	;Disable TMR0 interrupts (TMROIE=0)
		 ;---0----	;Disable RBO/INT external interrupt (INTE=1)
		 ;----1---	;Enable interrupt on change for PORTB (IOCIE=0)
    movwf	INTCON
    
    ;Enable interrupt on change for PORTB
    movlw	b'00000001'	;PORTB,  pins set for IOC (rising edge)
		 ;-------1	Leak Detector
    banksel	IOCBP
    movwf	IOCBP
    
    banksel	ANSELB
    clrf	ANSELA
    clrf	ANSELB
    clrf	ANSELD
    clrf	ANSELE
    
mainLoop
    btfsc	readyThrust, 1
    call	processThrusterStream
    
    goto	mainLoop
   
    END                       































