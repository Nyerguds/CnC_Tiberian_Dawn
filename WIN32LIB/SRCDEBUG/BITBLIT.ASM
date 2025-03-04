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
;*                   Programmer : Julio R. Jerez                           *
;*                                                                         *
;*                   Start Date : Feb 6, 1995                              *
;*                                                                         *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS ??

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

CODESEG

	PROC	Linear_Blit_To_Linear C near
	USES	ebx,ecx,edx,esi,edi

	;*===================================================================
	;* define the arguements that our function takes.
	;*===================================================================
	ARG    	this_object :DWORD		; this is a member function
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

;This Clipping algorithm is a derivation of the very well known
;Cohen-Sutherland Line-Clipping test. Due to its simplicity and efficiency
;it is probably the most commontly implemented algorithm both in software
;and hardware for clipping lines, rectangles, and convex polygons against
;a rectagular clipping window. For reference see
;"COMPUTER GRAPHICS principles and practice by Foley, Vandam, Feiner, Hughes
; pages 113 to 177".
; Briefly consist in computing the Sutherland code for both end point of
; the rectangle to find out if the rectangle is:
; - trivially accepted (no further clipping test, display rectangle)
; - trivially rejected (return with no action)
; - retangle must be iteratively clipped again edges of the clipping window
;   and the remaining retangle is display.

; Clip Source Rectangle against source Window boundaries.
	mov  	esi,[this_object]    ; get ptr to src
	xor 	ecx,ecx		    ; Set sutherland code to zero
	xor 	edx,edx		    ; Set sutherland code to zero

   ; compute the difference in the X axis and get the bit signs into ecx , edx
	mov	edi,[(GraphicViewPort esi).GVPWidth]  ; get width into register
	mov	ebx,[x_pixel]	    ; Get first end point x_pixel into register
	mov	eax,[x_pixel]	    ; Get second end point x_pixel into register
	add	ebx,[pixel_width]   ; second point x1_pixel = x + width
	shld	ecx, eax,1	    ; the sign bit of x_pixel is sutherland code0 bit4
	mov	[x1_pixel],ebx	    ; save second for future use
	inc	edi		    ; move the right edge by one unit
	shld	edx,ebx,1	    ; the sign bit of x1_pixel is sutherland code0 bit4
	sub	eax,edi		    ; compute the difference x0_pixel - width
	sub	ebx,edi		    ; compute the difference x1_pixel - width
	shld	ecx,eax,1	    ; the sign bit of the difference is sutherland code0 bit3
	shld	edx,ebx,1	    ; the sign bit of the difference is sutherland code0 bit3

   ; the following code is just a repeticion of the above code
   ; in the Y axis.
	mov	edi,[(GraphicViewPort esi).GVPHeight] ; get height into register
	mov	ebx,[y_pixel]
	mov	eax,[y_pixel]
	add	ebx,[pixel_height]
	shld	ecx,eax,1
	mov	[y1_pixel ],ebx
	inc	edi
	shld	edx,ebx,1
	sub	eax,edi
	sub	ebx,edi
	shld	ecx,eax,1
	shld	edx,ebx,1

    ; Here we have the to Sutherland code into cl and dl
	xor	cl,5		       ; bit 2 and 0 are complented, reverse then
	xor	dl,5		       ; bit 2 and 0 are complented, reverse then
	mov	al,cl		       ; save code1 in case we have to clip iteratively
	test	dl,cl		       ; if any bit in code0 and its counter bit
	jnz	??real_out	       ; in code1 is set then the rectangle in outside
	or	al,dl		       ; if all bit of code0 the counter bit in
	jz	??clip_against_dest    ; in code1 is set to zero, then all
				       ; end points of the rectangle are
				       ; inside the clipping window

     ; if we are here the polygon have to be clip iteratively
	test	cl,1000b	       ; if bit 4 in code0 is set then
	jz	??scr_left_ok	       ; x_pixel is smaller than zero
	mov	[x_pixel],0	       ; set x_pixel to cero.

??scr_left_ok:
	test	cl,0010b	       ; if bit 2 in code0 is set then
	jz	??scr_bottom_ok	       ; y_pixel is smaller than zero
	mov	[ y_pixel ],0	       ; set y_pixel to cero.

??scr_bottom_ok:
	test	dl,0100b	       ; if bit 3 in code1 is set then
	jz	??scr_right_ok	       ; x1_pixel is greater than the width
	mov	eax,[(GraphicViewPort esi).GVPWidth] ; get width into register
	mov	[ x1_pixel ],eax       ; set x1_pixel to width.
??scr_right_ok:
	test	dl,0001b	       ; if bit 0 in code1 is set then
	jz	??clip_against_dest    ; y1_pixel is greater than the width
	mov	eax,[(GraphicViewPort esi).GVPHeight]  ; get height into register
	mov	[ y1_pixel ],eax       ; set y1_pixel to height.

