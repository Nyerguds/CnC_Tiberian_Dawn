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
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : WWLIB32 library source                   *
 *                                                                         *
 *                    File Name : EXIT.CPP                                 *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : August 3, 1994                           *
 *                                                                         *
 *                  Last Update : August 3, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Exit -- Exit routine with message.                                    *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "misc.h"

#include <stdio.h>

#include <stdlib.h>
#include <stdarg.h>
#include <time.h>




/***************************************************************************
 * EXIT -- Exit routine with message.                                      *
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
 *   08/03/1994 SKB : Created.                                             *
 *=========================================================================*/
void __cdecl Exit(INT errorval, const char *message, ...)
{
	va_list		argptr;
	char		errstring[256];

	Prog_End();

	if (message && *message) {
		va_start (argptr, message);
		vsprintf ((char *)errstring, (const char *)message, argptr);
		va_end (argptr);
		printf(errstring);
	}

	::exit(errorval);

}

void randomize	( void )
{
  srand ( time ( NULL ) ) ;
}

#if(0)
unsigned long	random ( unsigned long mod )
{
  return rand () * mod / RAND_MAX ;
}
#endif
