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
;**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
;***************************************************************************
;*                                                                         *
;*                 Project Name : 32 bit library Text Print                *
;*                                                                         *
;*                    File Name : TEXTPRNT.ASM                             *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : July 2, 1994                             *
;*                                                                         *
;*                  Last Update : July 2, 1994   [SKB]                     *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Text_Print -- Assembly text print routine.                            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT


GLOBAL  C ColorXlat:BYTE
GLOBAL	C Set_Font_Palette_Range:NEAR

	CODESEG

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
	PROC	Set_Font_Palette_Range C near
	USES	eax, ebx, ecx,edi,esi
	ARG	palette:DWORD
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
	add	ebx,010H    		; add 16 to index for hinibble offset
	dec	ecx
	jnz	??setpal

??exit:
	ret

	ENDP	Set_Font_Palette_Range

;***********************************************************


;***********************************************************

	END