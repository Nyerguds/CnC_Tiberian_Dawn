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
 *                 Project Name : Library                                  *
 *                                                                         *
 *                    File Name : FILE.CPP                                 *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : September 13, 1993                       *
 *                                                                         *
 *                  Last Update : September 13, 1993   [SKB]               *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   File_Exists -- Searches for and FINDS the specified file.             *
 *   File_Size -- Determine the size of the specified file.                *
 *   Open_File -- Opens a file for access.                                 *
 *   Close_File -- Closes a file previously opened with Open_File.         *
 *   Seek_File -- Adjusts the position of the file pointer.                *
 *   Read_File -- Reads a block of data from a file.                       *
 *   Write_File -- Writes a block of data to a file.                       *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef WWSTD_H
#include <wwstd.h>
#endif	   

#ifndef FILE_H
#include "_file.h"
#endif

#ifndef WWMEM_H
#include <wwmem.h>
#endif


#include <fcntl.h>
#include <io.h>
#include <sys\stat.h>

#define DEBUGPRINT FALSE

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/***************************************************************************
 * OPEN_FILE -- Opens a file for access.                                   *
 *                                                                         *
 *    This routine will open the specified file for access.  It functions  *
 *    in a similar manner to the regular DOS open command.                 *
 *                                                                         *
 * INPUT:   filename -- Pointer to the filename to open.                   *
 *                                                                         *
 *          mode     -- Access mode to use.                                *
 *             READ: A file opened for READ access, MUST be available.     *
 *                   This may cause a disk swap message to appear.         *
 *                                                                         *
 *             WRITE:A file opened for WRITE access (only), need not be    *
 *                   available.  If it can't be found, then it will be     *
 *                   created in the current directory.                     *
 *                                                                         *
 * OUTPUT:  Returns with the westwood file handle.  If ERROR is returned   *
 *          it means that the programmer took over the file error handler  *
 *          and signaled that an open access failure should not keep trying*
 *          for success.                                                   *
 *                                                                         *
 * WARNINGS:   If you take over the file error handling code, you must be  *
 *             sure to anticipate a possible ERROR value being returned.   *
 *             If you open a file for READ or READ|WRITE, then the file    *
 *             must previously exist.  To create a file for read and write *
 *             access, first open it for WRITE, then re-open it for        *
 *             read and write.                                             *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/11/1991 JLB : Created.                                             *
 *=========================================================================*/
