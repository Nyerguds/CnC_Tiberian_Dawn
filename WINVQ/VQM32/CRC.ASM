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
;*        C O N F I D E N T I A L --- W E S T W O O D  S T U D I O S
;*
;*---------------------------------------------------------------------------
;*
;* FILE
;*     crc.asm
;*
;* DESCRIPTION
;*     CRC checksum calculation.
;*
;* PROGRAMMER
;*     Joe L. Bostic
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     Calculate_CRC - Calculate CRC checksum.
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
;*     Calculate_CRC - Calculate CRC checksum.
;*
;* SYNOPSIS
;*     CRC = Calculate_CRC(Buffer, Length)
;*
;*     long Calculate_CRC(void *, long);
;*
;* FUNCTION
;*     Compute a CRC checksum for a block of memory.
;*
;* INPUTS
;*     Buffer - Pointer to buffer to calculate CRC for.
;*     Length - Length of buffer.
;*
;* RESULT
;*     CRC - CRC value.
;*
;****************************************************************************

	GLOBAL	C Calculate_CRC:NEAR
	PROC	Calculate_CRC C NEAR USES esi ebx ecx edx
	ARG	buffer:NEAR PTR
	ARG	length:DWORD

	mov	esi,[buffer]
	cld

	; Clear CRC to default (NULL) value.
	xor	ebx,ebx

	mov	ecx,[length]	;Get length of data block
	or	ecx,ecx
	jz	short ??fini

	; Prepare the length counters.
	mov	edx,ecx
	and	dl,011b
	shr	ecx,2

	; Perform the bulk of the CRC scanning.
	or	ecx,ecx
	jz	short ??remainder

??accumloop:
	lodsd
	rol	ebx,1
	add	ebx,eax
	loop	??accumloop

	; Handle the remainder bytes.
??remainder:
	or	dl,dl
	jz	short ??fini
	mov	ecx,edx
	xor	eax,eax

	push	ecx
??nextbyte:
	lodsb
	ror	eax,8
	loop	??nextbyte
	pop	ecx
	neg	ecx
	add	ecx,4
	shl	ecx,3
	ror	eax,cl

;??nextbyte:
;	shl	eax,8
;	lodsb
;	loop	??nextbyte
	rol	ebx,1
	add	ebx,eax

??fini:
	mov	eax,ebx
	ret

	ENDP	Calculate_CRC

	END
