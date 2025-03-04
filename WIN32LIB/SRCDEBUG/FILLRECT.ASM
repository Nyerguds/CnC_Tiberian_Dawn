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
;*                 Project Name : GraphicViewPortClass			   *
;*                                                                         *
;*                    File Name : CLEAR.ASM                                *
;*                                                                         *
;*                   Programmer : Phil Gorrow				   *
;*                                                                         *
;*                   Start Date : June 7, 1994				   *
;*                                                                         *
;*                  Last Update : June 7, 1994   [PWG]                     *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   GVPC::Fill_Rect -- draws a filled rectangle to a graphics buffer      *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"


CODESEG

;***************************************************************************
;* GVPC::FILL_RECT -- Fills a rectangular region of a graphic view port	   *
;*                                                                         *
;* INPUT:	WORD the left hand x pixel position of region		   *
;*		WORD the upper x pixel position of region		   *
;*		WORD the right hand x pixel position of region		   *
;*		WORD the lower x pixel position of region		   *
;*		UBYTE the color (optional) to clear the view port to	   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* NOTE:	This function is optimized to handle viewport with no XAdd *
;*		value.  It also handles DWORD aligning the destination	   *
;*		when speed can be gained by doing it.			   *
;* HISTORY:                                                                *
;*   06/07/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Buffer_Fill_Rect C near
	USES	eax,ebx,ecx,edx,esi,edi,ebp

	;*===================================================================
	;* define the arguements that our function takes.
	;*===================================================================
	ARG    	this_object:DWORD			; this is a member function
	ARG	x1_pixel:WORD
	ARG	y1_pixel:WORD
	ARG	x2_pixel:WORD
	ARG	y2_pixel:WORD
	ARG    	color:BYTE			; what color should we clear to
	;*===================================================================
	; Define some locals so that we can handle things quickly
	;*===================================================================
	LOCAL	VPwidth:DWORD		; the width of the viewport
	LOCAL	VPheight:DWORD		; the height of the viewport
	LOCAL	VPxadd:DWORD		; the additional x offset of viewport
	LOCAL	VPbpr:DWORD		; the number of bytes per row of viewport

	;*===================================================================
	;* save off the viewport characteristics on the stack
	;*===================================================================
	mov	ebx,[this_object]				; get a pointer to viewport
	mov	eax,[(GraphicViewPort ebx).GVPWidth]	; get width from viewport
	mov	ecx,[(GraphicViewPort ebx).GVPHeight]	; get height from viewport
	mov	edx,[(GraphicViewPort ebx).GVPXAdd]	; get xadd from viewport
	add	edx,[(GraphicViewPort ebx).GVPPitch]	; extra pitch of direct draw surface
	mov	[VPwidth],eax				; store the width of locally
	mov	[VPheight],ecx
	mov	[VPxadd],edx
	add	eax,edx
	mov	[VPbpr],eax

	;*===================================================================
	;* move the important parameters into local registers
	;*===================================================================
	movsx	eax,[x1_pixel]
	movsx	ebx,[y1_pixel]
	movsx	ecx,[x2_pixel]
	movsx	edx,[y2_pixel]

	;*===================================================================
	;* Convert the x2 and y2 pixel to a width and height
	;*===================================================================
	cmp	eax,ecx
	jl	??no_swap_x
	xchg	eax,ecx

??no_swap_x:
	sub	ecx,eax
	cmp	ebx,edx
	jl	??no_swap_y
	xchg	ebx,edx
??no_swap_y:
	sub	edx,ebx
	inc	ecx
	inc	edx

	;*===================================================================
	;* Bounds check source X.
	;*===================================================================
	cmp	eax, [VPwidth]			; compare with the max
	jge	??out				; starts off screen, then later
	jb	short ??sx_done			; if it's not negative, it's ok

	;------ Clip source X to left edge of screen.
	add	ecx, eax			; Reduce width (add in negative src X).
	xor	eax, eax			; Clip to left of screen.
??sx_done:

	;*===================================================================
	;* Bounds check source Y.
	;*===================================================================
	cmp	ebx, [VPheight]			; compare with the max
	jge	??out				; starts off screen, then later
	jb	short ??sy_done			; if it's not negative, it's ok

	;------ Clip source Y to top edge of screen.
	add	edx, ebx			; Reduce height (add in negative src Y).
	xor	ebx, ebx			; Clip to top of screen.

