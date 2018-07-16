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
    #define ADCread	     (d'0')	;Read out ADC result
    #define deviceAddrWrite  (d'236')	;Command to perform device write
    #define deviceAddrRead   (d'237')	;Command to perform device read
    #define deviceReset	     (d'30')
    ;Addresses for PROM coefficients
    #define C1	    (d'162')
    #define C2	    (d'164')
    #define C3	    (d'166')
    #define C4	    (d'168')
    #define C5	    (d'170')
    #define C6	    (d'172')
    
    global  slaveReset
    global  sensorData
    
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
    
    extern  tOrP
    extern  SENS
    extern  OFF
    extern  TCS
    extern  TCO
    extern  Tref
    extern  TEMPSENS
    extern  D1
    extern  D2
    
    
    
    