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

#ifndef VQFILE_H
#define VQFILE_H
/****************************************************************************
*
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     VQFile.h
*
* DESCRIPTION
*     VQ file format definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*      
* DATE
*     September 27, 1995
*
****************************************************************************/

#include <vqm32\iff.h>

/* Disable Watcom structure alignment. */
#ifdef __WATCOMC__
#pragma pack(1);
#endif

/*---------------------------------------------------------------------------
 * STRUCTURE DEFINITIONS AND RELATED INFORMATION
 *-------------------------------------------------------------------------*/

/* VQHeader: VQ header.
 *
 * Version     - VQ file version
 * Flags       - Various flags (see below)
 * ImageWidth  - Width of constructed image in pixels.
 * ImageHeight - Height of contructed image in pixels.
 * BlockType   - Type of codebook block. (EX: rectangle)
 * BlockWidth  - Width of a codebook block in pixels.
 * BlockHeight - Height of a codebook block in pixels.
 * BlockDepth  - Depth of a codebook block in bits.
 * CBEntries   - Number of entries in the codebook.
 * VPtrType    - Vector pointer type. (IE: Banked)
 * PalStart    - Starting entry position of palette.
 * PalLength   - Number of palette entries the palette.
 * PalDepth    - Depth of palette entries in bits.
 * ColorModel  - Color model of this VQ
 */
typedef struct _VQHeader {
	short Version;
	short Flags;
	short ImageWidth;
	short ImageHeight;
	short BlockType;
	short BlockWidth;
	short BlockHeight;
	short BlockDepth;
	short CBEntries;
	short VPtrType;
	short PalStart;
	short PalLengh;
	short PalDepth;
	short ColorModel;
} VQHeader;


/* VQ file flags */
#define VQHB_CBCOMP 0 /* Codebook compressed */
#define VQHB_CTCOMP 1 /* Color table compressed */
#define VQHB_VPCOMP 2 /* Vector pointers compressed */
#define VQHF_CBCOMP (1<<VQHB_CBCOMP)
#define VQHF_CTCOMP (1<<VQHB_CTCOMP)
#define VQHF_VPCOMP (1<<VQHB_VPCOMP)

/* Block types */
#define VQBT_RECT 0 /* Rectangle Width X Height */

/* Color models */
#define VQCM_PALETTED 0 /* Palette (8 bit indices) */
#define VQCM_RGBTRUE  1 /* RBG truecolor (24 bit) */
#define VQCM_YBRTRUE  2 /* YCbCr truecolor */


/*---------------------------------------------------------------------------
 * VQ FILE CHUNK ID DEFINITIONS
 *-------------------------------------------------------------------------*/

#define ID_VQHR MAKE_ID('V','Q','H','R') /* VQ Header */
#define ID_VQCB MAKE_ID('V','Q','C','B') /* VQ Codebook */
#define ID_VQCT MAKE_ID('V','Q','C','T') /* VQ Color Table (palette) */
#define ID_VQVP MAKE_ID('V','Q','V','P') /* VQ Vector pointers */

#ifdef __WATCOMC__
#pragma pack();
#endif

#endif /* VQFILE_H */

