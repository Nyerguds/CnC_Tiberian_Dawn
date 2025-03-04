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

#ifndef VQMFONT_H
#define VQMFONT_H
/****************************************************************************
*
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*---------------------------------------------------------------------------
*
* FILE
*     font.h
*
* DESCRIPTION
*     Font definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     March 9, 1995
*
****************************************************************************/

/* Font: A Westwood style font.
 *
 * Size       - Size of font.
 * CompMethod - Compression method of font. (0 = none)
 * NumBlks    - Number of data blocks.
 * InfoBlk    - Offset to font information block.
 * OffsetBlk  - Offset to character offset block.
 * WidthBlk   - Offset to character width block.
 * DataBlk    - Offset to character data block.
 * HeightBlk  - Offset to character height block.
 */
typedef struct _Font {
	unsigned short Size;
	unsigned char  CompMethod;
	unsigned char  NumBlks;
	unsigned short InfoBlk;
	unsigned short OffsetBlk;
	unsigned short WidthBlk;
	unsigned short DataBlk;
	unsigned short HeightBlk;
} Font;

typedef struct _FontInfo {
	long huh;
	unsigned char MaxHeight;
	unsigned char MaxWidth;
} FontInfo;

#ifdef __cplusplus
extern "C" {
#endif

extern void const *FontPtr;
extern int FontXSpacing;
extern int FontYSpacing;

#ifdef __cplusplus
}
#endif

extern char FontWidth;
extern char FontHeight;
extern char *FontWidthBlockPtr;

/* Function prototypes. */
void *cdecl Load_Font(char const *name);
void *cdecl Set_Font(void const *font);
unsigned short __cdecl String_Pixel_Width(char const *string);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __WATCOMC__
long __cdecl __saveregs Char_Pixel_Width(char chr);
#else
long __cdecl Char_Pixel_Width(char chr);
#endif

#ifdef __cplusplus
}
#endif

#endif /* VQMFONT_H */

