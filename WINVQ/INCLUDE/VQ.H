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

#ifndef VQ_H
#define VQ_H
/****************************************************************************
*
*        C O N F I D E N T I A L ---  W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* NAME
*     vq.h
*
* DESCRIPTION
*     VQ file definition
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     September 28, 1995
*
* NOTES
*     VQ file organization:
*
*       Header: This structure contains all the data pertaining to the VQ.
*               (See structure definition for details)
*
*               Size: 40 bytes
*
*       Palette: Color palette used by this VQ. Stored as 24 bit RGB entries.
*
*                Size: (PaletteRange * 3) bytes
*
*       Codebook: Sequence of vector blocks used to represent the VQ image.
*                 Also called the dictionary. The sequence is sorted by
*                 usage, so the first entry is the most commonly used block.
*
*                 Size: ((BlockWidth * BlockHeight) * CodebookSize) bytes
*
*       Pointers: Vector pointer map used to indicate the construction of
*                 the vector blocks. Also called codewords.
*
*                 Size: (((ImageWidth / BlockWidth)
*                       * (ImageHeight / BlockHeight)) * 2)
*
*     Pointer format:
*
*       Single color - Value less than or equal to 'Num1Color'
*       Multi Color  - Value greater than 'Num1Color'
*
****************************************************************************/

/* VQHeader - VQ header structure.
 *
 * ImageSize       - Compressed image size 
 * ImageWidth      - Image x-dimension
 * ImageHeight     - Image y-dimension
 * BlockWidth      - Block x-dimension
 * BlockHeight     - Block y-dimension
 * BlockType       - Block type
 * PaletteRange    - Number of palette colors
 * Num1Color       - Number of 1-color blocks & 1-color colors
 * CodebookSize    - Number of actual codebook entries
 * CodingFlag      - Flag for 2-color blocks
 * FrameDiffMethod - Frame differencing method
 * ForcedPalette   - Force a palette on image
 * F555Palette     - Flag for output 15-bit palette
 * VQVersion       - VQ Version #
 * pad[5]          - Pad out to 40 bytes total
 */
typedef struct _VQHeader {
	unsigned long  ImageSize;
	unsigned short ImageWidth;
	unsigned short ImageHeight;
	unsigned short BlockWidth;
	unsigned short BlockHeight;
	unsigned short BlockType;
	unsigned short PaletteRange;
	unsigned short Num1Color;
	unsigned short CodebookSize;
	unsigned short CodingFlag;
	unsigned short FrameDiffMethod;
	unsigned short ForcedPalette;
	unsigned short F555Palette;
	unsigned short VQVersion;
	unsigned short pad[5];
} VQHeader;

#endif /* VQ_H */
