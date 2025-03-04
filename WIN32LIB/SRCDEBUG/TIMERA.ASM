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
;*                 Project Name : Timer stuff                              *
;*                                                                         *
;*                    File Name : TIMERA.ASM                               *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : July 6, 1994                             *
;*                                                                         *
;*                  Last Update : March 14, 1995   [PWG]                   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Get_RM_Timer_Address -- Return address of real mode code for copy.    *
;*   Get_RM_Timer_Size -- return size of real mode timer code.             *
;*   Increment_Tick_Count -- Increments WW system timer.                   *
;*   Timer_Interrupt -- Temp routine to mimic a timer system calling our.  *
;*   Install_Timer_Interrupt -- Installs the timer interrupt routine.      *
;*   Remove_Timer_Interrupt -- Removes the timer interrupt vectors.       **
;*   Set_Timer_Frequency -- Set the frequency of the timer.                *
;*   Set_Timer_Rate -- Set the rate of the timer.                          *
;*   Get_System_Tick_Count -- Returns the system tick count.               *
;*   Get_User_Tick_Count -- Get tick count of user clock.                  *
;*   Increment_Timers -- Increments system and user timers.                *
;*   Get_Num_Interrupts -- Returns the number of interrupts that have occured*
;*   Timer_Interrupt_Func -- Handles core timer code                       *
;*   Disable_Timer_Interrupt -- Disables at the hardware level             *
;*   Enable_Timer_Interrupt -- Enables at the hardware level               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT


DPMI_INTR	equ	31h	
TRUE		equ	1			; Boolean 'true' value
FALSE		equ	0			; Boolean 'false' value

LOCALS ??

;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Equates ////////////////////////////////////////

SYSTEM_TIMER_FREQ	equ	60	; Frequency of system timer.

;********************************************************************
; There are two ways to call our interrupt chain in protected mode.  
; The obvious way it to call the address that we replaced in the
; PM interrupt chain.  This method is a little difficult but works and
; should always work.


;********************************************************************
; The RM and PM interrupts can be installed at the same time or seperately.
; Installing at the same time is the best method, the other method
; can be used to faciliated debugging when you only want one or the other
; called.  Both methods work.
; -SKB July 21, 1994.
INSTALL_SEPERATE	equ	FALSE


INTCHIP0	EQU	20h		; 8259 interrupt chip controller 0
CLEARISR	EQU	20h		; Value to write to 8259 to reenable interrupts.
IRQ0INTNUM	EQU	08h		; IRQ0 interrupt vector number.
DOS_SYS_CALL	EQU	21h		; to do TNT DOS-XNDR system calls.
LOCK_PAGES	EQU	5		; Lock pages subfunction using DX_MEM_MGT
UNLOCK_PAGES	EQU	6		; Unlock pages subfunction using DX_MEM_MGT

TIMER_CONST	EQU	1193180		; TIMER_CONST / FREQ = rate to set 8259 chip

TIMERCMDREG	EQU	043H		; timer command register port.
TIMER0PORT	EQU	040H		; timer channel 0 port
TIMETYPE	EQU	036H		; type of timer.
	;  36H = 0011 0110			    
	;        --         select channel 0			    
	;          --       read/load low byte then high byte for timer			    
	;             ---   timer mode 3			    
	;                -  0 - binary , 1 - BCD data
	
;//////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////// Structs ////////////////////////////////////////


; Structure of memory in real mode handler.
; This is at the very start of the real mode code.
; This information may not change unless the real mode version is also changed.

