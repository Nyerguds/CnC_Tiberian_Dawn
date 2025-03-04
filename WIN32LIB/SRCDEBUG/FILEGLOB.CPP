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
 *                 Project Name : FILEIO Library                           *
 *                                                                         *
 *                    File Name : FILEGLOB.C                               *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : April 11, 1994                           *
 *                                                                         *
 *                  Last Update : April 11, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef WWSTD_H
#include <wwstd.h>
#endif	   

#ifndef FILE_H
#include "_file.h"
#endif

#include <process.h>

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/* Global varaiables */
BYTE ExecPath[XMAXPATH + 1];
BYTE DataPath[XMAXPATH + 1];
BYTE StartPath[XMAXPATH + 1];
BOOL UseCD;

/* File System only Global varaiables */
BYTE CallingDOSInt;									// Indicate we are performing a DOS function
BYTE MaxDevice,DefaultDrive;						
BYTE MultiDriveSearch = TRUE;						// Multiple drive search flag
FileDataType *FileDataPtr = NULL;
FileHandleType FileHandleTable[TABLE_MAX];
UWORD NumFiles;										// Number of files, except PAK, in file table.
UWORD NumPAKFiles;									// Number of PAK files in filetable.
VOID *FileCacheHeap = NULL;						// Pointer to the cache in memory.
WORD DiskNumber;										// Where file was found (-1 == current directory).
WORD MaxDirNum = 0;


WORD (*Open_Error)(FileErrorType, BYTE const *) = NULL;
