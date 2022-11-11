

#ifndef mod_multi_h
#define mod_multi_h

#include "xbasic_types.h"
#include "xparameters.h"
#include "xuartps.h"

//function for writing an array into the memory for A val of the mod multiplier
//precondition: array must be less than 4
int writeA(Xuint32 *base_addr, Xuint32 num[], int len) ;

//function for writing an array into the memory for B val of the mod multiplier
//precondition: array must be less than 8
int writeB(Xuint32 *base_addr, Xuint32 num[], int len);

//function for writing an array into the memory for M val of the mod multiplier
//precondition: array must be less than 4
int writeM(Xuint32 *base_addr, Xuint32 num[], int len) ;

//need to figure out how to return the array value here
void readRemainder(Xuint32 *base_addr) ;

void readA(Xuint32 *base_addr) ;
void readB(Xuint32 *base_addr) ;
void readM(Xuint32 *base_addr) ;


#endif
