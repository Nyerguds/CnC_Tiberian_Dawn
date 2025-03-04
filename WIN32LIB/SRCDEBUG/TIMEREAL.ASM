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
;*                 Project Name : Timer interrupt for RM                   *
;*                                                                         *
;*                    File Name : TIMEREAL.ASM                             *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : July 8, 1994                             *
;*                                                                         *
;*                  Last Update : July 8, 1994   [SKB]                     *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
MODEL TINY
P386N

LOCALS ??

;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Equates ////////////////////////////////////////

INTCHIP0	EQU	20h		; 8259 interrupt chip controller 0
CLEARISR	EQU	20h		; Value to write to 8259 to reenable interrupts.

CODESEG
;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Data ////////////////////////////////////////
; This information may not change unless the protected mode version is
; also changed.
; For speed, PM uses a DD while RM used DW
TrueRate		DW	0	; True rate of clock. (only use word)
TrueRateNA		DW	0		; used for speed in prot mode.

; For speed, SysRate and SysError are DD in PM and are DW in real mode.
SysTicks		DD	0	; Tick count of timer.
SysRate			DD	0	; Desired rate of timer.
SysError	 	DD	0	; Amount of error in clock rate for desired frequency.
SysCurRate	 	DW	0	; Keeps track of when to increment timer.
SysCurError		DW	0	; Keeps track of amount of error in timer.

UserTicks		DD	0	; Tick count of timer.
UserRate	 	DD	0	; Desired rate of timer.
UserError	 	DD	0	; Amount of error in clock rate for desired frequency.
UserCurRate	 	DW	0	; Keeps track of when to increment timer.
UserCurError		DW	0	; Keeps track of amount of error in timer.

DosAdder		DW	0 	; amount to add to DosFraction each interrupt.
DosFraction		DW	0	; Call dos when overflowed.

OldRMI			DD	0	; The origianl RM interrupt seg:off.
OldPMIOffset		DD	0	; The origianl PM interrupt offset		
OldPMISelector		DD	0	; The original PM interrupt segment.

CodeOffset		DW	RM_Timer_Interrupt_Handler	; Offset of the code in the RM stuff.
CallRMIntOffset		DW	Call_Interrupt_Chain		; Offset of function to call DOS timer interrupt.
CallRMIntAddr		DD	0	; PM address of CallRealIntOffset for speed.

PMIssuedInt		DD	0	; PM signals RM to just call Int chain.	

; These are just used for information on testing.  When all is done, they can
; be removed, but why?  The don't add too much proccessing time and can
; be useful.
NumPMInts		DD	0	; Number of PM interrupts
NumRMInts		DD	0	; Number of RM interrupts.

;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Code ////////////////////////////////////////


; This is here for easy comparison with the PM version.
MACRO INCREMENT_TIMERS
	inc	[NumRMInts]		; For testing.


	; At this point, increment the system and user timers.
	mov	ax,[TrueRate]		; Get the rate of the PC clock.

	sub	[SysCurRate],ax		; Sub from our rate counter.
	ja	??end_sys			; If !below zero, do not inc.

	mov	bx,[WORD PTR SysRate]	; Get rate of timer.
	mov	dx,[WORD PTR SysError]	; Get amount of error.
	add	[SysCurRate],bx		; Add rate to the current.

	sub	[SysCurError],dx	; Subtract err from error count.
	jb	??error_adj_sys		; If !below 0, increment counter.

	inc	[SysTicks]		; increment the timer.
	jmp	short ??end_sys		; don't modify SysCurError.
??error_adj_sys:
	add	[SysCurError],bx	; reajust the error by timer rate.
??end_sys:

	sub	[UserCurRate],ax	; Sub from our rate counter.
	ja	??end_user		; If !below zero, do not inc.

	mov	bx,[WORD PTR UserRate]	; Get rate of timer.
	mov	dx,[WORD PTR UserError]	; Get amount of error.
	add	[UserCurRate],bx	; Add rate to the current.

	sub	[UserCurError],dx	; Subtract err from error count.
	jb	??error_adj_user	; If !below 0, increment counter.

	inc	[UserTicks]		; increment the timer.
	jmp	short ??end_user	; don't modify UserCurError.
??error_adj_user:
	add	[UserCurError],bx	; reajust the error by timer rate.
??end_user:

ENDM




;**************************************************************************
;* RM_INTERRUPT_HANDLER -- Called when processor interrupted in real mode. *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/08/1994 SKB : Created.                                             *
;*=========================================================================*
label RM_Timer_Interrupt_Handler
start_RM_Timer_Interrupt_Handler:

	push	ax
	push	bx
	push	dx
	push	ds

	mov	ax,cs			; Set data segment to code segment 
	mov	ds,ax			;   since data is in code seg.

	cmp	[WORD PTR PMIssuedInt],0; Check to see if PM made Int call.
	mov	[WORD PTR PMIssuedInt],0; Make it false.		
	jne	??call_int_chain	; if so, just call Int Chain.


	INCREMENT_TIMERS


	; Now check to see if we should call the old timer handler.
	mov	ax,[DosAdder]		; Get amount to add each tick.
	add	[DosFraction],ax      	; add it to the fraction.
	jnc	??no_int_chain	      	; Skip call if no overflow.

??call_int_chain:
	pushf				; Push flags for interrupt call.
       	call	[OldRMI]		; chain the call.

??no_int_chain:
	sti
	mov	al,CLEARISR   		; value to clear In Service Register
	mov	dx,INTCHIP0
	out	dx,al			; 8259 interrupt chip controller 0
exit1:

	pop	ds
	pop	dx
	pop	bx
	pop	ax
	iret



;**************************************************************************
;* CALL_INTERRUPT_CHAIN -- Function PM calls to call the RM interrupt chain*
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/08/1994 SKB : Created.                                             *
;*=========================================================================*
Call_Interrupt_Chain:

	pushf
	call	[OldRMI]		;
	retf

STACK	   ; Don't really need this

END




IF 0
; mono print stuff.
	pushf
	push	ax
	push	di
	push	es

	mov	ax,0B000h		; ES:DI = Mono RAM address.
	mov	es,ax
		
	mov	al,'A'
	mov	ah,2
	and	di,63

	stosw

	pop	es
	pop	di
	pop	ax
	popf
ENDIF
