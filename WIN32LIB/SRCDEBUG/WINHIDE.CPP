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

/* $Header: g:/library/source/rcs/./winhide.c 1.10 1994/05/20 15:35:50 joe_bostic Exp $ */
/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Dune                                     *
 *                                                                         *
 *                    File Name : WINHIDE.C                                *
 *                                                                         *
 *                   Programmer : Joe L. Bostic                            *
 *                                                                         *
 *                   Start Date : May 30, 1991                             *
 *                                                                         *
 *                  Last Update : August 16, 1991   [JLB]                  *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Window_Hide_Mouse -- Hides the mouse when it enters a window.         *
 *   Window_Show_Mouse -- Shows the mouse after Window_Hide_Mouse hides it.*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	<wwstd.h>
#include	<keyboard.h>
#include "ww_win.h"


#if(IBM)
/***************************************************************************
 * WINDOW_HIDE_MOUSE -- Hides the mouse when it enters a window.           *
 *                                                                         *
 *    This is an intelligent form of Conditional_Hide_Mouse().  It will    *
 *    hide the mouse if it enters the specified window (see the            *
 *    WindowList global).                                                  *
 *                                                                         *
 * INPUT:   window   - Window number.                                      *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   Just like Conditional_Hide_Mouse(), this function is NOT    *
 *             nestable.                                                   *
 *                                                                         *
 * HISTORY:                                                                *
 *   04/26/1991 JLB : Created.                                             *
 *=========================================================================*/
void Window_Hide_Mouse(int window)
{
	int	x,y,w,h;

	x = WindowList[window][WINDOWX]<<3;
	y = WindowList[window][WINDOWY];
	w = WindowList[window][WINDOWWIDTH]<<3;
	h = WindowList[window][WINDOWHEIGHT];
//	Conditional_Hide_Mouse(x,y,x+w-1,y+h-1);
}


/***************************************************************************
 * WINDOW_SHOW_MOUSE -- Shows the mouse after Window_Hide_Mouse hides it.  *
 *                                                                         *
 *    This routines will show the mouse after Window_Hide_Mouse has hidden *
 *    it.                                                                  *
 *                                                                         *
 * INPUT:      none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/22/1991 JLB : Created.                                             *
 *=========================================================================*/
void Window_Show_Mouse(void)
{
//	Conditional_Show_Mouse();
}
#endif



