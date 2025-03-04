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
;**   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
;***************************************************************************
;*                                                                         *
;*                 Project Name : WWLIB32                                  *
;*                                                                         *
;*                    File Name : SHAPE.ASM                                *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : April 13, 1992                           *
;*                                                                         *
;*                  Last Update : September 14, 1994   [IML]               *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Draw_Shape -- Draws a shape at given buffer coordinates and clips     *
;*   Not_Supported -- Replacement function for Draw_Shape routines not used*
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************* Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT

INCLUDE "shape.inc"

global	C ShapeBuffer		:dword
global	C ShapeBufferSize	:dword
global	C _ShapeBuffer		:dword
global	C _ShapeBufferSize	:dword
global	C Set_Shape_Buffer	:near

DATASEG
label	ShapeBuffer	dword
_ShapeBuffer		dd	0

label	ShapeBufferSize	dword
_ShapeBufferSize	dd	0

CODESEG

;***************************************************************************
;* SET_SHAPE_BUFFER -- Sets the shape buffer to the given pointer          *
;*                                                                         *
;* This routine will set the shape buffer to the given value and make sure *
;* that the system does not try to compress any shapes that will be larger *
;* than the shape buffer.						   *
;*                                                                         *
;* INPUT:	void * - pointer to the shape buffer                       *
;*		int    - size of the buffer which has been passed in	   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:       VOID *Set_Shape_Bufer(void *buffer, int size);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   10/26/1994 PWG : Created.                                             *
;*=========================================================================*
GLOBAL	C Set_Shape_Buffer:NEAR

PROC	Set_Shape_Buffer C near
	USES	eax

	ARG	buff:DWORD
	ARG	size:DWORD

	mov	eax,[size]
	mov	[_ShapeBufferSize],eax

	mov	eax,[buff]
	mov	[_ShapeBuffer],eax
	ret

	ENDP	Set_Shape_Buffer
END

