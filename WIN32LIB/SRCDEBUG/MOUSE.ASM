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
;*                 Project Name : Westwood 32 bit Library                  *
;*				  (Mouse Routines)			   *
;*                                                                         *
;*                    File Name : MOUSE.ASM                                *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : August 26, 1994                          *
;*                                                                         *
;*                  Last Update : November 3, 1994   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Install_Mouse -- Initializes mouse driver and verifies mouse exists   *
;*   Remove_Mouse -- uninstalls the mouse interrupt by disabling the call  *
;*   Get_Mouse_X -- Returns the mouses x pixel position                    *
;*   Get_Mouse_Y -- Returns the mouse's y pixel position                   *
;*   Get_Mouse_Button -- Gets the values of the mouse button               *
;*   Set_Mouse_Cursor -- Sets the shape to be used as the mouse.           *
;*   Low_Hide_Mouse -- Low-level routine which hides the mouse		   *
;*   Low_Show_Mouse -- Low level routine which shows the mouse		   *
;*   Mouse_Shadow_Buffer -- Handles storing and restoring the mouse buffer *
;*   Draw_Mouse -- Handles drawing the mouse cursor			   *
;*   Hide_Mouse -- Hides mouse cursor on screen if it was show             *
;*   Show_Mouse -- Display mouse cursor on screen if it was hidden         *
;*   Conditional_Hide_Mouse -- Hides mouse if its with given region        *
;*   Conditional_Show_Mouse -- shows mouse if it was conditionally hidden  *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL				; the product runs in ideal mode
P386				; use 386 real mode instructions
MODEL USE32 FLAT
LOCALS ??			; ?? is the symbol for a local
;WARN				; generate all warnings we can
;JUMPS				; optimize jumps if possible

;---------------------------------------------------------------------------
; Include all of the keyboard specific defines
;---------------------------------------------------------------------------
INCLUDE "keystruc.inc"
INCLUDE "shape.inc"
include "drawbuff.inc"

DOS_SYS_CALL		EQU	21h		; to do TNT DOS-XNDR system calls.
RESTORE_VISIBLE_PAGE	EQU	0
STORE_VISIBLE_PAGE	EQU	1
CONDHIDE		EQU	08000H		; bit for testing conditional region
CONDHIDDEN		EQU	04000H		; bit for testing conditional hidden
;---------------------------------------------------------------------------
; Define any data which needs to be global...
;---------------------------------------------------------------------------

GLOBAL C	RealModePtr:DWORD
GLOBAL C	MInstalled:DWORD
GLOBAL C	MouseBuffer:DWORD
GLOBAL C	LCW_Uncompress:NEAR

GLOBAL C	Get_Shape_Uncomp_Size     :NEAR
GLOBAL C	Get_Shape_Width      	  :NEAR
GLOBAL C	Get_Shape_Original_Height :NEAR
GLOBAL C  Size_Of_Region		  :NEAR
GLOBAL C	_ShapeBuffer		  :DWORD

GLOBAL C  XRes	: dword
GLOBAL C  YRes	: dword


GLOBAL C	VesaFunc : dword
GLOBAL C	Vesa_XRes : near
GLOBAL C	Vesa_YRes : near





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
	     dd ?
  nothing    dd ?
ENDS



;---------------------------------------------------------------------------
; Now lets handle any data in the data segment
;---------------------------------------------------------------------------
	DATASEG

RealInt		DPMI_REGS <>	; structure to call a real mode int
MInstalled	DD	0		; is the mouse installed?
MouseCursor	DD	0
MouseBuffer	DD	0
BufferWidth	DD	0
BufferHeight	DD	0
BufferSize	DD	0
PrevMousePtr	DD	0
MouseBufferSel	DD	0


Draw_Mouse		dd	VGA_Draw_Mouse
Mouse_Shadow_Buffer	dd	VGA_Mouse_Shadow_Buffer

;---------------------------------------------------------------------------
; Time to write some code
;---------------------------------------------------------------------------
	CODESEG

;***************************************************************************
;* INSTALL_MOUSE -- Initializes mouse driver and verifies mouse connected  *
;*                                                                         *
;* First check the mouse interupt to see if the vector is pointing to zero *
;* page.  If it is not then make sure it is not pointing to an IRET.  If   *
;* not call the mouse reset to verify that the hardware is attached.	   *
;*                                                                         *
;* INPUT:	int mouse_max_width  - the max width of the mouse cursor   *
;*		int mouse_max_height - the max height of the mouse cursor  *
;*		int screen_width     - width of the physical screen	   *
;*		int screen_height    - height of the physical screen	   *
;*                                                                         *
;* OUTPUT:      TRUE is mouse driver is initialized, FALSE if unable to    *
;*		initialize mouse driver.				   *
;*                                                                         *
;* PROTO:	int Install_Mouse(	int mouse_max_width,		   *
;*					int mouse_max_height,		   *
;*					int screen_width,		   *
;*					int screen_height);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/26/1994 PWG : Created.                                             *
;*=========================================================================*
GLOBAL C	Install_Mouse:NEAR
PROC	Install_Mouse C NEAR
	USES	eax,ebx,ecx,edx,esi,edi

	ARG	mouse_max_width:DWORD
	ARG	mouse_max_height:DWORD
	ARG	screen_width:DWORD
	ARG	screen_height:DWORD

ifdef NOT_FOR_WIN95
	;*=========================================================================*
	;* Initialize all of the general mouse variables
	;*=========================================================================*
	mov	esi,[RealModePtr]		; get offset of real mode data start
	test	esi , esi			; mouse driver should be install
	jz 	??exit				; after keyboard interrup is install
	mov	eax , [ XRes ]
	shr	eax , 1
	mov	[(KeyboardType esi).MouseX],eax	; set the mouses x coordinate to 160
	mov	eax , [ YRes ]
	shr	eax , 1
	mov	[(KeyboardType esi).MouseY],eax	; set the mouses y coordinate to 100
	mov	[(KeyboardType esi).MState],1	; flag the mouse as hidden
	mov	[(KeyboardType esi).MCState],0	; turn off conditional region
	mov	eax , [ XRes ]
	mov	[(KeyboardType esi).MouseRight],eax
	mov	eax , [ YRes ]
	mov	[(KeyboardType esi).MouseBottom],eax


	;==========================================================================
	; Get the real mode interrupt vector keyboard
	; input ax = 0200, bl = number of interrupt to get
	; output cf error, cx,dx= address (seg:off) of RM int handler routine.
	; cl set above
	;==========================================================================
	mov	eax,0200h
	mov	bl,033h
	int	DPMI_INTR		; do call.
	jc	??error			; no mouse driver present

	;*=========================================================================*
	;* If the interupt vector is pointing to 0000:0000h, there is no mouse
	;*=========================================================================*
	or	cx,dx
	jz	short ??nomouse

	and	edx , 0ffffh
	and	ecx , 0ffffh
	shl	ecx,4
	add	ecx,edx

	;*=========================================================================*
	;* If the first instruction is an IRET, there is no mouse
	;*=========================================================================*

	cmp	[byte ptr ecx],0CFH	; is this an IRET
	jne	short ??mouse_buff	; if it isnt then reset the mouse

??nomouse:
	mov	eax,FALSE				; flag no mouse driver
	mov	[MInstalled],FALSE			; flag no mouse driver
    	jmp	??exit					; exit