WORD cdecl Open_File(BYTE const *file_name, WORD mode)
{
	WORD							file_handle;				// Westwood file handle.
	WORD					 		handle;						// DOS file handle.
	UWORD				 			local_mode;					// DOS access mode number.
	WORD							index;						// FileData index (if available).
	BOOL							immediate;					// Is the file immediately available?
	FileDataType				*filedata;					// Pointer to the current FileData.
	FileDataType				*parent;						// Pointer to the current FileData.
	FileHandleType				*filehandletable;			// Pointer to the current file handle.

	CallingDOSInt++;


	#if(DEBUGPRINT)
		Mono_Printf("Open_File('%s')\r", file_name);
	#endif

	/*
	** Is there a slot in the FileHandleTable?  If not, then exit with
	**	a file error.
	*/
	filehandletable = FileHandleTable;
	for (file_handle = 0; file_handle < TABLE_MAX; file_handle++, filehandletable++) {
		if (filehandletable->Empty) break;
	}
	if (file_handle == TABLE_MAX) {
 		Do_IO_Error(TOO_MANY_FILES, file_name);
	}

	/*
	**	Find the file in the FileTable (if it exists there).
	*/
	index = Find_File_Index(file_name);
	filedata = &FileDataPtr[index];

	// Start out looking at the start drive.
	ibm_setdisk(*StartPath - 'A');

	/*
	**	If the file exists in the current directory, then by all
	**	means, use that file instead of any corresponding pack
	**	file representation.  This is used as a means of
	**	overriding packed files (quite handy).
	*/
	immediate = FALSE;

	/*
	**	Check the current directory by attempting to open with READ access.
	** Only check if the file is not already cached and it is a packed file.
	*/
	if ((index != ERROR) && (filedata->Flag & FILEF_PACKED) && (!filedata->Ptr)) 
	{
		WORD	handle2;
	
		handle2 = FILEOPEN(file_name, MODE_OLDFILE);
		if (handle2 != FILEOPENERROR) {
			FILECLOSE(handle2);
			immediate = TRUE;
		}
	}


	/*
	** Check to see if any WRITE permission is requested for the
	**	file.  If so, delete the file from RAM and mark it as non-resident.
	**
	**	NOTE:	If the file is packed, we CAN NOT alter it in ANY way.
	**			We will return an ERROR to the user, and hope he/she is
	**			smart enough to handle it.
	*/
	if ((mode & WRITE) && index != ERROR && filedata->Ptr) {
		if(filedata->Flag & FILEF_PACKED) {		// is file packed?
			Mem_Free(FileCacheHeap, filedata->Ptr);						
			filedata->Ptr = NULL;
		} else {													// file is packed
			Do_IO_Error(WRITING_RESIDENT, file_name);
		}
	}

	// If the file is cached already, then let us use it and leave.
	if (filedata->Ptr && index != ERROR) {
		/*
		**	File is resident.  Initialize the local table.
		*/
		filehandletable->Index = index;
		filehandletable->Empty = FALSE;
		filehandletable->Pos = 0L;
		filehandletable->Name = filedata->Name;
		filehandletable->Handle = 0;	// Resident flag.
		filehandletable->Mode = mode;

		// If the cached file is packed and its parent is resident, then
		// add one to the parent open count.
		if (filedata->Flag & FILEF_PACKED) {
			parent = &FileDataPtr[filedata->Disk];
		}
		else {
			parent = NULL;
		}

		if (parent && (parent->Ptr == filedata->Ptr)) {
			filehandletable->Start = filedata->Start;
			parent->OpenCount++;
		} else {
			filehandletable->Start = 0;
		}

		// Mark the pointer in use so that it is never returned as the oldest
		// pointer location in memory.
		Mem_In_Use(filedata->Ptr);

	} else {
		
		/*
		** At this time we determine if it is a packed file.  If so, the
		**	opening process takes a dramatically different turn.
		*/
		if (index != ERROR && (filedata->Flag & FILEF_PACKED) && !immediate && (mode & WRITE) == 0) {

			/*
			**	This is a packed file.  Perform recursive open process to reach
			**	the parent packed file.
			*/
			parent = &FileDataPtr[filedata->Disk];
			file_handle = Open_File(parent->Name, mode);

			// Reread the parents information.
			parent = &FileDataPtr[filedata->Disk];
			filehandletable = &FileHandleTable[file_handle];

			/*
			**	Process the packed file header.  Update the start offset for every
			**	file ellaborated in the packed file.  
			**	Exception:  When a file is specified in the packed file and an
			**					entry exists for it in the file table, BUT the entry
			**					is not marked as packed, THEN ignore the packed version
			**					of the file.
			*/

			if (FileData == FileDataPtr && 
			    !(FileDataPtr[filehandletable->Index].Flag & FILEF_PROCESSED)) {
				LONG	offset;					// Offset of sub-file start.
				WORD	i;							// Sub-file FileData index.
				BYTE	name[FILENAMESIZE];	// Name of sub-file.
				FileDataType	*cur=NULL;	// Current entry in FileData.
				FileDataType	*last=NULL;	// Last entry in FileData.


				#if(DEBUGPRINT)
					Mono_Printf("Processing packed file '%s'\r", FileDataPtr[filedata->Disk].Name); 
				#endif

				Read_File(file_handle, &offset, (ULONG)sizeof(LONG));
				while (offset) {

					/*
					**	Due to the fact that the embedded file name is of arbitrary
					**	length, we must read it in a byte at a time.  Reading stops
					**	when the terminating NULL is found.
					*/
					i=0;
					do {
						Read_File(file_handle, &name[i], (ULONG)sizeof(name[0]));
					} while (name[i++]);

					i = Find_File_Index(name);
					if (i != ERROR) {
						cur = &FileDataPtr[i];
						if ((cur->Flag & FILEF_PACKED) && cur->Disk == filehandletable->Index) {

							cur->Start = offset + FileDataPtr[ filehandletable->Index ].Start;
							if (last != NULL) {
								last->Size = cur->Start - last->Start;
							}

							last = cur;	
						}
					} else {
						// ERROR: File specified in packed file has no table entry.
						// When this occurs, the embedded file is ignored.
					}

					Read_File(file_handle, &offset, (ULONG)sizeof(LONG));
				}

				/*
				**	Fixup the size record of the last embedded file.
				*/
				if (last != NULL) {
					last->Size = File_Size(file_handle) - last->Start;
				}

				FileDataPtr[filehandletable->Index].Flag |= FILEF_PROCESSED;
			}

			// if the parent is resident, the the child must have the same address.
			filedata->Ptr = parent->Ptr;

			/*
			**	Set starting position to start of embedded file.
			*/
			filehandletable->Index = index;
			filehandletable->Name = filedata->Name;
			filehandletable->Start = filedata->Start;

			Seek_File(file_handle, NULL, SEEK_SET);

			// Attempt to cache the file if wanted, and room.
			Cache_File(index, file_handle);

		} else {

			/*
			**	Convert the Westwood access mode into the system specific mode.
			*/
			local_mode = MODE_OLDFILE;
			switch (mode) {
				case READ:
					local_mode = MODE_OLDFILE;
					break;

				case READ | WRITE:
					#if(IBM)
						local_mode = MODE_READWRITE;
					#else
						local_mode = MODE_OLDFILE;
					#endif
					break;

				case WRITE:
					local_mode = MODE_NEWFILE;
					break;


				default:
					Do_IO_Error(BAD_OPEN_MODE, file_name);
					break;
			}


			/*
			**	The file is disk based.  Perform the DOS open processing.
			*/

			/*
			**	Make sure the file is available or the proper disk is inserted.
			** The file MUST exist if READ access is requested.  A mild attempt
			**	will be made to find the file if open for WRITE only.
			*/
			if (mode & READ) {
				if (!File_Exists(file_name)) {
					CallingDOSInt--;
					return(ERROR);			/* Ignore the error */
				}
			} 


			/*
			**	Repetitively try to open the file until the error handler
			**	routine indicates otherwise.
			*/
			handle = FILEOPENERROR;
			for (;;) {
				handle = Open_File_With_Recovery( file_name, local_mode );
				if (handle != FILEOPENERROR) {
					break;
				} else {
					CHANGEDIR( DataPath );
					CHANGEDIR( StartPath );
					if (!Do_Open_Error(COULD_NOT_OPEN, file_name)) {
						CallingDOSInt--;
						return(FILEOPENERROR);
					}
				}
			}

			/*
			**	A file that is read off of disk cannot be part of
			**	a pack file regardless of the bit settting.
			*/
			if (immediate && index != ERROR) {
				filedata->Flag &= ~FILEF_PACKED;
				filedata->Size = 0;
			}

			if (index != ERROR) {

				// The true file size is needed.
				// Go back to beginning of file.
				filedata->Size = FILESEEK(handle, 0L, SEEK_END);
				FILESEEK(handle, 0L, SEEK_SET);
			}

			/*
			**	Initialize the local file handle table.
			*/
			filehandletable->Index = index;
			filehandletable->Pos = 0L;
			filehandletable->Start = 0L;
			filehandletable->Empty = FALSE;
			filehandletable->Handle = handle;
			filehandletable->Mode = mode;
			if (index != ERROR) {
				filehandletable->Name = filedata->Name;
			} else {
				filehandletable->Name = NULL;
			}

			/*
			**	If the file should be made resident, then do it at this time.
			**	Perform all necessary adjustments to the file tables.
			*/
			if ((mode & WRITE) == 0) {
				Cache_File(index, file_handle);
			}
		}
	}

	// If in the file table, increment the number of opens on this file.
	if (index != ERROR) {
		filedata->OpenCount++;
	}

	/*
	**	Return with valid file handle.
	*/
	CallingDOSInt--;
	return(file_handle);
}


