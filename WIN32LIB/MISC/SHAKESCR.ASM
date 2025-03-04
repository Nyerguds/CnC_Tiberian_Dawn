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
;*                    File Name : SHAKESCR.ASM                             *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : August 19, 1993                          *
;*                                                                         *
;*                  Last Update : February 10, 1995 [BWG]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

GLOBAL	C Shake_Screen	:NEAR

	CODESEG

;***********************************************************
; SHAKE_SCREEN
;
; VOID Shake_Screen(int shakes);
;
; This routine shakes the screen the number of times indicated.
;
; Bounds Checking: None
;
;*
	PROC	Shake_Screen C near
	USES	ecx, edx

	ARG	shakes:DWORD
 ret

	mov	ecx,[shakes]

;;; push es
;;; mov ax,40h
;;; mov es,ax
;;; mov dx,[es:63h]
;;; pop es
	mov	eax,[0463h]		; get CRTC I/O port
	mov	dx,ax
	add	dl,6			; video status port

??top_loop:

??start_retrace:
	in	al,dx
	test	al,8
	jz	??start_retrace

??end_retrace:
	in	al,dx
	test	al,8
	jnz	??end_retrace

	cli
	sub	dl,6			; dx = 3B4H or 3D4H

	mov	ah,01			; top word of start address
	mov	al,0Ch
	out	dx,al
	xchg	ah,al
	inc	dx
	out	dx,al
	xchg	ah,al
	dec	dx

	mov	ah,040h			; bottom word = 40 (140h)
	inc	al
	out	dx,al
	xchg	ah,al
	inc	dx
	out	dx,al
	xchg	ah,al

	sti
	add	dl,5

??start_retrace2:
	in	al,dx
	test	al,8
	jz	??start_retrace2

??end_retrace2:
	in	al,dx
	test	al,8
	jnz	??end_retrace2

??start_retrace3:
	in	al,dx
	test	al,8
	jz	??start_retrace3

??end_retrace3:
	in	al,dx
	test	al,8
	jnz	??end_retrace3

	cli
	sub	dl,6			; dx = 3B4H or 3D4H

	mov	ah,0
	mov	al,0Ch
	out	dx,al
	xchg	ah,al
	inc	dx
	out	dx,al
	xchg	ah,al
	dec	dx

	mov	ah,0
	inc	al
	out	dx,al
	xchg	ah,al
	inc	dx
	out	dx,al
	xchg	ah,al

	sti
	add	dl,5

	loop	??top_loop

	ret

	ENDP	Shake_Screen

;***********************************************************

	END
