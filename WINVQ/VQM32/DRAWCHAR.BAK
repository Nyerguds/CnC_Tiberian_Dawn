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

; $Header:   U:\vq\projects\vqm32\drawchar.asv   1.1   08 May 1995 10:48:32   DENZIL_LONG  $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : DRAWCHAR.ASM                             *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : August 20, 1993                          *
;*                                                                         *
;*                  Last Update : August 20, 1993   [JLB]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

XPIXEL_MAX		EQU	320
YPIXEL_MAX		EQU	200

FONTINFOBLOCK		EQU	4
FONTOFFSETBLOCK	EQU	6
FONTWIDTHBLOCK	EQU	8
FONTDATABLOCK		EQU	10
FONTHEIGHTBLOCK	EQU	12

FONTINFOMAXHEIGHT	EQU	4
FONTINFOMAXWIDTH	EQU	5

	EXTRN	FontPtr:NEAR PTR

;***********************************************************
; DRAW_CHAR
;
; VOID Draw_Char(BYTE fontchar, WORD x_pixel, WORD y_pixel);
;
; Draws a character to the screen only if given coordinates that will allow
; the entire character to be drawn on the screen else will exit.
; 
; NOTE: This is a routine called by Text_Print.
;
;*
	GLOBAL	C Draw_Char:NEAR
	PROC	Draw_Char C NEAR USES eax ebx ecx edx esi edi 
	ARG	fontchar:DWORD
	ARG	x_pixel:DWORD
	ARG	y_pixel:DWORD

	LOCAL	infoblock:DWORD
	LOCAL	offsetblock:DWORD
	LOCAL	widthblock:DWORD
	LOCAL	heightblock:DWORD
	LOCAL	fwidth:DWORD
	LOCAL	nextline:DWORD
	LOCAL	startv:BYTE
	LOCAL	dheight:BYTE
	LOCAL	wheight:BYTE

	mov	esi,[FontPtr]

	; Set up some working local variables.

	xor	eax,eax
	mov	ax,[esi+FONTINFOBLOCK]	; get offset to info block
	mov	[infoblock],eax		; save offset to info block
	mov	ax,[esi+FONTOFFSETBLOCK]	; get offset to offset block
	mov	[offsetblock],eax		; save offset to offset block
	mov	ax,[esi+FONTWIDTHBLOCK]	; get offset to width block
	mov	[widthblock],eax		; save offset to width block
	mov	ax,[esi+FONTHEIGHTBLOCK]	; get offset to height block
	mov	[heightblock],eax		; save offset to height block

	; Fetch character data offset -- if NULL then undefined character.

	mov	ebx,[fontchar]
	and	ebx,0FFh
	shl	ebx,1		; make word index
	add	ebx,[offsetblock]	; add offset to offset block
	xor	ecx,ecx
	mov	cx,[esi+ebx]		; load offset to font data
	or	ecx,ecx
	jz	??exit		; is this character a null? if so exit

	; If the character is off the left/right edge of the screen then abort.

	mov	edx,[x_pixel]
	cmp	edx,XPIXEL_MAX
	jae	??exit

	; If the character is off the top/bottom edge of the screen then abort.

	mov	ebx,[fontchar]		; get char
	and	ebx,0FFh
	add	ebx,[widthblock]	; add offset to width block
	xor	eax,eax
	mov	al,[esi+ebx]		; get width for character
	mov	[fwidth],eax		; save char width
	add	eax,edx		; ax = char len + x
	cmp	eax,XPIXEL_MAX
	ja	??exit

	mov	edi,edx		; save xpos in di

	mov	edx,[y_pixel]
	cmp	edx,YPIXEL_MAX
	jae	??exit

	mov	ebx,[infoblock]	; get offset to offset block
	xor	eax,eax
				; get font max height from info block
	mov	al,[esi+ebx+FONTINFOMAXHEIGHT]
	mov	[wheight],al		; save max height of character
	add	eax,edx		; add height to y pos
	cmp	eax,YPIXEL_MAX		; will it go off the bottom
	ja	??exit

??vdraw:
	mov	ebx,[fontchar]		; get char
	and	ebx,0FFh
	shl	ebx,1		; make 2 byte index
	add	ebx,[heightblock]	; add offset to height block
	mov	ah,[esi+ebx]		; get start vertical for character
	mov	[startv],ah		; save start vertical for later
	mov	al,[esi+ebx+1]		; get data height for character
	mov	[dheight],al		; save data height for later
	add	ah,al		; add background and data
	sub	[wheight],ah		; remaining background height

	add	esi,ecx		; add font offset to font data

	push	edx
	mov	eax,XPIXEL_MAX
	mul	edx
	add	edi,eax
	pop	edx

	mov	eax,XPIXEL_MAX
	sub	eax,[fwidth]
	mov	[nextline],eax		; ?? to add to index for the nextline

	add	edi,0A0000h
	mov	ebx,OFFSET ColorXlat	; setup up bx for xlat commands
	xor	ecx,ecx
	mov	cl,[startv]		; number of scan lines that are
				; background color
	or	ecx,ecx		; if starting vertical is zero
	je	short ??skiplead	; skip drawing top background lines

	mov	al,0
	xlat	[ebx]		; get background color

	or	al,al		; check for none zero color
	jne	short ??lheight	; update background color

	push	edx
	mov	eax,XPIXEL_MAX
	mul	ecx
	add	edi,eax
	pop	edx

	mov	ebx,OFFSET ColorXlat	; restore bx for xlat commands
	jmp	SHORT ??skiplead

