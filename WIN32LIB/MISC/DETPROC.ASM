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

; $Header: g:/library/wwlib32/system/rcs/detproc.asm 1.1 1994/04/18 09:13:53 jeff_wilson Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : PROC.ASM                                 *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : May 11, 1993                             *
;*                                                                         *
;*                  Last Update : May 11, 1993   [JLB]                     *
;*                                                                         *
;*  Converted to 32Bit -- JAW                                              *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL 	      	C Processor          :NEAR


PROC_80386	equ	0
PROC_80486	equ	1
PROC_80586	equ	2

DATASEG
cpu_id_586	dw	0

CODESEG

PROC	Processor C near
	USES ebx
	LOCAL	ptype:WORD

	pushfd

; At least a 386 -- check for 486.
	mov	[WORD PTR ptype],PROC_80386	; 80386
	pushfd
	pop	eax
	mov	ebx,eax
	xor	eax,40000h
	push	eax
	popfd
	pushfd
	pop	eax
	xor	eax,ebx
	je	short ??fini

; At least a 486 -- check for 586(Pentium)
	mov	[ptype],PROC_80486	; 80486

	; Some machines have a problem with this fLAG
	; and thus make us think they are a 586 but they are
	; really a 486. A possible way around this is to
	; capture the Illegal instruction vector, then  do
	; an instruction only available on the 586.

	; for now this is just commented out
	pushfd
	pop	eax
	mov	ebx,eax
	xor	eax,200000h
	push	eax
	popfd
	pushfd
	pop	eax
	xor	eax,ebx
	je	short ??fini

; At least a 586(Pentium) -- check for higher.
	mov	[ptype],PROC_80586	; 80486
;	mov	eax,1
;	DW	0fA2h		; CPUID opcode.
;	shr	ax,8
;	and	ax,0fh
;	inc	ax
;	inc	ax
;	mov	[cpu_id_586],ax

; Final cleanup and exit.
??fini:
	popfd
	sub	eax,eax
	mov	ax,[ptype]
	ret

ENDP	Processor

END