/*
 * UART.hpp
 *
 *  Created on: 11 maj 2020
 *      Author: WSN02
 */

#ifndef SRC_UART_HPP_
#define SRC_UART_HPP_

#include "xuartps.h"

class UART {
	XUartPs_Config *Config;
	XUartPs Uart_PS;
	u8 XPAR_XUARTPS;
	u8 txBuf [100];
	u8 rxBuf [100];
	u8 rxCount = 0;
	u8 rxReady = 0;
public:
	UART(u8 XPAR_XUARTPS)
		: XPAR_XUARTPS(XPAR_XUARTPS) {

	}

	u8 init() {
		int Status;
		Config = XUartPs_LookupConfig(XPAR_XUARTPS);
		if (NULL == Config) {
			return XST_FAILURE;
		}
		Status = XUartPs_CfgInitialize(&Uart_PS, Config, Config->BaseAddress);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		return XST_SUCCESS;
	}

	void print(const char data[], u8 len) {

		XUartPs_Send(&Uart_PS, (u8*)data, len);
	}

	void print(u8 data) {
		XUartPs_Send(&Uart_PS, &data, 1);
	}

	void print(const char data[]) {
		u8 len = strlen(data);
		strcpy((char *)txBuf, data );
		XUartPs_Send(&Uart_PS, (u8*)&txBuf, len);
	}

	u8 run() {
		u8 rxOneByte;
		u8 status = XUartPs_Recv(&Uart_PS, &rxOneByte, 1);
		if (status > 0) {
			if (rxOneByte == '\n') {
				rxBuf[rxCount++] = 0; // (u8)('\0');
				rxReady = rxCount - 1;
				rxCount = 0;
//				print(rxOneByte);
				return rxReady;
			} else {
				rxBuf[rxCount++] = rxOneByte;
				rxReady = 0;
			}
//			print(rxOneByte);
		}
		return 0;
	}

	u8* getRxBuffer() {
		return rxBuf;
	}
};


#endif /* SRC_UART_HPP_ */
