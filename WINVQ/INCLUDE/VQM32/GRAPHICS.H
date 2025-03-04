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

#ifndef VQMGRAPHICS_H
#define VQMGRAPHICS_H
/****************************************************************************
*
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     graphics.h
*
* DESCRIPTION
*     Graphic rendering and manipulation definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     April 27, 1995
*
****************************************************************************/

/* Prototypes */

#ifdef __cplusplus
extern "C" {
#endif

void __cdecl Eor_Region(long sx, long sy, long dx, long dy, long color);
void __cdecl Fill_Rect(long x1, long y1, long x2, long y2, long color);

#ifdef __cplusplus
}
#endif

#endif /* VQMGRAPHICS_H */

