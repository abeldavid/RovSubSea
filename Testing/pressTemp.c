/*Simple test program to determine output of MS5837 module*/

#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <inttypes.h>

/*Function prototypes*/
int32_t getUncompPressure();
int32_t getUncompTemperature();

int main (void){
  int32_t PRESSURE;
  int32_t TEMP;
  
  TEMP = getUncompTemperature();
  printf("Uncompensated temperature = %"PRId32 "= %2.2f deg C = %3.2f deg F\n\n", TEMP, TEMP/100.0, ((TEMP/100.0) * 9)/5 +32);
  //PRESSURE = getUncompPressure();
  //printf("Uncompensated pressure value = %"PRId32 " = %8.2f mBar = %4.2f inHg\n\n", PRESSURE, PRESSURE/10.0, (PRESSURE/10.0) / 33.86388667);
  return 0;
}

/*Calculate Pressure value*/
int32_t getUncompPressure(){
  int32_t dt;
  int32_t p;
  int64_t OFF;
  int64_t SENS;
  uint16_t C1 = 978;
  uint16_t C2 = 31763;
  uint16_t C3 = 19252;
  uint16_t C4 = 18722;
  uint16_t C5 = 26597;
  uint32_t D1 = 4398053;
  uint32_t D2 = 7300111;
  
  //Get value for dt 
  dt = D2 -C5 * pow(2, 8);
  //dt = D2 - C5;
  printf("dt = %d\n", dt);
  
  //Get value for OFF 
  OFF = C2 * pow(2, 16) + (C4 * dt) / pow(2, 7);
  printf("OFF = %"PRId64"\n", OFF);
  
  //Get value for SENS 
  SENS = C1 * pow(2, 15) + (C3 * dt)/pow(2, 8);
  printf("SENS = %"PRId64"\n", SENS);
  
  printf("D1 = %u\n", D1);
  printf("D2 = %u\n", D2);
  
  //Get uncompensated presure value
  return ((D1*SENS/pow(2,21)) - OFF) * 1/pow(2,13);
   
}

/*Calculate temperature*/
int32_t getUncompTemperature(){
  uint16_t C5 = 26597;
  uint16_t C6 = 26294;
  uint32_t D2 = 7115661
  ;
  int32_t dt; 
  //int x;
  
  dt = D2 -C5 * pow(2, 8);
  printf("\ndt = %d\n", dt);
  //Get uncompensted temperature value
  return 2000 + dt * (C6 / pow(2, 23));
}












































