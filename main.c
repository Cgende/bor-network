/******************************************************************************/
/*                                                                            */
/* main.c -- Example program using the PmodBLE IP                            */
/*                                                                            */
/******************************************************************************/
/* Author: Arthur Brown                                                       */
/*                                                                            */
/******************************************************************************/
/* File Description:                                                          */
/*                                                                            */
/* This demo continuously polls the Pmod BLE and host development board's     */
/* UART connections and forwards each character from each to the other.       */
/*                                                                            */
/******************************************************************************/
/* Revision History:                                                          */
/*                                                                            */
/*    10/04/2017(artvvb):  Created                                            */
/*	  01/16/2017(Tommyk):  Modified to work for PmodBLE						  */
/*                                                                            */
/******************************************************************************/

#include "xil_cache.h"
#include "xparameters.h"
#include "PmodBLE.h"
#include "xbasic_types.h"
#include "mod_multi.h"
#include "int_arr.h"

//required definitions for sending & receiving data over the host board's UART port
#ifdef __MICROBLAZE__
#include "xuartlite.h"
typedef XUartLite SysUart;
#define SysUart_Send            XUartLite_Send
#define SysUart_Recv            XUartLite_Recv
#define SYS_UART_DEVICE_ID      XPAR_AXI_UARTLITE_0_DEVICE_ID
#define BLE_UART_AXI_CLOCK_FREQ XPAR_CPU_M_AXI_DP_FREQ_HZ
#else
#include "xuartps.h"
typedef XUartPs SysUart;
#define SysUart_Send            XUartPs_Send
#define SysUart_Recv            XUartPs_Recv
#define SYS_UART_DEVICE_ID      XPAR_PS7_UART_1_DEVICE_ID
#define BLE_UART_AXI_CLOCK_FREQ 100000000
#endif

PmodBLE myDevice;
SysUart myUart;

Xuint32 *mod_multi_base_addr_p = (Xuint32 *)XPAR_MODULAR_MULTIPLICATI_0_S00_AXI_BASEADDR;

void DemoInitialize();
void DemoRun();
void SysUartInit();
void EnableCaches();
void DisableCaches();

int main()
{
    DemoInitialize();
    DemoRun();
    DisableCaches();
    return XST_SUCCESS;
}

void DemoInitialize()
{
    EnableCaches();
    SysUartInit();
    BLE_Begin (
        &myDevice,
        XPAR_PMODBLE_0_S_AXI_GPIO_BASEADDR,
        XPAR_PMODBLE_0_S_AXI_UART_BASEADDR,
        BLE_UART_AXI_CLOCK_FREQ,
        115200
    );
}

void DemoRun()
{

    u8 buf[1];
    int n;

	xil_printf("Initialized PmodBLE Demo, received data will be echoed here, type to send data\r\n");

	Xuint32 base[] = {0, 69};
	Xuint32 mod[] = {232830643 ,2808348741};

	Xuint32 b[] = {0,0,0,1};

	writeM(mod_multi_base_addr_p, mod, 2);
	writeB(mod_multi_base_addr_p, b, 4);
	writeA(mod_multi_base_addr_p, base, 2);

	int my_secret_int = 43;
//	int my_secret_int = 420;

	Xuint32 rem[4];
	Xuint32 my_pub[4];
		//complete the exponentiation
	for (int i=0; i<=my_secret_int;i++) {
		if (i==my_secret_int) {
			//do the final modulo
			Xuint32 one[] = {0,1};
			writeA(mod_multi_base_addr_p, one, 2);
		}
		readRemainder(mod_multi_base_addr_p, rem);
		writeB(mod_multi_base_addr_p, rem, 4);
	}

	xil_printf("Attempting to read the remainder array w/o pointer\r\n");
		for(int i=0; i<4; i++ ) {
			xil_printf("%d\r\n", rem[i]);
			my_pub[i] = rem[i];
	}

	xil_printf("Attempting to read their public int");

	int their_pub_bytes_rec = 0;
	int their_pub_bytes[8];

	//recieve their 8 bytes
	while(their_pub_bytes_rec < 8) {
		n = BLE_RecvData(&myDevice, buf, 1);
		if (n != 0) {
			SysUart_Send(&myUart, buf, 1);
			their_pub_bytes[their_pub_bytes_rec] = buf[0];
			their_pub_bytes_rec++;
			xil_printf("%d\r\n", buf[0]);
		}

	}

	Xuint32 their_pub_ints[2];
	//cast their 8 bytes to 2 32 bit integers
	hex2intArr(their_pub_bytes, 8, their_pub_ints, 2);

//	Xuint32 their_pub_ints[] = { 99793266, 63568489};

	//write their public value into the mod multiplier
	writeA(mod_multi_base_addr_p, their_pub_ints, 2);
	writeB(mod_multi_base_addr_p, b, 4);

	//complete the exponentiation
	for (int i=0; i<=my_secret_int;i++) {
		if (i==my_secret_int) {
			//do the final modulo
			Xuint32 one[] = {0,1};
			writeA(mod_multi_base_addr_p, one, 2);
		}
		readRemainder(mod_multi_base_addr_p, rem);
		writeB(mod_multi_base_addr_p, rem, 4);
	}

	Xuint32 key[4];
	xil_printf("Attempting to read the key \r\n");
	for(int i=0; i<4; i++ ) {
		xil_printf("%d\r\n", rem[i]);
		key[i] = rem[i];
	}


	xil_printf("Attempting to transmit my public int\r\n");
	Xuint32 my_pub_trunc[2];
	u8 my_pub_bytes[8];

	for (int i=2; i<4; i++) {
		my_pub_trunc[i-2] = my_pub[i];
		xil_printf("%d\r\n", my_pub[i]);
	}

	hex2intArr(my_pub_bytes, 8, my_pub_trunc, 2);

	for (int i=0; i<8; i++) {
		//SysUart_Send(&myUart, my_pub_bytes[i], 1);
		xil_printf("%d\r\n", my_pub_bytes[i]);
		BLE_SendData(&myDevice, my_pub_bytes[i], 1);
	}

	xil_printf("Test complete\r\n");

//    while(1) {
//        //echo all characters received from both BLE and terminal to terminal
//        //forward all characters received from terminal to BLE
//        n = SysUart_Recv(&myUart, buf, 1);
//        if (n != 0) {
//            SysUart_Send(&myUart, buf, 1);
//            BLE_SendData(&myDevice, buf, 1);
//        }
//
//        n = BLE_RecvData(&myDevice, buf, 1);
//        if (n != 0) {
//        	xil_printf("here");
//            SysUart_Send(&myUart, buf, 1);
//        }
//    }
}

//initialize the system uart device, AXI uartlite for microblaze, uartps for Zynq
void SysUartInit()
{
#ifdef __MICROBLAZE__
    XUartLite_Initialize(&myUart, SYS_UART_DEVICE_ID);
#else
    XUartPs_Config *myUartCfgPtr;
    myUartCfgPtr = XUartPs_LookupConfig(SYS_UART_DEVICE_ID);
    XUartPs_CfgInitialize(&myUart, myUartCfgPtr, myUartCfgPtr->BaseAddress);
#endif
}

void EnableCaches()
{
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheEnable();
#endif
#endif
}

void DisableCaches()
{
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}
