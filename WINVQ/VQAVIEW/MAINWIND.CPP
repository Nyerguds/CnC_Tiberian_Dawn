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
 *                 Project Name : VQAVIEW				                       *
 *                                                                         *
 *                    File Name : MAINWIND.CPP                             *
 *                                                                         *
 *                   Programmer : Mike Grayford                         	  *
 *                                                                         *
 *                   Start Date : Nov 15, 1995                             *
 *                                                                         *
 *                  Last Update : Nov 15, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <windows.h>

#include <westwood.h>
#include <mainwind.h>
#include <vidmode.h>
#include <wm.h>
#include <misc.h>
#include <wwlib.h>

//==========================================================================
// Private defines
//==========================================================================

#define APPLICATION_NAME		"VQAVIEW"
#define APPLICATION_TITLE	"VQA Movie Viewer"


//==========================================================================
// Public data
//==========================================================================

MainWindowClass Main_Window;

//==========================================================================
// Private functions
//==========================================================================

long WINAPI Main_Window_Message_Handler(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param );


/***************************************************************************
 * MainWindowClass::MainWindowClass -- Constructor for MainWindowClass	  *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY: See PVCS log                                                   *
 *=========================================================================*/
MainWindowClass::MainWindowClass( void )
{
	// Much ado about nothing.
}


void MainWindowClass::Create_Main_Window( InstanceHandle instance_handle )
{
	WindowClass window_class;

	//
	// Register the window class.
	//
	window_class.style         = CS_OWNDC;
	window_class.lpfnWndProc   = Main_Window_Message_Handler;
	window_class.cbClsExtra    = 0;
	window_class.cbWndExtra    = 0;
	window_class.hInstance     = instance_handle;
	window_class.hIcon         = LoadIcon ( NULL, IDI_APPLICATION );
	window_class.hCursor       = LoadCursor ( NULL, IDC_ARROW );
	window_class.hbrBackground = GetStockObject( BLACK_BRUSH );
	window_class.lpszMenuName  = APPLICATION_NAME;
	window_class.lpszClassName = APPLICATION_NAME;

	RegisterClass ( &window_class );

	//
	// Create our main window
	//
	main_window_handle = CreateWindowEx (
		WS_EX_TOPMOST,					// extended window info
		APPLICATION_NAME,				// window class name
		APPLICATION_TITLE,         // window caption
//		WS_POPUP | WS_MAXIMIZE,    // window style
		WS_OVERLAPPED,					// window style
		0,                         // initial x position
		0,                         // initial y position
		VIDEO_MODE_WIDTH,          // initial width
		VIDEO_MODE_HEIGHT,         // initial height
		NULL,                      // parent window handle
		NULL,                      // window menu handle
		instance_handle,           // program instance handle
		NULL );                    // creation parameters

	MainWindow = main_window_handle;

	global_instance_handle = instance_handle;
}


void MainWindowClass::Display_Window( void )
{
	//
	// Bring up the window, force a paint, and make sure we are the foreground window.
	//
	ShowWindow( main_window_handle, SW_SHOWMAXIMIZED );
	UpdateWindow( main_window_handle );
	SetForegroundWindow( main_window_handle );

	//
	// Via direct draw, set the video mode.
	//
	Set_Video_Mode( main_window_handle, VIDEO_MODE_WIDTH, VIDEO_MODE_HEIGHT, VIDEO_MODE_BITS_PER_PIXEL );

}


BOOL MainWindowClass::Update_Windows_Messages( void )
{
	if ( PeekMessage( &message_queue, NULL, 0, 0, PM_NOREMOVE ) ) {
		if ( GetMessage( &message_queue, NULL, 0, 0 ) ) {
			TranslateMessage( &message_queue );
			DispatchMessage( &message_queue );
		}
		else {
			return( FALSE );
		}
	}

	return( TRUE );
}


int MainWindowClass::Get_Message_Queue_wParam( void )
{
	return( message_queue.wParam );
}


WindowHandle MainWindowClass::Get_Window_Handle( void )
{
	return( main_window_handle );
}


long WINAPI Main_Window_Message_Handler(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param )
{
	switch ( message ) {

		case WM_COMMAND:
			return( WM_Command_Func( window_handle, message, w_param, l_param ) );

		case WM_TIMER:
			break;

		case WM_ACTIVATEAPP:
			WM_ActivateApp_Func( window_handle, message, w_param, l_param );
			break;

		case WM_DESTROY:
			WM_Destroy_Func( window_handle, message, w_param, l_param );
			return( 0 );
	}

	return( DefWindowProc( window_handle, message, w_param, l_param ) );
}


InstanceHandle MainWindowClass::Get_Instance_Handle( void )
{
	return( global_instance_handle );
}


