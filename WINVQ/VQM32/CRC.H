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

#ifndef VQMCRC_H
#define VQMCRC_H
/****************************************************************************
*
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     CRC.h
*
* DESCRIPTION
*     CRC calculation definitions.
*
* PROGRAMMER
*     Joe L. Bostic
*
* DATE
*     January 26, 1995
*
****************************************************************************/

#ifdef __cplusplus
extern "C" {
#endif

long __cdecl Calculate_CRC(void const *buffer, long length);

#ifdef __cplusplus
}
#endif

#endif /* VQMCRC_H */
