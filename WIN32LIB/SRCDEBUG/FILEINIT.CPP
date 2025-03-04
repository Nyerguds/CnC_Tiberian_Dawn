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
 *                 Project Name : Library - Fileio init routines.          *
 *                                                                         *
 *                    File Name : FILEINIT.C                               *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : September 13, 1993                       *
 *                                                                         *
 *                  Last Update : April 19, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   WWDOS_Init -- Initialize the fileio WWS fileio system.                *
 *   WWDOS_Shutdown -- Clean up any things that needs to be to exit game.  *
 *   Init_FileData_Table -- Initializes or reads in FileData Table.        *
 *   Sort_FileData_Table -- Sorts the FileData table that is in memory.    *
 *   Preload_Files -- Loads files marked with FILEF_PRELOAD into cache.    *
 *   Init_File_Cache -- Initializes and allocs the file cache heap.        *
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

#ifndef MISC_H
#include <misc.h>
#endif

#include <direct.h>
#include <search.h>
#include <string.h>

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

PRIVATE FileInitErrorType cdecl Init_File_Cache(ULONG cachesize);
PRIVATE FileInitErrorType cdecl Init_FileData_Table(BYTE const *filename);
PRIVATE FileInitErrorType cdecl Set_Search_Drives( BYTE *cdpath );
PRIVATE FileInitErrorType cdecl Preload_Files(VOID);
PRIVATE int QSort_Comp_Func(const void *p1, const void *p2);
PRIVATE VOID Sort_FileData_Table(VOID);

/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/



/***************************************************************************
 * WWDOS_INIT -- Initialize the fileio WWS fileio system.                  *
 *                                                                         *
 *                                                                         *
 * INPUT:   ULONG cachesize - size wanted for the cache.                   *
 *          BYTE *filedat - NULL or name of filedata table file.           *
 *          BYTE *cdpath - NULL or secondary search path on a CD.          *
 *                                                                         *
 * OUTPUT:  Returns all errors encountered or'd together.						*
 *                                                                         *
 * WARNINGS:  User should call the WWDOS_Init function for all file 			*
 *            initialization.																*
 *                                                                         *
 * HISTORY:                                                                *
 *   04/19/1994 SKB : Created.                                             *
 *=========================================================================*/
FileInitErrorType cdecl WWDOS_Init(ULONG cachesize, BYTE *filedata, BYTE *cdpath)
{
//	FileInitErrorType errors;
	unsigned errors ;
	
	// This has not been completed yet, when it is, uncomment it and add errors.
	Install_Hard_Error_Handler () ;
	Get_Devices();

	if (cachesize) {	
		errors = Init_File_Cache(cachesize);
	} else {
	 	errors = FI_SUCCESS;
	}


	errors = errors | Init_FileData_Table(filedata);

	errors = errors | Set_Search_Drives(cdpath);

	errors = errors | Preload_Files();


	return ( FileInitErrorType ) errors ;
}

/***************************************************************************
 * WWDOS_SHUTDOWN -- Clean up any things that needs to be in file syste to *
 *                   exit game.    														*
 *                   One could shut down the file system and open it back  *
 *                   up with a different size cache or filetable.          *
 *                                                                         *
 * INPUT:   NONE.																				*
 *                                                                         *
 * OUTPUT:  NONE.                                                          *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/19/1994 SKB : Created.                                             *
 *=========================================================================*/
VOID cdecl WWDOS_Shutdown(VOID)
{
	FileDataType			*filedata;					// Pointer to the current FileData.
	WORD						file_handle;
	FileHandleType		  	*filehandletable;			// Pointer to the current file handle.

	// Close all open files.
	filehandletable = FileHandleTable;
	for (file_handle = 0; file_handle < TABLE_MAX; file_handle++, filehandletable++) {
		if (!filehandletable->Empty) {
		  	Close_File(file_handle);
		}
	}

	// Free the file cache heap.
	if (FileCacheHeap) {

		// Get a pointer to the current filedata.
		if (FileDataPtr) {
	 		filedata = FileDataPtr;
		} else {
	 		filedata = FileData;
		}

		while(filedata->Name && filedata->Name[0]) {
			filedata->Ptr = NULL;
			filedata++;
		}

		Free(FileCacheHeap);
		FileCacheHeap = NULL;
	}

	// Free up the file data.
	if (FileDataPtr != FileData) {
		Free(FileDataPtr);
	}
	FileDataPtr = NULL;

	chdir(StartPath);
	ibm_setdisk(*StartPath - 'A');

	// This has not been completed yet, when it is, uncomment it and add errors.
	Remove_Hard_Error_Handler();
}


/***************************************************************************
 * INIT_FILE_CACHE -- Initializes and allocs the file cache heap.          *
 *                                                                         *
 * INPUT:  ULONG cachesize - size of heap cache..                          *
 *                                                                         *
 * OUTPUT: FileInitErrorType  error code.                                  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/19/1994 SKB : Created.                                             *
 *=========================================================================*/
