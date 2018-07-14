;Routines for MS5837 Temperature/Pressure module
    
    list	p=16f1937	;list directive to define processor
    #include	<p16f1937.inc>	;processor specific variable definitions
    #include	<ms5837.inc>
    
    
    
    .MS5837 code
;*************Get ADC value for temp or press conversion from slave*************
sensorData
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Give slave command for 12 bit uncompensated Temp (D2) or Pressure (D1) conversion
    banksel	tOrP
    btfss	tOrP, 0	    ;0=pressure, 1=temperature
    goto	pressure
temperature
    movlw	.88	    ;cmd for 12 bit temp conv.
    goto	getData
pressure
    movlw	.72
getData
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend	
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;wait 18 mS for conversion to complete
    movlw	.18
    pagesel	delayMillis
    call	delayMillis
    pagesel$
    ;write command
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend	
    pagesel$
    ;Give slave command to perform ADC read
    movlw	b'00000000'	    ;cmd for ADC read
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    
    ;read command
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    pagesel	threeByteReceive
    call	threeByteReceive    ;receive temp (D2) data
    pagesel$
    retlw	0
;*************************End sensorData Routine********************************
    
;*********************Reset sequence for MS5837 device**************************
slaveReset
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for device write
    pagesel$
    
    movlw	deviceReset	    ;command for device reset
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for device reset
    pagesel$
    pagesel	I2CStop
    call	I2CStop		    ;send stop condition
    pagesel$
    
    ;Get PROM Coefficients
    ;*********************SENS (C1)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend	
    pagesel$
    ;Send address to be read
    movlw	C1		    ;addr for SENS (C1)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read SENS (C1)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	twoByteReceive
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into SENS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	SENS+1
    movfw	coeffCPY	    ;low bytes
    movwf	SENS
    ;*********************OFF (C2)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Send address to be read
    movlw	C2		    ;addr for OFF (C2)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read OFF (C2)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	twoByteReceive
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into OFF
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	OFF+1
    movfw	coeffCPY	    ;low bytes
    movwf	OFF
    ;*********************TCS (C3)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Send address to be read
    movlw	C3		    ;addr for TCS (C3)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read TCS (C3)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into TCS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TCS+1
    movfw	coeffCPY	    ;low bytes
    movwf	TCS
    ;*********************TCO (C4)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Send address to be read
    movlw	C4		    ;addr for TCO (C4)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read TCO (C4)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	twoByteReceive
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into TCO
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TCO+1
    movfw	coeffCPY	    ;low bytes
    movwf	TCO
    ;*********************Tref (C5)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Send address to be read
    movlw	C5		    ;addr for TREF (C5)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read Tref (C5)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	twoByteReceive
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into Tref
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	Tref+1
    movfw	coeffCPY	    ;low bytes
    movwf	Tref
    ;*********************TEMPSENS (C6)*********************************************
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrWrite	    ;command for device addr (write)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend
    pagesel$
    ;Send address to be read
    movlw	C6		    ;addr for TEMPSENS (C6)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	I2CStop
    call	I2CStop
    pagesel$
    ;read TEMPSENS (C6)
    pagesel	I2Cstart
    call	I2Cstart
    pagesel$
    movlw	deviceAddrRead	    ;command for device addr (read)
    banksel	i2cByteToSend
    movwf	i2cByteToSend
    pagesel	I2Csend
    call	I2Csend		    ;send command for PROM read
    pagesel$
    pagesel	twoByteReceive
    call	twoByteReceive	    ;receive SENS (C1) data
    pagesel$
    ;place coeffCPY into TEMPSENS
    banksel	coeffCPY
    movfw	coeffCPY+1	    ;high bytes
    movwf	TEMPSENS+1
    movfw	coeffCPY	    ;low bytes
    movwf	TEMPSENS
    retlw	0
    ;***********Done getting PROM coefficients (End slaveReset)*****************
    
    
    END