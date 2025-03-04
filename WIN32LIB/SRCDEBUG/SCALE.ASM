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
;*                    File Name : SCALE.ASM                                *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : June 16, 1994                            *
;*                                                                         *
;*                  Last Update : June 21, 1994   [PWG]                    *
;*                  New version : feb 12, 1995  [JRJ]                      *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   VVC::Scale -- Scales a virtual viewport to another virtual viewport   *
;*   Normal_Draw -- jump loc for drawing  scaled line of normal pixel      *
;*   Normal_Remapped_Draw -- jump loc for draw scaled line of remap pixel  *
;*   Transparent_Draw -- jump loc for scaled line of transparent pixels    *
;*   Transparent_Remapped_Draw -- jump loc for scaled remap trans pixels   *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"


CODESEG


;***************************************************************************
;* VVC::SCALE -- Scales a virtual viewport to another virtual viewport     *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   06/16/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Linear_Scale_To_Linear C NEAR
	USES	eax,ebx,ecx,edx,esi,edi

	;*===================================================================
	;* Define the arguements that our function takes.
	;*===================================================================
	ARG	this_object:DWORD		; pointer to source view port
	ARG	dest:DWORD		; pointer to destination view port
	ARG	src_x:DWORD		; source x offset into view port
	ARG	src_y:DWORD		; source y offset into view port
	ARG	dst_x:DWORD		; dest x offset into view port
	ARG	dst_y:DWORD		; dest y offset into view port
	ARG	src_width:DWORD		; width of source rectangle
	ARG	src_height:DWORD	; height of source rectangle
	ARG	dst_width:DWORD		; width of dest rectangle
	ARG	dst_height:DWORD	; width of dest height
	ARG	trans:DWORD		; is this transparent?
	ARG	remap:DWORD		; pointer to table to remap source

	;*===================================================================
	;* Define local variables to hold the viewport characteristics
	;*===================================================================
	local	src_x0 : dword
	local	src_y0 : dword
	local	src_x1 : dword
	local	src_y1 : dword

	local	dst_x0 : dword
	local	dst_y0 : dword
	local	dst_x1 : dword
	local	dst_y1 : dword

	local	src_win_width : dword
	local	dst_win_width : dword
	local	dy_intr : dword
	local	dy_frac : dword
	local	dy_acc  : dword
	local	dx_frac : dword

	local	counter_x     : dword
	local	counter_y     : dword
	local	remap_counter :dword
	local	entry : dword

	;*===================================================================
	;* Check for scale error when to or from size 0,0
	;*===================================================================
	cmp	[dst_width],0
	je	??all_done
	cmp	[dst_height],0
	je	??all_done
	cmp	[src_width],0
	je	??all_done
	cmp	[src_height],0
	je	??all_done

	mov	eax , [ src_x ]
	mov	ebx , [ src_y ]
	mov	[ src_x0 ] , eax
	mov	[ src_y0 ] , ebx
	add	eax , [ src_width ]
	add	ebx , [ src_height ]
	mov	[ src_x1 ] , eax
	mov	[ src_y1 ] , ebx

	mov	eax , [ dst_x ]
	mov	ebx , [ dst_y ]
	mov	[ dst_x0 ] , eax
	mov	[ dst_y0 ] , ebx
	add	eax , [ dst_width ]
	add	ebx , [ dst_height ]
	mov	[ dst_x1 ] , eax
	mov	[ dst_y1 ] , ebx

