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

#ifndef VQMVESABLIT_H
#define VQMVESABLIT_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     VESABlit.h (32-Bit protected mode)
*
* DESCRIPTION
*     VESA bitblit routines.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     Febuary 3, 1995
*
****************************************************************************/

#include <vqm32\video.h>

/*---------------------------------------------------------------------------
 * FUNCTION PROTOTYPES
 *-------------------------------------------------------------------------*/

void VESA_Blit_640x480(DisplayInfo *disp,unsigned char *buf,long x1,
		long y1,long width,long height);

#ifdef __cplusplus
extern "C" {
#endif

void __cdecl Blit_VESA640x480(DisplayInfo *disp,unsigned char *buf,long x1,
		long y1,long width,long height);

void __cdecl Buf_320x200_To_VESA_320x200(unsigned char *buffer, long grain);
void __cdecl Buf_320x200_To_VESA_640x400(unsigned char *buffer, long grain);
void __cdecl Buf_320x200_To_VESA_32K(unsigned char *buffer,
		unsigned char *palette, long grain);

void __cdecl Copy_Row(char *, char *, long);
void __cdecl Copy_Word_Row(char *source, char *dest, char *palette,
		long numbytes);

#ifdef __cplusplus
}
#endif

#endif /* VQMVESABLIT_H */

