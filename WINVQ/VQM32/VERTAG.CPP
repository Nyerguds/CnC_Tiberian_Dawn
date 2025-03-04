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
*       C O N F I D E N T I A L  --  W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* PROJECT
*     VQMisc32 library.
*
* FILE
*     vertag.c (32-Bit protected mode)
*
* DESCRIPTION
*     Embedded version string. This string is prefixed with a tag ("$VER$")
*     which can be search for to find this string.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*      
* DATE
*     Febuary 8, 1995
*
****************************************************************************/

#ifdef __WATCOMC__
#define DEVNAME "Watcom/4GW"
#else
#define DEVNAME "Borland/TNT"
#endif

char VerTag[] = {"$VER$VQM32 2.12 "DEVNAME" ("__DATE__" "__TIME__")"};
