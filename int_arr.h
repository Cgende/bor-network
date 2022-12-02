#ifndef int_arr_h
#define int_arr_h

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <math.h>
#include "xuartps.h"


// pass in an array of hexidecimal values represented by their ascii values
// writes the values into arr as 32 bit integers
void hex2intArr(u8 chars[], int num_chars, u32 arr[], int num_ints);
void int2hexArr(u8 chars[], int num_chars, u32 arr[], int num_ints);
void thirtyTwo2Eight(u8 eights[], int num_eights, u32 thirtyTwos[], int num_thirtyTwos);
// https://www.geeksforgeeks.org/write-an-efficient-c-program-to-reverse-bits-of-a-number/
u8 reverseBits(u8 num);

#endif
