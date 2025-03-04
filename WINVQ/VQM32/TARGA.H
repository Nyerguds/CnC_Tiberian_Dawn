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

#ifndef VQMTARGA_H
#define VQMTARGA_H
/****************************************************************************
*
*         C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     Targa.h (32-Bit protected mode)
* 
* DESCRIPTION
*     Targa Image File definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     January 26, 1995
*
****************************************************************************/

/*---------------------------------------------------------------------------
 * Targa Header definitions
 *-------------------------------------------------------------------------*/

/* TGAHeader - Targa Image File header.
 *
 * IDLength        - Size of Image ID field
 * ColorMapType    - Color map type.
 * ImageType       - Image type code.
 * CMapStart       - Color map origin.
 * CMapLength      - Color map length.
 * CMapDepth       - Depth of color map entries.
 * XOffset         - X origin of image.
 * YOffset         - Y origin of image.
 * Width           - Width of image.
 * Height          - Height of image.
 * PixelDepth      - Image pixel size
 * ImageDescriptor - Image descriptor byte.
 */
typedef struct _TGAHeader {
	char  IDLength;
	char  ColorMapType;
	char  ImageType;
	short CMapStart;
	short CMapLength;
	char  CMapDepth;
	short XOffset;
	short YOffset;
	short Width;
	short Height;
	char  PixelDepth;
	char  ImageDescriptor;
} TGAHeader;

/* ImageType definiton */
#define TGA_NOIMAGE           0  /* No image data included in file */
#define TGA_CMAPPED           1  /* Color-mapped image data */
#define TGA_TRUECOLOR         2  /* Truecolor image data */
#define TGA_MONO              3  /* Monochrome image data */
#define TGA_CMAPPED_ENCODED   9  /* Color-mapped image data (Encoded) */
#define TGA_TRUECOLOR_ENCODED 10 /* Truecolor image data (Encoded) */
#define TGA_MONO_ENCODED      11 /* Monochrome image data (Encoded) */

/* ImageDescriptor definition */
#define TGAF_ATTRIB_BITS (0x0F<<0) /* Number of attribute bits per pixel */
#define TGAF_XORIGIN     (1<<4)
#define TGAF_YORIGIN     (1<<5)

/*---------------------------------------------------------------------------
 * Targa Handle definitions
 *-------------------------------------------------------------------------*/

/* TGAHandle - Targa Image File handle.
 *
 * fh     - File handle returned by open().
 * mode   - Access mode.
 * header - TGAHeader structure.
 */
typedef struct _TGAHandle {
	short          fh;
	unsigned short mode;
	TGAHeader      header;
} TGAHandle;

/* Access modes. */
#define TGA_READMODE  0
#define TGA_WRITEMODE 1
#define TGA_RDWRMODE  2

/* Error codes */
#define TGAERR_OPEN         -1
#define TGAERR_READ         -2
#define TGAERR_WRITE        -3
#define TGAERR_SYNTAX       -4
#define TGAERR_NOMEM        -5
#define TGAERR_NOTSUPPORTED -6
 
/*---------------------------------------------------------------------------
 * Function prototypes
 *-------------------------------------------------------------------------*/

TGAHandle *OpenTarga(char *, unsigned short);
void CloseTarga(TGAHandle *);
long LoadTarga(char *, char *, char *);
long SaveTarga(char *, TGAHeader *, char *, char *);
void XFlipTarga(TGAHeader *, char *);
void YFlipTarga(TGAHeader *, char *);

#endif /* VQMTARGA_H */