??sy_done:
	;*===================================================================
	;* Bounds check width versus width of source and dest view ports
	;*===================================================================
	push	ebx				; save off ebx for later use
	mov	ebx,[VPwidth]			; get the source width
	sub	ebx, eax			; Maximum allowed pixel width (given coordinates).
	sub	ebx, ecx			; Pixel width undershoot.
	jns	short ??width_ok		; if not signed no adjustment necessary
	add	ecx, ebx			; Reduce width to screen limits.

??width_ok:
	pop	ebx				; restore ebx to old value

	;*===================================================================
	;* Bounds check height versus height of source view port
	;*===================================================================
	push	eax				; save of eax for later use
	mov	eax, [VPheight]			; get the source height
	sub	eax, ebx			; Maximum allowed pixel height (given coordinates).
	sub	eax, edx			; Pixel height undershoot.
	jns	short ??height_ok		; if not signed no adjustment necessary
	add	edx, eax			; Reduce height to screen limits.
??height_ok:
	pop	eax				; restore eax to old value

	;*===================================================================
	;* Perform the last minute checks on the width and height
	;*===================================================================
	or	ecx,ecx
	jz	??out

	or	edx,edx
	jz	??out

	cmp	ecx,[VPwidth]
	ja	??out
	cmp	edx,[VPheight]
	ja	??out

	;*===================================================================
	;* Get the offset into the virtual viewport.
	;*===================================================================
	xchg	edi,eax			; save off the contents of eax
	xchg	esi,edx			;   and edx for size test
	mov	eax,ebx			; move the y pixel into eax
	mul	[VPbpr]			; multiply by bytes per row
	add	edi,eax			; add the result into the x position
	mov	ebx,[this_object]
	add	edi,[(GraphicViewPort ebx).GVPOffset]

	mov	edx,esi			; restore edx back to real value
	mov	eax,ecx			; store total width in ecx
	sub	eax,[VPwidth]		; modify xadd value to include clipped
	sub	[VPxadd],eax		;   width bytes (subtract a negative number)

	;*===================================================================
	; Convert the color byte to a DWORD for fast storing
	;*===================================================================
	mov	al,[color]				; get color to clear to
	mov	ah,al					; extend across WORD
	mov	ebx,eax					; extend across DWORD in
	shl	eax,16					;   several steps
	mov	ax,bx

	;*===================================================================
	; If there is no row offset then adjust the width to be the size of
	;   the entire viewport and adjust the height to be 1
	;*===================================================================
	mov	esi,[VPxadd]
	or	esi,esi					; set the flags for esi
	jnz	??row_by_row_aligned			;   and act on them

	xchg	eax,ecx					; switch bit pattern and width
	mul	edx					; multiply by edx to get size
	xchg	eax,ecx					; switch size and bit pattern
	mov	edx,1					; only 1 line off view port size to do

	;*===================================================================
	; Find out if we should bother to align the row.
	;*===================================================================
??row_by_row_aligned:
	mov	ebp,ecx					; width saved in ebp
	cmp	ecx,OPTIMAL_BYTE_COPY			; is it worth aligning them?
	jl	??row_by_row				;   if not then skip

	;*===================================================================
	; Figure out the alignment offset if there is any
	;*===================================================================
	mov	ebx,edi					; get output position
	and	ebx,3					;   is there a remainder?
	jz	??aligned_loop				;   if not we are aligned
	xor	ebx,3					; find number of align bytes
	inc	ebx					; this number is off by one
	sub	ebp,ebx					; subtract from width

	;*===================================================================
	; Now that we have the alignment offset copy each row
	;*===================================================================
??aligned_loop:
	mov	ecx,ebx					; get number of bytes to align
	rep	stosb					;   and move them over
	mov	ecx,ebp					; get number of aligned bytes
	shr	ecx,2					;   convert to DWORDS
	rep	stosd					;   and move them over
	mov	ecx,ebp					; get number of aligned bytes
	and	ecx,3					;   find the remainder
	rep	stosb					;   and move it over
	add	edi,esi					; fix the line offset
	dec	edx					; decrement the height
	jnz	??aligned_loop				; if more to do than do it
	jmp	??exit					; we are all done

	;*===================================================================
	; If not enough bytes to bother aligning copy each line across a byte
	;    at a time.
	;*===================================================================
??row_by_row:
	mov	ecx,ebp					; get total width in bytes
	rep	stosb					; store the width
	add	edi,esi					; handle the xadd
	dec	edx					; decrement the height
	jnz	??row_by_row				; if any left then next line
??out:
??exit:
	ret
	ENDP	Buffer_Fill_Rect

END