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
;*				  (Mouse Routines)
;*                                                                         *
;*                    File Name : KEYIREAL.ASM                             *
;*                                                                         *
;*                   Programmer : Philip W. Gorrow                         *
;*                                                                         *
;*                   Start Date : May 21, 1992                             *
;*                                                                         *
;*                  Last Update : July 13, 1994   [PWG]                    *
;*                                                                         *
;* This file sort of breaks the standard of keeping all of the keyboard    *
;* and mouse routines isolated.  This is done because the mouse and	   *
;* the keyboard share data, and the best way to do this is to put	   *
;* them in the same segment.  This should probably be split into several   *
;* include files to help make the code clearer once it is finally put	   *
;* together.								   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   KeyNum_Translate -- Translates extended keynums to normal keynums	   *
;*   Stuff_Key_Word -- Stuffs a word of data into keyboard buffer          *
;*   Stuff_Key_Num -- Stuffs a key num code into the circular buffer       *
;*   Keystroke_Interrupt -- Real mode handler of input from the keyboard   *
;*   Break_Interrupt -- Handles the break key interrupt                    *
;*   Call_Interrupt_Chain -- Function PM calls to call RM interrupt chain  *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;*									   *
;*	Keyboard driver -- 8086 Assembly portion;			   *
;*	updated by: Phil Gorrow for 32 bit Protected Mode		   *
;***************************************************************************

;---------------------------------------------------------------------------
; Set the assembly directives
;---------------------------------------------------------------------------
IDEAL				; the product runs in ideal mode
P386N				; use 386 real mode instructions
MODEL TINY			; code must be tiny so it fits
LOCALS ??			; ?? is the symbol for a local
WARN				; generate all warnings we can
JUMPS				; optimize jumps if possible

;---------------------------------------------------------------------------
; Include all of the keyboard specific defines
;---------------------------------------------------------------------------
INCLUDE "keyboard.inc"

CONDHIDE		EQU	08000H		; bit for testing conditional region
CONDHIDDEN		EQU	04000H		; bit for testing conditional hidden
RESTORE_VISIBLE_PAGE	EQU	0
STORE_VISIBLE_PAGE	EQU	1


GLOBAL	set_vesa_page 	:near
GLOBAL	set_vesa_window :near
GLOBAL	get_vesa_window :near
GLOBAL	next_vesa_page	:near

ECHOON	equ 0
;---------------------------------------------------------------------------
; WARNING!!!!  All of the following code segment variables are shared by
;   the protected mode interrupt.  Do not change these unless you make the
;   proper changes to KEYSTRUC.INC.  If you do not know what you are doing,
;   find someone who does!!!
;---------------------------------------------------------------------------
CODESEG

;---------------------------------------------------------------------------
; Begin definition of Keyboard specific variables
;---------------------------------------------------------------------------
SoundOn		DW	1	; toggled by alt S
MusicOn		DW	1	; toggled by alt M
KeyFlags	DD	REPEATON+CTRLALTTURBO	; all but repeat for now


Break		DW	0

KeyMouseMove	DB	-1,0,1
		DB	-16,0,16

ScreenEdge	DW	320/2,0		; North
		DW	319,0		; North-East
		DW	319,138/2	; East
		DW	319,137		; South-East
		DW	320/2,137	; South
		DW	0,137		; South-West
		DW	0,138/2		; West
		DW	0,0		; North-West
		DW	320/2,138/2	; Center


Bits		DB	01H,02H,04H,08H,10H,20H,40H,80H

CondPassKey	DW	0220H, 0320H, 060CH, 070DH, 066AH
		DW	0669H, 0230H, 0330H, 007DH, 017DH
		DW	025AH, 035AH, 0200H, 0410H, 046EH
		DW	026EH, 007CH

CondPassCond	DW	CTRLSON, CTRLSON, CTRLALTTURBO, CTRLALTTURBO, CTRLALTTURBO
		DW	CTRLALTTURBO, CTRLCON, CTRLCON, SCROLLLOCKON, SCROLLLOCKON
		DW	PAUSEON, PAUSEON, BREAKON, TASKSWITCHABLE, TASKSWITCHABLE
		DW	TASKSWITCHABLE, BREAKON

EscRoutine	DD	0	; vector to execute on esc key press (0=none)

; Extended raw keycodes to be converted to Westwood keycodes.
ExtCodes	DB	038H,01DH,052H,053H,04BH,047H,04FH,048H,050H,049H
		DB	051H,04DH,035H,01CH,037H
		DB	046H
; The matching Westwood keycodes.
ExtNums		DB	62,  64,  75,  76,  79,  80,  81,  83,  84,  85
		DB	86,  89,  95, 108, 124,  0
; If extended mapping is disabled, then these codes really are...
ExtRemap	DB	60,  58,  99, 104,  92,  91,  93,  96,  98, 101
		DB	103, 102, 55,  43, 124,  0
ExtRemapEnd	DB	0

ExtKeyboard	DB	0	; flag for 101/102-key keyboard


KeyBuffer	DW	128 DUP(0) ; set to empty
KeyBufferHead	DD	0	; set to first entry
KeyBufferTail	DD	0	; set to head for empty buffer
KeyLock		DW	0	; num and caps lock bits
KeyNums		DB	127,110,002,003,004,005,006,007,008,009,010,011,012,013,015,016
		DB	017,018,019,020,021,022,023,024,025,026,027,028,043,058,031,032
		DB	033,034,035,036,037,038,039,040,041,001,044,029,046,047,048,049
		DB	050,051,052,053,054,055,057,100,060,061,030,112,113,114,115,116
		DB	117,118,119,120,121,090,125,091,096,101,105,092,097,102,106,093
		DB	098,103,099,104,127,127,127,122,123

KeysCapsLock	DB	0,0,0FEH,087H,0FFH,0C0H,01FH,0,0,0,0,0,0,0,0,0
KeysNumLock	DB	0,0,0,0,0,0,0,0,0,0,0,038H,0EFH,1,0,0
KeysUpDown	DB	16 DUP(0) ; set to all keys up
KeyStream	DB	16 DUP(0) ; set to all keys up
PassCount	DW	0
KeyStreamIndex	DW	0
LastKeyE0	DB	0
LastKeyE1	DB	0

;
; Westwood key number values of keys to pass through
;
;			CAPS, LEFT_SHIFT, RIGHT_SHIFT, LEFT_CTRL, LEFT_ALT,
;			RIGHT_ALT, RIGHT_CTRL, NUM_LOCK, UNKNOWN
PassAlways	DB	30, 44, 57, 58, 60, 62, 64, 90, 128, 128
PassAlwaysEnd	DB	128		; invalid code to END PassAlways
CtrlFlags	DB	0

Buffer		DW	?
Time		DW	?

ADJUST	= 1			; do not modify DRD

XYAdjust	DB	-ADJUST, -ADJUST	; 91 -> upleft
		DB	-ADJUST,  0		; 92 -> left
		DB	-ADJUST,  ADJUST	; 93 -> downleft
		DB	 0,  0			; 94 illegal
		DB	 0,  0			; 95 illegal
		DB	 0, -ADJUST		; 96 -> up
		DB	 0,  0			; 97 illegal (center)
		DB	 0,  ADJUST		; 98 -> down
		DB	 0,  0			; 99 illegal
		DB	 0,  0			; 100 illegal
		DB	 ADJUST, -ADJUST	; 101 -> upright
		DB	 ADJUST,  0		; 102 -> right
		DB	 ADJUST,  ADJUST	; 103 -> downright
	EdgeConv		DW	8,2,8,6,4,3,8,5,8,8,8,8,0,1,8,7
	MouseUpdate		DW	0
	MouseX			DW	0,0
	LocalMouseX		DW	0
	MouseY			DW	0,0
	LocalMouseY		DW	0
	IsExtKey		DB	0
	ExtIndex		DW	0

	KeyOldRMI		DD	0			; The origianl RM interrupt seg:off.
	KeyOldPMIOffset		DD	0			; The origianl PM interrupt offset
	KeyOldPMISelector	DD	0			; The original PM interrupt segment.

	KeyCodeOffset		DW	RM_Keystroke_Interrupt	; Offset of the code in the RM stuff.
	CallKeyRMIntOffset	DW	Call_Interrupt_Chain	; Offset of function to call DOS timer interrupt.
	CallKeyRMIntAddr	DD	0			; PM address of CallRealIntOffset for speed.
	PMIssuedKeyInt		DD	0

	BrkOldRMI		DD	0			; The origianl RM interrupt seg:off.
	BrkOldPMIOffset		DD	0			; The origianl PM interrupt offset
	BrkOldPMISelector	DD	0			; The original PM interrupt segment.

	BrkCodeOffset		DW	RM_Break_Interrupt	; Offset of the code in the RM stuff.
	CallBrkRMIntOffset	DW	0
	CallBrkRMIntAddr	DD	0			; PM address of CallRealIntOffset for speed.
	PMIssuedBrkInt		DD	0
	KeyIntDisabled		DD	0

	DbgOldPMIOffset		DD	0	; The origianl PM interrupt offset
	DbgOldPMISelector	DD	0	; The original PM interrupt segment.

