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
    extern	dtMulProduct
    extern	TEMPSENS
    
.math code
;****************Multiply two 16 bit numbers (unsigned)************************************
mul16
    movlw	.16			;loop through 16 times 
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
    addwf	product16+3			;Add 2nd byte of multiplicand to 4th byte of product
;2)Shift the product register right one bit
shiftProduct
    ;1st Byte
    bcf		STATUS, C		;Clear carry
    rrf		product16, f		;right shift 1st byte
    ;2nd Byte
    bcf		STATUS, C		;Clear carry
    rrf		product16+1, f		;right shift 2nd byte
    btfsc	STATUS, C		;Carry due to right shift of 2nd byte?
    bsf		product16, 7		;Yes so shift that bit into byte 1
    ;3rd Byte
    bcf		STATUS, C		;Clear carry
    rrf		product16+2		;right shift 3rd byte
    btfsc	STATUS, C		;Carry due to right shift of 3rd byte?
    bsf		product16+1, 7		;Yes so shift that bit into byte 2
    ;4th Byte
    bcf		STATUS, C		;Clear carry
    rrf		product16+3		;right shift 4th byte
    btfsc	STATUS, C		;Carry due to right shift of 4th byte?
    bsf		product16+2, 7		;Yes so shift that bit into byte 3
decrement    
    ;decrement loop counter
    decfsz	loopCount, f
    goto	checkLsb	    ;reloop 16 times
    retlw	0
;***********************End mul16 subroutine************************************
;*******Multiply dt (4 byte number) by C6/TEMPSENS (2 byte number)**************
    
dtMul
    movlw	.16			;loop through 16 times 
    banksel	loopCount
    movwf	loopCount
    ;Multiplier occupies the lower 2 bytes of the product register (dtMulProduct=6 bytes) 
    ;and its lsb acts as the control mechanism
    ;1) Check the lsb of dtMulProduct register (multiplier=TEMPSENS)
    banksel	dtMulProduct
checkLsb2
    btfss	dtMulProduct, 0		;lsb=1?
    goto	shiftProduct2	    ;No so proceed to shift the product register   
    ;lsb=1 so add multiplicand (deeT=4 bytes) to left-half of dtMulProduct register and 
    ;place result in left half of dtMulProduct register
    banksel	deeT
    movfw	deeT
    addwf	dtMulProduct+2, f  ;Add LSB of multiplicand to 3rd byte of product
    
    movfw	deeT+1
    btfsc	STATUS, C	   ;increment 4th byte of product if carry from addition
    incfsz	deeT+1, w
    addwf	dtMulProduct+3, f  ;Add 2nd byte of multiplicand to 4th byte of product
    
    movfw	deeT+2
    btfsc	STATUS, C	   ;increment 5th byte of product if carry from addition
    incfsz	deeT+2, w
    addwf	dtMulProduct+4, f  ;Add 3rd byte of multiplicand to 4th byte of product
    
    movfw	deeT+3
    btfsc	STATUS, C	   ;increment 6th byte of product if carry from addition
    incfsz	deeT+3, w
    addwf	dtMulProduct+5, f  ;Add 3rd byte of multiplicand to 4th byte of product
    
    ;2)Shift the product register right one bit
shiftProduct2
    ;1st Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct, f		;right shift 1st byte
    ;2nd Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct+1, f	;right shift 2nd byte
    btfsc	STATUS, C		;Carry due to right shift of 2nd byte?
    bsf		dtMulProduct, 7		;Yes so shift that bit into byte 1
    ;3rd Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct+2, f	;right shift 3rd byte
    btfsc	STATUS, C		;Carry due to right shift of 3rd byte?
    bsf		dtMulProduct+1, 7	;Yes so shift that bit into byte 2
    ;4th Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct+3, f	;right shift 4th byte
    btfsc	STATUS, C		;Carry due to right shift of 4th byte?
    bsf		dtMulProduct+2, 7	;Yes so shift that bit into byte 3
    ;5th Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct+4, f	;right shift 5th byte
    btfsc	STATUS, C		;Carry due to right shift of 5th byte?
    bsf		dtMulProduct+3, 7	;Yes so shift that bit into byte 4
    ;6th Byte
    bcf		STATUS, C		;Clear carry
    rrf		dtMulProduct+5, f	;right shift 6th byte
    btfsc	STATUS, C		;Carry due to right shift of 5th byte?
    bsf		dtMulProduct+4, 7	;Yes so shift that bit into byte 5
decrement2    
    ;decrement loop counter
    decfsz	loopCount, f
    goto	checkLsb2	    ;reloop 16 times    
    
    retlw	0
    
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
    clrf	dtMulProduct
    clrf	dtMulProduct+1
    clrf	dtMulProduct+2
    clrf	dtMulProduct+3
    clrf	dtMulProduct+4
    clrf	dtMulProduct+5
    
    banksel	PORTD
    clrf	PORTD

    ;multiply Tref/C5 (C5=16 bit number) by (2^8 = 256, 16 bit number)
    ;1) Place multiplier (Tref) into lower 2 bytes of product register
    banksel	Tref
    movfw	Tref
    movwf	product16
    movfw	Tref+1
    movwf	product16+1
    ;2) Place 256 into multiplicand
    movlw	.1
    movwf	mCand16+1
    clrf	mCand16
    
    pagesel	mul16
    call	mul16
    pagesel$
    
    ;Get dT (4 bytes) by subtracting product16 (4 bytes) from D2 (3 bytes)
    ;Place D2 in dT
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
    
    ;Multiply deeT (dT) by TEMPSENS (C6)
    ;1) Place multiplier (TEMPSENS) into lower 2 bytes of dtMulProduct register
    banksel	TEMPSENS
    movfw	TEMPSENS
    movwf	dtMulProduct
    movfw	TEMPSENS+1
    movwf	dtMulProduct+1
    ;2) deeT (dT) is the multiplicand
    call	dtMul
    
    banksel	dtMulProduct
    movfw	dtMulProduct+3
    banksel	PORTD
    movwf	PORTD
    
wer
    
    goto	wer
    
    
    
 
 retlw	0
    
    
    
    
    END


