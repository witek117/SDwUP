/*
 * platform_includes.hpp
 *
 *  Created on: 13 maj 2020
 *      Author: WSN02
 */

#ifndef SRC_PLATFORM_INCLUDES_HPP_
#define SRC_PLATFORM_INCLUDES_HPP_


#include "xil_types.h"
#include "xil_printf.h"

#define printf(f_, ...) xil_printf((f_), ##__VA_ARGS__)

#endif /* SRC_PLATFORM_INCLUDES_HPP_ */
