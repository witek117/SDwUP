#include <stdio.h>

#include "platform.h"
#include "xil_printf.h"
#include "xuartps.h"
#include "UART.hpp"
#include "Huffman.hpp"
#include "xparameters.h"
#include "myip2.h"

#define CODER_BASE_ADDR XPAR_MYIP2_0_S00_AXI_BASEADDR

#define INPUT_DATA MYIP2_S00_AXI_SLV_REG0_OFFSET
#define INPUT_SYMBOLS MYIP2_S00_AXI_SLV_REG1_OFFSET
#define OUTPUT_STATE MYIP2_S00_AXI_SLV_REG2_OFFSET
#define OUTPUT_DATA MYIP2_S00_AXI_SLV_REG3_OFFSET

#define SET_SYMBOL(param) (((u32)(param) & 0xFF) <<  8)
#define SET_CHARACTER(param) (((u32)(param) & 0xFF) <<  16)
#define SET_MESSAGE(param) (((u32)(param) & 0xFF) <<  24)


#define SYMBOLS_COUNT 28

uint8_t characters[28] = {' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '\0'};
uint8_t frequency[28] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
uint8_t symbolLength[28] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
uint32_t symbols[28] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

char text[100] = "W H"; //  BEDZIE TRUDNIEJSZE O WIELE
uint8_t MESSAGE_LEN = strlen(text); // sizeof(text);

UART uart(XPAR_XUARTPS_1_DEVICE_ID);

u32 outData[100];

int main() {
	u32 mes1 = 0;
	u32 mes2 = 0;

    init_platform();
    uart.init();
    uart.print("\n\nHello Huffman Coder!!\n\n");

	while(1) {
		u8 len = uart.run();
		volatile u8* rxBuff;
		if (len ) { // if data received
			rxBuff = uart.getRxBuffer();
			memset(text, 0, sizeof(text)); // clear old data
			memcpy(text, (u8*)rxBuff, len); // copy new data
			printf("RECEIVED TEXT: %s\n", rxBuff);
			printf("TEXT LENGTH: %d\n", len);
			MESSAGE_LEN = strlen(text);

			// prepare Huffman data
		    Huffman::clear(frequency, symbols, symbolLength, SYMBOLS_COUNT);

		    // Calculate chars probabilities
		    Huffman::calculateFrequency(frequency, (const uint8_t*)text, MESSAGE_LEN);

		    // build Tree
		    Huffman::buildTree(characters, frequency, symbols, symbolLength, SYMBOLS_COUNT);

		    // print Tree
		    printf("\nDICTIONARY\n");
		    Huffman::print(characters, frequency, symbols, symbolLength, SYMBOLS_COUNT);

		    // reset input registers
			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_SYMBOLS, 0);
			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 0);

			// manual reset
		    MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, (1 << 3));
			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 0);

			// send tables length
			mes1 = 1; // dataClock = 1
			mes1 |= SET_SYMBOL(SYMBOLS_COUNT);
			mes2 = SYMBOLS_COUNT;
			mes1 |= SET_CHARACTER(SYMBOLS_COUNT);
			mes1 |= SET_MESSAGE(MESSAGE_LEN + 1);

			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_SYMBOLS, mes2);
			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, mes1);
			MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 0);

			// send all data
			int i = 0;
			while(1) {
				mes1 = 1; // dataClock = 1

				if (i < SYMBOLS_COUNT) {
					mes1 |= SET_SYMBOL(symbols[i]);
					mes2 = symbolLength[i];
					mes1 |= SET_CHARACTER(characters[i]);
				} else {
					mes1 |= (1 << 2); // dataloaded = 1
				}

				if (i < MESSAGE_LEN) {
					mes1 |= SET_MESSAGE(text[i]);
				} else {
					mes1 |= (1 << 1); // messageLoaded = 1
				}
				MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_SYMBOLS, mes2);
				MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, mes1);
				MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 0);

				if (i >= SYMBOLS_COUNT && i >= MESSAGE_LEN) {
					break;
				}
				i++;
			}

			// wait for ready, and calculate time
			u32 result = 0;
			for(i=0; i < 100; i++ ) {
				result = MYIP2_mReadReg(CODER_BASE_ADDR, OUTPUT_STATE);
				if (result & 1) {
					break;
				}
			}

			printf("\n\nDONE DATA   IN %d CYCLES \n\n", i);

			// get data from FPGA
			u32 limit = 5;
			for(u32 i  = 0; i < limit; i++) {
				MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 1); // data clock to 1
				MYIP2_mWriteReg(CODER_BASE_ADDR, INPUT_DATA, 0); // data clock to 0
				outData[i] = MYIP2_mReadReg(CODER_BASE_ADDR, OUTPUT_DATA);
				printf("DATA: %lu, INDEX: %d\n", outData[i], MYIP2_mReadReg(CODER_BASE_ADDR, OUTPUT_STATE) & 0xFFFF);

				if (i == 0) {
					u32 result = outData[0] >> 16;
					result += 16;
					if (result % 32) {
						limit = result / 32 + 1;
					} else {
						limit = result / 32;
					}
				}
				outData[i] = 0;
			}
			printf("\n\nEND\n\n");
		}
	}

    cleanup_platform();
    return 0;
}
