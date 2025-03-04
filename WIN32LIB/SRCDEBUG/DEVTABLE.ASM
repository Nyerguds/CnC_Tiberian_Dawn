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

; $Header: g:/library/wwlib32/system/rcs/devtable.asm 1.2 1994/04/28 12:41:29 jeff_wilson Exp $
;***************************************************************************
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : DEVTABLE.ASM                             *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                  Last Update : 12 December, 1990   [CY]                 *
;*                                                                         *
;* Updated to 32bit protected mode JAW					   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
; VOID Init_Device_Table(BYTE *table);                                     *
; WORD Max_Device(VOID);						   *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

LOCALS ??

DOS	equ	21h

GLOBAL	 Max_Device			:NEAR
GLOBAL	 get_max_device 		:NEAR
GLOBAL	 Init_Device_Table		:NEAR
					 

CODESEG

; ----------------------------------------------------------------
;
; Here are prototypes for the routines defined within this module:
;
; VOID Init_Device_Table(BYTE *table);
; WORD Max_Device(VOID);
;
; ----------------------------------------------------------------


;----------------------------------------------------------------------------
;
; WORD Max_Device(VOID);
;

PROC	Max_Device C NEAR
	
	call	get_max_device		; get max devices in ax
	ret

ENDP	Max_Device

;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
;
;
; returns max devices in AX

PROC	get_max_device C NEAR 
	USES ebx,edx
	
	mov	ah,25			; get current drive service
	int	DOS			; drive returned in al
	mov	dl,al
	mov	ah,14			; set current as current drive
	int	DOS
	dec	al			; al = max drives, make it n - 1
	xor	ah,ah			; clear high byte
	sub	edx,edx
	mov	edx,eax			; use dx to go backward to find out
					; if DOS is lying (down)

??back_loop:
	push	ds
	push	ebx
	mov	bl,dl			; find out about the drive in dl
	inc	bl
	mov	eax,0440Eh 		; get the physical drive associated
	int	DOS			; with this letter
	pop	ebx
	pop	ds
	jnc	short ??later		; if c clear, no error
	
	cmp	al,0Fh			; was it invalid? (0Fh = invalid)
	jne	short ??later			; yes, so LATER
	
	dec	edx
	jmp	??back_loop		; try, try again

??later:
	mov	eax,edx			; restore ax
	ret

ENDP	get_max_device

;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
;
; VOID Init_Device_Table(BYTE *table);
;

PROC	Init_Device_Table C NEAR 

	USES eax,ebx,edi,edx
	ARG	table:DWORD	   	; Pointer to device table.
	LOCAL	curr_drive:BYTE	   	; Copy of current drive number.

	mov	edi,[table]

	call	get_max_device		; get max devices in ax
	add	edi,eax
	std
	mov	[curr_drive],al	; save it

??next_drive:
	mov	dl,[curr_drive]	; copy current drive #
	cmp	dl,0FFh			; are we done?
	je	short ??later			; if so, later

	dec	[curr_drive]		; dec our local drive #

	push	ds
	push	ebx
	mov	bl,dl			; find out about the drive in dl
	inc	bl
	mov	eax,0440Eh 		; get the physical drive associated
	int	DOS			; with this letter
	pop	ebx
	pop	ds

	jnc	short ??it_is_real		; jump if no error
	cmp	al,01			; 1 = invalid command, 
					; 0F = invalid device
	je	short ??set_as_current	; 1? it is ok (RAM device)
	jmp	short ??invalid		; 0Fh, it was not a device


??it_is_real:
	cmp	al,0			; was it a fixed device?
	je	short ??set_as_current	; yes, it's ok
	
	dec	al			; make it a drive #
	cmp	al,dl			; is it a valid drive?
	je	short ??set_as_current

;
; Device was logical and not active, so clear the entry
;
??invalid:
	xor	al,al
	stosb
	cmp	[curr_drive],0		; are we done checking?
	jge	??next_drive	   	; no, go to next
	
	jmp	short ??later

??set_as_current:
	mov	al,1
	stosb
	cmp	dl,0			; are we before the A drive (invalid)
	jl	short ??later			; yes, we are done checking
	
	jmp	??next_drive		; keep processing

??later:
	cld
	ret

ENDP	Init_Device_Table

;----------------------------------------------------------------------------

END
