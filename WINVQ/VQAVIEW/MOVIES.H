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
 *                    File Name : VQ.CPP                                   *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date :                                          *
 *                                                                         *
 *                  Last Update : May 31, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Choose_VQA - Brings up choice of VQA files.									  *
 *   Draw_To_Video_Callback -- callback after draw VQA frame to video      *
 *   Draw_To_Buffer_Callback -- callback after draw VQA frame to buffer    *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


//==========================================================================
// PUBLIC FUNCTIONS
//==========================================================================

extern int Initialize_Movie_System( void );
extern void Free_Movie_System( void );
extern void Choose_Movie( WindowHandle window_handle );
extern long Draw_To_Video_Callback( unsigned char *buffer, long frame_number );
extern long Draw_To_Buffer_Callback( unsigned char *buffer, long frame_number );
extern void Create_Palette_Interpolation_Table( void );

//==========================================================================
// PRIVATE DEFINES
//==========================================================================

#define DRAW_TO_VIDEO		FALSE


//==========================================================================
// PUBLIC FUNCTIONS
//==========================================================================

#if( DRAW_TO_VIDEO )

#define MOVIE_WIDTH	640
#define MOVIE_HEIGHT	480

#else

#define MOVIE_WIDTH	320
#define MOVIE_HEIGHT	200

#endif

