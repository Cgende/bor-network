#ifndef dh_h
#define dh_h

#include "xil_cache.h"
#include "xparameters.h"
#include "PmodBLE.h"
#include "message_receive.h"
#include "mod_multi.h"
#include "int_arr.h"

//this is really the only function that should be called from the outside
// InstancePtr --> pointer to PmodBLE instance
// mod_multi_base_addr_p --> pointer to the base address of a specific modular_multiplication IP core
// key --> empty array for the values of the key to be returned in, 64 bit key will be split across indices 0 and 1
void diffieHellman(PmodBLE InstancePtr, u32 *mod_multi_base_addr_p, u32 key[4]);

//function for receiving the modulus from the controller
// InstancePtr --> pointer to PmodBLE instance
// modulus --> u32 array with two positions, 64 bit modulus will be written across the two positions
void readMod(PmodBLE InstancePtr, u32 modulus[]);

//function for receiving the base from the controller
// InstancePtr --> pointer to PmodBLE instance
// modulus --> u32 array with two positions, 64 bit base will be written across the two positions
void readBase(PmodBLE InstancePtr, u32 base[]);

//function for carrying out the modular multiplication
// mod_multi_base_addr_p --> pointer to the base address of a specific modular_multiplication IP core
// base --> array of 2, 32-bit ints with the 64 bit base spread across the two ints
// modulus --> array of 2, 32-bit ints with the 64 bit modulus spread across the two ints
// power --> u32 representing the exponent of the modular multiplication (in DH this should be your secret int)
// rem --> array of 4, 32-bit ints for the remainder to be written into. Will be filled in ascending order from index 0 -> index 3
void modularMultiply(u32 *mod_multi_base_addr_p, u32 base[2], u32 modulus[2], u32 power, u32 rem[4]);

//function for transmitting your public value to the controller
// InstancePtr --> pointer to PmodBLE instance
// myPublicInt --> array of 4, 32-bit integers containing the 128 bit public int to be sent to the controller
void txMyPublicInt(PmodBLE InstancePtr, u32 myPublicInt[4]);

//function for reading the controller's public integer
// InstancePtr --> pointer to PmodBLE instance
// theirPublicInt --> array of 4, 32-bit integers where the controller's 128 bit public int will be written
void rxTheirPublicInt(PmodBLE InstancePtr, u32 theirPublicInt[4]);


#endif
