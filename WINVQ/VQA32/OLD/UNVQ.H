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

#ifndef VQAUNVQ_H
#define VQAUNVQ_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* PROJECT
*     VQAPlay32 library. (32-Bit protected mode)
*
* FILE
*     unvq.h
*
* DESCRIPTION
*     VQ frame decompress definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     Feburary 8, 1995
*
****************************************************************************/

#ifdef PHARLAP_TNT
#include <pltypes.h>
#endif

/*---------------------------------------------------------------------------
 * FUNCTION PROTOTYPES
 *-------------------------------------------------------------------------*/

#ifdef __cplusplus
extern "C" {
#endif

/* unvqbuff.asm */
#ifndef PHARLAP_TNT
void cdecl UnVQ_2x2(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);

void cdecl UnVQ_2x3(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);

void cdecl UnVQ_4x2(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);

void cdecl UnVQ_4x4(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);

void cdecl UnVQ_4x2_Woofer(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);

/* unvqvesa.asm */
void cdecl UnVQ_4x2_VESA320_32K(unsigned char *codebook,
		unsigned char *pointers, unsigned char *palette,
		unsigned long grains_per_win,unsigned long dummy1,unsigned long dummy2);

#else /* PHARLAP_TNT */

void cdecl UnVQ_2x2(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth);

void cdecl UnVQ_2x3(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth);

void cdecl UnVQ_4x2(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth);

void cdecl UnVQ_4x4(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth);

/* unvqvesa.asm */
void cdecl UnVQ_4x2_VESA320_32K(unsigned char *codebook,
		unsigned char *pointers, FARPTR palette, unsigned long grains_per_win,
		unsigned long dummy1, unsigned long dummy2);

#endif /* PHARLAP_TNT */

/* unvqxmde.asm */
void cdecl UnVQ_4x2_Xmode(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long dummy);

void cdecl UnVQ_4x2_XmodeCB(unsigned char *cbdummy, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long dummy);

void cdecl Upload_4x2CB(unsigned char *codebook, unsigned long numentries);
void cdecl XlatePointers(unsigned char *pointers, unsigned long numpointers);

#ifdef __cplusplus
}
#endif

#endif /* VQAUNVQ_H */
