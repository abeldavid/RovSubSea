;Variable length delay routine (1-255 milliseconds)
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    global      delayMillis
	
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
	
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    
;Variables accessible in all banks:
MULTIBANK	UDATA_SHR
userMillis	RES	1

.delay code
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
    
    END


