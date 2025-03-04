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
 *                 Project Name : Library - File functions.                *
 *                                                                         *
 *                    File Name : FILECHNG.CPP                             *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : September 13, 1993                       *
 *                                                                         *
 *                  Last Update : September 13, 1993   [SKB]               *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Delete_File -- Deletes the file from the disk.                        *
 *   Create_File -- Creates an empty file on disk.                         *
 *   Change_File_Size -- Change the size of a writting file.               *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
#ifndef WWSTD_H
#include "wwstd.h"
#endif	   

#ifndef _FILE_H
#include "_file.h"
#endif

#ifndef WWMEM_H
#include <wwmem.h>
#endif

#include <io.h>

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

/***************************************************************************
 * CREATE_FILE -- Creates an empty file on disk.                           *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/24/1992 JLB : Created.                                             *
 *=========================================================================*/
WORD cdecl Create_File(BYTE const *file_name)
{
	WORD fd;

	if (!file_name) return(FALSE);

	fd = Open_File(file_name, WRITE);
	if (fd != ERROR) {
		Close_File(fd);
		return(TRUE);
	}
	return(FALSE);
}


/***************************************************************************
 * DELETE_FILE -- Deletes the file from the disk.                          *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/24/1992 JLB : Created.                                             *
 *=========================================================================*/
WORD cdecl Delete_File(BYTE const *file_name)
{
	WORD					index;
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	FileDataType		hold;				// Hold buffer for record (DO NOT ACCESS DIRECTLY)

	if (!file_name) return(FALSE);

	CallingDOSInt++;

	ibm_setdisk(*StartPath - 'A');

	index = Find_File_Index(file_name);
	filedata = &FileDataPtr[index];

	if (index != ERROR && filedata->Ptr) {
		Mem_Free(FileCacheHeap, filedata->Ptr);
		filedata->Ptr = NULL;
	}

	index = !FILEDELETE(file_name);
	CallingDOSInt--;
	return(index);
}



/***************************************************************************
 * CHANGE_FILE_SIZE -- Change the size of a writting file.                 *
 *                                                                         *
 * INPUT:   WORD handle - handle of file.                                  *
 *          ULONG new_size - size of new handle.                           *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/
BOOL cdecl Change_File_Size(WORD handle, ULONG new_size)
{
	WORD entry;

	if (Is_Handle_Valid(handle, WRITING_NON_HANDLE, NULL)) {
		entry = Get_DOS_Handle(handle);
		if (entry != ERROR) {
			return(chsize(entry, new_size) != ERROR);
		}
	}
	return(FALSE);
}
