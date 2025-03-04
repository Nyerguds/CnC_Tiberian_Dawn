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


;**********************************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S  I N C                     **
;**********************************************************************************************
;*                                                                                            *
;*                 Project Name : VQA Viewer                                                  *
;*                                                                                            *
;*                    File Name : INTERPAL.ASM                                                *
;*                                                                                            *
;*                   Programmer : Steve Tall                                                  *
;*                                                                                            *
;*                   Start Date : December 15th, 1995                                         *
;*                                                                                            *
;*                  Last Update : December 22nd, 1995  [ST]                                   *
;*                                                                                            *
;*--------------------------------------------------------------------------------------------*
;* Functions:                                                                                 *
;*                                                                                            *
;*  Asm_Interpolate -- interpolate a 320x200 buffer to a 640x400 screen                       *
;*                                                                                            *
;*                                                                                            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  *




		IDEAL
		P386
		MODEL USE32 FLAT


		segment mycode page public use32 'code'	; Need stricter segment alignment

global		C	Asm_Interpolate:near
global		C	Palette_Interpolation_Table:byte





;*********************************************************************************************
;* Asm_Interpolate -- interpolate a 320x200 buffer to a 640x400 screen                       *
;*                                                                                           *
;* INPUT:	ptr to source buffer (320x200 image)                                         *
;*              ptr to dest buffer (640x400)                                                 *
;*              height of source buffer                                                      *
;*              width f source buffer                                                        *
;*              width of dest buffer                                                         *
;*                                                                                           *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Warnings:                                                                                 *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   12/15/95 ST : Created.                                                                  *
;*===========================================================================================*

PROC		Asm_Interpolate C near

		ARG	src_ptr:dword
		ARG	dest_ptr:dword
		ARG	source_height:dword
		ARG	source_width:dword
		ARG	dest_width:dword

		LOCAL	old_dest:dword
		LOCAL	width_counter:dword

		pushad

		mov	eax,[dest_ptr]
		mov	[old_dest],eax

		mov	esi,[src_ptr]

??each_line_loop:
		mov	[width_counter],0
		mov	ecx,[source_width]
		sub	ecx,2
		shr	ecx,1
		mov	edi,[old_dest]
		jmp	??interpolate_loop

		align	32
;
; convert 2 pixels of source into 4 pixels of destination
; so we can write to video memory with dwords
;
??interpolate_loop:
		mov	eax,[esi]
		lea	esi,[esi+2]
		mov	edx,eax
		mov	ebx,eax
		and	edx,65535
		ror	ebx,8
		mov	bl,[edx+Palette_Interpolation_Table]
		mov	bh,ah
		and	eax,000ffff00h
		ror	ebx,8

;1st 3 pixels now in ebx

		shr	eax,8
		mov	bh,[eax+Palette_Interpolation_Table]
		ror	ebx,16
		mov	[edi],ebx
		add	edi,4

		dec	ecx
		jnz	??interpolate_loop

; do the last three pixels and a blank on the end of a row
		xor	eax,eax
		mov	ax,[esi]
		mov	[edi],al
		inc	edi
		lea	esi,[esi+2]
		mov	al,[eax+Palette_Interpolation_Table]
		mov	[edi],al
		inc	edi
		mov	[edi],ah
		inc	edi
		mov	[byte edi],0

		mov	edi,[dest_width]
		add	[old_dest],edi

		dec	[source_height]
		jnz	??each_line_loop

		popad
		ret

endp		Asm_Interpolate




ends		mycode

end


