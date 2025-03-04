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

#ifndef VQMMIXFILE_H
#define VQMMIXFILE_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     mixfile.h
*
* DESCRIPTION
*     A mix file is basically a group of files concatinated together
*     proceeded by a header describing where in the file each individual
*     entry is located. These definitions are provided to simplify the access
*     to these file entries.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     January 26, 1995
*
****************************************************************************/

/* Disable structure alignment.*/
#ifdef __WATCOMC__
#pragma pack(1);
#endif

/*---------------------------------------------------------------------------
 * STRUCTURE DEFINITIONS
 *-------------------------------------------------------------------------*/

/* MIXHeader: Mix file data header.
 *
 * Count - Number of entries contained in this mix file.
 * Size  - Size of Mix file.
 */
typedef struct _MIXHeader {
	short Count;
	long  Size;
} MIXHeader;

/* MIXSubBlock: Mix file entry descriptor.
 *
 * CRC    - Unique entry identifier.
 * Offset - Offset from beginning of data segment to entry.
 * Size   - Size of entry.
 */
typedef struct _MIXSubBlock {
	long CRC;
	long Offset;
	long Size;
} MIXSubBlock;

/* MIXHandle: Mix file handle.
 *
 * Name    - Pointer to the name of the mix file this handle is for.
 * Size    - Size of entire mix file.
 * FH      - DOS file handle of opened entry.
 * Count   - Number of files contained in this mix.
 * Entries - Array of 'Count' MIXSubBlock structure entries.
 */
typedef struct _MIXHandle {
	char        *Name;
	long        Size;
	long        FH;
	long        Count;
	MIXSubBlock Entries[];
} MIXHandle;

/*---------------------------------------------------------------------------
 * PROTOTYPES
 *-------------------------------------------------------------------------*/

MIXHandle *OpenMix(char *name);
void CloseMix(MIXHandle *mix);
long OpenMixEntry(MIXHandle *mix, char *name);

/* Restore original alignment */
#ifdef __WATCOMC__
#pragma pack();
#endif

#endif /* VQMMIXFILE_H */

