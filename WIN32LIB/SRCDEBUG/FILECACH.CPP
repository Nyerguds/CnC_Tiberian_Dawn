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
 *                 Project Name : Library - File Caching routines          *
 *                                                                         *
 *                    File Name : FILECACH.CPP                             *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : September 13, 1993                       *
 *                                                                         *
 *                  Last Update : April 18, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Make_File_Resident -- Makes a file resident even if not flaged so.    *
 *   Flush_Unused_File_Cache -- Flushes the file cache of any non opened fi*
 *   Free_Resident_File -- Free the given file if it is resident.          *
 *   Unfragment_File_Cache -- Does a garbage collection on the file heap.  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
#ifndef WWSTD_H
#include <wwstd.h>
#endif	   

#ifndef _FILE_H
#include "_file.h"
#endif

#ifndef WWMEM_H
#include <wwmem.h>
#endif

#include <string.h>

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/



/***************************************************************************
 * UNFRAGMENT_FILE_CACHE -- Does a garbage collection on the file heap.    *
 *                                                                         *
 * INPUT:    NONE.                                                         *
 *                                                                         *
 * OUTPUT:   NONE.                                                         *
 *                                                                         *
 * WARNINGS: Can be a lengthy process.                                     *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/18/1994 SKB : Created.                                             *
 *=========================================================================*/
VOID Unfragment_File_Cache(VOID)
{
	FileDataType	*filedata;
	FileDataType	*parent;
	UWORD				idx;


	// Let the memory system clean up the file heap.
	Mem_Cleanup(FileCacheHeap);

	// Now get our pointers back.
	// Start after the parent PAK files since we will need to check our pointers
	// with them.
	filedata = &FileDataPtr[NumPAKFiles];
	for (idx = NumPAKFiles; idx < NumPAKFiles; idx++, filedata++) {
	while (filedata->Name) {

		// Only process files that are in the file cache.
		if (filedata->Ptr) {

			// Is a inner PAK file?
			if (filedata->Flag & FILEF_PACKED) {

				parent = &FileDataPtr[filedata->Disk];

				// Is it just a copied pointer of the parent?
				if (parent->Ptr == filedata->Ptr) {	
					filedata->Ptr = Mem_Find(FileCacheHeap, filedata->Disk);
				}
				else 
					filedata->Ptr = Mem_Find(FileCacheHeap, idx);
				}
			}
			else {
			 	filedata->Ptr = Mem_Find(FileCacheHeap, idx);
			}
		}
	}

	// Now that the children have been taken care of, let us do the parents.
	for (filedata = FileDataPtr, idx = 0; idx < NumPAKFiles; idx++, filedata++) {

		// Only process files that are in the file cache.
		if (filedata->Ptr) {
		 	filedata->Ptr = Mem_Find(FileCacheHeap, idx);
		}
	}
}

/***************************************************************************
 * MAKE_FILE_RESIDENT -- Makes a file resident even if not flaged so.      *
 *                                                                         *
 * INPUT:  BYTE *filename - name of file to be made resident.              *
 *                                                                         *
 * OUTPUT: BOOL if successful.  could fail in not enouph RAM or not found. *
 *                                                                         *
 * WARNINGS: File must be in FileData table.                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/
BOOL Make_File_Resident(BYTE const *filename)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	FileDataType		hold;				// Hold buffer for record (DO NOT ACCESS DIRECTLY)
	WORD					fileindex;
	WORD					oldflag;
	WORD					handle;

	fileindex = Find_File_Index(filename);

	//	if the file is not in the table, we can't make it resident
	if (fileindex == ERROR) return(FALSE);

	// Get a pointer for quicker pointer action.
	filedata = &FileDataPtr[fileindex];

	// Change the flags for a moment.
	oldflag = filedata->Flag;
	filedata->Flag |= FILEF_RESIDENT;
	filedata->Flag &= ~FILEF_FLUSH;

	// Make the file resident.
	handle = Open_File(filename, READ);
	Close_File(handle);

	// Set flags back to normal.
	filedata->Flag = oldflag;

	return(TRUE);
}

/***************************************************************************
 * Flush_Unused_File_Cache -- Flushes the file cache of any non opened files.     *
 *                                                                         *
 * INPUT:     WORD flush_keep - TRUE to flush even files marked FILEF_KEEP.*
 *                                                                         *
 * OUTPUT:    WORD Number of file flushed.                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   02/23/1993  SB : Created.                                             *
 *=========================================================================*/
WORD Flush_Unused_File_Cache(WORD flush_keeps) 
{
	WORD				index;
	WORD				freed = 0;
	FileDataType	*filedata = NULL;
	FileDataType	hold;				// Hold buffer for record (DO NOT ACCESS DIRECTLY)

	// Loop throuph the file table looking for files that could be freed.
	index = 0;
	filedata = &FileDataPtr[index];;
	while (filedata->Name && strlen(filedata->Name)) {

		if (filedata->Ptr && !filedata->OpenCount && 
		    (flush_keeps || !(filedata->Flag & FILEF_KEEP)) ) {

			Mem_Free(FileCacheHeap, filedata->Ptr);
			filedata->Ptr = NULL;
			freed++;
		}
		index++;
		filedata = &FileDataPtr[index];;
	}
	return (freed);
}

/***************************************************************************
 * FREE_RESIDENT_FILE -- Free the given file if it is resident.            *
 *                                                                         *
 * INPUT:      BYTE *file to free                                          *
 *                                                                         *
 * OUTPUT:     TRUE if file was free'd, FALSE otherwise                    *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/22/1992  CY : Created.                                             *
 *=========================================================================*/
BOOL cdecl Free_Resident_File(BYTE const *file)
{
	WORD					fileindex;
	BOOL					oldflag;			// Previous file flag.
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	FileDataType		hold;				// Hold buffer for record (DO NOT ACCESS DIRECTLY)


	//	if the file is not in the table, we can't free it
	if ((fileindex = Find_File_Index(file)) == ERROR) {
		return(FALSE);
	}

	// get a pointer for quicker calculations.
	filedata = &FileDataPtr[fileindex];

	// If it isn't resident, don't try to Free it
	if (filedata->Ptr == NULL) {
		return(TRUE);
	}

	// Change the flags for a moment.
	oldflag = filedata->Flag;
	filedata->Flag &= ~(FILEF_RESIDENT|FILEF_KEEP);
	filedata->Flag |= FILEF_FLUSH;

	// Get the file out of Memory if it was there.
	Close_File(Open_File(file, READ));

	// Set flags back to original.
	filedata->Flag = oldflag;

	return(TRUE);
}