;---------------------------------------------------------------------------
; Begin definition of Mouse Specific Variables for real mode
;---------------------------------------------------------------------------
Button			DB	0	; current value of the mouse button
MDisabled		DB	0	; Is the mouse driver disabled
MInput			DB	1	; Defaults to mouse input allowed.
Adjust			DW	0	; flag to adjust coordinates if necessary
MouseStepX		DW	0	; step values if the mouse moves at
MouseStepY		DW	0	;   more than one pixel at a time
MouseOffsetX		DW	0	; Fractional step values used if a mouse
MouseOffsetY		DW	0	;   moves at less than one pixel at a time
MState			DW	0,0	; Tracks if mouse is hidden (TRUE) or not (FALSE)
MouseXOld     		DW	0	; Holds last MouseX and MouseY to determine if
MouseYOld     		DW	0	;   mouse needs to be redrawn
MCState			DW	0	; Tracks if mouse conditional hidden (TRUE) or not
MouseCXLeft		DW	0,0	; Conditional hide mouse left x position
MouseCYUpper		DW	0,0	; Conditional hide mouse top y position
MouseCXRight		DW	0,0	; Conditional hide mouse right x position
MouseCYLower		DW	0,0	; Conditional hide mouse lower y position
MouseCursor   		DD	0	; Pointer to the mouse cursor to draw
MouseCursorSize		DW	0	; Pointer to buffer mouse is saved in
MouseBuffer   		DD	0	; Pointer to buffer mouse is saved in
MouseXHot     		DW	0,0	; Offset to mouse's x hot spot
MouseYHot     		DW	0,0	; Offset to mouse's y hot spot
MouseBuffX		DW	0,0	; X position background was saved at
MouseBuffY		DW	0,0	; Y position background was saved at
MouseBuffW		DW	0,0	; Width of the region saved for mouse
MouseBuffH		DW	0,0	; Height of the region saved for mouse
MouseWidth		DW	0,0	; Mouse cursor theoretical width
MouseHeight		DW	0,0	; Mouse cursor theoretical height
MouseCodeOffset		DW	RM_Mouse_Interrupt	; Offset of the code in the RM stuff.
MouseRight		DW	0,0
MouseBottom		DW	0,0


ShadowPtr		dw	0
DrawMousePtr 		dw	0

VGAMouseDraw		dw	VGA_Draw_Mouse
VGAMouseShadow		dw	VGA_Mouse_Shadow_Buffer

VESAMouseDraw		dw	VESA_Draw_Mouse
VESAMouseShadow		dw	VESA_Mouse_Shadow_Buffer

VesaPtr			dd	0
banktable		dd      8 dup ( 0 )
Adjust_XPos		dw 	0 , 0
Adjust_YPos		dw 	0 , 0

		align 2
Keyboard_App_Stack_ES	dw 0		; This the System Stack Offsset
Keyboard_App_Stack_SS	dw 0		; This the System Stack Selector
Keyboard_StackPointer	dw 0DEADh	; We Create a Local Application
Keyboard_Stack		dw 512 dup (0)
Keyboard_StackStart	dw 0

Mouse_State		dw 0		; Mouse Temp Variable
Mouse_Cond		dw 0		; Mouse Temp Variable
Mouse_App_Stack_ES	dw 0		; This the System Stack Offsset
Mouse_App_Stack_SS	dw 0		; This the System Stack Selector
Mouse_StackPointer	dw 0DEADh	; We Create a Local Application
Mouse_Stack		dw 512 dup (0)
Mouse_StackStart	dw 0



current_page		dw	0
;***************************************************************************
;* KEYNUM_TRANSLATE -- Translates extended keynums to normal keynums	   *
;*                                                                         *
;* INPUT:	UWORD the keynum to translate				   *
;*                                                                         *
;* OUTPUT:	WORD the translated keynum                                 *
;*                                                                         *
;* PROTO:	UWORD KeyNum_Translate(UWORD keynum);			   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	KeyNum_Translate:FAR
	PROC	KeyNum_Translate C FAR
	USES	cx,di,es,ds
	ARG	keycode:WORD

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds
	mov	es,ax				; set es up for scansb

	mov	ax,[keycode]
	test	[WORD PTR KeyFlags],TRACKEXT
	jne 	short ??fini

	mov	cx,ExtRemap-ExtNums
	mov	di,OFFSET ExtNums

	repne	scasb
	jcxz	short ??fini			; No match found.

	mov	di,OFFSET ExtRemapEnd
	dec	di
	sub	di,cx
	mov	al,[es:di]
??fini:
	ret
	ENDP	KeyNum_Translate

;***************************************************************************
;* STUFF_KEY_WORD -- Stuffs a word of data into keyboard buffer            *
;*                                                                         *
;* INPUT:	WORD the code to stick into the circular buffer            *
;*                                                                         *
;* OUTPUT:      WORD !=0 is sucessful, ==0 is not enough room		   *
;*                                                                         *
;* PROTO:	VOID Stuff_Key_WORD(WORD code);				   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C Stuff_Key_WORD:FAR
	PROC	Stuff_Key_WORD C FAR
	USES	si,bx,ds
	ARG	code:WORD

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	mov	ax,[WORD PTR KeyBufferTail]
	mov	si,ax
	add	ax,2
	and	ax,0FFh				; New KeyBufferTail value.
	cmp	[WORD PTR KeyBufferHead],ax
	je 	short ??noroom

	mov	bx,[code]
	mov	[KeyBuffer+si],bx		; Record the keystroke.
	mov	[WORD PTR KeyBufferTail],ax
	xor	ax,ax
	ret

??noroom:
	mov	ax,1
	ret

	ENDP	Stuff_Key_WORD

;***************************************************************************
;* STUFF_KEY_NUM -- Stuffs a key num code into the circular buffer         *
;*                                                                         *
;* INPUT:	WORD the keycode to stuff                                  *
;*                                                                         *
;* OUTPUT:      WORD !=0 is sucessful, ==0 is not enough room		   *
;*                                                                         *
;* PROTO:	VOID Stuff_Key_Num(WORD keynum);			   *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/11/1994 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	C Stuff_Key_Num:FAR
	PROC	Stuff_Key_Num C FAR
	USES	bx,cx,dx,di,si,ds
	ARG	keycode:WORD
	LOCAL	tail:WORD		; Original keybuffer tail (safety copy).
	LOCAL	size:WORD		; Size of write.

	pushf
	cli				; disable interrupts

	; Abort key recognition if in record mode and unable
	; to output key due to simultaneous DOS operation.
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds


	; Record the mouse position to be stuffed into buffer.
	mov	ax,[MouseX]
	mov	[LocalMouseX],ax
	mov	ax,[MouseY]
	mov	[LocalMouseY],ax

??cando:
	mov	ax,[keycode]		; get the code
	or	ax,ax			; Null keycodes are not recorded.
	jne	short ??validkey
	jmp	??exit


??validkey:

	test	[WORD PTR KeyFlags],KEYMOUSE	; is the numeric keypad moving the mouse?
	je	??no_pad_move

	; ALT-cursor keys are undefined.  Pass them on to the program.
	test	ah,ALTPRESS		; is either alt key down?
	jne	??no_pad_move

	test	[WORD PTR KeyFlags],SIMLBUTTON	; are we simulating left mouse presses
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
	or	[Button],1		; Left mouse bit.
	test	ah,KEYRELEASE
	je	??mousefake
	and	[Button],NOT 1
	jmp	??mousefake

??regular:
	cmp	al,KN_DELETE
	jne	short ??regular2
	mov	al,KN_RMOUSE
	or	[Button],2		; Right mouse bit.
	test	ah,KEYRELEASE
	je	??mousefake
	and	[Button],NOT 2
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
	sub	al,KN_UPLEFT		; get a number between 0 and 12
	mov	bx,ax
	shl	bx,1			; double for WORD index
	add	bx,OFFSET XYAdjust
	mov	ax,[bx]			; get x,y add value

	mov	bl,ah
	cbw
	xchg	ax,bx
	cbw
	xchg	ax,bx			; AX = mouse x delta, BX = mouse y delta

	; DRD correction to use ch
	; The CTRL key moves the mouse to the edge of the screen.
	test	ch,CTRLPRESS		; is either ctrl key down?
	jne	short ??ctrlon		; if so, ctrl is on

	; DRD correction to use ch
	; use fast speed of the mouse move if the shift key is held down.
	mov	dx,1			; for slow speed
	test	ch,SHIFTPRESS		; is either shift key down?
	je	short ??normspeed	; if not then neither shift is down
??doublespeed:
	add	dx,3			; for fast speed
??normspeed:
	add	bx,dx			; add speed for y index
	mov	bl,[KeyMouseMove+bx] 	; get speed for y delta
	xchg	ax,bx			; swap with ax to extend sign
	cbw
	xchg	ax,bx
	xchg	bx,dx			; save mouse y delta
	add	bx,ax			; add speed for x index
	mov	al,[KeyMouseMove+bx]	; get speed for x delta
	cbw
	xchg	bx,dx			; restore mouse y delta

	jmp	short ??ctrloff

