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
;*                 Project Name : Hard/Critical Error Handler              *
;*                                                                         *
;*                    File Name : harderr.asm				   *
;*                                                                         *
;*                   Programmer : Scott K. Bowen.			   *
;*                                                                         *
;*                   Start Date : July  18, 1994                           *
;*                                                                         *
;*                  Last Update : July 26, 1994   [SKB]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Install_Hard_Error_Handler -- Setup for handling critical errors      *
;*   Remove_Hard_Erroror_Handler -- Remove the critical error handler stuff*
;*   Critical_Error_Handler -- Catch critical error interrupt.             *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

LOCALS ??

;INCLUDE "tntdos.inc"


;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Equates ////////////////////////////////////////
DOS_SYS_CALL	EQU	21h		; to do TNT DOS-XNDR system calls.
LOCK_PAGES	EQU	5		; Lock pages subfunction using DX_MEM_MGT
UNLOCK_PAGES	EQU	6		; Unlock pages subfunction using DX_MEM_MGT
CRITERR_INT_NUM EQU	24h

DISK_ERROR_BIT	EQU	01000000000000000b ; bit 7 of dh.
DISK_ERROR	EQU	1		; Value of Hard_Error_Occured if disk/floppy error.
OTHER_ERROR	EQU	2		; Value of Hard_Error_Occured if other type of error.

;
; Interrupt handler stack frame
;
_FLGS	equ	[DWORD PTR ebp+52]	; 386|DOS-Extender flags
_GS	equ	[WORD PTR ebp+48]	; original GS
_FS	equ	[WORD PTR ebp+44]	; original FS
_DS	equ	[WORD PTR ebp+40]	; original DS
_ES	equ	[WORD PTR ebp+36]	; original ES
_SS	equ	[WORD PTR ebp+32]	; original SS
_ESP	equ	[DWORD PTR ebp+28]	; original ESP
_EFLAGS	equ	[DWORD PTR ebp+24]	; original EFLAGS
_CS	equ	[DWORD PTR ebp+20]	; original CS
_EIP	equ	[DWORD PTR ebp+16]	; original EIP
_EBP	equ	[DWORD PTR ebp]		; original EBP

;
; DOS critical error stack frame
;
_DOS_FLAGS equ	[WORD PTR es:ebx+22]	; interrupt stack frame from real
_DOS_CS	equ	[WORD PTR es:ebx+20]	; mode INT 21h
_DOS_IP	equ	[WORD PTR es:ebx+18]	;
_DOS_ES	equ	[WORD PTR es:ebx+16]	; regs at time INT 21h was issued
_DOS_DS	equ	[WORD PTR es:ebx+14]		; in real mode
_DOS_BP	equ	[WORD PTR es:ebx+12]		;
_DOS_DI	equ	[WORD PTR es:ebx+10]		;
_DOS_SI	equ	[WORD PTR es:ebx+8]		;
_DOS_DX	equ	[WORD PTR es:ebx+6]		;
_DOS_CX	equ	[WORD PTR es:ebx+4]		;
_DOS_BX	equ	[WORD PTR es:ebx+2]		;
_DOS_AX	equ	[WORD PTR es:ebx]		;


; 
; Error codes put into Hard_Error_Code
;
DISK_WRITE_PROTECTED	equ	00h
UNKOWN_DEVICE		equ	01h
DRIVE_NOT_READY		equ	02h
UNKOWN_COMMAND		equ	03h
CRC_ERROR		equ	04h
WRONG_DATA_LENGTH	equ	05h
SEEK_ERROR		equ	06h
UNKOWN_DEVICE_TYPE	equ	07h
SECTOR_NOT_FOUND	equ	08h
OUT_OF_PAPER		equ	09h
WRITE_ERROR		equ	0Ah
READ_ERROR		equ	0Bh
GENERAL_ERROR		equ	0Ch

;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////// Prototypes ///////////////////////////////////////

GLOBAL	 Install_Hard_Error_Handler :NEAR
GLOBAL	 Remove_Hard_Error_Handler  :NEAR

;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////// Global/Local Data //////////////////////////////////

DATASEG

LABEL	LockedDataStart	BYTE	
Hard_Error_Occured	DB	0	; Hard disk error or other error.
Hard_Error_Code		DB	0	; Error Code.	
LABEL	LockedDataEnd	BYTE


OldRMI		DD	?	; original real mode critical err vector
OldPMIOffset	DD	?	; original protected mode critical err vector
OldPMISelector	DD	?     	; original PM crit error selector.

InitFlags	DD	0	; Flags to indicate what has been initialized.

; InitFlags that are set to have a fully functional interrupt.
IF_SET_VECTORS		equ	1		; Vectors have been set.
IF_LOCKED_PM_CODE	equ	2		; Locked PM code for DPMI.
IF_LOCKED_PM_DATA	equ	4		; Locked PM data for DPMI.
IF_FUNCTIONAL		equ	8		; crit error is in and functional.


;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Code //////////////////////////////////////////

CODESEG

;***************************************************************************
;* INSTALL_HARD_ERROR_HANDLER -- Setup for handling critical errors.         *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/26/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC Install_Hard_Error_Handler C near
	USES eax,ebx,ecx,ds,es
	ret

	ENDP Install_Hard_Error_Handler


;***************************************************************************
;* REMOVE_HARD_ERROROR_HANDLER -- Remove the critical error handler stuff    *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/26/1994 SKB : Created.                                             *
;*=========================================================================*

	PROC 	Remove_Hard_Error_Handler C near
	USES 	ebx,ecx,edx,ds,es
;
; Restore the original interrupt vectors and exit
;

	ret

	ENDP Remove_Hard_Error_Handler


;***************************************************************************
;* Critical_Error_Handler -- Catch critical error interrupt.               *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/26/1994 SKB : Created.                                             *
;*=========================================================================*

LABEL 	LockedCodeStart	BYTE

	PROC Critical_Error_Handler NEAR

	ENDP Critical_Error_Handler

LABEL 	LockedCodeEnd		BYTE

END

