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

; $Header: g:/library/source/rcs/./shadow.asm 1.9 1994/05/20 15:30:49 joe_bostic Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : SHADOW.ASM                               *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                  Last Update : February 28, 1995   [BG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
;* void Shadow_Blit(int xpix, int ypix, int width, int height, GVPC src, GVPC dst, void *shadowbuff);
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"
INCLUDE ".\keystruc.inc"

GLOBAL	C Shadow_Blit	: NEAR

GLOBAL	C RealModePtr : DWORD
GLOBAL	C Hide_Mouse  : NEAR
GLOBAL	C Show_Mouse  : NEAR

	CODESEG

; void Shadow_Blit(int xpix, int ypix, int width, int height, GVPC src, VBC dst, void *shadowbuff);
; Warning: Shadow_Blit appears to be relatively stupid, in that while it is
;	   optimized to perform word or dword blits, it only does so if the
;	   entire region is word or dword-sized.  In other words, if you blit
;	   a region that is 200 pixels wide (clearly dword-sized), then it
;	   will use the dword loop.  However, if you blit a region that is
;	   201 pixels wide, the dumb thing will use the byte loop for the
;	   entire blit.
	PROC    Shadow_Blit C near
	USES	eax,ebx,ecx,edx,esi,edi

	ARG	x:DWORD
	ARG	y:DWORD
	ARG	region_width:DWORD
	ARG	region_height:DWORD
	ARG     srcpage:DWORD
	ARG     dstpage:DWORD
	ARG     shadow:DWORD

	LOCAL	modulo:DWORD		; Row modulo
	LOCAL	hidemouse:DWORD		; Was the mouse hidden?
	LOCAL	dwordwidth:DWORD
	LOCAL	bytewidth:DWORD

	cld                             ; Always move forward.
	mov	[hidemouse],0		; Presume mouse hasn't been hidden.

; Fetch the segment of the seenpage.
	mov	ebx,[dstpage]
	mov	ebx,[(GraphicViewPort ebx).GVPOffset]

	; Determine if the mouse needs to be hidden at all.  If this happens to be
	; a shadow blit to non visible page (who knows why!?) then don't bother to
	; hide the mouse since it isn't necessary.
;	cmp	ebx,0A0000h
;	setne	[BYTE PTR hidemouse]	; Flag that mouse need not be hidden.
;	jne	short ??itsok
	mov	esi,[RealModePtr]
	cmp	[(KeyboardType esi).MState],0
	je	short ??itsok
	mov	[hidemouse],1
	call	Hide_Mouse C		; Hides mouse again (just to be sure).
??itsok:
	mov	edi,[srcpage]
	mov	esi,[(GraphicViewPort edi).GVPOffset]

	mov	eax,[(GraphicViewPort edi).GVPWidth]
	add	eax,[(GraphicViewPort edi).GVPXAdd]
	add	eax,[(GraphicViewPort edi).GVPPitch]
	push	eax			; save width+xadd for later calc
	mov	edx,[y]
	mul	edx
	add	eax,[x]
	add	esi,eax
; At this point, esi points to the source page and ebx points to the dest page
	sub	ebx,esi			; esi+ebx == dest page pointer

	mov	edi,[shadow]             ; EDI points to shadow buffer.

	mov     ecx,[region_height]		; get the height of the window in cx

	mov	edx,[RealModePtr]

	; Calculate the row add module.
	pop	eax			; restore width+xadd
	sub	eax,[region_width]
	mov	[modulo],eax

	mov	eax,[region_width]
	shr	eax,2
	mov	[dwordwidth],eax
	mov	eax,[region_width]
	and	eax,3
	mov	[bytewidth],eax

;---------------------------------------
; DOUBLE WORD shadow blit if possible.
;---------------------------------------
??dloop_top:
	push	ecx
	mov	ecx,[dwordwidth]

??lcontinue:
	repe    cmpsd                   ; check the entire row for changed longs
	je      short ??loop_top

	; If this row would interfere with the mouse image, then hide it.
	cmp	[hidemouse],0
	jnz	short ??dok
	mov	eax,[(KeyboardType edx).MouseY]
	sub	eax,[(KeyboardType edx).MouseYHot]
	cmp	eax,[y]
	jg	short ??dok
	add	eax,[(KeyboardType edx).MouseHeight]
	cmp	eax,[y]
	jb	short ??dok
	mov	[hidemouse],1		; Manual hide of the mouse.
	call	Hide_Mouse C
??dok:

	mov     eax,[esi-4]
	mov     [ebx+esi-4],eax		; Update destination page.
	mov     [edi-4],eax		; Update shadow buffer.
	or	ecx,ecx
	jne     short ??lcontinue

;---------------------------------------
; Row loop start for BYTES.
;---------------------------------------
??loop_top:
	mov	ecx,[bytewidth]

; Column loop start -- by bytes.
??continue:
	repe    cmpsb                   ; check the entire row for changed longs
	je      short ??done_x

	; If this row would interfere with the mouse image, then hide it.
	cmp	[hidemouse],0
	jnz	short ??bok
	mov	eax,[(KeyboardType edx).MouseY]
	sub	eax,[(KeyboardType edx).MouseYHot]
	cmp	eax,[y]
	jg	short ??bok
	add	eax,[(KeyboardType edx).MouseHeight]
	cmp	eax,[y]
	jl	short ??bok
	mov	[hidemouse],1		; Manual hide of the mouse.
	call	Hide_Mouse C
??bok:

	mov     al,[esi-1]
	mov     [ebx+esi-1],al		; Update destination page.
	mov     [edi-1],al		; Update shadow buffer.

	or	ecx,ecx
	jne     short ??continue

??done_x:
	inc	[y]
	add     esi,[modulo]
	pop     ecx
	dec		ecx
    jnz		??dloop_top

??fini:
	; Re show the mouse if it was hidden by this routine.
	cmp	[hidemouse],0
	je	short ??reallyfini
	call	Show_Mouse C
??reallyfini:
	ret

	ENDP    Shadow_Blit

	END