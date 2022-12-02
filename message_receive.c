#include "message_receive.h"

void message_receive(int num_bytes, u8 arr[], PmodBLE InstancePtr) {
	int bytes_rec = 0;
	u8 buf[1];
	int n;
	while(bytes_rec < num_bytes) {
		n = BLE_RecvData(&InstancePtr, buf, 1);
		if (n != 0) {
			arr[bytes_rec] = buf[0];
			bytes_rec++;
//			xil_printf("%d\r\n", buf[0]);
		}
	}
}

//assumes IV to be 16 bytes
void incrementIV(u8 IV[16]) {
	int i = 15;
	while (IV[i] == 255) {
		IV[i] = 0;
		i--;
		if (i<0) {
			return;
		}
	}
	IV[i] = IV[i]+1;

	return;
}

void listen_for_messages(PmodBLE InstancePtr, SysUart myUart, u8 iv[16], u8 key[16]) {
	u8 buf[1], n;

	u8 rx_message_contents[256];
	u8 packets_recvd = 0;
	u8 rx_packet_data[16];


//	u8 tx_message_contents[256];
//	u8 tx_chars = 0;

	struct AES_ctx ctx;
	u8 tx_data[] = {0,0,0,0,0,0,0,0,0,0,0,104,101,108,108,111};
	AES_init_ctx_iv(&ctx, key, iv);
	AES_CBC_encrypt_buffer(&ctx, tx_data, 16);

	u8 tx_payload[20];
	tx_payload[0] = 128;
	for (int i=1; i<20; i++) {
		if (i<4) {
			tx_payload[i]=0;
		}
		else {
			tx_payload[i] = tx_data[i-4];
		}
	}

	xil_printf("Encrypted payload\r\n");
	for(int i=0; i<20; i++) {
		xil_printf("%d\r\n", tx_payload[i]);
	}


	xil_printf("Transmitting");
//	BLE_SendData(&InstancePtr, tx_payload, 20);
	for (int i=0;i<20;i++) {
		u8 temp[1];
		temp[0] = tx_payload[i];
		BLE_SendData(&InstancePtr, temp, 1);
		for(int j=0; j<10000; j++) {}
//		xil_printf("%d\r\n", temp[0]);
	}

	while(1) {
		//echo all characters received from both BLE and terminal to terminal
		//forward all characters received from terminal to BLE
		n = SysUart_Recv(&myUart, buf, 1);
		if (n != 0) {
			//listen until end packet, writing characters into a buffer
			// after return, break into 15 byte lengths, encrypt and send
			xil_printf("send data");
		}

		n = BLE_RecvData(&InstancePtr, buf, 1);
		if (n != 0) {
			u8 header = buf[0];
//			xil_printf("header: %d\r\n", header);

			u8 packet_payload[19];
			message_receive(19, packet_payload, InstancePtr);
			for(int i=0; i<19; i++) {
				if (i>=3) {
					rx_packet_data[i-3] = packet_payload[i];
//					xil_printf("%d\r\n", packet_payload[i]);
				}
			}

//			struct AES_ctx ctx;
			AES_init_ctx_iv(&ctx, key, iv);
			AES_CBC_decrypt_buffer(&ctx, rx_packet_data, 16);
			xil_printf("Message decrypted\r\n");
			incrementIV(iv);

			for (int i=0; i<16; i++) {
				int array_write_pos = (packets_recvd*16) + i;
//				xil_printf("%d\r\n",rx_packet_data[i]);
				rx_message_contents[array_write_pos] = rx_packet_data[i];
//				xil_printf("%d\r\n",rx_message_contents[array_write_pos]);
			}
			packets_recvd++;
			if (header & 0x80) {
				//packet was the last of a message

				//print the decrypted message
				xil_printf("Decrypted Message: \r\n");
				for (int i=0; i<packets_recvd*16; i++) {
					if (rx_message_contents[i] > 0) {
						xil_printf("%c", rx_message_contents[i]);
						rx_message_contents[i] = 0;
					}
					if (i % 80 == 0 && i!=0) {
						xil_printf("\r\n");
					}
				}
				xil_printf("\r\n");
				packets_recvd = 0;
			}
//			if (packet_payload[0] & 0x80) {
//				//packet was the first of a message but not the last
//
//			}

		}
	}


}