PRIVATE FileInitErrorType cdecl Init_File_Cache(ULONG cachesize)
{
	// Allocate and initialize the file cache heap.
	if (FileCacheHeap) {
 	 	return (FI_CACHE_ALREADY_INIT);
	}

	if ((Ram_Free(MEM_NORMAL) >= cachesize)) {
		FileCacheHeap = Alloc(cachesize, MEM_NORMAL);
		Mem_Init(FileCacheHeap, cachesize);
	}

	if (!FileCacheHeap) {
	 	return (FI_CACHE_TOO_BIG);
	}

	return (FI_SUCCESS);
}




/***************************************************************************
 * INIT_FILEDATA_TABLE -- Initializes or reads in FileData Table.          *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT: FileInitErrorType  error code.                                  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/
PRIVATE FileInitErrorType cdecl Init_FileData_Table(BYTE const *filename)
{
	WORD					fd;
	ULONG					fsize;
	FileDataType		*ptr;
	WORD 					index;
	BYTE					fname[13];		

	/*
	**	Inialize the file handle table to reflect no files open.
	*/
	for (index = 0; index < TABLE_MAX; index++) {
		FileHandleTable[index].Empty = TRUE;
	}

	// Set up our FileData ptr to be the initial FileData table.
	FileDataPtr = FileData;

	// Sort the filedata table.
	// This needs to be done even if we load it off disk since the initial file data
	// table might contain a filename.
	Sort_FileData_Table();

	// If there is a file name, then the filedata table will be loaded from disk.
	if (filename) {
		if (!Find_File(filename)) {
		 	return (FI_FILEDATA_FILE_NOT_FOUND);
		}
		fd = Open_File(filename, READ);

		fsize = File_Size(fd);

		if ((Ram_Free(MEM_NORMAL) < fsize)) {
			Close_File(fd);
		 	return (FI_FILEDATA_TOO_BIG);
		}

		// Allocate some system memory.
		// Setup the new FileDataPtr and this time.
		FileDataPtr = ptr = (FileDataType *) Alloc(fsize, MEM_NORMAL);

		// Load the file up into  memory.
		Read_File(fd, FileDataPtr, fsize);
		Close_File(fd);

		// Process the filetable.  The filenames need their pointers adjusted.
		// At this time we will also count the number of files and number of PAK files.
		NumPAKFiles = NumFiles = 0;

		// Make sure that the file name will have a NUL at the end.
		fname[12] = 0;
		while(TRUE) {
			// Have we reached the end of the list?	
			if (!ptr->Name) break;
		 	
			// Adjust the name pointer to point the the correct area.
			ptr->Name = (BYTE *)FileDataPtr + (LONG) ptr->Name;

			// Count up weather it is a PAK file or a normal file.
			if (!NumFiles && strstr((char *) ptr->Name, (char *)  ".PAK")) {
			 	NumPAKFiles++;

				// Mark that it has been processed so that Open_File() will not do it.
				ptr->Flag |= FILEF_PROCESSED;

			} else {
				NumFiles++;
			}

			// Next record.
			ptr++;
		}
	}

	return (FI_SUCCESS);
}




/***************************************************************************
 * Set_Search_Drives -- Sets up the CDRom and HardDrive paths.             *
 *                                                                         *
 * INPUT:    BYTE *cdpath - path of data files on a CD.							*
 *           					 Should pass in NULL for non CD products.			*
 *           																					*
 * OUTPUT: FileInitErrorType  error code.                                  *
 *           Varibable defined:                                            *
 *               ExecPath = Full path of EXE file.                         *
 *               StartPath = Directory user started in.                    *
 *               DataPath = secondary search path (typically CD-ROM).      *
 *           Note: format of paths is "C:\PATH"                           	*
 *                                                                         *
 * WARNINGS: The cdpath may be overiden by a "-CD<path>" command line      *
 *           arguement that specifies another drive (HARD or CD) and path  *
 *           where the data resides.  Whenever a file is opened, it checks *
 *           the startup drive first, then the CD search path if the first *
 *           search was unsuccessful.                                      *
 *                                                                         *
 * HISTORY:                                                                *
 *   01/14/1993  SB : Created.                                             *
 *   04/19/1994 SKB : Mods for 32 bit library.                             *
 *=========================================================================*/
