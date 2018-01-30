;Math routines
    ;LCD Routines


    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
    
    global  getTemp
	
    extern	sixByteNum
    extern  Tref    ;C5
	extern	D2
	extern	power
	extern	deeT
    
.math code
pow
	movlw		.2
	banksel		sixByteNum
	movwf		sixByteNum			;place 2 into sixByteNum
exp
	;right-shift all six bytes
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum, f
	btfsc		STATUS, C
	incf		sixByteNum+1, f
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum+1, f
	btfsc		STATUS, C
	incf		sixByteNum+2, f
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum+2, f		
	btfsc		STATUS, C
	incf		sixByteNum+3, f
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum+3, f
	btfsc		STATUS, C
	incf		sixByteNum+4, f
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum+4, f
	btfsc		STATUS, C
	incf		sixByteNum+5, f
	bcf			STATUS,C        ;clear carry
	rlf			sixByteNum+5, f
	
	decfsz		power, f			;do until power=0
	goto		exp					;continue exponentiating
    retlw   0
 
getTemp
    ;get 2^8
    movlw	.7
    banksel	power
    call	pow			;2^8 is now in variable sixByteNum
	;multiply sixByteNum (2^8) by Tref (C5)
	
	
	;place value of D2 (3 bytes) into deeT (dT=4 bytes signed)
	banksel	D2
	movfw	D2		;low byte
	movwf	deeT
	movfw	D2+1	;second byte
	movwf	deeT+1
	movfw	D2+2	;high byte
	movwf	deeT+2
    
 
 retlw	0
    
    
    
    
    END


