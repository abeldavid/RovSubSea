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
    extern	sixteenMpcand
    extern	sixteenMplier
    extern	loopCount
    extern	mulResult16
    
.math code
mul16
    ;Low Bytes
    movlw	.8
    banksel	loopCount
    movwf	loopCount
lowByte
    btfss	sixteenMplier, 0    ;Test lsb of multiplier
    goto	shiftLow	    ;It's zero so proceed
    movfw	sixteenMpcand	    ;It's not zero so add multiplicand to result
    bcf		STATUS, C	    ;Clear carry bit
    addwf	mulResult16, f	    
    btfss	STATUS, C	    ;Did this addition overflow first byte of result
    goto	shiftLow	    ;No so proceed
    movlw	.1		    ;It did cause an overflow
    bcf		STATUS, C	    ;Clear carry bit
    addwf	mulResult16+1, f    ;so add one to second byte of result
    btfss	STATUS, C	    ;Did this addition overflow second byte of result
    goto	shiftLow	    ;No so proceed
    movlw	.1		    ;It did cause an overflow
    bcf		STATUS, C	    ;Clear carry bit
    addwf	mulResult16+2, f    ;so add one to third byte of result
    btfss	STATUS, C	    ;Did this addition overflow third byte of result
    goto	shiftLow	    ;No so proceed
    movlw	.1		    ;It did cause an overflow
    addwf	mulResult16+3, f    ;so add one to fourth byte of result
shiftLow
    bcf		STATUS, C	    ;Clear carry bit
    rlf		sixteenMpcand, f    ;Shift multiplicand left one bit
    rrf		sixteenMplier, f    ;Shift multiplier right one bit
    decfsz	loopCount	    ;decrement loop counter
    goto	lowByte		    ;Haven't done this for all 8 bits yet
    
highByte
    
    
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
    clrf	sixteenMplier
    clrf	sixteenMplier+1
    clrf	sixteenMpcand
    clrf	sixteenMpcand+1
    clrf	mulResult16
    clrf	mulResult16+1
    clrf	mulResult16+2
    clrf	mulResult16+3
    

;multiply sixByteNum (2^8 = 256, 16 bit number) by Tref (C5) (C5=16 bit number)
    ;place 256 into sixteenMplier
    movlw	.2
    banksel	sixteenMplier
    movwf	sixteenMplier	
    ;place Tref into sixteenMpcand
    movlw	.2
    banksel	sixteenMpcand
    call	mul16
    
    call	mul16
    banksel	sixteenMpcand
    movfw	sixteenMpcand
    banksel	PORTD
    movwf	PORTD
   
    ;place value of D2 (3 bytes) into deeT (dT=4 bytes signed)
    
 
 retlw	0
    
    
    
    
    END


