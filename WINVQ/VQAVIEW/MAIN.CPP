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

/**********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S              ***
 **********************************************************************************************
 *                                                                                            *
 *                 Project Name : VQAVIEW																		*
 *                                                                                            *
 *                    File Name : MAIN.CPP                                                	   *
 *                                                                                            *
 *                   Programmer : Mike Grayford                                               *
 *                                                                                            *
 *                   Start Date : November 14, 1995                                          	*
 *                                                                                            *
 *                  Last Update : November 20, 1995 [MG]                                     	*
 *                                                                                            *
 *--------------------------------------------------------------------------------------------*
 * Functions:                                                                                 *
 *  WinMain 		-- Program entry point                                                      	*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/


//---------------------------------------------------------------------------------------------
//	INCLUDES
//---------------------------------------------------------------------------------------------

#include <windows.h>
#include <windowsx.h>
#include <gbuffer.h>
#include <ddraw.h>
#include <file.h>
#include <wwmem.h>

#include <westwood.h>
#include <main.h>
#include <vidmode.h>
#include <mainwind.h>
#include <monochrm.h>
#include <movies.h>


extern void VQA_Test( char *filename );

//==========================================================================
// Public data
//==========================================================================

GraphicBufferClass *Screen_Buffer = NULL;
int						ScreenWidth = VIDEO_MODE_WIDTH;

BOOL	GameInFocus = TRUE;
void Block_Mouse(GraphicBufferClass*){}
void Unblock_Mouse(GraphicBufferClass*){}


/***********************************************************************************************
 * WinMain -- Program entry point                                                              *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Standard Windows startup parameters                                               *
 *                                                                                             *
 * OUTPUT:   wParam of the message queue                                                       *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/15/95 1:28PM ST : Created                                                             *
 *=============================================================================================*/

int WINAPI WinMain (
	Handle instance_handle,
	Handle prev_instance_handle,
	String command_line_string,
	int show_window_command )
{
	if (!prev_instance_handle){
		//
		// If the program is already running, bail.
		//
		if ( prev_instance_handle ) {
			return( 0 );
		}

		//
		// Create the main window.
		//
		Main_Window.Create_Main_Window( instance_handle );

		//
		// Show the window.
		//
		Main_Window.Display_Window();

		//
		// Create the GraphicBufferClass that will be the screen buffer
		//
		Screen_Buffer = new GraphicBufferClass ( VIDEO_MODE_WIDTH, VIDEO_MODE_HEIGHT, (GBC_Enum)(GBC_VIDEOMEM | GBC_VISIBLE) );

		//
		// Initialize Movie system.
		//
		Initialize_Movie_System();

		if (*command_line_string){
			VQA_Test(command_line_string);
		}else{
			//
			// Windows message loop
			//
			while ( Main_Window.Update_Windows_Messages() ) ;
		}

		//
		// Free the Movie system.
		//
		Free_Movie_System();

		return( Main_Window.Get_Message_Queue_wParam() );
	}else{
		return (-1);
	}

}


