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

;****************************************************************************
;*
;*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
;*
;*---------------------------------------------------------------------------
;*
;* PROJECT
;*     VQAPlay32 library.
;*
;* FILE
;*     unvqvesa.asm
;*
;* DESCRIPTION
;*     VESA VQ decompress/draw routines. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     UnVQ_4x2_VESA320_32K - Draw 4x2 VQ frame to VESA320 32k color.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"vga.i"
	INCLUDE	"vesavid.i"
	INCLUDE	"vqaplay.i"
	CODESEG

SKIP_PTR	EQU	8000h

	IF	VQAVESA_ON
	IF	VQABLOCK_4X2
;****************************************************************************
;*
;* NAME
;*     UnVQ_4x2_VESA320_32K - Draw 4x2 VQ frame to VESA320 32k color.
;*
;* SYNOPSIS
;*     UnVQ_4x2_VESA320_32K(Codebook, Pointers, Palette, GrainPerWin)
;*
;*     void UnVQ_4x2_VESA320_32K(char *, char *, char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Codebook    - Pointer to codebook.
;*     Pointers    - Pointer to vector pointer data to unvq.
;*     Palette     - Pointer to 15-bit palette.
;*     GrainPerWin - Granularity units for 64k window.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************
 
;---------------------------------------------------------------------------
; SET_2_PIXELS:
; - Loads 2 bytes from codebook, expands them into words in eax
; - Sets them on the screen
;   cb_index: offset into codebook of start of 2 bytes to load
;   di_index: offset from current di to draw 2 pixels
;   BX: offset into codebook of this block
; Uses: EAX, DX, SI!
;---------------------------------------------------------------------------

	MACRO	SET_2_PIXELS cb_index,edi_index
	xor	edx,edx
	mov	dl,[BYTE PTR ebx+1+cb_index]
	shl	edx,1
	add	edx,[palette]
	mov	esi,edx
	mov	ax,[WORD PTR esi]
	shl	eax,16
	xor	edx,edx
	mov	dl,[BYTE PTR ebx+cb_index]
	shl	edx,1
	add	edx,[palette]
	mov	esi,edx
	mov	ax,[WORD PTR esi]

	IF	PHARLAP_TNT
	mov	[DWORD PTR es:edi+edi_index],eax
	ELSE
	mov	[DWORD PTR edi+edi_index],eax
	ENDIF
	ENDM

;---------------------------------------------------------------------------
; DRAW_BLOCK_ROWS macro:
; Draws 'numrows' rows of 'blocksperrow' blocks each
;---------------------------------------------------------------------------

	MACRO	DRAW_BLOCK_ROWS numrows,blocksperrow
	LOCAL	??Start_row
	LOCAL	??Not_finished_a_line
	LOCAL	??One_color
	LOCAL	??Draw_One_Color
	LOCAL	??Next_row
	LOCAL	??Done

	mov	[rowcount],numrows		; initialize row counter

	;---------------------------------------- Start a new row:
??Start_row:
	mov	ecx,blocksperrow			; # blocks to fill a line

	;---------------------------------------- Start a new block:
??Not_finished_a_line:
	;........................................ Get next pointer word:
	xor	ebx,ebx
	mov	bx,[WORD PTR esi]		; BX = pointer word
	add	esi,2

	;........................................ Check for a 1-color block:
	or	bx,bx				; see if high bit is set
	js	??One_color

	;---------------------------------------- Multi-color block:
	mov	[esi_save],esi			; save current SI
	add	ebx,[cb_offset]			; get codebook offset
	SET_2_PIXELS 0,0
	SET_2_PIXELS 2,4
	SET_2_PIXELS 4,640
	SET_2_PIXELS 6,644
	add	edi,8				; next block position
	mov	esi,[esi_save]			; get current SI

	;........................................ Check block count
	dec	ecx				; decrement block count
	jnz	??Not_finished_a_line

	;---------------------------------------- Next block row:
	add	edi,640
	;
	;............ see if we're past the end of the ptr data ............
	;
	dec	[rowcount]
	jnz	??Start_row
	jmp	??Done

	;---------------------------------------- 1-color block:
??One_color:
	;................... skip ptr value SKIP_PTR .......................
	cmp	bx,SKIP_PTR
	jne	??Draw_One_Color
	add	edi,8
	dec	ecx
	jnz	??Not_finished_a_line
	jmp	??Next_row
??Draw_One_Color:
	not	bx				; get palette index
	shl	bx,1				; convert to WORD offset
	add	ebx,[palette]
	mov	ax,[WORD PTR ebx]		; get 15-bit palette value
	mov	dx,ax				; copy it into dx
	shl	eax,16
	mov	ax,dx				; eax = 2 pixels, same color
	mov	edx,eax				; edx = 2 pixels, same color

	IF	PHARLAP_TNT
	mov	[DWORD PTR es:edi],eax		; set 2 pixels
	mov	[DWORD PTR es:edi+4],edx		; set 2 pixels
	mov	[DWORD PTR es:edi+640],eax	; set 2 pixels
	mov	[DWORD PTR es:edi+644],edx	; set 2 pixels
	ELSE
	mov	[DWORD PTR edi],eax		; set 2 pixels
	mov	[DWORD PTR edi+4],edx		; set 2 pixels
	mov	[DWORD PTR edi+640],eax	; set 2 pixels
	mov	[DWORD PTR edi+644],edx	; set 2 pixels
	ENDIF

	add	edi,8				; next block position

	;........................................ Check block count
	dec	ecx				; decrement block count
	jnz	??Not_finished_a_line

	;---------------------------------------- Next block row:
??Next_row:
	add	edi,640
	;
	;............ see if we're past the end of the ptr data ............
	;
	dec	[rowcount]
	jnz	??Start_row
??Done:
	ENDM

;---------------------------------------------------------------------------
; DRAW_BLOCK_PART_ROW macro:
; Draws top or bottom half of blocks on a row
; 'numblocks' = # blocks to draw
; 'cb_add' = amt to add to codebook (0=top half, 4=bottom half)
;---------------------------------------------------------------------------

	MACRO	DRAW_BLOCK_PART_ROW numblocks,cb_add
	LOCAL	??Not_finished_a_line
	LOCAL	??One_color
	LOCAL	??Draw_One_Color
	LOCAL	??Done

	mov	ecx,numblocks

	;---------------------------------------- Start a new block:
??Not_finished_a_line:
	;........................................ Get next pointer word:
	xor	ebx,ebx
	mov	bx,[WORD PTR esi]		; BX = pointer word
	add	esi,2

	;........................................ Check for a 1-color block:
	or	bx,bx				; see if high bit is set
	js	short ??One_color

	;---------------------------------------- Multi-color block:
	mov	[esi_save],esi			; save current SI
	add	ebx,[cb_offset]			; get codebook offset
	SET_2_PIXELS cb_add,0
	SET_2_PIXELS cb_add+2,4
	add	edi,8				; next block position
	mov	esi,[esi_save]			; get current SI

	;........................................ Check block count
	dec	ecx				; decrement block count
	jnz	short ??Not_finished_a_line
	jmp	??Done

	;---------------------------------------- 1-color block:
??One_color:
	;................... skip ptr value SKIP_PTR .......................
	cmp	bx,SKIP_PTR
	jne	??Draw_One_Color
	add	edi,8
	dec	ecx
	jnz	short ??Not_finished_a_line
	jmp	??Done
??Draw_One_Color:
	not	bx				; get palette index
	shl	bx,1				; convert to WORD offset
	add	ebx,[palette]
	mov	ax,[WORD PTR ebx]		; get 15-bit palette value
	mov	dx,ax				; copy it into dx
	shl	eax,16
	mov	ax,dx				; eax = 2 pixels, same color
	mov	edx,eax				; edx = 2 pixels, same color

	IF	PHARLAP_TNT
	mov	[DWORD PTR es:edi],eax		; set 2 pixels
	mov	[DWORD PTR es:edi+4],edx		; set 2 pixels
	ELSE
	mov	[DWORD PTR edi],eax		; set 2 pixels
	mov	[DWORD PTR edi+4],edx		; set 2 pixels
	ENDIF

	add	edi,8				; next block position

	;........................................ Check block count
	dec	ecx				; decrement block count
	jnz	??Not_finished_a_line
??Done:
	ENDM

;===========================================================================
; The actual procedure:
;===========================================================================

	GLOBAL	C UnVQ_4x2_VESA320_32K:NEAR
	PROC	UnVQ_4x2_VESA320_32K C NEAR

	ARG	codebook:NEAR PTR
	ARG	pointers:NEAR PTR

	IF	PHARLAP_TNT
	ARG	pal:QWORD	;KLUDGE - bcc32 pads FARPTR
	ELSE
	ARG	palette:NEAR PTR
	ENDIF

	ARG	grains_per_win:DWORD
	ARG	dummy1:DWORD
	ARG	dummy2:DWORD

	LOCAL	rowcount:DWORD		; # rows drawn
	LOCAL	esi_save:DWORD
	LOCAL	cb_offset:DWORD

	IF	PHARLAP_TNT
	LOCAL	palette:NEAR PTR
	ENDIF

	;-------------------------------------------------------------------
	; Save registers
	;-------------------------------------------------------------------
	pushad

	;-------------------------------------------------------------------
	; Set GS:[cb_offset] to codebook
	;-------------------------------------------------------------------
	mov	eax,[codebook]
	sub	eax,4
	mov	[cb_offset],eax
	mov	esi,[pointers]

	;-------------------------------------------------------------------
	; Set ES:DI to screen
	;-------------------------------------------------------------------

	IF	PHARLAP_TNT
	push	es
	les	edi,[FWORD pal]
	mov	[palette],edi
	mov	eax,01Ch
	mov	es,ax
	mov	edi,0
	ELSE
	mov	edi,0A0000h
	ENDIF

	;-------------------------------------------------------------------
	; Do Bank 0:
	; - 102 full scanlines (51 rows of blocks)
	; - 128 pixels of the top half of blocks (32 top-half blocks)
	;-------------------------------------------------------------------
	SET_WINDOW 0
	DRAW_BLOCK_ROWS 51,80
	DRAW_BLOCK_PART_ROW 32,0	; do top half

	;-------------------------------------------------------------------
	; Do Bank 1:
	; - 128 pixels of the bottom half of the previous 32 blocks
	; - 192 pixels of full blocks (1 row of 48 blocks)
	; - 96 full scanlines (48 rows of blocks)
	;-------------------------------------------------------------------
	SET_WINDOW [grains_per_win]
	sub	esi,64			; subtract word size of last 32 blks
	mov	edi,384
	DRAW_BLOCK_PART_ROW 32,4	; do bottom half
	mov	edi,0
	DRAW_BLOCK_ROWS 1,48		; draw one row of 48 full blocks
	DRAW_BLOCK_ROWS 48,80		; draw 48 full block rows

??End_of_data:
	IF	PHARLAP_TNT
	pop	es
	ENDIF

	popad
	ret

	ENDP	UnVQ_4x2_VESA320_32K

	ENDIF	;VQABLOCK_4X2
	ENDIF	;VQAVESA_ON

	END

