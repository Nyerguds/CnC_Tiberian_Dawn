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
;**      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : VESA.ASM                                 *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : December 8, 1994                         *
;*                                                                         *
;*                  Last Update : December 8, 1994   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Vesa_Asm_Set_Win -- Sets the current vesa window from Asm             *
;*   Vesa_Asm_Next_Window -- Sets to the next vesa window                  *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT
LOCALS  ??

INCLUDE "svgaprim.inc"

GLOBAL	RMVesaVector	: DWORD
GLOBAL	RMVesaRegs	: DWORD


DPMI_INTR	EQU	31h	

STRUC DPMI_REGS
       _edi  dd ?
       _esi  dd ?	
       _ebp  dd ?	
       	     dd ?
       _ebx  dd ?	
       _edx  dd ?	
       _ecx  dd ?	
       _eax  dd ?	
       Flags dw ?
       _es   dw ?
       _ds   dw ?
       _fs   dw ?
       _gs   dw ?
       _ip   dw ?
       _cs   dw ?
       _sp   dw ?
       _ss   dw ?
       	     dd ?	
ENDS


DATASEG

cpu_video_page	dd           0h
cpu_page_limit  dd	0b0000h
CurrentBank	DD  	     0h		; current vesa bank  
RealFunc	DPMI_REGS   ?		; structure to call a real mode int


	CODESEG


;***************************************************************************
;* VESA_ASM_SET_WIN -- Sets the current vesa window from Asm               *
;*                                                                         *
;* INPUT:	edi - offset to set the window for                         *
;*                                                                         *
;* OUTPUT:      edi - adjusted offset for window                           *
;*                                                                         *
;* PROTO:	void Vesa_Asm_Set_Win(void);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   12/08/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Vesa_Asm_Set_Win C near 

	push	eax
	push	edi
	push	ecx
	push	ebx


	mov	eax , edi
	and	eax , 0ffff0000h
	add	eax , 010000h
	mov	[ cpu_page_limit ] , eax

	lea	eax , [ edi - 0a0000h ]
	and	eax , 0ffff0000h
	mov	[ cpu_video_page ] , eax

	shr	eax , 14
	cmp	eax , [ CurrentBank ]
	jz	 ??no_change
	mov	[CurrentBank],eax		; it will be new current bank
	mov	ebx , [ BankTable + eax ]	; find gran value of new bank

	mov     edi , [ RMVesaRegs ]		; clean up RMRegister bank
	xor	eax , eax
	mov	ecx , 34h / 4			; size of RMRegs Bank
	rep	stosd

	mov     edi , [ RMVesaRegs ]
	mov	[(type DPMI_REGS ptr edi ) . _eax ] , 04f05h
	mov	[(type DPMI_REGS ptr edi ) . _ebx ] , 0
	mov	[(type DPMI_REGS ptr edi ) . _edx ] , ebx

	mov	eax , 0300h
	xor	ecx , ecx			; set amount to copy of stack
	mov	ebx , [ RMVesaVector]		; set pointer to func to call
	int	DPMI_INTR			; make the call
 ??no_change:
	pop	ebx
	pop	ecx
	pop	edi
	pop	eax
	and	edi,0000ffffh			; adjust edi to be 64k
	add	edi,0a0000h
	ret
	ENDP	Vesa_Asm_Set_Win

END
