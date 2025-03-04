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
*----------------------------------------------------------------------------
*
* PROJECT
*     VQA player library. (32-Bit protected mode)
*
* FILE
*     vertag.c
*
* DESCRIPTION
*     Version Tag
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     February 23, 1995
*
****************************************************************************/

#include "vqaplayp.h"

#ifdef __WATCOMC__
#define DEVNAME "Watcom/4GW"
#else
#define DEVNAME "Borland/TNT"
#endif

char VerTag[] = {"$VER$" VQA_IDSTRING" "DEVNAME" ("VQA_DATE")"};
char ReqTag[] = {"$REQ$" VQA_REQUIRES};

