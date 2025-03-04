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

/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer 95                                         *
 *                                                                                             *
 *                    File Name : THIPX16C.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 1/15/96                                                      *
 *                                                                                             *
 *                  Last Update : January 29thth 1996 [ST]                                     *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *                                                                                             *
 *   'C' code for the 16 bit IPX library. This library is 'thunked' down to from a 32bit       *
 *  .dll.                                                                                      *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *  LibMain -- library entry point                                                             *
 *  DllEntryPoint -- called each time a new app requests use of the .dll                       *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#include <windows.h>


extern "C" {
	BOOL FAR PASCAL Thipx_ThunkConnect16_(LPSTR pszDll16, LPSTR pszDll32, WORD  hInst, DWORD dwReason);
	BOOL FAR PASCAL DllEntryPoint_ (DWORD dwReason, WORD hInst, WORD, WORD, DWORD, WORD);
}


/***********************************************************************************************
 * LibMain -- library entry point                                                              *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    the usual windows rubbish                                                         *
 *                                                                                             *
 * OUTPUT:   true                                                                              *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/29/96 10:45AM ST : Created                                                             *
 *=============================================================================================*/
int CALLBACK LibMain (HANDLE, WORD, WORD, LPSTR)
{
	return (1);
}



/***********************************************************************************************
 * DllEntryPoint -- called each time a new app requests use of the .dll                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    windows junk                                                                      *
 *                                                                                             *
 * OUTPUT:   true                                                                              *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/29/96 10:45AM ST : Created                                                             *
 *=============================================================================================*/
BOOL FAR PASCAL DllEntryPoint_ (DWORD dwReason, WORD hInst, WORD, WORD, DWORD, WORD)
{
	if (!Thipx_ThunkConnect16_("THIPX16.DLL", "THIPX32.DLL", hInst, dwReason)){
        return FALSE;
    }
    return TRUE;
}