/***************************************************************************
 * CLOSE_FILE -- Closes a file previously opened with Open_File.           *
 *                                                                         *
 *    Use this routine to close a file that was opened with Open_File.     *
 *    This is the only way to close a file that was opened with the        *
 *    Westwood file I/O system.                                            *
 *                                                                         *
 * INPUT:   handle   -- Westwood file handle.                              *
 *                                                                         *
 * OUTPUT:  none                                                           *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/11/1991 JLB : Created.                                             *
 *=========================================================================*/
VOID cdecl Close_File(WORD handle)
{
	WORD				index;					// File data table index.
	BOOL				flushed	= FALSE;		// If file flushed from cache, do change time stamp.
	BOOL				stillopen;
	FileDataType	*parent = NULL;
	FileDataType	*filedata = NULL;
	VOID				*memptr=NULL;


	#if(DEBUGPRINT)
		Mono_Printf("Close_File(%d)\r", handle);
	#endif


	/*
	**	Check for file handle validity.
	*/
	if (!Is_Handle_Valid(handle, CLOSING_NON_HANDLE, NULL)) {
		return;
	}

	CallingDOSInt++;

	index = FileHandleTable[handle].Index;
	filedata = &FileDataPtr[index];

	// Remove the OpenCount on the file.
	if (index != ERROR) {

		filedata->OpenCount--;
		stillopen = filedata->OpenCount;

		// If this file packed in another, then decrement the parents open count.
		if (filedata->Flag & FILEF_PACKED) {
			parent = &FileDataPtr[filedata->Disk];

			// Do not dec OpenCount if the child was cached but not the parent.
			if (parent->Ptr == filedata->Ptr) {
		 		parent->OpenCount--;
				stillopen = parent->OpenCount;
			}
		}
	}


	// If the file was resident, then handle bookeeping.
	if (index != ERROR && filedata->Ptr) {

		// Get a pointer to the memory area for later use.
		memptr = filedata->Ptr;

		// If file has a parent, and it is the cached file...
		if (parent && (parent->Ptr == filedata->Ptr)) {

			// The PAK'd file is closed just by setting the pointer.
			if (!filedata->OpenCount)	{
				filedata->Ptr = NULL;
			}

			// Uncache parent if no other sons are open and it should be flushed.
			if ((!parent->OpenCount) && (parent->Flag & FILEF_FLUSH)) {
				Mem_Free(FileCacheHeap, parent->Ptr);
				parent->Ptr = NULL;
				flushed = TRUE;
			}
		}
		// Else should the file be flushed?  Only flush it if the flag says
		// so AND there are no other open counts on it.
		else if ((filedata->Flag & FILEF_FLUSH) && !filedata->OpenCount) {
			Mem_Free(FileCacheHeap, filedata->Ptr);
			filedata->Ptr = NULL;
			flushed = TRUE;
		}

		//
		// Set the time stamp on the close IF
		//     the file was not flush AND
		//     is not open AND 
		//		 its time stamp should be changed by being a FILEF_KEEP|PROIORTY file.
		//
		if (!flushed && !stillopen && !(filedata->Flag & (FILEF_KEEP|FILEF_PRIORITY))) {
			Mem_Reference(memptr);
		}
	} 
	// Just a simple close will do.
	else 	{
		FILECLOSE(FileHandleTable[handle].Handle);
	}

	// The WWS handle is no longer being used.
	FileHandleTable[handle].Empty = TRUE;

	CallingDOSInt--;
}