??mouse_buff:
	;*=========================================================================*
	;* Allocate two real mode memory buffers for the mouse cursor and the
	;*	mouse shadow
	;*=========================================================================*
	mov	eax,[mouse_max_width]	       	; get the is max width
	mov	[BufferWidth],eax	       	; save it off for set cursor
	mov	edx,[mouse_max_height]	       	; get the max height
	mov	[BufferHeight],edx	       	; save it off for set cursor
	mul	edx			       	; size = max_width * max_height
	add	eax,22			       	; add width/height(8) + para align(15)
	and	al, 0f0h		       	; now size is even paragraphs
	mov	[BufferSize],eax	       	; store off the buffer size
	shl	eax,1			       	; make two of them

 	mov	ebx,eax				; get size of RM binary.
	mov	ecx,eax				; ecx will use it later.
	add	ebx,15				; round up
	shr	ebx,4				; convert to pages.
	mov	eax,0100h			; alloc real buffer
	int	DPMI_INTR	 		; do call.
	jc	??error		 		; check for error.

	mov	esi,[RealModePtr]		; get offset of real mode data start
	mov	[MouseBufferSel], edx
	shl	eax , 16
	mov	[(KeyboardType esi).MouseCursor],eax	; store off the real mode segment
	mov	edx,eax					; get the buffer position
	add	edx,[BufferSize]			; add in the buffer size
	mov	[(KeyboardType esi).MouseBuffer],edx	; store off the real mode segment
	shr	eax,12					; convert the seg/off to 32 bit offset
	mov	edx,eax
	add	edx,[BufferSize]
	mov	[MouseCursor],eax			; store it off in the mouse buffer
	mov	[MouseBuffer],edx			; store it off in the mouse buffer

	mov	eax,0600h				; function number.
	mov	ecx,[MouseCursor]			; ecx must have start of memory.
	mov	edi,[BufferSize]
	shl	edi,1
	shld	ebx,ecx,16
	shld	esi,edi,16
       	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.


??begin:
	mov	esi,[RealModePtr]		; get offset of real mode data start
	; Reset mouse thru int 33h funtion 0
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	xor	ecx , ecx
	mov	[RealInt . _eax ] , 0
	lea	edi, [RealInt]
	int	DPMI_INTR
	mov	eax ,[RealInt . _eax]
	cmp	ax,-1					; was the mouse attached to system
      	jne	??nomouse				; if not exit out of the routine

	mov	[(KeyboardType esi).Adjust],0		; assume we do not need to adjust mouse

;***************************************************************************
; Set the Vesa Parameters

	mov	eax , [ VesaFunc ]
	test	eax , eax
	jz	??set_vga_mouse
	mov	[(KeyboardType esi). VesaPtr ] , eax


	mov	ax ,  [(KeyboardType esi). VESAMouseShadow ]
	mov	[(KeyboardType esi). ShadowPtr] , ax

	mov	ax ,  [(KeyboardType esi). VESAMouseDraw ]
	mov	[(KeyboardType esi). DrawMousePtr ] , ax

	lea	eax , [ VESA_Draw_Mouse ]
	mov	[ Draw_Mouse ] , eax
	lea	eax , [ VESA_Mouse_Shadow_Buffer ]
	mov	[ Mouse_Shadow_Buffer ] , eax

 	mov	eax , [ XRes ]
	mov	[(KeyboardType esi). MouseRight ] , eax

	mov	eax , [ YRes ]
	mov	[(KeyboardType esi). MouseBottom ] , eax

	lea	edi , [(KeyboardType esi). VesaBankTable]
	lea	esi , [ BankTable ]
	mov	ecx , 8
	rep	movsd

	mov	esi,[RealModePtr]		; get offset of real mode data start
	jmp	??end_vesa

??set_vga_mouse:

	mov	ax ,  [(KeyboardType esi). VGAMouseShadow ]
	mov	[(KeyboardType esi). ShadowPtr] , ax

	mov	ax ,  [(KeyboardType esi). VGAMouseDraw ]
	mov	[(KeyboardType esi). DrawMousePtr ] , ax

	lea	eax , [ VGA_Draw_Mouse ]
	mov	[ Draw_Mouse ] , eax
	lea	eax , [ VGA_Mouse_Shadow_Buffer ]
	mov	[ Mouse_Shadow_Buffer ] , eax

??end_vesa:
	call 	Reset_Mouse
	mov	eax , TRUE
	ret

??error:
	mov	eax,FALSE
??exit:
endif ; NOT_FOR_WIN95
	ret
	ENDP	Install_Mouse

;***************************************************************************
;* ResET_MOUSE -- Reset mouse to a new graphif mode			   *
;*									   *
;* reset mouse driver funtions to a a currently graphic mode		   *
;*                                                                         *
;* INPUT:								   *
;* OUTPUT:      							   *
;* PROTO:	Reset_Mouse ( void ) 					   *
;*									   *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/26/1994 JRJ : Created.                                             *
;*=========================================================================*
GLOBAL C	Reset_Mouse:NEAR
PROC	Reset_Mouse C NEAR
	USES	eax,ebx,ecx,edx,esi,edi

ifdef NOT_FOR_WIN95
	;*=========================================================================*
	;* Initialize all of the general mouse variables
	;*=========================================================================*
	mov	esi , [RealModePtr]		; get offset of real mode data start
	test	esi , esi
	jz	??exit
	mov	eax , [ XRes ]
	shr	eax , 1
	mov	[(KeyboardType esi).MouseX],eax	; set the mouses x coordinate to 160
	mov	eax , [ YRes ]
	shr	eax , 1
	mov	[(KeyboardType esi).MouseY],eax	; set the mouses y coordinate to 100
	mov	[(KeyboardType esi).MState],1	; flag the mouse as hidden
	mov	[(KeyboardType esi).MCState],0	; turn off conditional region
	mov	eax , [ XRes ]
	mov	[(KeyboardType esi).MouseRight],eax
	mov	eax , [ YRes ]
	mov	[(KeyboardType esi).MouseBottom],eax


	mov	[(KeyboardType esi).Adjust],0		; assume we do not need to adjust mouse

;***************************************************************************
; Set the Vesa Parameters

	mov	eax , [ VesaFunc ]
	test	eax , eax
	jz	??set_vga_mouse
	mov	[(KeyboardType esi). VesaPtr ] , eax


	mov	ax ,  [(KeyboardType esi). VESAMouseShadow ]
	mov	[(KeyboardType esi). ShadowPtr] , ax

	mov	ax ,  [(KeyboardType esi). VESAMouseDraw ]
	mov	[(KeyboardType esi). DrawMousePtr ] , ax

	lea	eax , [ VESA_Draw_Mouse ]
	mov	[ Draw_Mouse ] , eax
	lea	eax , [ VESA_Mouse_Shadow_Buffer ]
	mov	[ Mouse_Shadow_Buffer ] , eax

 	mov	eax , [ XRes ]
	mov	[(KeyboardType esi). MouseRight ] , eax

	mov	eax , [ YRes ]
	mov	[(KeyboardType esi). MouseBottom ] , eax

	lea	edi , [(KeyboardType esi). VesaBankTable]
	lea	esi , [ BankTable ]
	mov	ecx , 8
	rep	movsd

	mov	esi,[RealModePtr]		; get offset of real mode data start
	jmp	??end_vesa

??set_vga_mouse:

	mov	ax ,  [(KeyboardType esi). VGAMouseShadow ]
	mov	[(KeyboardType esi). ShadowPtr] , ax

	mov	ax ,  [(KeyboardType esi). VGAMouseDraw ]
	mov	[(KeyboardType esi). DrawMousePtr ] , ax

	lea	eax , [ VGA_Draw_Mouse ]
	mov	[ Draw_Mouse ] , eax
	lea	eax , [ VGA_Mouse_Shadow_Buffer ]
	mov	[ Mouse_Shadow_Buffer ] , eax


??end_vesa:
       ; S Mickey/pixel Ratio cursor limits
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	mov	ecx , 8
	mov	edx , 16
	mov	[RealInt . _eax ] , 0fh
	mov	[RealInt . _ecx] , ecx
	mov	[RealInt . _edx] , edx
	xor	ecx , ecx
	lea	edi, [RealInt]
	int	DPMI_INTR

	; Set Min/Max X pos
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	mov	ecx , 0
	mov	edx , [ XRes ]
	cmp	edx , 320
	jne	??set_it
	shl	edx , 1
	mov	[(KeyboardType esi).Adjust],1

??set_it:
;	dec	edx
	mov	[RealInt . _eax ] , 7
	mov	[RealInt . _ecx] , ecx
	mov	[RealInt . _edx] , edx
	xor	ecx , ecx
	lea	edi, [RealInt]
	int	DPMI_INTR

	; Set Min/Max Y pos
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	mov	ecx , 0
	mov	edx , [ YRes ]
	dec	edx
	mov	[RealInt . _eax ] , 8
	mov	[RealInt . _ecx] , ecx
	mov	[RealInt . _edx] , edx
	xor	ecx , ecx
	lea	edi, [RealInt]
	int	DPMI_INTR


