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

/* $Header: g:/library/source/rcs/./dipthong.c 1.15 1994/05/20 15:35:17 joe_bostic Exp $ */
/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood Library                         *
 *                                                                         *
 *                    File Name : DIPTHONG.C                               *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : February 23, 1992                        *
 *                                                                         *
 *                  Last Update : February 13, 1995 [BWG]                  *
 *                                                                         *
 * DIGRAM or DIATOMIC encoding is the correct term for this method.        *
 * This is a fixed dictionary digram encoding optimized for English text.  *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Extract_String -- Extracts a string pointer from a string data block. *
 *   UnDip_Text -- Undipthongs a text string into specified buffer.        *
 *   Dip_Text -- Compresses text by using dipthonging.                     *
 *   Fixup_Text -- Converts dipthonged foreign text into normal text.      *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

//#include	"function.h"
//#include	"ems.h"
#include <keyboard.h>
#include "dipthong.h"

/***************************************************************************
 * Fixup_Text -- Converts dipthonged foreign text into normal text.        *
 *                                                                         *
 *    Takes text that has been processed (or undipped) to hold foriegn     *
 *    language character pairs (needed for Window_Print) and converts it   *
 *    so that Text_Print will print it properly.  Typically this would be  *
 *    used after text has been undipped but before it will be Text_Printed.*
 *    Text that is to be Window_Printed doesn't and mustn't have its text  *
 *    processed by this routine.                                           *
 *                                                                         *
 * INPUT:   source   -- Pointer to the source string to process.           *
 *                                                                         *
 *          dest     -- Destination buffer to hold the processed string.   *
 *                                                                         *
 * OUTPUT:  none                                                           *
 *                                                                         *
 * WARNINGS:   This routine will only reduce the size of the string if it  *
 *             modifies it at all.  Because of this it is quite legal to   *
 *             pass the same pointers to this routine so that it will      *
 *             modify the string "in place".                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/13/1993 JLB : Created.                                             *
 *   10/06/1994 JLB : Handles source string in EMS.                        *
 *=========================================================================*/
void Fixup_Text(char const *source, char *dest)
{
	if (source && dest) {
		char const 	*src;
		char			temp;

		src = source;
		while (*src) {
			if (*src == KA_EXTEND) {
				src++;
				temp = *src++;
				temp += 127;
				*dest++ = temp;
			} else {
				*dest++ = *src++;
			}
		}
		*dest = '\0';

	}
}


/***************************************************************************
 * Dip_Text -- Compresses text by using dipthonging.                       *
 *                                                                         *
 *    This routine is used to compress text by using dipthonging.  Text    *
 *    that is compressed in this fashion usually is reduced in size by     *
 *    approximately 40%.                                                   *
 *                                                                         *
 * INPUT:   source   -- Pointer to the source string to compress.          *
 *                                                                         *
 *          dest     -- Pointer to the buffer that will hold the dipthong  *
 *                      text output.                                       *
 *                                                                         *
 * OUTPUT:  Returns the number of bytes output into the output buffer.     *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/13/1993 JLB : Created.                                             *
 *=========================================================================*/
int Dip_Text(char const *source, char *dest)
{
	unsigned char	first,		// First character in pair.
						next;			// Second character in pair.
	int				common,		// Common character index.
						dipthong;	// Dipthong character index.

	unsigned long length=0;		// Length of output string

	first = *source++;
	next = *source;
	while (first) {

		if (first > 127) {

			/*
			**	Characters greater than 127 cannot be dipthonged.  They must
			**	be preceeded with an extended character code.
			*/
			*dest++ = (char)KA_EXTEND;
			first -= 127;
			length++;

		} else {

			/*
			**	Normal characters can be dipthonged.  First see if there is a
			**	match in the Common table.
			*/
			for (common = 0; common < 16; common++) {
				if (Common[common] == first) {

					/*
					**	Common character found.  See if there is a matching
					**	Dipthong character.
					*/
					for (dipthong = 0; dipthong < 8; dipthong++) {
						if (Dipthong[common][dipthong] == next) {
							first = (unsigned char) (common << 3);
							first |= (unsigned char)dipthong;
							first |= (unsigned char)0x80;
							source++;
						}
					}
				}
			}
		}

		/*
		**	Output the translated character to the destination buffer.
		*/
		*dest++ = first;
		length++;

		first = *source++;
		next = *source;
	}

	*dest = '\0';

	return(length);
}


/***************************************************************************
 * UnDip_Text -- Undipthongs a text string into specified buffer.          *
 *                                                                         *
 *    This routine is used to undipthong a text string and place the       *
 *    undipped text into the buffer specified.  Since dipthonged text is   *
 *    compressed, in order for the text to be used it must be undipped     *
 *    first.                                                               *
 *                                                                         *
 * INPUT:   source   -- Pointer to the dipped string.                      *
 *                                                                         *
 *          dest     -- Pointer to the destination buffer.                 *
 *                                                                         *
 * OUTPUT:  Returns the number of bytes placed into the destination        *
 *          buffer.                                                        *
 *                                                                         *
 * WARNINGS:   Be sure the destination buffer is big enough to hold the    *
 *             undipped text.                                              *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/13/1993 JLB : Created.                                             *
 *   10/06/1994 JLB : Handles source string in EMS.                        *
 *=========================================================================*/
int UnDip_Text(char const *source, char *dest)
{
	int	c;			// Source input character.
	int	common;	// Common character index.
	int	len;		// Length of output string.
	char const *src;

	len = 0;						// Presume no translation.

	/*
	**	Sweep through the source text and dipthong it.
	*/
	src = source;
	c = *src++;
	while (c) {

		/*
		**	Convert a dipthong character into it's component
		**	ASCII characters.
		*/
		if (c & 0x80) {
			c &= 0x7F;

			common = (c & 0x78) >> 3;

			*dest++ = Common[common];
			len++;

			c = Dipthong[common][c & 0x07];
		}

		*dest++ = (unsigned char)c;
		len++;

		c = *src++;
	}

	/*
	**	End the output text with a '\0'.
	*/
	*dest++ = '\0';

	return(len);
}


/***************************************************************************
 * Extract_String -- Extracts a string pointer from a string data block.   *
 *                                                                         *
 *    This routine is used to find a pointer to the specified string       *
 *    inside a string block.  String data blocks are created with the      *
 *    TEXTMAKE utility.  The data block my reside in XMS or EMS memory,    *
 *    but of course the returned string pointer will also point to         *
 *    such memory.  In this case, the string must be placed in real        *
 *    memory before it can be used.                                        *
 *                                                                         *
 * INPUT:   data     -- Pointer to the string data block.                  *
 *                                                                         *
 *          string   -- The string number to extract (if < 0 then NULL     *
 *                      is returned).                                      *
 *                                                                         *
 * OUTPUT:  Returns with pointer to the string number specified.           *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/13/1993 JLB : Created.                                             *
 *   08/13/1993 JLB : Handles EMS or XMS data pointer.                     *
 *=========================================================================*/
char *Extract_String(void const *data, int string)
{
	unsigned short int	const *ptr;

	if (!data || string < 0) return(NULL);

	ptr = (unsigned short int const *)data;
	return (((char*)data) + ptr[string]);
}
