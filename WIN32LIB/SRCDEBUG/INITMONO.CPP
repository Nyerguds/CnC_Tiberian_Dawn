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
 *                 Project Name : Initialize mono                          *
 *                                                                         *
 *                    File Name : INITMONO.CPP                             *
 *                                                                         *
 *                   Programmer : Jeff Wilson                              *
 *                                                                         *
 *                   Start Date : March 28, 1994                           *
 *                                                                         *
 *                  Last Update : September 8, 1994   [IML]                *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef WWSTD_H
#include "wwstd.h"
#endif	   

#ifndef MONO_H
#include "mono.h"
#endif

#ifndef DESCMGMT_H
#include "descmgmt.h"
#endif

/***************************************************************************
 * INITIALIZE_MONO_SCREEN -- Initializes the Mono display data             *
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
 *   01/21/1994  jaw: Created.                                             *
 *========================================================================*/
				   
int Initialize_Mono_Screen(void)
{							 
	// get a valid selector to mono screen.
//	Map_Segment_To_Address(0x0b0000UL, 0x8000UL);

	MonoScreen = 0xb0000	;

	return (int)0;
}			



