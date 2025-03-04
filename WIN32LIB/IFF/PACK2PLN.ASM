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

; $Header: g:/library/wwlib32/file/rcs/pack2pln.asm 1.1 1994/04/22 18:07:46 scott_bowen Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Library                                  *
;*                                                                         *
;*                    File Name : PACK2PLN.ASM                             *
;*                                                                         *
;*                   Programmer : Scott K. Bowen			   *
;*                                                                         *
;*                   Start Date : November 20, 1991                        *
;*                                                                         *
;*                  Last Update : April 22, 1994   [SKB]                   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT


LOCALS ??


;******************************************************************************
; External declares so these functions can be called
;
GLOBAL  		Pack_2_Plane:NEAR

	CODESEG

;***************************************************************************
;* PACK_2_PLANE -- packed to planar scanline conversion                    *
;*                                                                         *
;* INPUT:  BYTE *buffer (far) -- pointer to planar output buffer           *
;*         BYTE *pageptr (far) -- pointer to current row in packed page    *
;*         WORD planebit -- current bit used in plane -- use only low byte *
;*                                                                         *
;* OUTPUT:                                                                 *
;*         Return result in buffer.                                        *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   11/20/1991  SB : Created.                                             *
;*   04/22/1994 SKB : Converted to 32 bit library.                         *
;*=========================================================================*
;									   *
;	This is the original function that is converted to asm
;  
;PRIVATE VOID Pack_2_Plane(UBYTE * buffer, BYTE * pageptr, BYTE planebit)
;{
;  WORD currbit=0x80;		// current bit to be written to
;  WORD pixel;	  		// current pixel in row used as a counter;
;
;  buffer--;			// will be incremented at the start
;  for (currbit = 0, pixel = 0; pixel < 320; pixel++) {
;    if (!currbit) {
;      currbit = 0x80;		// reset bit 7
;      buffer++;		// go to next byte in buffer
;      *buffer = 0;		// clear byte so we only need to set bits needed
;    }
;  if (planebit & *pageptr++)
;    *buffer |= currbit;	// set bit in destination if plane was set is source
;
;  currbit >>= 1;		// shift destination bit one right
;  }
;}

PROC	Pack_2_Plane C NEAR 
	USES	ebx,ecx,esi,edi
 	ARG	buffer:DWORD
	ARG	page:DWORD
	ARG	planebit:WORD


	mov	edi,[buffer]
	mov	esi,[page]

	mov	ax,[planebit]		; move bit set for current plane (planebit) to ax
					; the low byte will only be used
	      
	mov	ecx,320d	      	; set counter to 320 columns (320x200 picture)
	mov	ah,80h			; set bit 7 of current_bit 
	dec	edi			; this will get incremented at the start

??top_loop:				; while (columns left)
	cmp	ah,80h			;   if current_bit is bit 7
	jnz	short ??same_dest			
					;   Then
	inc	edi			;     buffer++  increment pointer
	mov	[BYTE PTR edi],0	;     *buffer = 0 

??same_dest:				;   EndIf
	mov	bl,al
	and	bl,[esi]		;   if (planebit & *pageptr)
	jz	short ??no_set_bit

	or	[BYTE PTR edi],ah     	;     Then *buffer |= current_bit

??no_set_bit:
	inc	esi			;   pageptr++	goto next in source byte
	ror	ah,1			;   rotate current_bit right one
	dec	ecx			; 
	jnz	??top_loop

	ret

	ENDP	Pack_2_Plane

	END