; Clip Source Rectangle against destination Window boundaries.
??clip_against_dest:

   ; build the destination rectangle before clipping
   ; dest_x1 = dest_x0 + ( x1_pixel - x_pixel )
   ; dest_y1 = dest_y0 + ( y1_pixel - y_pixel )
	mov	eax,[dest_x0]	     ; get dest_x0 into eax
	mov	ebx,[dest_y0]	     ; get dest_y0 into ebx
	sub	eax,[x_pixel]	     ; subtract x_pixel from eax
	sub	ebx,[y_pixel]	     ; subtract y_pixel from ebx
	add	eax,[x1_pixel]	     ; add x1_pixel to eax
	add	ebx,[y1_pixel]	     ; add y1_pixel to ebx
	mov	[dest_x1],eax	     ; save eax into dest_x1
	mov	[dest_y1],ebx	     ; save eax into dest_y1


  ; The followin code is a repeticion of the Sutherland clipping
  ; descrived above.
	mov  	esi,[dest]	    ; get ptr to src
	xor 	ecx,ecx
	xor 	edx,edx
	mov	edi,[(GraphicViewPort esi).GVPWidth]  ; get width into register
	mov	eax,[dest_x0]
	mov	ebx,[dest_x1]
	shld	ecx,eax,1
	inc	edi
	shld	edx,ebx,1
	sub	eax,edi
	sub	ebx,edi
	shld	ecx,eax,1
	shld	edx,ebx,1

	mov	edi,[( GraphicViewPort esi) . GVPHeight ] ; get height into register
	mov	eax,[dest_y0]
	mov	ebx,[dest_y1]
	shld	ecx,eax,1
	inc	edi
	shld	edx,ebx,1
	sub	eax,edi
	sub	ebx,edi
	shld	ecx,eax,1
	shld	edx,ebx,1

	xor	cl,5
	xor	dl,5
	mov	al,cl
	test	dl,cl
	jnz	??real_out
	or	al,dl
	jz	??do_blit

	test	cl,1000b
	jz	??dest_left_ok
	mov	eax,[ dest_x0 ]
	mov	[ dest_x0 ],0
	sub	[ x_pixel ],eax

??dest_left_ok:
	test	cl,0010b
	jz	??dest_bottom_ok
	mov	eax,[ dest_y0 ]
	mov	[ dest_y0 ],0
	sub	[ y_pixel ],eax


??dest_bottom_ok:
	test	dl,0100b
	jz	??dest_right_ok
	mov	ebx,[ (GraphicViewPort esi) . GVPWidth ]  ; get width into register
	mov	eax,[ dest_x1 ]
	mov	[ dest_x1 ],ebx
	sub	eax,ebx
	sub	[ x1_pixel ],eax

??dest_right_ok:
	test	dl,0001b
	jz	??do_blit
	mov	ebx,[ (GraphicViewPort esi) . GVPHeight ]  ; get width into register
	mov	eax,[ dest_y1 ]
	mov	[ dest_y1 ],ebx
	sub	eax,ebx
	sub	[ y1_pixel ],eax


; Here is where	we do the actual blit
??do_blit:
       cld
       mov	ebx,[this_object]
       mov	esi,[(GraphicViewPort ebx).GVPOffset]
       mov	eax,[(GraphicViewPort ebx).GVPXAdd]
       add	eax,[(GraphicViewPort ebx).GVPWidth]
       add	eax,[(GraphicViewPort ebx).GVPPitch]
       mov	ecx,eax
       mul	[y_pixel]
       add	esi,[x_pixel]
       mov	[source_area],ecx
       add	esi,eax

       add	ecx,[x_pixel ]
       sub	ecx,[x1_pixel ]
       mov	[scr_ajust_width ],ecx

       mov	ebx,[dest]
       mov	edi,[(GraphicViewPort ebx).GVPOffset]
       mov	eax,[(GraphicViewPort ebx).GVPXAdd]
       add	eax,[(GraphicViewPort ebx).GVPWidth]
       add	eax,[(GraphicViewPort ebx).GVPPitch]
       mov	ecx,eax
       mul	[ dest_y0 ]
       add	edi,[ dest_x0 ]
       mov	[ dest_area ],ecx
       add	edi,eax

       mov	eax,[ dest_x1 ]
       sub	eax,[ dest_x0 ]
       jle	??real_out
       sub	ecx,eax
       mov	[ dest_ajust_width ],ecx

       mov	edx,[ dest_y1 ]
       sub	edx,[ dest_y0 ]
       jle	??real_out

       cmp	esi,edi
       jz	??real_out
       jl	??backupward_blit

