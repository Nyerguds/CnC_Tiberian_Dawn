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
 *                 Project Name : Library - Fileio information functions.  *
 *                                                                         *
 *                    File Name : FILE.CPP                             		*
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : September 13, 1993                       *
 *                                                                         *
 *                  Last Update : April 19, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Get_DOS_Handle -- Fetches system specific DOS file handle.            *
 *   Find_Disk_Number -- Determine disk a file resides upon.               *
 *   Set_File_Flags -- Sets flags for file if FileData table.              *
 *   Get_File_Flags -- Gets the flags on a file in the FileData table.     *
 *   Free_Handles -- Returns number of free file handles in WW system.     *
 *   Multi_Drive_Search -- Turns Multi search drive on and off.            *
 *   Clear_File_Flags -- Clears flags specified for file.                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
#ifndef WWSTD_H
#include "wwstd.h"
#endif	   

#ifndef _FILE_H
#include "_file.h"
#endif

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/***************************************************************************
 * GET_DOS_HANDLE -- Fetches system specific DOS file handle.              *
 *                                                                         *
 *    This routine will return with the system specific DOS file handle.   *
 *    On the IBM, this is a WORD, on the Amiga, it is a LONG (BPTR).  Use  *
 *    this routine with caution, because the value returned is NOT         *
 *    portable.                                                            *
 *                                                                         *
 * INPUT:   fh -- Westwood file system handle.                             *
 *                                                                         *
 * OUTPUT:  Returns with the system DOS file handle (WORD or LONG).        *
 *                                                                         *
 * WARNINGS:   If you pass in an invalid file handle, or a file handle     *
 *             that references a resident file, then the ERROR code is     *
 *             returned.  Be SURE to check for this.                       *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/21/1991 JLB : Created.                                             *
 *   11/09/1991 JLB : Checks for illegal file handle passed in.            *
 *=========================================================================*/
WORD cdecl Get_DOS_Handle(WORD fh)
{
	/*
	**	If an illegal file handle is passed in then always abort.
	*/
	if (fh >= 0 && fh < TABLE_MAX) {
		if (!FileHandleTable[fh].Empty || FileHandleTable[fh].Handle) {
			return(FileHandleTable[fh].Handle);
		}

		/*
		**	If it falls through here, then the file must be resident.  It is
		**	illegal to get a DOS handle to a resident file.
		*/
	}
	return(FILEOPENERROR);
}

/***************************************************************************
 * FREE_HANDLES -- Returns number of free file handles in WW system.       *
 *                                                                         *
 * INPUT:    NONE.                                                         *
 *                                                                         *
 * OUTPUT:   NONE.                                                         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/
WORD cdecl Free_Handles(VOID)
{
	WORD	count;		// Count of the number of free file handles.
	WORD	index;		// Working file handle index var.
	
	count = 0;
	for (index = 0; index < TABLE_MAX; index++) {
		if (FileHandleTable[index].Empty) count++;
	}
	return(count);
}



/***************************************************************************
 * FIND_DISK_NUMBER -- Determine disk a file resides upon.                 *
 *                                                                         *
 *    This routine will determine the disk number that the specified       *
 *    file resides upon.  It determines this by scanning through the       *
 *    FileData table.  If the specified file is a packed file, then it     *
 *    will reference the parent packed file to determine the disk number.  *
 *                                                                         *
 * INPUT:   file_name   -- Pointer to the file name to check.              *
 *                                                                         *
 * OUTPUT:  Returns with the disk number that the file resides upon.  If   *
 *          ERROR is returned, then the file does not exist in the         *
 *          FileTable.  The number returned is 0=A, 1=B, etc.              *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1991 JLB : Created.                                             *
 *=========================================================================*/
WORD cdecl Find_Disk_Number(BYTE const *file_name)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	WORD					index;	// FileTable index.

	index = Find_File_Index(file_name);

	if (index != ERROR) {
		
		filedata = &FileDataPtr[index];

		if (filedata->Flag & FILEF_PACKED) {
			return (Find_Disk_Number(FileDataPtr[filedata->Disk].Name));
		}
		return(filedata->Disk);
	}
	return (index);
}





/***************************************************************************
 * SET_FILE_FLAGS -- Sets flags for file if FileData table.                *
 *                                                                         *
 * INPUT:  BYTE *filename - file to modify.                                *
 *         WORD flags - flags to set in file.                              *
 *                                                                         *
 * OUTPUT: WORD - if file found in FileData table.                         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   10/04/1993 SKB : Created.                                             *
 *=========================================================================*/
WORD cdecl Set_File_Flags(BYTE const *filename, WORD flags)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	WORD					index;	// FileTable index.

	index = Find_File_Index(filename);

	if (index != ERROR) {
		filedata = &FileDataPtr[index];
		filedata->Flag |= flags;
		return (TRUE);
	}

	return (FALSE);
}


/***************************************************************************
 * CLEAR_FILE_FLAGS -- Clears flags specified for file.                    *
 *                                                                         *
 * INPUT:  BYTE *filename - file to modify.                                *
 *         WORD flags - flags to set in file.                              *
 *                                                                         *
 * OUTPUT: WORD - if file found in FileData table.                         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/19/1994 SKB : Created.                                             *
 *=========================================================================*/
WORD cdecl Clear_File_Flags(BYTE const *filename, WORD flags)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	WORD					index;	// FileTable index.

	index = Find_File_Index(filename);

	if (index != ERROR) {
		filedata = &FileDataPtr[index];
		filedata->Flag &= ~flags;
		return (TRUE);
	}

	return (FALSE);
}



/***************************************************************************
 * GET_FILE_FLAGS -- Gets the flags on a file in the FileData table.       *
 *                                                                         *
 *                                                                         *
 * INPUT:  BYTE *filename - file to modify.                                *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * OUTPUT: WORD - if file found in FileData table.                         *
 *                                                                         *
 * HISTORY:                                                                *
 *   10/04/1993 SKB : Created.                                             *
 *=========================================================================*/
WORD cdecl Get_File_Flags(BYTE const *filename)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.
	WORD					index;	// FileTable index.

	index = Find_File_Index(filename);

	if (index != ERROR) {
		filedata = &FileDataPtr[index];
		return (filedata->Flag);
	}
	return (FALSE);
}


/***************************************************************************
 * MULTI_DRIVE_SEARCH -- Turns Multi search drive on and off.              *
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
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/
BOOL cdecl Multi_Drive_Search(BOOL on)
{
	BOOL	old;

	Hard_Error_Occured = 0;
	old = MultiDriveSearch;
	MultiDriveSearch = on;
	return(old);
}
