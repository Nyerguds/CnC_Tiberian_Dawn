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

/****************************************************************************
*
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*---------------------------------------------------------------------------
*
* FILE
*     font.c
*
* DESCRIPTION
*     Font manipulation.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     March 9, 1995
*
*---------------------------------------------------------------------------
*
* PUBLIC
*     Load_Font          - Open a font for use.
*     Set_Font           - Set the default system font.
*     String_Pixel_Width - Get the pixel width of a string.
*
****************************************************************************/

#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <string.h>
#include <malloc.h>
#include "font.h"


/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

/* min and max macros */
#ifdef __cplusplus
#ifndef max
#define max(a,b)  (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
#define min(a,b)  (((a) < (b)) ? (a) : (b))
#endif
#endif

void const *FontPtr = NULL;
char FontHeight = 8;
char FontWidth = 8;
int FontXSpacing = 0;
int FontYSpacing = 0;
char *FontWidthBlockPtr = NULL;


/****************************************************************************
*
* NAME
*     Load_Font - Open a font for use.
*
* SYNOPSIS
*     Font = Load_Font(Name)
*
*     char *Load_Font(char *);
*
* FUNCTION
*     Open a graphics font for use by Text_Print(). Use free() to dispose
*     of the font.
*
* INPUTS
*     Name - Name of font file to open.
*
* RESULT
*     Font - Pointer to font, NULL if error.
*
****************************************************************************/

void *cdecl Load_Font(char const *name)
{
	Font  *font = NULL;
	long  fh;
	short size;
	short valid;

	/* Open the font. */
	if ((fh = open(name, (O_RDONLY|O_BINARY))) != -1) {

		/* Get the size of the font. */
		if (read(fh, &size, 2) == 2) {

			/* Allocate memory to contain the font. */
			if ((font = (Font *)malloc((unsigned long)size)) != NULL) {
				valid = 0;	

				/* Read in the body of the font. */
				if (read(fh, &font->CompMethod, (unsigned long)(size - 2))
						== (unsigned long)(size - 2)) {
					
					/* Verify the validity of the font. */
					if ((font->CompMethod == 0) && (font->NumBlks == 5)) {
						font->Size = size;
						valid = 1;
					}
				}

				/* Free the font if it is not valid. */
				if (valid == 0) {
					free(font);
					font = NULL;
				}
			}
		}

		/* Close the font. */
		close(fh);
	}

	return ((char *)font);
}


/****************************************************************************
*
* NAME
*     Set_Font - Set the default system font.
*
* SYNOPSIS
*     OldFont = Set_Font(Font)
*
*     char *Set_Font(char *);
*
* FUNCTION
*     Sets up the specified font as the default font used by the system.
*
* INPUTS
*     Font - Pointer to Font to set as default. (NULL returns current font)
*
* RESULT
*     OldFont - Previous font.
*
****************************************************************************/

void *cdecl Set_Font(void const *font)
{
	void const *oldfont;
	FontInfo   *fi;

	oldfont = FontPtr;
	
	if (font != NULL) {
		FontWidthBlockPtr = ((char *)font + ((Font *)font)->WidthBlk);
		fi = (FontInfo *)((char *)font + ((Font *)font)->InfoBlk);
		FontHeight = fi->MaxHeight;
		FontWidth = fi->MaxWidth;
		FontPtr = font;
	}

	return ((void *)oldfont);
}


/****************************************************************************
*
* NAME
*     String_Pixel_Width - Get the pixel width of a string.
*
* SYNOPSIS
*     Width = String_Pixel_Width(String)
*
*     long String_Pixel_Width(char *);
*
* FUNCTION
*     Calculates the pixel width of a string of characters.
*
* INPUTS
*     String - Pointer to string to calculate width for.
*
* RESULT
*     Width - Width of string in pixels.
*
****************************************************************************/

unsigned short String_Pixel_Width(char const *string)
{
	long width = 0;
	long largest = 0;

	while (*string != NULL) {
		if (*string == '\r') {
			string++;
			largest = max(largest, width);
			width = 0;
		} else {
			width += Char_Pixel_Width(*string++);
		}
	}

	largest = max(largest, width);

	return (largest);
}

