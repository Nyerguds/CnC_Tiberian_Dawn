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
 **   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : wwlib32                                  *
 *                                                                         *
 *                    File Name : FILESTUB.CPP                             *
 *                                                                         *
 *                   Programmer : Bill Randolph                            *
 *                                                                         *
 *                   Start Date : May 3, 1994                              *
 *                                                                         *
 *                  Last Update : May 3, 1994   [BR]                       *
 *                                                                         *
 * This module is a temorary stub that contains IO_Error.						*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
#include "wwstd.h"
#include "file.h"

WORD Text_IO_Error(FileErrorType, BYTE const *){return FALSE;}
WORD (*IO_Error)(FileErrorType, BYTE const *)   = Text_IO_Error;

/************************* End of filestub.cpp *****************************/
