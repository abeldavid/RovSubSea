;config file for ms5837.asm
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207     ;no label after column one warning
    
    #define BANK0            (h'000')
    #define BANK1            (h'080')
    #define BANK2	     (h'100')
    #define BANK3	     (h'180')
    ;Commands for Temp/Pressure Module
    #define convertT	     (d'72')    ;start 12 bit Temperature conversion
    #define convertP	     (d'88')    ;start 12 bit Pressure conversion
    #define ADCread	     (d'0')	    ;Read out ADC result
    #define deviceAddrWrite  (b'11101100')
    #define deviceAddrRead   (b'11101101')
    #define deviceReset	     (d'30')
    
    global  slaveReset
    global  TEMPSENS
    global  Tref
    global  D2
    global  D1
    
    extern  I2Cstart
    extern  I2CStop
    extern  I2Crestart
    extern  waitMSSP
    extern  sendACK
    extern  sendNACK
    extern  enReceive
    extern  I2CFail
    extern  sendI2Cbyte
    extern  I2Csend
    extern  twoByteReceive
    extern  coeffCPY
    extern  adcCPY
    extern  i2cByteToSend
    extern  delayMillis
    extern  twoByteReceive
    extern  threeByteReceive
    
    GENVAR1	UDATA
    tOrP	RES 1	;flag used to determine whether we read temp
			;or pressure data (0=pressure, 1=temperature)
    SENS	RES 2	;Pressure Secnsitivity (2 bytes) from PROM
    OFF		RES 2	;Pressure Offset (2 bytes) from PROM
    TCS		RES 2	;Temp coeff of pressure sensitivity (2 bytes) from PROM
    TCO		RES 2	;Temp coeff of pressure offset (2 bytes) from PROM
    Tref	RES 2	;Reference temperature (2 bytes) from PROM
    TEMPSENS	RES 2	;Temp coeff of temperature (2 bytes) from PROM
    D1		RES 3	;Pressure value from ADC read of slave (3 bytes)
    D2		RES 3	;Temperature value from ADC read of slave (3 bytes)
    
    