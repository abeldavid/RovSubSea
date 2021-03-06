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
;Final Result is held in product32 at end of mul routine
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
;	remainder at end of routine = 33 bits in length
;	loopCount = 32
;	divisor = 32 bits in length
;	Q = dividend (32 bits), but holds quotient at end of routine
divShift
    ;Left-shift Q and remainder together (Q is shifted into remainder)
    bcf		STATUS, C		;Clear carry
    banksel	remainder
    rlf		remainder+4,f		;left shift A (byte 5)
    btfsc	remainder+3, 7		;msb of 4th byte of A = 1?
    bsf		remainder+4, 0		;yes so shift it into 5th byte of A
    
    rlf		remainder+3,f		;left shift A (byte 4)
    btfsc	remainder+2, 7		;msb of 3rd byte of A = 1?
    bsf		remainder+3, 0		;yes so shift it into 4th byte of A
    
    bcf		STATUS, C		;Clear carry
    rlf		remainder+2,f		;left shift A (byte 3)
    btfsc	remainder+1, 7		;msb of 2nd byte of A = 1?
    bsf		remainder+2, 0		;yes so shift it into 3rd byte of A
    
    bcf		STATUS, C		;Clear carry
    rlf		remainder+1,f		;left shift A (byte 2)
    btfsc	remainder, 7		;msb of 1st byte of A = 1?
    bsf		remainder+1, 0		;yes so shift it into 2nd byte of A
    
    bcf		STATUS, C		;Clear carry
    rlf		remainder,f		;left shift A (byte 1)
    btfsc	Q+4, 7			;msb of 5th byte of Q = 1?
    bsf		remainder, 0		;yes so shift it into 1st byte of A
    
    bcf		STATUS, C		;Clear carry
    rlf		Q+4, f			;left shift Q (byte 5)
    btfsc	Q+3, 7			;msb of 4th byte of Q = 1?
    bsf		Q+4, 0			;yes so shift it into 5th byte of Q
    
    bcf		STATUS, C		;Clear carry
    rlf		Q+3, f			;left shift Q (byte 4)
    btfsc	Q+2, 7			;msb of 3rd byte of Q = 1?
    bsf		Q+3, 0			;yes so shift it into 4th byte of Q
    
    bcf		STATUS, C		;Clear carry
    rlf		Q+2, f			;left shift Q (byte 3)
    btfsc	Q+1, 7			;msb of 2nd byte of Q = 1?
    bsf		Q+2, 0			;yes so shift it into 3rd byte of Q
    
    bcf		STATUS, C		;Clear carry
    rlf		Q+1, f			;left shift Q (byte 2)
    btfsc	Q, 7			;msb of 1st byte of Q = 1?
    bsf		Q+1, 0			;yes so shift it into 2nd byte of Q
    
    bcf		STATUS, C		;Clear carry
    rlf		Q, f			;left shift Q (byte 1)
    
    ; remainder = remainder - divisor
    movfw	divisor
    subwf	remainder, f	;Subtract 1st bytes
    
    movfw	divisor+1
    btfss	STATUS, C	;borrow from subtraction of 1st bytes?
    incfsz	divisor+1, w	;yes so increment 2nd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	remainder+1, f	;Subtract 2nd bytes
	
    movfw	divisor+2
    btfss	STATUS, C	;borrow from subtraction of 2nd bytes?
    incfsz	divisor+2, w	;yes so increment 3rd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	remainder+2, f	;Subtract 3rd bytes
	
    movfw	divisor+3
    btfss	STATUS, C	;borrow from subtraction of 3rd bytes?
    incfsz	divisor+3, w	;yes so increment 4th byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	remainder+3, f	;Subtract 4th bytes
    
    ;Extract lsb of remainder+4
    movlw	b'00000001'
    andwf	remainder+4, f
    movlw	.1
    btfss	STATUS, C	;borrow from subtraction of 4th bytes?
    subwf	remainder+4, f
    ;Negative result from subtraction? (Restore if so)
    btfss	STATUS, C	;C=neg number
    goto	resto		;msb of A=1 so restore A
	
    bsf		Q, 0		;no so set lsb of Q
    decfsz	loopCount, f	;Decrement loop counter
    goto	divShift	;Reloop
    goto	divComplete	;Done so exit routine
resto
    banksel	Q
    bcf		Q, 0		;clear lsb of Q