; Clip Source Rectangle against source Window boundaries.
	mov  	esi , [ this_object ]	    ; get ptr to src
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	eax , [ src_x0 ]
	mov	ebx , [ src_x1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( GraphicViewPort esi) . GVPHeight ] ; get height into register
	mov	eax , [ src_y0 ]
	mov	ebx , [ src_y1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	xor	cl , 5
	xor	dl , 5
	mov	al , cl
	test	dl , cl
	jnz	??all_done
	or	al , dl
	jz	??clip_against_dest
	mov	bl , dl
	test	cl , 1000b
	jz	??src_left_ok
	xor	eax , eax
	mov	[ src_x0 ] , eax
	sub	eax , [ src_x ]
	imul	[ dst_width ]
	idiv	[ src_width ]
	add	eax , [ dst_x ]
	mov	[ dst_x0 ] , eax

??src_left_ok:
	test	cl , 0010b
	jz	??src_bottom_ok
	xor	eax , eax
	mov	[ src_y0 ] , eax
	sub	eax , [ src_y ]
	imul	[ dst_height ]
	idiv	[ src_height ]
	add	eax , [ dst_y ]
	mov	[ dst_y0 ] , eax

??src_bottom_ok:
	test	bl , 0100b
	jz	??src_right_ok
	mov	eax , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	[ src_x1 ] , eax
	sub	eax , [ src_x ]
	imul	[ dst_width ]
	idiv	[ src_width ]
	add	eax , [ dst_x ]
	mov	[ dst_x1 ] , eax

??src_right_ok:
	test	bl , 0001b
	jz	??clip_against_dest
	mov	eax , [ (GraphicViewPort esi) . GVPHeight ]  ; get width into register
	mov	[ src_y1 ] , eax
	sub	eax , [ src_y ]
	imul	[ dst_height ]
	idiv	[ src_height ]
	add	eax , [ dst_y ]
	mov	[ dst_y1 ] , eax

; Clip destination Rectangle against source Window boundaries.
??clip_against_dest:
	mov  	esi , [ dest ]	    ; get ptr to src
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	eax , [ dst_x0 ]
	mov	ebx , [ dst_x1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( GraphicViewPort esi) . GVPHeight ] ; get height into register
	mov	eax , [ dst_y0 ]
	mov	ebx , [ dst_y1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	xor	cl , 5
	xor	dl , 5
	mov	al , cl
	test	dl , cl
	jnz	??all_done
	or	al , dl
	jz	??do_scaling
	mov	bl , dl
	test	cl , 1000b
	jz	??dst_left_ok
	xor	eax , eax
	mov	[ dst_x0 ] , eax
	sub	eax , [ dst_x ]
	imul	[ src_width ]
	idiv	[ dst_width ]
	add	eax , [ src_x ]
	mov	[ src_x0 ] , eax

??dst_left_ok:
	test	cl , 0010b
	jz	??dst_bottom_ok
	xor	eax , eax
	mov	[ dst_y0 ] , eax
	sub	eax , [ dst_y ]
	imul	[ src_height ]
	idiv	[ dst_height ]
	add	eax , [ src_y ]
	mov	[ src_y0 ] , eax

??dst_bottom_ok:
	test	bl , 0100b
	jz	??dst_right_ok
	mov	eax , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	[ dst_x1 ] , eax
	sub	eax , [ dst_x ]
	imul	[ src_width ]
	idiv	[ dst_width ]
	add	eax , [ src_x ]
	mov	[ src_x1 ] , eax

??dst_right_ok:
	test	bl , 0001b
	jz	??do_scaling

	mov	eax , [ (GraphicViewPort esi) . GVPHeight ]  ; get width into register
	mov	[ dst_y1 ] , eax
	sub	eax , [ dst_y ]
	imul	[ src_height ]
	idiv	[ dst_height ]
	add	eax , [ src_y ]
	mov	[ src_y1 ] , eax

??do_scaling:

       cld
       mov	ebx , [ this_object ]
       mov	esi , [ (GraphicViewPort ebx) . GVPOffset ]
       mov	eax , [ (GraphicViewPort ebx) . GVPXAdd ]
       add	eax , [ (GraphicViewPort ebx) . GVPWidth ]
       add	eax , [ (GraphicViewPort ebx) . GVPPitch ]
       mov	[ src_win_width ] , eax
       mul	[ src_y0 ]
       add	esi , [ src_x0 ]
       add	esi , eax

       mov	ebx , [ dest ]
       mov	edi , [ (GraphicViewPort ebx) . GVPOffset ]
       mov	eax , [ (GraphicViewPort ebx) . GVPXAdd ]
       add	eax , [ (GraphicViewPort ebx) . GVPWidth ]
       add	eax , [ (GraphicViewPort ebx) . GVPPitch ]
       mov	[ dst_win_width ] , eax
       mul	[ dst_y0 ]
       add	edi , [ dst_x0 ]
       add	edi , eax

       mov	eax , [ src_height ]
       xor	edx , edx
       mov	ebx , [ dst_height ]
       idiv	[ dst_height ]
       imul	eax , [ src_win_width ]
       neg	ebx
       mov	[ dy_intr ] , eax
       mov	[ dy_frac ] , edx
       mov	[ dy_acc ]  , ebx

       mov	eax , [ src_width ]
       xor	edx , edx
       shl	eax , 16
       idiv	[ dst_width ]
       xor	edx , edx
       shld	edx , eax , 16
       shl	eax , 16

       mov	ecx , [ dst_y1 ]
       mov	ebx , [ dst_x1 ]
       sub	ecx , [ dst_y0 ]
       jle	??all_done
       sub	ebx , [ dst_x0 ]
       jle	??all_done

       mov	[ counter_y ] , ecx

       cmp	[ trans ] , 0
       jnz	??transparency

       cmp	[ remap ] , 0
       jnz	??normal_remap

; *************************************************************************
; normal scale
       mov	ecx , ebx
       and	ecx , 01fh
       lea	ecx , [ ecx + ecx * 2 ]
       shr	ebx , 5
       neg	ecx
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??ref_point + ecx + ecx * 2 ]
       mov	[ entry ] , ecx

 ??outter_loop:
       push	esi
       push	edi
       xor	ecx , ecx
       mov	ebx , [ counter_x ]
       jmp	[ entry ]
 ??inner_loop:
       REPT	32
	       mov	cl , [ esi ]
	       add	ecx , eax
	       adc	esi , edx
	       mov	[ edi ] , cl
	       inc	edi
       ENDM
 ??ref_point:
       dec	ebx
       jge	??inner_loop

       pop	edi
       pop	esi
       add	edi , [ dst_win_width ]
       add	esi , [ dy_intr ]

       mov	ebx , [ dy_acc ]
       add	ebx , [ dy_frac ]
       jle	??skip_line
       add	esi , [ src_win_width ]
       sub	ebx , [ dst_height ]
??skip_line:
	dec	[ counter_y ]
	mov	[ dy_acc ] , ebx
	jnz	??outter_loop
	ret


; *************************************************************************
; normal scale with remap

??normal_remap:
       mov	ecx , ebx
       mov	[ dx_frac ], eax
       and	ecx , 01fh
       mov	eax , [ remap ]
       shr	ebx , 5
       imul	ecx , - 13
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??remapref_point + ecx ]
       mov	[ entry ] , ecx

 ??remapoutter_loop:
       mov	ebx , [ counter_x ]
       push	esi
       mov	[ remap_counter ] , ebx
       push	edi
       xor	ecx , ecx
       xor	ebx , ebx
       jmp	[ entry ]
 ??remapinner_loop:
       REPT	32
	       mov	bl , [ esi ]
	       add	ecx , [ dx_frac ]
	       adc	esi , edx
	       mov	cl , [ eax + ebx ]
	       mov	[ edi ] , cl
	       inc	edi
       ENDM
 ??remapref_point:
       dec	[ remap_counter ]
       jge	??remapinner_loop

       pop	edi
       pop	esi
       add	edi , [ dst_win_width ]
       add	esi , [ dy_intr ]

       mov	ebx , [ dy_acc ]
       add	ebx , [ dy_frac ]
       jle	??remapskip_line
       add	esi , [ src_win_width ]
       sub	ebx , [ dst_height ]
