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
;*                 Project Name : Clear the Full Mcga Screen		   *
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
;*   VVPC::Clear -- Clears a virtual viewport instance                     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS  ??

INCLUDE "svgaprim.inc"
INCLUDE "gbuffer.inc"

CODESEG

PROC	Vesa_Clear C near 
	USES	eax,ebx,ecx,edx,esi,edi

	ARG    	this:DWORD				; this is a member function
	ARG    	color:BYTE				; what color should we clear to

	cld 		 				; always go forward

	mov	ebx,[this]				; get a pointer to viewport
	mov	esi,[(GraphicViewPort ebx).GVPXAdd]	; esi = add for each line
	mov	edi,[(GraphicViewPort ebx).GVPOffset]	; get the correct offset
	push	esi
	mov	edx,[(GraphicViewPort ebx).GVPHeight]	; ecx = height of viewport
	mov	esi,[(GraphicViewPort ebx).GVPWidth]	; edx = width of viewport


	;*===================================================================
	; Convert the color byte to a DWORD for fast storing
	;*===================================================================
	mov	al,[color]				; get color to clear to
	mov	ah,al					; extend across WORD
	mov	ecx,eax					; extend across DWORD in
	shl	eax,16					; several steps
	mov	ax,cx		

	Call	Vesa_Asm_Set_Win			; set the window

	;*===================================================================
	; Find out if we should bother to align the row.
	;*===================================================================

??row_by_row_aligned:
	cmp	esi , OPTIMAL_BYTE_COPY			; is it worth aligning them?
	jl	??row_by_row				;   if not then skip
	
	;*===================================================================
	; Now that we have the alignment offset copy each row
	;*===================================================================


??aligned_loop:
       lea	ebx , [ edi + esi ]
       add	ebx , [ cpu_video_page ]
       cmp	ebx , [ cpu_page_limit ]
       jl	??in_range


       xor	ecx , ecx
       mov	ebx , esi
       cmp	edi , 0b0000h
       jge	??no_trailing
       mov	ecx , 0b0000h
       sub	ecx , edi 
       sub	ebx , ecx
       rep	stosb
??no_trailing:  
       add	edi , [ cpu_video_page ]
       Call	Vesa_Asm_Set_Win			; set the window

       mov	ecx , ebx
       rep	stosb
       add	edi , [ esp ]
       dec	edx					; decrement the height
       jnz	??aligned_loop				; if more to do than do it
       pop	eax
       ret

??in_range:
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
       jnz	??aligned_loop				; if more to do than do it
       pop	eax
       ret

	;*===================================================================
	; If not enough bytes to bother aligning copy each line across a byte
	;    at a time.
	;*===================================================================
??row_by_row:

       lea	ebx , [ edi + esi ]
       add	ebx , [ cpu_video_page ]
       cmp	ebx , [ cpu_page_limit ]
       mov	ebx , esi 
       jl	??in_range_bytes

       xor	ecx , ecx
       mov	ebx , esi
       cmp	edi , 0b0000h
       jge 	??no_trailing_bytes
       mov	ecx , 0b0000h
       sub	ecx , edi 
       sub	ebx , ecx
       rep	stosb
??no_trailing_bytes:  
       add	edi , [ cpu_video_page ]
       Call	Vesa_Asm_Set_Win			; set the window
				
??in_range_bytes:

       mov	ecx , ebx
       rep	stosb
       add	edi , [ esp ]
       dec	edx					; decrement the height
       jnz	??row_by_row				; if more to do than do it
       pop	eax
       ret

ENDP	Vesa_Clear


END