PRIVATE FileInitErrorType cdecl Set_Search_Drives( BYTE *cdpath )
{
	BYTE *ptr;


#if LIB_EXTERNS_RESOLVED 
	// NOTE: THIS IS WRONG, THIS IS NOT THE WAY TO GET THE EXE's PATH.
	// Locate the executable.	
	strcpy(ExecPath, _argv[0]);

	// Find the very last '\' on the path.
	ptr = strrchr((char *) ExecPath, (int) '\\');
#else
	ptr = NULL;
#endif

	// Remove the exe name to just have the path.
	if (ptr == NULL) {
		*ExecPath = 0;
	}
	else {
	 	*ptr = 0; 
	}

	// Did the user specify a second path?
	ptr = Find_Argv("-CD");

	// If so, set the data path to that.
	if (ptr) {
		strcpy(DataPath, ptr + 3);
	}
	// Otherwise check to see if there is a CD-Rom drive.
	else {
		if (cdpath && *cdpath) {

#if LIB_EXTERNS_RESOLVED
			UseCD = GetCDDrive();
#else
			UseCD = FALSE;
#endif
		}
		else {
		 	UseCD = FALSE;
		}

		// If so, set the Drive to it and find out if any directories.
		if ( UseCD ) {
			strcpy( DataPath, "A:" );
			strcat( DataPath, cdpath);
			*DataPath = 'A'+UseCD;
		}
		// If not, set the Data path to the execacutable path.
		else {
	 		strcpy(DataPath, ExecPath);
		}
	}

	// Finnally, set the starting path.
	getcwd(StartPath, XMAXPATH);

	// Make sure they are all uppercase.
	strupr(StartPath);
	strupr(DataPath);
	strupr(ExecPath);

	// Change directories to the secondary search path (DataPath).
	if (*DataPath && chdir(DataPath)) {
		return (FI_SEARCH_PATH_NOT_FOUND);
	}

	// Lastley, Make sure we are in the startup directory.  This will overide
	// the secondary data path if they are on the same drive.
	if (chdir(StartPath)) {
		return (FI_STARTUP_PATH_NOT_FOUND);
	}

	return (FI_SUCCESS);
}


/***************************************************************************
 * PRELOAD_FILES -- Loads files marked with FILEF_PRELOAD into cache.      *
 *                                                                         *
 *                                                                         *
 * INPUT:  none.                                                           *
 *                                                                         *
 * OUTPUT: FileInitErrorType  error code.                                  *
 *                                                                         *
 * WARNINGS: The FileData must be initialized and the file heap initialized*
 *           in order for this to work.                                    *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/19/1994 SKB : Created.                                             *
 *=========================================================================*/
PRIVATE FileInitErrorType cdecl Preload_Files(VOID)
{
	FileDataType	*filedata;		// Working file data table pointer.
	BOOL				oldflag;			// Previous file flag.

	if (!FileDataPtr) {
		return (FI_FILETABLE_NOT_INIT);
	}

	if (!FileCacheHeap) {
		return (FI_NO_CACHE_FOR_PRELOAD);
	}

	/*
	**	Make all files flagged to be made resident at startup, resident.
	*/
	filedata = FileDataPtr;

	while (filedata->Name && strlen(filedata->Name)) {
		if (filedata->Flag & FILEF_PRELOAD) {

			oldflag = filedata->Flag;
			filedata->Flag |= FILEF_RESIDENT;	// Make it resident.
			filedata->Flag &= ~FILEF_FLUSH;		// Don't purge on Close_File.

			Close_File(Open_File(filedata->Name, READ));

			filedata->Flag &= ~(FILEF_RESIDENT|FILEF_FLUSH);	// Clear bits.
			filedata->Flag |= oldflag & (FILEF_RESIDENT|FILEF_FLUSH);	// Restore bits.

		}
		filedata++;
	}
	return (FI_SUCCESS);
}



/***************************************************************************
 * SORT_FILEDATA_TABLE -- Sorts the FileData table that is in memory.      *
 *                                                                         *
 * INPUT:  NONE                                                            *
 *                                                                         *
 * OUTPUT: NONE.                                                           *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/13/1993 SKB : Created.                                             *
 *=========================================================================*/

PRIVATE int QSort_Comp_Func(const void *p1, const void *p2)
{
	return(strcmp(((FileDataType*)p1)->Name, ((FileDataType*)p2)->Name));
}
PRIVATE VOID Sort_FileData_Table(VOID)
{
	/*
	**	Sort the filetable it but keep the pack file indexes correct.
	*/

	/*
	**	The number of pak files in the file table.
	*/
	NumPAKFiles = 0;
	strupr(FileData[NumPAKFiles].Name);
	while (strstr((char *) FileData[NumPAKFiles].Name, (char *) ".PAK")) {
		strupr(FileData[NumPAKFiles].Name);
		NumPAKFiles++;
	}

	/*
	**	Count the remaining files within the file table.
	*/
	NumFiles = 0;
	while(FileData[NumFiles+NumPAKFiles].Name && FileData[NumFiles+NumPAKFiles].Name[0]) {
		strupr(FileData[NumFiles+NumPAKFiles].Name);
		NumFiles++;
	}

	/*
	**	Sort the file entries (past the pak files).
	*/
	if (NumFiles) {
		qsort(&FileData[NumPAKFiles], NumFiles, sizeof(FileDataType), QSort_Comp_Func);
	}
}

