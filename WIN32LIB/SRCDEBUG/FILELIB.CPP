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
 *                 Project Name : FILEIO Library support routines.         *
 *                                                                         *
 *                    File Name : FILELIB.C                                *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : April 11, 1994                           *
 *                                                                         *
 *                  Last Update : April 11, 1994   [SKB]                   *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 *-------------------------------------------------------------------------*
 *  Notes: This file contains private functions to the fileio system.      *
 *         While these functions may be used by any module in the fileio   *
 *         system, they cannot be used by a user program.  For this reason *
 *         they are put into this module.                                  *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Cache_File -- Attempts to cache file in XMS if flags set.             *
 *   Do_IO_Error -- Performs a non-recoverable error message display.      *
 *   Do_Open_Error -- Does an error message that could return.             *
 *   Is_Handle_Valid -- Determines validity of the specified file handle.  *
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


#include <fcntl.h>
#include <io.h>
#include <process.h>
#include <sys\stat.h>

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/***************************************************************************
 * DO_ERROR -- Does an error message that could return.               *
 *                                                                         *
 *    This routine displays a file error message and unless the player     *
 *    presses <ESC>, it will return.  If the player presses <ESC>, then    *
 *    it will terminate the program.                                       *
 *                                                                         *
 * INPUT:   error    -- Error message number.                              *
 *                                                                         *
 *          filename -- File name that the error occured on.               *
 *                                                                         *
 * OUTPUT:  TRUE/FALSE; Should the process be repeated?                    *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/09/1991 JLB : Created.                                             *
 *=========================================================================*/
#pragma argsused
WORD cdecl Do_Open_Error(FileErrorType errormsgnum, BYTE const *file_name)
{
	BYTE	*ptr=NULL;		// Working file name pointer (just name and extension).

	/*
	** Since the file name may include a path, we must extract the true
	** file name from the given string.
	*/
	if (file_name) {
#if  LIB_EXTERNS_RESOLVED 
		ptr = strrchr((char *) file_name, (int) '\\');
#else
		ptr = NULL;
#endif		
		if (ptr) {
			ptr++;
		} else {
			ptr = (BYTE *) file_name;
		}
	}

#if  LIB_EXTERNS_RESOLVED 
	strupr(ptr);
	return (IO_Error(errormsgnum, ptr));
#else
	return(0);
	
#endif	

}


/***************************************************************************
 * DO_IO_ERROR -- Performs a non-recoverable error message display.        *
 *                                                                         *
 *    This routine will perform a non-recoverable file error message       *
 *    display.  It is called when an error is detected that has no         *
 *    recovery or retry process defined.                                   *
 *                                                                         *
 * INPUT:   errornum -- Error number detected.                             *
 *                                                                         *
 *          filename -- Name of the file that caused the error.            *
 *                                                                         *
 * OUTPUT:  none                                                           *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/09/1991 JLB : Created.                                             *
 *=========================================================================*/
#pragma argsused
VOID cdecl Do_IO_Error(FileErrorType errormsgnum, BYTE const *filename)
{
#if  LIB_EXTERNS_RESOLVED 
	(VOID)IO_Error(errormsgnum, filename);
#endif
	#if(TRUE)
	Prog_End();
	exit((int)errormsgnum);
	#else
	Program_End();
	#endif
}


/***************************************************************************
 * Read_File_With_Recovery -- read the same file on another directory if an error    *
 *                  occurs.                                                *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   02/16/1993  QY : Created.                                             *
 *=========================================================================*/
LONG cdecl Read_File_With_Recovery( WORD handle, VOID *buf, UWORD bytes )
{
	WORD newhandle;
	LONG bytes_read;

	do {
		Hard_Error_Occured = 0;

		// Make sure we are in the right path.
		CHANGEDIR( DataPath );

		// open the same file
		newhandle = Open_File( FileHandleTable[ handle ].Name, FileHandleTable[ handle ].Mode );
	   Seek_File( newhandle, FileHandleTable[ handle ].Pos, SEEK_SET );

		// dos close the old file
		FILECLOSE( FileHandleTable[ handle ].Handle );

		// copy FileHandleTable[ newhandle ] to FileHandleTable[ handle ]
		Mem_Copy( &FileHandleTable[ newhandle ], &FileHandleTable[ handle ],
 		         ( ULONG ) sizeof( FileHandleTable[ newhandle ] ) );

		// delete FileHandleTable[newhandle]

		FileHandleTable[ newhandle ].Empty = TRUE;

		// continue reading file 
		bytes_read = ( LONG ) FILEREAD( FileHandleTable[ handle ].Handle, buf, bytes );

		// if still error, do it again; else return the number of bytes read
		if ( !Hard_Error_Occured ) {
			return( bytes_read );
		}
		if (!Do_Open_Error(COULD_NOT_OPEN, FileHandleTable[ handle ].Name)) {
			return(FALSE);
		}

	} while (CHANGEDIR( DataPath ));

	return (NULL);
}

