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
 *                    File Name : GAMETIME.H                               *
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
// PUBLIC FUNCTIONS
//==========================================================================

extern unsigned long Get_Game_Time();

//==========================================================================
// PUBLIC DEFINES
//==========================================================================

#define MAX_ULONG				0xFFFFFFFF

//==========================================================================
// CLASSES
//==========================================================================

class GameTimeClass {
	private:
		unsigned long game_start_time;

	public:
		GameTimeClass( void );
		unsigned long Get_Time( void );

}; /* VQAClass */


//==========================================================================
// PUBLIC DATA
//==========================================================================

extern GameTimeClass Game_Time;


