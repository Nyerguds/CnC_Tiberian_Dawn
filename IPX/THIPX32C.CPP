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
 *   'C' code for the 32 bit IPX library. This library 'thunks' down to a 16bit .dll           *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *  DllMain -- called each time a new app requests use of the .dll                             *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#define WIN32
#ifndef _WIN32 // Denzil 6/2/98 Watcom 11.0 complains without this check
#define _WIN32
#endif // _WIN32
#include <windows.h>


extern "C" {
	BOOL WINAPI Thipx_ThunkConnect32(LPSTR pszDll16, LPSTR pszDll32, DWORD hIinst, DWORD dwReason);
};



/***********************************************************************************************
 * DllMain -- called every time a new app requests use of the .dll                             *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    usual windoze junk                                                                *
 *                                                                                             *
 * OUTPUT:   true                                                                              *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/29/96 10:55AM ST : Created                                                             *
 *=============================================================================================*/
BOOL APIENTRY DllMain(DWORD hInst, DWORD dwReason, DWORD dwReserved)

{
    if (! Thipx_ThunkConnect32("THIPX16.DLL", "THIPX32.DLL", hInst, dwReason)) {
        return FALSE;
    }
	return (TRUE);
}


/***********************************************************************************************
 * LibMain -- This just calls DllMain. Watcom erroneously links this in as the entry point!    *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/29/96 10:56AM ST : Created                                                             *
 *=============================================================================================*/
BOOL APIENTRY LibMain(DWORD hInst, DWORD dwReason, DWORD dwReserved)
{
	return (DllMain(hInst, dwReason, dwReserved));
}