/***************************************************************************
 * READ_FILE -- Reads a block of data from a file.                         *
 *                                                                         *
 *    This routine is used to read a block of data from a previously       *
 *    opened file.                                                         *
 *                                                                         *
 * INPUT:   handle   -- Westwood file handle returned from Open_File.      *
 *                                                                         *
 *          buf      -- Pointer to buffer to load the data into.           *
 *                                                                         *
 *          bytes    -- Number of bytes to load.                           *
 *                                                                         *
 * OUTPUT:  Returns with the number of bytes actually read from the file.  *
 *          If this number is less than the number requested, this         *
 *          indicates the end of the file.                                 *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/13/1991 JLB : Created.                                             *
 *=========================================================================*/
LONG cdecl Read_File(WORD handle, VOID *buf, ULONG bytes)
{
	WORD					doshandle;		// DOS file handle.
	WORD					fileindex;		// File table index.
	LONG					bytesread;		// Accumulation of number of bytes read.
	FileDataType	  	*filedata;		// Pointer to the current FileData.

	#if(DEBUGPRINT)
		Mono_Printf("Read_File(%d, %08lx, %ld)\r", handle, buf, bytes);
	#endif

	/*
	**	The handle must be valid or else it is an error.
	*/
	if (!buf || !bytes || !Is_Handle_Valid(handle, READING_NON_HANDLE, NULL)) {
		return(NULL);
	}

	CallingDOSInt++;

	/*
	**	Prepare some working variables.
	*/
	doshandle = FileHandleTable[handle].Handle;
	fileindex = FileHandleTable[handle].Index;


	/*
	**	Limit the number of bytes to read according to the size of the
	**	file.  If no file size is specified, then don't perform the check.
	*/
	if (fileindex != ERROR) {
		filedata = &FileDataPtr[fileindex];

		if (filedata->Size) {
			bytes = MIN((ULONG)filedata->Size - FileHandleTable[handle].Pos, bytes);
		}
	}

	/*
	**	Starts with no bytes being read in.
	*/
	bytesread = 0;

	if (bytes) {

		if (doshandle) {
			/*
			**	Perform a DOS read of the file.  Read the file in chunks.
			*/
			while (bytes) {
				LONG	number;	// Number of bytes read.

				/*
				**	Read in a chunk of file data.
				*/
				Hard_Error_Occured = 0;
				number = (LONG)FILEREAD(doshandle, buf, MIN(bytes, IO_CHUNK_SIZE));

				/*
				** if a hard error occurs, read its copy on a different directory
				*/
				if ( Hard_Error_Occured	) {
					number = Read_File_With_Recovery( handle, buf, (UWORD)MIN(bytes, IO_CHUNK_SIZE));
					doshandle = FileHandleTable[handle].Handle;
				}

				/*
				**	Adjust the remaining bytes to read counter and adjust the count
				**	of the number of bytes actually read from the file.
				*/
				bytes -= number;
				bytesread += number;

				/*
				**	Adjust the file position (manually).
				*/
				FileHandleTable[handle].Pos += number;

				/*
				**	If less than requested bytes were read from the file, then 
				** we KNOW that the reading loop must terminate.
				**	Was there an error?
				*/
				if (number < IO_CHUNK_SIZE) {
					break;
				}

				/*
				**	Adjust the destination pointer in anticipation of the next
				**	file read operation.
				*/
				// this is a BCC bug
				// (BYTE *)buf += number;
				 buf = (BYTE* ) buf +  number;

			}

		} else {

			#if (DEBUGPRINT)
				Mono_Printf("Resident read '%s' %08lx[%ld].%ld\r", filedata->Name, (LONG)filedata->Start, FileHandleTable[handle].Pos, bytes);
			#endif

			/*
			**	Copy the block of the file into the specified buffer.
			*/
			Mem_Copy((VOID*)((LONG)filedata->Ptr + FileHandleTable[handle].Start + FileHandleTable[handle].Pos), buf, bytes);
			bytesread = bytes;

			/*
			**	Adjust the file position (manually).
			*/
			FileHandleTable[handle].Pos += bytes;
		}
	}

	/*
	**	Return with the number of bytes read in from the file.
	*/
	CallingDOSInt--;
	return(bytesread);
}


