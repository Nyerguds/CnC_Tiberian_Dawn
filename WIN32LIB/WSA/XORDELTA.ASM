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

; **************************************************************************
; **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   *
; **************************************************************************
; *                                                                        *
; *                 Project Name : WSA Support routines			   *
; *                                                                        *
; *                    File Name : XORDELTA.ASM                            *
; *                                                                        *
; *                   Programmer : Scott K. Bowen			   *
; *                                                                        *
; *                  Last Update :May 23, 1994   [SKB]                     *
; *                                                                        *
; *------------------------------------------------------------------------*
; * Functions:                                                             *
;*   Apply_XOR_Delta -- Apply XOR delta data to a buffer.                  *
;*   Apply_XOR_Delta_To_Page_Or_Viewport -- Calls the copy or the XOR funti*
;*   Copy_Delta_buffer -- Copies XOR Delta Data to a section of a page.    *
;*   XOR_Delta_Buffer -- Xor's the data in a XOR Delta format to a page.   *
; * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*

IDEAL
P386
MODEL USE32 FLAT




LOCALS ??

; These are used to call Apply_XOR_Delta_To_Page_Or_Viewport() to setup flags parameter.  If
; These change, make sure and change their values in wsa.cpp.
DO_XOR		equ	0
DO_COPY		equ	1
TO_VIEWPORT	equ	0
TO_PAGE		equ	2

;
; Routines defined in this module
;
;
; UWORD Apply_XOR_Delta(UWORD page_seg, BYTE *delta_ptr);
; PUBLIC Apply_XOR_Delta_To_Page_Or_Viewport(UWORD page_seg, BYTE *delta_ptr, WORD width, WORD copy)
;
;	PROC	C XOR_Delta_Buffer
;	PROC	C Copy_Delta_Buffer
;

GLOBAL 	C Apply_XOR_Delta:NEAR
GLOBAL 	C Apply_XOR_Delta_To_Page_Or_Viewport:NEAR



	CODESEG



;***************************************************************************
;* APPLY_XOR_DELTA -- Apply XOR delta data to a linear buffer.             *
;*   AN example of this in C is at the botton of the file commented out.   *
;*                                                                         *
;* INPUT:  BYTE *target - destination buffer.                              *
;*         BYTE *delta - xor data to be delta uncompress.                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   05/23/1994 SKB : Created.                                             *
;*=========================================================================*
PROC	Apply_XOR_Delta C near
	USES 	ebx,ecx,edx,edi,esi
	ARG	target:DWORD 		; pointers.
	ARG	delta:DWORD		; pointers.

	; Optimized for 486/pentium by rearanging instructions.
	mov	edi,[target]		; get our pointers into offset registers.
	mov	esi,[delta]

	cld				; make sure we go forward
	xor	ecx,ecx			; use cx for loop

??top_loop:
	xor	eax,eax			; clear out eax.
	mov	al,[esi]		; get delta source byte
	inc	esi

	test	al,al			; check for a SHORTDUMP ; check al incase of sign value.
	je	??short_run
	js	??check_others

;
; SHORTDUMP
;
	mov	ecx,eax			; stick count in cx

??dump_loop:
	mov	al,[esi]		;get delta XOR byte
	xor	[edi],al		; xor that byte on the dest
	inc	esi
	inc	edi
	dec	ecx
	jnz	??dump_loop
	jmp	??top_loop

;
; SHORTRUN
;

??short_run:
	mov	cl,[esi]		; get count
	inc	esi			; inc delta source

??do_run:
	mov	al,[esi]		; get XOR byte
	inc	esi

??run_loop:
	xor	[edi],al		; xor that byte.

	inc	edi			; go to next dest pixel
	dec	ecx			; one less to go.
	jnz	??run_loop
	jmp	??top_loop

;
; By now, we know it must be a LONGDUMP, SHORTSKIP, LONGRUN, or LONGSKIP
;

??check_others:
	sub	eax,080h		; opcode -= 0x80
	jnz	??do_skip		; if zero then get next word, otherwise use remainder.

	mov	ax,[esi]
	lea	esi,[esi+2]		; get word code in ax
	test	ax,ax			; set flags. (not 32bit register so neg flag works)
	jle	??not_long_skip

;
; SHORTSKIP AND LONGSKIP
;
??do_skip:
	add	edi,eax			; do the skip.
	jmp	??top_loop


??not_long_skip:
	jz	??stop			; long count of zero means stop
	sub	eax,08000h     		; opcode -= 0x8000
	test	eax,04000h		; is it a LONGRUN (code & 0x4000)?
	je	??long_dump

