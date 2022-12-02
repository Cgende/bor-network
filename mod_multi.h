#ifndef mod_multi_h
#define mod_multi_h

#include "xparameters.h"
#include "xuartps.h"

//function for writing an array into the memory for A val of the mod multiplier
//precondition: array must be less than 4
int writeA(u32 *base_addr, u32 num[], int len) ;

//function for writing an array into the memory for B val of the mod multiplier
//precondition: array must be less than 8
int writeB(u32 *base_addr, u32 num[], int len);

//function for writing an array into the memory for M val of the mod multiplier
//precondition: array must be less than 4
int writeM(u32 *base_addr, u32 num[], int len) ;

//returns address of array with 4, 32 bit ints --> ie the remainder across 4 registers
void readRemainder(u32 *base_addr, u32 rem[]) ;

//not sure if we need to actually return array or just use for debug
void readA(u32 *base_addr) ;
void readB(u32 *base_addr) ;
void readM(u32 *base_addr) ;


#endif