IF 0
	; Check for scale factors in X and Y pos
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	mov	ecx , [ XRes ]
	mov	edx , [ YRes ]
	sub	ecx , 8
	sub  	edx , 16
	mov	[RealInt . _eax ] , 4
	mov	[RealInt . _ecx] , ecx
	mov	[RealInt . _edx] , edx
	xor	ecx , ecx
	lea	edi, [RealInt]
	int	DPMI_INTR
	; Read mouse position thru int 33 funtion 3
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	xor	ecx , ecx
	mov	[RealInt . _eax ] , 3
	lea	edi, [RealInt]
	int	DPMI_INTR
	mov	ecx ,[RealInt . _ecx]
	mov	edx ,[RealInt . _edx]

      ; compute Scale values X Y for different vendor mouse driver if nessesary
	add 	ecx , 8
	add	edx , 16
	cmp	ecx , [ XRes ]
	mov	[(KeyboardType esi).Adjust_XPos],0
	jz	??No_scaleX
	mov	[(KeyboardType esi).Adjust_XPos],ecx
??No_scaleX:
	cmp	edx , [ YRes ]
	mov	[(KeyboardType esi).Adjust_YPos],0
	jz	??No_scaleY
	mov	[(KeyboardType esi).Adjust_YPos],edx
??No_scaleY:
ENDIF

	mov	ecx, [ XRes ]				; set the mouses x coordinate to 160
	mov	edx, [ YRes ]				; set the mouses x coordinate to 160
	cmp	[(KeyboardType esi).Adjust],1
	je	??no_ecx_shift
	shr	ecx , 1
??no_ecx_shift:
	shr	edx , 1
	mov	[MInstalled],TRUE			; set the fact that mouse is installed
	mov	[(KeyboardType esi).MDisabled],TRUE	; disable mouse until the overlay is loaded

	; Set new Mouse position any way
	call	Clear_RM_regs
	mov	eax , 0300h
	mov	ebx , 033h
	mov	[RealInt . _eax ] , 4
	mov	[RealInt . _ecx] , ecx
	mov	[RealInt . _edx] , edx
	xor	ecx , ecx
	lea	edi, [RealInt]
	int	DPMI_INTR

	call	Clear_RM_regs
	mov	eax, 0300h
	mov	ebx ,33h				; mouse is in 33h
	mov	ecx,0					; any mouse condition generates int
	mov	edx,[RealModePtr]			; get real mode memory address
	shr	edx,4					; convert it to a segment
	mov	[RealInt. _es],dx			; store it in the real mode es
	movzx	edx,[(KeyboardType PTR esi).MouseCodeOffset] ; Get address of code
	mov	[RealInt._edx],edx			; set edx to offset of code
	mov	[RealInt._eax],12			; set eax to set interrupt routine
	mov	[RealInt._ecx],31
	lea	edi, [RealInt]
	int	DPMI_INTR

??installed:
	mov	eax,TRUE  				; return TRUE if all is well
	mov	[(KeyboardType esi).MDisabled],FALSE	; no 32 bit overlays installed
	je	??exit

??error:
	mov	eax,FALSE

??exit:
endif ;NOT_FOR_WIN95

	ret
	ENDP	Reset_Mouse



;***************************************************************************
;* REMOVE_MOUSE -- uninstalls the mouse interrupt by disabling the call	   *
;*                                                                         *
;* This routine will uninstall the mouse interrupt.  It does this by	   *
;* simply disabling the call condition.  The interrupt itself is still	   *
;* present, just uncalled until dos removes it at program termination.	   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:	VOID Remove_Mouse(VOID);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/29/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Remove_Mouse:NEAR
	PROC	Remove_Mouse C NEAR
	USES	eax,ebx,ecx,edx,esi,edi

ifdef NOT_FOR_WIN95
	call	Clear_RM_regs
	cmp 	[MInstalled],FALSE	; check to see if mouse installed
	je	??exit			; if not then no need to remove it

	mov	[MInstalled],FALSE	; Force to NOT-Installed.

;;PWG	cmp 	[_MSWIFTDevice],1	; check to see if SWIFT device installed
;;PWG	je	short ??prevSWIFT		; if so use previous SWIFT event handler

	mov	ebx , 033h
	mov	edx,[RealModePtr]			; get real mode memory address
	test	edx,edx					; check that the memory block is valid
	jz	??exit

	shr	edx,4					; convert it to a segment
	mov	[RealInt._es],dx			; store it in the real mode es
	xor	edx,edx
	mov	esi,[RealModePtr]			; get offset of real mode data start
	mov	dx,[(KeyboardType PTR esi).MouseCodeOffset] ; Get address of code
	mov	[RealInt._edx],edx			; set edx to offset of code
	mov	[RealInt._eax],12			; set eax to set interrupt routine
	mov	[RealInt._ecx],0
	mov	ecx,0					; no mouse condition generates an int
	mov	eax,0300h
	lea	edi,[RealInt]
	int	DPMI_INTR

	mov	eax,0601h				; function number.
	mov	ecx,[MouseCursor]			; ecx must have start of memory.
	mov	edi,[BufferSize]
	shl	edi,1
	shld	ebx,ecx,16
	shld	esi,edi,16
       	int	DPMI_INTR			; do call.


	; Deallocate real memory buffer
	mov	edx ,[MouseBufferSel]
	test	dx ,dx
	jz	??exit
	mov	eax ,0101h
	int	DPMI_INTR

??exit:
endif ;NOT_FOR_WIN95
	ret
	ENDP	Remove_Mouse


;***************************************************************************

GLOBAL C	Clear_RM_regs :NEAR
PROC	Clear_RM_regs  NEAR
ifdef NOT_FOR_WIN95
	push	eax
	push	ecx
	push	edi
	lea	edi , [ RealInt ]
	lea	ecx , [ RealInt . nothing ]
	sub	ecx , edi
	xor	eax , eax
	shr	ecx , 2
	rep	stosd
	pop	edi
	pop	ecx
	pop	eax
endif; NOT_FOR_WIN95
	ret
ENDP	Clear_RM_regs


;***************************************************************************
;* GET_MOUSE_X -- Returns the mouses x pixel position                      *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      int - the mouse x position in pixels			   *
;*                                                                         *
;* WARNINGS:    int Get_Mouse_X(void);                                     *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/29/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Get_Mouse_X:NEAR
	PROC	Get_Mouse_X C NEAR
	USES	esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]
	mov	eax,[(KeyboardType esi).MouseX]
endif;NOT_FOR_WIN95
	ret

	ENDP	Get_Mouse_X

;***************************************************************************
;* GET_MOUSE_STATE -- Returns the current mouse state			   *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      int - the mouse's current state				   *
;*                                                                         *
;* WARNINGS:    int Get_Mouse_State(void);                                 *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/29/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Get_Mouse_State:NEAR
	PROC	Get_Mouse_State C NEAR
	USES	esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]
	mov	eax,[(KeyboardType esi).MState]
endif;ifdef NOT_FOR_WIN95
	ret

	ENDP	Get_Mouse_State

;***************************************************************************
;* GET_MOUSE_X -- Returns the mouses x pixel position                      *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      int - the mouse x position in pixels			   *
;*                                                                         *
;* WARNINGS:    int Get_Mouse_X(void);                                     *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/29/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Get_Mouse_Disabled:NEAR
	PROC	Get_Mouse_Disabled C NEAR
	USES	esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]
	movzx	eax,[(KeyboardType esi).MDisabled]
endif; NOT_FOR_WIN95
	ret

	ENDP	Get_Mouse_Disabled

;***************************************************************************
;* GET_MOUSE_Y -- Returns the mouse's y pixel position                     *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:       none							   *
;*                                                                         *
;* OUTPUT:      int - the mouses y position in pixels                      *
;*                                                                         *
;* PROTO:	int Get_Mouse_Y(void);					   *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/29/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Get_Mouse_Y:NEAR
	PROC	Get_Mouse_Y C NEAR
	USES	esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]
	mov	eax,[(KeyboardType esi).MouseY]
endif; NOT_FOR_WIN95
	ret

	ENDP	Get_Mouse_Y

