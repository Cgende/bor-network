#include "int_arr.h"

// take in array of 8 bit chars, convert into 32 bit integers
void hex2intArr(u8 chars[], int num_chars, u32 arr[], int num_ints) {
		u32 buff;
		int i;
//		u8 c;

		buff = 0;

		for(i=0; i<num_chars; i++) {
				buff = buff << 8;
//				c = chars[i];
				buff = buff+chars[i];

				if ((i+1) % 4 == 0) {
						arr[i / 4] = buff;
						buff = 0;
				}
		}
		return;
}

// take in array of 32 bit integers, convert to 8 bit chars for transmission
void int2hexArr(u8 chars[], int num_chars, u32 arr[], int num_ints) {
        unsigned int buff, temp;
        int i;

        buff = 0;

        for(i=0; i<num_ints; i++) {
                buff = arr[i];
                temp = arr[i];
                for(int j=0; j<4; j++) {
                        buff = buff >> 8;
                        buff = buff << 8;
                        chars[(3-j)+(i*4)] = temp - buff;
                        buff = buff >> 8;
                        temp = temp >> 8;
                }
        }

        return;
}

void thirtyTwo2Eight(u8 eights[], int num_eights, u32 thirtyTwos[], int num_thirtyTwos) {
	for (int i = 0; i<num_thirtyTwos; i++) {
		eights[(i*4)+3] = (u8) (thirtyTwos[i] & 0xFF);
		eights[(i*4)+2] = (u8) (thirtyTwos[i] >> 8) & 0xFF;
		eights[(i*4)+1] = (u8) (thirtyTwos[i] >> 16) & 0xFF;
		eights[(i*4)+0] = (u8) ((thirtyTwos[i] >> 24));
	}

	return;
}

u8 reverseBits(u8 num)
{
    u8 NO_OF_BITS = 8;
    u8 reverse_num = 0;
    int i;
    for (i = 0; i < NO_OF_BITS; i++) {
        if ((num & (1 << i)))
            reverse_num |= 1 << ((NO_OF_BITS - 1) - i);
    }
    return reverse_num;
}