STRUC TimerType
; For speed, PM uses a DD while RM used DW
; For speed, SysRate and SysError are DD in PM and are DW in real mode.

	TrueRate		DD	?	; True rate of clock. (only use word)
    	SysTicks		DD	?	; Tick count of timer.
	SysRate			DD	?	; Desired rate of timer.
	SysError	 	DD	?	; Amount of error in clock rate for desired frequency.
	SysCurRate	 	DW	?	; Keeps track of when to increment timer.
	SysCurError		DW	?	; Keeps track of amount of error in timer.

    	UserTicks		DD	?	; Tick count of timer.
	UserRate	 	DD	?	; Desired rate of timer.
	UserError	 	DD	?	; Amount of error in clock rate for desired frequency.
	UserCurRate	 	DW	?	; Keeps track of when to increment timer.
	UserCurError		DW	?	; Keeps track of amount of error in timer.

	DosAdder		DW	? 	; amount to add to DosFraction each interrupt.
	DosFraction		DW	?	; Call dos when overflowed.

	OldRMI			DD	?	; The origianl RM interrupt seg:off.
	OldPMIOffset		DD	?	; The origianl PM interrupt offset		
	OldPMISelector		DD	?	; The original PM interrupt segment.

	CodeOffset		DW	?	; Offset of the code in the RM stuff.
	CallRMIntOffset		DW	?	; Offset of function to call DOS timer interrupt.
	CallRMIntAddr		DD	?	; PM address of CallRealIntOffset for speed.

	PMIssuedInt		DD	0	; PM signals RM to just call Int chain.	

; These are just used for information on testing.  When all is done, they can
; be removed, but why?  The don't add too much proccessing time and can
; be useful.
	NumPMInts		DD	?	; Number of PM interrupts
	NumRMInts		DD	?	; Number of RM interrupts.

ENDS


;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////// Prototypes //////////////////////////////////////

GLOBAL	 	Get_System_Tick_Count:NEAR
GLOBAL	 	Get_User_Tick_Count:NEAR
GLOBAL	 	Get_RM_Timer_Address:NEAR
GLOBAL	 	Get_RM_Timer_Size:NEAR
GLOBAL	 	Set_Timer_Frequency:NEAR
GLOBAL	 	Timer_Interrupt:NEAR
GLOBAL	 	Install_Timer_Interrupt:NEAR
GLOBAL	 	Remove_Timer_Interrupt:NEAR
GLOBAL	 	Get_Num_Interrupts:NEAR
GLOBAL		Timer_Interrupt_Func:FAR
GLOBAL		Disable_Timer_Interrupt:NEAR
GLOBAL		Enable_Timer_Interrupt:NEAR

;//////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////// Data ////////////////////////////////////////
	DATASEG

; The current time we will just include the real mode stuff
; into the protected mode code and then copy it down.  The C side of
; this will handle this method or reading it off of disk in the real
; method.

LABEL 	RealBinStart	BYTE
include "timereal.ibn"
LABEL	RealBinEnd	BYTE




LABEL	LockedDataStart	BYTE	
RealModeSel	DD	0
RealModePtr	DD	0		; Pointer to real mode memory.
RealModeSize	DD	0		; Pointer to real mode memory.
LABEL	LockedDataEnd	BYTE

	
InitFlags	DD	0		; Flags to indicate what has been initialized.

; InitFlags that are set to have a fully functional interrupt.
IF_ALLOC_RM		equ	1h		; Allocation of RM was successful.
IF_SET_VECTORS		equ	2h		; Vectors have been set.
IF_LOCKED_PM_CODE	equ	4h		; Locked PM code for DPMI.
IF_LOCKED_PM_DATA	equ	8h		; Locked PM code for DPMI.
IF_RATE_CHANGE		equ	10h		; Timer rate was changed.
IF_FUNCTIONAL		equ	20h		; Timer is in and functional.
IF_LOCKED_RM_CODE	equ	40h		; Timer is in and functional.

;//////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////// Code ////////////////////////////////////////

	CODESEG

;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////// Init routines ////////////////////////////////////////

;***************************************************************************
;* GET_RM_TIMER_ADDRESS -- Return address of real mode code for copy.      *
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
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_RM_Timer_Address C Near

	mov	eax, OFFSET RealBinStart
	ret

	ENDP

