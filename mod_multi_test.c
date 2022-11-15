//A should be the base value
	Xuint32 A[] = {22, 21};
	//B should start as 1
	Xuint32 B[] = {0, 0, 0, 1};

	Xuint32 M[] = {58, 132};
	//should be the secret number
	int exp = 102;
//	Xuint32 key[4];

	xil_printf("Beginning test\r\n\n\n\n\n");

	xil_printf("Writing\r\n");
	//write the initial values
	writeA(mod_multi_base_addr_p, A, 2);
	writeB(mod_multi_base_addr_p, B, 4);
	writeM(mod_multi_base_addr_p, M, 2);

	xil_printf("Reading\r\n");
	readA(mod_multi_base_addr_p);
	readB(mod_multi_base_addr_p);
	readM(mod_multi_base_addr_p);
	Xuint32 rem[4];

	//complete the exponentiation
	for (int i=0; i<=exp;i++) {
		if (i==exp) {
			//do the final modulo
			Xuint32 one[] = {0,1};
			writeA(mod_multi_base_addr_p, one, 2);
		}
		readRemainder(mod_multi_base_addr_p, rem);
		writeB(mod_multi_base_addr_p, rem, 4);
	}

	//readRemainder(mod_multi_base_addr_p, rem);
	xil_printf("Attempting to read the remainder array w/o pointer\r\n");
	for(int i=0; i<4; i++ ) {
		xil_printf("%d\r\n", rem[i]);
	}

	//at this point rem == my_public_int

	xil_printf("Test complete\r\n");