??ctrlon:

	; Table lookup method for determining hotkey positions for CTRL
	; cursor combination.  This algorithm is hard coded for an ADJUST
	; value of 3.  If this value changed, then this section will also
	; have to be modified.
	and	bx,011b			; Y = 1, 0, 3
	and	ax,011b			; X = 1, 0, 3
	; Table lookup method for determining hotkey positions for CTRL
	; cursor combination.  This algorithm is hard coded.
					;    -1, 0, 1
	and	bx,011b			; Y = 3, 0, 1
	and	ax,011b			; X = 3, 0, 1
	shl	bx,1
	shl	bx,1
	or	bx,ax			; Lookup index.

	; Convert raw index into logical (clockwise) index.
	shl	bx,1
	mov	bx,[EdgeConv+bx]
	shl	bx,1
	shl	bx,1
	mov	ax,[ScreenEdge+bx]	; New absolute X
	mov	bx,[ScreenEdge+bx+2] ; New absolute Y
	mov	[LocalMouseX],ax
	mov	[LocalMouseY],bx

??set_xyz:
	mov	ax,[LocalMouseX]	; get new mouse x,y
	mov	bx,[LocalMouseY]
	jmp	short ??set_xy

	; Process a normal faked mouse move.
??ctrloff:
	; DRD change
	add	[LocalMouseX],ax	; save it in our local
	jns	short ??not_negative_x
	xor	ax,ax
	mov	[LocalMouseX],ax	; clear our local

??not_negative_x:
; DRD change
	add	[LocalMouseY],bx	; save it in our local
	jns	short ??not_negative_y
	xor	bx,bx
	mov	[LocalMouseY],bx	; clear our local

??not_negative_y:
	mov	ax,[LocalMouseX]	; get new mouse x,y
	mov	bx,[LocalMouseY]
	cmp	ax,MAX_X_PIXEL		; bigger than
	jle	short ??check_y
	mov	ax,MAX_X_PIXEL

??check_y:
	cmp	bx,MAX_Y_PIXEL		; bigger than
	jle	short ??set_xy
	mov	bx,MAX_Y_PIXEL

??set_xy:
	mov	[LocalMouseX],ax
	mov	[LocalMouseY],bx
	mov	[MouseX],ax
	mov	[MouseY],bx
	cmp	[MouseUpdate],0	; wait until mouse interrupt is done
	jne	short ??noshow

	call	Low_Hide_Mouse
	call	Low_Show_Mouse
??noshow:
	mov	ax,KN_MOUSE_MOVE
??mousefake:
	mov	[keycode],ax		; Fake a MOUSE_MOVE event.

??no_pad_move:
	; Fetch working pointers to the keyboard ends.
	mov	si,[WORD KeyBufferTail]
	mov	[tail],si		; Safety record.
	mov	di,[WORD PTR KeyBufferHead]

	; Record the base keycode (if there is room).
	push	ax
	call	Stuff_Key_WORD
	add	sp,2
	or	ax,ax
	jne	short ??jmpnoroom

	; Also record the mouse coordinates if necessary.
	mov	ax,[keycode]		; get key code
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
	push	[LocalMouseX]
	call	Stuff_Key_WORD
	add	sp,2
	or	ax,ax
	jne	??jmpnoroom
	add	[size],2

	; Record mouse coordinate Y.
	push	[LocalMouseY]
	call	Stuff_Key_WORD
	add	sp,2
	or	ax,ax
	jne	??jmpnoroom
	add	[size],2

??ok:
	; If PASSBREAKS is not active and this is a keyboard
	; break AND it is not a mouse event, then don't put
	; it into the buffer.
	mov	bx,0101h		; Bit control tools.
	mov	ax,[keycode]
	cmp	al,KN_MOUSE_MOVE
	je 	short ??notreal
	cmp	al,127
	je	short ??notreal
	test	ah,KEYRELEASE
	je	short ??real
	xor	bl,bl
	test	[WORD PTR KeyFlags],PASSBREAKS
	jne 	short ??real
	cmp	al,KN_LMOUSE
	je 	short ??real
	cmp	al,KN_RMOUSE
	je 	short ??real
??notreal:
	mov	[WORD PTR KeyBufferTail],si	; Nullify any KeyBufferTail changes.
??real:

	; Update the KeysUpDown bit array.
	mov	di,ax
	and	di,07Fh
	mov	cl,3
	shr	di,cl			; DI = Byte offset into bit table.
	mov	cl,al
	and	cl,0111b		; CL = Bit offset into bit table byte.
	shl	bx,cl
	not	bh

	; If this is a reapeat key and the key is already being held
	; down, then don't stuff it into the keyboard buffer.
	test	bl,[KeysUpDown+di]
	je	short ??notalready
	test	[WORD PTR KeyFlags],REPEATON
	jne	short ??notalready
	mov	[WORD PTR KeyBufferTail],si	; Nullify any KeyBufferTail changes.
??notalready:
	and	[KeysUpDown+di],bh	; Force key bit to zero.
	or	[KeysUpDown+di],bl	; Insert key bit as appropriate.
;??notreal:

	; Successful keybuffer stuff could result in a
??norecord:
	mov	ax,1
	jmp short ??exit

	; Unsuccessful keybuffer stuff.
??noroom:
	mov	ax,[tail]
	mov	[WORD PTR KeyBufferTail],ax
	xor	ax,ax			; Signal an error.

??exit:
	popf
	ret

	ENDP	Stuff_Key_Num
;***********************************************************



;***************************************************************************
;* KEYSTROKE_INTERRUPT -- Handles input that comes from the keyboard       *
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
label RM_Keystroke_Interrupt
	GLOBAL	C Keystroke_Interrupt:FAR
	PROC	Keystroke_Interrupt C FAR

IF 0
	push	ax
	inc	ax
	pop	ax
	iret

ELSE
	push	ax
	push	bx
	push	cx
	push	di
	push	ds
	push	dx
	push	es
	push	si
	cld

	mov	ax,cs			; set ds to cs to avoid cs overide
	mov	ds,ax

	; At this point we do not know if the SS selector is a
 	; System Stack or the Application Stack pointer.
	; Soo to be in the safe side we create our own local
	; Stack Pointer	Selector Relative to DS
	; Note Do not try this trick in a reentrant interrupt
	mov cx, ss				; get SS
	mov [Keyboard_App_Stack_ES], sp		; Protect ES
	mov [Keyboard_App_Stack_SS], cx		; Protect SS
	lea dx, [Keyboard_StackStart ]		; Compute Local Stack size
	and dx, -2;
	cli					; Disable All interrupts
	mov ss, ax				; Set new SS Selector
	mov sp, dx				; Set new Stack Offset
	sti					; Enable Interrupts

	cmp	[WORD PTR PMIssuedKeyInt],0; Check to see if PM made Int call.
	mov	[WORD PTR PMIssuedKeyInt],0; Make it false.
	jne	??passcode	; if so, just call Int Chain.


	mov	dx,[WORD PTR KeyFlags]
	;*** The following fix allows proper caps and num lock tracking on Tandy
	; 10-6-89 LJC, DRD

	and	[KeyLock],NOT (NUMLOCK OR CAPSLOCK); assume caps and num inactive
	mov	ax,040H			; BIOS segment
	mov	es,ax			; put in es
	test	[BYTE PTR es:017H],040H	; test Caps lock bit in BIOS
	je	short ??bioscapsoff	; skip activate code
	or	[KeyLock],CAPSLOCK	; Caps Lock active

??bioscapsoff:
	test	[BYTE PTR es:017H],020H	; test Num lock bit in BIOS
	je	short ??biosnumoff	; skip activate code
	or	[KeyLock],NUMLOCK 	; Num Lock active

??biosnumoff:
	mov	[ExtKeyboard],TRUE 	; assume 101/102-key keyboard
	test	[BYTE PTR es:096H],010H	; test for 101/102-key keyboard
	jne	short ??extkeyboard	; skip deactivate code
	mov	[ExtKeyboard],FALSE 	; no 101/102-key keyboard

??extkeyboard:
	mov	ax,cs			; set ds to cs to avoid cs overide
	mov	es,ax

	cld				; clear direction flag for strings
	xor	ah,ah			; clear ctrl flags to 0
	mov	bx,0101H		; set key to a make by default
	in	al,KEYDATA		; get a code from the keyboard

	;
	; New CODE to montior key stream
	;
	mov	bx,[KeyStreamIndex]
	mov	[KeyStream+bx],al
	inc	bx
	and	bx,15
	mov	[KeyStreamIndex],bx
	mov	bx,0101H		; set key to a make by default
	;
	; END OF SEQUENCE
	;

	;
	; Handle the PAUSE key being pressed.  If it is pressed, then
	; signal that the next two input codes are to be thrown out.
	;
	cmp	al,0E1H			; see if this is a pause/break
	jne	short ??notpcode	; not a pause/break start code
	mov	[LastKeyE1],3		; absorb this and next two codes

