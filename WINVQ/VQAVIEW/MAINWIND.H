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
 *                    File Name : MAINWIND.H                               *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date : Nov 15, 1995                             *
 *                                                                         *
 *                  Last Update : Nov 15, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


//==========================================================================
// Public classes
//==========================================================================

class MainWindowClass {
	public:

		//==========================================================================
		// Public functions
		//==========================================================================

		MainWindowClass( void );
		void Create_Main_Window( InstanceHandle instance_handle );
		WindowHandle Get_Window_Handle( void );
		void Display_Window( void );
		BOOL Update_Windows_Messages( void );
		int Get_Message_Queue_wParam( void );
		InstanceHandle Get_Instance_Handle( void );

	private:

		//==========================================================================
		// Private data
		//==========================================================================

		WindowHandle	main_window_handle;
		InstanceHandle	global_instance_handle;
		MessageQueue	message_queue;

		//==========================================================================
		// Private functions
		//==========================================================================

}; /* VQAClass */


//==========================================================================
// Public data
//==========================================================================

extern MainWindowClass Main_Window;


