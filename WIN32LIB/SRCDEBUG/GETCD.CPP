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
 *                 Project Name : WWLIB												*
 *                                                                         *
 *                    File Name : GETCD.CPP											*
 *                                                                         *
 *                   Programmer : STEVE WETHERILL BASED ON JOE BOSTIC CODE *
 *                                                                         *
 *                   Start Date : 5/13/94												*
 *                                                                         *
 *                  Last Update : June 4, 1994   [SW]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *		GetCDClass::GetCDClass	--	default constructor                       *
 *		GetCDClass::~GetCDClass	--	destructor                                *
 *		GetCDClass::GetCDDrive	--	returns the logical CD drive              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>

#include "wwstd.h"
#include "playcd.h"
#include "wwmem.h"


/***************************************************************************
 * GetCDClass -- default constructor													*
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *       none 																					*
 * OUTPUT:                                                                 *
 *			none                          												*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW   : Created.                                            *
 *   12/4/95    ST   : fixed for Win95                                     *
 *=========================================================================*/

GetCDClass::GetCDClass(VOID)
{
	char	path[]={"a:\\"};

	CDCount = 0;
	CDIndex = 0;

	/*
	** Set all CD drive placeholders to empty
	*/
	memset (CDDrives, NO_CD_DRIVE, MAX_CD_DRIVES);


	for (char i='c' ; i<='z' ; i++){
		path[0]=i;
		if (GetDriveType (path) == DRIVE_CDROM){
			CDDrives[CDCount++] = (int) (i-'a');
		}
	}

	/*
	**	Catch the case when there are NO CD-ROM drives available
	*/
	if (CDCount == 0) {
		for (char i='a' ; i<='b' ; i++){
			path[0]=i;
			if (GetDriveType (path) == DRIVE_CDROM){
				CDDrives[CDCount++] = (int) (i-'a');
			}
		}
	}
}

/***************************************************************************
 * GetCDClass -- destructor                                                *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	none																					*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW: Created.                                               *
 *   12/4/95    ST: fixed for Win95                                        *
 *=========================================================================*/

GetCDClass::~GetCDClass(VOID)
{
//	if(cdDrive_addrp.seg)
//		DPMI_real_free(cdDrive_addrp);		// free up those conventional buffers
}

/* ==================================================================== */

