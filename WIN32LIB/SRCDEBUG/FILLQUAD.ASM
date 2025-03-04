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
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : FILLQUAD.ASM                             *
;*                                                                         *
;*                   Programmer : Ian M. Leslie                            *
;*                                                                         *
;*                   Start Date : August 11, 1994                          *
;*                                                                         *
;*                  Last Update : August 30, 1994   [IML]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:								   *
;*	Fill_Quad -- Flood fills an arbitrary convex quadrilateral	   *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

SLOT_VACANT	EQU	80008000h
NULL		EQU	0h


CODESEG

;***************************************************************************
;* VVC::FILL_QUAD -- Flood fills an arbitrary convex quadrilateral	   *
;*                                                                         *
;* INPUT:      	DWORD this_object	- associated graphic viewport		   *
;*		DWORD span_buff - pointer to span array			   *
;*		DWORD x0_pixel 	- the zeroth x pixel position		   *
;*	       	DWORD y0_pixel	- the zeroth y pixel position		   *
;*	       	DWORD x1_pixel	- the first x pixel position		   *
;*	       	DWORD y1_pixel  - the first y pixel position		   *
;*	       	DWORD x2_pixel	- the second x pixel position		   *
;*	       	DWORD y2_pixel	- the second y pixel position		   *
;*	       	DWORD x3_pixel	- the third x pixel position		   *
;*	       	DWORD y3_pixel	- the third y pixel position		   *
;*		DWORD color     - the color of the quad to fill		   *
;*                                                                         *
;* Bounds Checking: Compares quad points with the graphic viewport it 	   *
;*		    has been assigned to.				   *
;*									   *
;* Rasterization Rules: FILL_QUAD is designed to be used within a quad	   *
;*			mesh. There is no pixel overlapping or stitching   *
;*			effects at shared borders. FILL_QUAD is NOT	   *
;*                      recommended for isolated quads.                    *                                *
;* HISTORY:                                                                *
;*   08/11/1994 IML : Created.						   *
;*   08/26/1994 IML : Various optimizations.				   *
;*   08/30/1994 IML : Added rasterization rules for shared borders.	   *
;*=========================================================================*
	PROC	Buffer_Fill_Quad C NEAR
	USES	eax,ebx,ecx,edx,esi,edi


	;*==================================================================
	;* Define the arguments that the function takes.
	;*==================================================================
	ARG	this_object:DWORD		; associated graphic viewport
	ARG	span_buff:DWORD		; pointer to span array
	ARG	x0_pixel:DWORD		; the zeroth x pixel position
	ARG	y0_pixel:DWORD		; the zeroth y pixel position
	ARG	x1_pixel:DWORD		; the first x pixel position
	ARG	y1_pixel:DWORD		; the first y pixel position
	ARG	x2_pixel:DWORD		; the second x pixel position
	ARG	y2_pixel:DWORD		; the second y pixel position
	ARG	x3_pixel:DWORD		; the third x pixel position
	ARG	y3_pixel:DWORD		; the third y pixel position
	ARG	color:DWORD		; the color of the quad


	;*==================================================================
	;* Define the local variables that we will use on the stack.
	;*==================================================================
	LOCAL	clip_min_x:DWORD	; boundary of viewport
	LOCAL	clip_max_x:DWORD	;
	LOCAL	clip_min_y:DWORD	;
	LOCAL	clip_max_y:DWORD	;
	LOCAL	clip_var:DWORD
	LOCAL	left_clip_base:DWORD:2	; storage for additional edges
	LOCAL	left_clip_index:DWORD	;   generated by clipping
	LOCAL	right_clip_base:DWORD:2	;
	LOCAL	right_clip_index:DWORD	;
	LOCAL	scanline_min:DWORD	; vertical extent of quad
	LOCAL	scanline_max:DWORD
	LOCAL	realignment:DWORD
	LOCAL	bpr:DWORD		; bytes per row of associated buffer


	;*==================================================================
	;* Extract essential GraphicViewPort info.
	;*==================================================================
	mov	ebx,[this_object]
	mov	eax,[(GraphicViewPort ebx).GVPXPos]
	mov	[clip_min_x],eax
	mov	eax,[(GraphicViewPort ebx).GVPYPos]
	mov	[clip_min_y],eax
	mov	eax,[(GraphicViewPort ebx).GVPWidth]
	mov	[clip_max_x],eax
	add	eax,[(GraphicViewPort ebx).GVPXAdd]
	add	eax,[(GraphicViewPort ebx).GVPPitch]
	mov	[bpr],eax
	mov	eax,[(GraphicViewPort ebx).GVPHeight]
	mov	[clip_max_y],eax


	;*==================================================================
	;* Adjust top and right edges of viewport for rasterization rules.
	;*==================================================================
	dec	[clip_max_y]
	dec	[clip_min_y]


	;*==================================================================
	;* Find the vertical extent of the quad BEFORE clipping.
	;* y0_pixel = y0, y1_pixel = y1, y2_pixel = y2, y3_pixel = y3
	;*==================================================================
	mov	eax,[y0_pixel]
	cmp	eax,[y1_pixel]
	jle	short ??y1_not_smaller
	mov	eax,[y1_pixel]

