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
;*                 Project Name : Calculate size of an MCGA region	   *
;*                                                                         *
;*                    File Name : REGIONSZ.ASM                             *
;*                                                                         *
;*                   Programmer : Barry W. Green			   *
;*                                                                         *
;*                   Start Date : March 1, 1995				   *
;*                                                                         *
;*                  Last Update : March 1, 1995  [BWG]                     *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   VVPC::Size_Of_Region - calculate graphic buffer region size           *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

GLOBAL	Buffer_Size_Of_Region	: NEAR

CODESEG

;***************************************************************************
;* VVPC::Size_Of_Region - calculate buffer region size			   *
;*                                                                         *
;* INPUT:	DWORD the width of the region				   *
;*                                                                         *
;*		DWORD the height of the region				   *
;*                                                                         *
;* OUTPUT:      calculated size of the region (size = width * height)      *
;*                                                                         *
;*									   *
;* HISTORY:                                                                *
;*   03/01/1995 BWG : Created.                                             *
;*=========================================================================*
	PROC	Buffer_Size_Of_Region C near
	USES	ebx,ecx,edx

	ARG    	this_object:DWORD			; this is a member function
	ARG	region_width:DWORD			; width of region
	ARG	region_height:DWORD			; height of region

	;*===================================================================
	; Get the viewport information
	;*===================================================================
	mov	ebx,[this_object]				; get a pointer to viewport
	xor	eax,eax
	mov	ecx,[(GraphicViewPort ebx).GVPHeight]	; ecx = height of viewport
	mov	edx,[(GraphicViewPort ebx).GVPWidth]	; edx = width of viewport

	;*===================================================================
	; Verify that the width is legal
	;*===================================================================
	mov	eax,[region_width]				; find the width
	cmp	eax,edx					; is it too wide?
	jb	short ??wok				; if not, leave it alone
	mov	eax,edx					; otherwise clip it

	;*===================================================================
	; Verify that the height is ok
	;*===================================================================
??wok:	mov	ebx,[region_height]			; get the height
	cmp	ebx,ecx					; is it too tall?
	jb	??hok					; if not, leave it alone
	mov	ebx,ecx					; otherwise clip it

	;*===================================================================
	; Now multiply 'em to calculate the size of the region
	;*===================================================================
??hok:	mul	ebx					; size = w * h

	ret
	ENDP	Buffer_Size_Of_Region

	END