;***************************************************************************
;* GET_MOUSE_BUTTON -- Gets the values of the mouse button                 *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   09/19/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Get_Mouse_Button:NEAR
	PROC	Get_Mouse_Button C NEAR
	USES	eax,esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]
	xor	eax,eax
	mov	al,[(KeyboardType esi).Button]
endif; NOT_FOR_WIN95
	ret

	ENDP	Get_Mouse_Button

;***************************************************************************
;* SET_MOUSE_CURSOR -- Sets the shape to be used as the mouse.             *
;*                                                                         *
;*    This will inform the system of the shape desired as the mouse        *
;*    cursor.                                                              *
;*                                                                         *
;* INPUT:    xhotspot    -- Offset of click point into shape.              *
;*                                                                         *
;*           yhotspot    -- Offset of click point into shape.              *
;*                                                                         *
;*           cursor      -- Shape to use as the new mouse shape.           *
;*                                                                         *
;* OUTPUT:   Returns with a pointer to the original mouse shape.           *
;*                                                                         *
;* PROTO:	VOID  *Set_Mouse_Cursor(	int  xhotspot, 		   *
;*						int  yhotspot, 		   *
;*						void *cursor);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   02/13/1992 JLB : Created.                                             *
;*=========================================================================*
	GLOBAL C	Set_Mouse_Cursor:NEAR
	PROC	Set_Mouse_Cursor C NEAR
	USES	ebx,ecx,edx,esi,edi

	ARG	xhotspot:DWORD				; the x hot spot of the mouse
	ARG	yhotspot:DWORD				; the y hot spot of the mouse
	ARG	cursor:DWORD				; ptr to the new mouse cursor

	LOCAL	datasize:DWORD
	LOCAL	stype:WORD
	LOCAL	swidth:DWORD		; Shape width.
	LOCAL	sheight:DWORD		; Shape height.
	LOCAL	ssize:DWORD		; Size of raw shape.
ifdef NOT_FOR_WIN95
	;*=========================================================================*
	; Direction flag must be forward in this routine.
	;*=========================================================================*
	cld
	mov	esi,[RealModePtr]			; get offset of real mode data start

	;-------------------------------------------------------------------
	; Make sure the mouse is Enabled and Installed before continuing
	;-------------------------------------------------------------------
	mov	eax,[cursor]
	cmp	eax,0			; if the mouse cursor is in zero page
	je	??exit			; it is completely invalid

	cmp	eax,[PrevMousePtr]
	je 	??exit

	cmp	[(KeyboardType esi).MDisabled],FALSE	; make sure the mouse is not disabled
	jne	??exit			; if it is not then give it a try

	;-------------------------------------------------------------------
	; We need to wait if a mouse interrupt is in progress.  Once the
	; interrupt is finished flag that it is occuring so that it will
	; not attempt to draw the mouse while we are changing the cursor.
	;-------------------------------------------------------------------
??try:
	inc	[(KeyboardType esi).MouseUpdate] ; flag that mouse can not be drawn

	;-------------------------------------------------------------------
	; If the mouse is currently on the screen hide it.
	;-------------------------------------------------------------------
	call	Low_Hide_Mouse

	;-------------------------------------------------------------------
	; Calculate the size of the buffer needed.
	;-------------------------------------------------------------------
	push	[cursor]
	call	Get_Shape_Uncomp_Size
	pop	edx
	mov	[datasize],eax

	push	[cursor]
	call	Get_Shape_Width
	pop	edx
	mov	[swidth],eax
	cmp	eax,[BufferWidth]
	jg	??end

	push	[cursor]
	call	Get_Shape_Original_Height
	pop	edx
	mov	[sheight],eax
	cmp	eax,[BufferHeight]
	jg	??end


	mov	ebx,[sheight]
	mov	eax,[swidth]
	imul	ebx,eax

??copy_mouse:
	mov	esi,[cursor]			; set esi to point to mouse shape
	mov	ax,[esi]			; get the shape type byte
	mov	[stype],ax			; save off the shape type
	test	ax,MAKESHAPE_NOCOMP		; is it marked as no compression?
	je	??comp_shape			; if not go to the comped shape code
	mov	edi,[MouseCursor]		; set edi to point to mouse buffer
??copy_type:

	test	[stype],MAKESHAPE_COMPACT	; if the shape a 16 color shape?
	jne	??16_color_copy			; if it is then go handle it

??normal_copy:
	;-------------------------------------------------------------------
	;* Uncompressed NORMAL shapes just get run-length uncompressed
	;-------------------------------------------------------------------
	add	esi,10				; adjust past header of shape
	mov	eax,[swidth]			; load up the width
	mul	[sheight]				; find size of shape in pixels
	mov	edx,eax				; save this in number of bytes
	xor	ecx,ecx				; clear high of loop variable
??norm_unrle:
	mov	al,[esi]			; get a byte out of the file
	inc	esi				; increment to the next pos
	or	al,al				; set the flags on register state
	jz	??norm_trans			; if its a zero its transparent
	mov	[edi],al			; write out the pixel to dest
	inc	edi				; move to next dest position
	dec	edx				; we have now written another pix
	jnz	??norm_unrle			; if more to write then do it
	jmp	??done_copy			; otherwise we are all done

??norm_trans:
	mov	cl,[esi]			; get how many zeros to write
	sub	edx,ecx
	inc	esi				; increment the source position
	xor	al,al				; clear out al cuz we're writing zeros
	rep	stosb				; write all of them out
	or	edx,edx
	jnz	??norm_unrle			; if more to do then do it
	jmp	??done_copy			; otherwise we are done

??16_color_copy:
	;-------------------------------------------------------------------
	;* Uncompressed 16 color shapes just get remaped and UN-RLE'd
	;-------------------------------------------------------------------
	add	esi,10				; adjust past header of shape
	mov	ebx,esi				; save of position of remap
	add	esi,16				; move past remap table
	mov	eax,[swidth]			; load up the width
	mul	[sheight]			; load up the height
	mov	edx,eax				; save this in number of bytes
	xor	eax,eax				; clear high of lookup variable
	xor	ecx,ecx				; clear high of loop variable
??16_color_unrle:
	mov	al,[esi]			; get a byte out of the file
	inc	esi				; increment to the next pos
	or	al,al				; set the flags on register state
	jz	??16_color_trans		; if its a zero its transparent
	mov	al,[ebx+eax]			; remap the pixel from 16 color table
	mov	[edi],al			; store it out to the dest address
	inc	edi				; move to next dest address
	dec	edx				; we have now written a pixel
	jnz	??16_color_unrle
	jmp	??done_copy
??16_color_trans:
	mov	cl,[esi]			; get how many zeros to write
	sub	edx,ecx				; subtract off count ahead of time
	inc	esi				; increment the source position
	xor	al,al				; clear out al cuz we're writing zeros
	rep	stosb				; write all of them out
	or	edx,edx				; or edx to test for zero
	jnz	??16_color_unrle
	jmp	??done_copy

	;-------------------------------------------------------------------
	; Deal with the compressed shape by copying it into the shape
	;   staging buffer.
	;-------------------------------------------------------------------
??comp_shape:
	mov	edi,[_ShapeBuffer]	; get a pointer to ShapeBuffer
	mov	ax,[esi]		; load in the shape type
	add	esi,2			; increment the shape pointer
	or	ax,MAKESHAPE_NOCOMP	; make the shape as uncompressed
	mov	[stype],ax		; save off the shape type
	mov	[edi],ax		; write out uncompressed shape
	add	edi,2

	;-------------------------------------------------------------------
	; Process the shape header information and copy it over to the new
	;   location.
	;-------------------------------------------------------------------
	mov	ecx,4 			; transfer height, width, org and
	test	eax,MAKESHAPE_COMPACT	; is it a 16 color shape?
	je	??copy_head		; no - don't worry about it
	add	ecx,8			; otherwise adjust ecx for header
??copy_head:
	rep	movsw			; copy the necessary bytes

	mov 	eax,[datasize]		; get uncompressed length
	push	eax			; push as third param
	push	edi			; push the destination offset
	push	esi			; push the source offset
	call	LCW_Uncompress		; do the uncompress
	pop	eax
	pop	eax
	pop	eax
	mov	esi,[_ShapeBuffer]
	mov	edi,[MouseCursor]		; set edi to point to mouse buffer
	jmp	??copy_type