;restore remainder (A = remainder + divisor)
    movfw	divisor
    addwf	remainder, f	;Add 1st bytes
	
    movfw	divisor+1
    btfsc	STATUS, C	;Carry from addition of 1st bytes?
    incfsz	divisor+1, w	;Yes so increment 2nd byte to be added (unless incrementation resulted in a zero value)
    addwf	remainder+1, f	;Add 2nd bytes
	
    movfw	divisor+2
    btfsc	STATUS, C	;Carry from addition of 2nd bytes?
    incfsz	divisor+2, w	;Yes so increment 3rd byte to be added (unless incrementation resulted in a zero value)
    addwf	remainder+2, f	;Add 3rd bytes
	
    movfw	divisor+3
    btfsc	STATUS, C	;Carry from addition of 3rd bytes?
    incfsz	divisor+3, w	;Yes so increment 4th byte to be added (unless incrementation resulted in a zero value)
    addwf	remainder+3, f	;Add 4th bytes
    
    btfss	STATUS, C	;Carry from addition of 4th bytes?
    goto	decrement	;No so proceed to decrement counter
    movlw	.1
    addwf	remainder+4, f	;Yes so add one to 5th byte of A
	
decrement
    decfsz	loopCount, f	;Decrement loop counter
    goto	divShift	;Reloop
	
divComplete
    retlw	0
