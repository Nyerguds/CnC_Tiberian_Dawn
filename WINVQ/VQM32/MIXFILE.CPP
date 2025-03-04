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
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     mixfile.c
*
* DESCRIPTION
*     A mix file is basically a group of files concatinated together
*     proceeded by a header describing where in the file each individual
*     entry is located. These routines are provided to simplify the access
*     to these file entries.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* MixFile format:
*
*     HEADER
*       (2 bytes) Count - The number of entries in this file.
*       (4 bytes) Size  - Size of the mix file in bytes.
*
*     SUBBLOCKS (There are "Count" number of these.)
*       (4 bytes) CRC    - Entry descriptor (CRC of filename).
*       (4 bytes) Offset - Offset in bytes from beginning of the DATA chunk.
*       (4 bytes) Size   - Size of entry.
*
*     DATA
*       Entry data.
* 
*----------------------------------------------------------------------------
*
* PUBLIC
*     OpenMix - Open mix file for access.
*     CloseMix - Close a mix file.
*     OpenMixEntry - Open a mix file entry.
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <mem.h>
#include <string.h>
#include "mixfile.h"
#include "crc.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

int compfunc(void const *ptr1, void const *ptr2);


/****************************************************************************
*
* NAME
*     OpenMix - Open mix file for access.
*
* SYNOPSIS
*     MixHandle = OpenMix(Name)
*
*     MixHandle *OpenMix(char *);
*
* FUNCTION
*     Open a mix file for access.
*
* INPUTS
*     Name - Pointer to name of mix file to open.
*
* RESULT
*     MixHandle - Pointer to handle for mix file.
*
****************************************************************************/

MIXHandle *OpenMix(char *name)
{
  MIXHeader mfhdr;
	MIXHandle *mix = NULL;
	long      fh;
	long      sbsize;
	long      size;

	/* Open mix file and read in header. */
	if ((fh = open(name, (O_RDONLY|O_BINARY))) != -1) {
		if (read(fh, &mfhdr, sizeof(MIXHeader)) == sizeof(MIXHeader)) {

			/* Allocate handle based on the number of SubBlocks. */
			sbsize = (mfhdr.Count * sizeof(MIXSubBlock));
			size = sbsize + sizeof(MIXHandle);

			if ((mix = (MIXHandle *)malloc(size)) != NULL) {
				memset(mix, 0, size);
				mix->Name = name;
				mix->Size = mfhdr.Size;
				mix->Count = mfhdr.Count;

				/* Read in the SubBlock entries. */
				if (read(fh, &mix->Entries[0], sbsize) != sbsize) {
					free(mix);
					mix = NULL;
				}
			}
		}

		close(fh);
	}

	return (mix);
}


/****************************************************************************
*
* NAME
*     CloseMix - Close a mix file.
*
* SYNOPSIS
*     CloseMix(MixHandle)
*
*     void CloseMix(MixHandle *);
*
* FUNCTION
*     Close a mix file by freeing its handle.
*
* INPUTS
*     MixHandle - Pointer to MixHandle returned by OpenMix().
*
* RESULT
*     NONE
*
****************************************************************************/

void CloseMix(MIXHandle *mix)
{
	free(mix);
}


/****************************************************************************
*
* NAME
*     OpenMixEntry - Open a mix file entry.
*
* SYNOPSIS
*     FH = OpenMixEntry(MixHandle, EntryName)
*
*     short OpenMixEntry(MIXHandle *, char *);
*
* FUNCTION
*     Opens an entry from the specified mix file handle. Use close() to close
*     the file when done.
*
* INPUTS
*     MixHandle - Pointer to MIXHandle containing entry to open.
*     EntryName - Pointer to name of mix file entry to open.
*
* RESULT
*     FH - DOS filehandle, -1 if unable to open.
*
****************************************************************************/

long OpenMixEntry(MIXHandle *mix, char *name)
{
	MIXSubBlock key;
	MIXSubBlock *block;
	long        fh;

	/* Search for the specified file in the mix file. */
	key.CRC = Calculate_CRC(name, strlen(name));
	block = (MIXSubBlock *)bsearch(&key, &mix->Entries[0], mix->Count,
			sizeof(MIXSubBlock), compfunc);

	/* If the block exists for the requested filename. */
	if (block != NULL) {

		/* Initialize the key for file access. */
		key.Offset = block->Offset;
		key.Offset += (mix->Count * sizeof(MIXSubBlock)) + sizeof(MIXHeader);

		/* Open the mix file. */
		if ((fh = open(mix->Name, (O_RDONLY|O_BINARY))) != -1) {

			/* Seek to the start of the file. */
			if (lseek(fh, key.Offset, SEEK_SET) == -1) {
				close(fh);
				fh = -1;
			}
		}
	}

	return (fh);
}


/****************************************************************************
*
* NAME
*     compfunc - Compare function for bsearch().
*
* SYNOPSIS
*     Result = compfunc(Entry1, Entry2);
*
*     int compfunc(void const *, void const *);
*
* FUNCTION
*
* INPUTS
*     Entry1 - Pointer to first entry to compare.
*     Entry2 - Pointer to second entry to compare.
*
* RESULT
*     Result -
*
****************************************************************************/

int compfunc(void const *ptr1, void const *ptr2) 
{
	if (((MIXSubBlock *)ptr1)->CRC < ((MIXSubBlock *)ptr2)->CRC) return -1;
	if (((MIXSubBlock *)ptr1)->CRC > ((MIXSubBlock *)ptr2)->CRC) return 1;
	return(0);
}


