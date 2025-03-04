#ifndef GCL_MODEM_H
#define GCL_MODEM_H

#include "commlib.h"

typedef void ( *__gcl_func)(char);

#ifdef __cplusplus
extern "C" {
#endif
void HMSetUpEchoRoutine( __gcl_func );
void HMWaitForOK(long, char *);
#ifdef __cplusplus
}
#endif

#endif
