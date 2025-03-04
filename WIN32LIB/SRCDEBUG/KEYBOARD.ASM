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
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Library                                  *
;*                                                                         *
;*                    File Name : KEYBOARD.ASM                             *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                   Start Date : May 21, 1992                             *
;*                                                                         *
;*                  Last Update : July 15, 1994   [PWG]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Get_RM_Timer_Address -- Return address of real mode code for copy.    *
;*   Get_RM_Keyboard_Size -- return size of real mode timer code.          *
;*   Check_Key -- checks queue for key (make)                              *
;*   Check_Key_Num -- Checks if key in queue, return key num               *
;*   Get_Key_Num -- Returns the next key num in ax                         *
;*   KN_To_KA -- Translates a key num to an ASCII key                      *
;*   Low_Get_Key -- low level get key returns key num and bits             *
;*   Convert_Num_To_ASCII -- Assembly routine converts keynum to ASCII key *
;*   KeyNum_Translate -- Performs a lowlevel xlate to a keycode            *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*
;*	Keyboard driver -- 80386 Protected Mode Assembly portion	   *
;*	updated by: Phil Gorrow for 32 bit Protected Mode
;***************************************************************************
;
; ----------------------------------------------------------------

IDEAL				; the product runs in ideal mode
P386				; use 386 real mode instructions
MODEL USE32 FLAT
LOCALS ??			; ?? is the symbol for a local
;WARN				; generate all warnings we can
JUMPS				; optimize jumps if possible

;---------------------------------------------------------------------------
; Make some general equates for easy compatability
;---------------------------------------------------------------------------
PROT_INT_ENABLE	EQU	1		; if false protected int just calls real mode int

DPMI_INTR	EQU	31h
IRQ1INTNUM	EQU	09h		; IRQ1 interrupt vector number.
BRKINTNUM	EQU	23h		; Crtl-C (Break) interrupt vector number
DBGINTNUM	EQU	3h		; Debug interrupt vector number
DOS_SYS_CALL	EQU	21h		; to do TNT DOS-XNDR system calls.
LOCK_PAGES	EQU	5		; Lock pages subfunction using DX_MEM_MGT
UNLOCK_PAGES	EQU	6		; Unlock pages subfunction using DX_MEM_MGT
CLEARISR	EQU	020H	; value to clear In Service Register
INTCHIP0	EQU	020H	; 8259 interrupt chip controller 0
;---------------------------------------------------------------------------
; Include all of the keyboard specific defines
;---------------------------------------------------------------------------
	INCLUDE "keyboard.inc"
	INCLUDE "keystruc.inc"
	INCLUDE "drawbuff.inc"

	GLOBAL C	 RealModePtr:DWORD

	GLOBAL C	 Install_Keyboard_Interrupt:NEAR
	GLOBAL C	 Get_RM_Keyboard_Address:Near
	GLOBAL C	 Get_RM_Keyboard_Size:Near
	GLOBAL C	 Remove_Keyboard_Interrupt:NEAR
	GLOBAL C	 Check_Key_Num:NEAR
	GLOBAL C	 Get_Key_Num:NEAR
	GLOBAL C	 KN_To_KA:NEAR
	GLOBAL C	 KeyNum_Translate:NEAR
	GLOBAL C	 Check_Key:NEAR
	GLOBAL C	 Get_Key:NEAR
	GLOBAL C	 Keyboard_Attributes_On:NEAR
	GLOBAL C	 Clear_KeyBuffer:NEAR
	GLOBAL C	 Key_Down:NEAR
	GLOBAL C	 Keyboard_Attributes_Off:NEAR
	GLOBAL C	 Check_Key_Bits:NEAR
	GLOBAL C	 Get_Key_Bits:NEAR
	GLOBAL C	 Key_Satisfied:NEAR
	GLOBAL C	 Stuff_Key_WORD:NEAR
	GLOBAL C	 Stuff_Key_Num:NEAR
	GLOBAL C	 MouseQX:DWORD
	GLOBAL C	 MouseQY:DWORD
;DBG
	GLOBAL C   Keyboard_Interrupt:NEAR


	DATASEG
; For the current time we will just include the real mode stuff
; into the protected mode code and then copy it down.  The C side of
; this will handle this method or reading it off of disk in the real
; method.

LABEL 	RealBinStart	BYTE
include "keyireal.ibn"
LABEL	RealBinEnd	BYTE

LABEL	LockedDataStart	BYTE
RMVector	DD	0
RealModeSel	DD	0
RealModePtr	DD	0		; Pointer to real mode memory.
RealModeSize	DD	0		; Pointer to real mode memory.
LABEL	LockedDataEnd	BYTE



Ascii	DB	0,"`1234567890-=",0,8,9,"qwertyuiop[]\",0,"asdfghjkl;'"
	DB	0,13,0,45,"zxcvbnm,./",0,0,0,0,0," "

Shift	DB	0,"~!@#$%^&*()_+",0,8,9,"QWERTYUIOP{}|",0,"ASDFGHJKL:",22H
	DB	0,13,0,45,"ZXCVBNM<>?",0,0,0,0,0," "

Alpha_Lower	DB	0
	DB	"~!@#$%^&*()_+",0,8,9,"qwertyuiop{}|",0,"asdfghjkl:",22H
	DB	0,13,0,45,"zxcvbnm<>?",0,0,0,0,0," "

Alpha_Shift	DB	0
	DB	"`1234567890-=",0,8,9,"QWERTYUIOP[]\",0,"ASDFGHJKL;'"
	DB	0,13,0,45,"ZXCVBNM,./",0,0,0,0,0," "

Edit	DB	0AEH,0ADH,000H,000H,0B5H,0B9H,0B1H,000H,0B8H,0B0H,0B7H,0AFH
	DB	000H,000H,0B3H,000H,0B9H,0B5H,0B1H,000H, "/",0B8H,0B4H,0B0H
	DB	0AEH, "*",0B7H,0B3H,0AFH,0ADH, "-", "+",000H,00DH,000H

NumPad	DB	0,"741",0,"/8520*963.-+",0,13,0


GetKeyLock	DW	0	; snap shot of num and caps lock bits
InitFlags	DW	0
MouseQX		DD	0
MouseQY		DD	0

	CODESEG
;***************************************************************************
;* GET_RM_TIMER_ADDRESS -- Return address of real mode code for copy.      *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      VOID * to the address of the real mode timer               *
;*                                                                         *
;* PROTO:	VOID	*Get_RM_Keyboard_Address(VOID);			   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_RM_Keyboard_Address C Near
ifdef NOT_FOR_WIN95

	mov	eax, OFFSET RealBinStart
	ret
endif;ifdef NOT_FOR_WIN95

	ENDP

;***************************************************************************
;* GET_RM_KEYBOARD_SIZE -- return size of real mode timer code.            *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      LONG size of the real mode timer code                      *
;*                                                                         *
;* PROTO:	LONG	Get_RM_Keyboard_Size(VOID);
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_RM_Keyboard_Size C Near

ret
	mov	eax, OFFSET RealBinEnd - OFFSET RealBinStart
	ret

	ENDP
;***************************************************************************
;* INSTALL_KEYBOARD_INTERRUPT -- Installs the keyboard interrupt           *
;*                                                                         *
;* INPUT:	int rm_ptr  - ptr to the real mode handler		   *	   *
;*		int rm_size - size of the real mode handler		   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:	VOID Install_Keyboard_Interrupt(int rm_ptr, int rm_size);  *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Install_Keyboard_Interrupt C NEAR
	USES	eax,ebx,ecx,edx,esi,edi
	ARG	rm_ptr:DWORD
	ARG	rm_size:DWORD

ifdef NOT_FOR_WIN95
	; Are they attempting to set timer again?
	cmp	[RealModePtr],0
	jnz	??error

	; Make sure all flags are cleared.
	cmp	[InitFlags],0
	jnz	??error


	; Before setting the interrupt vectors, the code needs to be locked
	; for DPMI compatability.  Any code or data accessed must be lockded
	; so that no page faults accure during an interrupt.
	; First lock the code, then the data.  The stack will already be locked.
	; The real mode code is also already locked be default.
	; To lock a page set up registers :
	; AX = 0600h
	; BX:CX	= starting linear address of memory block
	; SI:DI = size of region

	mov	eax,0600h			; function number.
	mov	ecx,OFFSET LockedCodeStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedCodeEnd	; edi will have size of region in bytes.
	shld	ebx,ecx,16
	sub	edi, ecx
	shld	esi,edi,16
   	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
	or	[InitFlags],IF_LOCKED_PM_CODE

	mov	eax,0600h			; function number.
	mov	ecx,OFFSET LockedDataStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedDataEnd	; edi will have size of region in bytes.
	shld	ebx,ecx,16
	sub	edi, ecx
	shld	esi,edi,16
   	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
	or	[InitFlags],IF_LOCKED_PM_DATA

	; now allocate real mode memory and copy the rm binary down to it.
	mov	eax,0100h	; set function number
	mov	ebx,[rm_size]		; get size of RM binary.
	mov	[RealModeSize],ebx
	add	ebx,15			; round up
	shr	ebx,4			; convert to pages.
	int	DPMI_INTR	 	; do call.
	jc	??error		 	; check for error.
	or	[InitFlags],IF_ALLOC_RM ; set successful
	mov	[RealModeSel],edx
	shl	eax,4			; convert segment to offset.
	mov	[RealModePtr],eax	; save offset to global variable.

	; now lock the real mode memory that we allocated
	mov	eax,0600h		; function number.
	mov	ecx,[RealModePtr]	; ecx must have start of memory.
	mov	edi,[RealModeSize]	; edi will have size of region in bytes.
	shld	ebx,ecx,16
	shld	esi,edi,16
   	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
	or	[InitFlags],IF_LOCKED_RM_CODE



	; set up source and destination pointers for the copy.
	mov	eax,[RealModePtr];	; set up our dest pointer
	mov	esi,[rm_ptr]		; Set up our source pointer.
	mov	edi,eax			; put it into esi for copy.
	mov	ecx,[rm_size]
	rep	movsb			; write RM bin to RM memory.

	; restore esi to point to data and initialize some of it.
	mov	esi,[RealModePtr]
	mov	eax,esi
	shl	eax,12						; make seg in high eax.
	mov	ax,[(KeyboardType PTR esi).CallKeyRMIntOffset]	; create RM addr of call chain.
	mov	[(KeyboardType PTR esi).CallKeyRMIntAddr],eax	; save it for use in PM int.

