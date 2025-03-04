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
;*       C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
;*
;*----------------------------------------------------------------------------
;*
;* FILE
;*     video.i
;*
;* DESCRIPTION
;*     Video manager definitions. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;****************************************************************************

	INCLUDE	"vesavid.i"

;----------------------------------------------------------------------------
; Video Modes
;----------------------------------------------------------------------------

TEXT	EQU	002h
MCGA	EQU	013h
XMODE_320X200	EQU	050h
XMODE_320X240	EQU	051h
XMODE_320X400	EQU	052h
XMODE_320X480	EQU	053h
XMODE_360X400	EQU	054h
XMODE_360X480	EQU	055h

;----------------------------------------------------------------------------
; Structure definitions
;----------------------------------------------------------------------------

; DisplayInfo - Information about the current display.
;
; Mode     - Mode identification
; XRes     - X resolution
; YRes     - Y resolution
; VBIbit   - Polarity of vertical blank bit.
; Extended - Pointer to mode specified data structure.

	STRUC	DisplayInfo
Mode	DD	?
XRes	DD	?
YRes	DD	?
VBIbit	DD	?
Extended	DD	?
	ENDS	DisplayInfo

;----------------------------------------------------------------------------
; Function definitions
;----------------------------------------------------------------------------

	GLOBAL C GetDisplayInfo:NEAR
	GLOBAL C GetVBIBit:NEAR

