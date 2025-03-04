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
;**   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : FADING.ASM                               *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : August 20, 1993                          *
;*                                                                         *
;*                  Last Update : August 20, 1993   [JLB]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL	C Build_Fading_Table	:NEAR

	CODESEG

;***********************************************************
; BUILD_FADING_TABLE
;
; void *Build_Fading_Table(void *palette, void *dest, long int color, long int frac);
;
; This routine will create the fading effect table used to coerce colors
; from toward a common value.  This table is used when Fading_Effect is
; active.
;
; Bounds Checking: None
;*
	PROC	Build_Fading_Table C near
	USES	ebx, ecx, edi, esi
	ARG	palette:DWORD
	ARG	dest:DWORD
	ARG	color:DWORD
	ARG	frac:DWORD

	LOCAL	matchvalue:DWORD	; Last recorded match value.
	LOCAL	targetred:BYTE		; Target gun red.
	LOCAL	targetgreen:BYTE	; Target gun green.
	LOCAL	targetblue:BYTE		; Target gun blue.
	LOCAL	idealred:BYTE
	LOCAL	idealgreen:BYTE
	LOCAL	idealblue:BYTE
	LOCAL	matchcolor:BYTE		; Tentative match color.

	cld

	; If the source palette is NULL, then just return with current fading table pointer.
	cmp	[palette],0
	je	??fini
	cmp	[dest],0
	je	??fini

	; Fractions above 255 become 255.
	mov	eax,[frac]
	cmp	eax,0100h
	jb	short ??ok
	mov	[frac],0FFh
??ok:

	; Record the target gun values.
	mov	esi,[palette]
	mov	ebx,[color]
	add	esi,ebx
	add	esi,ebx
	add	esi,ebx
	lodsb
	mov	[targetred],al
	lodsb
	mov	[targetgreen],al
	lodsb
	mov	[targetblue],al

	; Main loop.
	xor	ebx,ebx			; Remap table index.

	; Transparent black never gets remapped.
	mov	edi,[dest]
	mov	[edi],bl
	inc	edi

	; EBX = source palette logical number (1..255).
	; EDI = running pointer into dest remap table.
??mainloop:
	inc	ebx
	mov	esi,[palette]
	add	esi,ebx
	add	esi,ebx
	add	esi,ebx

	mov	edx,[frac]
	shr	edx,1
	; new = orig - ((orig-target) * fraction);

	lodsb				; orig
	mov	dh,al			; preserve it for later.
	sub	al,[targetred]		; al = (orig-target)
	imul	dl			; ax = (orig-target)*fraction
	shl	ax,1
	sub	dh,ah			; dh = orig - ((orig-target) * fraction)
	mov	[idealred],dh		; preserve ideal color gun value.

	lodsb				; orig
	mov	dh,al			; preserve it for later.
	sub	al,[targetgreen]	; al = (orig-target)
	imul	dl			; ax = (orig-target)*fraction
	shl	ax,1
	sub	dh,ah			; dh = orig - ((orig-target) * fraction)
	mov	[idealgreen],dh		; preserve ideal color gun value.

	lodsb				; orig
	mov	dh,al			; preserve it for later.
	sub	al,[targetblue]		; al = (orig-target)
	imul	dl			; ax = (orig-target)*fraction
	shl	ax,1
	sub	dh,ah			; dh = orig - ((orig-target) * fraction)
	mov	[idealblue],dh		; preserve ideal color gun value.

	; Sweep through the entire existing palette to find the closest
	; matching color.  Never matches with color 0.

	mov	eax,[color]
	mov	[matchcolor],al		; Default color (self).
	mov	[matchvalue],-1		; Ridiculous match value init.
	mov	ecx,255

	mov	esi,[palette]		; Pointer to original palette.
	add	esi,3

	; BH = color index.
	mov	bh,1
??innerloop:

	; Recursion through the fading table won't work if a color is allowed
	; to remap to itself.  Prevent this from occuring.
	add	esi,3
	cmp	bh,bl
	je	short ??notclose
	sub	esi,3

	xor	edx,edx			; Comparison value starts null.
	mov	eax,edx
	; Build the comparison value based on the sum of the differences of the color
	; guns squared.
	lodsb
	sub	al,[idealred]
	mov	ah,al
	imul	ah
	add	edx,eax

	lodsb
	sub	al,[idealgreen]
	mov	ah,al
	imul	ah
	add	edx,eax

	lodsb
	sub	al,[idealblue]
	mov	ah,al
	imul	ah
	add	edx,eax
	jz	short ??perfect		; If perfect match found then quit early.

	cmp	edx,[matchvalue]
	ja	short ??notclose
	mov	[matchvalue],edx	; Record new possible color.
	mov	[matchcolor],bh
??notclose:
	inc	bh			; Checking color index.
	loop	??innerloop
	mov	bh,[matchcolor]
??perfect:
	mov	[matchcolor],bh
	xor	bh,bh			; Make BX valid main index again.

	; When the loop exits, we have found the closest match.
	mov	al,[matchcolor]
	stosb
	cmp	ebx,255
	jne	??mainloop

??fini:
	mov	eax,[dest]
	ret

	ENDP	Build_Fading_Table


	END