/***************************************************************************
 * WRITE_FILE -- Writes a block of data to a file.                         *
 *                                                                         *
 *    This routine will write a block of data to a file.  The file must    *
 *    have been previously opened with WRITE or READ|WRITE access.         *
 *    Writing cannot occur to a resident or packed file.                   *
 *                                                                         *
 * INPUT:   handle   -- File handle as returned by Open_File.              *
 *                                                                         *
 *          buf      -- Pointer to the buffer that holds the data to be    *
 *                      written out.                                       *
 *                                                                         *
 *          bytes    -- The number of bytes to write out.                  *
 *                                                                         *
 * OUTPUT:  Returns with the actual number of bytes written to the file.   *
 *                                                                         *
 * WARNINGS:   If the value returned from this function is less than the   *
 *             number of bytes requested to be written, then this          *
 *             indicates some kind of error NOT caught by the file I/O     *
 *             system.                                                     *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/13/1991 JLB : Created.                                             *
 *=========================================================================*/
LONG cdecl Write_File(WORD handle, VOID const *buf, ULONG bytes)
{
	WORD					doshandle;		// DOS specific file handle.
	WORD					fileindex;		// FileData table index (if any).
	LONG					byteswritten;	// Accumulated number of bytes written.
	FileDataType	  	*filedata;		// Pointer to the current FileData.

	#if(DEBUGPRINT)
		Mono_Printf("Write_File(%d, %08lx, %ld)\r", handle, buf, bytes);
	#endif

	/*
	**	Check to make sure the file handle is valid.
	*/
	if (!Is_Handle_Valid(handle, WRITING_NON_HANDLE, NULL)) {
		return(NULL);
	}
	doshandle = FileHandleTable[handle].Handle;
	fileindex = FileHandleTable[handle].Index;
	filedata = &FileDataPtr[fileindex];

	/*
	**	Writing to a resident file is an error condition.
	*/
	if (!doshandle) {
		Do_IO_Error(WRITING_RESIDENT, filedata->Name);
		return(NULL);
	}

	CallingDOSInt++;

	/*
	**	Perform a DOS write of the data.  This write is performed in blocks.
	*/
	byteswritten = NULL;

	while (bytes) {
		LONG	outbytes;		// Number bytes written in one block.

		/*
		**	Write out one block of data.
		*/
		outbytes = FILEWRITE(doshandle, (void*)buf, MIN((LONG)bytes, IO_CHUNK_SIZE));

		/*
		**	Reduce the bytes remaining to output counter and adjust the
		**	file position.
		*/
		bytes -= outbytes;
		byteswritten += outbytes;
		FileHandleTable[handle].Pos += outbytes;

		/*
		**	If NO bytes were written out, then this is some kind of unknown
		**	error (possibly disk full?).
		*/
		if (!outbytes) {
			break;
		}

		/*
		**	Possible adjustment to the file's size.
		*/
		if (fileindex != ERROR) {
			filedata->Size = MAX(filedata->Size, FileHandleTable[handle].Pos);
		}

		/*
		**	Adjust the source pointer in anticipation of the next block write.
		*/
		buf = (BYTE*)(((LONG)buf) + outbytes);
	}

	/*
	**	Return with the actual number of bytes written.
	*/
	CallingDOSInt--;
	return (byteswritten);
}


