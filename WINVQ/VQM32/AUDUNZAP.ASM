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
;*     audunzap.asm 
;*
;* DESCRIPTION
;*     Audio uncompress (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Joe L. Bostic
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     February 9, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     AudioUnzap - Uncompress zapped audio sample.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

CODE_2BIT	EQU	0
CODE_4BIT	EQU	1
CODE_RAW	EQU	2
CODE_SILENCE	EQU	3
MAGICNUMBER	EQU	00000DEAFh
MAGICNUMBER2	EQU	0BABEBABEh

_2bitdecode	DB	-2,-1,0,1
_4bitdecode	DB	-9,-8,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,8

;****************************************************************************
;*
;* NAME
;*     AudioUnzap - Uncompress zapped audio sample.
;*
;* SYNOPSIS
;*     Size = AudioUnzap(Source, Dest, Size)
;*
;*     long AudioUnzap(void *, void *, long);
;*
;* FUNCTION
;*     Decompress the zapped audio sample data into a buffer.
;*
;* INPUTS
;*     Source - Pointer to encoded audio data.
;*     Dest   - Pointer to buffer to decompress into.
;*     Size   - Maximum size of dest buffer.
;*
;* RESULT
;*     Size - Number of uncompressed bytes.
;*
;****************************************************************************

	GLOBAL	C AudioUnzap:NEAR
	PROC	AudioUnzap C NEAR USES ebx ecx edx esi edi

	ARG	source:DWORD
	ARG	dest:DWORD
	ARG	count:DWORD

	LOCAL	previous:BYTE
	LOCAL	incount:DWORD

	mov	[incount],0	;Bytes read from source

;	Source, Dest and count must be valid.

;	cmp	[source],0
;	je	??fini

;	cmp	[dest],0
;	je	??fini

;	cmp	[count],0
;	je	??fini

	mov	esi,[source]	;Pointer to source data.
	mov	edi,[dest]	;Pointer to destination data.
	mov	ecx,[count]	;Number of bytes to fill dest buffer.
	mov	dl,080h	;Previous sample (starting value).
	cld

??mainloop:
	cmp	ecx,0	;If dest full then exit
	jle	??fini

	xor	eax,eax
	mov	al,[esi]	;Get code byte
	inc	[incount]
	inc	esi
	shl	eax,2	;AH contains code.
	shr	al,2	;AL contains sub-code data.

	cmp	ah,CODE_RAW	;Raw sequence?
	jne	short ??try4bit

;	The code contains either a 5 bit delta or a count of
;	raw samples to dump out.

	test	al,00100000b
	je	short ??justraw

;	The lower 5 bits are actually a signed delta.
;	Sign extend the delta and add it to the stream.

	shl	al,3
	sar	al,3
	add	dl,al
	mov	[edi],dl
	dec	ecx
	inc	edi
	jmp	??mainloop

;	The lower 5 bits hold a count of the number of raw
;	samples that follow this code. Dump these samples to
;	the output buffer.

??justraw:
	mov	ebx,ecx
	xor	ah,ah
	inc	al
	mov	ecx,eax
	shr	ecx,1
	rep	movsw
	adc	ecx,ecx
	rep	movsb
	mov	ecx,ebx
	add	[incount],eax
	sub	ecx,eax
	dec	edi
	mov	dl,[edi]	;Set "previous" value.
	inc	edi
	jmp	??mainloop

;	Check to see if this is a 4 bit delta code sequence.

??try4bit:
	inc	al	;Following codes use AL+1
	cmp	ah,CODE_4BIT
	jne	short ??try2bit

;	A sequence of 4bit deltas follow. AL equals the
;	number of nibble packed delta bytes to process.

??bit4loop:
	mov	ah,[esi]	;Fetch nibble packed delta codes
	mov	bl,ah
	inc	[incount]
	inc	esi

;	Add first delta to 'previous' sample already in DL.

	and	ebx,00001111b
	add	dl,[_4bitdecode+ebx]
	pushf
	cmp	[_4bitdecode+ebx],0
	jl	short ??neg1

	popf
	jnc	short ??ok1
	mov	dl,0FFh
	jmp	short ??ok1

??neg1:
	popf
	jc	short ??ok1

	xor	dl,dl

??ok1:
	mov	dh,dl	;DH now holds new 'previous' sample.
	mov	bl,ah
	shr	bl,4
	add	dh,[_4bitdecode+ebx]
	pushf
	cmp	[_4bitdecode+ebx],0
	jl	short ??neg2

	popf
	jnc	short ??ok2

	mov	dh,0FFh
	jmp	short ??ok2

??neg2:
	popf
	jc	short ??ok2

	xor	dh,dh

??ok2:
	mov	[edi],dx	;Output the two sample bytes
	sub	ecx,2
	add	edi,2

;	Put the correct 'previous' sample in DL where it belongs.

	mov	dl,dh

;	If there are more deltas to process then loop back.

	dec	al
	jnz	short ??bit4loop
	jmp	??mainloop

;	Check to see if 2 bit deltas need to be processed.

??try2bit:
	cmp	ah,CODE_2BIT
	jne	??zerodelta

;	A sequence of 2bit deltas follow.  AL equals the number of 
;	packed delta bytes to process.

??bit2loop:
	mov	ah,[esi]	;Fetch packed delat codes
	inc	[incount]
	inc	esi

;	Add first delta to 'previous' sample already in DL.

	mov	bl,ah
	and	ebx,000011b
	add	dl,[_2bitdecode+ebx]
	pushf
	cmp	[_2bitdecode+ebx],0
	jl	short ??neg3

	popf
	jnc	short ??ok3

	mov	dl,0FFh
	jmp	short ??ok3

??neg3:
	popf
	jc	short ??ok3
	xor	dl,dl

??ok3:
	mov	dh,dl
	ror	edx,8
	mov	bl,ah
	shr	ebx,2
	and	bl,00000011b
	add	dl,[_2bitdecode+ebx]
	pushf
	cmp	[_2bitdecode+ebx],0
	jl	short ??neg4

	popf
	jnc	short ??ok4

	mov	dl,0FFh
	jmp	short ??ok4

??neg4:
	popf
	jc	short ??ok4

	xor	dl,dl

??ok4:
	mov	dh,dl
	ror	edx,8
	mov	bl,ah
	shr	ebx,4
	and	bl,00000011b
	add	dl,[_2bitdecode+ebx]
	pushf
	cmp	[_2bitdecode+ebx],0
	jl	short ??neg5

	popf
	jnc	short ??ok5

	mov	dl,0FFh
	jmp	short ??ok5

??neg5:
	popf
	jc	short ??ok5

	xor	dl,dl

??ok5:
	mov	dh,dl
	ror	edx,8
	mov	bl,ah
	shr	ebx,6
	and	bl,00000011b
	add	dl,[_2bitdecode+ebx]
	pushf
	cmp	[_2bitdecode+ebx],0
	jl	short ??neg6

	popf
	jnc	short ??ok6

	mov	dl,0FFh
	jmp	short ??ok6

??neg6:
	popf
	jc	short ??ok6

	xor	dl,dl

??ok6:
	ror	edx,8
	mov	[edi],edx	;Output two sample bytes
	sub	ecx,4
	add	edi,4

;	Put the correct 'previous' sample in DL where it belongs.

	rol	edx,8

;	If there are more deltas to process then loop back.

	dec	al
	jnz	??bit2loop
	jmp	??mainloop

;	There is a run of zero deltas.  Zero deltas merely duplicate
;	the 'previous' sample the requested number of times.

??zerodelta:
	xor	ebx,ebx
	mov	bl,al
	mov	al,dl
	sub	ecx,ebx
	xchg	ecx,ebx
	rep	stosb
	mov	ecx,ebx
	jmp	??mainloop

??fini:
	mov	eax,[incount]
	ret

	ENDP	AudioUnzap

	END

