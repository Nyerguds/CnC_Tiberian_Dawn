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

/* $Header: g:/library/wwlib32/misc/rcs/findargv.cpp 1.2 1994/04/22 10:29:28 scott_bowen Exp $ */
/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : findargv 								*
 *                                                                         *
 *                    File Name : findargv.C                               *
 *                                                                         *
 *                   Programmer : Jeff Wilson								*
 *                                                                         *
 *                   Start Date : January 14, 1993                         *
 *                                                                         *
 *                  Last Update : May 20, 1993   [PWG]                     *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Find_Argv -- Checks to see if string is in arguement              		*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#include "wwstd.h"
#include <dos.h>
#include <stdio.h>
#include <string.h>
#include <process.h>




/***************************************************************************
 * Find_Argv -- Checks to see if string is in arguement                		*
 *                                                                         *
 * INPUT: char *str - string to search for.                                *
 *                                                                         *
 * OUTPUT: NULL if not found else pointer to string.                       *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   01/14/1993  SB : Created.                                             *
 *=========================================================================*/

//static char command [ 256 ] ;
#pragma on (argsused)
char * __cdecl Find_Argv(char const)
{
	return (NULL);


#ifdef NOT_FOR_WIN95
char * __cdecl Find_Argv(char const *str)
{
	char   * ptr ;
	static   startup_flag = 0 ;

	if ( ! startup_flag )
	{
	  startup_flag = 1 ;
	  getcmd ( command )	;
	}

	if ( ! strlen(str) ) return NULL ;
	return strstr ( command , str ) ;
#endif
}