/***************************************************************************
 * SEEK_FILE -- Adjusts the position of the file pointer.                  *
 *                                                                         *
 *    This routine adjusts the position of the file pointer.  Use this     *
 *    to control where the next Read_File or Write_File will occur.        *
 *                                                                         *
 * INPUT:   handle   -- File handle as returned by Open_File.              *
 *                                                                         *
 *          offset   -- Signed offset from indicated starting position.    *
 *                                                                         *
 *          starting -- SEEK_CUR:   Seeks from the current position.       *
 *                      SEEK_SET:   Seeks from the start of the file.      *
 *                      SEEK_END:   Seeks backward from the end.				*
 *                                                                         *
 * OUTPUT:  Returns with the new file position.                            *
 *                                                                         *
 * WARNINGS:   Seeking past the end or before the beginning of the file    *
 *             is not allowed.                                             *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/13/1991 JLB : Created.                                             *
 *=========================================================================*/
ULONG cdecl Seek_File(WORD handle, LONG offset, WORD starting)
{
	WORD					doshandle;	// DOS specific file handle.
	WORD					fileindex;	// FileData index (if any).
	FileDataType	  	*filedata;		// Pointer to the current FileData.

	#if(DEBUGPRINT)
		Mono_Printf("Seek_File(%d, %ld, %d)\r", handle, offset, starting);
	#endif

	/*
	**	Check to make sure that the file handle is valid.
	*/
	if (!Is_Handle_Valid(handle, SEEKING_NON_HANDLE, NULL)) {
		return(NULL);
	}

	CallingDOSInt++;

	fileindex = FileHandleTable[handle].Index;
	doshandle = FileHandleTable[handle].Handle;
	filedata = &FileDataPtr[fileindex];

	if (!doshandle) {

		/*
		**	Resident file seek is merely an adjustment to the position value.
		*/
		switch (starting) {

			/*
			**	Manually position from start of file.
			*/
			case SEEK_SET:
				offset = MAX((long)0, offset);		// Only positive offsets allowed.
				FileHandleTable[handle].Pos = NULL;
				break;

			/*
			**	Position is relative to end of file.
			*/
			case SEEK_END:
				offset = MIN((long)0, offset);		// Only negative offsets allowed.
				FileHandleTable[handle].Pos = filedata->Size;
				break;

			case SEEK_CUR:
				break;

			default:
				Do_IO_Error(SEEKING_BAD_OFFSET, FileHandleTable[handle].Name);
				break;
		}

		/*
		**	Perform the resident file position adjustment.
		*/
		FileHandleTable[handle].Pos += offset;

		FileHandleTable[handle].Pos = MIN(FileHandleTable[handle].Pos,  filedata->Size-1);
		FileHandleTable[handle].Pos = MAX(FileHandleTable[handle].Pos,  (long)0);

	} else {

		/*
		**	Special handling for packed file seeks.
		*/
		if (fileindex != ERROR && (filedata->Flag & FILEF_PACKED)) {
			switch (starting) {
				case SEEK_SET:
					FileHandleTable[handle].Pos = offset;
					break;

				case SEEK_END:
					// Only negative offsets allowed.
					// Do not allow seeking past the beginning.
					offset = MIN(0L, offset);		
					if (-offset > filedata->Size) {
					 	Do_IO_Error(SEEKING_BAD_OFFSET, FileHandleTable[handle].Name);
					}
					FileHandleTable[handle].Pos = filedata->Size + offset;
					break;

				case SEEK_CUR:
					FileHandleTable[handle].Pos += offset;
					if (FileHandleTable[handle].Pos < 0) {
						FileHandleTable[handle].Pos = 0;
					}
					if (FileHandleTable[handle].Pos >= filedata->Size) {
						FileHandleTable[handle].Pos = filedata->Size;
					}
					break;

				default:
					Do_IO_Error(SEEKING_BAD_OFFSET, FileHandleTable[handle].Name);
					break;
			}
			FILESEEK(doshandle, FileHandleTable[handle].Pos+FileHandleTable[handle].Start, SEEK_SET);
			CallingDOSInt--;
			return (FileHandleTable[handle].Pos);
		}
		/*
		**	Perform the straight DOS seek.
		*/
		FileHandleTable[handle].Pos = FILESEEK(doshandle, offset, starting);

		/*
		**	File position does not recognize packed offset.
		*/
		if (fileindex != ERROR) {
			FileHandleTable[handle].Pos -= FileHandleTable[handle].Start;
			//SKB FileHandleTable[handle].Pos -= filedata->Start;
		}
	}

	/*
	**	Return with the current file position.
	*/
	CallingDOSInt--;
	return (FileHandleTable[handle].Pos);
}


