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
 *                 Project Name : File IO System LIbrary                   *
 *                                                                         *
 *                    File Name : FILEDATA.CPP                             *
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
#include "wwstd.h"
#endif	   

#ifndef _FILE_H
#include "_file.h"
#endif

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/* 
	structure for FileDataType is:

	BYTE *filename:	initialize to actual file name on disk.
	LONG size:			initialize to actual file size on disk.
	BYTE *ptr:			initialize to a 0L below.
	WORD disk:			which floppy disk number (1+) file resides on.
	LONG pos:			initialize to a 0L below.				
	UBYTE priority:	file priorities can be from 0 to 127. (127 = highest)
 							if you want the file to be attempted to be made
							resident at runtime, add 128 to the file priority
							to set the high bit. even though the files
							priority will appear to be 128 to 255, it will
							still remain 0 to 127.
*/	

FileDataType FileData[] = {
	{ 	"",               0L, 		0L, 	0, 0L,	0			}
	/* Must have an empty entry!!! */
};