??notpcode:
	cmp	[LastKeyE1],0		; are we in a pause/break code
	je	short ??notpause	; no, just keep going
	dec	[LastKeyE1]		; yes, dec the count
	test	dx,PAUSEON		; should it pass these codes
	jne 	??passcode		; pass the code
	jmp	??absorbcode		; don't pass code

??notpause:
	;
	; Record any extended key codes that arrive.  They will be
	; taken into account with the next code.
	;
	cmp	al,0E0H			; is it an extended code
	jne	short ??notextcode	; if not skip to handle key
	mov	[LastKeyE0],TRUE	; set the extended code to 1
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
	cmp	[LastKeyE0],FALSE	; was the prev byte an E0?
	je 	short ??normal		; if not it is a normal key
	mov	[LastKeyE0],FALSE	; if so clear for next read
	mov	[IsExtKey],TRUE	; it is an extended key
	mov	di,OFFSET ExtCodes	; get offset of extended codes table
	mov	cx,(ExtNums-ExtCodes)	; get number of entrys in ext table
	repne	scasb			; look for a match
	jcxz	??absorbcode		; Not recognized, so throw it away.
	mov	al,[(ExtNums - ExtCodes) - 1 + di] ; get the match
	mov	[IsExtKey],FALSE	; it is not an extended key
	jmp 	short ??notext

??normal:
	cmp	al,07Ah
	jne	short ??normok
	mov	al,128
	jmp	short ??notext
??normok:
	mov	di,ax			; use code as an index
	and	di,007Fh		; Mask off any release bit.
	mov	al,[KeyNums+di]		; get the key number of this key

??notext:
	;
	; Test and set the CTRL bit.
	;
	test	[KeysUpDown+8],001H	; is the right ctrl down?
	jne	short ??ctrlon		; if so, ctrl is on
	test	[KeysUpDown+7],004H	; is the left ctrl down?
	je	short ??ctrloff		; if not, neither are down, no ctrl

	; DRD
	; check for CTRL-NUMLOCK for pause on some keyboards

	cmp	al,KN_NUMLOCK		; check for CTRL-NUMLOCK
	jne	short ??ctrlon

	cmp	[ExtKeyboard],TRUE	; if 101/102-key keyboard it is ok
	je	short ??ctrlon

	test	dx,PAUSEON		; should it pass these codes
	jne	short ??ctrlon		; pass the code

	jmp	??absorbcode		; don't pass code

??ctrlon:
	or	ah,CTRLPRESS		; or on the ctrl bit in flags

??ctrloff:
	;
	; Test and set the ALT bit.
	;
	test	[KeysUpDown + 7],050H	; is either alt key down?
	je	short ??altoff
	or	ah,ALTPRESS		; or on the alt bit in flags

??altoff:
	;
	; Remap the keyboard keys if this is requested. (Do not set DGROUP
	;   as it is unecessary)
	push	ax
	call	KeyNum_Translate
	add	sp,2

;------	Set the shift bit if necessary.
	test	[KeysUpDown+5],010H	; is the left shift down?
	jne	short ??shifton		; if so the shift is on
	test	[KeysUpDown+7],002H	; is the right shift down?
	je	short ??shiftoff	; if not then neither shift is down

??shifton:
	or	ah,SHIFTPRESS		; or on the shift bit in flags

??shiftoff:
	;
	;------	Toggle the shift state if the caps lock key is on (if necessary).
	;
	mov	di,ax
	and	di,07Fh
	shr	di,1
	shr	di,1
	shr	di,1
	mov	bx,ax
	and	bx,07Fh
	and	bl,0111b
	mov	ch,[Bits+bx]		; get the bit to test
	test	[KeyLock],CAPSLOCK	; is the caps lock on?
	je	short ??capsoff		; if not don't worry about it
	test	ch,[KeysCapsLock+di]	; get code for keycaps
	je	short ??capsoff		; its not effected
	xor	ah,SHIFTPRESS		; toggle the shift flag

??capsoff:
	;
	;------	Toggle the shift state if the num-lock key is on (if necessary).
	;
	test	[KeyLock],NUMLOCK	; is the num lock key on?
	je	short ??numlockoff	; if not don't worry about it
	test	ch,[KeysNumLock+di]	; get code for numlock
	je	short ??numlockoff	; if not effected skip toggle
	xor	ah,SHIFTPRESS		; toggle the shift flag if effected

??numlockoff:
;------ Remember the current control/shift/alt bit settings for later use.

;??noshiftever:
	mov	[CtrlFlags],ah		; save off shift-ctrl-alt flags
					; for the mouse and joystick routines
					; to use in stuffing key into the
					; keyboard buffer.
	test	dx,DEBUGINT
	jz	??not_toggle


IF DEBUG
	cmp	[KeyIntDisabled],1
	jne	??not_currently_disabled
	cmp	ax,115			; is it the F4 key
	je	??disable
	cmp	ax,118			; is it less then F7 key
	jb	??justpass
	cmp	ax,120			; is it greater than F9 key
	ja	??justpass
??disable:
	mov	[KeyIntDisabled],0
??justpass:
	jmp	??passcode

??not_currently_disabled:
	cmp	ax,125
	jne	??not_toggle
	mov	[KeyIntDisabled],1
	jmp	??absorbcode
ENDIF

??not_toggle:

;------	The CTRL-ALT-DEL key combination always gets passed to the system.
	cmp	ax,0668H		; is it ctrl alt del?
	je	??passcode
	cmp	ax,064CH		; is it ctrl alt ext del?
	je	??passcode	; if so don't add it to the buffer

;------ Special Ctrl-C check.
	cmp	ax,0230h
	je	short ??breaker
	cmp	ax,027Eh
	jne	short ??nobreak
??breaker:
	mov	[Break],1

??nobreak:
;------	Check for Music and Sound control keys.
	cmp	ax,0420H		; is this an alt s
	jne	short ??checkmusic	; toggle the Sound variable
	push	ax
	mov	ax,[SoundOn]
	xor	ax,01H
	push	ax
	add	sp,2
	pop	ax

??checkmusic:
	cmp	ax,0434H		; is this an alt m
	jne	short ??esc		; toggle the Music variable
	push	ax
	mov	ax,[MusicOn]
	xor	ax,01H
	push	ax
	add	sp,2
	pop	ax

??esc:

	push	ax
	call	Stuff_Key_Num
	pop	ax
??skipstuff:

;------	Do the special ESC routine if necessary.
	cmp	al,110			; is this the esc key?
	jne	short ??noroutine	; if not goto the pass always
	cmp	[WORD PTR EscRoutine+2],0 ;if vector is 0 don't jump
	je	short ??noroutine
	push	ax
	call	[EscRoutine]
	pop	ax

??noroutine:
;------	Check to see if the key is to be passed to the system or not.
	mov	di,OFFSET PassAlways	; get offset to table
	mov	cx,(PassAlwaysEnd - PassAlways) ; get number of pass always CDY JLB MOD 7/11 was +1
	repne	scasb			; look for a match
	or	cx,cx			; see if there was no match
	jne	??passcode	; CDY JLB 7/11 optimization




??passalways:
	; now check for conditional passes
	mov	di,OFFSET CondPassKey	; get offset to cond key table
	mov	cx,(CondPassCond-CondPassKey) ; get number of entries
	shr	cx,1			; cut in half for words
	repne	scasw			; look for a match
	jcxz	short ??notcondpass	; OPTIMIZATION CDY JLB
	mov	bx,[(CondPassCond - CondPassKey) - 2 + di]
	and	bx,dx			; are the conditions met?
	je	short ??notcondpass	; NO... check normally.
	jmp	short ??passcode	; YES... pass back to system.
;
;------	Last check before passing keycode back to the system.
;
??notcondpass:
	test	dx,FILTERONLY		; is the filter only flag on?
	je	short ??absorbcode	; if not, absorb the code.

??passcode:

	inc	[cs:PassCount]

;mov   ax , 0B000h
;mov   es, ax
;inc   [BYTE PTR es : 40h]

	; Now it is time to set up for the call to the System Keyboard
	; interrupt handler.
	; 1 -Restore System Stack Pointer Selector before exit Interrupt
	; 2- We Create a Returning Point from Interrupt by Push A
 	;    Interupt Stack Frame into the Stack Pointer
	; 3- We make a Far jump to the interuupt handler
	cmp [Keyboard_StackPointer],0DEADh
	je  ??stackok
	push cx
	push di
	push ax
	push es
	mov  ax,0A000h
	mov  es,ax
	xor  di,di
	mov  cx,64000
	mov  ax,1
	rep  stosb
	pop  es
	pop  ax
	pop  di
	pop  cx
