


#ifndef message_receive_h
#define message_receive_h

#include "xuartps.h"
typedef XUartPs SysUart;
#define SysUart_Send            XUartPs_Send
#define SysUart_Recv            XUartPs_Recv
#define SYS_UART_DEVICE_ID      XPAR_PS7_UART_1_DEVICE_ID
#define BLE_UART_AXI_CLOCK_FREQ 100000000
//#endif

#include "xil_cache.h"
#include "xparameters.h"
#include "PmodBLE.h"
#include "aes.h"


//function for receiving data, data will be written into arr, blocks until num_bytes received
void message_receive(int num_bytes, u8 arr[], PmodBLE InstancePtr);

// increments IV
void incrementIV(u8 IV[16]);

//listens for, decrypts and process messages as they come in
// to do: return message/add in forwarding
void listen_for_messages(PmodBLE InstancePtr, SysUart myUart, u8 iv[16], u8 key[16]);

#endif