IF NOT PROT_INT_ENABLE
       ; Chain the Real Keyboard interrupt to any avilable
       ; Interrupt vector so We make sure that the Real Mode
       ; Keyboard Interrupt service get called at debuging time
       ; of the library.

       mov	edi , eax
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
       movzx	ebx , bl
       mov	[ byte ptr RMVector ] , bl
       mov	[ 4 * ebx ] , edi
ENDIF



	;-------------------------------------------------------
	; Initialize all of the keyboard specific information
	;-------------------------------------------------------
	xor	eax,eax			; clear the high bits of eax
	mov	al,[417H]		; get keyboard status flags
	test	eax,040H 		; caps lock active?
	je 	short ??nocap		; not active
	or	[(KeyboardType PTR esi).KeyLock],CAPSLOCK

??nocap:
	test	eax,020H			; num lock active?
	je	short ??nonumlock		; not active
	or	[(KeyboardType PTR esi).KeyLock],NUMLOCK

??nonumlock:
	test	eax,002H			; is left shift key down?
	je	short ??noleftshift		; try the right
	or	[(KeyboardType PTR esi+5).KeysUpDown],010H

??noleftshift:
	and	eax,001H			; get right shift bit
	shl	eax,9			; put it into the proper position (shl al,1 mov ah,al)
	mov	al,[418H]		; get alt and ctrl bits
	shl	al,2			; put in proper position
	shl	al,1
	and	al,00CH			; only alt and ctrl bits
	or	ah,al			; put them ah for Keys+7 later
	mov	al,[496H]		; get extended keys
	test	al,008H			; check for right alt key
	je	short ??noralt
	or	ah,040H
??noralt:
	mov	[(KeyboardType PTR esi+7).KeysUpDown],ah
	test	al,004H			; test for right ctrl
	je 	short ??norctrl
	or	[(KeyboardType PTR esi+8).KeysUpDown],001h
??norctrl:
	test	al,002H			; last code E0?
	je short ??noe0
	mov	[(KeyboardType PTR esi).LastKeyE0],001h
??noe0:
	test	al,001H			; last code E1?
	je short ??noe1
	mov	[(KeyboardType PTR esi).LastKeyE1],002h
