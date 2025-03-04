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
;*                    File Name : KEYINTR.ASM                              *
;*                                                                         *
;*                   Programmer : Christopher Yates                        *
;*                                                                         *
;*                   Start Date : May 21, 1992                             *
;*                                                                         *
;*                  Last Update : July 13, 1994   [PWG]                    *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   KeyNum_Translate -- Translates the given keynum to ???                *
;*   Install_Interrupt -- Installs the keyboard interrupt                  *
;*   Stuff_Key_Word -- Stuffs a word of data into keyboard buffer          *
;*   Stuff_Key_Num -- Stuffs a key num code into the circular buffer       *
;*   Remove_Interrupt -- Removes the keyboard interrupt and restores the chai*
;*   Keystroke_Interrupt -- Handles input that comes from the keyboard     *
;*   Break_Interrupt -- Handles the break key interrupt                    *
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

CODESEG


SoundOn		DW	1	; toggled by alt S
MusicOn		DW	1	; toggled by alt M
KeyFlags	DW	REPEATON+CTRLALTTURBO	; all but repeat for now


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
KeyBufferHead	DW	0	; set to first entry
KeyBufferTail	DW	0	; set to head for empty buffer
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
EdgeConv	DW	8,2,8,6,4,3,8,5,8,8,8,8,0,1,8,7

MouseUpdate		DW	0
MouseX			DW	0
LocalMouseX		DW	0
MouseY			DW	0
LocalMouseY		DW	0
Button			DW	0
IsExtKey		DB	0
ExtIndex		DW	0

OldRMI			DD	0	; The origianl RM interrupt seg:off.
OldPMIOffset		DD	0	; The origianl PM interrupt offset
OldPMISelector		DD	0	; The original PM interrupt segment.

CodeOffset		DW	RM_Keystroke_Interrupt	; Offset of the code in the RM stuff.
CallRMIntOffset		DW	Call_Interrupt_Chain		; Offset of function to call DOS timer interrupt.
CallRMIntAddr		DD	0	; PM address of CallRealIntOffset for speed.

;***************************************************************************
;* KEYNUM_TRANSLATE -- Translates the given keynum to ???                  *
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
	GLOBAL C	KeyNum_Translate:FAR
	PROC	KeyNum_Translate C FAR
	USES	cx,di,es,ds
	ARG	keycode:WORD
ifdef NOT_FOR_WIN95
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds
	mov	es,ax				; set es up for scansb

	mov	ax,[keycode]
	test	[KeyFlags],TRACKEXT
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
endif ;NOT_FOR_WIN95
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

ifdef NOT_FOR_WIN95
	mov	ax,cs				; since we are in tiny model
	mov	ds,ax				; set cs = ds

	mov	ax,[KeyBufferTail]
	mov	si,ax
	add	ax,2
	and	ax,0FFh				; New KeyBufferTail value.
	cmp	[KeyBufferHead],ax
	je 	short ??noroom

	mov	bx,[code]
	mov	[KeyBuffer+si],bx		; Record the keystroke.
	mov	[KeyBufferTail],ax
	xor	ax,ax
	ret

??noroom:
	mov	ax,1
endif ; NOT_FOR_WIN95
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
	USES	ax,bx,cx,dx,di,si,ds
	ARG	keycode:WORD
	LOCAL	tail:WORD		; Original keybuffer tail (safety copy).
	LOCAL	size:WORD		; Size of write.

ifdef NOT_FOR_WIN95
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

	test	[KeyFlags],KEYMOUSE	; is the numeric keypad moving the mouse?
	je	??no_pad_move

	; ALT-cursor keys are undefined.  Pass them on to the program.
	test	ah,ALTPRESS		; is either alt key down?
	jne	??no_pad_move

	test	[KeyFlags],SIMLBUTTON	; are we simulating left mouse presses
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
; PWG: ARRGGGHHHH!
;	call	Low_Hide_Mouse
;	call	Low_Show_Mouse
??noshow:
	mov	ax,KN_MOUSE_MOVE
??mousefake:
	mov	[keycode],ax		; Fake a MOUSE_MOVE event.

??no_pad_move:
	; Fetch working pointers to the keyboard ends.
	mov	si,[KeyBufferTail]
	mov	[tail],si		; Safety record.
	mov	di,[KeyBufferHead]

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
	test	[KeyFlags],PASSBREAKS
	jne 	short ??real
	cmp	al,KN_LMOUSE
	je 	short ??real
	cmp	al,KN_RMOUSE
	je 	short ??real
??notreal:
	mov	[KeyBufferTail],si	; Nullify any KeyBufferTail changes.
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
	test	[KeyFlags],REPEATON
	jne	short ??notalready
	mov	[KeyBufferTail],si	; Nullify any KeyBufferTail changes.
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
	mov	[KeyBufferTail],ax
	xor	ax,ax			; Signal an error.

??exit:
	popf
endif; NOT_FOR_WIN95
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

ifdef NOT_FOR_WIN95
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
	mov	dx,[KeyFlags]
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
;***********************************************************
	pushf
;	push	di
;	push	es

	mov	ax,0B000h
	mov	es,ax
	inc	[BYTE PTR es:0]

;	pop	es
;	pop	di
	popf
;***********************************************************

??passcode:

	pop	si
	pop	es
	pop	dx
	pop	ds
	pop	di
	pop	cx
	pop	bx
	pop	ax
	inc	[cs:PassCount]
	jmp	[cs:OldRMI]

??absorbcode:
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
endif ;NOT_FOR_WIN95

	ENDP	Keystroke_Interrupt

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
	GLOBAL	C Break_Interrupt:FAR
	PROC	Break_Interrupt C FAR

	iret

	ENDP	Break_Interrupt

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
ifdef NOT_FOR_WIN95
IF 0
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

	in	al,KEYDATA		; get a code from the keyboard
	mov	al,CLEARISR		; value to clear In Service Register
	out	INTCHIP0,al		; 8259 interrupt chip controller 0


	pop	es
	pop	di
	pop	ax
	popf
ENDIF
	pushf
	call	Keystroke_Interrupt ;[OldRMI]
endif; NOT_FOR_WIN95
	retf

STACK	   ; Don't really need this

;***********************************************************
END