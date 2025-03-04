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
;*     vb.asm
;*
;* DESCRIPTION
;*     Vertical blank routines. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     WaitNoVB - Wait for active scan.
;*     WaitVB   - Wait for vertical blank.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"video.i"
	CODESEG

;****************************************************************************
;*
;* NAME
;*     WaitNoVB - Wait for active scan.
;*
;* SYNOPSIS
;*     WaitNoVB()
;*
;*     void WaitNoVB(void);
;*
;* FUNCTION
;*     Sit and wait for the active scan of the display.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C WaitNoVB:NEAR
	PROC	WaitNoVB C NEAR USES edx
	ARG	vbibit:DWORD

	mov	eax,[vbibit]
	and	al,1
	shl	al,3
	mov	ah,al

;	loop while VBL bit != VQ_VertBlank

??no_scan_yet:
	mov	edx,03DAH
	in	al,dx
	and	al,8
	xor	al,ah
	jnz	short ??no_scan_yet
	ret

	ENDP	WaitNoVB


;****************************************************************************
;*
;* NAME
;*     WaitVB - Wait for vertical blank.
;*
;* SYNOPSIS
;*     WaitVB()
;*
;*     void WaitVB(void);
;*
;* FUNCTION
;*     Sit and wait for the vertical blank of the display.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C WaitVB:NEAR
	PROC	WaitVB C NEAR USES
	ARG	vbibit:DWORD

	mov	eax,[vbibit]
	and	al,1
	shl	al,3
	mov	ah,al

;	Loop while VBL bit = VQ_VertBlank

??no_vbl_yet:
	mov	edx,03DAH
	in	al,dx
	and	al,8
	xor	al,ah
	jz	short ??no_vbl_yet
	ret

	ENDP	WaitVB

	END
