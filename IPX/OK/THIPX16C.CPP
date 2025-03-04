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



#include <windows.h>

extern "C" {
	BOOL FAR PASCAL Thipx_ThunkConnect16_(LPSTR pszDll16, LPSTR pszDll32, WORD  hInst, DWORD dwReason);
}

int CALLBACK LibMain (HANDLE, WORD, WORD, LPSTR)
{
	return (1);
}


extern "C" {
	BOOL FAR PASCAL DllEntryPoint_ (DWORD dwReason, WORD hInst, WORD, WORD, DWORD, WORD);
}


BOOL FAR PASCAL DllEntryPoint_ (DWORD dwReason, WORD hInst, WORD, WORD, DWORD, WORD)
{
	OutputDebugString("In 16bit DLL entry point. Calling Thipx_ThunkConnect16\r\n");

	if (!Thipx_ThunkConnect16_("THIPX16.DLL", "THIPX32.DLL", hInst, dwReason)){
        OutputDebugString("In 16bit DllEntryPoint: thkThunkConnect16 ret FALSE\r\n");
        return FALSE;
    }

    OutputDebugString("In 16bit DllEntryPoint: thkThunkConnect16 ret TRUE\r\n");
    return TRUE;
}


