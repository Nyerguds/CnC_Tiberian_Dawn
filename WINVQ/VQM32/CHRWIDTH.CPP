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

/****************************************************************************
*
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*---------------------------------------------------------------------------
*
* FILE
*     chrwidth.c
*
* DESCRIPTION
*     Character pixel width.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     June 9, 1995
*
*---------------------------------------------------------------------------
*
* PUBLIC
*     Char_Pixel_Width - Get the pixel width of a character.
*
****************************************************************************/

#include "font.h"


/****************************************************************************
*
* NAME
*     Char_Pixel_Width - Get the pixel width of a character.
*
* SYNOPSIS
*     Width = Char_Pixel_Width(Character)
*
*     long Char_Pixel_Width(char);
*
* FUNCTION
*     Gets the pixel width of the specified character.
*
* INPUTS
*     Character - Character to get the width for.
*
* RESULT
*     Width - Width in pixels.
*
****************************************************************************/

#ifdef __WATCOMC__
long __cdecl __saveregs Char_Pixel_Width(char chr)
#else
#pragma saveregs
long __cdecl Char_Pixel_Width(char chr)
#endif
{
	return (*(FontWidthBlockPtr + chr) + FontXSpacing);
}
