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
;**      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : VSCALE.ASM                               *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : January 16, 1995                         *
;*                                                                         *
;*                  Last Update : January 16, 1995   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Linear_Scale_To_Vesa -- Scales a graphic viewport to a vesa viewport  *
;*   Vesa_Scale_To_Linear -- Scales a Vesa viewport to a graphic viewport  *
;*   Vesa_Scale_To_Vesa -- Scales a vesa viewport to a vesa viewport       *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE "mcgaprim.inc"
INCLUDE "gbuffer.inc"


GLOBAL 	Vesa_Asm_Set_Win   : near			
GLOBAL	cpu_video_page     : dword
GLOBAL	cpu_page_limit     : dword


CODESEG


;***************************************************************************
;* LINEAR_SCALE_TO_VESA -- Scales a graphic viewport to a vesa viewport	   *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/16/1995 PWG : Created.                                             *
;*=========================================================================*
	PROC	Linear_Scale_To_Vesa C near

	;*===================================================================
	;* Define the arguements that our function takes.
	;*===================================================================
	ARG	this:DWORD		; pointer to source view port
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
	local	dx_intr : dword

	local	scan_line     : dword	
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
	mov  	esi , [ this ]	    ; get ptr to src
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	eax , [ src_x0 ]
	mov	ebx , [ src_x1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( VideoViewPort esi) . VIVPHeight ] ; get height into register
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
	mov	eax , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	[ src_x1 ] , eax
	sub	eax , [ src_x ]
	imul	[ dst_width ]
	idiv	[ src_width ]
	add	eax , [ dst_x ]
	mov	[ dst_x1 ] , eax

??src_right_ok:
	test	bl , 0001b
	jz	??clip_against_dest
	mov	eax , [ (VideoViewPort esi) . VIVPHeight ]  ; get width into register
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
	mov	edi , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	eax , [ dst_x0 ]
	mov	ebx , [ dst_x1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( VideoViewPort esi) . VIVPHeight ] ; get height into register
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
	mov	eax , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	[ dst_x1 ] , eax
	sub	eax , [ dst_x ]
	imul	[ src_width ]
	idiv	[ dst_width ]
	add	eax , [ src_x ]
	mov	[ src_x1 ] , eax

??dst_right_ok:
	test	bl , 0001b
	jz	??do_scaling

	mov	eax , [ (VideoViewPort esi) . VIVPHeight ]  ; get width into register
	mov	[ dst_y1 ] , eax
	sub	eax , [ dst_y ]
	imul	[ src_height ]
	idiv	[ dst_height ]
	add	eax , [ src_y ]
	mov	[ src_y1 ] , eax

??do_scaling:

       cld	
       mov	ebx , [ this ]
       mov	esi , [ (VideoViewPort ebx) . VIVPOffset ]
       mov	eax , [ (VideoViewPort ebx) . VIVPXAdd ]
       add	eax , [ (VideoViewPort ebx) . VIVPWidth ]
       mov	[ src_win_width ] , eax
       mul	[ src_y0 ]
       add	esi , [ src_x0 ]
       add	esi , eax

       mov	ebx , [ dest ]
       mov	edi , [ (VideoViewPort ebx) . VIVPOffset ]
       mov	eax , [ (VideoViewPort ebx) . VIVPXAdd ]
       add	eax , [ (VideoViewPort ebx) . VIVPWidth ]
       mov	[ dst_win_width ] , eax
       mul	[ dst_y0 ]
       add	edi , [ dst_x0 ]
       add	edi , eax
       call	Vesa_Asm_Set_Win			; set the window

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
       jz	??all_done
       sub	ebx , [ dst_x0 ]
       jz	??all_done

       mov	[ counter_y ] , ecx
       mov	[ scan_line ] , ebx

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
       mov	ebx , [ scan_line ]
       push	esi
       add	ebx , edi 
       xor	ecx , ecx
       add	ebx , [ cpu_video_page ]
       push	edi
       cmp	ebx , [ cpu_page_limit ]
       jl	??in_range
       mov	ebx , [ scan_line ]
       jmp      ??trailing_entry 
  ??trailing_bytes: 
       mov	cl , [ esi ]
       add	ecx , eax
       adc	esi , edx
       mov	[ edi ] , cl
       inc	edi
       dec	ebx
  ??trailing_entry: 
       cmp	edi , 0b0000h
       jl	??trailing_bytes
       add	edi , [ cpu_video_page ]
       call	Vesa_Asm_Set_Win			; set the window