;****************************End div32 Routine**********************************
    
    
;*****************************Convert Celsius to Farenheit**********************
CtoF
    ;Convert from Celcius to Farenheit (F = (9*degreeC/5) + 32)
    banksel	negFaren
    clrf	negFaren	;Clear negative farenheit flag
	;Place TempC into lower 4 bytes of product32
    movfw	TempC		;TempC is only one byte
    movwf	product32
    movfw	TempC+1
    movwf	product32+1
    movfw	TempC+2
    movwf	product32+2
    movfw	TempC+3
    movwf	product32+3
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
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32	    ;Multiply (9*TempC)
    call	mul32	    ;result of 9 * TempC is in lower 4 bytes of product32
    pagesel$
	;divide product32 (result of 9 * TempC) by 5
	; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place d'5' into divisor
    movlw	.5
    movwf	divisor
    clrf	divisor+1
    clrf	divisor+2
    clrf	divisor+3
	; Place product32 (the result of 9*TempC) into Q (Q is initially the dividend but holds the quotient at 
	; the end of div routine) Q is a 4 byte number
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
    movfw	product32+4
    movwf	Q+4
    
	;loop though 40 times (40 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    pagesel$
	;Is above result negative or positive?
    banksel	negFlag
    btfsc	negFlag, 0
    goto	negC	;Yes because Celsius temp reading was negative, goto negC to handle this
	;Positve so add 32 to LSB of Q
	;CONVERT POSITIVE CELSIUS TO POSITIVE FARENHEIT
    movlw	.32
    banksel	Q
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
;*************************End Celsius to Farenheit conversion*******************
    
    
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
    ;banksel	adcCPY+2
    ;movfw	adcCPY+2	    ;MSBytes
    ;movwf	D1+2
    ;movfw	adcCPY+1
    ;movwf	D1+1
    ;movfw	adcCPY
    ;movwf	D1
   
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
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
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
    pagesel	mul32
    call	mul32	    ;result of Tref * 256 is in lower 4 bytes of product32
    pagesel$
    
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
    
    ;check to see which # is greater, D2/deeT or product32, (neither is larger than a 4 byte number)
    ;Subtract product32 from D2:
    movfw	product32
    subwf	deeT, f		;Subtract 1st bytes
    
    movfw	product32+1
    btfss	STATUS, C	;borrow from subtraction of 1st bytes?
    incfsz	product32+1, w	;yes so increment 2nd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	deeT+1, f	;Subtract 2nd bytes
    
    movfw	product32+2
    btfss	STATUS, C	;borrow from subtraction of 2nd bytes?
    incfsz	product32+2, w	;yes so increment 3rd byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	deeT+2, f	;Subtract 3rd bytes
    	
    movfw	product32+3
    btfss	STATUS, C	;borrow from subtraction of 3rd bytes?
    incfsz	product32+3, w	;yes so increment 4th byte to be subtracted (Don't subtract if zero resulted from incrementing)
    subwf	deeT+3, f	;Subtract 4th bytes
    
    btfsc	STATUS, C	;borrow from subtraction of 2nd bytes?
    goto	doneSubtracting	;(D2 is > 256*Tref)
						
negativeDt ;(256*Tref is > D2)
    ;Restore original value of deeT by placing value of D2 into deeT
    banksel	D2
    movfw	D2
    movwf	deeT
    movfw	D2+1
    movwf	deeT+1
    movfw	D2+2
    movwf	deeT+2
    clrf	deeT+3
    
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
	; Multiply dT by C6,TEMPSENS
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32
    call	mul32	    ;result of dT * TEMPSENS/C6 is in  product32
    pagesel$
	; Divide product32 by 2^23 (8388608)
	; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place d'8388608' into divisor/M
    clrf	divisor
    clrf	divisor+1
    movlw	.128
    movwf	divisor+2
    clrf	divisor+3
	; Place product32 into Q (Q is initially the dividend but holds
	; the quotient at the end of div routine
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
    movfw	product32+4
    movwf	Q+4
	;loop though 33 times (40 bit division)
    
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q
    pagesel$
	;Add/subtract Q to/from 2000 depending on status of negflag (sign of deeT)
	; First place d'2000' into TempC (5 byte number)
    banksel	TempC
    movlw	.208
    movwf	TempC
    movlw	.7
    movwf	TempC+1
    clrf	TempC+2
    clrf	TempC+3
    clrf	TempC+4
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
    
    movfw	Q+4
    btfsc	STATUS, C	;Carry from addition of 4th bytes?
    incfsz	Q+4, w		;yes so increment 5th byte to be added (unless inc results in zero)
    addwf	TempC+4, f	;Add 4th bytes
    
    goto	divBy100
	;negFlag is set (due to dT being negative) so subtract Q from 2000/Temp
;*********CHECK TEMPSUBTRACT PosTEMP AND NEGTEMP WITH DEBUGGER**************************
tempSubtract
    banksel	negFlag
    clrf	negFlag		;Reset negFlag (will need this if temp is found to be negative)
	;determine which is greater, Q or 2000
    movlw	.0
    xorwf	Q+4, f
    btfss	STATUS, Z	;non-zero number in MSB of Q?
    goto	negTemp		;Temperature will be negative
	
    movlw	.0
    xorwf	Q+3, f
    btfss	STATUS, Z	;non-zero number in 4th byte of Q?
    goto	negTemp		;Temperature will be negative
	
    movlw	.0
    xorwf	Q+2, f
    btfss	STATUS, Z	;non-zero number in 3rd byte of Q?
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
    
    movfw	TempC+4
    btfss	STATUS, C	;Borrow from subtraction of 4th bytes?
    incfsz	TempC+4, w	;Yes so inc 5th byte to be subtracted (unless inc results in zero)
    subwf	Q+4, f		;Subtract 5th bytes
    ;Now Place Q back in to TempC
    movfw	Q
    movwf	TempC
    movfw	Q+1
    movwf	TempC+1
    movfw	Q+2
    movwf	TempC+2
    movfw	Q+3
    movwf	TempC+3
    movfw	Q+4
    movwf	TempC+4
    
	;Divide result by 100 to get Temperature in Celsius
divBy100
	; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place d'100' into divisor/M
    movlw	.100
    movwf	divisor
    clrf	divisor+1
    clrf	divisor+2
    clrf	divisor+3
	; Place TempC into Q (Q is initially the dividend but holds the quotient at 
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
    movfw	TempC+4
    movwf	Q+4
    
	;loop though 40 times (32 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    pagesel$
	;Place div result held in Q into TempC (This is Temp in Celsius)
    banksel	Q
    movfw	Q
    movwf	TempC
    movfw	Q+1
    movwf	TempC+1
    movfw	Q+2
    movwf	TempC+2
    movfw	Q+3
    movwf	TempC+3
    movfw	Q+4
    movwf	TempC+4
    
    
    ;Convert Clesius to Farenheit
    pagesel	CtoF
    call	CtoF
    pagesel$
    
    ;Is TempC < 20 deg C? (It has already been divided by 100
     movlw	.20
     banksel	TempC
     subwf	TempC, w
     btfss	STATUS, C   ;C=0 is neg #
     goto	SecondOrderLow	    ;Yes so perform 2nd order conversion for low temperature
     goto	SecondOrderHigh	    ;No so perform 2nd order conversion for high temperature
    
	
					  
;*****************Perform 2nd Order Temperature Conversion**********************
SecondOrderHigh
     ;Square deeT
     ;Place deeT into lower 4 bytes of product32
    movfw	deeT		;TempC is only one byte
    movwf	product32
    movfw	deeT+1
    movwf	product32+1
    movfw	deeT+2
    movwf	product32+2
    movfw	deeT+3
    movwf	product32+3
	;zero out upper 4 bytes of product32
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
	;Place deeT into mpcand32 (4 byte number)
    movfw	deeT
    movwf	mpcand32
    movfw	deeT+1
    movwf	mpcand32+1
    movfw	deeT+2
    movwf	mpcand32+2
    movfw	deeT+3
    movwf	mpcand32+3
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32	    ;Multiply (deeT*deeT)
    call	mul32	    ;result of deeT^2 is in lower 4 bytes of product32
    pagesel$
    ;Divide result by 2^37 by calling div32 twice (once for div by 2^18 and 
    ;once for div by 2^19
    
    	; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place 2^18 into divisor/M (2^18=262144)
    clrf	divisor
    clrf	divisor+1
    movlw	.4
    movwf	divisor+2
    
	; place product32 into Q (Q is initially the dividend but holds the quotient at 
	; the end of div routine
    banksel	product32
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
    movfw	product32+4
    movwf	Q+4
    
	;loop though 40 times (32 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    ;Now redivide previous result (held in Q) again by 2^19 (2^19=524288)
    ; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place 2^19 into divisor/M	
    clrf	divisor
    clrf	divisor+1
    movlw	.8
    movwf	divisor+2
    
    ;Q already has the number it is supposed to
    
	;loop though 40 times (32 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    
    ;Multiply results by 2
    ;Place Q (result of deeT^2/2^37) into lower 4 bytes of product32
    movfw	Q		;TempC is only one byte
    movwf	product32
    movfw	Q+1
    movwf	product32+1
    movfw	Q+2
    movwf	product32+2
    movfw	Q+3
    movwf	product32+3
	;zero out upper 4 bytes of product32
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
	;Place d.2 into mpcand32 (4 byte number)
    movlw	.2
    movwf	mpcand32
    clrf	mpcand32+1
    clrf	mpcand32+2
    clrf	mpcand32+3
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32	    ;Multiply 
    call	mul32	    ;result of 3*(dt^2)/2^33 is in product32
    pagesel$
    ;Now subtract this result from original value of tempC
    banksel	product32
    movfw	product32
    subwf	TempC, f
    ;Convert to Farenheit
    pagesel	CtoF
    call	CtoF
    pagesel$
     
     goto	TemperatureComplete	  
     
     
     ;TempC < 20 deg C
SecondOrderLow
     ;Square deeT
     ;Place deeT into lower 4 bytes of product32
    movfw	deeT		;TempC is only one byte
    movwf	product32
    movfw	deeT+1
    movwf	product32+1
    movfw	deeT+2
    movwf	product32+2
    movfw	deeT+3
    movwf	product32+3
	;zero out upper 4 bytes of product32
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
	;Place deeT into mpcand32 (4 byte number)
    movfw	deeT
    movwf	mpcand32
    movfw	deeT+1
    movwf	mpcand32+1
    movfw	deeT+2
    movwf	mpcand32+2
    movfw	deeT+3
    movwf	mpcand32+3
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32	    ;Multiply (deeT*deeT)
    call	mul32	    ;result of deeT^2 is in lower 4 bytes of product32
    pagesel$
    ;Divide result by 2^33 by calling div32 twice (once for div by 2^16 and 
    ;once for div by 2^17
    
    	; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place 2^17 into divisor/M (2^17=131072)
    clrf	divisor
    clrf	divisor+1
    movlw	.2
    movwf	divisor+2
    
	; place product32 into Q (Q is initially the dividend but holds the quotient at 
	; the end of div routine
    banksel	product32
    movfw	product32	
    movwf	Q
    movfw	product32+1
    movwf	Q+1
    movfw	product32+2
    movwf	Q+2
    movfw	product32+3
    movwf	Q+3
    movfw	product32+4
    movwf	Q+4
    
	;loop though 40 times (32 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    
    ;Now redivide previous result (held in Q) again by 2^16 (2^16=65536)
    ; Zero out remainder
    banksel	remainder
    clrf	remainder
    clrf	remainder+1
    clrf	remainder+2
    clrf	remainder+3
    clrf	remainder+4
	; Place 2^16 into divisor/M	
    clrf	divisor
    clrf	divisor+1
    movlw	.1
    movwf	divisor+2
    
    ;Q already has the number it is supposed to
    
	;loop though 40 times (32 bit division)
    movlw	.40
    banksel	loopCount
    movwf	loopCount
    pagesel	div32
    call	div32	;division result is held in Q 
    
    ;Multiply results by 3
    ;Place Q (result of deeT^2/2^33) into lower 4 bytes of product32
    movfw	Q		;TempC is only one byte
    movwf	product32
    movfw	Q+1
    movwf	product32+1
    movfw	Q+2
    movwf	product32+2
    movfw	Q+3
    movwf	product32+3
	;zero out upper 4 bytes of product32
    clrf	product32+4
    clrf	product32+5
    clrf	product32+6
    clrf	product32+7
	;Place d.3 into mpcand32 (4 byte number)
    movlw	.3
    movwf	mpcand32
    clrf	mpcand32+1
    clrf	mpcand32+2
    clrf	mpcand32+3
    movlw	.32
    banksel	loopCount
    movwf	loopCount
    pagesel	mul32	    ;Multiply 
    call	mul32	    ;result of 3*(dt^2)/2^33 is in product32
    pagesel$
    ;Now subtract this result from original value of tempC
    banksel	product32
    movfw	product32
    subwf	TempC, f
    ;Convert to Farenheit
    pagesel	CtoF
    call	CtoF
    pagesel$
TemperatureComplete
     
    retlw	0
    
    
    
    
    
    
    
    
    
    
    END