??lheight:
	mov	edx,[fwidth]		; width of char

??lwidth:
	stosb			; write out line of pixels for width
	dec	edx
	jne	??lwidth

??lnext:
	add	edi,[nextline]		; goto next line at the start of char
	loop	??lheight		; any more lines

??skiplead:
	mov	cl,[dheight]		; number of scan lines that are data
	or	ecx,ecx		; is there any data to be drawn
	je	short ??exit

??vheight:
	mov	edx,[fwidth]		; width of char

??vwidth:
	lodsb				; get byte value from font data
	mov	ah,al			; save hinibble
	and	al,00FH			; get lonibble
	xlat	[ebx]			; get new color
	or	al,al
	je	short ??chklowidth		; skip color zero

	mov	[edi],al		; write out pixel of lonibble

??chklowidth:
	inc	edi
	dec	edx
	je	short ??vnext			; check if done with width of char

	mov	al,ah			; get byte value
	and	al,0F0H			; get hinibble
	xlat	[ebx]			; get new color
	or	al,al
	je	short ??chkhiwidth		; skip color zero

	mov	[edi],al		; write out pixel of hinibble

??chkhiwidth:
	inc	edi
	dec	edx
	jne	??vwidth		; check if done with width of char

??vnext:
	add	edi,[nextline]		; next line at start of char
	loop	??vheight		; any more lines


??trail:
	mov	cl,[wheight]		; remaining height of background color
	or	ecx,ecx			; if trailing height is zero
	jle	short ??exit			; skip drawing bottom background lines

	mov	al,0
	xlat	[ebx]			; get background color
	or	al,al			; check for color zero
	je	short ??exit			; skip drawing

??theight:
	mov	edx,[fwidth]		; width of char

??twidth:
	stosb				; write out line of pixels for width
	dec	edx
	jne	??twidth

??tnext:
	add	edi,[nextline]		; next line at start of char
	loop	??theight		; any more lines


??exit:
	ret

	ENDP	Draw_Char

;***********************************************************


;***********************************************************
; SET_FONT_PALETTE_RANGE
;
; VOID Set_Font_Palette_Range(VOID *palette, WORD start, WORD end);
;
; This routine changes the local Draw_Char color translation table
; with the color numbers in palette.
;
; Bounds Checking: forces start and end to a range of 0-15
;*
	GLOBAL	C Set_Font_Palette_Range:NEAR
	PROC	Set_Font_Palette_Range C NEAR USES eax ebx ecx edi esi
	ARG	palette:NEAR PTR
	ARG	start:DWORD
	ARG	endval:DWORD

	cld
	mov	esi,[palette]
	mov	ebx,[start]
	and	ebx,0FH			; value 0-15

	mov	ecx,[endval]
	and	ecx,0FH			; value 0-15

	cmp	ecx,ebx			; if end < start then exit
	jl	short ??exit

	sub	ecx,ebx			; number of colors = end - start + 1
	inc	ecx

	mov	edi,OFFSET ColorXlat	; get start of xlat table
	add	edi,ebx			; add starting offset
	shl	ebx,4			; multiply start offset by 16
	add	ebx,OFFSET ColorXlat	; add start of xlat table

; updates 0-15 for lonibble xlat
; updates 0,16,32,...,240 for hinibble xlat

??setpal:
	lodsb				; get color number
	stosb				; save color number for lonibble xlat
	mov	[ebx],al		; save color number for hinibble xlat
	add	ebx,010H			; add 16 to index for hinibble offset
	loop	??setpal

??exit:
	ret

	ENDP	Set_Font_Palette_Range

;***********************************************************


;***********************************************************
; DRAW_CHAR_SETUP
;
; VOID Draw_Char_Setup(VOID);
;
; This routine sets up code segment variables for Draw_Char.
; 
; NOTE: This is a routine called by Set_Font.
;
;*
	GLOBAL	C Draw_Char_Setup:NEAR
	PROC	Draw_Char_Setup C NEAR

	ret

	ENDP	Draw_Char_Setup

	DATASEG

ColorXlat	DB	000H,001H,002H,003H,004H,005H,006H,007H
	DB	008H,009H,00AH,00BH,00CH,00DH,00EH,00FH

	DB	001H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	002H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	003H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	004H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	005H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	006H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	007H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	008H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	009H,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00AH,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00BH,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00CH,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00DH,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00EH,000H,000H,000H,000H,000H,000H,000H
	DB	000H,000H,000H,000H,000H,000H,000H,000H

	DB	00FH

;***********************************************************
	END