??end_of_scanline:
       mov	cl , [ esi ]
       add	ecx , eax
       adc	esi , edx
       mov	[ edi ] , cl
       inc	edi
       dec	ebx
       jg	??end_of_scanline
       sub	[ dword ptr esp ] , 010000h
       jmp	??next_line

??in_range:
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
  ??next_line:
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
       mov	[ dx_frac ] , eax
       mov	[ dx_intr ] , edx

       and	ecx , 01fh
       mov	eax , [ remap ]
       shr	ebx , 5
       imul	ecx , - 13
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??remapref_point + ecx ]
       mov	[ entry ] , ecx

 ??remapoutter_loop:
       mov	ebx , [ scan_line ]
       push	esi
       add	ebx , edi 
       xor	ecx , ecx
       add	ebx , [ cpu_video_page ]
       push	edi
       cmp	ebx , [ cpu_page_limit ]
       jl	??remap_in_range
       mov	edx , [ scan_line ]
       xor	ebx , ebx
       jmp    ??remap_trailing_entry 
 ??remap_trailing_bytes: 
       mov	bl , [ esi ]
       add	ecx , [ dx_frac ]
       adc	esi , [ dx_intr ]
       mov	cl , [ eax + ebx ]
       mov	[ edi ] , cl
       inc	edi
       dec	edx
 ??remap_trailing_entry:
       cmp	edi , 0b0000h
       jl	??remap_trailing_bytes
??remap_no_trailing:  
       add	edi , [ cpu_video_page ]
       call	Vesa_Asm_Set_Win			; set the window
??remap_end_of_scanline:
       mov	bl , [ esi ]
       add	ecx , [ dx_frac ]
       adc	esi , [ dx_intr ]
       mov	cl , [ eax + ebx ] 
       mov	[ edi ] , cl
       inc	edi
       dec	edx
       jg	??remap_end_of_scanline
       sub	[ dword ptr esp ] , 010000h
       jmp	??remap_next_line
??remap_in_range:
       mov	ebx , [ counter_x ]
       push	esi
       mov	[ remap_counter ] , ebx
       push	edi
       mov	edx , [ dx_intr ]
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
 ??remap_next_line:
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
; scale with transparency

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
       lea	ecx , [ ??tr_ref_point + ecx ]
       mov	[ entry ] , ecx

 ??tr_outter_loop:
       mov	ebx , [ scan_line ]
       push	esi
       add	ebx , edi 
       xor	ecx , ecx
       add	ebx , [ cpu_video_page ]
       push	edi
       cmp	ebx , [ cpu_page_limit ]
       jl	??tr_in_range

       mov	ebx , [ scan_line ]
       jmp     ??tr_trailing_entry 
  ??tr_trailing_bytes: 
       mov	cl , [ esi ]
       test	cl , cl
       jz	??tr_skip
      mov	[ edi ] , cl
   ??tr_skip:
       add	ecx , eax
       adc	esi , edx
       inc	edi
       dec	ebx
  ??tr_trailing_entry: 
       cmp	edi , 0b0000h
       jl	??tr_trailing_bytes
       add	edi , [ cpu_video_page ]
       call	Vesa_Asm_Set_Win			; set the window
??tr_end_of_scanline:
       mov	cl , [ esi ]
       test	cl , cl
       jz	??tr_skip1
       mov	[ edi ] , cl
   ??tr_skip1:
       add	ecx , eax
       adc	esi , edx
       inc	edi
       dec	ebx
       jg	??tr_end_of_scanline
       sub	[ dword ptr esp ] , 010000h
       jmp	??tr_next_line

