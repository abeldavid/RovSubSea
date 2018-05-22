;Math Routines for use with MS5837
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>		; processor specific variable definitions
    #include	<math.inc>
    
    .math code
 mul32
;**********************Multiply 2 32 bit numbers********************************
;At beginning of routine,  product32 contains following:
;[-----upper 4 bytes------][-------lower 4 bytes----------]
;[---------zero-----------][------32 bit multiplier-------]
;		           [bit 0 of multiplier is control mechanism]
testLsb
    ; 1) Test Lsb of multiplier (also lsb of product32
    banksel product32
    btfss   product32, 0
    goto    mulShift	    ;lsb=0 so proceed to shift
addMpcand		    ;lsb=1 so add mpcand32 to left 1/2 of product32
    ;1st Bytes
    banksel mpcand32
    movfw   mpcand32
    addwf   product32+4, f  ;Add byte #0 of mpcand32 to byte #4 of product32
    ;2nd bytes
    movfw   mpcand32+1
    btfsc   STATUS, C
    incfsz  mpcand32+1, w   ;Increment byte #5 of product32 if carry from last addition
    addwf   product32+5, f  ;Add byte #1 of mpcan32 to byte #5 of product32
    ;3rd bytes
    movfw   mpcand32+2
    btfsc   STATUS, C
    incfsz  mpcand32+2, w   ;Increment byte #6 of product32 if carry from last addition
    addwf   product32+6, f  ;Add byte #2 of mpcan32 to byte #6 of product32
    ;4th bytes
    movfw   mpcand32+3
    btfsc   STATUS, C
    incfsz  mpcand32+3, w   ;Increment byte #7 of product32 if carry from last addition
    addwf   product32+7, f  ;Add byte #3 of mpcan32 to byte #7 of product32
    ; 2) Shift all 8 bytes the product32 register right one bit
mulShift
    ;1st byte
    bcf	    STATUS, C	    ;Clear carry
    banksel product32
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
    
;**********************Divide 2 32 bit numbers**********************************
div32
; At beginning of routine:
;	A = 0
;	loopCount = 32
;	M = divisor
;	Q = dividend, but holds quotient at end of routine
divShift
    ; left shift A and Q together (Q gets shifted into A)
    bcf		STATUS, C	;Clear carry
    banksel	A
    rlf		A+3,f		;left shift A (byte 4)
    btfsc	A+2, 7		;msb of 3rd byte of A = 1?
    bsf		A+3, 0		;yes so shift it into 4th byte of A
	
    bcf		STATUS, C	;Clear carry
    rlf		A+2,f		;left shift A (byte 3)
    btfsc	A+1, 7		;msb of 2nd byte of A = 1?
    bsf		A+2, 0		;yes so shift it into 3rd byte of A
	
    bcf		STATUS, C	;Clear carry
    rlf		A+1,f		;left shift A (byte 2)
    btfsc	A, 7		;msb of 1st byte of A = 1?
    bsf		A+1, 0		;yes so shift it into 2nd byte of A
	
    bcf		STATUS, C	;Clear carry
    rlf		A,f		;left shift A (byte 1)
    btfsc	Q+3, 7		;msb of 4th byte of Q = 1?
    bsf		A, 0		;yes so shift it into 1st byte of A
	
    bcf		STATUS, C	;Clear carry
    rlf		Q+3, f		;left shift Q (byte 4)
    btfsc	Q+2, 7		;msb of 3rd byte of Q = 1?
    bsf		Q+3, 0		;yes so shift it into 4th byte of Q
	
    bcf		STATUS, C	;Clear carry
    rlf		Q+2, f		;left shift Q (byte 3)
    btfsc	Q+1, 7		;msb of 2nd byte of Q = 1?
    bsf		Q+2, 0		;yes so shift it into 3rd byte of Q
	
    bcf		STATUS, C	;Clear carry
    rlf		Q+1, f		;left shift Q (byte 2)
    btfsc	Q, 7		;msb of 1st byte of Q = 1?
    bsf		Q+1, 0		;yes so shift it into 2nd byte of Q
	
    bcf		STATUS, C	;Clear carry
    rlf		Q, f		;left shift Q (byte 1)
		
	; A = A - M
    banksel	negFlag
    clrf	negFlag
    movfw	M
    subwf	A, f	    ;Subtract 1st bytes
    
    movfw	M+1
    btfss	STATUS, C	;borrow from subtraction of 1st bytes?
    incfsz	M+1, w	    ;yes so increment 2nd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	A+1, f	    ;Subtract 2nd bytes
	
    movfw	M+2
    btfss	STATUS, C	;borrow from subtraction of 2nd bytes?
    incfsz	M+2, w	    ;yes so increment 3rd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	A+2, f	    ;Subtract 3rd bytes
	
    movfw	M+3
    btfss	STATUS, C	;borrow from subtraction of 3rd bytes?
    incfsz	M+3, w	    ;yes so increment 4th byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	A+3, f	    ;Subtract 4th bytes
	
    btfss	STATUS, C	;borrow from subtraction of 4th bytes?
    goto	resto		;yes so restore A
	
    bsf		Q, 0		;no so set lsb of Q
    decfsz	loopCount, f	;Decrement loop counter
    goto	divShift	;Reloop
    goto	divComplete	;Done so exit routine
