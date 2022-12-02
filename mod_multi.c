//#include "xbasic_types.h"
//#include "xparameters.h"
#include "mod_multi.h"

// offsets from mod multi base address are as follows
// base_addr+0 - base_addr+1 --> A
// base_addr+2 - base_addr+5 --> B
// base_addr+6 - base_addr+7 --> M
// base_addr+16 - base_addr+19 --> remainder


int writeA(u32 *base_addr, u32 num[], int len) {
	//function for writing an array into the memory for A val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 2) {
		return 1;
	}

	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		*(base_addr+i) = num[i];
//		xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

int writeB(u32 *base_addr, u32 num[], int len) {
	//function for writing an array into the memory for B val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 4) {
			return 1;
	}
	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		//use +4 to get offset to the B registers
		*(base_addr+2+i) = num[i];
//		xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

int writeM(u32 *base_addr, u32 num[], int len) {
	//function for writing an array into the memory for M val of the mod multiplier
	//precondition: array must be less than 4
	if (len > 2) {
			return 1;
	}
	int i = 0;
	//xil_printf("Attempting to write array to uart\r\n");
	for( i=0; i < len; i++ ) {
		//use +12 to get offset to the M registers
		*(base_addr+6+i) = num[i];
//		xil_printf("%d\r\n", num[i]);
	}

	return 0;
}

void readRemainder(u32 *base_addr, u32 rem[]) {
	//need to figure out how to return the array value here
	int i=0;
	//u32 rem[4];
	for( i=0; i < 4; i++ ) {
		//use +16 to get offset to the remainder registers
		rem[i] = *(base_addr+16+(3-i));
//		xil_printf("%d\r\n", *(base_addr+16+(3-i)));
	}


}
void readA(u32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 2; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+0+i));
	}
}
void readB(u32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 4; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+2+i));
	}
}
void readM(u32 *base_addr) {
	//need to figure out how to return the array value here
	int i=0;
	for( i=0; i < 2; i++ ) {
		//use +16 to get offset to the remainder registers
		xil_printf("%d\r\n", *(base_addr+6+i));
	}
}
