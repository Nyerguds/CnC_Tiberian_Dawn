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
 *                    File Name : FINDFILE.C                               *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : August 21, 1991                          *
 *                                                                         *
 *                  Last Update : September 29, 1993   [SKB]               *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Find_File_Index -- Finds the FileTable index number for a given file. *
 *   Find_File -- Checks if a file is immediatly available.                *
 *   Get_FileData -- Gets a pointer back to the correct file.              *
 *   Find_File -- Checks if a file is immediatly available.                *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/



/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

#ifndef WWSTD_H
#include "wwstd.h"
#endif	   

#ifndef _FILE_H
#include "_file.h"
#endif

#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <search.h>
#include <sys\stat.h>



/***************************************************************************
 * FIND_FILE -- Checks if a file is immediatly available.                  *
 *                                                                         *
 *    Use this function to determine if a file is immediatly available.    *
 *    This routine will NOT request for the proper disk to be inserted     *
 *    if the file could not be found.  Use File_Exists for that feature.   *
 *    The Westwood file I/O system does NOT have to be initialized as      *
 *    a prerequisit to using this function.                                *
 *                                                                         *
 * INPUT:   file_name   -- Name of the file to check.                      *
 *                                                                         *
 * OUTPUT:  Returns the disk number that the file exits on (A=1, B=2, etc) *
 *                                                                         *
 * WARNINGS:   This sets the current drive to the drive that contains the  *
 *             specified file (if it is found).                            *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/14/1991 JLB : Created.                                             *
 *   03/14/1992 JLB : Modified for Amiga compatability.                    *
 *   01/11/1993 SKB : Modified for CD-ROM searches.                        *
 *=========================================================================*/
WORD cdecl Find_File(BYTE const *file_name)
{
	FileDataType	*filedata = NULL;
	WORD				index;					// File index (if any).
	WORD				disk;						// Disk number of file (if in filetable).
	
	/*
	**	If the filename is invalid then it errors out as if the file wasn't
	**	found (naturally).
	*/
	if (!file_name) return(FALSE);

	/*
	**	Determine if the file has a file table entry.  If it does, then
	**	special checks and processing must occur.
	** Also, if it is in memory, return with it.
	*/
	index = Find_File_Index(file_name);
	filedata = &FileDataPtr[index];

	if (index != ERROR) {

		// If the file is currently cached, return TRUE that it was found.
		if (filedata->Ptr) {
			return (TRUE);
		}
	}


	/*
	**	Always check the current directory for the file.  Only if it can't
	**	be found are furthur measures required.
	*/
	DiskNumber = ERROR;		// This indicates file exists in current directory.

		
 	#if (LIB_CDROM)
		ibm_setdisk(*StartPath - 'A');
 	#endif

	/*
	**	Check the current directory by attempting to open with READ access.
	*/
	{
		WORD	handle;
		
		CallingDOSInt++;
		handle = open(file_name, O_RDONLY | O_BINARY, S_IREAD);
		CallingDOSInt--;
		if (handle != ERROR) 
		{
		   //	WORD	d;
			unsigned d ;

			CallingDOSInt++;
			close(handle);
			// d = getdisk();
			_dos_getdrive ( & d) ;
			CallingDOSInt--;
			return(d);
		}
	}
	
		
	if (index != ERROR) {

		disk = filedata->Disk;
		/*
		**	If the file is in a packed file, then search for the packed file
		**	instead of the specified one.
		*/
		if (index != ERROR && (filedata->Flag & FILEF_PACKED)) {
			filedata = &FileDataPtr[disk];
			return (Find_File(filedata->Name));
		}

	}

	/*
	**	It could not be found on the current drive, so search the other
	**	drives if allowed to do so.
	*/
	if (!MultiDriveSearch) {
		return(FALSE);
	}

#if (LIB_CDROM)
	// If we were unable to find the file on the hard drive, change
	// drives to the CD rom drive and see if it is there.
	ibm_setdisk(*DataPath - 'A');
 
	{
		WORD	handle;
		
		Hard_Error_Occured = 0;

	  	handle = Open_File_With_Recovery( file_name, MODE_OLDFILE );

		if (handle != FILEOPENERROR) {
			FILECLOSE(handle);
			return(ibm_getdisk() + 1);
		}
	}

	ibm_setdisk(*StartPath - 'A');
	return (FALSE);
#else

	{
		WORD	start_drive;	// Original current drive number.

		/*
		**	Record the current drive for restoring later in case of failure.
		*/
		CallingDOSInt++;
		start_drive = getdisk();
		CallingDOSInt--;

		/*
		**	Sweep backward from the last real drive to the first, looking for the
		**	file on each in turn.
		*/
		for (index = MaxDevice; index != -1; index--) {
			if (Is_Device_Real(index)) {
				CallingDOSInt++;
			 	setdisk(index);
				CallingDOSInt--;

				{
					WORD	handle;

					CallingDOSInt++;
					handle = open(file_name, O_RDONLY | O_BINARY, S_IREAD);
					CallingDOSInt--;
					if (handle != ERROR) {
						CallingDOSInt++;
						close(handle);
						CallingDOSInt--;
						DiskNumber = index+1;
						return (DiskNumber);
					}
				}
			}
		}
		CallingDOSInt++;
		setdisk(start_drive);
		CallingDOSInt--;
	}
	
	return(FALSE);
#endif

}


