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
 *                    File Name : INITDLAY.C                               *
 *                                                                         *
 *                   Programmer : Barry Green                              *
 *                                                                         *
 *                  Last Update : August 3, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Init_Delay -- I am not sure                                           *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "wwstd.h"
#include "timer.h"
#include "video.h"
		   	 
BOOL VertBlank;

/***************************************************************************
 * INIT_DELAY -- I am not sure                                             *
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
VOID Init_Delay(VOID)
{	  
	WORD nz, nnz;

	nz = nnz = 0;

	CountDown.Set(15, TRUE); // set to  1/4 second and start it
	
	do {
		if (Get_Vert_Blank())
			nnz++;
		else
			nz++;
	} while (CountDown.Time());

	VertBlank = (nnz > nz);
}