??stackok:
	cli				       ; disable Interrupts
	mov dx, [Keyboard_App_Stack_SS]
	mov ss, dx			       ; Get System Stack Selector
	mov sp, [Keyboard_App_Stack_ES]      ; Get System Stack offset
	sti				       ; Enable Interrupts

	lea	dx, [??Call_Back_Keyboard]   ; Get Return address offset
 	pushf				      ; push flags
	push	cs			      ; push Code segment
	push	dx			      ; push Offset

	; Now we need to simulate an interrup call by using ired
	; because we still want to come back here from the
	; Old Keyboard interrupt handle.
	pushf
	push	[word ptr KeyOldRMI + 2] 	; push orig segment.
	push    [word ptr KeyOldRMI]   		; push orig offset.
	iret	 		        	; call interrupt

??absorbcode:

;mov   ax , 0B000h
;mov   es, ax
;inc   [BYTE PTR es : 0h]

	in	al,KEYCTRL			; get the control port
	mov	ah,al
	or	al,080H				; reset bit for keyboard
	out	KEYCTRL,al
	xchg	ah,al				; get orig control data
	out	KEYCTRL,al			; restore control data

	mov	ax,040h				; BIOS paragraph is always @ 040h
	mov	es,ax				; put in es as BIOS paragraph
	mov	al,[es:96h]			; get extended keys
	and	al,0FDh				; turn off last key e0 flag
	mov	[es:96h],al			; set extended keys

	mov	al,CLEARISR			; value to clear In Service Register
	out	INTCHIP0,al			; 8259 interrupt chip controller 0

	cmp [Keyboard_StackPointer],0DEADh
	je  ??stackok2
	push cx
	push di
	push ax
	push es
	mov  ax,0A000h
	mov  es,ax
	xor  di,di
	mov  cx,64000
	mov  ax,1
	rep  stosb
	pop  es
	pop  ax
	pop  di
	pop  cx
??stackok2:

	; Restore System Stack Pointer Selector before exit Interrupt
	mov dx, [Keyboard_App_Stack_SS]
	cli				       ; disable Interrupts
	mov ss, dx			       ; Get Syatem Stack Selector
	mov sp, [Keyboard_App_Stack_ES]        ; Get Syatem Stack offset
	sti				       ; Enable Interrupts

??Call_Back_Keyboard:
	pop	si
	pop	es
	pop	dx
	pop	ds
	pop	di
	pop	cx
	pop	bx
	pop	ax
	iret
ENDIF

	ENDP	Keystroke_Interrupt

;***************************************************************************
;* Break interrupt routines begin here!
;***************************************************************************

;***************************************************************************
;* BREAK_INTERRUPT -- Handles the break key interrupt                      *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* WARNINGS:    This is an interrupt routine.                              *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/13/1994 PWG : Created.                                             *
;*=========================================================================*
label RM_Break_Interrupt
	GLOBAL	C Break_Interrupt:FAR
	PROC	Break_Interrupt C FAR


	pushf
	push	ax
	push	es

	mov	ax,0B000h		; ES:DI = Mono RAM address.
	mov	es,ax
	inc	[BYTE PTR es:0]


	pop	es
	pop	ax
	popf


	iret

	ENDP	Break_Interrupt

;**************************************************************************
;* CALL_INTERRUPT_CHAIN -- Function PM calls to call the RM interrupt chain*
;*                                                                         *
;*                                                                         *
;* INPUT:	none                                                                  *
;*                                                                         *
;* OUTPUT:      none                                                       *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/08/1994 SKB : Created.                                             *
;*=========================================================================*
Call_Interrupt_Chain:
	pushf
	call	Keystroke_Interrupt ;[KeyOldRMI]
	retf

;----------------------------------------------------------------------------
; LOW_HIDE_MOUSE:
;
; This function hides the mouse cursor on the screen if it was shown.  It
; will not hide the mouse if it is already hidden.
;
; PROTOTYPE:
;
;	VOID Low_Hide_Mouse(VOID);
;
; NOTE: does not check if mouse is currently being updated.
;
;----------------------------------------------------------------------------

 	GLOBAL	C Low_Hide_Mouse:FAR
	PROC	Low_Hide_Mouse C FAR
	USES	ax,bx,cx,dx,ds

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

   	cmp	[MDisabled],0		; check if mouse is disabled
	jne	short ??end

   	cmp	[MState],0		; check if it was hidden before
	jne	short ??endnodraw		; no need to hide again

;------	Move the saved graphic buffer to the seenpage to hide the mouse.
;	call	Buffer_To_Page C,[buffx],[buffy],[buffw],[buffh],[MouseBuffer],SEENPAGE
	mov	ax,RESTORE_VISIBLE_PAGE
	push	ax
	push	cs
	call	[ ShadowPtr ]
	add	sp,2

;------	Record that the mouse has been hidden.
??endnodraw:
	add	[MState],1
	adc	[MState],0

??end:
	ret

	ENDP	Low_Hide_Mouse

;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; LOW_SHOW_MOUSE:
;
; This function displays the mouse cursor on the screen if it was hidden.
;
; PROTOTYPE:
;	VOID Low_Show_Mouse(VOID);
;
; NOTE: does not check if mouse is currently being updated.
;----------------------------------------------------------------------------

 	GLOBAL	C Low_Show_Mouse:FAR
	PROC	Low_Show_Mouse C FAR
	USES 	ax,bx,cx,dx,si,di,ds,es
	LOCAL	mousex:WORD		; Draw X position.
	LOCAL	mousey:WORD		; Draw Y position.

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

;-----	Don't show the mouse if it is not hidden, disabled.
	cmp	[MDisabled],0		; is the mouse disabled
	jne	??exit			; if so then exit

	cmp	[MState],0		; is the mouse already visible
       	je	??exit			; if so then exit

	dec	[MState]
	cmp	[MState],0		; can the mouse be shown
       	jne	short ??exit

;------	Determine the drawing position of the mouse.
	mov	cx,[MouseWidth]		; Theoretical buffer width (pixel).
	mov	dx,[MouseHeight]	; Theoretical buffer height (pixel).

	mov	ax,[MouseX]
;	sub	ax,[MouseXHot]
	mov	[mousex],ax		; Draw X pixel.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF 0
;	jns	short ??xnotneg
;	add	cx,ax			; Reduce width accordingly.
;	mov	ax,0
??xnotneg:
ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov	bx,[MouseY]
;	sub	bx,[MouseYHot]
	mov	[mousey],bx		; Draw Y pixel.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF 0
;	jns	short ??ynotneg
;	add	dx,bx			; Reduce height of mouse accordingly.
;	mov	bx,0
??ynotneg:
ENDIF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;------	Determine the theoretical coordinates and dimensions of the
;	area the mouse shape will be rendered upon.
	mov	[MouseBuffX],ax
	mov	[MouseBuffY],bx
	mov	[MouseBuffW],cx
	mov	[MouseBuffH],dx

;------	Move the area that will be drawn upon, to the graphic buffer.
	mov	ax,STORE_VISIBLE_PAGE
	push	ax
	push	cs
	call	[ ShadowPtr ]
	add	sp,2

;------	Draw the mouse shape to the seenpage.
	push	[mousey]
	push	[mousex]
	push	cs
	call	[ DrawMousePtr ]
	add	sp,4
??exit:
	ret

	ENDP	Low_Show_Mouse

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
	GLOBAL	C Mouse_KeyNum:FAR
	PROC	Mouse_KeyNum C FAR
	USES	bx
	ARG	state:WORD		; Current mouse state.
	LOCAL	keynum:WORD		; Determined keynum.

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	mov	[keynum],KN_MOUSE_MOVE	; Presume just a mouse move.
	mov	bx,[state]
	mov	ax,bx
	xor	bl,[Button]		; Bits of state change.
	je	short ??fini
	mov	[Button],al		; Record new mouse state.

	test	bl,0010b
	je	short ??notright
	mov	[keynum],KN_RMOUSE
	test	al,0010b
	jne	short ??notright
	or	[keynum],0800h		; Release bit on.
??notright:

; DRD
; note:  the left mouse button has priority over the right mouse button
; this should be changed at a later date to process them independently

	test	bl,0001b
	je	short ??notleft
	mov	[keynum],KN_LMOUSE
	test	al,0001b
	jne	short ??notleft
	or	[keynum],0800h		; Release bit on.
??notleft:

??fini:
	mov	ax,[keynum]
	ret

	ENDP	Mouse_KeyNum

