;Math routines
    ;LCD Routines


    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
    
    global  getTemp
	
    extern  deeT		;32 bit signed
    extern  product32	;64 bit
    extern  mpcand32	;32 bit
    extern  Tref		;16 bit
    extern  loopCount	;8 bit
    extern  D2			;24 bit
    extern  negFlag		;bit 0 of this is set if operation results in neg number
	extern	TEMPSENS	;C6
    
.math code
mul32
;******************Multiply 2 unsigned 32 bit numbers***************************
;At beginning of routine,  product32 contains following:
;[-----upper 4 bytes------][-------lower 4 bytes----------]
;[---------zero-----------][------32 bit multiplier-------]
;		           [bit 0 of multiplier is control mechanism]
testLsb
    ; 1) Test Lsb of multiplier (also lsb of product32
    btfss   product32, 0
    goto    mulShift	    ;lsb=0 so proceed to shift
addMpcand		    ;lsb=1 so add mpcand32 to left 1/2 of product32
    ;1st Bytes
    banksel mpcand32
    movfw   mpcand32
    addwf   product32+4	    ;Add byte #0 of mpcand32 to byte #4 of product32
    ;2nd bytes
    movfw   mpcand32+1
    btfsc   STATUS, C
    incfsz  mpcand32+1, w   ;Increment byte #5 of product32 if carry from last addition
    addwf   product32+5	    ;Add byte #1 of mpcan32 to byte #5 of product32
    ;3rd bytes
    movfw   mpcand32+2
    btfsc   STATUS, C
    incfsz  mpcand32+2, w   ;Increment byte #6 of product32 if carry from last addition
    addwf   product32+6	    ;Add byte #2 of mpcan32 to byte #6 of product32
    ;4th bytes
    movfw   mpcand32+3
    btfsc   STATUS, C
    incfsz  mpcand32+3, w   ;Increment byte #7 of product32 if carry from last addition
    addwf   product32+7	    ;Add byte #3 of mpcan32 to byte #7 of product32
    ; 2) Shift all 8 bytes the product32 register right one bit
mulShift
    ;1st byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32, f    ;right shift byte #0
    ;2nd byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+1, f  ;right shift byte #1
    btfsc   STATUS, C	    ;Carry due to right shift of byte #1?
    bsf	    product32, 7    ;Yes, so shift that bit into byte #0
    ;3rd byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+2, f  ;right shift byte #2
    btfsc   STATUS, C	    ;Carry due to right shift of byte #2?
    bsf	    product32+1, 7  ;Yes, so shift that bit into byte #1
    ;4th byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+3, f  ;right shift byte #3
    btfsc   STATUS, C	    ;Carry due to right shift of byte #3?
    bsf	    product32+2, 7    ;Yes, so shift that bit into byte #2
    ;5th byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+4, f  ;right shift byte #4
    btfsc   STATUS, C	    ;Carry due to right shift of byte #4?
    bsf	    product32+3, 7  ;Yes, so shift that bit into byte #3
    ;6th byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+5, f  ;right shift byte #5
    btfsc   STATUS, C	    ;Carry due to right shift of byte #5?
    bsf	    product32+4, 7    ;Yes, so shift that bit into byte #4
    ;7th byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+6, f  ;right shift byte #6
    btfsc   STATUS, C	    ;Carry due to right shift of byte #6?
    bsf	    product32+5, 7  ;Yes, so shift that bit into byte #5
    ;8th byte
    bcf	    STATUS, C	    ;Clear carry
    rrf	    product32+7, f  ;right shift byte #7
    btfsc   STATUS, C	    ;Carry due to right shift of byte #7?
    bsf	    product32+6, 7  ;Yes, so shift that bit into byte #6
    
    ; 3) Decrement loop counter
    decfsz  loopCount, f
    goto    testLsb	    ;reloop 32 times

    retlw	0
;************************End mul32 routine**************************************
    
;****************************Get Temperature Data*******************************
getTemp
    banksel	negFlag
    clrf	negFlag		;clear negative number indicator