??y1_not_smaller:
	cmp	eax,[y2_pixel]
	jle	short ??y2_not_smaller
	mov	eax,[y2_pixel]

??y2_not_smaller:
	cmp	eax,[y3_pixel]
	jle	short ??y3_not_smaller
	mov	eax,[y3_pixel]

??y3_not_smaller:
	cmp	eax,[clip_min_y]
	jge	short ??no_clamp_min_min
	mov	eax,[clip_min_y]

??no_clamp_min_min:
	cmp	eax,[clip_max_y]
	jle	short ??no_clamp_max_min
	mov	eax,[clip_max_y]
					; scanline_min = MIN (y0, y1, y2, y3)
??no_clamp_max_min:			; scanline_min = MAX (scanline_min, clip_min_y)
	mov	[scanline_min],eax	; scanline_min = MIN (scanline_min, clip_max_y)

	mov	eax,[y0_pixel]
	cmp	eax,[y1_pixel]
	jge	short ??y1_not_greater
	mov	eax,[y1_pixel]

??y1_not_greater:
	cmp	eax,[y2_pixel]
	jge	short ??y2_not_greater
	mov	eax,[y2_pixel]

??y2_not_greater:
	cmp	eax,[y3_pixel]
	jge	short ??y3_not_greater
	mov	eax,[y3_pixel]

??y3_not_greater:
	cmp	eax,[clip_min_y]
	jge	short ??no_clamp_min_max
	mov	eax,[clip_min_y]

??no_clamp_min_max:
	cmp	eax,[clip_max_y]
	jle	short ??no_clamp_max_max
	mov	eax,[clip_max_y]
					; scanline_max = MAX (y0, y1, y2, y3)
??no_clamp_max_max:			; scanline_max = MAX (scanline_max, clip_min_y)
	mov	[scanline_max],eax	; scanline_max = MIN (scanline_max, clip_max_y)


	;*==================================================================
	;* Initialize memory for spans.
	;*==================================================================
	sub	eax,[scanline_min]
	je	??abort_fill_quad	; don't render quads with zero height
	mov	ebx,eax
	mov	eax,[span_buff]		; check span_buff for NULL ptr
	cmp	eax,NULL
	je	??abort_fill_quad
	sal	ebx,2

??span_initialize_loop:
	mov	[DWORD PTR eax + ebx],SLOT_VACANT
	sub	ebx,4
	jl	short ??exit_span_initialize
	mov	[DWORD PTR eax + ebx],SLOT_VACANT
	sub	ebx,4
     	jl	short ??exit_span_initialize
	mov	[DWORD PTR eax + ebx],SLOT_VACANT
	sub	ebx,4
     	jl	short ??exit_span_initialize
	mov	[DWORD PTR eax + ebx],SLOT_VACANT
	sub	ebx,4
	jge	short ??span_initialize_loop


	;*==================================================================
	;* Clip and scan convert the four edges defining the quad.
	;*==================================================================
??exit_span_initialize:
	mov	[left_clip_index],0
	mov	[right_clip_index],0

	mov	eax,[x0_pixel]
	mov	ebx,[y0_pixel]
	mov	ecx,[x1_pixel]
	mov	edx,[y1_pixel]
	call	NEAR PTR ??clip_and_scan_convert
	mov	eax,[x1_pixel]
	mov	ebx,[y1_pixel]
	mov	ecx,[x2_pixel]
	mov	edx,[y2_pixel]
	call	NEAR PTR ??clip_and_scan_convert
	mov	eax,[x2_pixel]
	mov	ebx,[y2_pixel]
	mov	ecx,[x3_pixel]
	mov	edx,[y3_pixel]
	call	NEAR PTR ??clip_and_scan_convert
	mov	eax,[x3_pixel]
	mov	ebx,[y3_pixel]
	mov	ecx,[x0_pixel]
	mov	edx,[y0_pixel]
	call	NEAR PTR ??clip_and_scan_convert


	;*==================================================================
	;* Scan convert up to 2 additional left and right vertical edges
	;* generated by the clipping process.
	;*==================================================================
	cmp	[left_clip_index],0
	je	short ??no_left_edge
	mov	eax,[clip_min_x]
	mov	ebx,[left_clip_base]
	mov	ecx,eax
	mov	edx,[left_clip_base + 4]
	call	NEAR PTR ??scan_convert

