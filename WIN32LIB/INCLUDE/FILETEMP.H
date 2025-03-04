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
 *                 Project Name : Temp header for file routines.           *
 *                                                                         *
 *                    File Name : FILETEMP.H                               *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : April 20, 1994                           *
 *                                                                         *
 *                  Last Update : April 20, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef FILETEMP_H
#define FILETEMP_H

/////////////////////////////////////////////////////////////////////
// THIS DOES NOT BELONG HERE.  IT WAS PUT HERE JUST TO GET THE THING
// TO COMPILE.  ONCE THE BUFFER AND PAGE SYSTEMS ARE PUT IN, THESE
// WILL NEED TO BE TAKEN OUT AND MODS MADE TO ANY FUNCTION USING BuffType.
// SKB 4/20/94.



/*=========================================================================*/
/* Defines and such that must go into wwstd.h										*/
/*=========================================================================*/
// Look at FileErrorType below for the IO_Error function.
//extern WORD __cdecl ( __cdecl IO_Error)(FileErrorType error, BYTE const *filename);
VOID __cdecl Prog_End(VOID);
extern WORD Hard_Error_Occured;



//////////////////////// END OF DON'T BELONG //////////////////////////////////

#endif //FILETEMP_H