;***************************************************************************
;* GET_RM_TIMER_SIZE -- return size of real mode timer code.               *
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
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_RM_Timer_Size C Near

	mov	eax, OFFSET RealBinEnd - OFFSET RealBinStart
	ret

	ENDP


;***************************************************************************
;* SET_TIMER_RATE -- Set the rate of the timer.                            *
;*                                                                         *
;*                                                                         *
;* INPUT:  ebx = rate to set timer were rate = 1193180 / freq              *
;*                                                                         *
;* OUTPUT: none                                                            *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 SKB : Created.                                             *
;*=========================================================================*
PROC	Set_Timer_Rate Near

	push	eax
	pushf					; to save int enable flag	
	cli					; disable interupts while setting up swapper

	mov	al,TIMETYPE			; setup to modify timer 0
	out	TIMERCMDREG,al			; send command.
	mov	eax,ebx				; get rate.
	out	TIMER0PORT,al			; output low byte
	mov	al,ah
	out	TIMER0PORT,al			; output high byte

	sti
	popf					; get int enable flag.
	pop	eax

	ret
ENDP	Set_Timer_Rate

;***************************************************************************
;* SET_TIMER_FREQUENCY -- Set the frequency of the timer.                  *
;*                                                                         *
;*                                                                         *
;* INPUT:  INT Frequency of user timer.                                    *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
PROC	Set_Timer_Frequency C NEAR
	USES	eax,ebx,ecx,edx
	ARG	freq:DWORD
	LOCAL	clockrate:DWORD
	LOCAL	clockfreq:DWORD

	test	[InitFlags],IF_FUNCTIONAL	; Is our timer system installed?
	jz	??timer_not_installed		; if not, this is not legal.


	; Find out the greater of the frequencies (user or system.)
	; Assign the True rate value based of of that.
	; store the max frequency in ecx.
	mov	ecx,[freq]			; get user frequency.
	cmp	ecx,SYSTEM_TIMER_FREQ		; compare it with system frequency
	jg	??user_is_fastest		; is user frequency faster?
	mov	ecx,SYSTEM_TIMER_FREQ		; no, set clock freq to system frequency.
??user_is_fastest:   

	; now get the rate that the clock will be set at.
	; ecx is still max frequency.
	mov	esi,[RealModePtr]

	mov	eax,TIMER_CONST			; get the clock constant value.
	xor	edx,edx				; zero for divide.
	div	ecx				; rate = TC/freq => eax = eax/ecx;
	mov	[(TimerType PTR esi).TrueRate],eax ; Set our true rate.
	mov	ebx,eax				; save for later. DO NOT USE UNTIL CALL

	; Set up variables to call DOS correctly.
	; When DosFraction overflows, DOS is called.
	mov	[(TimerType PTR esi).DosAdder],ax	; Init count to until call dos.
	mov	[(TimerType PTR esi).DosFraction],0	; init the fraction.

	; now set up the system timer.
	mov	ecx,SYSTEM_TIMER_FREQ			; get frequency.
	mov	eax,TIMER_CONST				; get constant for formula rate=C/freq.
	xor	edx,edx				   	; make sure zero for divide
	div	ecx					; calculate rate
	mov	[(TimerType PTR esi).SysCurRate],ax	; Init current stuff.
	mov	[(TimerType PTR esi).SysCurError],ax	; Init current stuff.
	mov	[(TimerType PTR esi).SysRate],eax	; Save rate of timer
	mov	[(TimerType PTR esi).SysError],edx	; Save error of timer
	; Do not set SysTicks to zero since it always has the same frequency.  It
	; should be zero out only when the system clock is installed.

	; now set up the user timer.
	mov	ecx,[freq]				; get frequency of user timer.
	mov	eax,TIMER_CONST				; get constant for formula rate=C/freq.
	xor	edx,edx				   	; make sure zero for divide
	div	ecx					; calculate rate
	mov	[(TimerType PTR esi).UserCurRate],ax	; Init current stuff.
	mov	[(TimerType PTR esi).UserCurError],ax; Init current stuff.
	mov	[(TimerType PTR esi).UserRate],eax	; Save rate of timer
	mov	[(TimerType PTR esi).UserError],edx	; Save error of timer
	mov	[(TimerType PTR esi).UserTicks],0	; User timer sets to zero when freq change.

	; Call function to set the rate of the chip, ebx = rate from above.
	call	Set_Timer_Rate