;
; LONGRUN
;
	sub	eax,04000h		; opcode -= 0x4000
	mov	ecx,eax			; use cx as loop count
	jmp	??do_run		; jump to run code.


;
; LONGDUMP
;

??long_dump:
	mov	ecx,eax			; use cx as loop count
	jmp	??dump_loop		; go to the dump loop.

??stop:

	ret

	ENDP	Apply_XOR_Delta


;----------------------------------------------------------------------------


;***************************************************************************
;* APPLY_XOR_DELTA_To_Page_Or_Viewport -- Calls the copy or the XOR funtion.           *
;*                                                                         *
;*									   *
;* 	This funtion is call to either xor or copy XOR_Delta data onto a   *
;*	page instead of a buffer.  The routine will set up the registers   *
;*	need for the actual routines that will perform the copy or xor.	   *
;*									   *
;*	The registers are setup as follows :				   *
;*		es:edi - destination segment:offset onto page.		   *
;*		ds:esi - source buffer segment:offset of delta data.	   *
;*		dx,cx,ax - are all zeroed out before entry.		   *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/09/1992  SB : Created.                                             *
;*=========================================================================*

;PUBLIC Apply_XOR_Delta_To_Page_Or_Viewport(UWORD page_seg, BYTE *delta_ptr, WORD width, WORD flags, WORD descriptor)
PROC	Apply_XOR_Delta_To_Page_Or_Viewport C near
	USES 	ebx,ecx,edx,edi,esi
	ARG	target:DWORD		; pointer to the destination buffer.
	ARG	delta:DWORD		; pointer to the delta buffer.
	ARG	width:DWORD		; width of animation.
	ARG	nextrow:DWORD		; Page/Buffer width - anim width.
	ARG	copy:DWORD		; should it be copied or xor'd?


	mov	edi,[target]		; Get the target pointer.
	mov	esi,[delta]		; Get the destination pointer.

	xor	eax,eax			; clear eax, later put them into ecx and edx.

	cld				; make sure we go forward

	mov	ebx,[nextrow]		; get the amount to add to get to next row from end.  push it later...

	mov	ecx,eax			; use cx for loop
	mov	edx,eax			; use dx to count the relative column.

	push	ebx			; push nextrow onto the stack for Copy/XOR_Delta_Buffer.
	mov	ebx,[width]		; bx will hold the max column for speed compares

; At this point, all the registers have been set up.  Now call the correct function
; to either copy or xor the data.

	cmp	[copy],DO_XOR		; Do we want to copy or XOR
	je	??xorfunct		; Jump to XOR if not copy
	call	Copy_Delta_Buffer	; Call the function to copy the delta buffer.
	jmp	??didcopy		; jump past XOR
??xorfunct:
	call	XOR_Delta_Buffer	; Call funtion to XOR the deltat buffer.
??didcopy:
	pop	ebx			; remove the push done to pass a value.

	ret

	ENDP	Apply_XOR_Delta_To_Page_Or_Viewport
;----------------------------------------------------------------------------


;***************************************************************************
;* XOR_DELTA_BUFFER -- Xor's the data in a XOR Delta format to a page.     *
;*	This will only work right if the page has the previous data on it. *
;*	This function should only be called by XOR_Delta_Buffer_To_Page_Or_Viewport.   *
;*      The registers must be setup as follows :                           *
;*                                                                         *
;* INPUT:                                                                  *
;*	es:edi - destination segment:offset onto page.		 	   *
;*	ds:esi - source buffer segment:offset of delta data.	 	   *
;*	edx,ecx,eax - are all zeroed out before entry.		 	   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/09/1992  SB : Created.                                             *
;*=========================================================================*

PROC	XOR_Delta_Buffer C near
	ARG	nextrow:DWORD

??top_loop:
	xor	eax,eax			; clear out eax.
	mov	al,[esi]		; get delta source byte
	inc	esi

	test	al,al			; check for a SHORTDUMP ; check al incase of sign value.
	je	??short_run
	js	??check_others

;
; SHORTDUMP
;
	mov	ecx,eax			; stick count in cx

??dump_loop:
	mov	al,[esi]		; get delta XOR byte
	xor	[edi],al		; xor that byte on the dest
	inc	esi
	inc	edx			; increment our count on current column
	inc	edi
	cmp	edx,ebx			; are we at the final column
	jne	??end_col1		; if not the jmp over the code

	sub	edi,edx			; get our column back to the beginning.
	xor	edx,edx			; zero out our column counter
	add	edi,[nextrow]		; jump to start of next row
