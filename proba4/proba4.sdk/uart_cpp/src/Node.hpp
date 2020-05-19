#pragma once

#include "platform_includes.hpp"

#define SYMBOLS_COUNT 28

struct Node {
    uint8_t character = 0;
    uint32_t frequency = 0;
    Node* left = nullptr;
    Node* right = nullptr;
    uint32_t code = 0;
    uint8_t codeLen = 0;
};

