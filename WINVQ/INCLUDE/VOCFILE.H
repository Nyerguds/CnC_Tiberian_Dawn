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

#ifndef VOCFILE_H
#define VOCFILE_H
/****************************************************************************
*
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     vocfile.h
*
* DESCRIPTION
*     VOC audio file definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*      
****************************************************************************/

/* VOC file header.
 *
 * type   - File type description
 * offset - Offset of data block from the start of VOC file.
 * ver    - File format version number
 * id     - File identification code.
 */
typedef struct _VOCHeader {
	char           type[0x14];
	unsigned short offset;
	unsigned short ver;
	unsigned short id;
} VOCHeader;

/* VOC sub-block block types */
#define VBT_TERMINATE 0  /* Last block of file (no size field) */
#define VBT_VOICEDATA 1  /* New set of voice data */
#define VBT_VOICECONT 2  /* Continuation of voice data */
#define VBT_SILENCE   3  /* Silence period */
#define VBT_MARKER    4  /* Syncronization marker */
#define VBT_ASCII     5  /* NULL terminated string */
#define VBT_REPEAT    6  /* Mark beginning of repeat loop */
#define VBT_ENDREPEAT 7  /* Mark end of repeat loop */
#define VBT_EXTENDED  8

#define IS_VOC(a,b) (((~a)+0x1234)==b)
#define BLOCK_LEN(a) ((a&0x00FFFFFFL))

#endif  /* VOCFILE_H */


