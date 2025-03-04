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
;*                 Project Name : Draw Shape Routines for library.         *
;*                                                                         *
;*                    File Name : DS_DS.ASM                                *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : August 24, 1993                          *
;*                                                                         *
;*                  Last Update : September 6, 1994   [IML]                *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Draw_Scale -- Draws a scaled row of pixels to the viewport            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
IDEAL
P386
MODEL USE32 FLAT


;******************************** Includes *********************************
INCLUDE "shape.inc"


;********************************* Code ************************************
	CODESEG

;***************************************************************************
;* Draw_Scale -- Draws a scaled row of pixels to the viewport              *
;*                                                                         *
;* INPUT:								   *
;*		ECX = number of pixels (not bytes) to draw		   *
;*		EDX = XTotal initializer value				   *
;*		ESI = shape (source) buffer address			   *
;*		EDI = viewport (destination) address			   *
;*		[WidthCount] = remaining bytes on the line		   *
;*									   *
;* OUTPUT:      							   *
;*		ESI - updated to current location in the shape data	   *
;*		EDI - incr/decr by # pixels (not bytes) drawn/skipped	   *
;*		[WidthCount] - bytes remaining on the line		   *
;*                                                                         *
;* WARNINGS:    none                                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/14/1992 PWG : Created.                                             *
;*   08/19/1993 SKB : Split drawshp.asm into several modules.              *
;*   06/02/1994 BR  : Converted to 32-bit.                                 *
;*   08/09/1994 IML : Optimized for 32-bit.				   *
;*   09/06/1994 IML : Integrated p_* and ds_* routines.			   *
;*=========================================================================*
PROC	Draw_Scale NOLANGUAGE NEAR

	mov	eax,0				; init to 0
	test	[Flags],SHAPE_EFFECTS
	jnz	short ??general_draw_continue
	jmp	short ??fast_draw_continue


	;--------------------------------------------------------------------
	; Extra fast draw loop for shapes with no flags set.
	;--------------------------------------------------------------------
	
	;--------------------------------------------------------------------
	; Load a new byte:
	; - read the byte into AL
	; - if it's a run, deal with it
	; - otherwise, 
	;	- decrement [WidthCount]
	;	- update EDX with [ScaleX]
	;	- see if it's drawable (upon proc entry, it won't be)
	;		- yes: draw a pixel
	;		- no : load a new byte
	;--------------------------------------------------------------------
??fast_draw_loop:
	mov	al,[esi]			; get the next pixel from the source
	inc	esi
	or	eax,eax
	jz	short ??fast_is_run		; deal with a run
	dec	[WidthCount]			; count down # bytes processed
	add	edx,[ScaleX]			; add in the scale value

??fast_draw_continue:
	or	dh,dh				; are there any pixels to draw?
	jz	short ??fast_draw_loop


	;--------------------------------------------------------------------
	; Draw one pixel:
	; - draw the pixel
	; - increment destination pointer
	; - decrement high byte of EDX (X-scale accumulator)
	; - loop (while ECX>0) to see if it's drawable
	;--------------------------------------------------------------------
	mov	[edi],al			; store color value to viewport
	inc	edi				; increment the destination index
	dec	dh				; decrement the pixels to write
	dec	ecx
	jnz	short ??fast_draw_continue
	jmp	??out				; get the heck outta here


	;--------------------------------------------------------------------
	; Handle a run:
	; - Get the run repetition value
	; - subract it from [WidthCount]
	; - multiply it by [ScaleX]
	; - put high bytes from mul into EAX, low byte into DL (roundoff bits)
	; - add high bytes (# pixels) to EDI
	; - subtract them from ECX
	; - clear EAX
	; - if ECX>0, go get next byte
	;--------------------------------------------------------------------
??fast_is_run:
	mov	al,[esi]			; get number of repeated values
	inc	esi
	sub	[WidthCount],eax		; adjust the remaining byte width
	mov	ebx,edx				; preserve dx for the multiply
	mul	[ScaleX]			; EDX:EAX = # pixels + roundoff bits
	add	eax,ebx				; add in the current x-total
	mov	edx,eax				; (assume EDX is empty)
	shr	eax,8				; EAX = # pixels skipped
	and	edx,00FFh			; keep only low byte
	add	edi,eax				; add to EDI
     	sub	ecx,eax				; subtract it from ECX
	mov	eax,0				; clear EAX
	or	ecx,ecx
	jg	short ??fast_draw_loop		; if more to draw, process new byte
	jmp	??out


	;--------------------------------------------------------------------
	; General purpose draw loop for shapes with one or more flags set.
	;--------------------------------------------------------------------

	;--------------------------------------------------------------------
	; Load a new byte:
	; - read the byte into AL
	; - if it's a run, deal with it
	; - otherwise, 
	;	- decrement [WidthCount]
	;	- update EDX with [ScaleX]
	;	- see if it's drawable (upon proc entry, it won't be)
	;		- yes: draw a pixel
	;		- no : load a new byte
	;--------------------------------------------------------------------
??general_draw_loop:
	mov	al,[esi]			; get the next pixel from the source
	inc	esi
	or	eax,eax
	jz	??general_is_run		; deal with a run
	dec	[WidthCount]			; count down # bytes processed
	add	edx,[ScaleX]			; add in the scale value

