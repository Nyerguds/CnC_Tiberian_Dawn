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
;*                 Project Name : Draw Shape Routines for library.         *
;*                                                                         *
;*                    File Name : DS_LSS.ASM                               *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : August 24, 1993                          *
;*                                                                         *
;*                  Last Update : June 2, 1994   [BR]                      *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Left_Scale_Skip -- Skips past a scaled row of pixels on left side     *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************* Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT


;******************************** Includes *********************************
INCLUDE "shape.inc"


;********************************* Code ************************************
	CODESEG

;***************************************************************************
;* Left_Scale_Skip -- Skips past a scaled row of pixels on left side       *
;*                                                                         *
;* INPUT:								   *
;*		ECX = number of uncompressed bytes to skip		   *
;*		ESI = shape (source) buffer data address		   *
;*		EDI = viewport (destination) address			   *
;*		[WidthCount] = shape's width				   *
;*									   *
;* OUTPUT:								   *
;*		ECX - negative # pixels (not bytes) overrun, or 0	   *
;*		EDX - XTotal initializer value				   *
;*		ESI - updated to the current location in the shape data	   *
;*		EDI - incremented by # pixels (not bytes) overrun	   *
;*		[WidthCount] - decremented by # bytes skipped		   *
;*                                                                         *
;* The value returned in EDX reflects what XTotal's accumulated value 	   *
;* should be at the new pixel location.  If no bytes are overrun, this	   *
;* will be whatever is stored in [XTotalInit] (which will be 0 if no	   *
;* pixels are left-clipped).						   *
;*                                                                         *
;* WARNINGS:	none                                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   09/08/1992 PWG : Created.                                             *
;*   08/19/1993 SKB : Split drawshp.asm into several modules.              *
;*   06/02/1994 BR : Converted to 32-bit                                   *
;*=========================================================================*
PROC	Left_Scale_Skip NOLANGUAGE NEAR

	sub 	[WidthCount],ecx	; we process ECX bytes of real width

	;--------------------------------------------------------------------
	; Put shape data address in EDI so we can do a scasb on it
	;--------------------------------------------------------------------
	xchg	esi,edi			; xchange ESI and EDI
	jcxz	??getrem		; exit if no bytes to skip

	;--------------------------------------------------------------------
	; Search through the string and count down the info we have handled.
	; If we find a run (0 followed by a count byte), then handle it.
	;--------------------------------------------------------------------
??cliptop:
	mov	eax,0			; set al to 0 (we're scanning for 0)
	repne	scasb			; scan through source data
	jz	short ??on_run		; if it is a run then deal with it

	;--------------------------------------------------------------------
	; Default exit point: store default x-scale bits & exit
	;--------------------------------------------------------------------
??getrem:
	mov	edx,[XTotalInit]	; store out the remainder
	jmp	short ??out 		; we're done, get outta here

	;--------------------------------------------------------------------
	; If we have a run then get the next byte which is the length.  
	;--------------------------------------------------------------------
??on_run:
	mov	al,[BYTE PTR edi]	; get the count of zeros to run
	inc	edi			; advance past the count
	inc	ecx			; the 0 found doesn't count
	sub	ecx,eax			; subtract the count from remaining
	jg	??cliptop		; if more bytes left, scan again
	jz	??getrem		; exactly enough bytes; exit

	;--------------------------------------------------------------------
	; Overrun exit point: ECX is negative by the # of bytes overrun.
	; - adjust [WidthCount] by # of overrun bytes
	; - compute the remainder at the new location (EDX)
	; - compute the number of destination pixels to skip (ECX)
	; - adjust EDI by # of overrun bytes
	;--------------------------------------------------------------------
	;
	;............... adjust [WidthCount] by overrun bytes ...............
	;
	add	[WidthCount],ecx	; adjust overrun in bytes
	;
	;................. put x-scale roundoff bits in EDX .................
	;
	mov	eax,ecx			; get the number of bytes we overran
	neg	eax			; negate it since overun is negative
	add	eax,[LeftClipBytes]	; add the number of bytes we leftclip
	mul 	[ScaleX]		; convert to pixels plus roundoff bits
	mov	edx,0			; clear EDX
	mov	dl,al			; DL = x-scaling roundoff bits
	;
	;................ put negative overrun pixels in ECX ................
	;
	shr	eax,8			; EAX = total # left pixels
	sub	eax,[LeftClipPixels]	; EAX = # pixels overrun
	mov	ecx,eax			; store # overrun pixels
	neg	ecx			; make it negative
	;
	;................ adjust dest ptr by overrun pixels .................
	;
	add	esi,eax			; increment ESI (EDI) by overrun pixels

	;--------------------------------------------------------------------
	; Put shape address back into ESI, adjust EDI
	;--------------------------------------------------------------------
??out:
	xchg	esi,edi			; xchange ESI and EDI
	ret				; return back to the real function

	ENDP	Left_Scale_Skip

	END

;**************************** End of ds_lss.asm *****************************
