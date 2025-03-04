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
 **   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood Library                         *
 *                                                                         *
 *                    File Name : MONOPRNT.C                               *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : October 12, 1993                         *
 *                                                                         *
 *                  Last Update : November 2, 1993   [JLB]                 *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Mono_Printf -- Prints formated text to the monochrome screen.         *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	<stdarg.h>
#include	<string.h>
#include	<stdio.h>
#include "mono.h"

/***************************************************************************
 * Mono_Printf -- Prints formated text to the monochrome screen.           *
 *                                                                         *
 *    This routine is used to print formatted text (similar to printf) to  *
 *    the monochrome screen.                                               *
 *                                                                         *
 * INPUT:   string   -- The string that is to be printed.                  *
 *                                                                         *
 *          ...      -- Any optional parameters that the string requires   *
 *                      to format properly.                                *
 *                                                                         *
 * OUTPUT:  Returns with the length of the string that it printed to the   *
 *          monochrome screen.                                             *
 *                                                                         *
 * WARNINGS:   The total length of the formatted string must not exceed    *
 *             255 bytes.                                                  *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/02/1993 JLB : Created.                                             *
 *=========================================================================*/
int Mono_Printf(char const *string, ...)
{
	va_list	va;
	char		buffer[256];

	if (!MonoEnabled) return(0);
		
	va_start(va, string);

	vsprintf(buffer, string, va);
	Mono_Print(buffer);

	va_end(va);
	return(strlen(buffer));
}
