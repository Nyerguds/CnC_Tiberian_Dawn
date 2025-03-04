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

/***************************************************************************
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Memory system.                           *
 *                                                                         *
 *                    File Name : PRIOINIT.CPP                             *
 *                                                                         *
 *                   Programmer : Ian M. Leslie                            *
 *                                                                         *
 *                   Start Date : August 9, 1993                           *
 *                                                                         *
 *                  Last Update : August 9, 1994   [IML]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   INIT_PRIORITY_SYSTEM -- 	Sets the buffer addresses for the priority   *
 *   									system.													*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "shape.h"


/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/***************************************************************************
 * Init_Priority_System -- set the buffer addresses for the priority		   *
 *   								system.                       						*
 *                                                                         *
 * INPUT:																						*
 *		mask - pointer	to priority buffer class										*
 *		back - pointer to background buffer class										*
 *                                                                         *
 * OUTPUT:																						*
 *		none																						*
 *                                                                         *
 * HISTORY:                                                                *
 *   08/09/1994 IML : Created.															*															
 *=========================================================================*/

VOID cdecl Init_Priority_System (GraphicBufferClass *mask,
											GraphicBufferClass *back)
{
 MaskPage = mask->Get_Buffer();
 BackGroundPage = back->Get_Buffer();
}


/************************** end of prioinit.cpp ****************************/
