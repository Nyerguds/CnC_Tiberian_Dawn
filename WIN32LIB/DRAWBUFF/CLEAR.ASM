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
;*                 Project Name : Clear the Full Graphics Buffer	   *
;*                                                                         *
;*                    File Name : CLEAR.ASM                                *
;*                                                                         *
;*                   Programmer : Phil Gorrow				   *
;*                                                                         *
;*                   Start Date : June 7, 1994				   *
;*                                                                         *
;*                  Last Update : August 23, 1994   [SKB]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   GVPC::Clear -- Clears a virtual viewport instance                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

CODESEG

;***************************************************************************
;* VVPC::CLEAR -- Clears a virtual viewport instance                       *
;*                                                                         *
;* INPUT:	UBYTE the color (optional) to clear the view port to	   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* NOTE:	This function is optimized to handle viewport with no XAdd *
;*		value.  It also handles DWORD aligning the destination	   *
;*		when speed can be gained by doing it.			   *
;* HISTORY:                                                                *
;*   06/07/1994 PWG : Created.                                             *
;*   08/23/1994 SKB : Clear the direction flag to always go forward.       *
;*=========================================================================*
	PROC	Buffer_Clear C near
	USES	eax,ebx,ecx,edx,esi,edi

	ARG    	this_object:DWORD			; this is a member function
	ARG    	color:BYTE				; what color should we clear to

	cld 		 				; always go forward

	mov	ebx,[this_object]			; get a pointer to viewport
	mov	edi,[(GraphicViewPort ebx).GVPOffset]	; get the correct offset
	mov	edx,[(GraphicViewPort ebx).GVPHeight]	; ecx = height of viewport
	mov	esi,[(GraphicViewPort ebx).GVPWidth]	; edx = width of viewport
	push	[dword (GraphicViewPort ebx).GVPPitch]	; extra pitch of direct draw surface
	mov	ebx,[(GraphicViewPort ebx).GVPXAdd]	; esi = add for each line
	add	ebx,[esp]				; Yes, I know its nasty but
	add	esp,4					;      it works!

	;*===================================================================
	; Convert the color byte to a DWORD for fast storing
	;*===================================================================
	mov	al,[color]				; get color to clear to
	mov	ah,al					; extend across WORD
	mov	ecx,eax					; extend across DWORD in
	shl	eax,16					;   several steps
	mov	ax,cx

	;*===================================================================
	; Find out if we should bother to align the row.
	;*===================================================================

	cmp	esi , OPTIMAL_BYTE_COPY			; is it worth aligning them?
	jl	??byte_by_byte				;   if not then skip

	;*===================================================================
	; Figure out the alignment offset if there is any
	;*===================================================================
	push	ebx
??dword_aligned_loop:
       mov	ecx , edi
       mov	ebx , esi
       neg	ecx
       and	ecx , 3
       sub	ebx , ecx
       rep	stosb
       mov	ecx , ebx
       shr	ecx , 2
       rep	stosd
       mov	ecx , ebx
       and	ecx , 3
       rep	stosb
       add	edi , [ esp ]
       dec	edx					; decrement the height
       jnz	??dword_aligned_loop				; if more to do than do it
       pop	eax
       ret

	;*===================================================================
	; If not enough bytes to bother aligning copy each line across a byte
	;    at a time.
	;*===================================================================
??byte_by_byte:
	mov	ecx,esi					; get total width in bytes
	rep	stosb					; store the width
	add	edi,ebx					; handle the xadd
	dec	edx					; decrement the height
	jnz	??byte_by_byte				; if any left then next line
??exit:
	ret
	ENDP	Buffer_Clear
END