??no_left_edge:
	cmp	[right_clip_index],0
	je	short ??no_right_edge
	mov	eax,[clip_max_x]
	mov	ebx,[right_clip_base]
	mov	ecx,eax
	mov	edx,[right_clip_base + 4]
	call	NEAR PTR ??scan_convert


	;*==================================================================
	;* Fill the quad with specified color. Use DWORD copies where
	;* appropriate.
	;*==================================================================
??no_right_edge:
	mov	eax,[this_object]
	mov	edi,[(GraphicViewPort eax).GVPOffset]
	mov	eax,[scanline_min]		; eax = scanline_min

	mov	ebx,[scanline_max]
	sub	ebx,[scanline_min]		; ebx = span count

	mov	esi,[span_buff]			; esi = address of top span

	mul	[bpr]
	add	edi,eax				; edi = address of top scanline
						;  containing quad
	mov	al,[BYTE PTR color]		; extend pixel color into eax ready
	mov	ah,al				;   for DWORD copies
	mov	edx,eax
	shl	eax,16
	mov	ax,dx

	cld					; only fill forwards

	jmp	??skip_span			; rasterization rule: don't
						;   render topmost span

??quad_fill_loop:
	cmp	[DWORD PTR esi],SLOT_VACANT	; test for unused spans	due to clipping
	je	??skip_span
	xor	ecx,ecx
	xor	edx,edx
	mov	cx,[WORD PTR esi]
	mov	dx,[WORD PTR esi + 2]
	sub	ecx,edx
	push	edi
	jns	short ??not_negative_count
	add	edi,ecx
	neg	ecx				; ecx = span width

??not_negative_count:
	add	edi,edx				; edi = address of start of span
	cmp	ecx,OPTIMAL_BYTE_COPY		; does span width justify DWORD copies?
	jl	short ??byte_copy
	mov	edx,ecx
	mov	ecx,edi
	and	ecx,3				; if (ecx == 0) edi is already
	jz	short ??dword_copy_no_alignment	;   DWORD aligned
	xor	ecx,3
	inc	ecx				; ecx = number of pixels before alignment
	sub	edx,ecx
	rep	stosb

??dword_copy_no_alignment:
	mov	ecx,edx				; ecx = remaining pixels on span
	shr	ecx,2				; copy (ecx / 4) DWORDS
	rep	stosd
	mov	ecx,edx
	and	ecx,3				; ecx = remaining pixels on span

??byte_copy:
	rep	stosb				; byte copy remaining pixels on span
	pop	edi

??skip_span:
	add	edi,[bpr]			; edi = address of start of next scanline
	add	esi,4				; esi = address of next span
	dec	ebx
	jge	short ??quad_fill_loop		; is span count >= 0?

??abort_fill_quad:
	ret


	;*==================================================================
	;* This is the section that "pushes" the edge into bounds.
	;* I have marked the section with PORTABLE start and end to signify
	;* how much of this routine is 100% portable between graphics modes.
	;* It was just as easy to have variables as it would be for constants
	;* so the global vars clip_min_x, clip_min_y, clip_max_x, clip_max_y
	;* are used to clip the edge (default is the screen).
	;* PORTABLE start.
	;*==================================================================


	;*==================================================================
	;* Clip an edge against the viewport.
	;*==================================================================
??clip_and_scan_convert:
	call	NEAR PTR ??set_left_right_bits
	xchg	eax,ecx
	xchg	ebx,edx
	mov	edi,esi
	call	NEAR PTR ??set_left_right_bits
	mov	[clip_var],edi
	or	[clip_var],esi
	jz	??clip_up_down			; trivial acceptance?
	test	edi,esi
	jne	??exit				; trivial rejection?
	shl	esi,2
	call	[DWORD PTR cs:??clip_tbl+esi]
	xchg	eax,ecx
	xchg	ebx,edx
	shl	edi,2
	call	[DWORD PTR cs:??clip_tbl+edi]