resto
    banksel	Q
    bcf		Q, 0		;clear lsb of Q
;restore A (A = A + M)
    movfw	M
    addwf	A, f		;Add 1st bytes
	
    movfw	M+1
    btfsc	STATUS, C	;Carry from addition of 1st bytes?
    incfsz	M+1, w		;Yes so increment 2nd byte to be added (unless incrementation resulted in a zero value)
    addwf	A+1, f		;Add 2nd bytes
	
    movfw	M+2
    btfsc	STATUS, C	;Carry from addition of 2nd bytes?
    incfsz	M+2, w		;Yes so increment 3rd byte to be added (unless incrementation resulted in a zero value)
    addwf	A+2, f		;Add 3rd bytes
	
    movfw	M+3
    btfsc	STATUS, C	;Carry from addition of 3rd bytes?
    incfsz	M+3, w		;Yes so increment 4th byte to be added (unless incrementation resulted in a zero value)
    addwf	A+3, f		;Add 4th bytes
	
    decfsz	loopCount, f	;Decrement loop counter
    goto	divShift	;Reloop
	
divComplete
    retlw	0
;****************************End div32 Routine**********************************
    
;****************************Get Temperature Data*******************************
getTemp
    ;******************Get ADC values for temp and press************************
    banksel	tOrP
    clrf	tOrP
    ;First get temperature
    banksel	tOrP
    bsf		tOrP, 0		    ;1=temperature ADC reading
    pagesel	sensorData
    call	sensorData	    ;perform temperature reading
    pagesel$
    ;place result of temperature ADC read into D2
    banksel	adcCPY+2
    movfw	adcCPY+2	    ;MSBytes
    movwf	D2+2
    movfw	adcCPY+1
    movwf	D2+1
    movfw	adcCPY
    movwf	D2
    ;banksel	tOrP
    ;clrf	tOrP		    ;0=Pressure ADC reading
    ;pagesel	sensorData
    ;call	sensorData	    ;perform pressure reading
    ;pagesel$
    ;place result of pressure ADC read into D1
    banksel	adcCPY+2
    movfw	adcCPY+2	    ;MSBytes
    movwf	D1+2
    movfw	adcCPY+1
    movwf	D1+1
    movfw	adcCPY
    movwf	D1
   
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
    movfw	product32+2	;Check 3rd bytes
    subwf	deeT+2, w
    btfss	STATUS, C	;Carry from subtraction? (C=0 if result was negative)
    goto	negativeDt	;Yes so obtain a negative dT value
	
    movfw	product32+1	;Check 2nd bytes
    subwf	deeT+1, w
    btfss	STATUS, C	;Carry from subtraction? (C=0 if result was negative)
    goto	negativeDt	;Yes so obtain a negative dT value
	
    movfw	product32	;Check 1st bytes
    subwf	deeT, w
    btfsc	STATUS, C	;Carry from subtraction? (C=0 if result was negative)
    goto	postiveDt	;No so dT will be positive. (Proceed to subtract product32 from D2/deeT)
    	
						
