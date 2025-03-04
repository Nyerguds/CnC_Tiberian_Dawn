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
;*                    File Name : CRC.ASM                                  *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : June 12, 1992                            *
;*                                                                         *
;*                  Last Update : February 10, 1995 [BWG]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL	C Calculate_CRC	:NEAR

	CODESEG

; LONG Calculate_CRC(VOID *buffer, LONG length);
	PROC	Calculate_CRC C near
	USES 	esi

	ARG	buffer:DWORD
	ARG	length:DWORD

	LOCAL	crc:DWORD

	; Load pointer to data block.
	mov	[crc],0
	pushad
	mov	esi,[buffer]
	cld

	; Clear CRC to default (NULL) value.
	xor	ebx,ebx

	; Fetch the length of the data block to CRC.
	mov	ecx,[length]
	jecxz	short ??fini

	; Prepare the length counters.
	mov	edx,ecx
	and	dl,011b
	shr	ecx,2

	; Perform the bulk of the CRC scanning.
	jecxz	short ??remainder
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

	and 	ecx,0FFFFh
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
	mov	[crc],ebx
	popad
	mov	eax,[crc]
	ret

	ENDP	Calculate_CRC

	END