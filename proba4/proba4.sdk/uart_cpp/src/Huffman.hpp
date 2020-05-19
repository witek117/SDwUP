#pragma once

#include "Node.hpp"

class Huffman {
    static void sort(Node* tab, uint8_t len);

    static uint8_t getLen(Node* tab);

    static void codeLeft( Node* node);

    static void codeRight(Node* node);

    static void codeIt(Node* node);

public:
    static void buildTree(const uint8_t* characters, const uint8_t* frequency, uint32_t* symbolsCode, uint8_t* symbolsLength, uint8_t length);

    static void calculateFrequency(uint8_t* frequency, const uint8_t* inString, uint8_t inStringLen);

    static void print(Node* tab, uint8_t len);

    static void print(uint8_t* characters, uint8_t* probability, uint32_t* symbols, uint8_t* symbolsLength_m, uint8_t length);

    static void clear(uint8_t* probability, uint32_t* symbols, uint8_t* symbolsLength_m, uint8_t length);

    static uint8_t getIndex(uint8_t c);

    static void print(uint32_t* outBytesTab, uint32_t allBitsCount);
};