;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; MOUSE_INT:
;
; This routine is called automatically when the Mouse_Int is installed.  It
; automatically updates the global variables stored in the code segment so
; that the mouse information is automatically known at all times.
;
; INPUTS (from int):	AX = condition mask ( bit 0 == cursor position chg,
;					      bit 1 == left button press,
;					      bit 2 == left button release,
;					      bit 3 == right button press,
;					      bit 4 == right button release,
;					      5-15  == not used )
;			BX = button state   ( bit 0 == left button down,
;					      bit 1 == right button down,
;                                             bit 2 == middle button down.
;					      3-15  == not used )
;			CX = cursor coordinate (horizontal axis)
;			DX = cursor coordinate (vertical axis)
;			DI = horizontal mouse count (mickeys)
;			SI = vertical mouse count (mickeys)
;
; RETURNS:		none
;
; MODIFIES:		modifies the variables _Button, _ButtonChange,
;			_MouseX,_MouseY,_ButtonLatch
;
; PROTOTYPE:
;	This routine is called from an interrupt.
;----------------------------------------------------------------------------
label RM_Mouse_Interrupt
	PROC	Mouse_Int C FAR
	USES	ax,bx,cx,dx,ds,si,es,di
	LOCAL	cond:WORD		; Local copy of mouse event.
	LOCAL	state:WORD		; Local copy of button state.

	mov	[cs:Mouse_State],bx
	mov	[cs:Mouse_Cond],ax

	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	; At this point we do not know if the SS selector is a
 	; System Stack or the Application Stack pointer.
	; Soo to be in the safe side we create our own local
	; Stack Pointer	Selector Relative to DS
	; Note Do not try this trick in a reentrant interrupt
	mov bx, ss				; get SS
	mov [Mouse_App_Stack_ES], sp		; Protect ES
	mov [Mouse_App_Stack_SS], bx		; Protect SS
	lea bx, [Mouse_StackStart ]	; Compute Local Stack size
	and bx, -2;
	cli					; Disable All interrupts
	mov ss, ax				; Set new SS Selector
	mov sp, bx				; Set new Stack Offset
	sti					; Enable Interrupts



	push ax
	push dx

	mov 	dx,3c8h
	xor	al,al
	out	dx,al
	inc	dx
	out	dx,al

	mov	dx,3c9h
	mov	ax,cx
	shr	ax,3
	out	dx,al
	jmp	??j1
??j1:	xor	al,al
	out	dx,al
	jmp	??j2
??j2:	out	dx,al
	jmp	??j3
??j3:

	pop	dx
	pop	ax



;------	Process the mouse interrupt only if the mouse is enabled (whether
;	present or not).
	cmp	[MDisabled],0
	jne	??exit

	cmp	[MInput],0
	je	??exit


;------ This was added because of missing mouse presses and
;	releases during a mouse update.
	mov	ax,[Mouse_Cond]
	and	ax,0001EH 	; bits for left and right press and release
	jne	short ??dopress_release

	cmp	[MouseUpdate],0 ; if mouse move and mouse updating exit
	jne	??exit

??dopress_release:

;------	In EEGA mode mouse X coordinates as 0..639.  Make adjustment
;	to keep within 0..319 range.
	cmp	[Adjust],1		; if the x coordinate is returned
	jne	short ??noadjust	; incorrectly then
	shr	cx,1			; adjust x coord from 640 pixel screen
??noadjust:


; scale mouse posX and PosY
;	cmp	[Adjust_XPos] , 0
;	jz	short ??no_scaleX
;	push	dx
;	mov	ax , [MouseRight]
;	imul	cx
;	idiv	[Adjust_XPos]
;	mov	cx , ax
;	pop	dx
??no_scaleX:
;	cmp	[Adjust_YPos] , 0
;	jz	short ??no_scaleY
;	mov	ax , [MouseBottom]
;	imul	dx
;	idiv	[Adjust_YPos]
;	mov	dx , ax
??no_scaleY:

;------	Keep mouse within screen bounds.
	cmp	cx,[MouseRight]			; in EGAMODE, the mouse may go to 320
	jb	short ??boundX_ok		; force it to stay at least one pixel
	mov	cx,[MouseRight]			; on the screen
	dec	cx
??boundX_ok:
	cmp	dx,[MouseBottom]			; in EGAMODE, the mouse may go to 320
	jb	short ??boundY_ok		; force it to stay at least one pixel
	mov	dx,[MouseBottom]			; on the screen
	dec	dx
??boundY_ok:

	IF 0
;------	Remap the middle button to equal the right button.
	test	bx,04h
	je	??noremap
	or	bx,0010b		; Set the right button bit.
??noremap:
	ENDIF

	mov	[MouseX],cx		; and store in mouse x
	mov	[MouseY],dx		; store y coord in mouse y
	test	[KeyFlags],KEYMOUSE
	jne	short ??nostuffit

	call	Mouse_KeyNum C,[Mouse_State]	; Convert mouse state to key number code.
	call	Stuff_Key_Num C,ax	; Record mouse keynumber code.
??nostuffit:



;------ The check for Mouse in the middle of updating CAN NOT BE MOVED
;	any farther up because mouse presses and releases will be LOST!!
 	cmp	[MouseUpdate],0
	jne	??exit
;??jexit:
;	jmp	??exit


christopher:
??chkxy:

;------	Signal that no mouse updating can occur at this time.
;	cmp	[_MouseUpdate],0
;	jne	??exit
;	mov	[_MouseUpdate],1

;------	Perform any X movement grid adjustment.
	cmp	[MouseStepX],0		; are we stepping on the X?
	je	short ??no_x_step		; no x
	mov	ax,cx			; get current x_pixel
	mov	cx,dx			; save dx - it is trashed by idiv
	sub	ax,[MouseOffsetX]	; get offset difference
	mov	bx,[MouseStepX]	; get step in bx for idiv
	cwd				; extend ax -> dx:ax
	idiv	bx			; divide by Step X
	imul	bx			; ax = div * Step X
	add	ax,[MouseOffsetX]	; normalize to region offset
	mov	dx,cx			; restore dx (new MouseY)
	mov	cx,ax			; set cx (new MouseX)
??no_x_step:

;------	Perform any Y movement grid adjustment.
	cmp	[MouseStepY],0		; are we stepping on the Y
	je	short ??no_step		; no y
	mov	ax,dx			; get current y_pixel
	sub	ax,[MouseOffsetY]	; get offset difference
	mov	bx,[MouseStepY]		; get step in bx for idiv
	cwd				; extend ax -> dx:ax
	idiv	bx			; divide by Step Y
	imul	bx			; ax = div * Step Y
	add	ax,[MouseOffsetY]	; normalize to region offset
	mov	dx,ax			; set dx (new MouseY)
??no_step:

;------ Here is where we store the new MouseX and MouseY values
;	mov	[MouseX],cx		; and store in mouse x
;	mov	[MouseY],dx		; store y coord in mouse y

;------	If the mouse is hidden or its position hasn't changed, then
;	perform no action.
	cmp	[MState],0
	jne	short ??updateend
	cmp	[MouseXOld],cx
	jne	short ??doit
	cmp	[MouseYOld],dx
	je	short ??updateend
??doit:

;------	At this point we KNOW the mouse has moved.
	mov	ax,[MCState]
	and	ax,CONDHIDE+CONDHIDDEN
	cmp	ax,CONDHIDE+CONDHIDDEN
	je	short ??condcheck		; If already hidden.

;------	We know that the mouse is visible, we must hide it
;	before we update its position.
	call	Low_Hide_Mouse

;------	Conditional region check goes here.  If the mouse falls within the
;	conditional region, it gets marked as hidden and no other processing
;	occurs.
	test	[MCState],CONDHIDE
	je	short ??condok

??condcheck:
	cmp	cx,[MouseCXLeft]		; check adjusted x region
	jb	short ??condok
	cmp	cx,[MouseCXRight]
	ja	short ??condok
	cmp	dx,[MouseCYUpper]	; check adjusted y region
	jb	short ??condok
	cmp	dx,[MouseCYLower]
	ja	short ??condok

	or	[MCState],CONDHIDDEN	; flag as conditional hidden
	jmp short ??updateend

;------	The mouse coordinates and flags pass all of the tests, proceed
;	with rendering the mouse.
??condok:
	call	Low_Show_Mouse

;------	Final clean up and exit.
??updateend:
	mov	[MouseXOld],cx
	mov	[MouseYOld],dx

??exit:
	cmp	[Mouse_StackPointer],0DEADh
	je	??mouse_stk_ok
	push cx
	push di
	push ax
	push es
	mov  ax,0A000h
	mov  es,ax
	xor  di,di
	mov  cx,64000
	mov  ax,1
	rep  stosb
	pop  es
	pop  ax
	pop  di
	pop  cx

??mouse_stk_ok:
	; Restore System Stack Pointer Selector before exit Interrupt
	mov ax, [Mouse_App_Stack_SS]
	cli				       ; disable Interrupts
	mov ss, ax			       ; Get Syatem Stack Selector
	mov sp, [Mouse_App_Stack_ES]           ; Get Syatem Stack offset
	sti				       ; Enable Interrupts
	ret
	ENDP	Mouse_Int



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
	GLOBAL	C VGA_Mouse_Shadow_Buffer:FAR
	PROC	VGA_Mouse_Shadow_Buffer C FAR
	USES	ax,bx,cx,dx,di,si,ds,es
	ARG	store:WORD

	local	x0 : word
	local	y0 : word
	local	x1 : word
	local	y1 : word
	local	buffx0 : word
	local	buffy0 : word

	;*=========================================================================*
	;* Since we are in tiny model point ds to cs
	;*=========================================================================*
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	;*=========================================================================*
	; Direction flag must be forward in this routine.
	;*=========================================================================*
	cld

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	ax,[MouseBuffX]
	mov	bx,[MouseBuffY]
	sub	ax , [ MouseXHot ]
	sub	bx , [ MouseYHot ]
	mov	[ x0 ] , ax
	mov	[ y0 ] , bx

	add	ax , [MouseBuffW]
	add	bx , [MouseBuffH]
	mov	[ x1 ] , ax
	mov	[ y1 ] , bx

	mov	[ buffx0 ] , 0
	mov 	ax , [ word ptr MouseBuffer ]
	mov	[ buffy0 ] , ax

