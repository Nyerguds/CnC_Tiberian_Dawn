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

;****************************************************************************
;*
;*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
;*
;*---------------------------------------------------------------------------
;*
;* FILE
;*     fillrect.asm
;*
;* DESCRIPTION
;*     Rectangle rendering.
;*
;* PROGRAMMER
;*     Joe L. Bostic
;*
;* DATE
;*     Febuary 8, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     Fill_Rect - Draw a filled rectangle.
;*     Eor_Region - Hilights or unhilights a region by EOR it.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

;****************************************************************************
;*
;* NAME
;*     Eor_Region - Hilights or unhilights a region by EOR it.
;*
;* SYNOPSIS
;*     Eor_Region(X1, Y1, X2, Y2, Color)
;*
;*     void Eor_Region(long, long, long, long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     X1    - Starting X position.
;*     Y1    - Starting Y position.
;*     X2    - Ending X position.
;*     Y2    - Ending Y position.
;*     Color - Color to EOR.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Eor_Region:NEAR
	PROC	Eor_Region C NEAR USES eax ebx ecx edx edi
	ARG	x1_pixel:DWORD
	ARG	y1_pixel:DWORD
	ARG	x2_pixel:DWORD
	ARG	y2_pixel:DWORD
	ARG	color:DWORD
	LOCAL	eorit:DWORD

	mov	[eorit],1
	jmp	short Fill_Rect_Entry

	ENDP	Eor_Region


;****************************************************************************
;*
;* NAME
;*     Fill_Rect - Draw a filled rectangle.
;*
;* SYNOPSIS
;*     Fill_Rect(X1, Y1, X2, Y2, Color)
;*
;*     void Fill_Rect(long, long, long, long, long);
;*
;* FUNCTION
;*     Fill a rectangle area with a specified color.
;*
;* INPUTS
;*     X1    - Starting X position.
;*     Y1    - Starting Y position.
;*     X2    - Ending X position.
;*     Y2    - Ending Y position.
;*     Color - Color to draw rectangle
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Fill_Rect:NEAR
	PROC	Fill_Rect C NEAR USES eax ebx ecx edx edi
	ARG	x1_pixel:DWORD
	ARG	y1_pixel:DWORD
	ARG	x2_pixel:DWORD
	ARG	y2_pixel:DWORD
	ARG	color:DWORD
	LOCAL	eorit:DWORD

	mov	[eorit],0

Fill_Rect_Entry:
	cld			; always go forward
	mov	edi,0A0000h

	; Verify bounds of x1_pixel.
	mov	eax,[x1_pixel]
	cmp	eax,320	;XPIXEL_MAX
	jae	short ??exit

	; Verify bounds of x2_pixel.
	mov	ebx,[x2_pixel]
	cmp	ebx,320	;XPIXEL_MAX
	jae	short ??exit

	; Backward rectangles are legal -- adjust for it.
	cmp	eax,ebx
	jbe	short ??okx
	xchg	eax,ebx
??okx:

	; Verify bounds of y1_pixel.
	mov	ecx,[y1_pixel]
	cmp	ecx,200	;YPIXEL_MAX
	jae	short ??exit

	; Verify bounds of y2_pixel.
	mov	edx,[y2_pixel]
	cmp	edx,200	;YPIXEL_MAX
	jae	short ??exit

	; Backward rectangles are legal -- adjust for it.
	cmp	ecx,edx
	jbe	short ??oky
	xchg	ecx,edx
??oky:

	; Set DX for height and BX for width.
	sub	edx,ecx
	inc	edx
	sub	ebx,eax
	inc	ebx

	; Adjust DI to match offset into page of upper left corner.
	push	edx
	push	eax
	mov	eax,320	;XPIXEL_MAX
	mul	ecx
	add	edi,eax			; Add in Y offset.
	pop	edx
	add	edi,edx			; Add in X offset.
	pop	edx

	; Fill the region with the specified color.
	mov	eax,320	;XPIXEL_MAX
	sub	eax,ebx
	xchg	eax,[color]
	mov	ah,al
	cmp	[eorit],0
	je	short ??loop

;------	EOR rectangle filling.
??loop2:
	mov	ecx,ebx			; Length of row
??loop2in:
	lodsb
	xor	al,ah
	stosb
	loop	??loop2in
	add	edi,[color]		; Modulo add for next line prep.
	dec	edx
	jg	short ??loop2
	jmp	short ??exit

;------	Conventional rectangle filling.
??loop:
	mov	ecx,ebx			; Length of row
	shr	ecx,1
	rep	stosw
	adc	ecx,0
	rep	stosb
	add	edi,[color]		; Modulo add for next line prep.
	dec	edx
	jg	short ??loop

??exit:
	ret

	ENDP	Fill_Rect

	END