/***************************************************************************
 * FILE_EXISTS -- Searches for and FINDS the specified file.               *
 *                                                                         *
 *    This routine will scan the available drives and return when the file *
 *    is accessable.  This routine is used when the programmer MUST be     *
 *    sure of a file's existance before proceeding.  This process is       *
 *    automatically performed on a Open_File with READ access.             *
 *                                                                         *
 * INPUT:   file_name   -- Name of the file to check for.                  *
 *                                                                         *
 * OUTPUT:  Returns the disk number that the file exits on (A=1, B=2, etc) *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/14/1991 JLB : Created.                                             *
 *=========================================================================*/
WORD cdecl File_Exists(BYTE const *file_name)
{
	/*
	**	If the filename is invalid then it errors out.
	*/
	if (!file_name) return(FALSE);
	/*
	**	Continually search for the file (prompting as needed).  Only return
	**	upon success or error function control reasons.
	*/
	while (!Find_File(file_name)) {

		/*
		**	If the file could not be found then request for proper disk.
		*/
		do {
			//struct	find_t ffblk;
			//BYTE		path[MAXPATH];
			
			if (!Do_Open_Error(COULD_NOT_OPEN, file_name)) {
				return(FALSE);
			}
			ibm_setdisk(*DataPath - 'A');

			// Search for the volume ID so that the disk information get read in again.
			//_dos_findfirst("*.*", _A_VOLID, &ffblk);
		} while (CHANGEDIR( DataPath ));
	}
	return (TRUE);
}


