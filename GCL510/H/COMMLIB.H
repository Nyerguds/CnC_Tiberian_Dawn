#ifndef GCL_COMMLIB_H
#define GCL_COMMLIB_H

//#include <windows.h>

#define COM1 (int)0
#define COM2 1
#define COM3 2
#define COM4 3
#define COM5 4

#define ASSUCCESS     0
#define ASUSERABORT -16

enum {
    CTS_SET = 0x10,
    DSR_SET = 0x20,
    RI_SET  = 0x40,
    CD_SET  = 0x80
};

#define PORT struct _tag_port

#endif