??end_col1:

	dec	ecx
	jnz	??dump_loop
	jmp	??top_loop

;
; SHORTRUN
;

??short_run:
	mov	cl,[esi]		; get count
	inc	esi			; inc delta source

??do_run:
	mov	al,[esi]		; get XOR byte
	inc	esi

??run_loop:
	xor	[edi],al		; xor that byte.

	inc	edx			; increment our count on current column
	inc	edi			; go to next dest pixel
	cmp	edx,ebx			; are we at the final column
	jne	??end_col2		; if not the jmp over the code

	sub	edi,ebx			; get our column back to the beginning.
	xor	edx,edx			; zero out our column counter
	add	edi,[nextrow]		; jump to start of next row
??end_col2:


	dec	ecx
	jnz	??run_loop
	jmp	??top_loop

;
; By now, we know it must be a LONGDUMP, SHORTSKIP, LONGRUN, or LONGSKIP
;

??check_others:
	sub	eax,080h		; opcode -= 0x80
	jnz	??do_skip		; if zero then get next word, otherwise use remainder.

	mov	ax,[esi]		; get word code in ax
	lea	esi,[esi+2]
	test	ax,ax			; set flags. (not 32bit register so neg flag works)
	jle	??not_long_skip

;
; SHORTSKIP AND LONGSKIP
;
??do_skip:
	sub	edi,edx			; go back to beginning or row.
	add	edx,eax			; incriment our count on current row
??recheck3:
	cmp	edx,ebx			; are we past the end of the row
	jb	??end_col3  		; if not the jmp over the code

	sub	edx,ebx			; Subtract width from the col counter
	add	edi,[nextrow]  		; jump to start of next row
	jmp	??recheck3		; jump up to see if we are at the right row
??end_col3:
	add	edi,edx			; get to correct position in row.
	jmp	??top_loop


??not_long_skip:
	jz	??stop			; long count of zero means stop
	sub	eax,08000h     		; opcode -= 0x8000
	test	eax,04000h		; is it a LONGRUN (code & 0x4000)?
	je	??long_dump

;
; LONGRUN
;
	sub	eax,04000h		; opcode -= 0x4000
	mov	ecx,eax			; use cx as loop count
	jmp	??do_run		; jump to run code.


;
; LONGDUMP
;

??long_dump:
	mov	ecx,eax			; use cx as loop count
	jmp	??dump_loop		; go to the dump loop.

??stop:

	ret


	ENDP	XOR_Delta_Buffer

;----------------------------------------------------------------------------


;***************************************************************************
;* COPY_DELTA_BUFFER -- Copies XOR Delta Data to a section of a page.      *
;*	This function should only be called by XOR_Delta_Buffer_To_Page_Or_Viewport.   *
;*      The registers must be setup as follows :                           *
;*                                                                         *
;* INPUT:                                                                  *
;*	es:edi - destination segment:offset onto page.		 	   *
;*	ds:esi - source buffer segment:offset of delta data.	 	   *
;*	dx,cx,ax - are all zeroed out before entry.		 	   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/09/1992  SB : Created.                                             *
;*=========================================================================*
PROC	Copy_Delta_Buffer C near
	ARG	nextrow:DWORD

??top_loop:
	xor	eax,eax			; clear out eax.
	mov	al,[esi]		; get delta source byte
	inc	esi

	test	al,al			; check for a SHORTDUMP ; check al incase of sign value.
	je	??short_run
	js	??check_others

;
; SHORTDUMP
;
	mov	ecx,eax			; stick count in cx

??dump_loop:
	mov	al,[esi]		; get delta XOR byte

	mov	[edi],al		; store that byte on the dest

	inc	edx			; increment our count on current column
	inc	esi
	inc	edi
	cmp	edx,ebx			; are we at the final column
	jne	??end_col1		; if not the jmp over the code

	sub	edi,edx			; get our column back to the beginning.
	xor	edx,edx			; zero out our column counter
	add	edi,[nextrow]		; jump to start of next row
??end_col1:

	dec	ecx
	jnz	??dump_loop
	jmp	??top_loop

;
; SHORTRUN
;

??short_run:
	mov	cl,[esi]		; get count
	inc	esi			; inc delta source

??do_run:
	mov	al,[esi]		; get XOR byte
	inc	esi

??run_loop:
	mov	[edi],al		; store the byte (instead of XOR against current color)

	inc	edx			; increment our count on current column
	inc	edi			; go to next dest pixel
	cmp	edx,ebx			; are we at the final column
	jne	??end_col2		; if not the jmp over the code

	sub	edi,ebx			; get our column back to the beginning.
	xor	edx,edx			; zero out our column counter
	add	edi,[nextrow]		; jump to start of next row
