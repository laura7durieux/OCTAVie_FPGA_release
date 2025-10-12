#ifndef IO_H
#define IO_H

#include "gui.h"
#include "msg.h"
//***************************************************
// Define
//***************************************************

//#define OS_POSIX
//#define OS_WIN

#define DEFAULT_COM_PORT 0
#ifdef OS_POSIX
#define DEFAULT_LINUX_COM_PORT_PATH "/dev/ttyUSB"
#endif
#ifdef OS_WIN
#define DEFAULT_LINUX_COM_PORT_PATH "\\\\.\\COM"
#endif
#define DEFAULT_OUTPUT_FILE "FFT_data.csv"

#define COM_OPEN_ERROR -1

//***************************************************
// Prototypes
//***************************************************

// COM port reading thread
void* read_com(void* data);

// File transfert function
void* record_data(void* data);

// File transfert function
void* update_graph(void* data);

#endif