/***************************************************************************
 * Open_File_With_Recovery -- open the same file on another directory      *
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
 *   02/16/1993  QY : Created.                                             *
 *=========================================================================*/
WORD cdecl Open_File_With_Recovery( BYTE const *file_name, UWORD mode )
{
	WORD handle;

	Hard_Error_Occured = FALSE;
	handle = FILEOPEN(file_name, mode);

	// Do not return if there was a HardError and Using a CD and we are looking at
	// the CD.
	if (!Hard_Error_Occured || !UseCD || (ibm_getdisk() != (*DataPath - 'A'))) {
		return (handle);
	}

#if DEBUGPRINT
	Mono_Print(file_name); Mono_Print(":OPENERROR  ");
#endif

	Hard_Error_Occured = 0;

	// It is possible that the CD has been poped out and put back in, let us
	// change there and then try again.
	ibm_setdisk(*DataPath - 'A');
	CHANGEDIR( DataPath );

	// open the same file
	handle = FILEOPEN( file_name, mode );

	// if still error, do it again; else return the dos handle
	if ( !Hard_Error_Occured ) {
		return( handle );
	}
		
	Hard_Error_Occured = 0;
	return (FILEOPENERROR);
}


/***************************************************************************
 * CACHE_FILE -- Attempts to cache file in XMS if flags set.               *
 *                                                                         *
 *                                                                         *
 * INPUT:    WORD index - the index of the file in the FileData table.     *
 *           WORD file_handle - WWS file handle of file.                   *
 *                                                                         *
 * OUTPUT:   BOOL : was it cached?                                         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/21/1993 SKB : Created.                                             *
 *=========================================================================*/
BOOL cdecl Cache_File(WORD index, WORD file_handle)
{
	LONG				filesize;		// Size of the memory block needed.
	LONG				freecache; 		// Amount of free XMS.
	FileDataType	*filedata = NULL;
	FileDataType	hold;
	FileHandleType	*filehandletable;
	WORD				flag;				// Type of system memory to cache file.
	WORD				file;

	// Only files in the file table can be cached.
	if (index == ERROR) {
	 	return FALSE;
	}

	// Setup our pointer to the file we may want to cache.
	filedata = &FileDataPtr[index];

	// Should this be cached, and is it not yet cached?
	if ((filedata->Flag & (FILEF_RESIDENT|FILEF_PRELOAD)) && !filedata->Ptr) {

		filesize = filedata->Size;

		/*
		**	If there is o room to cache the file, then turn off its cache file.
		*/
		if (filesize > Mem_Pool_Size(FileCacheHeap)) { 

			// Remove resident flags so that it will not keep trying to cache itself 
			// since there will never be enough room for it.
			filedata->Flag &= ~(FILEF_PRELOAD|FILEF_KEEP|FILEF_RESIDENT|FILEF_FLUSH);
			
			return FALSE;
		}


		// Go through freeing files until there is enouph space in the
		// memory pool.
		while (filesize > Mem_Avail(FileCacheHeap)) {
			VOID  *node;

			// Get the oldest non used file pointer.
			node = Mem_Find_Oldest(FileCacheHeap);

			// If non was found, sorry no room for the new file.
			if (!node) {
				return (FALSE);
			}

			// Get a pointer to the structure for convenience.
			filedata = &FileDataPtr[Mem_Get_ID(node)];

			// Free it from the heap and update the file system so it knows that
			// the file is no longer in memory.
			Mem_Free(FileCacheHeap, filedata->Ptr);
			filedata->Ptr = NULL;
		}


		// If there is not a big enough space we will have to take garbage
		// collection hit.  (OUCH!!!!!!)
		if (filesize > Mem_Largest_Avail(FileCacheHeap)) {
			Unfragment_File_Cache();
		}

		// Make sure we have a big enough space and if so, put the file into memory.
		if (filesize < Mem_Largest_Avail(FileCacheHeap)) {

			// Get some pointers to save code space and time.
			filehandletable = &FileHandleTable[file_handle];
			filedata = &FileDataPtr[index];

			// Alloc the buffer in our file cache, then read the file in.
			filedata->Ptr = Mem_Alloc(FileCacheHeap, filesize, index);

			// Extra check - it should not fail.
			if (!filedata->Ptr) return(FALSE);

			// Mark it so that it never comes back as Oldest used.
			Mem_In_Use(filedata->Ptr);

			// Get the file into memory.
			Read_File(file_handle, filedata->Ptr, filesize);

			// reset the read index from the above read.
			filehandletable->Pos = 0L;

			// This makes caching inner pak file possible.  No longer is the
			// PAK'd file based off the parent file.
			filehandletable->Start = 0;	  

			// Close the parent file.  Remove it's open count.
			if (filedata->Flag & FILEF_PACKED) {
				FileDataType	p_hold;
				FileDataType	*parent;

				parent = &FileDataPtr[filedata->Disk];
				parent->OpenCount--;
			}
			FILECLOSE(filehandletable->Handle);
			filehandletable->Handle = 0;

			return (TRUE);
		}	
	}

	// The file was not cached, let the caller know.
	return (FALSE);
}
