;config file for math.asm
    
    errorlevel -302	;no "register not in bank 0" warnings
    errorlevel -207    ;no label after column one warning
    
    global  getTemp
    
    
    extern  TEMPSENS
    extern  Tref
    extern  D2
    extern  D1
    extern  sensorData
    extern  tOrP
    extern  adcCPY
    extern  slaveReset
    
    extern  product32
    extern  mpcand32
    extern  loopCount
    extern  negFlag
    extern  deeT
    extern  remainder
    extern  divisor
    extern  Q
    extern  TempC
    extern  TempF
    extern  negFaren
    
   
    
    