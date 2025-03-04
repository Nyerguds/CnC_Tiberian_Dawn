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
;**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Clear the Full Mcga Screen		   *
;*                                                                         *
;*                    File Name : PUTPIXEL.ASM                             *
;*                                                                         *
;*                   Programmer : Phil Gorrow				   *
;*                                                                         *
;*                   Start Date : June 7, 1994				   *
;*                                                                         *
;*                  Last Update : June 8, 1994   [PWG]                     *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   GVPC::Put_Pixel -- Puts a pixel on a graphic viewport                 *
;*   VIVPC::Put_Pixel -- Puts a pixel on a virtual viewport                *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS ??

INCLUDE "svgaprim.inc"
INCLUDE "gbuffer.inc"


	CODESEG

;***************************************************************************
;* VIVPC::PUT_PIXEL -- Puts a pixel on a video viewport                    *
;*                                                                         *
;* INPUT:	WORD the x position for the pixel relative to the upper    *
;*			left corner of the viewport			   *
;*		WORD the y pos for the pixel relative to the upper left	   *
;*			corner of the viewport				   *
;*		UBYTE the color of the pixel to write			   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNING:	If pixel is to be placed outside of the viewport then	   *
;*		this routine will abort.				   *
;*									   *
;* HISTORY:                                                                *
;*   06/08/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Vesa_Put_Pixel C near 
	USES	eax,ebx,ecx,edx,edi,esi

	ARG    	this:DWORD				; this is a member function
	ARG	x_pixel:DWORD				; x position of pixel to set
	ARG	y_pixel:DWORD				; y position of pixel to set
	ARG    	color:BYTE				; what color should we clear to

	;*===================================================================
	; Get the viewport information and put bytes per row in ecx
	;*===================================================================
	mov	ebx,[this]				; get a pointer to viewport
	mov	edi,[(VideoViewPort ebx).VIVPOffset]	; get the correct offset
	mov	ecx,[(VideoViewPort ebx).VIVPHeight]	; edx = height of viewport
	mov	edx,[(VideoViewPort ebx).VIVPWidth]	; ecx = width of viewport

	;*===================================================================
	; Verify that the X pixel offset if legal
	;*===================================================================
	mov	eax,[x_pixel]				; find the x position
	cmp	eax,edx					;   is it out of bounds
	jae	short ??exit				; if so then get out
	add	edi,eax					; otherwise add in offset

	;*===================================================================
	; Verify that the Y pixel offset if legal
	;*===================================================================
	mov	eax,[y_pixel]				; get the y position
	cmp	eax,ecx					;  is it out of bounds
	jae	??exit					; if so then get out
	add	edx,[(VideoViewPort ebx).VIVPXAdd]	; otherwise find bytes per row
	mul	edx					; offset = bytes per row * y
	add	edi,eax					; add it into the offset

	;*===================================================================
	;* Figure out what bank we are in and set it, then adjust the
	;*   offset.
	;*===================================================================
       call	Vesa_Asm_Set_Win

	;*===================================================================
	; Write the pixel to the screen
	;*===================================================================
	mov	al,[color]				; read in color value
	mov	[edi],al				; write it to the screen
??exit:
	ret
	ENDP	Vesa_Put_Pixel
END