??remapskip_line:
	dec	[ counter_y ]
	mov	[ dy_acc ] , ebx
	jnz	??remapoutter_loop
	ret


;****************************************************************************
; scale with trnsparency

??transparency:
       cmp	[ remap ] , 0
       jnz	??trans_remap

; *************************************************************************
; normal scale with transparency
       mov	ecx , ebx
       and	ecx , 01fh
       imul	ecx , -13
       shr	ebx , 5
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??trans_ref_point + ecx ]
       mov	[ entry ] , ecx

 ??trans_outter_loop:
       xor	ecx , ecx
       push	esi
       push	edi
       mov	ebx , [ counter_x ]
       jmp	[ entry ]
 ??trans_inner_loop:
       REPT	32
       local	trans_pixel
	       mov	cl , [ esi ]
	       test	cl , cl
	       jz	trans_pixel
	       mov	[ edi ] , cl
       trans_pixel:
	       add	ecx , eax
	       adc	esi , edx
	       inc	edi
       ENDM
 ??trans_ref_point:
       dec	ebx
       jge	??trans_inner_loop

       pop	edi
       pop	esi
       add	edi , [ dst_win_width ]
       add	esi , [ dy_intr ]

       mov	ebx , [ dy_acc ]
       add	ebx , [ dy_frac ]
       jle	??trans_skip_line
       add	esi , [ src_win_width ]
       sub	ebx , [ dst_height ]
??trans_skip_line:
	dec	[ counter_y ]
	mov	[ dy_acc ] , ebx
	jnz	??trans_outter_loop
	ret


; *************************************************************************
; normal scale with remap

??trans_remap:
       mov	ecx , ebx
       mov	[ dx_frac ], eax
       and	ecx , 01fh
       mov	eax , [ remap ]
       shr	ebx , 5
       imul	ecx , - 17
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??trans_remapref_point + ecx ]
       mov	[ entry ] , ecx

 ??trans_remapoutter_loop:
       mov	ebx , [ counter_x ]
       push	esi
       mov	[ remap_counter ] , ebx
       push	edi
       xor	ecx , ecx
       xor	ebx , ebx
       jmp	[ entry ]
 ??trans_remapinner_loop:
       REPT	32
       local	trans_pixel
	       mov	bl , [ esi ]
	       test	bl , bl
	       jz	trans_pixel
	       mov	cl , [ eax + ebx ]
	       mov	[ edi ] , cl
	  trans_pixel:
	       add	ecx , [ dx_frac ]
	       adc	esi , edx
	       inc	edi
       ENDM
 ??trans_remapref_point:
       dec	[ remap_counter ]
       jge	??trans_remapinner_loop

       pop	edi
       pop	esi
       add	edi , [ dst_win_width ]
       add	esi , [ dy_intr ]

       mov	ebx , [ dy_acc ]
       add	ebx , [ dy_frac ]
       jle	??trans_remapskip_line
       add	esi , [ src_win_width ]
       sub	ebx , [ dst_height ]
??trans_remapskip_line:
	dec	[ counter_y ]
	mov	[ dy_acc ] , ebx
	jnz	??trans_remapoutter_loop
	ret





??all_done:
	ret
endp


END