??done_copy:
	mov	esi,[RealModePtr]	; get offset of real mode data start

	mov	eax,[xhotspot]		; get the mouse cursors x hotspot
	mov	[(KeyboardType esi).MouseXHot],eax
	mov	eax,[yhotspot]		; get the mouse cursors y hotspot
	mov	[(KeyboardType esi).MouseYHot],eax

	mov	ebx,[sheight]		; get shape height
	mov	[(KeyboardType esi).MouseHeight],ebx
	mov	ebx,[swidth]
	mov	[(KeyboardType esi).MouseWidth],ebx

??error:
	call	Low_Show_Mouse

	;-------------------------------------------------------------------
	; Final cleanup and exit.
	;-------------------------------------------------------------------
??end:
	dec	[(KeyboardType esi).MouseUpdate]		; we are done modifying the cursor
??exit:
	push	[cursor]
	push	[PrevMousePtr]
	pop	eax
	pop	[PrevMousePtr]
endif; NOT_FOR_WIN95
	ret				; and return back to the world

	ENDP	Set_Mouse_Cursor


;***************************************************************************
;* LOW_HIDE_MOUSE -- Low-level routine which hides the mouse		   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    none                                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   09/19/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C Low_Hide_Mouse:NEAR
	PROC	Low_Hide_Mouse C NEAR
	USES	eax,ebx,esi
ifdef NOT_FOR_WIN95
	mov	ebx,[RealModePtr]			; get 32 bit offset of dos data

	;*=========================================================================*
	;* Is the mouse disabled or hidden?
	;*=========================================================================*
	cmp	[(KeyboardType ebx).MDisabled],0 	; is the mouse disabled?
	jne	short ??end

   	cmp	[(KeyboardType ebx).MState],0 	; is the mouse hidden?
	jne	short ??endnodraw			; no need to hide again

	;*=========================================================================*
	;* Take care of restoring the mouse cursor
	;*=========================================================================*
	mov	eax,RESTORE_VISIBLE_PAGE
	push	eax
	call	[ Mouse_Shadow_Buffer]
	pop	eax
	;*=========================================================================*
	;* The mouse is now hidden -- again.
	;*=========================================================================*
??endnodraw:
	add	[(KeyboardType ebx).MState],1
	adc	[(KeyboardType ebx).MState],0

??end:
endif; NOT_FOR_WIN95
	ret
	ENDP	Low_Hide_Mouse

;***************************************************************************
;* LOW_SHOW_MOUSE -- Low level routine which shows the mouse		   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    none                                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   09/19/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C Low_Show_Mouse:NEAR
	PROC	Low_Show_Mouse C NEAR
	USES	eax,ebx,ecx,edx,edi,esi
	LOCAL	mousex:DWORD
	LOCAL	mousey:DWORD
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]			; get offset of real mode data start

	;*=========================================================================*
	;* Don't show the mouse if it is not hidden or it is disabled
	;*=========================================================================*
	cmp	[(KeyboardType esi).MDisabled],0	; is the mouse disabled
	jne	??exit					; if so then exit

	cmp	[(KeyboardType esi).MState],0	; is the mouse already visible
       	je	??exit					; if so then exit

	;*=========================================================================*
	;* Don't show the mouse if it was hidden multiple times
	;*=========================================================================*
	dec	[(KeyboardType esi).MState]		; show the mouse one level
	cmp	[(KeyboardType esi).MState],0	; can the mouse be shown
       	jne	short ??exit

	;*=========================================================================*
	;* Determine the theoretcial drawing position of the mouse
	;*=========================================================================*
	mov	ecx,[(KeyboardType esi).MouseWidth]		; Theoretical buffer width (pixel).
	mov	edx,[(KeyboardType esi).MouseHeight]	; Theoretical buffer height (pixel).
	mov	eax,[(KeyboardType esi).MouseX]
	mov	[mousex],eax		; Draw X pixel.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	ebx,[(KeyboardType esi).MouseY]
	mov	[mousey],ebx		; Draw Y pixel.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;*=========================================================================*
	;* Determine the theoretical coordinates and dimensions of the
	;*	area the mouse shape will be rendered upon.
	;*=========================================================================*
	mov	[(KeyboardType esi).MouseBuffX],eax
	mov	[(KeyboardType esi).MouseBuffY],ebx
	mov	[(KeyboardType esi).MouseBuffW],ecx
	mov	[(KeyboardType esi).MouseBuffH],edx

;------	Move the area that will be drawn upon, to the graphic buffer.
	mov	eax,STORE_VISIBLE_PAGE
	push	eax
	call	[ Mouse_Shadow_Buffer ]
	pop	eax

;------	Draw the mouse shape to the seenpage.
	push	[mousey]
	push	[mousex]
	call	[ Draw_Mouse ]
	pop	eax
	pop	eax
??exit:
endif; NOT_FOR_WIN95
	ret
	ENDP	Low_Show_Mouse

;***************************************************************************
;* HIDE_MOUSE -- Hides mouse cursor on screen if it was show               *
;*                                                                         *
;* INPUT:	none							   *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:       void Hide_Mouse(void);					   *
;*                                                                         *
;* HISTORY:                                                                *
;*   11/03/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Hide_Mouse:NEAR
	PROC	Hide_Mouse C NEAR
	USES	eax,esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]			; get the real mode offset

	;*=========================================================================*
	;* Mark us as updating the mouse and then run and do the update
	;*=========================================================================*
	inc	[(KeyboardType esi).MouseUpdate]	; were drawing the mouse
	call	Low_Hide_Mouse				; make the function call
	dec	[(KeyboardType esi).MouseUpdate]	; were done drawing mouse
endif; NOT_FOR_WIN95
	ret

	ENDP	Hide_Mouse

;----------------------------------------------------------------------------


;***************************************************************************
;* SHOW_MOUSE -- Display mouse cursor on screen if it was hidden           *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:       void Show_Mouse(void)                                      *
;*                                                                         *
;* HISTORY:                                                                *
;*   11/03/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Show_Mouse:NEAR
	PROC	Show_Mouse C NEAR
	USES	eax,esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]			; get the real mode offset

	;*=========================================================================*
	;* Mark us as updating the mouse and then run and do the update
	;*=========================================================================*
	inc	[(KeyboardType esi).MouseUpdate]	; were drawing the mouse
	call	Low_Show_Mouse				; make the function call
	dec	[(KeyboardType esi).MouseUpdate]	; were done drawing mouse
endif;ifdef NOT_FOR_WIN95
	ret
	ENDP	Show_Mouse

;***************************************************************************
;* CONDITIONAL_HIDE_MOUSE -- Hides mouse if its with given region          *
;*                                                                         *
;* INPUT:	int sx_pixel - the left-most pixel position of the region  *
;*		int sy_pixel - the upper-most pixel position of the region *
;*		int dx_pixel - the right most pixel position of the region *
;*		int dy_pixel - the lower most pixel position of the region *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:       void Conditional_Hide_Mouse(	int sx_pixel, 		   *
;*						int sy_pixel,		   *
;*						int dx_pixel,		   *
;*						int dy_pixel);		   *
;*                                                                         *
;* HISTORY:                                                                *
;*   11/03/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Conditional_Hide_Mouse:NEAR
	PROC	Conditional_Hide_Mouse C NEAR
	USES	eax,ebx,ecx,edx,esi,edi

	ARG	sx_pixel:DWORD				; left x pixel pos
	ARG     sy_pixel:DWORD				; upper y pixel pos
	ARG	dx_pixel:DWORD				; right x pixel pos
	ARG	dy_pixel:DWORD				; lower y pixel pos
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]			; get the real mode offset

	;*=========================================================================*
	;* Widen region leftward by amount mouse shape spills to the right of
	;* its hot point.  Limited to the left edge of the screen.
	;*=========================================================================*
	mov	eax,[(KeyboardType esi).MouseWidth]
	sub	eax,[(KeyboardType esi).MouseXHot]
	neg	eax
	add	eax,[sx_pixel]
	jns	short ??noleftlimit
	xor	eax,eax
??noleftlimit:
	;*=========================================================================*
	;* Widen region upward by amount mouse shape spills below the
	;* mouse's hot point.  Limited by the top edge of the screen.
	;*=========================================================================*
	mov	ebx,[(KeyboardType esi).MouseHeight]
	sub	ebx,[(KeyboardType esi).MouseYHot]
	neg	ebx
	add	ebx,[sy_pixel]
	jns	short ??notoplimit
	xor	ebx,ebx
