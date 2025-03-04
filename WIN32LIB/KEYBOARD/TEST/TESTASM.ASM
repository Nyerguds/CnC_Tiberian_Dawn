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

IDEAL
P386
MODEL USE32 FLAT
jumps

	codeseg

	masm
;
; Change a DAC colour register directly
;
; register number in al
;
; bh=red bl=green cl=blue
;

set_dac_col proc near
		pushad
		cli
		push	eax
		mov	dx,03dah
		in	al,dx
		jmp	@@1
@@1:		mov	dx,03c8h
		pop	eax
		out	dx,al
		jmp	@@2
@@2:		inc	dl
		mov	al,bh
		out	dx,al
		jmp	@@3
@@3:		mov	al,bl
		out	dx,al
		jmp	@@4
@@4:		mov	al,cl
		out	dx,al
		jmp	@@5
@@5:		sti
		popad
		ret
set_dac_col endp

	ideal


global	Set_Palette_Register_:near


proc Set_Palette_Register_ near

		pushad
		and	cl,63
		mov	bh,dl
		and	bh,63
		and	bl,63
		call	set_dac_col
		popad
		ret

endp Set_Palette_Register_

end