??clip_up_down:
	call	NEAR PTR ??set_up_down_bits
	xchg	eax,ecx
	xchg	ebx,edx
	mov	edi,esi
	call	NEAR PTR ??set_up_down_bits
	mov	[clip_var],edi
	or	[clip_var],esi
	jz	??scan_convert			; trivial acceptance?
	test	edi,esi
	jne	??exit				; trivial rejection?
	shl	esi,2
	call	[DWORD PTR cs:??clip_tbl+esi]
	xchg	eax,ecx
	xchg	ebx,edx
	shl	edi,2
	call	[DWORD PTR cs:??clip_tbl+edi]
	jmp	??scan_convert


	;*==================================================================
	;* Subroutine table for clipping conditions.
	;*==================================================================
??clip_tbl	DD	??nada,??a_lft,??a_rgt,??nada
		DD	??a_up,??nada,??nada,??nada
		DD	??a_dwn


	;*==================================================================
	;* Subroutines for clipping conditions.
	;*==================================================================
??nada:
	retn

??a_up:
	mov	esi,[clip_min_y]
	call	NEAR PTR ??clip_vert
	retn

??a_dwn:
	mov	esi,[clip_max_y]
	call	NEAR PTR ??clip_vert
	retn

??a_lft:
	mov	esi,[clip_min_x]
	call	NEAR PTR ??clip_horiz
	push	ebx
	mov	esi,[left_clip_index]
	cmp	ebx,[clip_min_y]
	jge	??no_left_min_clip
	mov	ebx,[clip_min_y]

??no_left_min_clip:
	cmp	ebx,[clip_max_y]
	jle	??no_left_max_clip
	mov	ebx,[clip_max_y]

??no_left_max_clip:
	mov	[left_clip_base + esi],ebx	; a left edge will be generated
	mov	[left_clip_index],4		;   store off yb
	pop	ebx
	retn

??a_rgt:
	mov	esi,[clip_max_x]
	call	NEAR PTR ??clip_horiz
	push	ebx
	mov	esi,[right_clip_index]
	cmp	ebx,[clip_min_y]
	jge	??no_right_min_clip
	mov	ebx,[clip_min_y]

??no_right_min_clip:
	cmp	ebx,[clip_max_y]
	jle	??no_right_max_clip
	mov	ebx,[clip_max_y]

??no_right_max_clip:
	mov	[right_clip_base + esi],ebx	; a right edge will be generated
	mov	[right_clip_index],4		;   store off yb
	pop	ebx
	retn


	;*==================================================================
	;* Clip a line against a horizontal edge at clip_y.
	;* (eax,ebx) = (xa,ya), (ecx,edx) = (xb,yb)
	;* xa' = xa+[(clip_y-ya)(xb-xa)/(yb-ya)]
	;* ya' = clip_y
	;*==================================================================
??clip_vert:
	push	edx
	push	eax
	mov	[clip_var],edx		; clip_var = yb
	sub	[clip_var],ebx		; clip_var = (yb-ya)
	neg	eax			; eax = -xa
	add	eax,ecx			; eax = (xb-xa)
	mov	edx,esi			; edx = clip_y
	sub	edx,ebx			; edx = (clip_y-ya)
	imul	edx			; eax = (clip_y-ya)(xb-xa)
	idiv	[clip_var]		; eax = (clip_y-ya)(xb-xa)/(yb-ya)
	pop	edx
	add	eax,edx			; eax = xa+[(clip_y-ya)(xb-xa)/(yb-ya)]
	pop	edx
	mov	ebx,esi			; ebx =	clip_y
	retn


	;*==================================================================
	;* Clip a line against a vertical edge at clip_x.
	;* (eax,ebxx) = (xa,ya), (ecx,edxx) = (xb,yb)
	;* ya' = ya+[(clip_x-xa)(yb-ya)/(xb-xa)]
	;* xa' = clip_x
	;*==================================================================
??clip_horiz:
	push	edx
	mov	[clip_var],ecx		; clip_var = xb
	sub	[clip_var],eax		; clip_var = (xb-xa)
	sub	edx,ebx			; edx = (yb-ya)
	neg	eax			; eax = -xa
	add	eax,esi			; eax = (clip_x-xa)
	imul	edx			; eax = (clip_x-xa)(yb-ya)
	idiv	[clip_var]		; eax = (clip_x-xa)(yb-ya)/(xb-xa)
	add	ebx,eax			; ebx = ya+[(clip_x-xa)(yb-ya)/(xb-xa)]
	pop	edx
	mov	eax,esi			; eax = clip_x
	retn


	;*==================================================================
	;* Set the condition bits for the subroutine table.
	;*==================================================================
??set_left_right_bits:
	xor	esi,esi
	cmp	eax,[clip_min_x]   	; if x >= left its not left
	jge	short ??a_not_left
	or	esi,1