/***************************************************************************
 * FIND_FILE_INDEX -- Finds the FileTable index number for a given file.   *
 *                                                                         *
 *    This function searches the FileTable and returns with the index of   *
 *    the matching file.  If the file doesn't exist in the table, then     *
 *    ERROR is returned.  It does not care about case.                     *
 *                                                                         *
 * INPUT:   filename -- Pointer to the filename to check.                  *
 *                                                                         *
 * OUTPUT:  Returns with the index into the FileTable.  If the file does   *
 *          not exist in the file table, then ERROR is returned.           *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/09/1991 JLB : Created.                                             *
 *   06/11/1993 JLB : Sorts and binary searches the file table.            *
 *=========================================================================*/
PRIVATE int Comp_Func(const void *p1, const void *p2)
{
	return(strcmp((char *) ((FileDataType*)p1)->Name, (char *) ((FileDataType*)p2)->Name));
}
WORD cdecl Find_File_Index(BYTE const *filename)
{
	FileDataType	*filedata;			// File entry pointer.
	FileDataType	key;					// Working file data type var.

	/*
	**	Perform a binary search on the presorted filetable.
	*/
	if (filename) {

		filedata = NULL;
		key.Name = (BYTE *) strupr((char *)filename);
		if (strstr((char *)key.Name, (char *)".PAK")) {
			
			/*
			** If the FileData table was not loaded from the disk then the PAK files are
			** not sorted so Perform a linear search for the pak files.
			** Otherwise the files are sorted so speed things up by doing a bsearch.
			*/
			if (FileData == FileDataPtr) {
				filedata = (FileDataType *) lfind(&key, FileDataPtr, (size_t *) &NumPAKFiles, sizeof(FileDataType), Comp_Func);
			}
			else {
				filedata = (FileDataType *)bsearch(&key, FileDataPtr, NumPAKFiles, sizeof(FileDataType), Comp_Func);
			}

		} else {
				
			/*
			**	Perform a binary search for the regular files.
			*/
			filedata = (FileDataType *)bsearch(&key, &FileDataPtr[NumPAKFiles], NumFiles, sizeof(FileDataType), Comp_Func);
		}

		// Return the element in the array if file was found in table.
		if (filedata) {
			return (filedata - FileDataPtr);
			//return ((WORD)((((LONG)filedata) - ((LONG)FileDataPtr)) / sizeof(FileDataType)));
		}
	}
	return(ERROR);
}




