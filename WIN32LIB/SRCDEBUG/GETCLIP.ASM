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
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : BITBLIT.ASM                              *
;*                                                                         *
;*                   Programmer : Julio R. Jerez                           *
;*                                                                         *
;*                   Start Date : Feb 6, 1995                              *
;*                                                                         *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS ??

INCLUDE ".\drawbuff.inc"
INCLUDE "gbuffer.inc"


; typedef struct {
;		     int x0 , y0 ;
;		     int x1 , y1 ;
;		 } CLIP_WIN ;
; Note for efficiency reasons x1 must be >= x0 and y1 >= y0
; int get_clip ( CLIP_WIN * window , CLIP_WIN * sorce_rect ) ;

CODESEG

	PROC	get_clip C near
	USES	eax , ebx

	;*===================================================================
	;* define the arguements that our function takes.
	;*===================================================================
	ARG	win	    : dword
	ARG     rect	    : dword


	mov	edi , [ rect ]
	mov  	esi , [ win ]
	xor 	eax , eax
	xor 	edx , edx

	mov	ecx , [ (RECTANGLE edi) . x0 ]
	mov	ebx , [ (RECTANGLE edi) . x1 ]
	sub	ecx , [ (RECTANGLE esi) . x0 ]
	sub	ebx , [ (RECTANGLE esi) . x0 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

;	mov	ebx , [ (RECTANGLE esi) . x1 ]
;	inc	ebx
;	mov	[ rect ] , ebx
	mov	ecx , [ (RECTANGLE edi) . x0 ]
	mov	ebx , [ (RECTANGLE edi) . x1 ]
	sub	ecx , [ (RECTANGLE esi) . x1 ]
	sub	ebx , [ (RECTANGLE esi) . x1 ]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ (RECTANGLE edi) . y0 ]
	mov	ebx , [ (RECTANGLE edi) . y1 ]
	sub	ecx , [ (RECTANGLE esi) . y0 ]
	sub	ebx , [ (RECTANGLE esi) . y0 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

;	mov	ebx , [ (RECTANGLE esi) . y1 ]
;	inc	ebx
;	mov	[ rect ] , ebx
	mov	ecx , [ (RECTANGLE edi) . y0 ]
	mov	ebx , [ (RECTANGLE edi) . y1 ]
	sub	ecx , [ (RECTANGLE esi) . y1 ]
	sub	ebx , [ (RECTANGLE esi) . y1 ]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	xor	al , 5
	xor	dl , 5
	mov	ah , dl
	ret
       ENDP	get_clip



END