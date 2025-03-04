;
;	Command & Conquer Red Alert(tm)
;	Copyright 2025 Electronic Arts Inc.
;
;	This program is free software: you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation, either version 3 of the License, or
;	(at your option) any later version.
;
;	This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

;***************************************************************************
;**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Get the data selector                    *
;*                                                                         *
;*                    File Name : FGETDS.ASM                               *
;*                                                                         *
;*                   Programmer : Jeff Wilson                              *
;*                                                                         *
;*                   Start Date : March 28, 1994                           *
;*                                                                         *
;*                  Last Update : March 28, 1994   []                      *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   GetDs -- Return the current Data selector.                            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT


GLOBAL             GetDs          :NEAR
		    
;============================================================================
CODESEG

;***************************************************************************
;* GETDS -- Return the current Data selector.                              *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT: NONE                                                             *
;*                                                                         *
;* OUTPUT: UWORD        selector of the default data segment               *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/28/1994  jaw: Created.                                             *
;*=========================================================================*

PROC GetDs 	C near 
     
	xor	eax,eax
	mov	ax,ds
	ret
;====================
ENDP GetDs	


END




