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
;*                    File Name : BITBLIT.ASM                              *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : June 8, 1994                             *
;*                                                                         *
;*                  Last Update : December 13, 1994   [PWG]                *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS ??

INCLUDE "svgaprim.inc"
INCLUDE "gbuffer.inc"


TRANSP   equ 0

CODESEG


;***************************************************************************
;* GVC::BLIT -- Copies a buffer to a graphic page non-linearly             *
;*                                                                         *
;* NOTE:		All coordinate values are expressed in pixels      *
;*                                                                         *
;* INPUT:	VideoViewPortClass *dest -   Video View Port to copy to    *
;*		WORD src_x	     	   - Src x position to copy from   *
;*		WORD src_y		   - Src y position to copy from   *
;*		WORD dst_x		   - Dest x position to copy to	   *
;*		WORD dst_y		   - Dest y position to copy to	   *
;*		WORD w			   - Width of region to copy	   *
;*		WORD h			   - Height of region to copy	   *
;*                                                                         *
;* OUTPUT:     none                                                        *
;*                                                                         *
;* WARNINGS:   Coordinates and dimensions will be adjusted if they exceed  *
;*	       the boundaries.  In the event that no adjustment is 	   *
;*	       possible this routine will abort.			   *
;*                                                                         *
;* HISTORY:                                                                *
;*   05/11/1994 PWG : Created.                                             *
;*   08/05/1994 PWG : Fixed clipping problem                               *
;*=========================================================================*
	PROC	Linear_Blit_To_Vesa C near 
	USES	ebx,ecx,edx,esi,edi

	;*===================================================================
	;* define the arguements that our function takes.
	;*===================================================================
	ARG    	this        :DWORD		; this is a member function
	ARG	dest        :DWORD		; what are we blitting to
	ARG	x_pixel     :DWORD		; x pixel position in source
	ARG	y_pixel     :DWORD		; y pixel position in source
	ARG	dest_x0     :dword
	ARG	dest_y0     :dword
	ARG	pixel_width :DWORD		; width of rectangle to blit
	ARG	pixel_height:DWORD		; height of rectangle to blit
	ARG	trans       :DWORD			; do we deal with transparents?

	;*===================================================================
	; Define some locals so that we can handle things quickly
	;*===================================================================
	LOCAL 	x1_pixel :dword
	LOCAL	y1_pixel :dword
	LOCAL	dest_x1 : dword
	LOCAL	dest_y1 : dword
	LOCAL	scr_ajust_width:DWORD
	LOCAL	dest_ajust_width:DWORD
        LOCAL	source_area :  dword
        LOCAL	dest_area :  dword

; Clip Source Rectangle against source Window boundaries.
	mov  	esi , [ this ]	    ; get ptr to src
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	ebx , [ x_pixel ]
	mov	eax , [ x_pixel ]
	add	ebx , [ pixel_width ]
	shld	ecx , eax , 1
	mov	[ x1_pixel ] , ebx
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( VideoViewPort esi) . VIVPHeight ] ; get height into register
	mov	ebx , [ y_pixel ]
	mov	eax , [ y_pixel ]
	add	ebx , [ pixel_height ]
	shld	ecx , eax , 1
	mov	[ y1_pixel ] , ebx
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
	jnz	??real_out
	or	al , dl
	jz	??clip_against_dest

	test	cl , 1000b
	jz	??scr_left_ok
	mov	[ x_pixel ] , 0

??scr_left_ok:
	test	cl , 0010b
	jz	??scr_bottom_ok
	mov	[ y_pixel ] , 0

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	eax , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	[ x1_pixel ] , eax
??scr_right_ok:
	test	dl , 0001b
	jz	??clip_against_dest
	mov	eax , [ (VideoViewPort esi) . VIVPHeight ]  ; get width into register
	mov	[ y1_pixel ] , eax


; Clip Source Rectangle against destination Window boundaries.
??clip_against_dest:

	mov	eax , [ dest_x0 ]
	mov	ebx , [ dest_y0 ]
	sub	eax , [ x_pixel ]
	sub	ebx , [ y_pixel ]
	add	eax , [ x1_pixel ]
	add	ebx , [ y1_pixel ]
	mov	[ dest_x1 ] , eax
	mov	[ dest_y1 ] , ebx

	mov  	esi , [ dest ]	    ; get ptr to src
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	eax , [ dest_x0 ]
	mov	ebx , [ dest_x1 ]
	shld	ecx , eax , 1
	inc	edi
	shld	edx , ebx , 1
	sub	eax , edi
	sub	ebx , edi
	shld	ecx , eax , 1
	shld	edx , ebx , 1

	mov	edi,[ ( VideoViewPort esi) . VIVPHeight ] ; get height into register
	mov	eax , [ dest_y0 ]
	mov	ebx , [ dest_y1 ]
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
	jnz	??real_out
	or	al , dl
	jz	??do_blit

	test	cl , 1000b
	jz	??dest_left_ok
	mov	eax , [ dest_x0 ]
	mov	[ dest_x0 ] , 0
	sub	[ x_pixel ] , eax

??dest_left_ok:
	test	cl , 0010b
	jz	??dest_bottom_ok
	mov	eax , [ dest_y0 ]
	mov	[ dest_y0 ] , 0
	sub	[ y_pixel ] , eax


??dest_bottom_ok:
	test	dl , 0100b
	jz	??dest_right_ok
	mov	ebx , [ (VideoViewPort esi) . VIVPWidth ]  ; get width into register
	mov	eax , [ dest_x1 ]
	mov	[ dest_x1 ] , ebx
	sub	eax , ebx
	sub	[ x1_pixel ] , eax

