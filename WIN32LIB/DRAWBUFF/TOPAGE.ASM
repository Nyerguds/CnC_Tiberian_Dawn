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
;*                    File Name : TOPAGE.ASM                               *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : June 8, 1994                             *
;*                                                                         *
;*                  Last Update : June 15, 1994   [PWG]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Buffer_To_Page -- Copies a linear buffer to a virtual viewport	   *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

TRANSP	equ  0


INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

CODESEG

;***************************************************************************
;* VVC::TOPAGE -- Copies a linear buffer to a virtual viewport		   *
;*                                                                         *
;* INPUT:	WORD	x_pixel		- x pixel on viewport to copy from *
;*		WORD	y_pixel 	- y pixel on viewport to copy from *
;*		WORD	pixel_width	- the width of copy region	   *
;*		WORD	pixel_height	- the height of copy region	   *
;*		BYTE *	src		- buffer to copy from		   *
;*		VVPC *  dest		- virtual viewport to copy to	   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    Coordinates and dimensions will be adjusted if they exceed *
;*	        the boundaries.  In the event that no adjustment is 	   *
;*	        possible this routine will abort.  If the size of the 	   *
;*		region to copy exceeds the size passed in for the buffer   *
;*		the routine will automatically abort.			   *
;*									   *
;* HISTORY:                                                                *
;*   06/15/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Buffer_To_Page C near
	USES	eax,ebx,ecx,edx,esi,edi

	;*===================================================================
	;* define the arguements that our function takes.
	;*===================================================================
	ARG	x_pixel     :DWORD		; x pixel position in source
	ARG	y_pixel     :DWORD		; y pixel position in source
	ARG	pixel_width :DWORD		; width of rectangle to blit
	ARG	pixel_height:DWORD		; height of rectangle to blit
	ARG    	src         :DWORD		; this is a member function
	ARG	dest        :DWORD		; what are we blitting to

;	ARG	trans       :DWORD			; do we deal with transparents?

	;*===================================================================
	; Define some locals so that we can handle things quickly
	;*===================================================================
	LOCAL 	x1_pixel :dword
	LOCAL	y1_pixel :dword
	local	scr_x 	: dword
	local	scr_y 	: dword
	LOCAL	dest_ajust_width:DWORD
	LOCAL	scr_ajust_width:DWORD
	LOCAL	dest_area   :  dword

	cmp	[ src ] , 0
	jz	??real_out


; Clip dest Rectangle against source Window boundaries.

	mov	[ scr_x ] , 0
	mov	[ scr_y ] , 0
	mov  	esi , [ dest ]	    ; get ptr to dest
	xor 	ecx , ecx
	xor 	edx , edx
	mov	edi , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
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

	mov	edi,[ ( GraphicViewPort esi) . GVPHeight ] ; get height into register
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
	jz	??do_blit

	test	cl , 1000b
	jz	??dest_left_ok
	mov	eax , [ x_pixel ]
	neg	eax
	mov	[ x_pixel ] , 0
	mov	[ scr_x ] , eax

??dest_left_ok:
	test	cl , 0010b
	jz	??dest_bottom_ok
	mov	eax , [ y_pixel ]
	neg	eax
	mov	[ y_pixel ] , 0
	mov	[ scr_y ] , eax

??dest_bottom_ok:
	test	dl , 0100b
	jz	??dest_right_ok
	mov	eax , [ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	[ x1_pixel ] , eax
??dest_right_ok:
	test	dl , 0001b
	jz	??do_blit
	mov	eax , [ (GraphicViewPort esi) . GVPHeight ]  ; get width into register
	mov	[ y1_pixel ] , eax

??do_blit:

       cld

       mov	eax , [ (GraphicViewPort esi) . GVPXAdd ]
       add	eax , [ (GraphicViewPort esi) . GVPWidth ]
       add	eax , [ (GraphicViewPort esi) . GVPPitch ]
       mov	edi , [ (GraphicViewPort esi) . GVPOffset ]

       mov	ecx , eax
       mul	[ y_pixel ]
       add	edi , [ x_pixel ]
       add	edi , eax

       add	ecx , [ x_pixel ]
       sub	ecx , [ x1_pixel ]
       mov	[ dest_ajust_width ] , ecx


       mov	esi , [ src ]
       mov	eax , [ pixel_width ]
       sub	eax , [ x1_pixel ]
       add	eax , [ x_pixel ]
       mov	[ scr_ajust_width ] , eax

       mov	eax , [ scr_y ]
       mul 	[ pixel_width ]
       add	eax , [ scr_x ]
       add	esi , eax

       mov	edx , [ y1_pixel ]
       mov	eax , [ x1_pixel ]

       sub	edx , [ y_pixel ]
       jle	??real_out
       sub	eax , [ x_pixel ]
       jle	??real_out


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
       mov	ecx , eax
       rep	movsb
       add	esi , [ scr_ajust_width ]
       add	edi , [ dest_ajust_width ]
       dec	edx					; decrement the height
       jnz	??forward_loop_bytes
       ret

IF  TRANSP


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
       		inc	esi
       		test	bl , bl
       		jz	transp_pixel
       		mov	[ edi ] , bl
    	    transp_pixel:
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


	ENDP	Buffer_To_Page
END