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



#define WIN32
#ifndef _WIN32 // Denzil 6/2/98 Watcom 11.0 complains without this check
#define _WIN32
#endif // _WIN32
#include <windows.h>



extern "C" {
BOOL WINAPI Thipx_ThunkConnect32(LPSTR pszDll16, LPSTR pszDll32, DWORD hIinst, DWORD dwReason);
};




BOOL APIENTRY DllMain(DWORD hInst, DWORD dwReason, DWORD dwReserved)

{
	OutputDebugString("In THIPX32.DLL : DllMain\r\n");
    if (! Thipx_ThunkConnect32("THIPX16.DLL", "THIPX32.DLL", hInst, dwReason)) {
        OutputDebugString("ERROR! 32Bit ThunkConnect32 failed!\r\n");
        return FALSE;
    }
	OutputDebugString("32Bit ThunkConnect32 succeeded.\r\n");
	return (TRUE);
}


BOOL APIENTRY LibMain(DWORD hInst, DWORD dwReason, DWORD dwReserved)
{
	return (DllMain(hInst, dwReason, dwReserved));
}
