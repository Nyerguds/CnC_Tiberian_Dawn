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

#ifndef VQMMONO_H
#define VQMMONO_H
/****************************************************************************
*
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     mono.h
*
* DESCRIPTION
*     Mono screen definitions. (32-Bit protected mode)
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     Feburary 8, 1995
*
****************************************************************************/

/* Prototypes */

#ifdef __cplusplus
extern "C" {
#endif

void __cdecl Mono_Enable(void);
void __cdecl Mono_Disable(void);
void __cdecl Mono_Set_Cursor(long x, long y);
void __cdecl Mono_Clear_Screen(void);
void __cdecl Mono_Scroll(long lines);
void __cdecl Mono_Put_Char(long character, long attrib);
void __cdecl Mono_Draw_Rect(long x, long y, long w, long h, long attrib,
		long thick);

void __cdecl Mono_Text_Print(void const *text, long x, long y, long attrib);
void __cdecl Mono_Print(void const *text);
short __cdecl Mono_View_Page(long page);
short __cdecl Mono_X(void);
short __cdecl Mono_Y(void);

#ifdef __cplusplus
}
#endif

#endif /* VQMMONO_H */
