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
 *                    File Name : WM.CPP                                   *
 *                                                                         *
 *                   Programmer : Mike Grayford                            *
 *                                                                         *
 *                   Start Date : November 20, 1995                        *
 *                                                                         *
 *                  Last Update : Nov 20, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

//==========================================================================
// INCLUDES
//==========================================================================

#include <windows.h>

#include <westwood.h>
#include <wm.h>
#include <gbuffer.h>
#include <main.h>
#include <mainwind.h>
#include <menus.rh>

#include <movies.h>
#include <vq.h>


//==========================================================================
// PUBLIC FUNCTIONS
//==========================================================================

void Menu_Exit_Game( void );


/***************************************************************************
 * WM_COMMAND_FUNC -- Handles all main window commands                     *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: IDOK or IDCANCEL                                                *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY:                                                                *
 *    11/20/95 MG : Created                                                *
 *=========================================================================*/
long WM_Command_Func(
	WindowHandle window_handle,
	unsigned int message,
	WPARAM w_param,
	LPARAM l_param )
{
	switch( w_param ) {
		case MENU_EXIT:
			Menu_Exit_Game();
			break;

		case MENU_OPEN:
			Choose_Movie( Main_Window.Get_Window_Handle() );
			break;

		case MENU_SET_MOVIE_FRAME_RATE:
			Set_Movie_Frame_Rate();
			break;

		default:
			break;
	}

	return( 0 );
}


/***************************************************************************
 * WM_SYS_COMMAND_FUNC -- Handles all system menu commands                 *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: IDOK or IDCANCEL                                                *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
#pragma argsused
long WM_Sys_Command_Func(
	WindowHandle window_handle,
	unsigned int message,
	WPARAM w_param,
	LPARAM l_param )
{
	switch( w_param & 0xfff0 ) {
		case SC_CLOSE:
			break;

		case SC_MINIMIZE:
			break;

		case SC_MAXIMIZE:
		case SC_RESTORE:
			break;

		case SC_KEYMENU:
		case SC_MOUSEMENU:
         break;

		default:
			break;
	}

	return( DefWindowProc( window_handle, message, w_param, l_param ) );
}


/***************************************************************************
 * WM_PAINT_FUNC -- Code that is executed when WM_PAINT is sent            *
 *                                                                         *
 * INPUT: standard windows dialog command parameter passing                *
 *                                                                         *
 * OUTPUT: unused                                                          *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
#pragma argsused
long WM_Paint_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param )
{
	return( 0 );
}


/***************************************************************************
 * WM_DESTROY_FUNC -- Handles when a WM_DESTROY hits the main window       *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: unused                                                          *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
long WM_Destroy_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param )
{
	if ( Screen_Buffer ) {
		delete( Screen_Buffer );
	}

	PostQuitMessage( w_param );

	return( 0L );
}


/***************************************************************************
 * WM_MOUSE_BUTTON_FUNC -- Handles when a MOUSE button command comes in    *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: unused                                                          *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
long WM_Mouse_Button_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param )
{
	int x_pix;
	int y_pix;

	x_pix = LOWORD( l_param );
	y_pix = HIWORD( l_param );

	switch ( message ) {
		case WM_LBUTTONDOWN:
		case WM_MBUTTONDOWN:
		case WM_RBUTTONDOWN:
			break;

		default:
			break;
	}
	return( 0 );
}



/***************************************************************************
 * WM_ACTIVATEAPP_FUNC -- Handles WM_ACTIVATEAPP                           *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: unused                                                          *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
long WM_ActivateApp_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param )
{
	return( 0 );
}



void Menu_Exit_Game( void )
{
	PostMessage( Main_Window.Get_Window_Handle(), WM_CLOSE, 0, 0L );
}


