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

#ifndef VQMCAPTOKEN_H
#define VQMCAPTOKEN_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     captoken.h
*
* DESCRIPTION
*     Text caption script definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     July 26, 1995
*
****************************************************************************/

/* CaptionText: This structure describes a line of text to be displayed
 *              with the video/audio.
 *
 * Size     - Size of caption in bytes.
 * OnFrame  - Frame number to display caption.
 * OffFrame - Frame number to clear caption.
 * Flags    - Display modifiers.
 * CPF      - Characters to draw per frame.
 * Xpos     - X pixel position to display caption.
 * Ypos     - Y pixel position to display caption.
 * BgPen    - Background pen to use.
 * FgPen    - Foreground pen to use.
 * Text     - Text string to display. (WORD aligned)
 */
typedef struct _CaptionText {
	unsigned short Size;
	unsigned short OnFrame;
	unsigned short OffFrame;
	unsigned char  Flags;
	char           CPF;
	unsigned short Xpos;
	unsigned short Ypos;
	char           BgPen;
	char           FgPen;
	char           Text[];
} CaptionText;

/* CaptionText flag definitions. */
#define CTF_JUSTIFY	(3<<0)  /* Justification field. */
#define CTF_ABS     (0<<0)  /* Use absolute X,Y positions. */
#define CTF_CENTER  (1<<0)  /* Justify on Center */
#define CTF_LEFT    (2<<0)  /* Justify on left */
#define CTF_RIGHT   (3<<0)  /* Justify on right */
#define CTF_FLASH   (1<<4)  /* Flash text. */

/* Function prototypes. */
long BuildCaptions(char *name, char *buffer);

#endif /* VQMCAPTOKEN_H */