??end_col2:


	dec	ecx
	jnz	??run_loop
	jmp	??top_loop

;
; By now, we know it must be a LONGDUMP, SHORTSKIP, LONGRUN, or LONGSKIP
;

??check_others:
	sub	eax,080h		; opcode -= 0x80
	jnz	??do_skip		; if zero then get next word, otherwise use remainder.

	mov	ax,[esi]		; get word code in ax
	lea	esi,[esi+2]
	test	ax,ax			; set flags. (not 32bit register so neg flag works)
	jle	??not_long_skip

;
; SHORTSKIP AND LONGSKIP
;
??do_skip:
	sub	edi,edx			; go back to beginning or row.
	add	edx,eax			; incriment our count on current row
??recheck3:
	cmp	edx,ebx			; are we past the end of the row
	jb	??end_col3  		; if not the jmp over the code

	sub	edx,ebx			; Subtract width from the col counter
	add	edi,[nextrow]  		; jump to start of next row
	jmp	??recheck3		; jump up to see if we are at the right row
??end_col3:
	add	edi,edx			; get to correct position in row.
	jmp	??top_loop


??not_long_skip:
	jz	??stop			; long count of zero means stop
	sub	eax,08000h     		; opcode -= 0x8000
	test	eax,04000h		; is it a LONGRUN (code & 0x4000)?
	je	??long_dump

;
; LONGRUN
;
	sub	eax,04000h		; opcode -= 0x4000
	mov	ecx,eax			; use cx as loop count
	jmp	??do_run		; jump to run code.


;
; LONGDUMP
;

??long_dump:
	mov	ecx,eax			; use cx as loop count
	jmp	??dump_loop		; go to the dump loop.

??stop:

	ret

	ENDP	Copy_Delta_Buffer

;----------------------------------------------------------------------------

	END


;----------------------------------------------------------------------------
;
;PUBLIC UWORD Apply_XOR_Delta(UWORD page_seg, BYTE *delta_ptr)
;{
;
;	register UWORD loop;
;	BYTE opcode, xor_byte;
;	UWORD bytes_to_uncompress = 64000U;
;
;
;	/* Make our buffer pointer */
;
;	to    = MK_FP(page_seg, 0);
;	delta = Normalize_Pointer(delta_ptr);
;
;
;	while (bytes_to_uncompress) {
;
;		opcode = *delta++;
;
;
;		/* Check for SHORTDUMP */
;
;		if (opcode > 0) {
;
;
;			bytes_to_uncompress -= opcode;
;
;			for (loop = 0; loop < opcode; loop++) {
;				xor_byte = *delta++;
;				*to++ ^= xor_byte;
;			}
;			continue;
;		}
;
;		/* Check for SHORTRUN */
;
;		if (opcode == 0) {
;
;			word_count = *delta++;
;			xor_byte   = *delta++;
;
;			bytes_to_uncompress -= word_count;
;
;			for (loop = 0; loop < word_count; loop++) {
;				*to++ ^= xor_byte;
;			}
;			continue;
;		}
;
;		/* By now, we know it must be a LONGDUMP, SHORTSKIP, or LONGSKIP */
;
;		opcode -= 0x80;
;
;
;		/* Is it a SHORTSKIP? */
;
;		if (opcode != 0) {
;
;			to += opcode;
;			bytes_to_uncompress -= (WORD) opcode;
;			continue;
;		}
;
;
;		word_count = *((UWORD *) delta)++;
;
;		/* Is it a LONGSKIP? */
;
;		if ((WORD) word_count > 0) {
;
;			to += word_count;
;			bytes_to_uncompress -= (WORD) word_count;
;			continue;
;		}
;
;
;		word_count -= 0x8000;
;
;		/* Is it a LONGRUN? */
;
;		if (word_count & 0x4000) {
;
;			word_count -= 0x4000;
;
;			bytes_to_uncompress -= word_count;
;
;			xor_byte = *delta++;
;
;			for (loop = 0; loop < word_count; loop++) {
;				*to++ ^= xor_byte;
;			}
;			continue;
;		}
;
;
;		/* It must be a LONGDUMP */
;
;		bytes_to_uncompress -= word_count;
;
;		for (loop = 0; loop < word_count; loop++) {
;			xor_byte = *delta++;
;			*to++ ^= xor_byte;
;		}
;	}
;
;
;	return(64000U);
;}
;


