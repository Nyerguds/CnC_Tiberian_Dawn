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
;*                    File Name : DS_DR.ASM                                *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : August 24, 1993                          *
;*                                                                         *
;*                  Last Update : September 6, 1994   [IML]                *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Draw_Reverse -- Draws a reversed row of pixels to the viewport        *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
IDEAL
P386
MODEL USE32 FLAT


;******************************** Includes *********************************
INCLUDE "shape.inc"


;********************************* Code ************************************
	CODESEG

;***************************************************************************
;* Draw_Reverse -- Draws a reversed row of pixels to the viewport          *
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
;*   06/02/1994 BR  : Converted to 32-bit.				   *	
;*   08/09/1994 IML : Optimized for 32-bit.				   *
;*   09/06/1994 IML : Integrated p_* and ds_* routines.			   *
;*=========================================================================*
PROC	Draw_Reverse NOLANGUAGE NEAR

	mov	[StashEDX],edx			; save edx
	mov	edx,[Flags]			
	mov	eax,0				; init to zero
	sub	[WidthCount],ecx		; decrement bytes remaining by pixels
						;   to draw

	;--------------------------------------------------------------------
	; Drawing Loop:
	; - Get a data byte
	; - If it's a 0, handle the run:
	;	- get repetition value
	;	- subtract it from EDI
	;	- subtract it from [WidthCount]
	;	- subtract it from ECX
	;	- if ECX>0, draw again, else exit
	; - Otherwise:
	;	- draw the pixel
	;	- increment EDI to next pixel location
	;	- decrement [WidthCount]
	;	- loop until ECX is 0
	;--------------------------------------------------------------------
	test	edx,SHAPE_EFFECTS		; are any effects flags set?
	jnz	short ??general_draw_continue	;   if so use the general purpose loop


	;--------------------------------------------------------------------
	; Extra fast draw loop for shapes with no flags set.
	;--------------------------------------------------------------------
??fast_draw_loop:
	mov	al,[esi]			; get a byte of the source
	inc	esi
	or	eax,eax				; is the byte a transparent run?
	jz	short ??fast_is_run		;   if yes then handle the run
	mov	[edi],al			; store color value to viewport
	dec	edi				; point to next viewport pixel
	dec	ecx				; any source pixels left?
	jnz	short ??fast_draw_loop		;   if not then go home
	jmp	??out

??fast_is_run:
	mov	al,[esi]
	inc	esi
	sub	edi,eax				; move the viewport pointer
	sub	ecx,eax				; chop down the width to do
	jg	short ??fast_draw_loop		; while more to do, loop back up
	jmp	??out


	;--------------------------------------------------------------------
	; General purpose draw loop for shapes with one or more flags set.
	;--------------------------------------------------------------------
??general_draw_loop:
	test	edx,SHAPE_FADING		; if fading is enabled test for
	jz	short ??no_fading_draw_loop	;   transparency
	or	eax,eax
	jz	short ??is_transparent

??no_fading_draw_loop:	
	mov	[edi],al			; store color value to viewport

??is_transparent:
	dec	edi				; point to next viewport pixel
	dec	ecx				; any source pixels left?
	jz	??out				;   if not then go home

??general_draw_continue:
	mov	al,[esi]			; get a byte of the source
	inc	esi
	or	eax,eax				; is the byte a transparent run?
	jz	??general_is_run		;   if yes then handle the run
	
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
	jz	short ??test_fading

	mov	ebx,[IsTranslucent]		; is it a translucent color?
	mov	bh,[BYTE PTR ebx + eax]
	or	bh,bh
	js	short ??test_fading		

	and	ebx,0FF00h			; clear all of ebx except bh
						; we have the index to the translation table
						; ((trans_colour * 256) + dest colour)
	mov	al,[edi]			; mov pixel at destination to al
	add	ebx,[Translucent]		; get the ptr to it!
						; Add the (trans_color * 256) of the translation equ.
	mov	al,[BYTE PTR ebx + eax]		; get new pixel in al

??test_fading:
	test	edx,SHAPE_FADING
	jnz	??fading
	jmp	short ??general_draw_loop

??priority:	
	mov	ebx,[MaskAdjust]		; get mask page	offset
	mov	bl,[BYTE PTR ebx + edi]		; get mask value  

	and	bl,CLEAR_UNUSED_BITS		; clear unused bits

	cmp	[PriLevel],bl			; are we in front of
	jge	short ??test_predator		;  background?

	mov	ebx,[BackAdjust]		; get background page offset
	mov	al,[BYTE PTR ebx + edi]		; get background pixel
	jmp	??general_draw_loop

??predator:
	mov	ebx,[PartialCount]
	add	ebx,[PartialPred]	
	or	bh,bh
	jnz	short ??draw_pred		; is this a predator pixel?
	mov	[PartialCount],ebx
	jmp	short ??test_compact

??draw_pred:
	xor	bh,bh
	mov	[PartialCount],ebx
	mov	ebx,[PredValue]			; pick up a color offset a pseudo-
						;  random amount from the current
	mov	al,[edi + ebx]			;  viewport address
	jmp	??general_draw_loop

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
	jmp	??general_draw_loop			

??fading:
	mov	[StashECX],ecx			; preserve ecx for later
	mov	ebx,[FadingTable]		; run color through fading table
	mov	ecx,[FadingNum]

??fade_loop:
	mov	al, [BYTE PTR ebx + eax]
	dec	ecx
	jnz	short ??fade_loop

	mov	ecx,[StashECX]			; restore ecx for main draw loop
	jmp	??general_draw_loop			

??general_is_run:
	mov	al,[esi]
	inc	esi
	sub	edi,eax				; move the viewport pointer
	sub	ecx,eax				; chop down the width to do
	jg	??general_draw_continue			; while more to do, loop back up

??out:	
	add	[WidthCount],ecx		; adjust for source ending in a run
	mov	edx,[StashEDX]
	ret	

	ENDP	Draw_Reverse


	END

;**************************** End of ds_dr.asm *****************************
