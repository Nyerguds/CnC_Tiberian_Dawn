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

/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood Library                         *
 *                                                                         *
 *                    File Name : SET_FONT.C                               *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : September 6, 1991                        *
 *                                                                         *
 *                  Last Update : June 29, 1994   [SKB]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Set_Font -- Changes the default text printing font.                   *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#include "font.h"
#include <wwstd.h>



/***************************************************************************
 * SET_FONT -- Changes the default text printing font.                     *
 *                                                                         *
 *    This routine will change the default text printing font for all      *
 *    text output.  It handles updating the system where necessary.        *
 *                                                                         *
 * INPUT:   fontptr  -- Pointer to the font to change to.                  *
 *                                                                         *
 * OUTPUT:  Returns with a pointer to the previous font.                   *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/06/1991 JLB : Created.                                             *
 *   09/17/1991 JLB : Fixed return value bug.                              *
 *   01/31/1992 DRD : Modified to use new font format.                     *
 *   06/29/1994 SKB : modified for 32 bit library                          *
 *=========================================================================*/
void * __cdecl Set_Font(void const *fontptr)
{
	void *oldfont;
	char	const *blockptr;

	oldfont = (void *) FontPtr;

	if (fontptr) {
		FontPtr    = (void *) fontptr;

		/*
		**	Inform the system about the new font.
		*/

		FontWidthBlockPtr = (char*)fontptr + *(unsigned short *)((char*)fontptr + FONTWIDTHBLOCK);
		blockptr  = (char*)fontptr + *(unsigned short *)((char*)fontptr + FONTINFOBLOCK);
		FontHeight = *(blockptr + FONTINFOMAXHEIGHT);
		FontWidth  = *(blockptr + FONTINFOMAXWIDTH);
		//Draw_Char_Setup();

#if FALSE
		WindowLines = WinH / FontHeight;
		WindowWidth = WinW << 3;
		WindowColumns = WindowWidth / FontWidth;
#endif
	}

	return(oldfont);
}