??notoplimit:
	;*=========================================================================*
	;* Widen region rightward by amount mouse shape spills to the
	;* left of its hot point.  Limited by the right edge of the
	;* screen.
	;*=========================================================================*
	mov	ecx,[dx_pixel]
	add	ecx,[(KeyboardType esi).MouseXHot]
	cmp	ecx,[(KeyboardType esi).MouseRight]
	jb	short ??norightlimit
	mov	ecx,[(KeyboardType esi).MouseRight]
	dec	ecx
??norightlimit:
	;*=========================================================================*
	;* Widen region downward by amout the mouse shape extends above
	;* its hot point.  Limited to the bottom of the screen.
	;*=========================================================================*
	mov	edx,[dy_pixel]
	add	edx,[(KeyboardType esi).MouseYHot]
	cmp	edx,[(KeyboardType esi).MouseBottom]
	jb	short ??nobottomlimit
	mov	edx,[(KeyboardType esi).MouseBottom]
	dec	edx

??nobottomlimit:
	inc	[(KeyboardType esi).MouseUpdate]		; don't let interrupt scrag variables

	;*=========================================================================*
	;* The mouse could be in one of four conditions.
	;* 1) The mouse is visible and no conditional hide has been specified.
	;* 	(perform normal region checking with possible hide)
	;* 2) The mouse is hidden and no conditional hide as been specified.
	;* 	(record region and do nothing)
	;* 3) The mouse is visible and a conditional region has been specified
	;* 	(expand region and perform check with possible hide).
	;* 4) The mouse is already hidden by a previous conditional.
	;* 	(expand region and do nothing)
	;*
	;* First: Set or expand the region according to the specified parameters
	;*=========================================================================*
	cmp	[(KeyboardType esi).MCState],0
	jne	short ??expand
	mov	[(KeyboardType esi).MouseCXLeft],eax
	mov	[(KeyboardType esi).MouseCYUpper],ebx
	mov	[(KeyboardType esi).MouseCXRight],ecx
	mov	[(KeyboardType esi).MouseCYLower],edx
	jmp	??noylower
??expand:

	;*=========================================================================*
	;* Expand the clipping rectangle.
	;*=========================================================================*
	cmp	eax,[(KeyboardType esi).MouseCXLeft]
	jb	short ??noxleft
	mov	[(KeyboardType esi).MouseCXLeft],eax
??noxleft:
	cmp	ebx,[(KeyboardType esi).MouseCYUpper]
	jb	short ??noyupper
	mov	[(KeyboardType esi).MouseCYUpper],ebx
??noyupper:
	cmp	ecx,[(KeyboardType esi).MouseCXRight]
	ja	short ??noxright
	mov	[(KeyboardType esi).MouseCXRight],ecx
??noxright:
	cmp	edx,[(KeyboardType esi).MouseCYLower]
	ja	short ??noylower
	mov	[(KeyboardType esi).MouseCYLower],edx
??noylower:
	;*=========================================================================*
	;* If the mouse isn't already hidden, then check its location against
	;* the hiding region and hide if necessary.
	;*=========================================================================*
	test	[(KeyboardType esi).MCState],CONDHIDDEN
	jne	short ??nohide

	mov	eax,[(KeyboardType esi).MouseX]
	mov	ebx,[(KeyboardType esi).MouseY]
	cmp	eax,[(KeyboardType esi).MouseCXLeft]
	jb	short ??nohide
	cmp	eax,[(KeyboardType esi).MouseCXRight]
	ja	short ??nohide
	cmp	ebx,[(KeyboardType esi).MouseCYUpper]
	jb	short ??nohide
	cmp	ebx,[(KeyboardType esi).MouseCYLower]
	ja	short ??nohide

	;*=========================================================================*
	;* The mouse falls within the region for hiding, so hide it.
	;*=========================================================================*

	call	Low_Hide_Mouse				; make the function call
	or	[(KeyboardType esi).MCState],CONDHIDDEN
??nohide:

	;*=========================================================================*
	;* Record the fact that a Conditional_Hide_Mouse was
	;* called and then exit.
	;*=========================================================================*
	or	[(KeyboardType esi).MCState],CONDHIDE
	add	[BYTE PTR (KeyboardType esi).MCState],1
	adc	[BYTE PTR (KeyboardType esi).MCState],0
	dec	[(KeyboardType esi).MouseUpdate]
endif; NOT_FOR_WIN95
	ret

	ENDP	Conditional_Hide_Mouse

;***************************************************************************
;* CONDITIONAL_SHOW_MOUSE -- shows mouse if it was conditionally hidden    *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* PROTO:       void Conditional_Show_Mouse(void);                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   11/03/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	Conditional_Show_Mouse:NEAR
	PROC	Conditional_Show_Mouse C NEAR
	USES	eax,esi
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]    ; get the real mode offset

	;*=========================================================================*
	; Notify the interrupt that we are updating the mouse
	;*=========================================================================*
	inc	[(KeyboardType esi).MouseUpdate]

	mov	ax,[(KeyboardType esi).MCState]
	cmp	al,0
	je	short ??exit			; if no more nesting clear cond

	;*=========================================================================*
	;* Decrement the conditional hide counter.
	;*=========================================================================*
	dec	al

	;*=========================================================================*
	;* If there are more conditional levels to undo, then just abort the show.
	;*=========================================================================*
	jne	short ??exit

	;*=========================================================================*
	;* Yup, the mouse should be show, but only if it was previously hidden.
	;*=========================================================================*
	test	ax,CONDHIDDEN			; was it hidden by interrupt??
	je	short ??exit1			; or initial check for level 0

	call	Low_Show_Mouse

??exit1:
	mov	ax,0

??exit:
	mov	[(KeyboardType esi).MCState],ax
	dec	[(KeyboardType esi).MouseUpdate]
endif;ifdef NOT_FOR_WIN95
	ret
	ENDP	Conditional_Show_Mouse



;***************************************************************************
;***************************************************************************
;***************************************************************************

;***************************************************************************
;* MOUSE_SHADOW_BUFFER -- Handles storing and restoring the mouse buffer   *
;*                                                                         *
;* INPUT:	int store - indicates whether we are storing the buffer or *
;*			    not.					   *
;*                                                                         *
;* OUTPUT:	none                                                       *
;*                                                                         *
;* PROTO:       Asm callable only!                                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   10/27/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C VGA_Mouse_Shadow_Buffer:NEAR
	PROC	VGA_Mouse_Shadow_Buffer C NEAR
	USES	eax,ebx,ecx,edx,edi,esi
	ARG	store:DWORD

	local	x0 : dword
	local	y0 : dword
	local	x1 : dword
	local	y1 : dword
	local	buffx0 : dword
	local	buffy0 : dword
ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]			; get 32 bit offset of dos data

	;*=========================================================================*
	; Direction flag must be forward in this routine.
	;*=========================================================================*
	cld

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	eax,[(KeyboardType esi).MouseBuffX]
	mov	ebx,[(KeyboardType esi).MouseBuffY]
	sub	eax,[(KeyboardType esi).MouseXHot]
	sub	ebx,[(KeyboardType esi).MouseYHot]

	mov	[ x0 ] , eax
	mov	[ y0 ] , ebx
	add	eax,[(KeyboardType esi).MouseBuffW]
	add	ebx,[(KeyboardType esi).MouseBuffH]
	mov	[ x1 ] , eax
	mov	[ y1 ] , ebx

	mov	[ buffx0 ] , 0
	mov	eax , [ MouseBuffer ]
	mov	[ buffy0 ] , eax

	;*===================================================================
	;* Bounds check source X.
	;*===================================================================

	xor 	eax , eax
	xor 	edx , edx

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	sub	ecx , [(KeyboardType esi).MouseRight]
	sub	ebx , [(KeyboardType esi).MouseRight]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	sub	ecx , [(KeyboardType esi).MouseBottom]
	sub	ebx , [(KeyboardType esi).MouseBottom]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??not_clip

	test	ah , 1000b
	jz	??scr_left_ok
	mov	ebx , [ x0 ]
	neg	ebx
	mov	[ buffx0 ] , ebx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	mov	ebx , [ y0 ]
	neg	ebx
	imul	ebx , [(KeyboardType esi).MouseBuffW]
	add	[ buffy0 ] , ebx
	mov	[ y0 ] , 0

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	eax , [(KeyboardType esi).MouseRight]  ; get width into register
	mov	[ x1 ] , eax