??timer_not_installed:

	ret

	ENDP


;***************************************************************************
;* INSTALL_TIMER_Interrupt -- Installs the timer interrupt routine.        *
;*                                                                         *
;*                                                                         *
;* INPUT:  VOID * pointer to RM binary in PM memory.                       *
;*         LONG Size of RM binary.                                         *
;*         INT  frequency of user timer.                                   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Install_Timer_Interrupt C Near
	USES	ebx,ecx,edx
	ARG	rm_ptr:DWORD
	ARG	rm_size:DWORD
	ARG	freq:DWORD
	ARG	partial:DWORD

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
	mov	eax,0100h		; set function number
	mov	ebx,[rm_size]		; get size of RM binary.
	add	ebx,15			; round up 
	shr	ebx,4			; convert to pages.
	int	DPMI_INTR	 	; do call.
	jc	??error		 	; check for error.
	mov	[ RealModeSel ]	, edx
	shl	eax,4			; convert segment to offset.
	mov	[RealModePtr],eax	; save offset to global variable.

	; now lock the real mode memory that we allocated, just in
	; case it needs to be.

	mov	eax,0600h	 	; function number.
	mov	ecx,[RealModePtr]	; ecx must have start of memory.
	mov	edi,[rm_size]	 	; edi will have size of region in bytes.
	mov	[RealModeSize],edi	; save off the size for the unlock
	shld	ebx,ecx,16
	shld	esi,edi,16
   	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
	or	[InitFlags],IF_LOCKED_RM_CODE


	; set up source and destination pointers for the copy.
	mov	eax,[RealModePtr]
	mov	esi,[rm_ptr]		; Set up our source pointer.
	or	[InitFlags],IF_ALLOC_RM ; set successful
	mov	edi,eax			; put it into esi for copy.
	mov	ecx,[rm_size]
	rep	movsb			; write RM bin to RM memory.


	; restore esi to point to data and initialize some of it.
	mov	esi,[RealModePtr]
	mov	eax,esi						; get real mode 32 offset.
	shl	eax,12						; make seg in high eax.
	mov	ax,[(TimerType PTR esi).CallRMIntOffset]	; create RM addr of call chain.
	mov	[(TimerType PTR esi).CallRMIntAddr],eax		; save it for use in PM int.

	cmp	[partial],0
	jne	??partial_exit

	;==========================================================================
	; Get the protected mode interrupt vector keyboard.
	; input ax = 0204
	; bl = number of interrupt to get
	; output: cf error
	;==========================================================================
	mov	eax,0204h		; Get proteced mode
	mov	bl,IRQ0INTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	mov	[(TimerType PTR esi).OldPMIOffset],edx	 ; save offset.
	mov	[(TimerType PTR esi).OldPMISelector],ecx ; save selector.

	;==========================================================================
	; Get the real mode interrupt vector keyboard
	; input ax = 2503, cl = number of interrupt to get
	; output cf error, CX:DX = address (seg:off) of RM int handler routine.
	; cl set above
	;==========================================================================
	mov	eax,0200h
	mov	bl,IRQ0INTNUM		; IRQ1 interrupt vector
	int	DPMI_INTR		; do call.
	jc	??error
	shl 	edx,16
	shld	ecx,edx,16
	mov	[(TimerType PTR esi).OldRMI],ecx

	;==========================================================================
	; only separate method of installation is posible. 
	; Now it is time to set the Protected mode interrupt Keyboard
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================
	mov	eax, 0205h
	mov	bl,IRQ0INTNUM
	mov	cx , cs
	lea	edx, [Timer_Interrupt] ; get address of protected code int hand.
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
	mov	bl,IRQ0INTNUM
	mov	ecx,[RealModePtr]     			; get address of real code int hand.
	shr	ecx,4					; put segment in hi word.
	mov	dx,[(TimerType PTR esi).CodeOffset]  ; Get address of code
	int	DPMI_INTR				; do call.
	jc	??error
	or	[InitFlags],IF_SET_VECTORS

	; now set the frequency.
	mov	eax,[freq]
	or	[InitFlags],IF_FUNCTIONAL
	push	eax
	call	NEAR Set_Timer_Frequency
	mov	[(TimerType PTR esi).SysTicks],0	; Only place SysTicks in inited.
	mov	[(TimerType PTR esi).UserTicks],0	; Timers start off on same foot.
	pop	eax
	or	[InitFlags],IF_RATE_CHANGE

	; we have finished with success.