negativeDt
    banksel	negFlag
    bsf		negFlag, 0		;Set negFlag to indicate a negative value for dT
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
    banksel	product32
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
	;Place dT into lower 4 bytes of product32
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
	; Divide lower 4 bytes of product32 by 2^23 (8388608)
	; Zero out A
    banksel	A
    clrf	A
    clrf	A+1
    clrf	A+2
    clrf	A+3
	; Place d'8388608' into divisor/M
    clrf	M
    clrf	M+1
    movlw	.128
    movwf	M+2
    clrf	M+3
	; Place lower 4 bytes of product32 into Q (Q is initially the dividend but holds
	; the quotient at the end of div routine
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
	;loop though 32 times (32 bit division)
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    call	div32	;division result is held in Q
	;Add/subtract Q to/from 2000 depending on status of negflag
	; First place d'2000' into TempC
    banksel	TempC
    movlw	.208
    movwf	TempC
    movlw	.7
    movwf	TempC+1
    clrf	TempC+2
    clrf	TempC+3
	;check negflag to see if we need to add or subtract Q from 2000/Temp
    btfsc	negFlag, 0
    goto	tempSubtract	;negFlag is set so subtract Q from 2000/Temp
	;negFlag is not set so add Q to 2000/Temp
    movfw	Q
    addwf	TempC, f		;Add 1st bytes
	
    movfw	Q+1
    btfsc	STATUS, C	;Carry from addition of 1st bytes?
    incfsz	Q+1, w		;yes so increment 2nd byte to be added (unless inc results in zero)
    addwf	TempC+1, f	;Add 2nd bytes
	
    movfw	Q+2
    btfsc	STATUS, C	;Carry from addition of 2nd bytes?
    incfsz	Q+2, w		;yes so increment 3rd byte to be added (unless inc results in zero)
    addwf	TempC+2, f	;Add 3rd bytes
	
    movfw	Q+3
    btfsc	STATUS, C	;Carry from addition of 3rd bytes?
    incfsz	Q+3, w		;yes so increment 4th byte to be added (unless inc results in zero)
    addwf	TempC+3, f	;Add 4th bytes
    goto	divBy100
	;negFlag is set (due to dT being negative) so subtract Q from 2000/Temp
;*********CHECK TEMPSUBTRACT PosTEMP AND NEGTEMP WITH DEBUGGER**************************
tempSubtract
    banksel	negFlag
    clrf	negFlag		;Reset negFlag (will need this if temp is found to be negative)
	;determine which is greater, Q or 2000
    movfw	Q+3
    subwf	TempC+3, w	;4th bytes
    btfss	STATUS, C	;neg result if C=0
    goto	negTemp		;Temperature will be negative
	
    movfw	Q+2
    subwf	TempC+2, w	;3rd bytes
    btfss	STATUS, C	;neg result if C=0
    goto	negTemp		;Temperature will be negative
	
    movfw	Q+1
    subwf	TempC+1, w	;2nd bytes
    btfss	STATUS, C	;neg result if C=0
    goto	negTemp		;Temperature will be negative
	
    movfw	Q
    subwf	TempC, w	    ;1st bytes
    btfss	STATUS, C	;neg result if C=0
    goto	negTemp		;Temperature will be negative
;Temperature will be a positive result so subtract Q from 2000/Temp
posTemp	
    banksel	Q
    movfw	Q
    subwf	TempC, f		;Subtract 1st bytes
	
    movfw	Q+1
    btfss	STATUS, C	;Borrow from subtraction of 1st bytes?
    incfsz	Q+1, w		;Yes so inc 2nd byte to be subtracted (unless inc results in zero)
    subwf	TempC+1, f	;Subtract 2nd bytes
	
    movfw	Q+2
    btfss	STATUS, C	;Borrow from subtraction of 2nd bytes?
    incfsz	Q+2, w		;Yes so inc 3rd byte to be subtracted (unless inc results in zero)
    subwf	TempC+2, f	;Subtract 3rd bytes
	
    movfw	Q+3
    btfss	STATUS, C	;Borrow from subtraction of 3rd bytes?
    incfsz	Q+3, w		;Yes so inc 4th byte to be subtracted (unless inc results in zero)
    subwf	TempC+3, f	;Subtract 4th bytes
    goto	divBy100
	
;Temperature will be a negative result so subtract 2000/Temp from Q (and set negFlag)
negTemp
    banksel	negFlag
    bsf		negFlag, 0	;Set negFlag to indicate a negative temperature
	
    movfw	TempC
    subwf	Q, f		;Subtract 1st bytes
	
    movfw	TempC+1
    btfss	STATUS, C	;Borrow from subtraction of 1st bytes?
    incfsz	TempC+1, w	;Yes so inc 2nd byte to be subtracted (unless inc results in zero)
    subwf	Q+1, f		;Subtract 2nd bytes
	
    movfw	TempC+2
    btfss	STATUS, C	;Borrow from subtraction of 2nd bytes?
    incfsz	TempC+2, w	;Yes so inc 3rd byte to be subtracted (unless inc results in zero)
    subwf	Q+2, f		;Subtract 3rd bytes
	
    movfw	TempC+3
    btfss	STATUS, C	;Borrow from subtraction of 3rd bytes?
    incfsz	TempC+3, w	;Yes so inc 4th byte to be subtracted (unless inc results in zero)
    subwf	Q+3, f		;Subtract 4th bytes
	;Divide result by 100 to get Temperature in Celsius
divBy100
	; Zero out A
    banksel	A
    clrf	A
    clrf	A+1
    clrf	A+2
    clrf	A+3
    clrf	A+4
	; Place d'100' into divisor/M
    movlw	.100
    movwf	M
    clrf	M+1
    clrf	M+2
    clrf	M+3
	; Place Temp into Q (Q is initially the dividend but holds the quotient at 
	; the end of div routine
    banksel	TempC
    movfw	TempC	
    movwf	Q
    movfw	TempC+1
    movwf	Q+1
    movfw	TempC+2
    movwf	Q+2
    movfw	TempC+3
    movwf	Q+3
	;loop though 32 times (32 bit division)
    movlw	.32
    movwf	loopCount
    call	div32	;division result is held in Q 
	;Place div result held in Q into TempC (This is Temp in Celsius)
    banksel	Q
    movfw	Q
    movwf	TempC
;*****DUE TO INTEGER DIVISION AND NO ROUNDING, THIS IS +- 1 DEGree CELSIUS******
	;Convert from Celcius to Farenheit (F = (9*C/5) + 32)
    banksel	negFaren
    clrf	negFaren	;Clear negative farenheit flag
	;Place TempC into lower 4 bytes of product32
    movfw	TempC		;TempC is only one byte
    movwf	product32
    clrf	product32+1
    clrf	product32+2
    clrf	product32+3
	;zero out upper 4 bytes of product32
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
	;Place d'9' into mpcand32 (4 byte number)
    movlw	.9
    movwf	mpcand32
    clrf	mpcand32+1
    clrf	mpcand32+2
    clrf	mpcand32+3
    movlw	.32
    movwf	loopCount
    call	mul32	    ;result of 9 * TempC is in lower 4 bytes of product32
	;divide LSB of product32 (result of 9 * TempC) by 5
	; Zero out A
    banksel	A
    clrf	A
    clrf	A+1
    clrf	A+2
    clrf	A+3
    clrf	A+4
	; Place d'5' into divisor/M
    movlw	.5
    movwf	M
    clrf	M+1
    clrf	M+2
    clrf	M+3
	; Place lower 4 bytes of product32 (the result of 9*TempC) into Q (Q is initially the dividend but holds the quotient at 
	; the end of div routine) Q is a 4 byte number
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
    ;clrf	Q+1
    ;clrf	Q+2
    ;clrf	Q+3
	;loop though 32 times (32 bit division)
    movlw	.32
    movwf	loopCount
    call	div32	;division result is held in Q 
	;Is above result negative or positive?
    banksel	negFlag
    btfsc	negFlag, 0
    goto	negC	;Yes because Celsius temp reading was negative, goto negC to handle this
	;Positve so add 32 to LSB of Q
	;CONVERT POSITIVE CELSIUS TO POSITIVE FARENHEIT
    movlw	.32
    addwf	Q, f	;Result of Farenheit conversion is now in LSB of Q
    movfw	Q
    movwf	TempF	;Positive Clesius reading converted to positive Farenheit and
					;result is in TempF
    goto	tempDone
	;CELSIUS READING WAS NEGATIVE (WILL DEG F BE NEG OR POS?)
negC
	;Celsius reading was negative so subtract LSB of Q from 32
	;if LSB of Q > than 32, result will be a negative Farenheit reading
    movlw	.32
    banksel	Q
    subwf	Q, w
    btfsc	STATUS, C	;C = 0 if neg result
    goto	posFarenheit
	;CONVERT NEGATIVE CELSIUS TO NEGATIVE FARENHEIT
    bsf  	negFaren, 0	;set flag to indicate a neg farenheit reading
    movfw	Q
    movwf	TempF		;Place LSB of Q into TempF
	;subtract 32 from LSB of Q (which is in TempF
    movlw	.32
    subwf	TempF, f	;Negative Celsius reading converted to a negative Farenheit and 
						;result is in TempF
    goto	tempDone
	;CONVERT NEGATIVE CELSIUS TO POSITIVE FARENHEIT
posFarenheit
    clrf	negFaren  ;clear flag for negative farenheit reading
	;Farenheit conversion will result in a positive number
	;subtract LSB of Q from 32
    movlw	.32
    movwf	TempF	  ;Place 32 into TempF
    movwf	Q		  ;Subtract Q from 32
    subwf	TempF, f  ;Negative Celsius reading converted to positive Farenheit and
					  ;result is in TempF
tempDone
    retlw	0
    
    
    
    
    
    
    
    
    
    
    END