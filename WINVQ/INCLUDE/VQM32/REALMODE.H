/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef VQMREALMODE_H
#define VQMREALMODE_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     realmode.h
*
* DESCRIPTION
*     Real-mode interfacing definitions and equates. Many of the definitions
*     and descriptions in this file were taken from other sources and
*     compiled here for use in MISC32 library.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     Febuary 6, 1995
*
****************************************************************************/

/* REALPTR: Real-mode pointer (segment:offset16).
 *
 * The REALPTR data type is used in protected mode to hold real-mode
 * pointers. The type is an unsigned long value, were the upper 16 bits
 * are the segment number and the lower 16 bit are an offset. This type
 * and the associated macros are identical to that of the PHARLAP "pltypes.h"
 * definitions for easy of conversion to WATCOM/4GW.
 */
typedef unsigned long REALPTR;

#define RP_OFF(rp) ((unsigned short)(((unsigned long)(rp)) & 0xFFFF))
#define RP_SEG(rp) ((unsigned short)(((unsigned long)(rp)) >> 16))
#define RP_SET(rp, off, seg) (rp = ((unsigned long)(seg) << 16) + (off))
#define RP_INCR(rp, incr) (rp += ((unsigned long)(incr)) & 0xFFFF)

#define MK_PTR(off, seg) (void *)((((unsigned long)seg&0xFFFF)<<4)+off)

/* RMInfo: Real-mode interrupt call structure.
 *
 * Information that needs to be passed down to the real-mode interrupt is
 * transfered using this structure. The address to this protected-mode
 * structure (allocated by user) is passed into DPMI function 0x300. DOS/4GW
 * will then use this information to set up the real-mode registers, switch
 * to real-mode and then execute the interrupt in real-mode.
 */
typedef struct _RMInfo {
	long  edi;
	long  esi;
	long  ebp;
	long  reservedbysystem;
	long  ebx;
	long  edx;
	long  ecx;
	long  eax;
	short flags;
	short es,ds,fs,gs,ip,cs,sp,ss;
} RMInfo;

#endif /* VQMREALMODE_H */

