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
    #define baudRate (d'250') ;baudrate = 10 (10 bps)
			     ;set BRG16 bit of BAUDCON register

    __CONFIG _CONFIG1,    _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _WDTE_OFF & _PWRTE_ON & _FOSC_HS & _FCMEN_OFF & _IESO_OFF

;Context saving variables:
CONTEXT	UDATA_SHR
userMillis	RES	1
w_copy		RES     1	;variable used for context saving (work reg)
status_copy	RES     1	;variable used for context saving (status reg)
pclath_copy	RES     1	;variable used for context saving (pclath copy)
transData	RES	1	;Data to be transmitted via UART
receiveData	RES	1	;Data received via UART
positionSpeed	RES	1	;thruster speed (Default max-reverse)
				;1.1mS (CCPR1L = 70)
adcCounter	RES	1	;counter to be increented till value in
				;ADRESH is reached
ADRESHc		RES	1	;copy of ADRESH
compCounter	RES	1	;counter to be incremented once every 6 servo
				;steps to give full range of motion
motorTemp	RES	1
ADRESH0		RES	1	;copy of value from pin AN0
ADRESH1		RES	1	;copy of value from pin AN1
ADRESH2		RES	1	;copy of value from pin AN2
AN0disp		RES	1	;displacement of ADRESHO from 127
AN1disp		RES	1	;displacement of ADRESH1 from 127

;General Variables
GENVAR	UDATA
dly16Ctr	RES	1
initCounter	RES	1	;used for calls to delayMillis to initialize ESC
thruster1	RES	1	;PWM value for thruster #1
thruster2	RES	1	;PWM value for thruster #2
thruster3	RES	1	;PWM value for thruster #3
thruster4	RES	1	;PWM value for thruster #4
thrusterUpDown	RES	1	;PWM value for up/down thrusters
UartReceiveCtr	RES	1	;counter for number of UART receptions

;**********************************************************************
    ORG		0x000	
    pagesel		start	; processor reset vector
    goto		start	; go to beginning of program
INT_VECTOR:
    ORG		0x004		; interrupt vector location
INTERRUPT:
	movwf   w_copy                      ; save off current W register contents
        movf    STATUS,w                    ; move status register into W register
        movwf   status_copy                 ; save off contents of STATUS register
        movf    PCLATH,W
        movwf   pclath_copy
	
	;Determine source of interrupt
	banksel	    PIR1
	btfsc	    PIR1, RCIF	    ;receive interrupt?
	goto	    UartReceive
	
UartReceive
	banksel	    PIR1
	bcf	    PIR1, RCIF
	call	    Receive
;test current value of counter and place data in correct thruster register
	;Test for thruster #1
	movlw	    .0
	banksel	    UartReceiveCtr
	xorwf	    UartReceiveCtr, w
	btfsc	    STATUS, Z
	goto	    thruster1Data
	
	;Test for thruster #2
	movlw	    b'00000001'
	banksel	    UartReceiveCtr
	xorwf	    UartReceiveCtr, w
	btfsc	    STATUS, Z
	goto	    thruster2Data
	
	;Test for thruster #3
	movlw	    b'00000010'
	banksel	    UartReceiveCtr
	xorwf	    UartReceiveCtr, w
	btfsc	    STATUS, Z
	goto	    thruster3Data
	
	;Test for thruster #4
	movlw	    b'00000011'
	banksel	    UartReceiveCtr
	xorwf	    UartReceiveCtr, w
	btfsc	    STATUS, Z
	goto	    thruster4Data
	
	;Test for Up/Down thrusters
	movlw	    b'00000100'
	banksel	    UartReceiveCtr
	xorwf	    UartReceiveCtr, w
	btfsc	    STATUS, Z
	goto	    upDownData
	
thruster1Data
	movfw	    receiveData
	banksel	    thruster1
	movwf	    thruster1
	banksel	    PORTB
	movwf	    PORTB
	banksel	    CCPR1L		;ESC #1
	movwf	    CCPR1L
	banksel	    UartReceiveCtr
	incf	    UartReceiveCtr, f
	goto	    isrEnd
	
thruster2Data
	movfw	    receiveData
	banksel	    thruster2
	movwf	    thruster2
	
	banksel	    UartReceiveCtr
	incf	    UartReceiveCtr, f
	goto	    isrEnd
	
thruster3Data
	movfw	    receiveData
	banksel	    thruster3
	movwf	    thruster3
	
	banksel	    UartReceiveCtr
	incf	    UartReceiveCtr, f
	goto	    isrEnd
	
thruster4Data
	movfw	    receiveData
	banksel	    thruster4
	movwf	    thruster4
	
	banksel	    UartReceiveCtr
	incf	    UartReceiveCtr, f
	goto	    isrEnd
	
upDownData
	movfw	    receiveData
	banksel	    thrusterUpDown
	movwf	    thrusterUpDown
	
	banksel	    UartReceiveCtr
	clrf	    UartReceiveCtr	;Clear out UART receiver counter
	
	;restore pre-ISR values to registers
isrEnd
	banksel	    PIR1
	bsf	    PIR1, RCIF
	movf    pclath_copy,W
        movwf   PCLATH
        movf    status_copy,w           ; retrieve copy of STATUS register
        movwf   STATUS                  ; restore pre-isr STATUS register contents
        swapf   w_copy,f
        swapf   w_copy,w                ; restore pre-isr W register contents
        retfie                          ; return from interrupt
	
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
	
    ;enable interrupts
    movlw	b'11001000'
	         ;1-------	;Enable global interrupts (GIE=1)
		 ;-1------	;Enable peripheral interrupts (PEIE=1)
		 ;--0-----	;Disable TMR0 interrupts (TMROIE=0)
		 ;---0----	;Disable RBO/INT external interrupt (INTE=1)
		 ;----1---	;Enable interrupt on change for PORTB (IOCIE=0)
    movwf	INTCON
    
    movlw	b'00110000'
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
    movwf	SPBRG	    ;Move 'X' to baurate generator
    
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
    banksel	UartReceiveCtr
    clrf	UartReceiveCtr
;*******************************************************************************
    movlw	.250
    movwf	motorTemp
    
    banksel	ANSELB
    clrf	ANSELB
    clrf	ANSELD
    clrf	ANSELE
    
    ;initialize ESC:
    call	ESCinit

mainLoop
    ;9th data bit = LSB of transmission:
    ;banksel	TXSTA
    ;bcf	TXSTA, TX9D
   
    
    
    goto	mainLoop
   
    END                       





























