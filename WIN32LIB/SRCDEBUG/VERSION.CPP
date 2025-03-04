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
 *                 Project Name : LIBRARY                                  *
 *                                                                         *
 *                    File Name : VERSION.C                                *
 *                                                                         *
 *                   Programmer : Christopher Yates                        *
 *                                                                         *
 *                  Last Update : July 26, 1991   [JLB]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Version -- Returns with current library version text.                 *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "wwstd.h"



PRIVATE char *version = "Westwood Studios - 32 Bit Library Version "
	__DATE__
	"\r\n";

/***************************************************************************
 * VERSION -- Returns with current library version text.                   *
 *                                                                         *
 *    Use this routine to determine the current library version.  The      *
 *    version text contains the date that it was created.                  *
 *                                                                         *
 * INPUT:   none                                                           *
 *                                                                         *
 * OUTPUT:  Returns pointer to version text.                               *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/26/1991 JLB : Created.                                             *
 *=========================================================================*/
char * __cdecl Version(void)
{
	return(version);
}
