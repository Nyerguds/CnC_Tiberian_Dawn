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

extern "C"{
	extern BOOL FAR __pascal ASM_IPX_Initialise(void);
	extern BOOL FAR __pascal ASM_IPX_Uninitialise(void);
}


extern "C"{
	BOOL FAR __pascal _export IPX_Initialise(int);
	void FAR __pascal _export IPX_Uninitialise(void);
}



int CALLBACK LibMain (HANDLE, WORD, WORD, LPSTR)
{
	return (1);
}



BOOL FAR __pascal _export IPX_Initialise(int)
{

	return (ASM_IPX_Initialise());

}



void FAR __pascal _export IPX_Uninitialise(void)
{

	ASM_IPX_Uninitialise();

}




