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
;*     vga.i
;*
;* DESCRIPTION
;*     VGA hardware definitions. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;****************************************************************************

;----------------------------------------------------------------------------
; VGA Registers
;----------------------------------------------------------------------------

R_SEQUENCER		EQU	03C4h	;Sequencer Controller Index reg
SEQ_RESET		EQU	00h	;Reset
SEQ_MAP_MASK		EQU	02h	;Index in Sequencer of Map Mask reg
SEQ_MEMORY_MODE	EQU	04h	;Memory Mode

R_GRAPHICS_CONTROLLER	EQU	03CEh	;Graphics Controller Index reg
GC_READ_MAP		EQU	04h	;Index in GController of Read Map reg
GC_MODE		EQU	05h	;Read/Write Modes
GC_MISC		EQU	06h	;Read/Write Modes
GC_BITMASK		EQU	08h	;Index in GController of BitMask reg

R_CRT_CONTROLLER	EQU	03D4h	;CRT Controller Index reg
CRT_VERT_TOTAL	EQU	06h	;Vertical total
CRT_OVERFLOW		EQU	07h	;Overflow
CRT_MAX_SCANLINE	EQU	09h	;Max scan line
CRT_STARTADDR_HIGH	EQU	0Ch	;Bitmap start address high byte
CRT_STARTADDR_LOW	EQU	0Dh	;Bitmap start address low byte
CRT_VERTRET_START	EQU	010h	;Vertical retrace pulse start
CRT_VERTRET_END	EQU	011h	;Vertical retrace pulse end
CRT_VERTDISP_END	EQU	012h	;Vertical display end
CRT_UNDERLINE		EQU	014h	;Underline location
CRT_START_VB		EQU	015h	;Start vertical blank
CRT_END_VB		EQU	016h	;End vertical blank
CRT_MODE_CONTROL	EQU	017h	;Mode control
R_MISC_OUTPUT		EQU	03C2h	;Miscellaneous Output reg

;----------------------------------------------------------------------------
; Palette Registers
;----------------------------------------------------------------------------

PEL_READ_ADDR		EQU	03C7h
PEL_WRITE_ADDR	EQU	03C8h
PEL_DATA		EQU	03C9h

;----------------------------------------------------------------------------
; XMode planes, for the Map Mask register
;----------------------------------------------------------------------------

XPLANE_1	EQU	1
XPLANE_2	EQU	2
XPLANE_3	EQU	4
XPLANE_4	EQU	8

;----------------------------------------------------------------------------
;
; NAME
;     SET_PLANE - Set an XMode plane.
;
; SYNOPSIS
;     SET_PLANE plane
;
; INPUTS
;     plane - Number of Xmode plane to set.
;
; USES
;     eax, edx
;
;----------------------------------------------------------------------------

	MACRO	SET_PLANE plane
	mov	edx,R_SEQUENCER
	mov	eax,SEQ_MAP_MASK
	out	dx,al
	inc	edx
	mov	eax,plane
	out	dx,al
	ENDM

;----------------------------------------------------------------------------
;
; NAME
;     SET_BITMASK - Set the BitMask register.
;
; SYNOPSIS
;     SET_BITMASK mask
;
; INPUTS
;     mask - Bitmask to use.
;
; USES
;     eax, edx
;
;----------------------------------------------------------------------------

	MACRO	SET_BITMASK mask
	mov	edx,R_GRAPHICS_CONTROLLER
	mov	eax,GC_BITMASK
	out	dx,al
	inc	edx
	mov	eax,mask
	out	dx,al
	ENDM

;----------------------------------------------------------------------------
;
; NAME
;     SET_WRITEMODE - Set the VGA writemode.
;
; SYNOPSIS
;     SET_WRITEMODE mode
;
; INPUTS
;     mode - Write mode.
;
; USES
;     eax, edx
;
;----------------------------------------------------------------------------

	MACRO	SET_WRITEMODE mode
	mov	edx,R_GRAPHICS_CONTROLLER
	mov	eax,GC_MODE
	out	dx,al
	inc	edx
	in	al,dx	;Read the register
	and	al,0FCh	;Turn off 2 lower bits
	or	al,mode	;Set write mode
	out	dx,al
	ENDM

;----------------------------------------------------------------------------
;
; NAME
;     OUTPORT - Output data to a VGA register.
;
; SYNOPSIS
;     OUTPORT port,register,data
;
; INPUTS
;     port     - Port address.
;     register - Register to write to.
;     data     - Data to write.
;
; USES
;     eax, edx
;
;----------------------------------------------------------------------------

	MACRO	OUTPORT port,register,data
	mov	edx,port
	mov	al,register
	out	dx,al
	inc	edx
	mov	al,data
	out	dx,al
	ENDM

;----------------------------------------------------------------------------
;
; NAME
;     INPORT - Input data from a VGA register.
;
; SYNOPSIS
;     data = INPORT port,register
;
; INPUTS
;     port     - Port address.
;     register - Register to read from.
;
; RESULT
;     data - Value read from port in AL.
;
; USES
;     eax, edx
;
;----------------------------------------------------------------------------

	MACRO	INPORT port,register
	mov	edx,port
	mov	al,register
	out	dx,al
	inc	edx
	in	al,dx
	ENDM