??partial_exit:
	mov	eax,1			; signal success.
	ret
??error:
       	xor	eax,eax			; signal an error.
	ret		

	ENDP


;***************************************************************************
;* REMOVE_TIMER_INTERRUPT -- Removes the timer interrupt vectors.         *
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
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Remove_Timer_Interrupt C NEAR
	USES	ebx,ecx,edx

	; check if timer was previosly install
	mov	esi,[RealModePtr]
	test	esi,esi
	jz	??error


	test	[InitFlags],IF_SET_VECTORS
	jz	??vectors_not_set
	;==========================================================================
	; Now it is time to set the real Interrupt Keyboard
	; ax = function number (0201
	; bl = number of interrupt to set
	; cx:dx = address of RM interrupt handler
	;====================================================================

	mov	eax, 0201h
	mov	bl,IRQ0INTNUM
	mov	edx,[(TimerType esi).OldRMI]		; get the RM address.
	shld	ecx , edx , 16
	int	DPMI_INTR				; do call.
	jc	??error

	;==========================================================================
	; Now it is time to set the Protected mode interrupt
	; ax = function number (0205
	; bl = number of interrupt to set
	; cx:edx = address of PM interrupt handler
	;==========================================================================

	mov	eax, 0205h
	mov	bl,IRQ0INTNUM
	mov	ecx,[(TimerType esi).OldPMISelector] 	; Get PM segment to put int ds later.
	mov	edx,[(TimerType esi).OldPMIOffset] 	; Get PM offset
	int	DPMI_INTR		  ; do call.
	jc	??error

??vectors_not_set:

	; Call function to set the rate of the chip, ebx = rate.
	test	[InitFlags],IF_RATE_CHANGE	; was it changed?	
	jz	??rate_not_changed
	mov	ebx,0FFFFh			; back to 18.2 time per second.
	call	Set_Timer_Rate			; call function to set timer.
??rate_not_changed:
	; now free up the real mode memory.
	test	[InitFlags],IF_LOCKED_RM_CODE
	jz	??rm_not_locked

	mov	eax , 0601h
	mov	ecx, [RealModePtr]
	mov	edi, [RealModeSize]
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
	; Unlock code
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
	mov	eax,1			; signal success.
	mov	[RealModePtr],0		; To say we can do it again sometime.
	mov	[InitFlags],0		; To say we can do it again sometime.
	ret
??error:
       	xor	eax,eax			; signal an error.
	ret

	ENDP	




;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////// Access routines //////////////////////////////////////


;***************************************************************************
;* GET_NUM_INTERRUPTS -- Returns the number of interrupts that have occured*
;*                                                                         *
;* INPUT: TRUE - returns num RM ints.                                      *
;*        FALSE - return num PM ints.                                      *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/12/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_Num_Interrupts C Near
	USES	esi
	ARG	realmode:DWORD

	mov	esi,[RealModePtr]
	cmp	[realmode],0
	je	??prot_mode
	mov	eax,[(TimerType PTR esi).NumRMInts]
	ret
??prot_mode:
	mov	eax,[(TimerType PTR esi).NumPMInts]
	ret

	ENDP

;***************************************************************************
;* GET_SYSTEM_TICK_COUNT -- Returns the system tick count.                 *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_System_Tick_Count C Near
	USES	esi

	mov	esi,[RealModePtr]
	mov	eax,[(TimerType PTR esi).SysTicks]
	ret

	ENDP


;***************************************************************************
;* GET_USER_TICK_COUNT -- Get tick count of user clock.                    *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/12/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_User_Tick_Count C Near
	USES	esi

	mov	esi,[RealModePtr]
	mov	eax,[(TimerType PTR esi).UserTicks]
	ret

	ENDP


;//////////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////// Interrupt routines ///////////////////////////////////

; These macros are placed here to handle to duplicate code in 2 methods in
; the Timer_Interrupt function.


MACRO	SET_DS_ESI_TO_RM
	; Sets DS : ES to point to DGROUP _DATA selector
	; Set esi to point to RealModePtr
	; Corrupts eax

	mov	ax , _DATA
	mov	ds , ax
	mov	es , ax
	mov	esi,[RealModePtr]		; Point to start of RM data.
ENDM

	
MACRO	INCREMENT_TIMERS
	; Expects ESI to point to real mode memory.

	inc	[(TimerType PTR esi).NumPMInts]		; For testing.

	mov	eax,[(TimerType PTR esi).TrueRate]	; Get the rate of the PC clock.
	sub	[(TimerType PTR esi).SysCurRate],ax	; Sub from our rate counter.
	ja	??end_sys				; If !below zero, do not inc.
	mov	ebx,[(TimerType PTR esi).SysRate]	; Get rate of timer.
	mov	ecx,[(TimerType PTR esi).SysError]	; Get amount of error.
	add	[(TimerType PTR esi).SysCurRate],bx	; Add rate to the current.
	sub	[(TimerType PTR esi).SysCurError],cx	; Subtract err from error count.
	jb	??error_adj_sys				; If wrapped don't inc.
	inc	[(TimerType PTR esi).SysTicks]	; increment the timer.
	jmp	short ??end_sys
??error_adj_sys:
	add	[(TimerType PTR esi).SysCurError],bx	; reajust the error by timer rate.
??end_sys:
	sub	[(TimerType PTR esi).UserCurRate],ax ; Sub from our rate counter.
	ja	??end_user	     			; If !below zero, do not inc.
	mov	ebx,[(TimerType PTR esi).UserRate]	; Get rate of timer.
	mov	ecx,[(TimerType PTR esi).UserError]	; Get amount of error.
	add	[(TimerType PTR esi).UserCurRate],bx	; Add rate to the current.
	sub	[(TimerType PTR esi).UserCurError],cx; Subtract err from error count.
	jb	??error_adj_user       			; If wrapped don't inc.
	inc	[(TimerType PTR esi).UserTicks]	; increment the timer.
	jmp	short ??end_user
??error_adj_user:
	add	[(TimerType PTR esi).UserCurError],bx; reajust the error by timer rate.
??end_user:

ENDM


MACRO	ENABLE_CLOCK_INT
	; Signal 8259 that we are done and that it can bug us again.
	; Corrupts al.

	mov	al,CLEARISR	; Signal EOI
	sti			; enable interrupts.
	out	INTCHIP0,al 	; 8259 interrupt chip controller 0
ENDM

LABEL 	LockedCodeStart	BYTE

;***************************************************************************
;* TIMER_INTERRUPT -- Temp routine to mimic a timer system calling ours     *
;*   This is a temp routine to call our tick count routine.  It will be    *
;*   replaced once another timer system is put in (such as HMI).           *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/06/1994 SKB : Created.                                             *
;*=========================================================================*

	PROC	Timer_Interrupt	Near
;////////////////////////////// Call prot mode interrupt vector ////////////////////////////////////////
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

	pushfd			; Step 1
	sub	esp,8		; Step 2
	push	ebp		; Step 3
	mov	ebp,esp		; Set up a stack frame to know where to poke address.

	; Step 3 continued.  Push used varables.
	pushad
	push	fs gs es ds


	; Step 4.  Now do processing before I chain.
	; Set up ds:esi to point at start of real memory block (data is first)

	call far Timer_Interrupt_Func

	SET_DS_ESI_TO_RM			; Set ds:esi to point to real mode stuff.

	; Now take care of calling the old DOS timer interrupt vector.
	; This must be the last operation of this module since if we call
	; DOS, we will never return.
	mov	ax,[(TimerType PTR ds:esi).DosAdder] 
	add	[(TimerType PTR esi).DosFraction],ax
	jnc	??no_dos_call					; if not, skip the call.

	; Tell RM that we forced the int and not to update timers.
	mov	[(TimerType PTR esi).PMIssuedInt],1		; Make it TRUE

	; Step 5.
	; Now it is time to set up for the call by returning by poking
	; the old interrupt handle address in.
	mov	eax,[(TimerType PTR esi).OldPMIOffset]		; Get orig offset.
	mov	ebx,[(TimerType PTR esi).OldPMISelector]	; Get orig selector.
	mov	[ss:ebp+4],eax					; Poke offset.
	mov	[ss:ebp+8],ebx					; Poke selector.

	; Step 6.
	pop	ds es gs fs
	popad
	pop	ebp  

	; Step 7.
	iretd				; transfer control to original handler.

??no_dos_call:

	ENABLE_CLOCK_INT

	; Restore all registers.
	pop	ds es gs fs
	popad

	pop	ebp  
	add	esp,8
	popfd	

	iretd
;////////////////////////////// Call prot mode interrupt vector ////////////////////////////////////////
;//////////////////////////////////////////////////////////////////////////////////////////////////////
	ENDP



;***************************************************************************
;* TIMER_INTERRUPT_FUNC -- Handles core timer code                         *
;*                                                                         *
;* This function exists so that we can call it from the core HMI driver    *
;* code when our timer interrupt has not been installed.		   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/14/1995 PWG : Created.                                             *
;*=========================================================================*

	PROC	Timer_Interrupt_Func C Far
	pushfd					; save off the flags
	pushad					; save off the main registers
	push	fs gs es ds			; save off the seg registers
	
	SET_DS_ESI_TO_RM			; Set ds:esi to point to real mode stuff.
	INCREMENT_TIMERS			; Increment Westwoods timers	

	pop	ds es gs fs
	popad
	popfd
	retf
	ENDP

LABEL 	LockedCodeEnd		BYTE

;***************************************************************************
;* DISABLE_TIMER_INTERRUPT_ONLY -- Disables at the hardware level          *
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   06/07/1995 DRD : Created.                                             *
;*=========================================================================*

	PROC	Disable_Timer_Interrupt C Near
	push	eax
	pushf

	sti			; disable all interrupts if not disabled
	in	al,021h		; read interrupt Mask register bits 0-7
				; apply to irq's 0-7
				;   value 0 of enabled
				;   value 1 of disabled
	or	al,001h		; setup to disable irq 0
	out	021h,al		; disable irq 0

	popf			; possibly enable all interrupts (except 0)
	pop	eax
	retf
	ENDP


;***************************************************************************
;* ENABLE_TIMER_INTERRUPT_ONLY -- Enables at the hardware level            *
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   06/07/1995 DRD : Created.                                             *
;*=========================================================================*

	PROC	Enable_Timer_Interrupt C Near
	push	eax
	pushf

	sti			; disable all interrupts if not disabled
	in	al,021h		; read interrupt Mask register bits 0-7
				; apply to irq's 0-7
				;   value 0 of enabled
				;   value 1 of disabled
	and	al,0FEh		; setup to enable irq 0
	out	021h,al		; enable irq 0

	popf			; possibly enable all interrupts
	pop	eax
	retf
	ENDP


	END



