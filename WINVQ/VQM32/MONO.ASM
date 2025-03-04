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
;* FILE
;*     mono.asm
;*
;* DESCRIPTION
;*     Mono screen print and output routines. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     Febuary 8, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     Mono_Enable       - Enable mono output.
;*     Mono_Disable      - Disable mono output.
;*     Mono_X            - Get mono cursors X position.
;*     Mono_Y            - Get mono cursors Y position.
;*     Mono_Set_Cursor   - Set the mono cursor to specified coordinates.
;*     Mono_Clear_Screen - Clear the mono screen.
;*     Mono_Scroll       - Scroll the mono screen up.
;*     Mono_Put_Char     - Ouput a character to the mono screen.
;*     Mono_Draw_Rect    - Draw a box on the mono screen.
;*     Mono_Text_Print   - Print a string to the mono screen at a specified
;*                         position.
;*     Mono_Print        - Print a string to the mono screen.
;*     Mono_View_Page    - View a mono page.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??

	DATASEG

MonoEnabled	DD	1
MonoX	DD	0
MonoY	DD	0
MonoOff	DD	0

CharData	DB	0DAh,0C4h,0BFh,0B3h,0D9h,0C4h,0C0h,0B3h	; Single line
	DB	0D5h,0CDh,0B8h,0B3h,0BEh,0CDh,0D4h,0B3h	; Double horz.
	DB	0D6h,0C4h,0B7h,0BAh,0BDh,0C4h,0D3h,0BAh	; Double vert.
	DB	0C9h,0CDh,0BBh,0BAh,0BCh,0CDh,0C8h,0BAh	; Double line.


;		x,y,dist
BoxData	DB	1,0,0		; Upper left corner.
	DB	1,0,1		; Top edge.
	DB	0,1,0		; Upper right corner.
	DB	0,1,2		; Right edge.
	DB	-1,0,0		; Bottom right corner.
	DB	-1,0,1		; Bottom edge.
	DB	0,-1,0		; Bottom left corner.
	DB	0,-1,2		; Left edge.
	DB	0,0,-1		; End of list.

PageMap	DD	0,1,2,3,4,5,6,7

	CODESEG

;****************************************************************************
;*
;* NAME
;*     Mono_Enable - Enable mono output.
;*
;* SYNOPSIS
;*     Mono_Enable()
;*
;*     void Mono_Enable(void);
;*
;* FUNCTION
;*     Turn on the MonoEnabled flag.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Enable:NEAR
	PROC	Mono_Enable C NEAR

	mov	[MonoEnabled],1
	ret

	ENDP	Mono_Enable


;****************************************************************************
;*
;* NAME
;*     Mono_Disable - Disable mono output.
;*
;* SYNOPSIS
;*     Mono_Disable()
;*
;*     void Mono_Disable(void);
;*
;* FUNCTION
;*     Turn off the MonoEnabled flag.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Disable:NEAR
	PROC	Mono_Disable C NEAR

	mov	[MonoEnabled],0
	ret

	ENDP	Mono_Disable


;****************************************************************************
;*
;* NAME
;*     Mono_X - Get mono cursors X position.
;*
;* SYNOPSIS
;*     X = Mono_X()
;*
;*     long Mono_X(void);
;*
;* FUNCTION
;*     Return the X position of the mono screen cursor.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     X - X coordinate position.
;*
;****************************************************************************

	GLOBAL	C Mono_X:NEAR
	PROC	Mono_X C NEAR

	mov	eax,[MonoX]
	ret

	ENDP	Mono_X


;****************************************************************************
;*
;* NAME
;*     Mono_Y - Get mono cursors Y position.
;*
;* SYNOPSIS
;*     Y = Mono_Y()
;*
;*     long Mono_Y(void);
;*
;* FUNCTION
;*     Return the Y position of the mono screen cursor.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     Y - Y coordinate position.
;*
;****************************************************************************

	GLOBAL	C Mono_Y:NEAR
	PROC	Mono_Y C NEAR

	mov	eax,[MonoY]
	ret

	ENDP	Mono_Y