??scr_right_ok:
	test	dl , 0001b
	jz	??not_clip
	mov	eax , [(KeyboardType esi).MouseBottom]  ; get width into register
	mov	[ y1 ] , eax

??not_clip:
	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================
	mov	eax , [ y0 ]
	mov	edx , [(KeyboardType esi).MouseRight]
	imul	eax , edx
	add	eax , [ x0 ]
	lea	edi , [ 0a0000h + eax ]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	ebx , [(KeyboardType esi).MouseBuffW]	; turn this into an offset
	mov	esi , [ buffy0 ]			; edx points to source
	add	esi , [ buffx0 ]					; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	eax , [ x1 ]
	mov	ecx , [ y1 ]
	sub	eax , [ x0 ]
	jle	??out
	sub	ecx , [ y0 ]
	jle	??out

	sub	edx , eax
	sub	ebx , eax
	push	ebp
	cmp	[store],RESTORE_VISIBLE_PAGE		; are we restoring page?
	jne	??store_entry				; if not the go to store
	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
	mov	ebp , ecx
??restore_loop:
	mov	ecx,eax					; get number to really write
	rep	movsb					; store them into the buffer
	add	esi,ebx				; move past right clipped pixels
	add	edi,edx					; adjust dest to next line
	dec	ebp					; decrement number of rows to do
	jnz	??restore_loop				; if more to do, do it
	pop	ebp
	ret

	;*===================================================================
	;* Handle soting the visible page into the Mouse Shadow Buffer
	;*===================================================================
??store_entry:
	xchg	esi,edi					; xchg the source and the dest
	mov	ebp , ecx
??store_loop:
	mov	ecx,eax					; get number to really write
	rep	movsb					; store them into the buffer
	add	esi,edx				; move past right clipped pixels
	add	edi,ebx					; adjust dest to next line
	dec	ebp					; decrement number of rows to do
	jnz	??store_loop				; if more to do, do it
	pop	ebp
??out:
endif;ifdef NOT_FOR_WIN95
	ret
	ENDP	VGA_Mouse_Shadow_Buffer

;***************************************************************************
;* DRAW_MOUSE -- Handles drawing the mouse cursor			   *
;*                                                                         *
;* INPUT:	none							   *
;*                                                                         *
;* OUTPUT:	none                                                       *
;*                                                                         *
;* PROTO:       Asm callable only!                                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   10/27/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	VGA_Draw_Mouse:NEAR
	PROC	VGA_Draw_Mouse C NEAR
	USES	eax,ebx,ecx,edx,edi,esi
	ARG	mousex:DWORD
	ARG	mousey:DWORD

	local	x0 : dword
	local	y0 : dword
	local	x1 : dword
	local	y1 : dword
	local	buffx0 : dword
	local	buffy0 : dword

ifdef NOT_FOR_WIN95
	mov	esi,[RealModePtr]    	; get 32 bit offset of dos data

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	eax,[mousex]
	mov	ebx,[mousey]
	sub	eax,[(KeyboardType esi).MouseXHot]
	sub	ebx,[(KeyboardType esi).MouseYHot]

	mov	[ x0 ] , eax
	mov	[ y0 ] , ebx
	add	eax,[(KeyboardType esi).MouseWidth]
	add	ebx,[(KeyboardType esi).MouseHeight]
	mov	[ x1 ] , eax
	mov	[ y1 ] , ebx

	mov	[ buffx0 ] , 0
	mov	eax , [ MouseCursor ]
	mov	[ buffy0 ] , eax


	;*===================================================================
	;* Bounds check source X. Y.
	;*===================================================================
	xor 	eax , eax
	xor 	edx , edx

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	sub	ecx , [(KeyboardType esi).MouseRight]
	sub	ebx , [(KeyboardType esi).MouseRight]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	sub	ecx , [(KeyboardType esi).MouseBottom]
	sub	ebx , [(KeyboardType esi).MouseBottom]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??not_clip

	test	ah , 1000b
	jz	??scr_left_ok
	mov	ebx , [ x0 ]
	neg	ebx
	mov	[ buffx0 ] , ebx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	mov	ebx , [ y0 ]
	neg	ebx
	imul	ebx , [(KeyboardType esi).MouseWidth]
	add	[ buffy0 ] , ebx
	mov	[ y0 ] , 0

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	eax , [(KeyboardType esi).MouseRight]  ; get width into register
	mov	[ x1 ] , eax
??scr_right_ok:
	test	dl , 0001b
	jz	??not_clip
	mov	eax , [(KeyboardType esi).MouseBottom]  ; get width into register
	mov	[ y1 ] , eax

??not_clip:

	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================
	mov	eax , [ y0 ]
	mov	edx , [(KeyboardType esi).MouseRight]
	imul	eax , edx
	add	eax , [ x0 ]
	lea	edi , [ 0a0000h + eax ]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	ebx , [(KeyboardType esi).MouseWidth]	; turn this into an offset
	mov	esi , [ buffy0 ]			; edx points to source
	add	esi , [ buffx0 ]					; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	eax , [ x1 ]
	mov	ecx , [ y1 ]
	sub	eax , [ x0 ]
	jle	??out
	sub	ecx , [ y0 ]
	jle	??out

	sub	edx , eax
	sub	ebx , eax

	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
??top_loop:
	mov	ah,al
??inner_loop:
	mov	ch ,[esi]
	inc	esi
	or	ch,ch
	jz	??inc_edi
	mov	[edi],ch
??inc_edi:
	inc	edi
	dec	ah
	jnz	??inner_loop
	add	esi,ebx				; move past right clipped pixels
	add	edi,edx				; adjust dest to next line
	dec	cl					; decrement number of rows to do
	jnz	??top_loop				; if more to do, do it
??out:
endif; NOT_FOR_WIN95
	ret

	ENDP	VGA_Draw_Mouse


;***************************************************************************
;***************************************************************************
;***************************************************************************

;***************************************************************************
;* MOUSE_SHADOW_BUFFER -- Handles storing and restoring the mouse buffer   *
;*                                                                         *
;* INPUT:	int store - indicates whether we are storing the buffer or *
;*			    not.					   *
;*                                                                         *
;* OUTPUT:	none                                                       *
;*                                                                         *
;* PROTO:       Asm callable only!                                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   10/27/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C VESA_Mouse_Shadow_Buffer:NEAR
	PROC	VESA_Mouse_Shadow_Buffer C NEAR
	USES	eax,ebx,ecx,edx,edi,esi
	ARG	store:DWORD

	local	x0 : dword
	local	y0 : dword
	local	x1 : dword
	local	y1 : dword
	local	buffx0 : dword
	local	buffy0 : dword
	local	vesa_linear : dword
ifdef NOT_FOR_WIN95
	mov	eax , [ cpu_video_page ]
	mov	[ vesa_linear ] ,  eax

	mov	esi,[RealModePtr]			; get 32 bit offset of dos data
	;*=========================================================================*
	; Direction flag must be forward in this routine.
	;*=========================================================================*

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	eax,[(KeyboardType esi).MouseBuffX]
	mov	ebx,[(KeyboardType esi).MouseBuffY]
	sub	eax,[(KeyboardType esi).MouseXHot]
	sub	ebx,[(KeyboardType esi).MouseYHot]


	mov	[ x0 ] , eax
	mov	[ y0 ] , ebx
	add	eax,[(KeyboardType esi).MouseBuffW]
	add	ebx,[(KeyboardType esi).MouseBuffH]
	mov	[ x1 ] , eax
	mov	[ y1 ] , ebx

	mov	[ buffx0 ] , 0
	mov	eax , [ MouseBuffer ]
	mov	[ buffy0 ] , eax

	;*===================================================================
	;* Bounds check source X.
	;*===================================================================

	xor 	eax , eax
	xor 	edx , edx

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	sub	ecx , [(KeyboardType esi).MouseRight]
	sub	ebx , [(KeyboardType esi).MouseRight]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	sub	ecx , [(KeyboardType esi).MouseBottom]
	sub	ebx , [(KeyboardType esi).MouseBottom]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??not_clip

	test	ah , 1000b
	jz	??scr_left_ok
	mov	ebx , [ x0 ]
	neg	ebx
	mov	[ buffx0 ] , ebx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	mov	ebx , [ y0 ]
	neg	ebx
	imul	ebx , [(KeyboardType esi).MouseBuffW]
	add	[ buffy0 ] , ebx
	mov	[ y0 ] , 0

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	eax , [(KeyboardType esi).MouseRight]  ; get width into register
	mov	[ x1 ] , eax