??tr_in_range:
       mov	ebx , [ counter_x ]
       jmp	[ entry ]
 ??tr_inner_loop:
       REPT	32	
       local	skip
	       mov	cl , [ esi ]
	       test	cl , cl
	       jz	skip
	       mov	[ edi ] , cl
	    skip:
	       add	ecx , eax
	       adc	esi , edx
	       inc	edi
       ENDM
 ??tr_ref_point:
       dec	ebx
       jge	??tr_inner_loop
  ??tr_next_line:
       pop	edi
       pop	esi
       add	edi , [ dst_win_width ]
       add	esi , [ dy_intr ]

       mov	ebx , [ dy_acc ]
       add	ebx , [ dy_frac ]
       jle	??tr_skip_line
       add	esi , [ src_win_width ]
       sub	ebx , [ dst_height ]
??tr_skip_line:
	dec	[ counter_y ]
	mov	[ dy_acc ] , ebx
	jnz	??tr_outter_loop
	ret



; *************************************************************************
; normal scale with remap and transparency

??trans_remap:	
       mov	ecx , ebx
       mov	[ dx_frac ], eax
       mov	[ dx_intr ] , edx

       and	ecx , 01fh
       mov	eax , [ remap ]
       shr	ebx , 5
       imul	ecx , - 17
       mov	[ counter_x ] , ebx
       lea	ecx , [ ??trans_remapref_point + ecx ]
       mov	[ entry ] , ecx

 ??trans_remapoutter_loop:
       mov	ebx , [ scan_line ]
       push	esi
       add	ebx , edi 
       xor	ecx , ecx
       add	ebx , [ cpu_video_page ]
       push	edi
       cmp	ebx , [ cpu_page_limit ]
       jl	??trans_remap_in_range
       mov	edx , [ scan_line ]
       xor	ebx , ebx
       jmp    ??trans_remap_trailing_bytes1 
  ??trans_remap_trailing_bytes: 
       mov	bl , [ esi ]
       test	bl , bl
       jz	??trans_remp
       mov	cl , [ eax + ebx ]
       mov	[ edi ] , cl
    ??trans_remp:
       add	ecx , [ dx_frac ]
       adc	esi , [ dx_intr ]
       inc	edi
       dec	edx
  ??trans_remap_trailing_bytes1: 
       cmp	edi , 0b0000h
       jl	??trans_remap_trailing_bytes
??trans_remap_no_trailing:  
       add	edi , [ cpu_video_page ]
       call	Vesa_Asm_Set_Win			; set the window
??trans_remap_end_of_scanline:
       mov	bl , [ esi ]
       test	bl , bl
       jz	??trans_remp1
       mov	cl , [ eax + ebx ]
       mov	[ edi ] , cl
   ??trans_remp1:
       add	ecx , [ dx_frac ]
       adc	esi , [ dx_intr ]
       inc	edi
       dec	edx
       jg	??trans_remap_end_of_scanline
       sub	[ dword ptr esp ] , 010000h
       jmp	??trans_remap_next_line

??trans_remap_in_range:
       mov	ebx , [ counter_x ]
       push	esi
       mov	[ remap_counter ] , ebx
       push	edi
       mov	edx , [ dx_intr ]
       xor	ecx , ecx
       xor	ebx , ebx
       jmp	[ entry ]
 ??trans_remapinner_loop:
       REPT	32	
       local	skip
	       mov	bl , [ esi ]
	       test	bl , bl
	       jz	skip
	       mov	cl , [ eax + ebx ]
	       mov	[ edi ] , cl
	  skip:

	       add	ecx , [ dx_frac ]
	       adc	esi , edx
	       inc	edi
       ENDM
 ??trans_remapref_point:
       dec	[ remap_counter ] 
       jge	??trans_remapinner_loop
 ??trans_remap_next_line:
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

	ENDP	Linear_Scale_To_Vesa

END
