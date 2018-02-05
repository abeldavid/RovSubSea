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
    extern	delayMillis
    
.math code
mul16
    ;Low Bytes
    movlw	.15
    banksel	loopCount
    movwf	loopCount
    
checkLsb
    banksel	sixteenMplier
    movfw	sixteenMplier
    banksel	PORTD
    movwf	PORTD
    movlw	.255
    call	delayMillis
    movlw	.255
    call	delayMillis
    movlw	.255
    call	delayMillis
    movlw	.255
    call	delayMillis
    banksel	sixteenMplier
    
    btfss	sixteenMplier, 0    ;Test lsb of multiplier
    goto	shift	    ;It's zero so proceed to shifts
    
    ;lsb of multiplier is not zero so add multiplicand (3 bytes after 8 left-shifts)
    ;to product/result (4bytes)
    movfw	sixteenMpcand	    ;add byte 0
    addwf	mulResult16, f
    
    movfw	sixteenMpcand+1	    ;add byte 1
    btfsc	STATUS, C	    ;overflow from addition?
    incfsz	sixteenMpcand+1, w  ;yes so increment the number to be added to 2nd byte of result
    addwf	mulResult16+1, f
    
    movfw	sixteenMpcand+2	    ;add byte 2
    btfsc	STATUS, C	    ;overflow from addition?
    incfsz	sixteenMpcand+2, w  ;yes so increment the number to be added to 3rd byte of result
    addwf	mulResult16+2, f    
    
    btfsc	STATUS, C	    ;overflow from addition?
    movlw	.1
    addwf	mulResult16+3, f    ;yes so add one to 4th byte of result
    
    ;perform left shit on multiplicand
shift
    bcf		STATUS, C	    ;Clear carry bit
    rlf		sixteenMpcand, f    ;Shift multiplicand (low byte)left one bit
    bcf		STATUS, C	    ;Clear carry bit
    rlf		sixteenMpcand+1, f
    
    ;and right shift on multiplier
    bcf		STATUS, C	    ;Clear carry bit
    rrf		sixteenMplier+1, f  ;Shift multiplier right one bit
    btfss	STATUS, C	    ;Did right shift result in a carry?
    goto	noCarryMplr
    bcf		STATUS, C	    ;Clear carry bit
    rrf		sixteenMplier, f    ;Shift multiplier right one bit
    bsf		sixteenMplier, 7
noCarryMplr
    bcf		STATUS, C	    ;Clear carry bit
    rrf		sixteenMplier, f    ;Shift multiplier right one bit
    
    ;*****REMEMBER TO RIGHT SHIFT BOTH BYTES OF MULTIPLIER AND ACCOUNT FOR CARRY
    
    ;decrement loop counter
    decfsz	loopCount, f
    goto	checkLsb	    ;reloop 16 times
    
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
    banksel	sixteenMplier
    clrf	sixteenMplier
    clrf	sixteenMplier+1
    clrf	sixteenMpcand
    clrf	sixteenMpcand+1
    clrf	sixteenMpcand+2
    clrf	mulResult16
    clrf	mulResult16+1
    clrf	mulResult16+2
    clrf	mulResult16+3
    banksel	PORTD
    clrf	PORTD

;multiply sixByteNum (2^8 = 256, 16 bit number) by Tref (C5) (C5=16 bit number)
    ;place 256 into sixteenMplier
    movlw	.1
    banksel	sixteenMplier
    movwf	sixteenMplier+1
    clrf	sixteenMplier
    ;place Tref into sixteenMpcand
    movfw	Tref
    banksel	sixteenMpcand
    movwf	sixteenMpcand
    movfw	Tref+1
    movwf	sixteenMpcand+1
    
    pagesel	mul16
    call	mul16
    pagesel$
    
wer
    
    goto	wer
    
    ;place value of D2 (3 bytes) into deeT (dT=4 bytes signed)
    
 
 retlw	0
    
    
    
    
    END


