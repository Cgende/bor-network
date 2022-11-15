#include "int_arr.h"

// take in array of 8 bit chars, convert into 32 bit integers
void hex2intArr(int chars[], int num_chars, Xuint32 arr[], int num_ints) {
		unsigned int buff;
		int i;
		int c;

		buff = 0;

		for(i=0; i<num_chars; i++) {
				buff = buff << 8;
				c = chars[i];
				buff = buff+c;

				if ((i+1) % 4 == 0) {
						arr[i / 4] = buff;
						buff = 0;
				}
		}
		return;
}

// take in array of 32 bit integers, convert to 8 bit chars for transmission
void int2hexArr(int chars[], int num_chars, Xuint32 arr[], int num_ints) {
        unsigned int buff, temp;
        int i;

        buff = 0;

        for(i=0; i<num_ints; i++) {
                buff = arr[i];
                temp = arr[i];
                for(int j=0; j<4; j++) {
                        buff = buff >> 8;
                        buff = buff << 8;
                        chars[j+(i*4)] = temp - buff;
                        buff = buff >> 8;
                        temp = temp >> 8;
                }
        }

        return;
}

