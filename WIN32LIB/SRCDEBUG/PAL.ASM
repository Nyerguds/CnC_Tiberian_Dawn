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
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : PAL.ASM                                  *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : May 30, 1992                             *
;*                                                                         *
;*                  Last Update : April 27, 1994   [BR]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Set_Palette_Range -- Sets changed values in the palette.              *
;*   Bump_Color -- adjusts specified color in specified palette            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************** Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT


;include "keyboard.inc"
FALSE = 0
TRUE  = 1

;****************************** Declarations ********************************
GLOBAL 		C Set_Palette_Range:NEAR
GLOBAL 		C Bump_Color:NEAR
GLOBAL  	C CurrentPalette:BYTE:768
GLOBAL		C PaletteTable:byte:1024


;********************************** Data ************************************
LOCALS ??

	DATASEG

CurrentPalette	DB	768 DUP(255)	; copy of current values of DAC regs
PaletteTable	DB	1024 DUP(0)

IFNDEF LIB_EXTERNS_RESOLVED
VertBlank	DW	0		; !!!! this should go away
ENDIF


;********************************** Code ************************************
	CODESEG



IF 1
;***************************************************************************
;* SET_PALETTE_RANGE -- Sets a palette range to the new pal                *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:	This routine is optimized for changing a small number of   *
;*		colors in the palette.
;*                                                                         *
;* HISTORY:                                                                *
;*   03/07/1995 PWG : Created.                                             *
;*=========================================================================*

	PROC	Set_Palette_Range C NEAR
	ARG	palette:DWORD

	GLOBAL	Set_DD_Palette_:near
	GLOBAL	Wait_Vert_Blank_:near

	pushad
	mov	esi,[palette]
	mov	ecx,768/4
	mov	edi,offset CurrentPalette
	cld
	rep	movsd
	;call	Wait_Vert_Blank_
	mov	eax,[palette]
	call	Set_DD_Palette_
	popad
	ret


ifdef NOT_FOR_WIN95
	USES	eax,ebx,ecx,edx,edi,esi

	cld

	;*=================================================================*/
	;* Set up pointers to begin making palette comparison		   */
	;*=================================================================*/
	mov	esi, [palette]
	mov	edi, OFFSET CurrentPalette
	mov	ebx, OFFSET PaletteTable
	mov	ecx, 0

??loop_top:
	mov	eax,[esi]			; read a dword from palette source
	mov	edx,[edi]			; read a dword from compare palette
	and	eax,00FFFFFFh			; palette entrys are only 3 bytes
	and	edx,00FFFFFFh			;   long so and of extra
	cmp	eax,edx				; if they are not the same then
	jne	??set_table			;   add them into the table
	add	esi,3
	add	edi,3
	inc	cl				; adjust to next palette entry
	jnz	??loop_top			; if we dont wrap to zero we have more
	jmp	??set_pal			; so now go set the palette
??set_table:
	shl	eax,8				; shift bgr value up register
	mov	al,cl				; store which palette entry num
	mov	[ebx],eax
	add	ebx,4
	movsw					; copy the three gun values into
	movsb					;  the shadow palette.  Use movsb
	inc	cl				; adjust to next palette entry
	jnz	??loop_top			; if we dont wrap to zero we have more

??set_pal:
	mov	esi,ebx
	mov	ebx,OFFSET PaletteTable
	sub	esi,ebx				; if ebx didn't change there
	jz	??exit				;   is nothing to set
	shr	esi,2				; find how many entrys

	mov	eax,[ebx]

	movzx	ecx,al				; we are currently on entry 0
	add	ebx,4

	; Tell DAC of the color gun to start setting.
	mov	edx,03C8h
	out	dx,al		; First color set.

	; Set the colors only during a VSync.
	mov	edx,03DAh	; CRTC register.

	push	ebx
	mov	bx,[VertBlank]
	and	bl,001h
	shl	bl,3

??in_vbi:
	in	al,dx				; read CRTC status
	and	al,008h				; only vertical sync bit
	xor	al,bl
	je	??in_vbi			; in vertical sync

??out_vbi:
	in	al,dx				; read CRTC status
	and	al,008h				; only vertical sync bit
	xor	al,bl
	jne	??out_vbi			; not in vertical sync
	pop	ebx
	; Update the DAC data register.
	mov	dx,03C9h

;**************** Time Critical Section Start ******************
	cli
??loop:
	shr	eax,8		; shift down the red gun value
	out	dx,al		; write it to the video card
	jmp	$ + 2		; force cache to flush, to create a time
	shr	eax,8		; shift down the blue gun value
	out	dx,al		; write it to the video card
	jmp	$ + 2		; force cache to flush, to create a time
	shr	eax,8		; shift down the blue gun value
	out	dx,al		; write the green value to video card
	jmp	$ + 2		; force cache to flush, to create a time
	inc	ecx		; move edx to next palette entry

	mov	eax,[ebx]	; get next value to set
	add	ebx,4		;  and post increment the palette value
	cmp	al,cl		; check if DAC position already correct
	je	??correct_pos

	mov	edx,03C8h	; Tell DAC of the color gun to start setting.
	out	dx,al		; First color set.
	mov	dx,03C9h

??correct_pos:
	dec	esi
	jnz	??loop
	sti
;***************** Time Critical Section End *******************
??exit:
	ret
