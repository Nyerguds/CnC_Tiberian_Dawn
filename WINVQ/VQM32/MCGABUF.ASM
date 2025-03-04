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
;*     mcgabuf.asm
;*
;* DESCRIPTION
;*     MCGA display routines. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Bill Randolph
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     Febuary 3, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     ClearVRAM       - Clear all VRAM.
;*     MCGA_BufferCopy - Copy 320x200 buffer to MCGA VRAM
;*     MCGA_Blit       - Bit blit a block to the MCGA screen.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"vga.i"
	CODESEG

;****************************************************************************
;*
;* NAME
;*     ClearVRAM - Clear all VRAM.
;*
;* SYNOPSIS
;*     ClearVRAM()
;*
;*     void ClearVRAM(void);
;*
;* FUNCTION
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C ClearVRAM:NEAR
 	PROC	ClearVRAM C NEAR USES eax ecx edi es

	IF	PHARLAP_TNT
	mov	eax,01Ch	;Set ES selector to video memory
	mov	es,ax
	mov	edi,0
	ELSE
	mov	edi,0A0000h
	ENDIF

	SET_PLANE 0Fh	;Enable all planes for writing
	cld
	mov	ecx,16000	;Clear 320x200
	xor	eax,eax
	rep	stosd
	ret

	ENDP	ClearVRAM


;****************************************************************************
;*
;* NAME
;*     MCGA_BufferCopy - Copy 320x200 buffer to MCGA VRAM
;*
;* SYNOPSIS
;*     MCGA_BufferCopy(Buffer, Dummy)
;*
;*     void MCGA_BufferCopy(char *, char *);
;*
;* FUNCTION
;*
;* INPUTS
;*     Buffer - Pointer to buffer to transfer.
;*     Dummy  - Prototype placeholder.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C MCGA_BufferCopy:NEAR
	PROC	MCGA_BufferCopy C NEAR USES ecx esi edi es

	ARG	buffer:NEAR PTR
	ARG	dummy:NEAR PTR

	IF	PHARLAP_TNT
	mov	eax,01Ch
	mov	es,ax
	mov	edi,0
	ELSE
	mov	edi,0A0000h
	ENDIF

	mov	esi, [buffer]
	mov	ecx,16000
	rep 	movsd	;Transfer the data
	ret

	ENDP	MCGA_BufferCopy


;****************************************************************************
;*
;* NAME
;*     MCGA_Blit - Bit blit a block to the MCGA screen.
;*
;* SYNOPSIS
;*     MCGA_Blit(Buffer, Screen, Width, Height)
;*
;*     void MCGA_Blit(char *, char *, long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Buffer - Pointer to buffer to copy.
;*     Screen - Screen address to copy buffer to.
;*     Width  - Width of block.
;*     Height - Height of block.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C MCGA_Blit:NEAR
	PROC	MCGA_Blit C NEAR USES ecx edx esi edi

	ARG	buffer:NEAR PTR
	ARG	screen:NEAR PTR
	ARG	imgwidth:DWORD
	ARG	imgheight:DWORD

	IF	PHARLAP_TNT
	push	es
	mov	eax,1Ch	;Set ES selector to VRAM
	mov	es,ax
	ENDIF

	mov	esi,[buffer]
	mov	edi,[screen]
	mov	edx,320
	sub	edx,[imgwidth]	;Compute modulo

??Do_row:
	mov	ecx,[imgwidth]
	rep 	movsb
	add	edi,edx
	dec	[imgheight]
	jnz	??Do_row

	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	MCGA_Blit

	END

