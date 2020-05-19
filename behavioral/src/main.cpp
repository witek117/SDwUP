#include "Node.hpp"
#include "Huffman.hpp"

uint8_t characters[SYMBOLS_COUNT] = {' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '\0'};
uint8_t frequency[SYMBOLS_COUNT] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
uint8_t symbolLength[SYMBOLS_COUNT] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
uint32_t symbols[SYMBOLS_COUNT] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

const char text[] = "ALA MA KOTA";
const uint8_t textLen = sizeof(text);

#define OUT_BYTES_COUNT 100

uint32_t outputBits[OUT_BYTES_COUNT];

void add(uint8_t bit) {
    static uint8_t len = 0;
    static uint32_t code = 0;

    code |= bit;

    len++;
    for(uint8_t i = 0; i < SYMBOLS_COUNT; i++) {
        if (symbolLength[i] == len) {
            if (symbols[i] == code) {
                printf("%c", characters[i]);
                len = 0;
                code = 0;
                break;
            }
        }
    }
    code <<= 1u;
}

int main(int argc, char* argv[]) {
    (void) argc;
    (void) argv;

    Huffman::clear(frequency, symbols, symbolLength, SYMBOLS_COUNT);
    Huffman::calculateFrequency(frequency, (const uint8_t*)text, sizeof(text)/sizeof(text[0]));
    Huffman::buildTree(characters, frequency, symbols, symbolLength, SYMBOLS_COUNT);

    printf("symbols = [");
    for (int k = 0; k < SYMBOLS_COUNT ; ++k) {
        printf("%d, ", symbols[k]);
    }
    printf("]\n");

    printf("symbolLength = [");
    for (int k = 0; k < SYMBOLS_COUNT ; ++k) {
        printf("%d, ", symbolLength[k]);
    }
    printf("]\n");

    printf("characters = [");
    for (int k = 0; k < SYMBOLS_COUNT ; ++k) {
        printf("%d, ", characters[k]);
    }
    printf("]\n");

    printf("message = [");
    for (int k = 0; k < textLen ; ++k) {
        printf("%d, ", text[k]);
    }
    printf("]\n");
    printf("%d\n", textLen);

    printf("\nCreated dictionary:\n");
    Huffman::print(characters, frequency, symbols, symbolLength, SYMBOLS_COUNT);

    for (int i = 0; i < OUT_BYTES_COUNT; ++i) {
        outputBits[i] = 0;
    }

    // code message
    uint8_t outBytesIndex = 0;
    uint16_t allBitsCount = 0;
    int bitShift = 16;
    for (int j = 0; j < textLen; ++j) {
        uint8_t index = Huffman::getIndex(text[j]);
        uint8_t symbolLen = symbolLength[index];
        bitShift -= symbolLen;
        allBitsCount += symbolLen;
        if (bitShift < 0) {
            uint8_t positive = -bitShift;
            outputBits[outBytesIndex] |= symbols[index] >> positive;
            bitShift = 32 - positive;
            outputBits[outBytesIndex + 1] |= symbols[index] << bitShift;
            outBytesIndex++;
        } else {
            uint32_t kk =  (symbols[index] << (uint8_t)bitShift);
            outputBits[outBytesIndex] |= kk;
        }
    }

    // first 16 bits are bits count
    outputBits[0] |= (allBitsCount << 16u);

    // print bit message
    printf("\nMessage: bit count %d\n", allBitsCount);
    Huffman::print(outputBits, allBitsCount + 16);
    printf("\n");

    // print message as uint variable
    for(int i = 0; i < outBytesIndex + 1; i++ ) {
        printf("DATA: %lu, INDEX: %d\n", outputBits[i], i);
    }

    // decode message
    printf("\nDecoded message:\n");
    for(uint32_t i = 16; i < allBitsCount + 16; i++) {
        uint32_t index = i % 32;
        uint32_t ind = i / 32;
        index = 32 - index - 1;
        uint32_t byte = outputBits[ind] & (1 << index);

        if(byte) {
            add(1);
        } else {
            add(0);
        }
    }
    printf("\n");
}