;*===================================================================
;* Bounds check source X. Y.
;*===================================================================

	xor 	ax , ax
	xor 	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	sub	cx , [ MouseRight ]
	sub	bx , [ MouseRight ]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	sub	cx , [MouseBottom]
	sub	bx , [MouseBottom]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??acepted

	test	ah , 1000b
	jz	??scr_left_ok
	mov	bx , [ x0 ]
	neg	bx
	mov	[ buffx0 ] , bx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	push	dx
	mov	ax , [ y0 ]
	neg	ax
	mul	[MouseBuffW]
	add	[ buffy0 ] , ax
	mov	[ y0 ] , 0
	pop	dx

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	ax , [MouseRight]  ; get width into register
	mov	[ x1 ] , ax
??scr_right_ok:
	test	dl , 0001b
	jz	??acepted
	mov	ax , [MouseBottom]  ; get width into register
	mov	[ y1 ] , ax

??acepted:

	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================

	mov	ax,0A000h
	mov	es,ax

	mov	ax , [ y0 ]
	mul	[ MouseRight ]
	mov	dx , [MouseRight]
	mov	di , ax
	add	di , [ x0 ]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	bx , [ MouseWidth ]	; turn this into an offset
	lds	si , [ MouseBuffer ]
	mov	si , [ buffy0 ]		; edx points to source
	add	si , [ buffx0 ]		; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	ax , [ x1 ]
	mov	cx , [ y1 ]
	sub	ax , [ x0 ]
	jle	??out
	sub	cx , [ y0 ]
	jle	??out

	sub	dx , ax
	sub	bx , ax

	push	bp
	cmp	[store],RESTORE_VISIBLE_PAGE		; are we restoring page?
	jne	??store_entry				; if not the go to store
	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
	mov	bp , cx
??restore_loop:
	mov	cx,ax					; get number to really write
	rep	movsb					; store them into the buffer
	add	si,bx				; move past right clipped pixels
	add	di,dx					; adjust dest to next line
	dec	bp					; decrement number of rows to do
	jnz	??restore_loop				; if more to do, do it
	pop	bp

IF  ECHOON
mov ax , 0b000h
mov di , 12 * 80 + 10
mov es, ax
mov al , 'V'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF

	ret

	;*===================================================================
	;* Handle soting the visible page into the Mouse Shadow Buffer
	;*===================================================================
??store_entry:
	xchg	si,di					; xchg the source and the dest
	mov	bp , cx
	push	es					; need to swap es and ds but
	push	ds					;   cant xchg so pop them on the
	pop	es					;   stack and pop them off the
	pop	ds					;   wrong way intentionally.
??store_loop:
	mov	cx,ax					; get number to really write
	rep	movsb					; store them into the buffer
	add	si,dx					; move past right clipped pixels
	add	di,bx					; adjust dest to next line
	dec	bp					; decrement number of rows to do
	jnz	??store_loop				; if more to do, do it
	pop	bp
??out:

IF  ECHOON
mov ax , 0b000h
mov di , 12 * 80 + 12
mov es, ax
mov al , 'G'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF
	ret

	ENDP	VGA_Mouse_Shadow_Buffer

;***************************************************************************

	GLOBAL	C VGA_Draw_Mouse:FAR
	PROC	VGA_Draw_Mouse C FAR
	USES	ax,bx,cx,dx,di,si,ds,es
	ARG	mousex:WORD
	ARG	mousey:WORD

	local	x0 : word
	local	y0 : word
	local	x1 : word
	local	y1 : word
	local	buffx0 : word
	local	buffy0 : word

	;*=========================================================================*
	;* Since we are in tiny model point ds to cs
	;*=========================================================================*
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	;*===================================================================
	;* Pre-initialize the left, right and topclip values to zero.
	;*===================================================================
	mov	ax, [ mousex ]
	mov	bx , [ mousey ]
	sub	ax , [ MouseXHot ]
	sub	bx , [ MouseYHot ]
	mov	[ x0 ] , ax
	mov	[ y0 ] , bx
	add	ax, [ MouseWidth ]
	add	bx, [ MouseHeight ]
	mov	[ x1 ] , ax
	mov	[ y1 ] , bx

	mov	[ buffx0 ] , 0
	les	ax , [ MouseCursor ]
	mov	[ buffy0 ] , ax

	;*===================================================================
	;* Bounds check source X. Y.
	;*===================================================================

	xor 	ax , ax
	xor 	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	sub	cx , [ MouseRight ]
	sub	bx , [ MouseRight ]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	sub	cx , [MouseBottom]
	sub	bx , [MouseBottom]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	xor	al , 5
	xor	dl , 5

	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??acepted

	test	ah , 1000b
	jz	??scr_left_ok
	mov	bx , [ x0 ]
	neg	bx
	mov	[ buffx0 ] , bx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	push	dx
	mov	ax , [ y0 ]
	neg	ax
	mul	[MouseWidth]
	add	[ buffy0 ] , ax
	mov	[ y0 ] , 0
	pop	dx

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	bx , [MouseRight]  ; get width into register
	mov	[ x1 ] , bx
??scr_right_ok:
	test	dl , 0001b
	jz	??acepted
	mov	bx , [MouseBottom]  ; get width into register
	mov	[ y1 ] , bx

??acepted:

	mov	ax , [ y0 ]
	mul	[ MouseRight ]
	mov	dx , [MouseRight]
	mov	di , ax
	add	di , [ x0 ]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	bx , [MouseWidth]	; turn this into an offset
	mov	si , [ buffy0 ]		; edx points to source
	add	si , [ buffx0 ]		; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================
	mov	ax , 0a000h
	mov	ds , ax
	mov	ax , [ x1 ]
	mov	cx , [ y1 ]
	sub	ax , [ x0 ]
	jle	??out
	sub	cx , [ y0 ]
	jle	??out

	sub	dx , ax
	sub	bx , ax

	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
??top_loop:
	mov	ah,al
??inner_loop:
	mov	ch , [es:si]
	inc	esi
	or	ch,ch
	jz	??inc_edi
	mov	[di],ch
??inc_edi:
	inc	di
	dec	ah
	jnz	??inner_loop
	add	si,bx				; move past right clipped pixels
	add	di,dx				; adjust dest to next line
	dec	cl					; decrement number of rows to do
	jnz	??top_loop				; if more to do, do it
??out:

IF  ECHOON
mov ax , 0b000h
mov di , 12 * 80 + 14
mov es, ax
mov al , 'A'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF
	ret
ENDP	VGA_Draw_Mouse


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
	GLOBAL	C VESA_Mouse_Shadow_Buffer:FAR
	PROC	VESA_Mouse_Shadow_Buffer C FAR
	USES	ax,bx,cx,dx,di,si,ds,es
	ARG	store:WORD

	local	x0 : word
	local	y0 : word
	local	x1 : word
	local	y1 : word
	local	buffx0 : word
	local	buffy0 : word

	;*=========================================================================*
	;* Since we are in tiny model point ds to cs
	;*=========================================================================*
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	call	get_vesa_window
	mov	[ app_vesa_window ] , dx

	;*=========================================================================*
	; Direction flag must be forward in this routine.
	;*=========================================================================*
	cld

	;*===================================================================
	;* Copy of X, Y, Width and Height into local registers
	;*===================================================================
	mov	ax,[MouseBuffX]
	mov	bx,[MouseBuffY]
	sub	ax , [ MouseXHot ]
	sub	bx , [ MouseYHot ]

	mov	[ x0 ] , ax
	mov	[ y0 ] , bx
	add	ax , [MouseBuffW]
	add	bx , [MouseBuffH]
	mov	[ x1 ] , ax
	mov	[ y1 ] , bx

	mov	[ buffx0 ] , 0
	mov 	ax , [ word ptr MouseBuffer ]
	mov	[ buffy0 ] , ax

;*===================================================================
;* Bounds check source X. Y.
;*===================================================================

	xor 	ax , ax
	xor 	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	sub	cx , [ MouseRight ]
	sub	bx , [ MouseRight ]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	sub	cx , [MouseBottom]
	sub	bx , [MouseBottom]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??acepted

	test	ah , 1000b
	jz	??scr_left_ok
	mov	bx , [ x0 ]
	neg	bx
	mov	[ buffx0 ] , bx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	push	dx
	mov	ax , [ y0 ]
	neg	ax
	mul	[MouseBuffW]
	add	[ buffy0 ] , ax
	mov	[ y0 ] , 0
	pop	dx

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	ax , [MouseRight]  ; get width into register
	mov	[ x1 ] , ax