endif	;NOT_FOR_WIN95

	ENDP	Set_Palette_Range
ELSE
;***************************************************************************
;* Set_Palette_Range -- Sets changed values in the palette.                *
;*                                                                         *
;* INPUT: 								   *
;*	VOID *palette - pointer to the new palette.                        *
;*                                                                         *
;* OUTPUT:                                                                 *
;*	none								   *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/25/1994 SKB : Created.                                             *
;*   04/27/1994 BR : Converted to 32-bit                                   *
;*=========================================================================*
; VOID cdecl Set_Palette_Range(VOID *palette);
	PROC Set_Palette_Range	C NEAR
	USES eax,ebx,ecx,edx,edi,esi
	ARG	palette:DWORD
	LOCAL	remain:DWORD	; 32-bit: converted to LONG

	cld

	mov	bx,[VertBlank]
	and	bl,001h
	shl	bl,3

	; Make a copy of the palette passed in.
	mov	edi,OFFSET CurrentPalette
	mov	esi,[palette]
	mov	[remain],768

	; Search for differences between the current palette and the
	; new palette.  When a difference is found, output a block
	; of color registers and keep scanning.
??bodyloop:
	mov	ecx,[remain]

	repe	cmpsb		; Search for differences.
	je	short ??exit
	dec	esi
	dec	edi
	inc	ecx

	mov	edx,0		; clear EDX
	mov	eax,ecx
	mov	ecx,3
	div	ecx		; EAX = # of colors to set, EDX = Fraction.
	or	edx,edx
	jz	short ??nofrac
	neg	edx
	add	edx,3		; Back offset skip needed.
	inc	eax		; Fractional color rounds up to whole color to set.
??nofrac:

	; Set CX to be the number of color guns to set.
	mov	ecx,eax		; Colors * 3 bytes per color.
	add	ecx,eax
	add	ecx,eax

	; Chop this DAC dump short if necessary in order to reduce
	; sparkling.
	mov	[remain],0
	cmp	ecx,86*3	; Number of color guns to set per vert retrace
	jbe	short ??ok
	sub	ecx,86*3
	mov	[remain],ecx
	mov	ecx,86*3
??ok:

	; Adjust the palette offsets back to point to the RED color gun.
	sub	esi,edx
	sub	edi,edx

	; Determine the color number to start setting.
	neg	eax
	add	eax,256		; AX = Color to start setting (0..255).

	; Tell DAC of the color gun to start setting.
	mov	edx,03C8h
	out	dx,al		; First color set.

	; Set the colors only during a VSync.
	mov	edx,03DAh	; CRTC register.

??in_vbi:
	in	al,dx		; read CRTC status
	and	al,008h		; only vertical sync bit
	xor	al,bl
	je	??in_vbi	; in vertical sync

??out_vbi:
	in	al,dx		; read CRTC status
	and	al,008h		; only vertical sync bit
	xor	al,bl
	jne	??out_vbi	; not in vertical sync

;??wait:
;	in	al,dx
;	test	al,01000b
;	jnz	??wait

;??retrace:
;	in	al,dx
;	test	al,01000b
;	jz	??retrace

	; Update the DAC data register.
	mov	dx,03C9h

;**************** Time Critical Section Start ******************
	pushf
	cli
??loop:
	lodsb
	stosb
	out	dx,al
	jmp	$ + 2		; force cache to flush, to create a time
				;  delay to give DAC time to get value
	loop	??loop
	popf
;***************** Time Critical Section End *******************

	cmp	[remain],0
	jnz	??bodyloop

??exit:
	ret

	ENDP	Set_Palette_Range
ENDIF



;***************************************************************************
;* Bump_Color -- adjusts specified color in specified palette              *
;*                                                                         *
;* INPUT:                                                                  *
;*	VOID *palette	- palette to modify				   *
;*	WORD changable	- color # to change				   *
;*	WORD target	- color to bend toward				   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/27/1994 BR : Converted to 32-bit.                                  *
;*=========================================================================*
; BOOL cdecl Bump_Color(VOID *palette, WORD changable, WORD target);
PROC Bump_Color C NEAR
	USES ebx,ecx,edi,esi
	ARG	pal:DWORD, color:WORD, desired:WORD
	LOCAL	changed:WORD		; Has palette changed?

	mov	edi,[pal]		; Original palette pointer.
	mov	esi,edi
	mov	eax,0
	mov	ax,[color]
	add	edi,eax
	add	edi,eax
	add	edi,eax			; Offset to changable color.
	mov	ax,[desired]
	add	esi,eax
	add	esi,eax
	add	esi,eax			; Offset to target color.

	mov	[changed],FALSE		; Presume no change.
	mov	ecx,3			; Three color guns.

	; Check the color gun.
??colorloop:
	mov	al,[BYTE PTR esi]
	sub	al,[BYTE PTR edi]	; Carry flag is set if subtraction needed.
	jz	short ??gotit
	mov	[changed],TRUE
	inc	[BYTE PTR edi]		; Presume addition.
	jnc	short ??gotit		; oops, subtraction needed so dec twice.
	dec	[BYTE PTR edi]
	dec	[BYTE PTR edi]
??gotit:
	inc	edi
	inc	esi
	loop	??colorloop

	mov	ax,[changed]
	ret

	ENDP	Bump_Color

	END

;*************************** End of pal.asm ********************************