??noe1:
	;==========================================================================
	; Get the protected mode interrupt vector keyboard.
	; input ax = 0204
	; bl = number of interrupt to get
	; output: cf error
	; ES:EBX = address of PM int handler routine.
	;==========================================================================
	mov	eax,0204h		; Get proteced mode
	mov	bl,IRQ1INTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	mov	[(KeyboardType PTR esi).KeyOldPMIOffset],edx	; save offset.
	mov	[(KeyboardType PTR esi).KeyOldPMISelector],ecx	; save selector.

	;==========================================================================
	; Get the real mode interrupt vector keyboard
	; input ax = 2503, cl = number of interrupt to get
	; output cf error, EBX = address (seg:off) of RM int handler routine.
	; cl set above
	;==========================================================================
	mov	eax,0200h
	mov	bl,IRQ1INTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	shl 	edx,16
	shld	ecx,edx,16
	mov	[(KeyboardType PTR esi).KeyOldRMI],ecx


	;==========================================================================
	; Now it is time to set the Protected mode interrupt Keyboard
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,IRQ1INTNUM
	mov	cx , cs
	lea	edx, [Keyboard_Interrupt] ; get address of protected code int hand.
	int	DPMI_INTR		  ; do call.
	jc	??error
	or	[InitFlags],IF_SET_VECTORS

	;==========================================================================
	; Now it is time to set the real Interrupt Keyboard
	; ax = function number (0201
	; bl = number of interrupt to set
	; cx:dx = address of RM interrupt handler
	;==========================================================================

	mov	eax, 0201h
	mov	bl,IRQ1INTNUM
	mov	ecx,[RealModePtr]     	; get address of real code int hand.
	shr	ecx,4			; put segment in hi word.
	mov	dx,[(KeyboardType PTR esi).KeyCodeOffset] ; Get address of code
	int	DPMI_INTR		; do call.
	jc	??error

	;==========================================================================
	; Get the protected mode interrupt vector - for the break interrupt
	; input ax = 0204
	; bl = number of interrupt to get
	; output: cf error
	; ES:EBX = address of PM int handler routine.
	;==========================================================================

	mov	eax,0204h		; Get proteced mode
	mov	bl,BRKINTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	mov	[(KeyboardType PTR esi).BrkOldPMIOffset],edx	; save offset.
	mov	[(KeyboardType PTR esi).BrkOldPMISelector],ecx	; save selector.


	;==========================================================================
	; Get the real mode interrupt vector - for the break interrupt
	; input ax = 0200, bl = number of interrupt to get
	; output cf error, EBX = address (seg:off) of RM int handler routine.
	; cl set above
	;==========================================================================
	mov	eax,0200h
	mov	bl,BRKINTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	shl 	edx,16
	shld	ecx,edx,16
	mov	[(KeyboardType PTR esi).BrkOldRMI],ecx

	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,BRKINTNUM
	mov	cx , cs
	lea	edx, [Break_Interrupt] ; get address of protected code int hand.
	int	DPMI_INTR		  ; do call.
	jc	??error
	or	[InitFlags],IF_SET_VECTORS


	;==========================================================================
	; Now it is time to set the real Interrupt
	; ax = function number (0201
	; bl = number of interrupt to set
	; cx:dx = address of RM interrupt handler
	;==========================================================================

	mov	eax, 0201h
	mov	bl,BRKINTNUM
	mov	ecx,[RealModePtr]     	; get address of real code int hand.
	shr	ecx,4			; put segment in hi word.
	mov	dx,[(KeyboardType PTR esi).BrkCodeOffset] ; Get address of code
	int	DPMI_INTR		; do call.
	jc	??error
	or	[InitFlags],IF_SET_VECTORS

IF DEBUG
	;==========================================================================
	; Get the protected mode interrupt vector - for the Debug interrupt
	; input ax = 0204
	; bl = number of interrupt to get
	; output: cf error
	; ES:EBX = address of PM int handler routine.
	;==========================================================================

	mov	eax,0204h		; Get proteced mode
	mov	bl,DBGINTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	mov	[(KeyboardType PTR esi).DbgOldPMIOffset],edx	; save offset.
	mov	[(KeyboardType PTR esi).DbgOldPMISelector],ecx	; save selector.

	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,DBGINTNUM
	mov	cx , cs
	lea	edx, [Debug_Interrupt] ; get address of protected code int hand.
	int	DPMI_INTR		  ; do call.
	jc	??error
	or	[InitFlags],IF_SET_VECTORS
ENDIF

	; we have finished with success.
	mov	eax,1			; signal success.
	ret
??error:
       	xor	eax,eax			; signal an error.
??exit:
endif ;NOT_FOR_WIN95
	ret
	ENDP	Install_Keyboard_Interrupt

;***************************************************************************
;* REMOVE_INTERRUPT -- Removes keyboard interrupt and restores chain	   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:	VOID Remove_Interrupt(VOID)                                *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/13/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Remove_Keyboard_Interrupt C NEAR
	USES	ebx,ecx,edx

ifdef NOT_FOR_WIN95
	; verifie that the keyboard was previosly install
	; this is here in case of a page fault crash
	mov	esi,[RealModePtr]
	test    esi,esi
	jz      ??error

	test	[InitFlags],IF_SET_VECTORS
	jz	??vectors_not_set

	; disengage Keyboard Interrupt handle
	;==========================================================================
	; Now it is time to set the real Interrupt
	; ax = function number (0201
	; bl = number of interrupt to set
	; cx:dx = address of RM interrupt handler
	;==========================================================================

	mov	eax, 0201h
	mov	bl,IRQ1INTNUM
	mov	edx,[(KeyboardType esi).KeyOldRMI]     	; get address of real code int hand.
	shld	ecx , edx , 16
	int	DPMI_INTR		; do call.
	jc	??error

	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,IRQ1INTNUM
	mov	ecx,[(KeyboardType esi).KeyOldPMISelector] 	; Get PM segment to put int ds later.
	mov	edx,[(KeyboardType esi).KeyOldPMIOffset] 	; Get PM offset
	int	DPMI_INTR		  ; do call.
	jc	??error



	; disengage Control Break Interrupt handle
	;==========================================================================
	; Now it is time to set the real Interrupt
	; ax = function number (0201
	; bl = number of interrupt to set
	; cx:dx = address of RM interrupt handler
	;==========================================================================

	mov	eax, 0201h
	mov	bl,BRKINTNUM
	mov	edx,[(KeyboardType esi).BrkOldRMI]     	; get address of real code int hand.
	shld	ecx , edx , 16
	int	DPMI_INTR		; do call.
	jc	??error

	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,BRKINTNUM
	mov	ecx,[(KeyboardType esi).BrkOldPMISelector] 	; Get PM segment to put int ds later.
	mov	edx,[(KeyboardType esi).BrkOldPMIOffset] 	; Get PM offset
	int	DPMI_INTR		  ; do call.
	jc	??error



IF DEBUG

	; disengage Keyboard Interrupt handle
	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,DBGINTNUM
	mov	ecx,[(KeyboardType esi).DbgOldPMISelector] 	; Get PM segment to put int ds later.
	mov	edx,[(KeyboardType esi).DbgOldPMIOffset] 	; Get PM offset
	int	DPMI_INTR		  ; do call.
	jc	??error


ENDIF

IF NOT PROT_INT_ENABLE
       ; Clean up the Users interrupt table
        mov	eax , 201h
       mov	bl , [ byte ptr RMVector ]
       xor	ecx , ecx
       xor	edx , edx
       int	DPMI_INTR
       jc	??error
ENDIF


??vectors_not_set:
	; now free up the real mode memory.
	test	[InitFlags],IF_LOCKED_RM_CODE
	jz	??rm_not_locked
	mov	eax , 0601h
	mov	ecx,[RealModePtr]		; ecx must have start of memory.
	mov	edi,[RealModeSize]		; edx will have size of region in bytes.
	shld	ebx , ecx , 16
	shld	esi , edi , 16
	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.

??rm_not_locked:
	test	[InitFlags],IF_ALLOC_RM
	jz	??mem_not_allocated
	mov	eax , 0101h
	mov	edx,[ RealModeSel ] 		; get physical address of real mode buffer.
	int	DPMI_INTR			; do call.
	jc	??error
??mem_not_allocated:

	; Now we can unlock all stuff needed for the interrupt.
	; Unlock Code
	test	[InitFlags],IF_LOCKED_PM_CODE
	jz	??code_not_locked
	mov	eax , 0601h
	mov	ecx,OFFSET LockedCodeStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedCodeEnd	; edx will have size of region in bytes.
	sub	edi,ecx				;  - figure size.
	shld	ebx , ecx , 16
	shld	esi , edi , 16
	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
??code_not_locked:

	; Unlock data
	test	[InitFlags],IF_LOCKED_PM_DATA
	jz	??data_not_locked
	mov	ax,0601h				; set es to descriptor of data.
	mov	ecx,OFFSET LockedDataStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedDataEnd	; edx will have size of region in bytes.
	sub	edi,ecx				;  - figure size.
	shld	ebx , ecx , 16
	shld	esi , edi , 16
	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
??data_not_locked:

	; we have finished with success.
	mov	[RealModePtr],0		; To say we can do it again sometime.
	mov	[InitFlags],0		; To say we can do it again sometime.
	mov	eax,1			; signal success.
	ret
??error:
       	xor	eax,eax			; signal an error.
endif; NOT_FOR_WIN95
	ret
	ENDP	Remove_Keyboard_Interrupt


;***************************************************************************
;* CHECK_KEY_NUM -- Checks if key in queue, return key num                 *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      Keynum of the key that was pressed, FALSE otherwise        *
;*
;* PROTO:	INT Check_Key_Num(VOID);
;*                                                                         *
;* HISTORY:                                                                *
;*   07/14/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Check_Key_Num C NEAR
	USES	ebx,esi
ifdef NOT_FOR_WIN95
	pushf					; save off the flags
	cli					; disable interrupts

	mov	esi,[RealModePtr]		; Point to start of RM data.
	mov	eax,[(KeyboardType PTR esi).KeyBufferHead]
	xor	eax,[(KeyboardType PTR esi).KeyBufferTail]
	or	eax,eax				; check to see if head == tail
	jz	short ??fini			; if so we are done

	mov	eax,[(KeyboardType PTR esi).KeyBufferHead]	; get the head
	mov	ax,[(KeyboardType PTR esi+eax).KeyBuffer]	; get key num

??fini:
	sti
	popf
endif; NOT_FOR_WIN95
	ret

	ENDP	Check_Key_Num

;***************************************************************************
;* GET_KEY_NUM -- Returns the next key num in ax                           *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      WORD key flags are in the high byte of return word, key    *
;*		  num is in the low byte.
;*                                                                         *
;* PROTO:	WORD Get_Key_Num(VOID);
;*                                                                         *
;* HISTORY:                                                                *
;*   07/14/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Get_Key_Num C NEAR
	USES	esi,edi

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]		; Point to start of RM data.
??wait:
	cli				; disable interrupts
	mov	eax,[(KeyboardType PTR esi).KeyBufferHead]		; get the head
	cmp	eax,[(KeyboardType PTR esi).KeyBufferTail]		; get the head
	jne	short ??getkey
	sti				; enable interrupts
	jmp	??wait

??getkey:
	call	Low_Get_Key
	sti				; enable interrupts
endif; NOT_FOR_WIN95
	ret

	ENDP	Get_Key_Num

;***************************************************************************
;* KN_TO_KA -- Translates a key num to an ASCII key                        *
;*                                                                         *
;* INPUT:	WORD the keynum to translate                               *
;*                                                                         *
;* OUTPUT:      WORD the ASCII key that is returned                        *
;*                                                                         *
;* PROTO:	INT KN_To_KA(INT keynum);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1994 PWG : Created.                                             *
;*=========================================================================*

	PROC	KN_To_KA C NEAR
	ARG	keynum:DWORD

ifdef NOT_FOR_WIN95
	mov	eax,[keynum]
	call	near ptr Convert_Num_To_ASCII

endif; NOT_FOR_WIN95
	ret

	ENDP	KN_To_KA


;***************************************************************************
;* LOW_GET_KEY -- low level get key returns key num and bits               *
;*                                                                         *
;* INPUT:	AX - index into the buffer                                 *
;*                                                                         *
;* OUTPUT:      AX - key num with bits                                     *
;*                                                                         *
;* PROTO:	none - assembly callable routine only.                     *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/14/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Low_Get_Key C NEAR
	USES	ebx,esi,edi

ifdef NOT_FOR_WIN95
	mov	edi,eax				; save off value in ax

; We should set up both DS & ES because we are a low level function
; and don't know who might have called us or what the registers
; currently are.

; No reason to set DS & ES.
; This is not a hardware interrupt and if the funtion is being called
; from within a hardware interrupt then DS and ES will be preset to
; DGROUP _DATA

	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	ax,[(KeyboardType PTR esi+edi).KeyBuffer]		; get the head

	add	edi,2
	and	edi,0FFH			; 128 word circular buffer

	cmp	al,KN_LMOUSE
	jb 	short ??cont
	cmp	al,KN_RMOUSE
	ja 	short ??chkjoy

	push	eax			; save off the keynum we got

	mov	ax,[(KeyboardType PTR esi+edi).KeyBuffer]		; get the head
	add	edi,2
	and	edi,0FFH		; 128 word circular buffer

	mov	[MouseQX],eax

	mov	ax,[(KeyboardType PTR esi+edi).KeyBuffer]		; get the head
	add	edi,2
	and	edi,0FFH			; 128 word circular buffer

	mov	[MouseQY],eax

	pop	eax			; restore keynum for return

	jmp	short ??cont

??chkjoy:
	cmp	al,KN_JBUTTON2		; mouse button before joystick button
	ja 	short ??cont

	push	eax			; save off the keynum we got

	mov	ax,[(KeyboardType PTR esi+edi).KeyBuffer]		; get the head
	add	edi,2
	and	edi,0FFH			; 128 word circular buffer

	mov	ax,[(KeyboardType PTR esi+edi).KeyBuffer]		; get the head
	add	edi,2
	and	edi,0FFH			; 128 word circular buffer

	pop	eax			; restore keynum for return
??cont:
	mov	[(KeyboardType PTR esi).KeyBufferHead],edi	; set the head

??out:
endif; NOT_FOR_WIN95
	ret

	ENDP	Low_Get_Key

;***************************************************************************
;* CONVERT_NUM_TO_ASCII -- Assembly routine converts keynum to ASCII key   *
;*                                                                         *
;* INPUT:	EAX where:						   *
;*			AH - holds the key num bits                        *
;*			AL - holds the key num value			   *
;*                                                                         *
;* OUTPUT:      EAX where:						   *
;*			AH - hold the key bits                             *
;*			AL - holds the ASCII key value			   *
;*                                                                         *
;* PROTO:	none - assembly callable routine only.                     *
;*                                                                         *
;* WARNINGS:    GetKeyLock must be set prior to calling this function	   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Convert_Num_To_ASCII C NEAR
	USES	ebx,ecx,esi,edi

ifdef NOT_FOR_WIN95
	;*===================================================================
	;* Force all breaks to be thrown out.
	;*===================================================================
	test	eax,08000h		; If it is a button number
	jne	short ??button		;  don't process it

	test	ah,KEYRELEASE		; If it is not key release
	je	short ??ok		;  then go process it

??button:
	xor	eax,eax			; no ascii value for a button
	ret

??ok:
	;*===================================================================
	;* ES points to the DOSMEM selector, esi is the offset of the
	;*   protected mode structure.
	;*===================================================================
	mov	esi,[RealModePtr]	; Point to start of RM data.

	;*===================================================================
	;* Start dealing with the keys.
	;*===================================================================
	cmp	al,110			; is it esc
	je	??esc			; if so then deal with it

;??chkext:
	cmp	al,62			; is it extended?
	jae	short ??extended	; its extended so return ext code

	mov	ebx,eax			; get an index
	and	ebx,03FH		; only 0-63 allowed
	test	ah,1			; if not, test for shift
	jnz	short ??shifted		; if shifted get shift value

	;*===================================================================
	;* Here when we have an unshifted ascii key
	;*===================================================================
	mov	al,[Ascii+ebx]		; get the ascii code for this number
	jmp	short ??ctrlkey

	;*===================================================================
	;* CAPS key is on, forcing all alphabetic characters to lower case (all
	;* others are shifted)
	;*===================================================================
??alpha_lowered:
	mov	al,[Alpha_Lower+ebx]	; get the s_ascii code for number
	jmp	short ??ctrlkey

	;*===================================================================
	;* CAPS key is on, forcing all alphabetic characters to lower case (all
	;* others are shifted)
	;*===================================================================
??alpha_shifted:
	mov	al,[Alpha_Shift+ebx]	; get the s_ascii code for number
	jmp	short ??ctrlkey

	;*===================================================================
	;* Shift'ed character
	;*===================================================================
??shifted:
	mov	al,[Shift+ebx] 		; get ascii shift code for number

??ctrlkey:
	test	ah,2			; is it ctrl?
	jz 	short ??jexit		; izf not skip ctrl check

	mov	edi,ebx			; get index
	and	edi,7			; only bits 0-7

	mov	cl,[(KeyboardType PTR esi+edi).Bits]

	shr	ebx,3			; div by 8 for byte offset
	test	[(KeyboardType PTR esi+ebx).KeysCapsLock],cl
	je 	short ??jexit
	and	al,01FH			; force to ctrl value

??jexit:
	jmp short ??exit

??extended:
	cmp	al,75			; if less than insert
	jb 	short ??special
	cmp	al,110			; if >= esc
	jae 	short ??funckey

??editkeys:
	xor	ebx,ebx
	mov	bl,al
	sub	ebx,75			; get value from 0-34
	test	[(KeyboardType PTR esi).KeyFlags],NONUMLOCK
	jne 	short ??no_numpad
	test	[GetKeyLock],NUMLOCK	; look at the snap shot of bits
	jne 	short ??numpad

??no_numpad:
	mov	al,[Edit+ebx] 		; get the ascii code for this number
	jmp	short ??exit

??numpad:
	sub	ebx,15			; adjust to numpad entries
	mov	al,[NumPad+ebx] 	; get the ascii code for this number
	jmp	short ??exit

??funckey:
	cmp	al,112			; if less than function keys
	jb 	short ??extout
	cmp	al,121			; if greater than function keys 1-10
	ja 	short ??extout
	mov	bl,al
	sub	bl,112			; get value 0-9
	mov	bh,0C5H			; function key 1 no shift-ctrl-alt
	test	ah,7			; any shift-ctrl-alt
	je	short ??funcadj
	mov	bh,098H			; function key 1 alt
	test	ah,ALTPRESS		; (highest prescendence)
	jne 	short ??funcadj
	mov	bh,0A2H			; function key 1 ctrl (next highest)
	test	ah,CTRLPRESS
	jne	short ??funcadj
	mov	bh,0ACH			; function key 1 shift (lowest)

??funcadj:
	sub	bh,bl			; adjust function key to a
	mov	al,bh			; shift/no shift etc
	jmp	short ??exit

??special:
	cmp	al,65			; if less than specials
	jb	short ??extout

	add	al,133			; make value between 198-207 or
	jmp	short ??exit		; 0C6H-0CFH

??extout:
	or	al,080H
	jmp	short ??exit

??esc:
	mov	al,01BH

??exit:
endif; NOT_FOR_WIN95
	ret
	ENDP	Convert_Num_To_ASCII

;***************************************************************************
;* CHECK_KEY -- checks for ASCII keys sitting in the keybuffer             *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      INT the ASCII sequence for the key that was pressed        *
;*                                                                         *
;* PROTO:	INT Check_Key(VOID);                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Check_Key C NEAR
	USES	ebx,edi,esi

ifdef NOT_FOR_WIN95
	pushf
	cld
	mov	ebx,[RealModePtr]		; Point to start of RM data.

??clrloop:
	cli				; disable interrupts
	mov	eax,[(KeyboardType PTR ebx).KeyBufferHead]
	cmp	eax,[(KeyboardType PTR ebx).KeyBufferTail]
	je	short ??clrexit
	mov	esi,eax
	mov	ax,[(KeyboardType PTR ebx+eax).KeyBuffer]	; get key num

	mov	edi,ebx
	add	edi,OFFSET (KeyboardType PTR 0).PassAlways
	mov	ecx,(OFFSET (KeyboardType PTR 0).PassAlwaysEnd-OFFSET (KeyboardType PTR 0).PassAlways)+1 ; get number of pass always
	repne	scasb			; look for a match
	or	ecx,ecx			; see if there was a match
	jne	short ??getinvalid

	test	ah,KEYRELEASE		; is this a break?
	jne	short ??getinvalid

	cmp	al,122			; is code a valid ascii key??
	jb	short ??convkey

??getinvalid:
	cmp	al,KN_LMOUSE		; check if it is a mouse or joystick
	jb	short ??contget
	cmp	al,KN_JBUTTON2
	ja	short ??contget
	add	si,4			; get rid of the x and y values

??contget:
	add	esi,2			; get rid of invalid ascii key
	and	esi,0FFH			; 128 word circular buffer
	mov	[(KeyboardType PTR ebx).KeyBufferHead],esi
	sti				; enable interrupts
	jmp	??clrloop

??clrexit:
	xor	eax,eax

??convkey:
	mov	cx,[(KeyboardType PTR ebx).KeyLock]
	mov	[GetKeyLock],cx		; save status for convert to ASCII
	sti				; enable interrupts
	or	eax,eax
	je 	short ??exit		; exit if no key

					; AX has key num code with bits
	call	near ptr Convert_Num_To_ASCII
					; AX has ASCII code with bits

	xor	ah,ah			; clear key bits
??exit:
	popf
endif; NOT_FOR_WIN95
	ret
	ENDP	Check_Key


;***************************************************************************
;* GET_KEY -- Gets the next available ASCII keystroke.			   *
;*                                                                         *
;* INPUT:	none							   *
;*                                                                         *
;* OUTPUT:      AH - hold the key bits                                     *
;*		AL - holds the ASCII key value				   *
;*                                                                         *
;* PROTO:	INT Get_Key(VOID);					   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Get_Key C NEAR
	USES 	ebx,ecx,edi

ifdef NOT_FOR_WIN95
	cld				; clear the direction flag for speed

	; Check_Key had to be copied because of enable and disable of ints
	;  with mod to get the key

	mov	ebx,[RealModePtr]	; Point to start of RM data.
??chkkey:
	cli				; disable interrupts
	mov	eax,[(KeyboardType PTR ebx).KeyBufferHead]
	cmp	eax,[(KeyboardType PTR ebx).KeyBufferTail]
	jne 	short ??getkey
	sti				; enable interrupts
	jmp	??chkkey

??getkey:
					; AX has index into keybuffer
	call	near ptr Low_Get_Key
					; AX has key num code with bits

	mov	cx,[(KeyboardType PTR ebx).KeyLock]
	mov	[GetKeyLock],cx		; save status for convert to ASCII

	sti				; enable interrupts

	mov	edi,ebx
	add	edi,OFFSET (KeyboardType PTR 0).PassAlways
	mov	ecx,(OFFSET (KeyboardType PTR 0).PassAlwaysEnd-OFFSET (KeyboardType PTR 0).PassAlways)+1 ; get number of pass always
	repne	scasb			; look for a match
	or	ecx,ecx			; see if there was a match
	jne	??chkkey

	test	ah,KEYRELEASE		; is this a break?
	jne	??chkkey

	cmp	al,122			; is code a valid ascii key??
	jae	??chkkey
					; AX has key num code with bits

	call	near ptr Convert_Num_To_ASCII

	xor	ah,ah
endif; NOT_FOR_WIN95
	ret

	ENDP	Get_Key

;***************************************************************************
;* KEYBOARD_ATTRIBUTES_ON -- Sets the specified keyflags on                *
;*                                                                         *
;* INPUT:	INT the keyflags that need to be turned on                 *
;*                                                                         *
;* OUTPUT:      INT the current keyflags that are on                       *
;*                                                                         *
;* PROTO:	INT Keyboard_Attributes_On(INT key_flags);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/19/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Keyboard_Attributes_On C NEAR
	USES	esi,edi
	ARG	bits:DWORD

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	eax,[bits]
	or	[(KeyboardType PTR esi).KeyFlags],eax

	; Only do this if in playback or record mode.
	test	eax,PASSBREAKS
	je	short ??fini

	xor	eax,eax
	mov	edi,esi
	add	edi,OFFSET (KeyboardType PTR 0).KeysUpDown
	mov	[edi],eax
	mov	[edi+4],eax
	mov	[edi+8],eax
	mov	[edi+12],eax
??fini:
	mov	eax,[(KeyboardType PTR esi).KeyFlags]
endif; NOT_FOR_WIN95
	ret
	ENDP	Keyboard_Attributes_On

;***************************************************************************
;* KEYBOARD_ATTRIBUTES_OFF -- Sets the specified keyflags off              *
;*                                                                         *
;* INPUT:	INT the keyflags that need to be turned off                *
;*                                                                         *
;* OUTPUT:      INT the current keyflags that are off                      *
;*                                                                         *
;* PROTO:	INT Keyboard_Attributes_Off(INT key_flags);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/19/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Keyboard_Attributes_Off C NEAR
	USES	esi
	ARG	bits:DWORD

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	eax,[bits]
	not	eax
	and	[(KeyboardType PTR esi).KeyFlags],eax
	xor	eax,eax
	mov	eax,[(KeyboardType PTR esi).KeyFlags]
endif; NOT_FOR_WIN95
	ret

	ENDP	Keyboard_Attributes_Off
;***************************************************************************
;* CLEAR_KEYBUFFER -- Clears keystrokes out of the key buffer              *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:	VOID Clear_KeyBuffer(VOID);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/19/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Clear_KeyBuffer C NEAR
	USES	eax,esi
ifdef NOT_FOR_WIN95

	mov	esi,[RealModePtr]		; Point to start of RM data.
	cli
	mov	eax,[(KeyboardType PTR esi).KeyBufferHead]
	mov	[(KeyboardType PTR esi).KeyBufferTail],eax
	sti

endif; NOT_FOR_WIN95
	ret

	ENDP	Clear_KeyBuffer

;***************************************************************************
;* KEY_DOWN -- tests the status of a keyboard key                          *
;*                                                                         *
;* INPUT:	INT the key num to check                                   *
;*                                                                         *
;* OUTPUT:      INT zero if the key is up, none zero if the key is down    *
;*                                                                         *
;* PROTO:	INT Key_Down(INT key);				   	   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/19/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Key_Down C NEAR
	USES	ebx,ecx,edi,esi
	ARG	key:DWORD

ifdef NOT_FOR_WIN95
	push	[key]
	call	KeyNum_Translate
	add	esp,4
	xor	ah,ah				; Always ignore the control bits.

	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	edi,eax
	shr	edi,3
	mov	cl,al
	and	cl,0111b
	mov	al,01b
	shl	al,cl
	and	al,[(KeyboardType PTR esi+edi).KeysUpDown]
endif; NOT_FOR_WIN95
	ret

	ENDP	Key_Down

;***************************************************************************
;* CHECK_KEY_BITS -- checks ascii key in key buff with shift,ctrl,alt bits *
;*                                                                         *
;* INPUT:	none 							   *
;*                                                                         *
;* OUTPUT:	INT 0 = no key in buffer, !0 = a key with the bits set     *
;*                                                                         *
;* PROTO:	INT Check_Key_Bits(VOID);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/20/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Check_Key_Bits C NEAR
	USES	ebx,ecx,edi,esi

ifdef NOT_FOR_WIN95
	pushf					; save off the direction flag
	cld					; we will go forward

	mov	ebx,[RealModePtr]		; Point to start of RM data.
??clrloop:
	cli				; disable interrupts
	mov	eax,[(KeyboardType PTR ebx).KeyBufferHead]
	cmp	eax,[(KeyboardType PTR ebx).KeyBufferTail]
	je	short ??clrexit
??playback:
	mov	esi,eax
	mov	ax,[(KeyboardType PTR ebx+eax).KeyBuffer]	; get key num

	mov	edi,ebx
	add	edi,OFFSET (KeyboardType PTR 0).PassAlways
	mov	ecx,(OFFSET (KeyboardType PTR 0).PassAlwaysEnd-OFFSET (KeyboardType PTR 0).PassAlways)+1 ; get number of pass always
	repne	scasb			; look for a match
	or	ecx,ecx			; see if there was a match
	jne	short ??getinvalid

	;------ If there is a NULL in the keyboard buffer, we must NOT treat it
	;	as a valid ASCII value because the calling code will falsely
	;	assume that the NULL return value indicates an empty buffer.
	or	al,al
	je	short ??getinvalid

	cmp	al,122			; is code a valid ascii key??
	jb	short ??convkey

??getinvalid:
	add	esi,2			; get rid of invalid ascii key
	and	esi,0FFH			; 128 word circular buffer
	mov	[(KeyboardType PTR ebx).KeyBufferHead],esi
	sti				; enable interrupts
	jmp	??clrloop

??clrexit:
	xor	ax,ax

??convkey:
	mov	cx,[(KeyboardType PTR ebx).KeyLock]
	mov	[GetKeyLock],cx		; save status for convert to ASCII

	sti				; enable interrupts

	or	eax,eax
	je 	short ??exit		; exit if no key

					; AX has key num code with bits
	mov	ch,ah
	and	ch,KEYRELEASE		; keep only KEYRELEASE bit
	and	ah,NOTKEYRELEASE	; keep everything but KEYRELEASE bit

	call	near ptr Convert_Num_To_ASCII

					; AX has ASCII code with bits
	or	ah,ch			; replace KEYRELEASE bit

??exit:
	popf
endif; NOT_FOR_WIN95
	ret

	ENDP	Check_Key_Bits
;***************************************************************************
;* GET_KEY_BITS -- Gets ascii key in key buff with shift,ctrl,alt bits     *
;*                                                                         *
;* INPUT:	none							   *
;*                                                                         *
;* OUTPUT:	INT 0 = no key in buffer, !0 = a key with the bits set	   *
;*                                                                         *
;* PROTO:	INT Check_Key_Bits(VOID);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/20/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Get_Key_Bits C NEAR
	USES	ebx,ecx,edi

ifdef NOT_FOR_WIN95
	cld

	; Check_Key_Bits was copied because of enable and disable of interrupts
	;  with mod to get the key

	mov	ebx,[RealModePtr]	; Point to start of RM data.

??chkkey:
	cli				; disable interrupts
	mov	eax,[(KeyboardType PTR ebx).KeyBufferHead]
	cmp	eax,[(KeyboardType PTR ebx).KeyBufferTail]
	jne 	short ??getkey
	sti				; enable interrupts
	jmp	??chkkey

??getkey:
					; AX has index into keybuffer
	call	near ptr Low_Get_Key
					; AX has key num code with bits

	mov	cx,[(KeyboardType PTR ebx).KeyLock]
	mov	[GetKeyLock],cx		; save status for convert to ASCII

	sti				; enable interrupts

	mov	edi,ebx
	add	edi,OFFSET (KeyboardType PTR 0).PassAlways
	mov	ecx,(OFFSET (KeyboardType PTR 0).PassAlwaysEnd-OFFSET (KeyboardType PTR 0).PassAlways)+1 ; get number of pass always
	repne	scasb			; look for a match
	or	ecx,ecx			; see if there was a match
	jne	??chkkey

	cmp	al,122			; is code a valid ascii key??
	jae	??chkkey

					; AX has key num code with bits
	mov	ch,ah
	and	ch,KEYRELEASE		; keep only KEYRELEASE bit
	and	ah,NOTKEYRELEASE	; keep everything but KEYRELEASE bit

	call	near ptr Convert_Num_To_ASCII

					; AX has ASCII code with bits
	or	ah,ch			; replace KEYRELEASE bit
	ret

endif; NOT_FOR_WIN95
	ENDP	Get_Key_Bits

;***************************************************************************
;* KEY_SATISFIED -- checks to see if the given key is satisfied            *
;*                                                                         *
;* INPUT:   INT the key flags/number to check                          	   *
;*                                                                         *
;* OUTPUT:  INT 0 if the key is not satisfied, !0 if the key is satisfied  *
;*                                                                         *
;* PROTO:   VOID Key_Satisfied(INT key);                                    *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/20/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Key_Satisfied C NEAR
	USES	ebx,ecx,esi,edi
	ARG	key:DWORD

ifdef NOT_FOR_WIN95
	mov	eax,[key]
	mov	ebx,eax			; save key code
	push	eax
	call	Key_Down		; see it its even down
	add	esp,4
	cmp	eax,0
	je	??out			; if not it can't be satisfied

	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	eax,ebx			; if so, restore code
	xor	ah,ah			; clear out flags area
	mov	edi,eax			; set as an index
	shr	edi,3			; div by 8 for bytes
	mov	ch,1h			; set a bit for mask
	mov	cl,al			; get the code number
	and	cl,7			; get the actual bit this code is
	shl	ch,cl			; move bit into mask position

; now test the ctrl,alt and shift bits

	test	[(KeyboardType PTR esi+7).KeysUpDown],04h	; is the left ctrl down?
	jne 	short ??ctrlon		; if so, ctrl is on

	test	[(KeyboardType PTR esi+8).KeysUpDown],01h	; is the right ctrl down?
	je 	short ??ctrloff		; if not, neither are down, no ctrl
??ctrlon:
	or	ah,02h			; or on the ctrl bit in flags
??ctrloff:
	test	[(KeyboardType PTR esi+7).KeysUpDown],50h	; is either alt key down?
	je 	short ??altoff
	or	ah,04h			; or on the alt bit in flags
??altoff:
	test	[(KeyboardType PTR esi+5).KeysUpDown],10h	; is the left shift down?
	jne 	short ??shifton		; if so the sift is on
	test	[(KeyboardType PTR esi+7).KeysUpDown],02h	; is the right shift down?
	je 	short ??shiftoff		; if not then neither shift is down
??shifton:
	or	ah,01h			; or on the shift bit in flags
??shiftoff:
	test	[(KeyboardType PTR esi).KeyLock],CAPSLOCK	; is the caps lock on?
	je 	short ??capsoff		; if not don't worry about it
	test	ch,[(KeyboardType PTR esi+edi).KeysCapsLock]	; get code for keycaps
	je 	short ??capsoff		; its not effected
	xor	ah,1h			; toggle the shift flag
??capsoff:
	test	[(KeyboardType PTR esi).KeyLock],NUMLOCK		; is the num lock key on?
	je 	short ??numlockoff		; if not don't worry about it
	test	ch,[(KeyboardType PTR esi+edi).KeysNumLock]	; get code for numlock
	je 	short ??numlockoff		; if not effected skip toggle
	xor	ah,1h			; toggle the shift flag if effected

??numlockoff:
	mov	al,0ffh			; set to match by default
	cmp	ah,bh			; if flags match return !0
	je 	short ??out			; just exit
	xor	eax,eax			; otherwise, clear all bits FALSE

??out:
	or	eax,eax
endif ;NOT_FOR_WIN95
	ret

	ENDP	Key_Satisfied


;***************************************************************************
;* Interrupt routines start here - Interrupts must be within the Locked
;*   code area for DPMI compatability.
;***************************************************************************




LABEL 	LockedCodeStart	BYTE
ifdef cuts
;***************************************************************************
;* KEYNUM_TRANSLATE -- Performs a lowlevel xlate to a keycode              *
;*                                                                         *
;* INPUT:	WORD the code that needs to be translated                  *
;*                                                                         *
;* OUTPUT:	WORD the translated code                                   *
;*                                                                         *
;* PROTO:	INT KeyNum_Translate(INT keynum);                          *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/15/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	KeyNum_Translate C NEAR
	USES 	ebx,ecx,esi,edi
	ARG	keycode:DWORD

;*===================================================================
;* ES points to the DOSMEM selector, esi is the offset of the
;*   protected mode structure.
;*===================================================================

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]	; Point to start of RM data.
	mov	eax,[keycode]
	test	[(KeyboardType PTR esi).KeyFlags],TRACKEXT
	jne 	short ??fini


	mov	ecx,OFFSET ((KeyboardType PTR 0).ExtRemap)- OFFSET((KeyboardType PTR 0).ExtNums)
	mov	edi,OFFSET (KeyboardType PTR 0).ExtNums
	add	edi,esi

	repne	scasb
	jcxz	short ??fini			; No match found.

	mov	edi,esi
	add	edi,OFFSET (KeyboardType PTR 0).ExtRemapEnd
	dec	edi
	sub	edi,ecx
	mov	al,[edi]
??fini:
endif ;NOT_FOR_WIN95
	ret

	ENDP	KeyNum_Translate
endif
	ifdef cuts
;***************************************************************************
;* STUFF_KEY_WORD -- Stuffs a word of data into keyboard buffer            *
;*                                                                         *
;* INPUT:	WORD the code to stick into the circular buffer            *
;*                                                                         *
;* OUTPUT:      WORD !=0 is sucessful, ==0 is not enough room		   *
;*                                                                         *
;* PROTO:	VOID Stuff_Key_WORD(INT code);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Stuff_Key_WORD C NEAR
	USES	ebx,esi,edi
	ARG	code:WORD

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	eax,[(KeyboardType PTR esi).KeyBufferTail]
	mov	edi,eax
	add	eax,2
	and	eax,0FFh			; New KeyBufferTail value.
	cmp	[(KeyboardType PTR esi).KeyBufferHead],eax
	je 	short ??noroom

	mov	bx,[code]
	mov	[(KeyboardType PTR esi+edi).KeyBuffer],bx		; Record the keystroke.
	mov	[(KeyboardType PTR esi).KeyBufferTail],eax
	xor	eax,eax
	ret

??noroom:
	mov	eax,1
endif ;NOT_FOR_WIN95
	ret

	ENDP	Stuff_Key_WORD
endif
ifdef cuts
;***************************************************************************
;* STUFF_KEY_NUM -- Stuffs a key num code into the circular buffer         *
;*                                                                         *
;* INPUT:	WORD the keycode to stuff                                  *
;*                                                                         *
;* OUTPUT:      WORD !=0 is sucessful, ==0 is not enough room		   *
;*                                                                         *
;* PROTO:	VOID Stuff_Key_Num(INT keynum);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Stuff_Key_Num C NEAR
	USES	ebx,ecx,edx,edi,esi
	ARG	keycode:DWORD
	LOCAL	tail:DWORD		; Original keybuffer tail (safety copy).
	LOCAL	size:WORD		; Size of write.

; for the moment we do not check for the interrupt flag
;	mov	eax,2534h 		; function to get the interrupt status
;	int	21			; eax = interrupt status
;	push	eax			; save the result on the stack

ifdef NOT_FOR_WIN95
	pushf				; store off the flags
	cli				; disable interrupts

; We need to set the data segment because we might be being called
; from within an interrupt
; Soo, if that is the case then DS & ES point to DGROUP _DATA

	mov	esi,[RealModePtr]		; Point to start of RM data.

	; Record the mouse position to be stuffed into buffer.
	mov	eax,[(KeyboardType PTR esi).MouseX]
	mov	[(KeyboardType PTR esi).LocalMouseX],ax
	mov	eax,[(KeyboardType PTR esi).MouseY]
	mov	[(KeyboardType PTR esi).LocalMouseY],ax

??cando:
	mov	eax,[keycode]		; get the code
	or	eax,eax			; Null keycodes are not recorded.
	jne	short ??validkey
	jmp	??exit


??validkey:

	test	[(KeyboardType PTR esi).KeyFlags],KEYMOUSE	; is the numeric keypad moving the mouse?
	je	??no_pad_move

	; ALT-cursor keys are undefined.  Pass them on to the program.
	test	ah,ALTPRESS		; is either alt key down?
	jne	??no_pad_move

	test	[(KeyboardType PTR esi).KeyFlags],SIMLBUTTON	; are we simulating left mouse presses
	je	short ??chkinsert

	cmp	al,KN_RETURN
	je	short ??forceleft

	cmp	al,KN_SPACE
	je	short ??forceleft

	cmp	al,KN_KEYPAD_RETURN
	je	short ??forceleft

??chkinsert:
	cmp	al,KN_INSERT
	jne	short ??regular

??forceleft:
	mov	al,KN_LMOUSE
	or	[(KeyboardType PTR esi).Button],1		; Left mouse bit.
	test	ah,KEYRELEASE
	je	??mousefake
	and	[(KeyboardType PTR esi).Button],NOT 1
	jmp	??mousefake

??regular:
	cmp	al,KN_DELETE
	jne	short ??regular2
	mov	al,KN_RMOUSE
	or	[(KeyboardType PTR esi).Button],2		; Right mouse bit.
	test	ah,KEYRELEASE
	je	??mousefake
	and	[(KeyboardType PTR esi).Button],NOT 2
	jmp	??mousefake

??regular2:
	; DRD correction to ignore key releases for key mouse movement
	test	ah,KEYRELEASE
	jne	??no_pad_move

	cmp	al,KN_CENTER
	je	short ??pad_move
	cmp	al,KN_UPLEFT		; less than upleft?
	jb	??no_pad_move		; yes, then it isn't a keypad key
	cmp	al,KN_DOWNRIGHT		; greater than downright?
	ja	??no_pad_move		; yes, then it isn't a keypad key
	cmp	al,KN_DOWNLEFT		; is it UPLEFT, LEFT, or DOWNLEFT?
	jbe	short ??pad_move
	cmp	al,KN_UPRIGHT		; is it UPRIGHT, RIGHT, or DOWNRIGHT?
	jae	short ??pad_move
	cmp	al,KN_UP		; up?
	je	short ??pad_move
	cmp	al,KN_DOWN		; down?
	jne	??no_pad_move

??pad_move:
	; DRD correction to use ch for ah
	mov	ch,ah			; save shift-ctrl-alt-rlse status

	xor	ah,ah			; get rid of any bits
	xor	ebx,ebx
	sub	al,KN_UPLEFT		; get a number between 0 and 12
	mov	bx,ax
	shl	ebx,1			; double for WORD index
	mov	ax,[WORD PTR ((KeyboardType PTR esi+ebx).XYAdjust)]

	movsx	ebx,ah
	movsx	eax,al

	; DRD correction to use ch
	; The CTRL key moves the mouse to the edge of the screen.
	test	ch,CTRLPRESS		; is either ctrl key down?
	jne	short ??ctrlon		; if so, ctrl is on

	; DRD correction to use ch
	; use fast speed of the mouse move if the shift key is held down.
	mov	edx,1			; for slow speed
	test	ch,SHIFTPRESS		; is either shift key down?
	je	short ??normspeed	; if not then neither shift is down
??doublespeed:
	add	edx,3			; for fast speed
??normspeed:
	add	ebx,edx			; add speed for y index
	mov	bl,[(KeyboardType PTR esi+ebx).KeyMouseMove] 	; get speed for y delta
	movsx	ebx,bl
	xchg	ebx,edx			; save mouse y delta
	add	ebx,eax			; add speed for x index
	mov	al,[(KeyboardType PTR esi+ebx).KeyMouseMove]	; get speed for x delta
	movsx	eax,al
	xchg	ebx,edx			; restore mouse y delta
	jmp	short ??ctrloff

??ctrlon:

	; Table lookup method for determining hotkey positions for CTRL
	; cursor combination.  This algorithm is hard coded for an ADJUST
	; value of 3.  If this value changed, then this section will also
	; have to be modified.
	and	ebx,011b			; Y = 1, 0, 3
	and	eax,011b			; X = 1, 0, 3
	; Table lookup method for determining hotkey positions for CTRL
	; cursor combination.  This algorithm is hard coded.
					;    -1, 0, 1
	and	ebx,011b			; Y = 3, 0, 1
	and	eax,011b			; X = 3, 0, 1
	shl	ebx,2
	or	ebx,eax			; Lookup index.

	; Convert raw index into logical (clockwise) index.
	shl	ebx,1
	movzx	ebx,[(KeyboardType PTR esi+ebx).EdgeConv]
	shl	ebx,2
	mov	ax,[(KeyboardType PTR esi+ebx).ScreenEdge]	; New absolute X
	mov	bx,[(KeyboardType PTR esi+ebx+2).ScreenEdge] ; New absolute Y
	mov	[(KeyboardType PTR esi).LocalMouseX],ax
	mov	[(KeyboardType PTR esi).LocalMouseY],bx

??set_xyz:
	mov	ax,[(KeyboardType PTR esi).LocalMouseX]	; get new mouse x,y
	mov	bx,[(KeyboardType PTR esi).LocalMouseY]
	jmp	short ??set_xy

	; Process a normal faked mouse move.
??ctrloff:
	; DRD change
	add	[(KeyboardType PTR esi).LocalMouseX],ax	; save it in our local
	jns	short ??not_negative_x
	xor	eax,eax
	mov	[(KeyboardType PTR esi).LocalMouseX],ax	; clear our local

??not_negative_x:
; DRD change
	add	[(KeyboardType PTR esi).LocalMouseY],bx	; save it in our local
	jns	short ??not_negative_y
	xor	ebx,ebx
	mov	[(KeyboardType PTR esi).LocalMouseY],bx	; clear our local

??not_negative_y:
	mov	ax,[(KeyboardType PTR esi).LocalMouseX]	; get new mouse x,y
	mov	bx,[(KeyboardType PTR esi).LocalMouseY]
	cmp	ax,MAX_X_PIXEL		; bigger than
	jle	short ??check_y
	mov	ax,MAX_X_PIXEL

??check_y:
	cmp	bx,MAX_Y_PIXEL		; bigger than
	jle	short ??set_xy
	mov	bx,MAX_Y_PIXEL

??set_xy:
	mov	[(KeyboardType PTR esi).LocalMouseX],ax
	mov	[(KeyboardType PTR esi).LocalMouseY],bx
	mov	[WORD PTR (KeyboardType PTR esi).MouseX],ax
	mov	[WORD PTR (KeyboardType PTR esi).MouseY],bx
	cmp	[(KeyboardType PTR esi).MouseUpdate],0	; wait until mouse interrupt is done
	jne	short ??noshow
; PWG: ARRGGGHHHH!
;	call	Low_Hide_Mouse
;	call	Low_Show_Mouse
??noshow:
	mov	eax,KN_MOUSE_MOVE
??mousefake:
	mov	[keycode],eax		; Fake a MOUSE_MOVE event.

??no_pad_move:
	; Fetch working pointers to the keyboard ends.
	mov	edi,[(KeyboardType PTR esi).KeyBufferTail]
	mov	[tail],edi		; Safety record.

	; Record the base keycode (if there is room).
	cwde
	push	eax
	call	Stuff_Key_WORD
	add	esp,4
	or	eax,eax
	jne	short ??jmpnoroom

	; Also record the mouse coordinates if necessary.
	mov	eax,[keycode]		; get key code
	cmp	al,KN_MOUSE_MOVE	; mouse move?
	je	short ??recordmouse	; yes? then record the mouse cooordinates
	cmp	al,KN_LMOUSE
	je	short ??recordmouse
	cmp	al,KN_RMOUSE
	je	short ??recordmouse
	jmp	short ??ok
??jmpnoroom:
	jmp	??noroom

	; Record mouse coordinate X.
??recordmouse:
	movzx	eax,[(KeyboardType esi).LocalMouseX]
	push	eax
	call	Stuff_Key_WORD
	add	esp,4
	or	eax,eax
	jne	??jmpnoroom
	add	[size],2

	; Record mouse coordinate Y.
	movzx	eax,[(KeyboardType esi).LocalMouseY]
	push	eax
	call	Stuff_Key_WORD
	add	esp,4
	or	eax,eax
	jne	??jmpnoroom
	add	[size],2

??ok:
	; If PASSBREAKS is not active and this is a keyboard
	; break AND it is not a mouse event, then don't put
	; it into the buffer.
	mov	ebx,0101h		; Bit control tools.
	mov	eax,[keycode]
	cmp	al,KN_MOUSE_MOVE
	je 	short ??notreal
	cmp	al,127
	je	short ??notreal
	test	ah,KEYRELEASE
	je	short ??real
	xor	bl,bl
	test	[(KeyboardType PTR esi).KeyFlags],PASSBREAKS
	jne 	short ??real
	cmp	al,KN_LMOUSE
	je 	short ??real
	cmp	al,KN_RMOUSE
	je 	short ??real
??notreal:
	mov	[(KeyboardType esi).KeyBufferTail],edi	; Nullify any KeyBufferTail changes.
??real:

	; Update the KeysUpDown bit array.
	mov	edi,eax
	and	edi,07Fh
	mov	cl,3
	shr	edi,cl			; DI = Byte offset into bit table.
	mov	cl,al
	and	cl,0111b		; CL = Bit offset into bit table byte.
	shl	bx,cl
	not	bh

	; If this is a reapeat key and the key is already being held
	; down, then don't stuff it into the keyboard buffer.
	test	bl,[(KeyboardType esi+edi).KeysUpDown]
	je	short ??notalready
	test	[(KeyboardType PTR esi).KeyFlags],REPEATON
	jne	short ??notalready
	mov	edx,[tail]
	mov	[(KeyboardType esi).KeyBufferTail],edx	; Nullify any KeyBufferTail changes.
??notalready:
	and	[(KeyboardType esi+edi).KeysUpDown],bh	; Force key bit to zero.
	or	[(KeyboardType esi+edi).KeysUpDown],bl	; Insert key bit as appropriate.
;??notreal:

	; Successful keybuffer stuff could result in a
??norecord:
	mov	eax,1
	jmp	short ??exit

	; Unsuccessful keybuffer stuff.
??noroom:
	mov	eax,[tail]
	mov	[(KeyboardType PTR esi).KeyBufferTail],eax
	xor	eax,eax			; Signal an error.

??exit:
	sti
	popf

;	popf
;	pop	ebx
;	or	ebx,ebx
;	jz	??final_exit
;	sti

??final_exit:
endif; NOT_FOR_WIN95
	ret

	ENDP	Stuff_Key_Num
endif

;***************************************************************************
;* BREAK_INTERRUPT -- Handles break interrupt for protected mode           *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    This is an interrupt routine.                              *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/28/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Break_Interrupt C NEAR

	iret
	ENDP	Break_Interrupt

IF DEBUG
;***************************************************************************
;* DEBUG_INTERRUPT -- Handles debug (INT 3) interrupt for protected mode   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    This is an interrupt routine.                              *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/28/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Debug_Interrupt C NEAR

	;*==================================================================
	;* Setup fake Interrupt entry sequence so that we can execute our
	;*   code and then IRET painlessly into the debuggers interrupt
	;*   handler.
	;*==================================================================
ifdef NOT_FOR_WIN95
	pushfd			; Step 1
	sub	esp,8		; Step 2
	push	ebp		; Step 3
	mov	ebp,esp		; Set up a stack frame to know where to poke address.

	;*==================================================================
	;* Preserve all of the registers that we intend to use.
	;*=======================================Dbg========================
	pushad
	push	ds es gs fs
	cld

	mov	ax , _DATA
	mov	ds , ax
	mov	es , ax
	inc	[BYTE PTR 0B0000h]

	;*==================================================================
	;* Setup the pointers to the real mode data and the protected mode
	;*   data and selectors.
	;*==================================================================
	mov	esi,[RealModePtr]		; Point to start of RM data.

	;*==================================================================
	;* Do the deed.
	;*==================================================================
	mov	[(KeyboardType PTR esi).KeyIntDisabled],1

	;*==================================================================
	;* Now get the address of the real debug handler and poke it into
	;*   the stack so we can IRET to it.
	;*==================================================================
	mov	eax,[(KeyboardType PTR esi).DbgOldPMIOffset]	; Get orig offset.
	mov	ebx,[(KeyboardType PTR esi).DbgOldPMISelector]	; Get orig selector.
	mov	[ss:ebp+4],eax					; Poke offset.
	mov	[ss:ebp+8],ebx					; Poke selector.

	;*==================================================================
	;* Restore the stack so it looks like we just did an IRET entry
	;*==================================================================
	pop	fs gs es ds
	popad
	pop	ebp

	;*==================================================================
	;* This iret should go directly to the real debugger handler
	;*	painlessly and effectively.
	;*==================================================================
endif; NOT_FOR_WIN95
	iretd

	ENDP	Debug_Interrupt
ENDIF



IF PROT_INT_ENABLE

;***************************************************************************
;* KEYBOARD_INTERRUPT -- Handles input that comes from the keyboard        *
;*                                                                         *
;* This routine intercepts the key codes on their way to the		   *
;* BIOS.  With the adjustment of the Flags described above		   *
;* you can get a wide variety of effects.				   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    This is an interrupt function                              *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/13/1994 PWG : Created.                                             *
;*=========================================================================*
	PROC	Keyboard_Interrupt C NEAR

	; This routine will do what it needs to,
	; then it will decide if the old vector should be called.
	; if so, it calls it and never returns to this function.
	; if not, we do our own return.
	; the method for doing this is found in:
	; "Phar Lap  TNT DOS-Extender Reference Manual, First Addition, p. 142"
	; It says:
	; 1 - Execute a PUSHFD to save the current flags.
	; 2 - Dec the stack ptr by 8 bytes to save room for the addr of orig handler
	; 3 - Push register I use.
	; 4 - Do any processing.
	; 5 - Put the address of the original handler in the reserved slot.
	; 6 - Pop saved register values
	; 7 - Execute an IRETD to transfer control to original handler.
ifdef NOT_FOR_WIN95
	pushfd			; Step 1
	sub	esp,8		; Step 2
	push	ebp		; Step 3
	mov	ebp,esp		; Set up a stack frame to know where to poke address.

	pushad
	push	ds es gs fs
	cld

; this is the part of the interrupt that set the segment registers
	mov	ax , _DATA
	mov	es , ax
	mov	ds , ax
	mov	esi,[RealModePtr]		; Point to start of RM data.

	mov	edx,[(KeyboardType PTR esi).KeyFlags]
	;*** The following fix allows proper caps and num lock tracking on Tandy
	; 10-6-89 LJC, DRD

	and	[(KeyboardType PTR esi).KeyLock],NOT (NUMLOCK OR CAPSLOCK); assume caps and num inactive
	test	[BYTE PTR 417H],040H	; test Caps lock bit in BIOS
	je	short ??bioscapsoff	; skip activate code
	or	[(KeyboardType PTR esi).KeyLock],CAPSLOCK	; Caps Lock active

??bioscapsoff:
	test	[BYTE PTR 417H],020H	; test Num lock bit in BIOS
	je	short ??biosnumoff	; skip activate code
	or	[(KeyboardType PTR esi).KeyLock],NUMLOCK 	; Num Lock active

??biosnumoff:
	mov	[(KeyboardType PTR esi).ExtKeyboard],TRUE 	; assume 101/102-key keyboard
	test	[BYTE PTR 496H],010H	; test for 101/102-key keyboard
	jne	short ??extkeyboard	; skip deactivate code
	mov	[(KeyboardType PTR esi).ExtKeyboard],FALSE 	; no 101/102-key keyboard

??extkeyboard:
	xor	ah,ah			; clear ctrl flags to 0
	mov	ebx,0101H		; set key to a make by default

	in	al,KEYDATA		; get a code from the keyboard
	;
	; New CODE to montior key stream
	;
	xor	ebx,ebx
	mov	bx,[(KeyboardType PTR esi).KeyStreamIndex]
	mov	[(KeyboardType PTR esi+ebx).KeyStream],al
	inc	ebx
	and	ebx,15
	mov	[(KeyboardType PTR esi).KeyStreamIndex],bx
	mov	ebx,0101H		; set key to a make by default
	;
	; END OF SEQUENCE
	;
	;
	; Handle the PAUSE key being pressed.  If it is pressed, then
	; signal that the next two input codes are to be thrown out.
	;
	cmp	al,0E1H			; see if this is a pause/break
	jne	short ??notpcode	; not a pause/break start code
	mov	[(KeyboardType PTR esi).LastKeyE1],3		; absorb this and next two codes

??notpcode:
	cmp	[(KeyboardType PTR esi).LastKeyE1],0		; are we in a pause/break code
	je	short ??notpause	; no, just keep going
	dec	[(KeyboardType PTR esi).LastKeyE1]		; yes, dec the count
	test	edx,PAUSEON		; should it pass these codes
	jne 	??passcode		; pass the code
	jmp	??absorbcode		; don't pass code

??notpause:
	;
	; Record any extended key codes that arrive.  They will be
	; taken into account with the next code.
	;
	cmp	al,0E0H			; is it an extended code
	jne	short ??notextcode	; if not skip to handle key
	mov	[(KeyboardType PTR esi).LastKeyE0],TRUE	; set the extended code to 1
??jmppasscode:
	jmp	??passcode		; always pass E0s

??notextcode:
	;
	; Check and acknowledge if the key is a make or a break.
	;
	test	al,080H			; test for high bit
	je	short ??make		; if off its a make
	xor	bl,bl			; set make/break to break
	and	al,07FH			; clear high bit
	or	ah,KEYRELEASE		; CDY NEW -- ABSENT IN OLD CODE

??make:
	;
	; Translate the raw keycode into the Westwood keycode.
	;
	cmp	[(KeyboardType PTR esi).LastKeyE0],FALSE	; was the prev byte an E0?
	je 	short ??normal		; if not it is a normal key
	mov	[(KeyboardType PTR esi).LastKeyE0],FALSE	; if so clear for next read
	mov	[(KeyboardType PTR esi).IsExtKey],TRUE	; it is an extended key


	mov	edi,OFFSET (KeyboardType PTR 0).ExtCodes
	add	edi,esi
	mov	ecx,(OFFSET (KeyboardType PTR 0).ExtNums-OFFSET (KeyboardType PTR 0).ExtCodes)	; get number of entrys in ext table
	repne	scasb			; look for a match
	jcxz	??absorbcode		; Not recognized, so throw it away.

	mov	al,[(OFFSET (KeyboardType PTR 0).ExtNums - OFFSET (KeyboardType PTR 0).ExtCodes) - 1 + edi] ; get the match
	mov	[(KeyboardType PTR esi).IsExtKey],FALSE	; it is not an extended key
	jmp 	short ??notext

??normal:
	cmp	al,07Ah
	jne	short ??normok
	mov	al,128
	jmp	short ??notext
??normok:
	mov	edi,eax			; use code as an index
	and	edi,007Fh		; Mask off any release bit.
	mov	al,[(KeyboardType PTR esi+edi).KeyNums]		; get the key number of this key

??notext:
	;
	; Test and set the CTRL bit.
	;
	test	[(KeyboardType PTR esi+8).KeysUpDown],001H	; is the right ctrl down?
	jne	short ??ctrlon		; if so, ctrl is on
	test	[(KeyboardType PTR esi+7).KeysUpDown],004H	; is the left ctrl down?
	je	short ??ctrloff		; if not, neither are down, no ctrl

	; DRD
	; check for CTRL-NUMLOCK for pause on some keyboards

	cmp	al,KN_NUMLOCK		; check for CTRL-NUMLOCK
	jne	short ??ctrlon

	cmp	[(KeyboardType PTR esi).ExtKeyboard],TRUE	; if 101/102-key keyboard it is ok
	je	short ??ctrlon

	test	edx,PAUSEON		; should it pass these codes
	jne	short ??ctrlon		; pass the code

	jmp	??absorbcode		; don't pass code

??ctrlon:
	or	ah,CTRLPRESS		; or on the ctrl bit in flags

??ctrloff:
	;
	; Test and set the ALT bit.
	;
	test	[(KeyboardType PTR esi+7).KeysUpDown],050H	; is either alt key down?
	je	short ??altoff
	or	ah,ALTPRESS		; or on the alt bit in flags

??altoff:
	;
	; Remap the keyboard keys if this is requested. (Do not set DGROUP
	;   as it is unecessary)
	push	eax
	call	KeyNum_Translate
	add	esp,4

;------	Set the shift bit if necessary.
	test	[(KeyboardType PTR esi+5).KeysUpDown],010H	; is the left shift down?
	jne	short ??shifton		; if so the shift is on
	test	[(KeyboardType PTR esi+7).KeysUpDown],002H	; is the right shift down?
	je	short ??shiftoff	; if not then neither shift is down

??shifton:
	or	ah,SHIFTPRESS		; or on the shift bit in flags

??shiftoff:
	;
	;------	Toggle the shift state if the caps lock key is on (if necessary).
	;
	mov	edi,eax
	and	edi,07Fh
	shr	edi,3
	mov	ebx,eax
	and	ebx,07Fh
	and	bl,0111b
	mov	ch,[(KeyboardType PTR esi+ebx).Bits]		; get the bit to test
	test	[(KeyboardType PTR esi).KeyLock],CAPSLOCK	; is the caps lock on?
	je	short ??capsoff		; if not don't worry about it
	test	ch,[(KeyboardType PTR esi+edi).KeysCapsLock]	; get code for keycaps
	je	short ??capsoff		; its not effected
	xor	ah,SHIFTPRESS		; toggle the shift flag

??capsoff:
	;
	;------	Toggle the shift state if the num-lock key is on (if necessary).
	;
	test	[(KeyboardType PTR esi).KeyLock],NUMLOCK	; is the num lock key on?
	je	short ??numlockoff	; if not don't worry about it
	test	ch,[(KeyboardType PTR esi+edi).KeysNumLock]	; get code for numlock
	je	short ??numlockoff	; if not effected skip toggle
	xor	ah,SHIFTPRESS		; toggle the shift flag if effected

??numlockoff:
;------ Remember the current control/shift/alt bit settings for later use.

;??noshiftever:
	mov	[(KeyboardType PTR esi).CtrlFlags],ah		; save off shift-ctrl-alt flags
					; for the mouse and joystick routines
					; to use in stuffing key into the
					; keyboard buffer.

	mov	ecx,eax
	xor	eax,eax
	mov	ax,cx

IF DEBUG
	cmp	[(KeyboardType PTR esi).KeyIntDisabled],1
	jne	??not_currently_disabled

	inc	[BYTE PTR 0B0002h]

	cmp	eax,115			; is it the F4 key
	je	??disable
	cmp	eax,118			; is it less then F7 key
	jb	??justpass
	cmp	eax,120			; is it greater than F9 key
	ja	??justpass
??disable:
	mov	[(KeyboardType PTR esi).KeyIntDisabled],0
??justpass:
	jmp	??passcode

??not_currently_disabled:
	cmp	eax,125
	jne	??not_toggle

	inc	[BYTE PTR 0B0000h]

	mov	[(KeyboardType PTR esi).KeyIntDisabled],1
	jmp	??absorbcode
ENDIF

??not_toggle:


;------	The CTRL-ALT-DEL key combination always gets passed to the system.
	cmp	eax,0668H		; is it ctrl alt del?
	je	??passcode
	cmp	eax,064CH		; is it ctrl alt ext del?
	je	??passcode	; if so don't add it to the buffer

;------ Special Ctrl-C check.
	cmp	eax,0230h
	je	short ??breaker
	cmp	eax,027Eh
	jne	short ??nobreak
??breaker:
	mov	[(KeyboardType PTR esi).Break],1

??nobreak:
;------	Check for Music and Sound control keys.
;	cmp	ax,0420H		; is this an alt s
;	jne	short ??checkmusic	; toggle the Sound variable
;	push	ax
;	mov	ax,[SoundOn]
;	xor	ax,01H
;	push	ax
;	add	sp,2
;	pop	ax

;??checkmusic:
;	cmp	ax,0434H		; is this an alt m
;	jne	short ??esc		; toggle the Music variable
;	push	ax
;	mov	ax,[MusicOn]
;	xor	ax,01H
;	push	ax
;	add	sp,2
;	pop	ax

;??esc:

	push	eax
	call	Stuff_Key_Num
	pop	eax
??skipstuff:

;------	Do the special ESC routine if necessary.
	cmp	al,110			; is this the esc key?
	jne	short ??noroutine	; if not goto the pass always
	cmp	[(KeyboardType PTR esi).EscRoutine],0 ;if vector is 0 don't jump
	je	short ??noroutine
	push	eax
	call	[(KeyboardType PTR esi).EscRoutine]
	pop	eax

??noroutine:
;------	Check to see if the key is to be passed to the system or not.
	mov	edi,OFFSET (KeyboardType PTR 0).PassAlways	; get offset to table
	add	edi,esi
	mov	ecx,(OFFSET (KeyboardType PTR 0).PassAlwaysEnd - OFFSET (KeyboardType PTR 0).PassAlways) ; get number of pass always CDY JLB MOD 7/11 was
	repne	scasb			; look for a match
	or	ecx,ecx			; see if there was no match
	jne	??passcode	; CDY JLB 7/11 optimization

??passalways:
	; now check for conditional passes
	mov	edi,OFFSET (KeyboardType PTR 0).CondPassKey	; get offset to cond key table
	add	edi,esi
	mov	ecx,(OFFSET (KeyboardType PTR 0).CondPassCond-OFFSET (KeyboardType PTR 0).CondPassKey) ; get number of entries
	shr	ecx,1			; cut in half for words
	repne	scasw			; look for a match
	jcxz	short ??notcondpass	; OPTIMIZATION CDY JLB
	mov	bx,[(OFFSET (KeyboardType PTR 0).CondPassCond - OFFSET (KeyboardType PTR 0).CondPassKey) - 2 + edi]
	and	bx,dx			; are the conditions met?
	je	short ??notcondpass	; NO... check normally.
	jmp	short ??passcode	; YES... pass back to system.
;
;------	Last check before passing keycode back to the system.
;
??notcondpass:
	test	edx,FILTERONLY		; is the filter only flag on?
	je	short ??absorbcode	; if not, absorb the code.

??passcode:
	inc	[(KeyboardType PTR esi).PassCount]

	; Step 5.
	; Now it is time to set up for the call by returning by poking
	; the old interupt handle address in.
	mov	[(KeyboardType PTR esi).PMIssuedKeyInt],1		; Make it TRUE
	mov	eax,[(KeyboardType PTR esi).KeyOldPMIOffset]	; Get orig offset.
	mov	ebx,[(KeyboardType PTR esi).KeyOldPMISelector]	; Get orig selector.
	mov	[ss:ebp+4],eax					; Poke offset.
	mov	[ss:ebp+8],ebx					; Poke selector.

	; Step 6.
	pop	fs gs es ds
	popad
	pop	ebp

	; Step 7.
	iretd

??absorbcode:
	in	al,KEYCTRL			; get the control port
	mov	ah,al
	or	al,080H				; reset bit for keyboard
	out	KEYCTRL,al
	xchg	ah,al				; get orig control data
	out	KEYCTRL,al			; restore control data

	mov	al,[496h]			; get extended keys
	and	al,0FDh				; turn off last key e0 flag
	mov	[496h],al			; set extended keys

	mov	al,CLEARISR			; value to clear In Service Register
	out	INTCHIP0,al			; 8259 interrupt chip controller 0

	pop	fs gs es ds
	popad

	pop	ebp
	add	esp,8
	popfd
endif;ifdef NOT_FOR_WIN95
	iret

	ENDP	Keyboard_Interrupt

ELSE
;***************************************************************************
;* KEYBOARD_INTERRUPT -- Stub for the keyboard interrupt call real mode    *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    This is an interrupt routine.                              *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*


DATASEG
STRUC	RealModeCallStruc
	_EDI  DD	0
	_ESI  DD	0
	_EBP  DD	0
	      DD        0
	_EBX  DD	0
	_EDX  DD	0
	_ECX  DD	0
	_EAX  DD        0
	FLAGS DW	0
	_ES   DW	0
	_DS   DW	0
	_FS   DW	0
	_GS   DW	0
	_IP   DW	0
	_CS   DW	0
	_SP   DW	0
	_SS   DW	0
	      dd	0
	      dd	0
  nothing     dd	0
ENDS

RMDS RealModeCallStruc  <>

CODESEG

PROC	Keyboard_Interrupt	Near

; This option of the keyboard interrupt handle will not be
; available at this moment because the light version of Rational System DOS
; Extender do not allow a DPMI real mode call which is
; DMPI INT 31h funtion 0301h

ifdef NOT_FOR_WIN95
	pushad
	push	fs gs es ds

	mov	ax , _DATA
	mov	es , ax
	mov	ds , ax

	lea	edi , [ RMDS ]
	lea	ecx , [ RMDS . nothing ]
	sub	ecx , edi
	xor	eax , eax
	shr	ecx , 2
	rep	stosd

	mov	eax , 0300h
	mov	bl , [ byte ptr RMVector ]
	xor	bh , bh
	xor	cx , cx
	lea	edi , [RMDS]
	int	DPMI_INTR

; this is here only for testing to make sure
; that a real mode interrupt is bieng issued.
mov	ax , _DATA
mov	es , ax
mov	ds , ax
mov [ byte ptr 0b0000h + 10 * 80 + 40 ] , 040h
jc	??error
mov [ byte ptr 0b0000h + 10 * 80 + 42 ] , 041h

??error:
	pop	ds es gs fs
	popad
endif;ifdef NOT_FOR_WIN95
	iretd
	ENDP

ENDIF

LABEL 	LockedCodeEnd		BYTE

;***************************************************************************
;* End of File.								   *
;***************************************************************************
END