; ********************************************************************
; Forward bitblit

       test	[ trans ],1
       jnz	??forward_Blit_trans


; the inner loop is so efficient that
; the optimal consept no longer apply because
; the optimal byte have to by a number greather than 9 bytes
       cmp	eax,10
       jl	??forward_loop_bytes

??forward_loop_dword:
       mov	ecx,edi
       mov	ebx,eax
       neg	ecx
       and	ecx,3
       sub	ebx,ecx
       rep	movsb
       mov	ecx,ebx
       shr	ecx,2
       rep	movsd
       mov	ecx,ebx
       and	ecx,3
       rep	movsb
       add	esi,[ scr_ajust_width ]
       add	edi,[ dest_ajust_width ]
       dec	edx
       jnz	??forward_loop_dword
       ret

??forward_loop_bytes:
       mov	ecx,eax
       rep	movsb
       add	esi,[ scr_ajust_width ]
       add	edi,[ dest_ajust_width ]
       dec	edx
       jnz	??forward_loop_bytes
       ret

??forward_Blit_trans:
       mov	ecx,eax
       and	ecx,01fh
       lea	ecx,[ ecx + ecx * 4 ]
       neg	ecx
       shr	eax,5
       lea	ecx,[ ??transp_reference + ecx * 2 ]
       mov	[ y1_pixel ],ecx

??forward_loop_trans:
       mov	ecx,eax
       jmp	[ y1_pixel ]
??forward_trans_line:
       REPT	32
       local	transp_pixel
       		mov	bl,[ esi ]
       		test	bl,bl
       		jz	transp_pixel
       		mov	[ edi ],bl
    	    transp_pixel:
       		inc	esi
	    	inc	edi
	ENDM
    ??transp_reference:
       dec	ecx
       jge	??forward_trans_line
       add	esi,[ scr_ajust_width ]
       add	edi,[ dest_ajust_width ]
       dec	edx
       jnz	??forward_loop_trans
       ret


; ************************************************************************
; backward bitblit

??backupward_blit:

	mov	ebx,[ source_area ]
	dec	edx
	add	esi,eax
	imul    ebx,edx
	std
	lea	esi,[ esi + ebx - 1 ]

	mov	ebx,[ dest_area ]
	add	edi,eax
	imul    ebx,edx
	lea	edi,[ edi + ebx - 1]

       test	[ trans ],1
       jnz	??backward_Blit_trans

        cmp	eax,15
        jl	??backward_loop_bytes

??backward_loop_dword:
	push	edi
	push	esi
	lea	ecx,[edi+1]
	mov	ebx,eax
	and	ecx,3		; Get non aligned bytes.
	sub	ebx,ecx		; remove that from the total size to be copied later.
	rep	movsb		; do the copy.
	sub	esi,3
	mov	ecx,ebx		; Get number of bytes left.
 	sub	edi,3
	shr	ecx,2		; Do 4 bytes at a time.
	rep	movsd		; do the dword copy.
	mov	ecx,ebx
	add	esi,3
	add	edi,3
	and	ecx,03h
	rep	movsb		; finnish the remaining bytes.
	pop	esi
	pop	edi
        sub	esi,[ source_area ]
        sub	edi,[ dest_area ]
	dec	edx
	jge	??backward_loop_dword
	cld
	ret

??backward_loop_bytes:
	push	edi
	mov	ecx,eax		; remove that from the total size to be copied later.
	push	esi
	rep	movsb		; do the copy.
	pop	esi
	pop	edi
        sub	esi,[ source_area ]
        sub	edi,[ dest_area ]
	dec	edx
	jge	??backward_loop_bytes
	cld
	ret

??backward_Blit_trans:
       mov	ecx,eax
       and	ecx,01fh
       lea	ecx,[ ecx + ecx * 4 ]
       neg	ecx
       shr	eax,5
       lea	ecx,[ ??back_transp_reference + ecx * 2 ]
       mov	[ y1_pixel ],ecx

??backward_loop_trans:
       mov	ecx,eax
       push	edi
       push	esi
       jmp	[ y1_pixel ]
??backward_trans_line:
       REPT	32
       local	transp_pixel
       		mov	bl,[ esi ]
       		test	bl,bl
       		jz	transp_pixel
       		mov	[ edi ],bl
    	    transp_pixel:
       		dec	esi
	    	dec	edi
	ENDM
    ??back_transp_reference:
       dec	ecx
       jge	??backward_trans_line
       pop	esi
       pop	edi
       sub	esi,[ source_area ]
       sub	edi,[ dest_area ]
       dec	edx
       jge	??backward_loop_trans
       cld
       ret

??real_out:
       ret
       ENDP	Linear_Blit_To_Linear



END