/***************************************************************************
 * FILE_SIZE -- Determine the size of the specified file.                  *
 *                                                                         *
 *    This routine will return with the size of the file specified by the  *
 *    file handle passed in.                                               *
 *                                                                         *
 * INPUT:   handle   -- Westwood file handle.                              *
 *                                                                         *
 * OUTPUT:  Returns with the size of the file in bytes.                    *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1991 JLB : Created.                                             *
 *=========================================================================*/
ULONG cdecl File_Size(WORD handle)
{
	FileDataType	  	*filedata;		// Pointer to the current FileData.


	if (FileHandleTable[handle].Index != ERROR) {
		filedata = &FileDataPtr[FileHandleTable[handle].Index];
		
		if (filedata->Size) {
			return(filedata->Size);
		}
	}
	return (filelength(FileHandleTable[handle].Handle));
}


/***************************************************************************
 * IS_HANDLE_VALID -- Determines validity of the specified file handle.    *
 *                                                                         *
 *    Use this routine to determine if a file handle is valid or not.  It  *
 *    checks to see if it falls within legal limits and does in fact       *
 *    reference an open file.  This routine will call the error handler    *
 *    with the specified error number if the handle is not valid.          *
 *                                                                         *
 * INPUT:   handle   -- Handle to check for validity.                      *
 *                                                                         *
 *          error    -- Error number to use when calling the IO_Error      *
 *                      handler.                                           *
 *                                                                         *
 *          name     -- The file name (if known).                          *
 *                                                                         *
 * OUTPUT:  Returns with the file table index, if one exists for this      *
 *          file.                                                          *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/13/1991 JLB : Created.                                             *
 *=========================================================================*/
BOOL cdecl Is_Handle_Valid(WORD handle, FileErrorType error, BYTE const *name)
{
	/*
	**	The handle must be valid or else it is an error.
	*/
	if (handle < 0 || handle >= TABLE_MAX) {
		/*
		**	ERROR: Invalid file handle.
		*/
		Do_IO_Error(error, name);
	}

	/*
	**	An unused file handle causes an error.
	*/
	if (FileHandleTable[handle].Empty) {
		Do_IO_Error(error, name);
	}

	return (TRUE);
}