;****************************************************************************
;*
;* NAME
;*     Mono_Set_Cursor - Set the mono cursor to specified coordinates.
;*
;* SYNOPSIS
;*     Mono_Set_Cursor(X, Y)
;*
;*     void Mono_Set_Cursor(long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     X - X coordinate position.
;*     Y - Y coordinate position.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Set_Cursor:NEAR
	PROC	Mono_Set_Cursor C NEAR USES eax ebx edx

	ARG	xpos:DWORD
	ARG	ypos:DWORD

	cmp	[MonoEnabled],0
	je	short ??fini

	mov	eax,[ypos]
	mov	ah,80
	imul	ah
	add	eax,[xpos]
	mov	ebx,eax

;	Update cursor position.

	mov	dx,03B4h
	mov	al,0Eh		;High byte register set.
	out	dx,al
	inc	dx
	mov	al,bh
	out	dx,al		;Set high byte.

	dec	dx
	mov	al,0Fh		;Low byte register set.
	out	dx,al
	inc	dx
	mov	al,bl
	out	dx,al		;Set low byte.

;	Update the globals.

	add	ebx,ebx
	mov	[MonoOff],ebx
	mov	eax,[xpos]
	mov	[MonoX],eax
	mov	eax,[ypos]
	mov	[MonoY],eax

??fini:
	ret

	ENDP	Mono_Set_Cursor


;****************************************************************************
;*
;* NAME
;*     Mono_Clear_Screen - Clear the mono screen.
;*
;* SYNOPSIS
;*     Mono_Clear_Screen()
;*
;*     void Mono_Clear_Screen(void);
;*
;* FUNCTION
;*     Clear the mono screen and set the mono cursor to the upperleft corner
;*     of the screen.
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Clear_Screen:NEAR
	PROC	Mono_Clear_Screen C NEAR USES es eax ecx edi

;	Exit if mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

;	Clear the mono screen

	IF	PHARLAP_TNT
	mov	ax,034h
	mov	es,ax		;Set ES selector to first MB
	ENDIF

	mov	edi,0B0000h		;EDI = Mono screen address
	xor	eax,eax		;Set char & attributes to 0
	mov	ecx,8000h/4		;Number of longwords to clear
	rep	stosd		;Clear the mono screen.
	call	Mono_Set_Cursor C,eax,eax

??fini:
	ret

	ENDP	Mono_Clear_Screen


;****************************************************************************
;*
;* NAME
;*     Mono_Scroll - Scroll the mono screen up.
;*
;* SYNOPSIS
;*     Mono_Scroll(Lines)
;*
;*     void Mono_Scroll(long);
;*
;* FUNCTION
;*     Move the contents of the mono screen up the specified number of lines
;*     while clearing out the bottom lines.
;*
;* INPUTS
;*     Lines - Number of lines to scroll the screen up.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Scroll:NEAR
	PROC	Mono_Scroll C NEAR USES es eax ebx ecx esi edi
	ARG	lines:DWORD

;	Exit if mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

;	Exit if lines to scroll is 0.

	mov	eax,[lines]
	or	eax,eax
	je	short ??fini

;	Move the screen data up the specified lines

	mov	ebx,eax

??looper:
	IF	PHARLAP_TNT
	mov	ax,034h
	mov	es,ax		;Set ES selector to first MB
	ENDIF

   	push	ds		;Save DS selector
	mov	ds,ax		;Set DS selector to first MB

	mov	ecx,((80*24)/2)	;Number of DWORDs to move
	mov	esi,0B00A0h
	mov	edi,0B0000h
	rep	movsd

	pop	ds		;Restore DS selector
	dec	[MonoY]
	sub	[MonoOff],(80*2)

	xor	eax,eax
	mov	ecx,(80/2)
	rep	stosd

	dec	ebx
	jne	??looper

??fini:
	ret

	ENDP	Mono_Scroll


;****************************************************************************
;*
;* NAME
;*     Mono_Put_Char - Ouput a character to the mono screen.
;*
;* SYNOPSIS
;*     Mono_Put_Char(Character, Attributes)
;*
;*     void Mono_Put_Char(long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Character  - ASCII character to output.
;*     Attributes - Display attributes
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Put_Char:NEAR
	PROC	Mono_Put_Char C NEAR USES es eax edi
	ARG	character:DWORD
	ARG	attrib:DWORD

;	Exit if mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

;	Output character to the mono screen

	cld

	IF	PHARLAP_TNT
	mov	ax,034h
	mov	es,ax		;Set ES selector to first MB
	ENDIF

	mov	edi,0B0000h		;EDI = mono screen
	add	edi,[MonoOff]		;Add cursor offset
	mov	eax,[character]
	mov	ah,[BYTE PTR attrib]
	stosw

;	Update cursor position.

	inc	[MonoX]		; X position moves.
	call	Mono_Set_Cursor C,[MonoX],[MonoY]

??fini:
	ret

	ENDP	Mono_Put_Char


;****************************************************************************
;*
;* NAME
;*     Mono_Draw_Rect - Draw a box on the mono screen.
;*
;* SYNOPSIS
;*     Mono_Draw_Rect(X, Y, Width, Height, Attributes, Thickness)
;*
;*     void Mono_Draw_Rect();
;*
;* FUNCTION
;*     Draw a rectangle text box on the mono screen.
;*
;* INPUTS
;*     X          - X coordinate position of upperleft corner.
;*     Y          - Y coordinate position of upperleft corner.
;*     Width      - Desired width.
;*     Height     - Desired height.
;*     Attributes - Display attributes.
;*     Thickness  - Line thickness.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Draw_Rect:NEAR
	PROC	Mono_Draw_Rect C NEAR
	ARG	xpos:DWORD
	ARG	ypos:DWORD
	ARG	width:DWORD
	ARG	height:DWORD
	ARG	attrib:DWORD
	ARG	thick:DWORD

;	Exit if mono disabled

	pushad
	cmp	[MonoEnabled],0
	je	??fini

;	Select the character table for the desired line thickness

	mov	edi,OFFSET CharData
	mov	cl,3
	mov	eax,[thick]
	and	eax,011b
	shl	eax,cl
	add	edi,eax

;	Prep width and height.

	cmp	[width],2
	jb	??fini

	cmp	[height],2
	jb	??fini

	sub	[width],2
	sub	[height],2

;	Set cursor position to upperleft corner of box

	push	[MonoY]
	push	[MonoX]		;Save current cursor position
	call	Mono_Set_Cursor C,[xpos],[ypos]

;	Draw the rectangle

	mov	esi,OFFSET BoxData

;	Determine the number of characters to output

??drawloop:
	mov	ecx,[width]
	cmp	[BYTE PTR esi+2],1
	je	short ??gotlen

	mov	ecx,[height]
	cmp	[BYTE PTR esi+2],2
	je	short ??gotlen

	mov	ecx,1

??gotlen:
	jecxz	??donerun

??runloop:
	xor	eax,eax
	mov	al,[BYTE PTR edi]
	call	Mono_Put_Char C,eax,[attrib]	;Output the character.

	mov	al,[BYTE PTR esi+1]
	cbw
	cwde
	add	eax,[MonoY]
	push	eax
	mov	al,[BYTE PTR esi]
	cbw
	cwde
	add	eax,[MonoX]
	dec	eax		; Undo cursor advance.
	push	eax
	call	Mono_Set_Cursor	; Properly advance cursor.
	add	sp,8
	loop	??runloop

;	Advance to next control entry.

??donerun:
	add	esi,3
	inc	edi
	cmp	[BYTE PTR esi+2],-1
	jne	??drawloop

;	Restore cursor to original position.

	call	Mono_Set_Cursor
	add	sp,8

??fini:
	popad
	ret

	ENDP	Mono_Draw_Rect


;****************************************************************************
;*
;* NAME
;*     Mono_Text_Print - Print a string to the mono screen at a specified
;*                       position.
;*
;* SYNOPSIS
;*     Mono_Text_Print(String, X, Y, Attributes, Update)
;*
;*     void Mono_Text_Print(char *, long, long, long, long);
;*
;* FUNCTION
;*     Print a NULL terminated string to the mono screen at the specified
;*     cooridinates and attributes.
;*
;* INPUTS
;*     String     - Pointer to NULL terminated string.
;*     X          - X coordinate position.
;*     Y          - Y coordinate position.
;*     Attributes - Display attributes
;*     Update     - Update cursor position flag.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C _Mono_Text_Print:NEAR
	PROC	_Mono_Text_Print C NEAR USES eax esi
	ARG	text:NEAR PTR
	ARG	xpos:DWORD
	ARG	ypos:DWORD
	ARG	attrib:DWORD
	ARG	update:DWORD

;	Save the current cursor position.

	push	[MonoY]
	push	[MonoX]
	cmp	[text],0		;Exit if the string is NULL
	je	short ??fini

	call	Mono_Set_Cursor C,[xpos],[ypos]

;	Print string to the mono screen

	mov	esi,[text]		;Text pointer

??charloop:
	mov	eax,[esi]
	inc	esi
	or	al,al		;Stop on a NULL
	je	short ??fini

	cmp	al,13		;Special processing for '\r'
	je	short ??cr

;	Output character to mono screen

??normal:
	xor	ah,ah
	call	Mono_Put_Char C,eax,[attrib]

;	Perform adjustments if wrapping past right margin.

	cmp	[MonoX],80
	jb	short ??nowrap

	inc	[ypos]
	call	Mono_Set_Cursor C,0,[ypos]
	jmp	short ??nowrap

	; Move to start of next line.

??cr:
	inc	[ypos]
	call	Mono_Set_Cursor C,[xpos],[ypos]

;	Scroll the monochrome screen if necessary.

??nowrap:
	cmp	[MonoY],25
	jb	short ??noscroll

	call	Mono_Scroll C,1
	dec	[ypos]

??noscroll:
	jmp	short ??charloop

??fini:
	cmp	[update],0
	jne	short ??noupdate

	call	Mono_Set_Cursor

??noupdate:
	pop	eax
	pop	eax
	ret

	ENDP	_Mono_Text_Print


;****************************************************************************
;*
;* NAME
;*     Mono_Text_Print - Print a string to the mono screen. (ASM call)
;*
;* SYNOPSIS
;*     Mono_Text_Print(String, X, Y, Attributes)
;*
;*     void Mono_Text_Print(char *, long, long, long);
;*
;* FUNCTION
;*     Print a NULL terminated string to the mono screen at the specified
;*     cooridinates and attributes.
;*
;* INPUTS
;*     String     - Pointer to NULL terminated string.
;*     X          - X coordinate position.
;*     Y          - Y coordinate position.
;*     Attributes - Display attributes
;*
;* RESULT
;*     NONE
;*
;* SEE ALSO
;*     _Mono_Text_Print
;*
;****************************************************************************

	GLOBAL	C Mono_Text_Print:NEAR
	PROC	Mono_Text_Print C NEAR USES
	ARG	text:NEAR PTR
	ARG	xpos:DWORD
	ARG	ypos:DWORD
	ARG	attrib:DWORD

;	Exit if mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

	call	_Mono_Text_Print C,[text],[xpos],[ypos],[attrib],0

??fini:
	ret

	ENDP	Mono_Text_Print


;****************************************************************************
;*
;* NAME
;*     Mono_Print - Print a string to the mono screen.
;*
;* SYNOPSIS
;*     Mono_Print(String)
;*
;*     void Mono_Print(char *);
;*
;* FUNCTION
;*     Print a string to the mono screen at the current cursor position and
;*     update the cursor position.
;*
;* INPUTS
;*     String - Pointer to NULL terminated string.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Mono_Print:NEAR
	PROC	Mono_Print C NEAR
	ARG	text:NEAR PTR

;	Exit if mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

	call	_Mono_Text_Print C,[text],[MonoX],[MonoY],2,1

??fini:
	ret

	ENDP	Mono_Print


;****************************************************************************
;*
;* NAME
;*     Mono_View_Page - View a mono page.
;*
;* SYNOPSIS
;*     Oldpage = Mono_View_Page(Page)
;*
;*     long Mono_View_Page(long);
;*
;* FUNCTION
;*     Displays the specified page in displayable mono memory.
;*
;* INPUTS
;*     Page - Page to view.
;*
;* RESULT
;*     Oldpage - Previous page.
;*
;****************************************************************************

	GLOBAL	C Mono_View_Page:NEAR
	PROC	Mono_View_Page C NEAR USES ds es eax ebx ecx edi esi
	ARG	page:DWORD
	LOCAL	oldpage:DWORD

;	Prepare the original page number for return to caller.

	cld
	mov	ebx,[PageMap]
	mov	[oldpage],ebx

;	Exit of mono disabled

	cmp	[MonoEnabled],0
	je	short ??fini

;	If the desired page is already displayed, then don't do anything.

	mov	eax,[page]
	cmp	eax,ebx
	je	short ??fini

;	Verify that page specified is legal.

	cmp	eax,7
	ja	short ??fini

;	Find where the logical page to display is actually located.

	mov	ecx,8
	push	ds
	pop	es
	lea	edi,[PageMap]
	repne	scasw
	neg	ecx
	add	ecx,7		; CX = where desired page is located.

;	Swap the page ID bytes in the PageMap array.

	sub	edi,4
	mov	ebx,[PageMap]
	mov	eax,[edi]
	mov	[edi],ebx
	mov	[PageMap],eax

	shl	ecx,8
	add	ecx,eax
	mov	esi,ecx

	IF	PHARLAP_TNT
	mov	ax,034h
	mov	ds,ax
	ENDIF

	mov	edi,0B0000h

;	Exchange the two pages.

	mov	ecx,1000H/4

??looper:
	mov	edx,[edi]
	mov	ebx,[esi]
	mov	[edi],ebx
	mov	[esi],edx
	add	esi,4
	add	edi,4
	loop	??looper

;	Return with the original page number.

??fini:
	mov      	eax,[oldpage]
	ret
	
	ENDP	Mono_View_Page

	END