??a_not_left:
	cmp	eax,[clip_max_x]	; if x <= right its not right
	jle	short ??a_not_right
	or	esi,2

??a_not_right:
	retn

??set_up_down_bits:
	xor	esi,esi
	cmp	ebx,[clip_min_y]	; if y >= top its not up
	jge	short ??a_not_up
	or	esi,4

??a_not_up:
	cmp	ebx,[clip_max_y]	; if y <= bottom its not down
	jle	short ??a_not_down
	or	esi,8

??a_not_down:
	retn


	;*==================================================================
	;* PORTABLE end.
	;*==================================================================

	;*==================================================================
	;* Scan convert an edge.
	;* (eax,ebx) = (xa,ya), (ecx,edx) = (xb,yb)
	;*==================================================================
??scan_convert:
	cmp	ebx,edx
	je	??exit		       		; if (ya == yb) don't scan convert
	jl	short ??no_swap			; if (ya < yb)  swap vertices
	xchg	eax,ecx
	xchg	ebx,edx

??no_swap:
	sub	edx,ebx 			; edx = (yb - ya)
	sub	ebx,[scanline_min]
	sal	ebx,2
	add	ebx,[span_buff]			; ebx = span_buff + 4(ya - clip_min_y)
	sub	ecx,eax				; ecx = (xb - xa)
	je	??v_scan			; if the edge is vertical use a
						;  special case routine
	push	eax
	mov	eax,ecx				; eax = (xb - xa)
	mov	ecx,edx				; ecx = (yb - ya)
	sal	edx,1
	mov	[realignment],edx		; realignment = 2(yb - ya)
	cwd
	idiv	cx
	cwde
	movsx	edx,dx
	mov	edi,eax				; edi = (xb - xa) / (yb - ya)
	mov	esi,edx
	mov	edx,ecx
	pop	eax				; eax = xa
	neg	edx				; edx = -(yb - ya)
	sal	esi,1				; esi = 2[(xb - xa) % (yb - ya)]
	jns	short ??r_scan			; scan to the left or right?
	neg	esi

	;*==================================================================
	;* Edge scan conversion DDA moving down and to the left.
	;* eax = xpos, ebx = span to reference
	;*==================================================================
	cmp	ebx,[span_buff]
	jg	??l_scan_convert

??l_scan_convert_loop:
	cmp	[DWORD PTR ebx],SLOT_VACANT    ; if the left slot of span is
	jne	short ??l_next_slot	       ;   vacant fill it with xpos
	mov	[ebx],ax

??l_next_slot:
	mov	[ebx + 2],ax		       ; otherwise fill the right slot
					       ;   with xpos
??l_scan_convert:
	dec	ecx
	jl	short ??exit
	add	ebx,4
	add	eax,edi
	add	edx,esi
	jle	short ??l_scan_convert_loop
	dec	eax
	sub	edx,[realignment]
	jmp	??l_scan_convert_loop


	;*==================================================================
	;* Edge scan conversion DDA moving down and to the right.
	;* eax = xpos, ebx = span to reference
	;*==================================================================
??r_scan:
	cmp	ebx,[span_buff]
	jg	??r_scan_convert

??r_scan_convert_loop:
	cmp	[DWORD PTR ebx],SLOT_VACANT    ; if the left slot of span is
	jne	short ??r_next_slot	       ;   vacant fill it with xpos
	mov	[ebx],ax

??r_next_slot:
	mov	[ebx + 2],ax		       ; otherwise fill the right slot
					       ;   with xpos
??r_scan_convert:
	dec	ecx
	jl	short ??exit
	add	ebx,4
	add	eax,edi
	add	edx,esi
	jle	short ??r_scan_convert_loop
	inc	eax
	sub	edx,[realignment]
	jmp	??r_scan_convert_loop


	;*==================================================================
	;* Scan convert a vertical edge.
	;* eax = xpos, ebx = span to reference
	;*==================================================================
??v_scan:
	cmp	ebx,[span_buff]
	jg	??v_scan_convert

??v_scan_convert_loop:
	cmp	[DWORD PTR ebx],SLOT_VACANT   ; if the left slot of span is
 	jne	short ??v_next_slot	      ;   vacant fill it with xpos
	mov	[ebx],ax

??v_next_slot:
	mov	[ebx + 2],ax		      ; otherwise fill the right slot
					      ;   with xpos
??v_scan_convert:
	add	ebx,4
	dec	edx
	jge	??v_scan_convert_loop

??exit:
	retn

	ENDP	Buffer_Fill_Quad

END
