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
 *                    File Name : DELAY.C                                  *
 *                                                                         *
 *                   Programmer : Christopher Yates                        *
 *                                                                         *
 *                  Last Update : 27 March, 1991   [CY]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"wwstd.h"
#include <timer.h>

void Delay(int duration)
{
	unsigned long count;
	TimerClass timer(BT_SYSTEM,TRUE);

	while (duration--) {
		count = timer.Time() + 1L;
		while (count >= timer.Time()) {
			;
		}
	}

#if(FALSE)
	while (duration--)
		Wait_Vert_Blank(VertBlank);
#endif
}

#if(FALSE)
void Vsync()
{
	Wait_Vert_Blank(VertBlank);
}
#endif
