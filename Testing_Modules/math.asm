;Math routines
    ;LCD Routines


    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
    
    global  getTemp
	
    extern	sixByteNum
    extern	Tref    ;C5
    extern	D2
    extern	deeT
    extern	sendData
    extern	loopCount
    extern	delayMillis
	extern	product16
	extern	mCand16
    
.math code
mul16
    movlw	.16			;loop through 32 times 
    banksel	loopCount
    movwf	loopCount
;Multiplier occupies the lower 2 bytes of the product register and its lsb acts 
;as the control mechanism
;1) Check the lsb of product register (multiplier)
checkLsb
	btfss	product16, 0		;lsb=1?
	goto	shiftProduct	    ;No so proceed to shift the product register
	;lsb=1 so add multiplicand to left-half of product register and place result
	;in left half of product register
	banksel	mCand16
	movfw	mCand16
	addwf	product16+2, f	     ;Add LSB of multiplicand to 3rd byte of product
	movfw	mCand16+1
	btfsc	STATUS, C		     ;increment 4th byte of product if carry from addition
	incfsz	mCand16+1, w
	addwf	product16+3			;Add 2nd byte of multiplicanf to 4th byte of product
;2)Shift the product register right one bit
shiftProduct
	;1st Byte
	bcf		STATUS, C			;Clear carry
	rrf		product16, f		;right shift 1st byte
	;2nd Byte
	bcf		STATUS, C
	rrf		product16+1, f		;right shift 2nd byte
	btfsc	STATUS, C			;Carry due to right shift of 2nd byte?
	bsf		product16, 7		;Yes so shift that bit into byte 1
	;3rd Byte
	bcf		STATUS, C			;Clear carry
	rrf		product16+2			;right shift 3rd byte
	btfsc	STATUS, C			;Carry due to right shift of 3rd byte?
	bsf		product16+1, 7		;Yes so shift that bit into byte 2
	;4th Byte
	bcf		STATUS, C			;Clear carry
	rrf		product16+3			;right shift 4th byte
	btfsc	STATUS, C			;Carry due to right shift of 4th byte?
	bsf		product16+2, 7		;Yes so shift that bit into byte 3
	
decrement    
	
	movfw	product16+3
	banksel	PORTD
	movwf	PORTD
	movlw	.255
	call	delayMillis
	movlw	.255
	call	delayMillis
	
	
	
	
    ;decrement loop counter
    decfsz	loopCount, f
    goto	checkLsb	    ;reloop 32 times
    
    retlw	0
;**********************Get Temperature Data************************************* 
getTemp
    banksel	sixByteNum
    clrf	sixByteNum+5
    clrf	sixByteNum+4
    clrf	sixByteNum+3
    clrf	sixByteNum+2
    clrf	sixByteNum+1
    clrf	sixByteNum
    clrf	deeT+3
    clrf	deeT+2
    clrf	deeT+1
    clrf	deeT
	clrf	product16
	clrf	product16+1
	clrf	product16+2
	clrf	product16+3
    
    banksel	PORTD
    clrf	PORTD

;multiply sixByteNum (2^8 = 256, 16 bit number) by Tref (C5) (C5=16 bit number)
    ;1)Place multiplier (Tref) into lower 2 bytes of product register
	banksel	Tref
	movfw	Tref
	movwf	product16
	movfw	Tref+1
	movwf	product16+1
	;2)Place 256 into multiplicand
	movlw	.1
	movwf	mCand16+1
	clrf	mCand16
    
    pagesel	mul16
    call	mul16
    pagesel$
    
wer
    
    goto	wer
    
    ;place value of D2 (3 bytes) into deeT (dT=4 bytes signed)
    
 
 retlw	0
    
    
    
    
    END


