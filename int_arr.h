#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <math.h>
#include <xbasic_types.h>

// pass in an array of hexidecimal values represented by their ascii values
// writes the values into arr as 32 bit integers
void hex2intArr(int chars[], int num_chars, Xuint32 arr[], int num_ints);
void int2hexArr(int chars[], int num_chars, Xuint32 arr[], int num_ints);
