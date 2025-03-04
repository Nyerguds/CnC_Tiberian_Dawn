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
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : MEM_COPY.ASM                             *
;*                                                                         *
;*                   Programmer : Scott Bowen				   *
;*                                                                         *
;*                  Last Update : September 8, 1994	[IML]              *
;*                  Ported to watcom c32 : 01/03/96     [JRJ]                                                                        *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Mem_Copy -- Copies from one pointer to another.                       *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT


LOCALS ??


;******************************************************************************
; Much testing was done to determine that only when there are 14 or more bytes
; being copied does it speed the time it takes to do copies in this algorithm.
; For this reason and because 1 and 2 byte copies crash, is the special case
; used.  SKB 4/21/94.  Tested on 486 66mhz.
OPTIMAL_BYTE_COPY	equ	14


;******************************************************************************
; External declares so these functions can be called
;
GLOBAL 	Mem_Copy	: NEAR
GLOBAL  Largest_Mem_Block : near

CODESEG


;***************************************************************************
;* MEM_COPY -- Copies from one pointer to another.                         *
;* This routine copies bytes from source to dest.  It takes care of	   *
;* overlapped memory, and unsigned long copies.					   *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/18/1994 SKB : Created.                                             *
;*=========================================================================*
; void Mem_Copy(void *source, void *dest, unsigned long bytes_to_copy);


PROC Mem_Copy 	C near 
	USES	ecx , esi , edi , ebx
	ARG	source:DWORD
	ARG	dest:DWORD
	ARG	bytes:DWORD
		
;********************************* Setup ******************************************
	cld
	mov	esi,[source]
	mov	edi,[dest]
	mov	ecx,[bytes]	; get number of bytes to copy.	

     ; check pointers for singularities
	cmp	esi,edi		; Compare source with dest.
	je	??done		; No sence in copying the same pointer.	
	or	esi,0
	jz	??done
	or	edi,0
	jz	??done

	cmp	ecx,OPTIMAL_BYTE_COPY  ; see notes above about equate.
	jge	??normal      	       ; If >= MAX(2,OPTIMAL_BYTE_COPY), do normal dword copy.

;******************************** Special case <= 2 *******************************
;
; This section must be called for bytes <= 2 since the other case will crash.  It
; optionally uses OPTIMAL_BYTE_COPY for the cut off point.  This is because after
; extensive testing, it was proved that only at that point (14 or more bytes) does
; it become quicker to use the dword copy method.

	cmp	esi,edi		; Compare source with dest.
	jge	??do_move	; if source greater do forward copy.
	lea	esi,[esi+ecx-1]
	std			; Opps, wrong, force the pointers to decrement.
	lea	edi,[edi+ecx-1]
??do_move:
	rep	movsb		; move the one or two bytes.
	cld
??done:
	ret

;************************** back or forth, that is the question *******************

??normal:
	mov	ebx,ecx
	cmp	esi,edi		; Compare source with dest.
	jge	??forward	; if source greater do forward copy.

;********************************* Backward ***************************************
??backward:
	lea	ecx,[edi+ebx]
	std
	lea	edi,[edi+ebx-1]
	and	ecx,3		; Get non aligned bytes.
	lea	esi,[esi+ebx-1]
	sub	ebx,ecx		; remove that from the total size to be copied later.
	rep	movsb		; do the copy.
	sub	esi,3
	mov	ecx,ebx		; Get number of bytes left.
 	sub	edi,3
	shr	ecx,2		; Do 4 bytes at a time.
	rep	movsd		; do the dword copy.
	mov	ecx,ebx
	add	esi,3
	add	edi,3
	and	ecx,03h
	rep	movsb		; finnish the remaining bytes.
	cld
	ret

;********************************* Forward ***************************************
??forward:
	cld
	mov	ecx,edi		; get destination pointer.	
	neg	ecx
	and	ecx,3		; Get non aligned bytes.
	sub	ebx,ecx		; remove that from the total size to be copied later.
	rep	movsb		; do the copy.
	mov	ecx,ebx		; Get number of bytes left.
	shr	ecx,2		; Do 4 bytes at a time.
	rep	movsd		; do the dword copy.
	mov	ecx, ebx
	and	ecx,03h
	rep	movsb		; finnish the remaining bytes.
	ret

ENDP	Mem_Copy

PROC Largest_Mem_Block 	C near 
	uses	esi , edi , ebx , ecx , edx
	local	mem_struct : dword : 16

	mov	eax , 0500h
	lea	edi , [ mem_struct ]
	int	31h
	mov	eax , [ mem_struct ]

	ret
ENDP Largest_Mem_Block

END