??general_draw_continue:
	or	dh,dh				; are there any pixels to draw?
	jz	short ??general_draw_loop

	;--------------------------------------------------------------------
	; Draw one pixel:
	; - draw the pixel
	; - increment destination pointer
	; - decrement high byte of EDX (X-scale accumulator)
	; - loop (while ECX>0) to see if it's drawable
	;--------------------------------------------------------------------
??draw:
	mov	[StashReg],eax			; save eax
	mov	[StashEDX],edx			; save edx
	mov	edx,[Flags]

??test_priority:
	test	edx,SHAPE_PRIORITY		
	jnz	short ??priority

??test_predator:
	test	edx,SHAPE_PREDATOR
	jnz	short ??predator

??test_compact:
	test	edx,SHAPE_COMPACT
	jnz	??compact

??test_shadow:
	test	edx,SHAPE_SHADOW
	jnz	??shadow

??test_translucency:
	test	edx,SHAPE_GHOST
	jnz	??translucency

??test_fading:
	test	edx,SHAPE_FADING
	jnz	??fading


??test_transparency:	
	test	edx,SHAPE_FADING		; if fading is enabled test for
	jz	short ??no_fading_draw_loop	;   transparency
	or	eax,eax
	jz	short ??is_transparent

??no_fading_draw_loop:
	mov	[edi],al			; store color value to viewport
	
??is_transparent:
	mov	eax,[StashReg]			; restore eax
	mov	edx,[StashEDX]			; restore edx
	inc	edi				; increment the destination index
	dec	dh				; decrement the pixels to write
	dec	ecx
	jnz	??general_draw_continue
	jmp	??out				; get the heck outta here

??priority:	
	mov	ebx,[MaskAdjust]		; get mask page	offset
	mov	bl,[BYTE PTR ebx + edi]		; get mask value  

	and	bl,CLEAR_UNUSED_BITS		; clear unused bits

	cmp	[PriLevel],bl			; are we in front of
	jge	short ??test_predator		;  background?

	mov	ebx,[BackAdjust]		; get background page offset
	mov	al,[BYTE PTR ebx + edi]		; get background pixel
	jmp	short ??test_transparency

??predator:
	mov	ebx,[PartialCount]
	add	ebx,[PartialPred]	
	or	bh,bh
	jnz	short ??draw_pred		; is this a predator pixel?
	mov	[PartialCount],ebx
	jmp	??test_compact

??draw_pred:
	xor	bh,bh
	mov	[PartialCount],ebx
	mov	ebx,[PredValue]			; pick up a color offset a pseudo-
						;  random amount from the current
	mov	al,[edi + ebx]			;  viewport address
	jmp	short ??test_transparency

??compact:
	mov	ebx,[ColorTable]		; get the address of the color table
	mov	al,[BYTE PTR ebx + eax]		; convert it into the proper byte
	jmp	??test_shadow

??shadow:
	cmp	al,SHADOW_COL
	jne	??test_translucency		; is the table value a magic number?

	mov	al,[edi]			; get the destination color and
	mov	ebx,[ShadowingTable]		;  index into the shadow table
	mov	al,[BYTE PTR ebx + eax]
	jmp	??test_transparency			

??fading:
	mov	[StashECX],ecx			; preserve ecx for later
	mov	ebx,[FadingTable]		; run color through fading table
	mov	ecx,[FadingNum]

??fade_loop:
	mov	al, [BYTE PTR ebx + eax]
	dec	ecx
	jnz	short ??fade_loop

	mov	ecx,[StashECX]			; restore ecx for main draw loop
	jmp	??test_transparency

??translucency:
	mov	ebx,[IsTranslucent]		; is it a translucent color?
	mov	bh,[BYTE PTR ebx + eax]
	or	bh,bh
	js	??test_fading

	and	ebx,0FF00h			; clear all of ebx except bh
						; we have the index to the translation table
						; ((trans_colour * 256) + dest colour)
	mov	al,[edi]			; mov pixel at destination to al
	add	ebx,[Translucent]		; get the ptr to it!
						; Add the (trans_color * 256) of the translation equ.
	mov	al,[BYTE PTR ebx + eax]		; get new pixel in al
	jmp	??test_fading


	;--------------------------------------------------------------------
	; Handle a run:
	; - Get the run repetition value
	; - subract it from [WidthCount]
	; - multiply it by [ScaleX]
	; - put high bytes from mul into EAX, low byte into DL (roundoff bits)
	; - add high bytes (# pixels) to EDI
	; - subtract them from ECX
	; - clear EAX
	; - if ECX>0, go get next byte
	;--------------------------------------------------------------------
??general_is_run:
	mov	al,[esi]			; get number of repeated values
	inc	esi
	sub	[WidthCount],eax		; adjust the remaining byte width
	mov	ebx,edx				; preserve dx for the multiply
	mul	[ScaleX]			; EDX:EAX = # pixels + roundoff bits
	add	eax,ebx				; add in the current x-total
	mov	edx,eax				; (assume EDX is empty)
	shr	eax,8				; EAX = # pixels skipped
	and	edx,00FFh			; keep only low byte
	add	edi,eax				; add to EDI
     	sub	ecx,eax				; subtract it from ECX
	mov	eax,0				; clear EAX
	or	ecx,ecx
	jg	??general_draw_loop		; if more to draw, process new byte

??out:
	ret					; lets get out of here

	ENDP	Draw_Scale

	END

;**************************** End of ds_ds.asm ******************************