??scr_right_ok:
	test	dl , 0001b
	jz	??not_clip
	mov	eax , [(KeyboardType esi).MouseBottom]  ; get width into register
	mov	[ y1 ] , eax

??not_clip:
	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================
	mov	eax , [ y0 ]
	mov	edx , [(KeyboardType esi).MouseRight]
	imul	eax , edx
	add	eax , [ x0 ]
	lea	edi , [ 0a0000h + eax ]
	call	Vesa_Asm_Set_Win

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	ebx , [(KeyboardType esi).MouseBuffW]	; turn this into an offset
	mov	esi , [ buffy0 ]			; edx points to source
	add	esi , [ buffx0 ]					; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	eax , [ x1 ]
	mov	ecx , [ y1 ]
	sub	eax , [ x0 ]
	jle	??out
	sub	ecx , [ y0 ]
	jle	??out

	sub	edx , eax
	sub	ebx , eax

	cmp	[store],RESTORE_VISIBLE_PAGE		; are we restoring page?
	jne	??store_entry				; if not the go to store
	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================

	mov	[ tempreg ] , ebx
??restore__top_loop:
	mov	ah,al
??restore__inner_loop:
	mov	ch ,[esi]
	mov	[edi],ch
	inc	esi
	inc	edi
	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??restore__in_range
	add	edi , [ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??restore__in_range:
	dec	ah
	jnz	??restore__inner_loop
	add	esi,[ tempreg ]				; move past right clipped pixels
	add	edi,edx	   				; adjust dest to next line

	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??restore__in_range1
	add  	edi ,[ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??restore__in_range1:
	dec	cl					; decrement number of rows to do
	jnz	??restore__top_loop				; if more to do, do it
	jmp	??out					; get the heck outta the routine

	;*===================================================================
	;* Handle soting the visible page into the Mouse Shadow Buffer
	;*===================================================================
??store_entry:
	mov	[ tempreg ] , ebx
??store_top_loop:
	mov	ah,al
??store_inner_loop:
	mov	ch ,[edi]
	mov	[esi],ch
	inc	esi
	inc	edi
	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??store_in_range
	add  	edi ,[ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??store_in_range:
	dec	ah
	jnz	??store_inner_loop
	add	esi,[ tempreg ]				; move past right clipped pixels
	add	edi,edx	   				; adjust dest to next line

	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??store_in_range1
	add  	edi ,[ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??store_in_range1:
	dec	cl					; decrement number of rows to do
	jnz	??store_top_loop				; if more to do, do it

??out:
	mov	edi , [ vesa_linear ]
	add	edi , 0a0000h
	call	Vesa_Asm_Set_Win

endif; NOT_FOR_WIN95
	ret
	ENDP	VESA_Mouse_Shadow_Buffer

;***************************************************************************
;* DRAW_MOUSE -- Handles drawing the mouse cursor			   *
;*                                                                         *
;* INPUT:	none							   *
;*                                                                         *
;* OUTPUT:	none                                                       *
;*                                                                         *
;* PROTO:       Asm callable only!                                         *
;*                                                                         *
;* HISTORY:                                                                *
;*   10/27/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL C	VESA_Draw_Mouse:NEAR
	PROC	VESA_Draw_Mouse C NEAR
	USES	eax,ebx,ecx,edx,edi,esi
	ARG	mousex:DWORD
	ARG	mousey:DWORD

	local	x0 : dword
	local	y0 : dword
	local	x1 : dword
	local	y1 : dword
	local	buffx0 : dword
	local	buffy0 : dword
	local	tempreg : dword
	local	vesa_linear : dword
ifdef NOT_FOR_WIN95
	mov	eax , [ cpu_video_page ]
	mov	[ vesa_linear ] ,  eax

	mov	esi,[RealModePtr]    	; get 32 bit offset of dos data

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	eax,[mousex]
	mov	ebx,[mousey]
	sub	eax,[(KeyboardType esi).MouseXHot]
	sub	ebx,[(KeyboardType esi).MouseYHot]

	mov	[ x0 ] , eax
	mov	[ y0 ] , ebx
	add	eax,[(KeyboardType esi).MouseWidth]
	add	ebx,[(KeyboardType esi).MouseHeight]
	mov	[ x1 ] , eax
	mov	[ y1 ] , ebx

	mov	[ buffx0 ] , 0
	mov	eax , [ MouseCursor ]
	mov	[ buffy0 ] , eax


	;*===================================================================
	;* Bounds check source X. Y.
	;*===================================================================
	xor 	eax , eax
	xor 	edx , edx

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ x0 ]
	mov	ebx , [ x1 ]
	sub	ecx , [(KeyboardType esi).MouseRight]
	sub	ebx , [(KeyboardType esi).MouseRight]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	mov	ecx , [ y0 ]
	mov	ebx , [ y1 ]
	sub	ecx , [(KeyboardType esi).MouseBottom]
	sub	ebx , [(KeyboardType esi).MouseBottom]
	dec	ecx
	dec	ebx
	shld	eax , ecx , 1
	shld	edx , ebx , 1

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??not_clip

	test	ah , 1000b
	jz	??scr_left_ok
	mov	ebx , [ x0 ]
	neg	ebx
	mov	[ buffx0 ] , ebx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	mov	ebx , [ y0 ]
	neg	ebx
	imul	ebx , [(KeyboardType esi).MouseWidth]
	add	[ buffy0 ] , ebx
	mov	[ y0 ] , 0

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	eax , [(KeyboardType esi).MouseRight]  ; get width into register
	mov	[ x1 ] , eax
??scr_right_ok:
	test	dl , 0001b
	jz	??not_clip
	mov	eax , [(KeyboardType esi).MouseBottom]  ; get width into register
	mov	[ y1 ] , eax

??not_clip:

	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================
	mov	eax , [ y0 ]
	mov	edx , [(KeyboardType esi).MouseRight]
	imul	eax , edx
	add	eax , [ x0 ]
	lea	edi , [ 0a0000h + eax ]
	call	Vesa_Asm_Set_Win

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	ebx , [(KeyboardType esi).MouseWidth]	; turn this into an offset
	mov	esi , [ buffy0 ]			; edx points to source
	add	esi , [ buffx0 ]					; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	eax , [ x1 ]
	mov	ecx , [ y1 ]
	sub	eax , [ x0 ]
	jle	??out
	sub	ecx , [ y0 ]
	jle	??out

	sub	edx , eax
	sub	ebx , eax

	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
	mov	[ tempreg ] , ebx
??top_loop:
	mov	ah,al
??inner_loop:
	mov	ch ,[esi]
	inc	esi
	or	ch,ch
	jz	??inc_edi
	mov	[edi],ch
??inc_edi:
	inc	edi
	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??in_range
	add  	edi ,[ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??in_range:
	dec	ah
	jnz	??inner_loop
	add	esi,[ tempreg ]				; move past right clipped pixels
	add	edi,edx	   				; adjust dest to next line

	mov	ebx , edi
	add	ebx , [ cpu_video_page ]
	cmp	ebx , [ cpu_page_limit ]
	jl	??in_range1
	add  	edi ,[ cpu_video_page ]
	call	Vesa_Asm_Set_Win
 ??in_range1:
	dec	cl					; decrement number of rows to do
	jnz	??top_loop				; if more to do, do it

??out:
	mov	edi , [ vesa_linear ]
	add	edi , 0a0000h
	call	Vesa_Asm_Set_Win

endif; NOT_FOR_WIN95
	ret

	ENDP	VESA_Draw_Mouse


;----------------------------------------------------------------------------
END