;1) get value of dt (dt = D2 - Tref * 2^8)
    ; 1st place Tref into lower 4 bytes of product32
    banksel	Tref
    movfw	Tref
    movwf	product32
    movfw	Tref+1
    movwf	product32+1
    clrf	product32+2
    clrf	product32+3
    ; 2nd place 256 (2^8) into mpcand32
    banksel	mpcand32
    clrf	mpcand32
    movlw	.1
    movwf	mpcand32+1
    clrf	mpcand32+2
    clrf	mpcand32+3
    ; 3rd, multiply Tref by 256
    movlw	.32
    movwf	loopCount
    call	mul32	    ;result of Tref * 256 is in lower 4 bytes of product32
    
    ; 4th, perform subtraction of product32 (3 bytes) from D2 (3 bytes and is placed in deeT)
    ;	    1st place D2 in dT
    banksel	D2
    movfw	D2
    movwf	deeT
    movfw	D2+1
    movwf	deeT+1
    movfw	D2+2
    movwf	deeT+2
    clrf	deeT+3
    ;TEST FOR A NEGATIVE DT
    ;banksel	deeT
    ;movlw	.64
    ;movwf	deeT
    ;movlw	.75
    ;movwf	deeT+1
    ;movlw	.76
    ;movwf	deeT+2
    ;check to see which # is greater, D2/deeT or product32, (neither is larger than a 3 byte number
    ;so test the MSB 1st)
    movfw	product32+2
    subwf	deeT+2, w
    btfsc	STATUS, C	;Carry from subtraction? (C=0 if result was negative)
    goto	postiveDt	;No so dT will be positive. (Proceed to subtract product32 from D2/deeT)
    bsf		negFlag, 0	;yes so indicate resulting value for dT will be a negative number
				;and subtract D2 from product32
negativeDt
    ;subtract deeT/D2 from product32 to get a negative deeT
    movfw	deeT
    subwf	product32, f	;Subtract 1st bytes
    
    movfw	deeT+1
    btfss	STATUS, C	;borrow from subtraction of 1st bytes?
    incfsz	deeT+1, w	;yes so increment 2nd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	product32+1, f	;Subtract 2nd bytes
    
    movfw	deeT+2
    btfss	STATUS, C	;borrow from subtraction of 2nd bytes?
    incfsz	deeT+2, w	;yes so increment 3rd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	product32+2, f	;Subtract 3rd bytes. No more bytes left in product32 (its a 24 bit number here)
    ;Value for dt is negative but it currently is in product32 so place product32 into deeT
    movfw	product32
    movwf	deeT
    movfw	product32+1
    movwf	deeT+1
    movfw	product32+2
    movwf	deeT+2
				
    goto	doneSubtracting	;finished subtracting D2 from product32
postiveDt
    movfw	product32
    subwf	deeT, f		;Subtract 1st bytes
    
    movfw	product32+1
    btfss	STATUS, C	;borrow from subtraction of 1st bytes?
    incfsz	product32+1, w	;yes so increment 2nd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	deeT+1, f	;Subtract 2nd bytes
   
    movfw	product32+2
    btfss	STATUS, C	;borrow from subtraction of 2nd bytes?
    incfsz	product32+2, w	;yes so increment 3rd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	deeT+2, f	;Subtract 3rd bytes. No more bytes left in D2 (its a 24 bit number)
doneSubtracting
    ;We now have a signed value for dT (if negFlag, 0 = 1 then negative)
    ;Multiply this by C6/2^23 and add/subtract it to/from 2000
    ;When multiplying dT*C6 only use the lower 4 bytes when you divide by 2^23
    ;then add/subtract this number to/from 2000
    
	;Multiply deeT by C6
	;Place dT into lower 4 bytes of product21
	banksel	deeT
	movfw	deeT
	movwf	product32	;byte 0
	movfw	deeT+1
	movwf	product32+1	;byte 1
	movfw	deeT+2
	movwf	product32+2	;byte 3
	movfw	deeT+3
	movwf	product32+3	;byte 4
	;zero out upper 4 byte of product32
	clrf	product32+4	;byte 5
	clrf	product32+5	;byte 6
	clrf	product32+6	;byte 7
	clrf	product32+7	;byte 8
	;Place C6/TEMPSENS into mpcand32
	movfw	TEMPSENS
	movwf	mpcand32	;byte 1
	movfw	TEMPSENS+1	
	movwf	mpcand32+1	;byte 2
	clrf	mpcand32+2	;clear out upper 2 bytes of
	clrf	mpcand32+3	;mpcand32 (TEMPSENS is a 16 bit number)
	; Multiply dT by C6/TEMPSENS
    movlw	.32
    movwf	loopCount
    call	mul32	    ;result of dT * TEMPSENS/C6 is in lower 4 bytes of product32
	;Divide lower 4 bytes of product32 by 2^23 (8388608)
wer
    
    goto	wer
    
    
    
 
 retlw	0
    
    
    
    
    END