??scr_right_ok:
	test	dl , 0001b
	jz	??acepted
	mov	ax , [MouseBottom]  ; get width into register
	mov	[ y1 ] , ax

??acepted:

	;*===================================================================
	;* Get the offset into the screen.
	;*===================================================================
	mov	ax,0A000h
	mov	es,ax

	mov	ax , [ y0 ]
	mul	[ MouseRight ]

	add	ax , [ x0 ]
	adc	dx , 0
	mov	di , ax
	call	set_vesa_page
	mov	dx , [MouseRight]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================


	mov	bx , [ MouseWidth ]	; turn this into an offset
	lds	si , [ MouseBuffer ]
	mov	si , [ buffy0 ]		; edx points to source
	add	si , [ buffx0 ]		; plus clipped lines


	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================

	mov	ax , [ x1 ]
	mov	cx , [ y1 ]
	sub	ax , [ x0 ]
	jle	??out
	sub	cx , [ y0 ]
	jle	??out

	sub	dx , ax
	sub	bx , ax

	cmp	[store],RESTORE_VISIBLE_PAGE		; are we restoring page?
	jne	??store_entry				; if not the go to store
	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
??restore_loop:
	mov	ah,al
??res_inner_loop:
	mov	ch , [si]
	mov	[es:di],ch
	inc	si
	inc	di
	jnz	??res_same_page
	call	next_vesa_page
 ??res_same_page:
 	dec	ah
	jnz	??res_inner_loop
	add	si,bx				; move past right clipped pixels
	add	di,dx				; adjust dest to next line
	jnc	??res_same_page1
	call	next_vesa_page
 ??res_same_page1:
	dec	cl					; decrement number of rows to do
	jnz	??restore_loop

IF  ECHOON
mov ax , 0b000h
mov di , 10 * 80 + 10
mov es,ax
mov al ,'v'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF
	jmp	??out

	;*===================================================================
	;* Handle soting the visible page into the Mouse Shadow Buffer
	;*===================================================================
??store_entry:
	mov	ah,al
??store_inner_loop:
	mov	ch , [es:di]
	mov	[si],ch
	inc	si
	inc	di
	jnz	??store_same_page
	call	next_vesa_page
 ??store_same_page:
 	dec	ah
	jnz	??store_inner_loop
	add	si,bx				; move past right clipped pixels
	add	di,dx				; adjust dest to next line
	jnc	??store_same_page1
	call	next_vesa_page
 ??store_same_page1:
	dec	cl					; decrement number of rows to do
	jnz	??store_entry
??out:

IF  ECHOON
mov ax , 0b000h
mov di , 10 * 80 + 14
mov es,ax
mov al ,'e'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF

	mov	dx , [ app_vesa_window ]
	call	set_vesa_window
	ret

	ENDP	VESA_Mouse_Shadow_Buffer



;***************************************************************************

	GLOBAL	C VESA_Draw_Mouse:FAR
	PROC	VESA_Draw_Mouse C FAR
	USES	ax,bx,cx,dx,di,si,ds,es
	ARG	mousex:WORD
	ARG	mousey:WORD

	local	x0 : word
	local	y0 : word
	local	x1 : word
	local	y1 : word
	local	buffx0 : word
	local	buffy0 : word
	local	app_vesa_window : word


	;*=========================================================================*
	;* Since we are in tiny model point ds to cs
	;*=========================================================================*
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	call	get_vesa_window
	mov	[ app_vesa_window ] , dx


	;*===================================================================
	;* Pre-initialize the left, right and topclip values to zero.
	;*===================================================================
	mov	ax, [ mousex ]
	mov	bx , [ mousey ]
	sub	ax , [ MouseXHot ]
	sub	bx , [ MouseYHot ]

	mov	[ x0 ] , ax
	mov	[ y0 ] , bx
	add	ax, [ MouseWidth ]
	add	bx, [ MouseHeight ]
	mov	[ x1 ] , ax
	mov	[ y1 ] , bx

	mov	[ buffx0 ] , 0
	les	ax , [ MouseCursor ]
	mov	[ buffy0 ] , ax

	;*===================================================================
	;* Bounds check source X. Y.
	;*===================================================================

	xor 	ax , ax
	xor 	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ x0 ]
	mov	bx , [ x1 ]
	sub	cx , [ MouseRight ]
	sub	bx , [ MouseRight ]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	mov	cx , [ y0 ]
	mov	bx , [ y1 ]
	sub	cx , [MouseBottom]
	sub	bx , [MouseBottom]
	dec	cx
	dec	bx
	add	cx , cx
	adc	ax , ax
	add	bx , bx
	adc	dx , dx

	xor	al , 5
	xor	dl , 5
	mov	ah , al
	test	dl , al
	jnz	??out
	or	al , dl
	jz	??acepted


	test	ah , 1000b
	jz	??scr_left_ok
	mov	bx , [ x0 ]
	neg	bx
	mov	[ buffx0 ] , bx
	mov	[ x0 ] , 0

??scr_left_ok:
	test	ah , 0010b
	jz	??scr_bottom_ok
	push	dx
	mov	ax , [ y0 ]
	neg	ax
	mul	[MouseWidth]
	add	[ buffy0 ] , ax
	mov	[ y0 ] , 0
	pop	dx

??scr_bottom_ok:
	test	dl , 0100b
	jz	??scr_right_ok
	mov	ax , [MouseRight]  ; get width into register
	mov	[ x1 ] , ax
??scr_right_ok:
	test	dl , 0001b
	jz	??acepted
	mov	ax , [MouseBottom]  ; get width into register
	mov	[ y1 ] , ax

??acepted:

	mov	ax , [ y0 ]
	mul	[ MouseRight ]

	add	ax , [ x0 ]
	adc	dx , 0
	mov	di , ax
	call	set_vesa_page

	mov	dx , [MouseRight]

	;*===================================================================
	;* Adjust the source for the top clip.
	;*===================================================================
	mov	bx , [MouseWidth]	; turn this into an offset
	mov	si , [ buffy0 ]		; edx points to source
	add	si , [ buffx0 ]		; plus clipped lines

	;*===================================================================
	;* Calculate the bytes per row add value
	;*===================================================================
	mov	ax , 0a000h
	mov	ds , ax
	mov	ax , [ x1 ]
	mov	cx , [ y1 ]
	sub	ax , [ x0 ]
	jle	??out
	sub	cx , [ y0 ]
	jle	??out

	sub	dx , ax
	sub	bx , ax

	;*===================================================================
	;* Handle restoring the buffer to the visible page
	;*===================================================================
??top_loop:
	mov	ah,al
??inner_loop:
	mov	ch , [es:si]
	inc	si
	or	ch,ch
	jz	??inc_edi
	mov	[di],ch
??inc_edi:
	inc	di
	jnz	??same_page
	call	next_vesa_page
 ??same_page:
 	dec	ah
	jnz	??inner_loop
	add	si,bx				; move past right clipped pixels
	add	di,dx				; adjust dest to next line
	jnc	??same_page1
	call	next_vesa_page
 ??same_page1:
	dec	cl					; decrement number of rows to do
	jnz	??top_loop				; if more to do, do it
??out:

IF  ECHOON
mov ax , 0b000h
mov di , 10 * 80 + 14
mov es, ax
mov al , 's'
mov [es:di],al
mov al,2
mov [es:di+1],al
mov di , 10 * 80 + 16
mov al , 'a'
mov [es:di],al
mov al,2
mov [es:di+1],al
ENDIF
	mov	dx , [ app_vesa_window ]
	call	set_vesa_window
	ret


ENDP	VESA_Draw_Mouse



;************************************************************************

PROC	get_vesa_window C near
uses	ax,bx
	mov	ax , 04f05h
	mov	bh , 1
	mov	bl , 0
	call	[ dword ptr cs: VesaPtr ]
	ret
ENDP

;************************************************************************

PROC	set_vesa_window C near
uses	ax,bx,dx
	mov	ax , 04f05h
	mov	bh , 0
	mov	bl , 0
	call	[ dword ptr cs: VesaPtr ]
	ret
ENDP


;***************************************************************************

PROC	set_vesa_page C near
USES	ax,bx,dx

	mov	bx , dx
	shl	bx , 2
	mov	[ cs: current_page ] , bx
	mov	dx , [ word ptr cs:banktable + bx ]
	mov	ax , 04f05h
	mov	bh , 0
	mov	bl , 0
	call	[ dword ptr cs: VesaPtr ]
	ret
ENDP	set_vesa_page

PROC	next_vesa_page C near
USES	ax,bx,dx
	mov	bx , [ cs: current_page ]
	add	bx , 4
	mov	[ cs:current_page ] , bx
	mov	dx , [ word ptr cs:banktable + bx ]
       	mov	ax , 04f05h
	mov	bh , 0
	mov	bl , 0
	call	[ dword ptr cs: VesaPtr ]
	ret
ENDP	next_vesa_page



;***********************************************************
END
