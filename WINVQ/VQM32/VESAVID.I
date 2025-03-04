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
;*     vesavid.i
;*
;* DESCRIPTION
;*     VESA video manager definitions. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;****************************************************************************

;----------------------------------------------------------------------------
; VESA video modes
;----------------------------------------------------------------------------

VESA_640X400_256   EQU	0x100
VESA_640X480_256   EQU	0x101
VESA_800X600_16    EQU	0x102
VESA_800X600_256   EQU	0x103
VESA_1024X768_16   EQU	0x104
VESA_1024X768_256  EQU	0x105
VESA_1280X400_16   EQU	0x106
VESA_1280X400_256  EQU	0x107
VESA_TEXT_80X60    EQU	0x108
VESA_TEXT_132X25   EQU	0x109
VESA_TEXT_132X60   EQU	0x10C
VESA_320X200_32K_1 EQU	0x10D
VESA_320X200_32K_2 EQU	0x10E
VESA_640X480_32K   EQU	0x110
VESA_640X480_65K   EQU	0x111
VESA_640X480_16M   EQU	0x112
VESA_800X600_32K   EQU	0x113
VESA_800X600_65K   EQU	0x114
VESA_1024X768_32K  EQU	0x116
VESA_1024X768_65K  EQU	0x117

VESA_MIN EQU	VESA_640X400_256
VESA_MAX EQU	VESA_1024X768_65K

;----------------------------------------------------------------------------
; Structure definitions
;----------------------------------------------------------------------------

; VESAInfo - General information about this VESA implementation.
;            (Filled in by VESA BIOS Function 0)
;
; Signature    - Will always be 'VESA'
; Ver          - Version #
; OEMString    - OEM ID string
; Capabilities - Not defined by VESA yet
; AvailModes   - List of available modes; terminated with -1 (0xffff)
; TotalMemory  - ???
; Reserved     - Pads structure to 256 bytes total

	STRUC	VESAInfo
Signature	DD	?
Ver	DW	?
OEMString	DD	?
Capabilities	DD	?
AvailModes	DD	?
TotalMemory	DW	?
Reserved	DB	236 DUP (?)
	ENDS	VESAInfo

; VESAModeInfo - Information about this VESA mode.
;                (Filled in by VESA BIOS Function 1)
;
; Attributes       - bit 0: 1 = mode is supported
;                    bit 1: 1 = optional info available
;                    bit 2: 1 = std BIOS output functions valid in this mode
;                    bit 3: 0 = monochrome, 1 = color
;                    bit 4: 0 = text mode, 1 = graphics
; WinA_Attributes  - bit 0 = window exists, bit 1=readable, bit 2= writable
; WinB_Attributes  - bit 0 = window exists, bit 1=readable, bit 2= writable
; WinGranularity   - smallest address boundary window can be placed upon;
;                    size is in KB (ie 64, 32, 4)
; WinSize          - size of windows in KB (ie 64, 32)
; WinA_Segment     - location of Window A in CPU space (usually 0xa000)
; WinB_Segment     - location of Window B in CPU space (usually 0xb000)
; WinFunc          - address of window-setting function (This is provided 
;                    as an alternative to Int 10 for speed.)
; BytesPerScanline - # bytes per scan line
; 
; Optional info (available if bit 1 of Attributes is set):
;
; XRes             - X-resolution
; YRes             - Y-resolution
; XCharSize        - Horizontal size of char cell
; YCharSize        - Vertical size of char cell
; NumPlanes        - # of memory planes (???)
; BitsPerPixel     - # bites per pixel
; NumBanks         - # of banks (ie planes)
; MemoryModel      - 00h = Text mode
;                    01h = CGA mode
;                    02h = Hercules
;                    03h = 4 plane planar mode
;                    04h = packed pixel mode (1 byte/pixel)
;                    05h = non-chain 4, 256-color mode
;                    06-0Fh = 
;                    10-FFh = OEM-specific
; BankSize         - Bank size in KB

		STRUC	VESAModeInfo 
Attributes		DW	?
WinA_Attributes	DB	?
WinB_Attributes	DB	?
WinGranularity	DW	?
WinSize		DW	?
WinA_Segment		DW	?
WinB_Segment		DW	?
WinFunc		DD	?
BytesPerScanline	DW	?
XRes		DW	?
YRes		DW	?
XCharSize		DB	?
YCharSize		DB	?
NumPlanes		DB	?
BitsPerPixel		DB	?
NumBanks		DB	?
MemoryModel		DB	?
BankSize		DB	?
NumInputPages		DB	?
Reserved		DB	?
RedMaskSize		DB	?
RedFieldPosition	DB	?
GreenMaskSize		DB	?
GreenFieldPosition	DB	?
BlueMaskSize		DB	?
BlueFieldPosition	DB	?
RsvdMaskSize		DB	?
RsvdFieldPosition	DB	?
DirectColorModeInfo	DB	?
pad		DB	216 DUP (?)
		ENDS	VESAModeInfo

;----------------------------------------------------------------------------
; Function definitions
;----------------------------------------------------------------------------

	GLOBAL C InitVESA:PROC
	GLOBAL C UninitVESA:PROC
	GLOBAL C SetVESAMode:PROC
	GLOBAL C ReadVESAModeInfo:PROC
	GLOBAL C SetVESAWindow:PROC

;----------------------------------------------------------------------------
;
; NAME
;     SET_WINDOW - Sets window A to the specified bank.
;
; SYNOPSIS
;     SET_WINDOW GrainNum
;
; FUNCTION
;     This routine uses the C Set_Window function rather than going through
;     the BIOS, for two reasons: (1) Speed, and (2) On the Cirrus Logic 54xx
;     VESA cards, BIOS calls make noise while playing digital audio.
;
; INPUTS
;     GrainNum - Granularity number.
;
; RESULT
;     NONE
;
;----------------------------------------------------------------------------

	MACRO	SET_WINDOW grain_num
	push	esi
	push	edi
	push	es
	call	SetVESAWindow C,grain_num
	pop	es
	pop	edi
	pop	esi
	ENDM

