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
 *                 Project Name : VQAVIEW                                  *
 *                                                                         *
 *                    File Name : GAMETIME.CPP                             *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date :                                          *
 *                                                                         *
 *                  Last Update : Nov 22, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

//==========================================================================
// INCLUDES
//==========================================================================

#include <windows.h>
#include <gametime.h>

//==========================================================================
// PUBLIC DATA
//==========================================================================

GameTimeClass Game_Time;

/***************************************************************************
 * GameTimeClass - Constructor function for GameTimeClass                  *
 *                                                                         *
 * INPUT:	                                                                 *
 *                                                                         *
 * OUTPUT:	                                                              *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
GameTimeClass::GameTimeClass( void )
{
	game_start_time = timeGetTime();
}


/***************************************************************************
 * Get_Time - returns the time in ms elapsed since game was started        *
 *                                                                         *
 * INPUT:	                                                                 *
 *                                                                         *
 * OUTPUT:	                                                              *
 *		unsigned long - time in milliseconds since game was started         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
unsigned long GameTimeClass::Get_Time( void )
{
	unsigned long curr_windows_time;
	unsigned long game_time;

	curr_windows_time = timeGetTime();
	if ( curr_windows_time <= game_start_time ) {
		// Handles the case if the windows time wraps while playing the game.
		game_time = MAX_ULONG - game_start_time + curr_windows_time;
	}
	else {
   		game_time = curr_windows_time - game_start_time;
	}
	return( game_time );
}


/***************************************************************************
 * Get_Game_Time - returns the time in ms elapsed since game was started   *
 *                                                                         *
 * INPUT:	                                                                 *
 *                                                                         *
 * OUTPUT:	                                                              *
 *		unsigned long - time in milliseconds since game was started         *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
unsigned long Get_Game_Time( void )
{
	return( Game_Time.Get_Time() );
}

