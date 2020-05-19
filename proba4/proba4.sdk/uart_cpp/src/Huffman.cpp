#include "Huffman.hpp"
#include <cstring>
#include <cmath>

static Node nodeTabPointers[2 * 50];
static Node startNode;
uint32_t* symbolsCode;
uint8_t* symbolsLength;

const char *byte_to_binary(int x, int len) {
    static char b[9];
    b[0] = '\0';

    int z;
    z = pow(2, len - 1); // 2 ^ len;
    for (; z > 0; z >>= 1u ) {
        strcat(b, ((x & z) == z) ? "1" : "0");
    }

    return b;
}


void  Huffman::print(uint32_t* outBytesTab, uint32_t allBitsCount) {
    for(uint32_t i = 0; i < allBitsCount; i++) {
        uint32_t index = i % 32;
        if (index == 0) {
            printf(" ");
        }
        uint32_t ind = i / 32;
        index = 32 - index - 1;

        uint32_t byte = outBytesTab[ind] & (1 << index);
        if(byte) {
            printf("1");
        } else {
            printf("0");
        }
    }
}

void Huffman::sort(Node* tab, uint8_t len) {
    Node tempNode;
    bool changed = false;
    for (int j = 0; j < len; ++j) {
        changed = false;
        for(uint8_t i = 0; i < len - 1; i++) {
            if (tab[i].frequency < tab[i+1].frequency) {
                tempNode = tab[i];
                tab[i] = tab[i+1];
                tab[i+1] = tempNode;
                changed = true;
            }
        }

        if(!changed) {
            break;
        }
    }
}

uint8_t Huffman::getLen(Node* tab) {
    uint8_t i;
    for (i = 0; i < 255; ++i) {
        if(tab[i].frequency == 0) {
            return i;
        }
    }
    return 0;
}

void Huffman::print(Node* tab, uint8_t len) {
    printf("Print:\n");
    for (uint8_t i = 0; i < len; ++i) {
        printf("%c %d \n", tab[i].character, tab[i].frequency);
    }
}

void Huffman::print(uint8_t* characters, uint8_t* probability, uint32_t* symbols, uint8_t* symbolsLength_m, uint8_t length) {
    for(uint8_t i = 0; i < length; i++) {
        printf("char: %c %d, probability: %d, len: %d, code: %s\n" , characters[i], characters[i], probability[i], symbolsLength_m[i], byte_to_binary(symbols[i], symbolsLength_m[i]));
    }
}


void codeRight(Node* node);

void Huffman::codeLeft( Node* node) {
    node->codeLen++;
    node->code = node->code << 1u;

    if (node->character > 0) {
        uint8_t index = getIndex(node->character);
        ::symbolsCode[index] = node->code;
        ::symbolsLength[index] = node->codeLen;
//        printf("char: %c %d, probability: %d, len: %d, code: %s\n" , node->character, node->character, node->frequency,  node->codeLen, byte_to_binary(node->code, node->codeLen));
    } else {
        node->left->codeLen = node->codeLen;
        node->left->code = node->code;
        codeLeft(node->left);

        node->right->codeLen = node->codeLen;
        node->right->code = node->code;

        codeRight(node->right);
    }
}

void Huffman::codeRight(Node* node) {
    node->codeLen++;
    node->code = node->code << 1u;
    node->code |= 1u;

    if (node->character > 0) {
        uint8_t index = getIndex(node->character);
        ::symbolsCode[index] = node->code;
        ::symbolsLength[index] = node->codeLen;
//        printf("char: %c %d, probability: %d, len: %d, code: %s\n" , node->character, node->character, node->frequency, node->codeLen, byte_to_binary(node->code, node->codeLen));
    } else {
        node->left->codeLen = node->codeLen;
        node->left->code = node->code;
        codeLeft(node->left);

        node->right->codeLen = node->codeLen;
        node->right->code = node->code;

        codeRight(node->right);
    }
}

void Huffman::codeIt(Node* node) {
    node->left->code = 0;
    node->left->codeLen = 0;
    codeLeft(node->left);

    node->right->code = 0;
    node->right->codeLen = 0;
    codeRight(node->right);
}

void Huffman::buildTree(const uint8_t* characters, const uint8_t* frequency, uint32_t* symbolsCode, uint8_t* symbolsLength_m, uint8_t length) {
    Node nodeTab[length];
    ::symbolsCode = symbolsCode;
    ::symbolsLength = symbolsLength_m;

    for(uint8_t i =0; i < length; i++) {
        nodeTab[i].frequency = frequency[i];
        nodeTab[i].character = characters[i];
    }

    uint8_t len = 0; //  = getLen(nodeTab);
    uint16_t index = 0;
    while(true) {
        sort(nodeTab, length);
        len = getLen(nodeTab);
        if (len < 2) {
            ::startNode = nodeTab[0];
            break;
        }

        len -= 2;
        ::nodeTabPointers[index] = nodeTab[len];
        ::nodeTabPointers[index + 1]= nodeTab[len + 1];

        nodeTab[len].frequency = ::nodeTabPointers[index].frequency + ::nodeTabPointers[index + 1].frequency;
        nodeTab[len].right = &::nodeTabPointers[index];
        nodeTab[len].left = &::nodeTabPointers[index + 1];
        nodeTab[len].character = 0;
        nodeTab[len + 1].frequency = 0;
        nodeTab[len + 1].character = 0;
        index += 2;
    }

    codeIt(&::startNode);
}

void Huffman::calculateFrequency(uint8_t* frequency, const uint8_t* inString, uint8_t inStringLen) {
    for (uint8_t i = 0; i < inStringLen; ++i) {
        frequency[getIndex(inString[i])]++;
    }
}

uint8_t Huffman::getIndex(uint8_t c) {
    if (c == ' ') {
        return 0;
    } else {
        c -= 'A';
        c++;
        return c;
    }
}

void Huffman::clear(uint8_t* probability, uint32_t* symbols, uint8_t* symbolsLength_m, uint8_t length) {
    for(uint8_t i = 0; i < length; i++) {
        probability[i] = 0;
        symbols[i] = 0;
        symbolsLength_m[i] = 0;
    }
}
