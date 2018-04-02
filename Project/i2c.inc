;config file for i2c.asm
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207     ;no label after column one warning
    
    #define BANK0  (h'000')
    #define BANK1  (h'080')
    #define BANK2  (h'100')
    #define BANK3  (h'180')
    
    global  I2Cstart
    global  I2CStop
    global  I2Crestart
    global  waitMSSP
    global  sendACK
    global  sendNACK
    global  enReceive
    global  I2CFail
    global  sendI2Cbyte
    global  I2Csend
    global  twoByteReceive
    global  coeffCPY
    global  adcCPY
    global  i2cByteToSend
    global  twoByteReceive
    global  threeByteReceive
    
    GENVAR	    UDATA
    i2cByteToSend   RES	1
    coeffCPY	    RES	2   ;shadow register for copying PROM coefficients
    adcCPY	    RES	3   ;shadow register for copying temp/press ADC values