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
 *                    File Name : WM.H                                     *
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
// Public functions
//==========================================================================

long WM_Command_Func(
	WindowHandle window_handle,
	unsigned int message,
	WPARAM w_param,
	LPARAM l_param );

long WM_Sys_Command_Func(
	WindowHandle window_handle,
	unsigned int message,
	WPARAM w_param,
	LPARAM l_param );

long WM_Paint_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param );

long WM_Mouse_Button_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param );

long WM_ActivateApp_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param );

long WM_Destroy_Func(
	WindowHandle window_handle,
	unsigned int message,
	unsigned int w_param,
	long l_param );


