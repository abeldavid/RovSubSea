;Math routines
    ;LCD Routines


    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -312     ;no  "page or bank selection not needed" messages
    errorlevel -207    ;no label after column one warning
    
    global  getTemp
	
    extern  deeT	;32 bit signed
    extern  product32	;64 bit
    extern  mpcand32	;32 bit
    extern  Tref	;16 bit
    extern  loopCount	;8 bit
    extern  D2		;24 bit
    
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
    
    ; 4th, subtract product32 (4 bytes) from D2 (3 bytes)
    ;	    1st place D2 in dT
    banksel	D2
    movfw	D2
    movwf	deeT
    movfw	D2+1
    movwf	deeT+1
    movfw	D2+2
    movwf	deeT+2
    clrf	deeT+3

   movfw	product32
   subwf	deeT, f
   
   movfw	product32+1
   btfss	STATUS, C	;borrow from subctraction?
   incfsz	product32+1, w	;yes so increment next byte to be subtracted (Don't subtract if zero resulted from incrementing)
   subwf	deeT+1, f
   
   movfw	product32+2
   btfss	STATUS, C	;borrow from subctraction?
   incfsz	product32+2, w	;yes so increment next byte to be subtracted (Don't subtract if zero resulted from incrementing)
   subwf	deeT+2, f
   
   movfw	product32+3
   btfss	STATUS, C	;borrow from subctraction?
   incfsz	product32+3, w	;yes so increment next byte to be subtracted (Don't subtract if zero resulted from incrementing)
   subwf	deeT+3, f
    
wer
    
    goto	wer
    
    
    
 
 retlw	0
    
    
    
    
    END


