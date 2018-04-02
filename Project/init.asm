;*********************INITILIZE PERIPHERALS*********************************
    
    list	    p=16f1937	   ;list directive to define processor
    #include        <p16f1937.inc> ;processor specific variable definitions
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
    extern  delayMillis
    extern  UartReceiveCtr
    extern  readyThrust
    extern  ESCinit
    
    global  peripheralInit
    
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    
    .initialization code
peripheralInit
    banksel BANK1
    ;Set PORTS to output
    movlw   b'00000000'		
    movwf   (TRISA ^ BANK1)
    movlw   b'00000000'		    
    movwf   (TRISB ^ BANK1)
    movlw   b'11011000'		;PORTC, 7 = RX pin for UART         
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
    
    movlw	.10
    pagesel	delayMillis
    call	delayMillis
    pagesel$
    
    ;initialize ESC:
    pagesel	ESCinit
    call	ESCinit
    pagesel$
    
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
    
    END