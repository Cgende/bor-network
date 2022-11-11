
//#include "xbasic_types.h"
//#include "xparameters.h"
#include "mod_multi.h"

// offsets from mod multi base address are as follows
// base_addr+0 - base_addr+3 --> A
// base_addr+4 - base_addr+11 --> B
// base_addr+12 - base_addr+15 --> M
// base_addr+16 - base_addr+23 --> remainder


int writeA(Xuint32 *base_addr, Xuint32 num[], int len) {
	//function for writing an array into the memory for A val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 4) {
		return 1;
	}

	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		*(base_addr+i) = num[i];
		xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

int writeB(Xuint32 *base_addr, Xuint32 num[], int len) {
	//function for writing an array into the memory for B val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 4) {
			return 1;
	}
	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		//use +4 to get offset to the B registers
		*(base_addr+4+i) = num[i];
		//xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

int writeM(Xuint32 *base_addr, Xuint32 num[], int len) {
	//function for writing an array into the memory for M val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 4) {
			return 1;
	}
	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		//use +12 to get offset to the M registers
		*(base_addr+12+i) = num[i];
		//xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

void readRemainder(Xuint32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 8; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+16+i));
	}
}
void readA(Xuint32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 4; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+0+i));
	}
}
void readB(Xuint32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 8; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+8+i));
	}
}
void readM(Xuint32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 4; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+12+i));
	}
}
