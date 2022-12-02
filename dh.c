#include "dh.h"


void readMod(PmodBLE InstancePtr, u32 modulus[]) {
	u8 mod_bytes[8];

	//receive their 8 bytes
	message_receive(8, mod_bytes, InstancePtr);

	//cast their 8 bytes to 2 32 bit integers
	hex2intArr(mod_bytes, 8, modulus, 2);

//	xil_printf("Base received\r\n");
//	for(int i=0;i<2;i++){
//		xil_printf("%u\r\n", modulus[i]);
//	}
}

void readBase(PmodBLE InstancePtr, u32 base[]) {
	u8 buf[1];
	u8 base_bytes[8]= {0,0,0,0,0,0,0,0};

	message_receive(1, buf, InstancePtr);
	base_bytes[7] = buf[0];

	xil_printf("Base received\r\n");

	//cast their 8 bytes to 2 32 bit integers
	hex2intArr(base_bytes, 8, base, 2);
}

void modularMultiply(u32 *mod_multi_base_addr_p, u32 base[2], u32 modulus[2], u32 power, u32 key[4]) {
	u32 b[] = {0,0,0,1};
	u32 rem[4];

	writeM(mod_multi_base_addr_p, modulus, 2);
	writeB(mod_multi_base_addr_p, b, 4);
	writeA(mod_multi_base_addr_p, base, 2);

	for (int i=0; i<=power; i++) {
		if (i==power) {
			//do the final modulo
			u32 one[] = {0,1};
			writeA(mod_multi_base_addr_p, one, 2);
		}
		readRemainder(mod_multi_base_addr_p, rem);
		writeB(mod_multi_base_addr_p, rem, 4);
	}

	for (int i=2;i<4;i++) {
		key[i-2] = rem[i];
	}
}

void txMyPublicInt(PmodBLE InstancePtr, u32 myPublicInt[4]) {
	xil_printf("Attempting to transmit my public int\r\n");
	u32 my_pub_trunc[2];
	u8 my_pub_bytes[8];

	for (int i=0; i<2; i++) {
		my_pub_trunc[i] = myPublicInt[i];
	}

	int2hexArr(my_pub_bytes, 8, my_pub_trunc, 2);

	BLE_SendData(&InstancePtr, my_pub_bytes, 8);
	xil_printf("Public int sent\r\n");
}

void rxTheirPublicInt(PmodBLE InstancePtr, u32 theirPublicInt[2]) {
	u8 their_pub_bytes[8];
	//receive their public values
	message_receive(8, their_pub_bytes, InstancePtr);

	//cast their 8 bytes to 2 32 bit integers
	hex2intArr(their_pub_bytes, 8, theirPublicInt, 2);

//	for( int i=0; i<2; i++) {
//		xil_printf("%u\r\n", theirPublicInt[i]);
//	}
}

void diffieHellman(PmodBLE InstancePtr, u32 *mod_multi_base_addr_p, u32 key[4]) {
	u32 base[] = {0, 0};
	u32 mod[] = {0, 0};

	readMod(InstancePtr, mod);

	xil_printf("Mod received, attempting to receive base\r\n");

	readBase(InstancePtr, base);

	//should come up with a way to get my secret int
	int my_secret_int = 43;

	u32 my_public_int[4];

	//complete the exponentiation
	modularMultiply(mod_multi_base_addr_p, base, mod, my_secret_int, my_public_int);


	xil_printf("Attempting to read their public int\r\n");
	u32 their_public_int[4];
	rxTheirPublicInt(InstancePtr, their_public_int);

//	u32 temp_key[4];
	//write their public value into the mod multiplier
	modularMultiply(mod_multi_base_addr_p, their_public_int, mod, my_secret_int, key);

	xil_printf("Attempting to read the key \r\n");
	for(int i=0; i<2; i++ ) {
		key[i+2] = key[i];
	}

	//print the key
//	xil_printf("Key:\r\n");
//	for(int i=0; i < 4; i++) {
//		xil_printf("%u\r\n", key[i]);
//	}

	txMyPublicInt(InstancePtr, my_public_int);

	xil_printf("Public int sent\r\n");

	return;
}
