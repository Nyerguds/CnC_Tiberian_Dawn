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

; $Header: g:/library/wwlib32/system/rcs/opsys.asm 1.1 1994/04/18 09:14:12 jeff_wilson Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Operating System Flags                   *
;*                                                                         *
;*                    File Name : OPSYS.ASM                                *
;*                                                                         *
;*                   Programmer : Scott Bowen                              *
;*                                                                         *
;*                   Start Date : January 26, 1993                         *
;*                                                                         *
;*                  Last Update : January 26, 1993   [SB]                  *
;*                                                                         *
;* Updated to 32bit protected mode JAW					   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Operating_System -- Determines what the operating system is.          *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

GLOBAL             C Operating_System         :NEAR
GLOBAL             C OperatingSystem          :WORD

DOS		equ	1
WIN31STD	equ	2
WIN31ENH	equ	3
WIN30ENH	equ	4
WIN30STD	equ	5
WIN30REAL	equ	6

DATASEG

OperatingSystem	dw	0


CODESEG

;***************************************************************************
;* Operating_System -- Determines what the operating system is.            *
;*                                                                         *
;* INPUT:   NONE.                                                          *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/26/1993  SB : Created.                                             *
;*=========================================================================*
PROC	Operating_System C near
	USES ebx,ecx,edx,es,edi


	; Check for Windows 3.1
	mov	eax,160Ah		; WIN31CHECK
	int	2fh
	or	ax,ax
	jz	short RunningUnderWin31

	;check for Windows 3.0 enhanced mode
	mov 	eax,1600h		; WIN386CHECK
	int	2fh
	mov	bl,al
	mov	eax,WIN30ENH
	test	bl,7fh
	jnz	short Exit

	;check for 3.0 WINOLDAP
	mov	eax,4680h		; IS_WINOLDAP_ACTIVE
	int	2fh
	or	eax,eax
	jnz	short NotRunningUnderWin

	; rule out MS-DOS 5.0 task switcher
	mov	eax,4b02h		; detect switcher
	push	ebx
	push	es
	push	edi
	xor	ebx,ebx
	mov	edi,ebx
	mov	es,bx
	int	2fh
	pop	edi
	pop	es
	pop	ebx
	or	eax,eax
	jz	short NotRunningUnderWin	; MS-DOS 5.0 task switcher found.

	; check for standrd mode Windows 3.0
	mov	eax,1605h		;PMODE_START
	int	2fh
	mov	eax,WIN30STD
	cmp	ecx,-1
	jz	short Exit

	;check for real mode Windows 3.0
	mov	eax,1606h		; PMODE_STOP
	int	2fh
	mov	eax,WIN30REAL
	jmp	SHORT Exit

RunningUnderWin31:
	; At this point: CX == 3 means Windows 3.1 enhanced mode.
	;                CX == 2 means Windows 3.1 standard mode.
	mov	eax,WIN31STD
	cmp	ecx,2
	je	short Exit

	mov	eax,WIN31ENH
	jmp	SHORT Exit

NotRunningUnderWin:
	mov	eax,DOS

Exit:
	mov [WORD PTR OperatingSystem], ax
	ret

ENDP	Operating_System



;----------------------------------------------------------------------------

END