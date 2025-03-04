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

; $Header:   J:\vq\projects\vqm32\textprnt.asv   1.5   27 Jul 1995 13:57:04   DENZIL_LONG  $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : TEXTPRNT.ASM                             *
;*                                                                         *
;*                   Programmer : David R. Dettmer                         *
;*                                                                         *
;*                   Start Date : January 28, 1992                         *
;*                                                                         *
;*                  Last Update : February 3, 1992   [DRD]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
;  VOID Text_Print(BYTE *string, WORD x_pixel, WORD y_pixel,               *
;                  WORD fcolor,  WORD bcolor);                             *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

XPIXEL_MAX    EQU	320
YPIXEL_MAX	EQU	200

FONTINFOBLOCK		EQU	4
FONTOFFSETBLOCK	EQU	6
FONTWIDTHBLOCK	EQU	8
FONTDATABLOCK		EQU	10
FONTHEIGHTBLOCK	EQU	12

FONTINFOMAXHEIGHT	EQU	4
FONTINFOMAXWIDTH	EQU	5

	EXTRN	C Char_Pixel_Width:NEAR
	EXTRN	C Draw_Char:NEAR
	EXTRN	C Set_Font_Palette_Range:NEAR
	EXTRN	FontPtr:NEAR PTR
	EXTRN	FontYSpacing:DWORD
	
;----------------------------------------------------------------------------
; TEXT_PRINT
;
; VOID Text_Print(BYTE *string, WORD x_pixel, WORD y_pixel,
;		  WORD fcolor,  WORD bcolor);
;
; Print the given string to the LogicPage.
;
; Bounds Checking:
;
; if x_pixel < 0, then x_pixel = 0
; if x_pixel >= XPIXEL_MAX, then exit
; if y_pixel < 0, then y_pixel = 0
; if y_pixel >= YPIXEL_MAX, then exit
;*

	GLOBAL	C Text_Print:NEAR
	PROC	Text_Print C NEAR USES ebx ecx edx edi esi
	ARG	string:NEAR PTR
	ARG	x_pixel:DWORD
	ARG	y_pixel:DWORD
	ARG	fcol:DWORD
	ARG	bcol:DWORD

	LOCAL	fwidth:DWORD	;Pixel width of font.
	LOCAL	fgbg:DWORD	;Two bytes of background & foreground colors.
	LOCAL	lines:DWORD	;Number of lines
	LOCAL	fontheight:DWORD

	; Make sure there is a font available. If not, then bail.

	xor	eax,eax
	mov	[lines],eax

	mov	eax,[FontPtr]
	or	eax,eax
	je	??exit

	movzx	ebx,[WORD PTR eax+FONTINFOBLOCK]
	add	ebx,eax
	movzx	eax,[BYTE PTR ebx+FONTINFOMAXHEIGHT]
	mov	[fontheight],eax
	mov	esi,[string]

	mov	ebx,[x_pixel]		; x pixel
	cmp	ebx,XPIXEL_MAX		; check max x pos
	jae	short ??exit

	mov	ecx,[y_pixel]		; y pixel
	cmp	ecx,YPIXEL_MAX		; check max y pos
	jge	short ??exit

	mov	al,[BYTE PTR bcol]
	mov	ah,[BYTE PTR fcol]
	mov	[fgbg],eax
	lea	eax,[fgbg]
	call	Set_Font_Palette_Range C,eax,0,1

; start of loop to print string

	xor	edx,edx
	inc	[lines]
??loop:
	mov	dl,[esi]
	inc	esi

	cmp	edx,0			; end of string
	je	short ??exit

	cmp	edx,13			; cmp to a '\r'
	jne	short ??chkxy

	; Advance the screen to the left edge and down one line. Check
	; to see if the coordinate would still be visible. If not, then
	; bail.

??onelinedown:
 	mov	ebx,[x_pixel]		; get original x position
	add	ecx,[fontheight]
	add	ecx,[FontYSpacing]
	cmp	ecx,YPIXEL_MAX	  	; check y pos
	jae	short ??exit
	inc	[lines]
	jmp	??loop

??chkxy:
	call	Char_Pixel_Width C,edx

	; Check to see if this character would spill past the right edge
	; of the screen. If it would then drop down a line.

	mov	[fwidth],eax		; save width of char for later
	add	eax,ebx

	cmp	eax,XPIXEL_MAX		; check x pos
	ja	short ??onelinedown

	call	Draw_Char C,edx,ebx,ecx

	add	ebx,[fwidth]		; add font width
	jmp	??loop

	; Exit routine and unlock string if it was in EMS.

??exit:
	mov	eax,[lines]
	ret

	ENDP	Text_Print

;----------------------------------------------------------------------------
	END

