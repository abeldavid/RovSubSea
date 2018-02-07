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
;****************Multiply two 16 bit numbers************************************
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
    ;decrement loop counter
    decfsz	loopCount, f
    goto	checkLsb	    ;reloop 32 times
    retlw	0
;***********************End mul16 subroutine************************************
    
;*********************Calculate dT**********************************************
;Get the variable "dT" by subtracting :product16" from "D2"
;D2 has already been placed in variable "deeT"
getDt
;1) Get the two's complement of product16 (low Byte)
    banksel	product16
    comf	product16, f
    incf	product16, f
    ;btfsc	STATUS, Z
    ;decf	product16+1, f
;2) add two's complement of product16 to deeT
    movfw	product16
    addwf	deeT, f
;3) Get the two's complement of product16+1 (2nd Byte)
    comf	product16+1, f
    incf	product16+1, f
    ;btfsc	STATUS, Z
    ;decf	product16+2, f
;4) add two's complement of product16+1 to deeT+1 (2nd Bytes)
    movfw	product16+1
    addwf	deeT+1, f
;5) Get the two's complement of product16+2 (3rd Byte)
    comf	product16+2, f
    incf	product16+2, f
;6) add two's complement of product16+2 to deeT+2 (3rd Bytes)
    movfw	product16+2
    addwf	deeT+2, f

    
    movfw	deeT+2
    banksel	PORTD
    movwf	PORTD
 
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
    
    ;Get dT (4 bytes) by subtracting product16 (4 bytes) from D2 (3 bytes)
    ;1) place D2 in dT
    banksel	D2
    movfw	D2
    movwf	deeT
    movfw	D2+1
    movwf	deeT+1
    movfw	D2+2
    movwf	deeT+2
    clrf	deeT+3
    pagesel	getDt
    call	getDt	    ;get variable "dT" by calculating D2-product16
    pagesel$
    
wer
    
    goto	wer
    
    
    
 
 retlw	0
    
    
    
    
    END