??dest_right_ok:
	test	dl , 0001b
	jz	??do_blit
	mov	ebx , [ (VideoViewPort esi) . VIVPHeight ]  ; get width into register
	mov	eax , [ dest_y1 ]
	mov	[ dest_y1 ] , ebx
	sub	eax , ebx
	sub	[ y1_pixel ] , eax

??do_blit:

       cld	
       mov	ebx , [ this ]
       mov	esi , [ (VideoViewPort ebx) . VIVPOffset ]
       mov	eax , [ (VideoViewPort ebx) . VIVPXAdd ]
       add	eax , [ (VideoViewPort ebx) . VIVPWidth ]
       mov	ecx , eax
       mul	[ y_pixel ]
       add	esi , [ x_pixel ]
       mov	[ source_area ] , ecx
       add	esi , eax

       add	ecx , [ x_pixel ]
       sub	ecx , [ x1_pixel ]
       mov	[ scr_ajust_width ] , ecx

       mov	ebx , [ dest ]
       mov	edi , [ (VideoViewPort ebx) . VIVPOffset ]
       mov	eax , [ (VideoViewPort ebx) . VIVPXAdd ]
       add	eax , [ (VideoViewPort ebx) . VIVPWidth ]
       mov	ecx , eax
       mul	[ dest_y0 ]
       add	edi , [ dest_x0 ]
       mov	[ dest_area ] , ecx
       add	edi , eax
       Call	Vesa_Asm_Set_Win			; set the window

       mov	eax , [ dest_x1 ]
       sub	eax , [ dest_x0 ]
       jz	??real_out
       sub	ecx , eax
       mov	[ dest_ajust_width ] , ecx

       mov	edx , [ dest_y1 ]
       sub	edx , [ dest_y0 ]
       jz	??real_out


; ********************************************************************       
; Forward bitblit only

IF TRANSP
       test	[ trans ] , 1
       jnz	??forward_Blit_trans
ENDIF


; the inner loop is so efficient that 
; the optimal consept no longer apply because
; the optimal byte have to by a number greather than 9 bytes
       cmp	eax , 10        
       jl	??forward_loop_bytes

??forward_loop_dword:
       lea	ebx , [ edi + eax ]
       add	ebx , [ cpu_video_page ]
       cmp	ebx , [ cpu_page_limit ]
       jl	??in_range

       xor	ecx , ecx
       mov	ebx , eax
       cmp	edi , 0b0000h
       jge	??no_trailing
       mov	ecx , 0b0000h
       sub	ecx , edi 
       sub	ebx , ecx
       rep	movsb
??no_trailing:  
       add	edi , [ cpu_video_page ]
       Call	Vesa_Asm_Set_Win			; set the window

       mov	ecx , ebx
       rep	movsb
       add	esi , [ scr_ajust_width ]
       add	edi , [ dest_ajust_width ]
       dec	edx					; decrement the height
       jnz	??forward_loop_dword
       ret

??in_range:

       mov	ecx , edi
       mov	ebx , eax
       neg	ecx
       and	ecx , 3
       sub	ebx , ecx
       rep	movsb
       mov	ecx , ebx
       shr	ecx , 2
       rep	movsd
       mov	ecx , ebx
       and	ecx , 3
       rep	movsb
       add	esi , [ scr_ajust_width ]
       add	edi , [ dest_ajust_width ]
       dec	edx 
       jnz	??forward_loop_dword
       ret

??forward_loop_bytes:
       lea	ebx , [ edi + eax ]
       add	ebx , [ cpu_video_page ]
       cmp	ebx , [ cpu_page_limit ]
       mov	ebx , eax
       jl	??in_range_bytes

       xor	ecx , ecx
       cmp	edi , 0b0000h
       jge	??no_trailing_bytes
       mov	ecx , 0b0000h
       sub	ecx , edi 
       sub	ebx , ecx
       rep	movsb
??no_trailing_bytes:  
       add	edi , [ cpu_video_page ]
       Call	Vesa_Asm_Set_Win			; set the window
??in_range_bytes:
       mov	ecx , ebx
       rep	movsb
       add	esi , [ scr_ajust_width ]
       add	edi , [ dest_ajust_width ]
       dec	edx					; decrement the height
       jnz	??forward_loop_bytes
       ret

IF	TRANSP

??forward_Blit_trans:
       mov	ecx , eax
       and	ecx , 01fh
       lea	ecx , [ ecx + ecx * 4 ]	
       neg	ecx
       shr	eax , 5
       lea	ecx , [ ??transp_reference + ecx * 2 ]
       mov	[ y1_pixel ] , ecx

??forward_loop_trans:
       mov	ecx , eax 
       jmp	[ y1_pixel ]
??forward_trans_line:
       REPT	32	
       local	transp_pixel
       		mov	bl , [ esi ]
       		test	bl , bl
       		jz	transp_pixel
       		mov	[ edi ] , bl
    	    transp_pixel:
       		inc	esi
	    	inc	edi
	ENDM
    ??transp_reference:
       dec	ecx 
       jge	??forward_trans_line
       add	esi , [ scr_ajust_width ]
       add	edi , [ dest_ajust_width ]
       dec	edx 
       jnz	??forward_loop_trans
       ret
ENDIF

??real_out:
       ret
ENDP	Linear_Blit_To_Vesa

END
