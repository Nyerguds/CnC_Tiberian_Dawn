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
;*                 Project Name : Vesa Hookup                              *
;*                                                                         *
;*                                                                         *
;*                   Programmer : Julio R. Jerez                           *
;*                                                                         *
;*                   Start Date : Jan 31, 1995                             *
;*                                                                         *
;*                                                                         *
;*-------------------------------------------------------------------------*



IDEAL
P386
MODEL USE32 FLAT

INCLUDE "svgaprim.inc"


DPMI_INTR equ 031h


LOCALS ??

;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////// Prototypes //////////////////////////////////////

GLOBAL	  RMVesaVector    : DWORD
GLOBAL	  RMVesaRegs      : DWORD	
GLOBAL	  RMVesaVectorSel : DWORD
GLOBAL	  Vesa_Hook    	  : NEAR
GLOBAL	  Remove_Vesa 	  : NEAR
GLOBAL	  VesaFunc	  : dword

;//////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////// Data ////////////////////////////////////////
	DATASEG

; The current time we will just include the real mode stuff
; into the protected mode code and then copy it down.  The C side of
; this will handle this method or reading it off of disk in the real
; method.

LABEL 	RealDataStart BYTE
include "VesaReal.ibn"
LABEL	RealDataEnd BYTE

RMVesaVectorSel DD	0

;//////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////// Code ////////////////////////////////////////

	CODESEG

PROC	Vesa_Hook C Near
	USES	ebx,ecx,edx,ecx,edi,esi
	ARG	vesa_ptr:DWORD

	; Are they attempting to set timer again?
	cmp	[RMVesaVectorSel],0
	jnz	??exit

	; now allocate real mode memory and copy the rm binary down to it.
	mov	eax,0100h		; set function number
	lea	ebx , [RealDataEnd]
	sub	ebx , offset RealDataStart
	push	ebx

	add	ebx , 15 + 040h
	shr	ebx,4			; convert to pages.
	int	DPMI_INTR	 	; do call.
	pop	ecx
	jc	??error		 	; check for error.

	; set up source and destination pointers for the copy.
	shl	edx , 16
	mov	[ RMVesaVectorSel ] , edx
	shl	eax,4			; convert segment to offset.

	mov	edi , ecx
	xor	esi , esi

;	push	ecx
;	push	eax
;	mov	ecx , eax
;	shld	ebx,ecx,16
;	mov	eax,0600h			; function number.
;   	int	DPMI_INTR			; do call.
;	pop	eax
;	pop	ecx
;	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.

	lea	esi , [ RealDataStart]
	lea	edi , [ eax + 040h ]	; put it into esi for copy.
	rep	movsb			; write RM bin to RM memory.

	mov	edx,[vesa_ptr]		; Setup vesa funtion
	mov	[ eax + 40h - 4 ] , edx


       ; Chain the Real Vesa funcion interrupt to any avilable
       ; Interrupt vector so We make sure that the Real Mode
       ; Keyboard Interrupt service get called at debuging time
       ; of the library.

       mov	[ RMVesaRegs ] , eax
       shl	eax , 12
       lea	edi , [ eax + 040h ]  ; ofsset of VesaFunc
       mov	bl , 060h
       mov	bh , 6
       mov	eax , 200h
 ??find:
       int	DPMI_INTR
       jc	??error
       or	cx,dx
       jz	??found
       inc	bl
       dec	bh
       jnz	??find
       jmp	??error
 ??found:
       mov	eax , 0201h	
       mov	edx , edi
       shld	ecx , edx , 16
       and	ebx , 0ffh
       mov	[ RMVesaVector ] , ebx
       int	DPMI_INTR
       jc	??error

 ??exit:
       xor	eax,eax			; signal an error.
       ret	       
 ??error:	
       mov 	eax , -1 
       ret	
      ENDP



PROC	Remove_Vesa C Near
	USES	ebx,ecx,edx,ecx,edi,esi
	ARG	vesa_ptr:DWORD


	; Are they attempting to set timer again?
	mov     [VesaFunc],0
	cmp	[RMVesaVectorSel],0
	jz	??exit

       mov	ebx , [ RMVesaVector ]
       test	ebx , ebx
       jz	??exit
       mov	eax , 0201h	
       xor	edx , edx
       xor	ecx , ecx 
       int	DPMI_INTR
       mov	[ RMVesaVector ] , 0
       jc	??exit

;       mov	eax , 0601h
;       mov 	ecx , [ RMVesaRegs ] 
;       shld	ebx , ecx , 16
;       lea	edi , [RealDataEnd]
;       sub	edi , offset RealDataStart
;       add	edi , 15 + 040h
;       xor	esi , esi
;       int	DPMI_INTR
;       jc	??exit

	mov	eax,0101h		; set function number
	mov	edx ,[RMVesaVectorSel]
	test 	edx , edx
	jz	??exit
	shr	edx , 16
	int	DPMI_INTR	 	; do call.
	mov	[RMVesaVectorSel],0
??exit:
       ret	
      ENDP


END



