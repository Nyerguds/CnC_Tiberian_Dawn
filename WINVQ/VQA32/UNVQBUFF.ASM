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
;*     VQAPlay library.
;*
;* FILE
;*     UnVQBuff.asm
;*
;* DESCRIPTION
;*     Buffered VQ decompress/draw routines.
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     Feburary 8, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     UnVQ_2x2 - Draw 2x2 block VQ frame to a buffer.
;*     UnVQ_2x3 - Draw 2x3 block VQ frame to a buffer.
;*     UnVQ_4x2 - Draw 4x2 block VQ frame to a buffer.
;*     UnVQ_4x4 - Draw 4x4 block VQ frame to a buffer.
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


	IF	VQABLOCK_2X2
;****************************************************************************
;*
;* NAME
;*     UnVQ_2x2 - Draw 2x2 block VQ frame to a buffer.
;*
;* SYNOPSIS
;*     UnVQ_2x2(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
;*
;*     void UnVQ_2x2(unsigned char *, unsigned char *, unsigned char *,
;*                        unsigned short, unsigned short, unsigned short);
;*
;* FUNCTION
;*     This function draws an image into the specified buffer from the
;*     pointers and codebook provided. This routine has been optimized for
;*     a 320x200 image.
;*
;* INPUTS
;*     Codebook - Pointer to codebook used to draw image.
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to buffer to draw image into.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*     BufWidth - Width of destination buffer in pixels.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C UnVQ_2x2:NEAR
	PROC	UnVQ_2x2 C NEAR USES ebx ecx edx esi edi

	ARG	codebook:NEAR PTR
	ARG	pointers:NEAR PTR

	IF	PHARLAP_TNT
	ARG	buffer:QWORD	;KLUDGE - bcc32 pads FARPTR
	ELSE
	ARG	buffer:NEAR PTR
	ENDIF

	ARG	blocksperrow:DWORD
	ARG	numrows:DWORD
	ARG	bufwidth:DWORD

	LOCAL	data_end:DWORD
	LOCAL	cb_offset:DWORD
	LOCAL	edi_startval:DWORD
	LOCAL	rowoffset:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	mov	eax,[codebook]		;Adjust the codebook address so
	sub	eax,4		; that the pointer offsets will
	mov	[cb_offset],eax	; point directly at the codeword.

	mov	eax,[bufwidth]		;Compute the offset to the next
	shl	eax,1		; row of blocks.
	mov	[rowoffset],eax

	mov	esi,[pointers]
	mov	eax,[numrows]		;Compute the end address of the
	mul	[blocksperrow]		; pointer data.
	shl	eax,1
	add	eax,esi
	mov	[data_end],eax

	IF	PHARLAP_TNT
	push	es
	les	edi,[FWORD buffer]	;KLUDGE - bcc32 pads FARPTR
	ELSE
	mov	edi,[buffer]
	ENDIF

	mov	[edi_startval],edi

;----------------------------------------------------------------------------
;	Drawing loop
;----------------------------------------------------------------------------

??Start_row:
	mov	ecx,[blocksperrow]	;Number of blocks in a line

??Not_finished_a_line:
	sub	ebx,ebx
	mov	bx,[WORD PTR esi]	;Get the codebook pointer value
	add	esi,2		; then advance to the next one.

	or	bx,bx		;Is it a one color block?
	js	short ??One_color

;	Draw multi-color block

	add	ebx,[cb_offset]	;Codeword address
	mov	eax,[ebx]		;Read codeword
	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],ax		;Write 1st row to dest
	ELSE
	mov	[edi],ax		;Write 1st row to dest
	ENDIF

	shr	eax,16

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],ax	;Write 2nd row to dest
	ELSE
	mov	[edi+ebx],ax		;Write 2nd row to dest
	ENDIF


	add	edi,2		;Next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

;	Draw 1-color block

??One_color:
	cmp	bx,SKIP_PTR		;Is this a skip block?
	jne	??Draw_One_Color

	add	edi,2		;Move to next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line
	jmp	??Next_row

??Draw_One_Color:
	not	bx		;NOT pointer value to get color
	mov	bh,bl		;Duplicate color through the
	mov	ax,bx		; entire dword register.
	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],ax		;Write 1st row to dest
	mov	[es:edi+ebx],ax	;Write 2nd row to dest
	ELSE
	mov	[edi],ax		;Write 1st row to dest
	mov	[edi+ebx],ax		;Write 2nd row to dest
	ENDIF

	add	edi,2		;Next dest block positionw
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

??Next_row:
	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

??End_of_data:
	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	UnVQ_2x2
	ENDIF	;VQABLOCK_2X2


	IF	VQABLOCK_2X3
;****************************************************************************
;*
;* NAME
;*     UnVQ_2x3 - Draw 2x3 block VQ frame to a buffer.
;*
;* SYNOPSIS
;*     UnVQ_2x3(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
;*
;*     void UnVQ_2x3(unsigned char *, unsigned char *, unsigned char *,
;*                        unsigned short, unsigned short, unsigned short);
;*
;* FUNCTION
;*     This function draws an image into the specified buffer from the
;*     pointers and codebook provided. This routine has been optimized for
;*     a 320x200 image.
;*
;* INPUTS
;*     Codebook - Pointer to codebook used to draw image.
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to buffer to draw image into.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*     BufWidth - Width of destination buffer in pixels.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C UnVQ_2x3:NEAR
	PROC	UnVQ_2x3 C NEAR USES ebx ecx edx esi edi

	ARG	codebook:NEAR PTR
	ARG	pointers:NEAR PTR

	IF	PHARLAP_TNT
	ARG	buffer:QWORD	;KLUDGE - bcc32 pads FARPTR
	ELSE
	ARG	buffer:NEAR PTR
	ENDIF

	ARG	blocksperrow:DWORD
	ARG	numrows:DWORD
	ARG	bufwidth:DWORD

	LOCAL	data_end:DWORD
	LOCAL	cb_offset:DWORD
	LOCAL	edi_startval:DWORD
	LOCAL	rowoffset:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	mov	eax,[codebook]		;Adjust the codebook address so
	sub	eax,4		; that the pointer offsets will
	mov	[cb_offset],eax	; point directly at the codeword.

	mov	eax,[bufwidth]		;Compute the offset to the next
	shl	eax,1		; row of blocks.
	add	eax,[bufwidth]
	mov	[rowoffset],eax

	mov	esi,[pointers]
	mov	eax,[numrows]		;Compute the end address of the
	mul	[blocksperrow]		; pointer data.
	shl	eax,1
	add	eax,esi
	mov	[data_end],eax

	IF	PHARLAP_TNT
	push	es
	les	edi,[FWORD buffer]	;KLUDGE - bcc32 pads FARPTR
	ELSE
	mov	edi,[buffer]
	ENDIF

	mov	[edi_startval],edi

;----------------------------------------------------------------------------
;	Drawing loop
;----------------------------------------------------------------------------

??Start_row:
	mov	ecx,[blocksperrow]	;Number of blocks in a line

??Not_finished_a_line:
	sub	ebx,ebx
	mov	bx,[WORD PTR esi]	;Get the codebook pointer value
	add	esi,2		; then advance to the next one.

	or	bx,bx		;Is it a one color block?
	js	short ??One_color

;	Draw multi-color block

	add	ebx,[cb_offset]	;Codeword address
	mov	eax,[ebx]		;Read 1st row of codeword
	mov	dx,[ebx+4]		;Read 2nd row of codeword
	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],ax		;Write 1st row to dest
	ELSE
	mov	[edi],ax		;Write 1st row to dest
	ENDIF

	shr	eax,16

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],ax	;Write 2nd row to dest
	ELSE
	mov	[edi+ebx],ax		;Write 2nd row to dest
	ENDIF

	add	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],dx
	ELSE
	mov	[edi+ebx],dx
	ENDIF

	add	edi,2		;Next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

;	Draw 1-color block

??One_color:
	cmp	bx,SKIP_PTR		;Is this a skip block?
	jne	??Draw_One_Color

	add	edi,2		;Move to next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line
	jmp	??Next_row

??Draw_One_Color:
	not	bx		;NOT pointer value to get color
	mov	bh,bl		;Duplicate color through the
	mov	ax,bx		; entire dword register.
	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],ax		;Write 1st row to dest
	mov	[es:edi+ebx],ax	;Write 2nd row to dest
	ELSE
	mov	[edi],ax		;Write 1st row to dest
	mov	[edi+ebx],ax		;Write 2nd row to dest
	ENDIF

	add	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],ax	;Write 2rd row to dest
	ELSE
	mov	[edi+ebx],ax		;Write 2rd row to dest
	ENDIF

	add	edi,2		;Next dest block positionw
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

??Next_row:
	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

??End_of_data:
	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	UnVQ_2x3
	ENDIF	;VQABLOCK_2X3


	IF	VQABLOCK_4X2
;****************************************************************************
;*
;* NAME
;*     UnVQ_4x2 - Draw 4x2 block VQ frame to a buffer.
;*
;* SYNOPSIS
;*     UnVQ_4x2(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
;*
;*     void UnVQ_4x2(unsigned char *, unsigned char *, unsigned char *,
;*                        long, long, long);
;*
;* FUNCTION
;*     This function draws an image into the specified buffer from the
;*     pointers and codebook provided. This routine has been optimized for
;*     a 320x200 image.
;*
;* INPUTS
;*     Codebook - Pointer to codebook used to draw image.
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to buffer to draw image into.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*     BufWidth - Width of destination buffer in pixels.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

;;;	GLOBAL	C UnVQ_4x2:NEAR
;;;	PROC	UnVQ_4x2 C NEAR USES ebx ecx edx esi edi
;;;
;;;	ARG	codebook:NEAR PTR
;;;	ARG	pointers:NEAR PTR
;;;
;;;	IF	PHARLAP_TNT
;;;	ARG	buffer:QWORD	;KLUDGE - bcc32 pads FARPTR
;;;	ELSE
;;;	ARG	buffer:NEAR PTR
;;;	ENDIF
;;;
;;;	ARG	blocksperrow:DWORD
;;;	ARG	numrows:DWORD
;;;	ARG	bufwidth:DWORD
;;;
;;;	LOCAL	data_end:DWORD
;;;	LOCAL	cb_offset:DWORD
;;;	LOCAL	edi_startval:DWORD
;;;	LOCAL	rowoffset:DWORD
;;;
;;;;----------------------------------------------------------------------------
;;;;	Initialize
;;;;----------------------------------------------------------------------------
;;;
;;;	mov	eax,[codebook]		;Adjust the codebook address so
;;;	sub	eax,4		; that the pointer offsets will
;;;	mov	[cb_offset],eax	; point directly at the codeword.
;;;
;;;	mov	eax,[bufwidth]		;Compute the offset to the next
;;;	shl	eax,1		; row of blocks.
;;;	mov	[rowoffset],eax
;;;
;;;	mov	esi,[pointers]
;;;	mov	eax,[numrows]		;Compute the end address of the
;;;	mul	[blocksperrow]		; pointer data.
;;;	shl	eax,1
;;;	add	eax,esi
;;;	mov	[data_end],eax
;;;
;;;	IF	PHARLAP_TNT
;;;	push	es
;;;	les	edi,[FWORD buffer]	;KLUDGE - bcc32 pads FARPTR
;;;	ELSE
;;;	mov	edi,[buffer]
;;;	ENDIF
;;;
;;;	mov	[edi_startval],edi
;;;
;;;;----------------------------------------------------------------------------
;;;;	Drawing loop
;;;;----------------------------------------------------------------------------
;;;
;;;??Start_row:
;;;	mov	ecx,[blocksperrow]	;Number of blocks in a line
;;;
;;;??Not_finished_a_line:
;;;	sub	ebx,ebx
;;;	mov	bx,[WORD PTR esi]	;Get the codebook pointer value
;;;	add	esi,2		; then advance to the next one.
;;;
;;;	or	bx,bx		;Is it a one color block?
;;;	js	short ??One_color
;;;
;;;;	Draw multi-color block
;;;
;;;	add	ebx,[cb_offset]	;Codeword address
;;;	mov	eax,[ebx]		;Read 1st row of codeword
;;;	mov	edx,[ebx+4]		;Read 2nd row of codeword
;;;	mov	ebx,[bufwidth]
;;;
;;;	IF	PHARLAP_TNT
;;;	mov	[es:edi],eax		;Write 1st row to dest
;;;	mov	[es:edi+ebx],edx	;Write 2nd row to dest
;;;	ELSE
;;;	mov	[edi],eax		;Write 1st row to dest
;;;	mov	[edi+ebx],edx		;Write 2nd row to dest
;;;	ENDIF
;;;
;;;	add	edi,4		;Next dest block position
;;;	dec	ecx		;More blocks for this row?
;;;	jnz	short ??Not_finished_a_line
;;;
;;;;	Advance to the next destination row of blocks.
;;;
;;;	mov	edi,[edi_startval]
;;;	add	edi,[rowoffset]
;;;	mov	[edi_startval],edi
;;;
;;;	cmp	esi,[data_end]		;Have we reached the end of the
;;;	jnb	short ??End_of_data	; pointers buffer?
;;;	jmp	??Start_row
;;;
;;;;	Draw 1-color block
;;;
;;;??One_color:
;;;	cmp	bx,SKIP_PTR		;Is this a skip block?
;;;	jne	??Draw_One_Color
;;;
;;;	add	edi,4		;Move to next dest block position
;;;	dec	ecx		;More blocks for this row?
;;;	jnz	short ??Not_finished_a_line
;;;	jmp	??Next_row
;;;
;;;??Draw_One_Color:
;;;	not	bx		;NOT pointer value to get color
;;;	mov	bh,bl		;Duplicate color through the
;;;	mov	ax,bx		; entire dword register.
;;;	rol	eax,16
;;;	mov	ax,bx
;;;	mov	ebx,[bufwidth]
;;;
;;;	IF	PHARLAP_TNT
;;;	mov	[es:edi],eax		;Write 1st row to dest
;;;	mov	[es:edi+ebx],eax	;Write 2nd row to dest
;;;	ELSE
;;;	mov	[edi],eax		;Write 1st row to dest
;;;	mov	[edi+ebx],eax		;Write 2nd row to dest
;;;	ENDIF
;;;
;;;	add	edi,4		;Next dest block positionw
;;;	dec	ecx		;More blocks for this row?
;;;	jnz	short ??Not_finished_a_line
;;;
;;;;	Advance to the next destination row of blocks.
;;;
;;;??Next_row:
;;;	mov	edi,[edi_startval]
;;;	add	edi,[rowoffset]
;;;	mov	[edi_startval],edi
;;;
;;;	cmp	esi,[data_end]		;Have we reached the end of the
;;;	jnb	short ??End_of_data	; pointers buffer?
;;;	jmp	??Start_row
;;;
;;;??End_of_data:
;;;	IF	PHARLAP_TNT
;;;	pop	es
;;;	ENDIF
;;;
;;;	ret
;;;
;;;	ENDP	UnVQ_4x2
;;;	ENDIF	;VQABLOCK_4X2

	GLOBAL	C UnVQ_4x2:NEAR
	PROC	UnVQ_4x2 C NEAR USES ebx ecx edx esi edi

	ARG	codebook:NEAR PTR
	ARG	pointers:NEAR PTR
	ARG	buffer:NEAR PTR
	ARG	blocksperrow:DWORD
	ARG	numrows:DWORD
	ARG	bufwidth:DWORD

	LOCAL	data_end:DWORD
	LOCAL	cb_offset:DWORD
	LOCAL	edi_startval:DWORD
	LOCAL	rowoffset:DWORD
	LOCAL	entries:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	mov	eax,[codebook]		;Adjust the codebook address so
;	sub	eax,4		; that the pointer offsets will
	mov	[cb_offset],eax	; point directly at the codeword.

	mov	eax,[bufwidth]		;Compute the offset to the next
	shl	eax,1		; row of blocks.
	mov	[rowoffset],eax

	mov	esi,[pointers]
	mov	eax,[numrows]		;Compute the end address of the
	mul	[blocksperrow]		; pointer data.
	mov	[entries],eax
	add	eax,esi
	mov	[data_end],eax

	mov	edi,[buffer]
	mov	[edi_startval],edi

;----------------------------------------------------------------------------
;	Drawing loop
;----------------------------------------------------------------------------

??Start_row:
	mov	ecx,[blocksperrow]	;Number of blocks in a line

??Not_finished_a_line:
	mov	eax,[entries]
	xor	ebx,ebx
	mov	bl,[esi]
	mov	bh,[esi + eax]	;Get the codebook pointer value
	inc	esi		; then advance to the next one.

	cmp	bh,00Fh		;Is it a one color block?
	je	short ??One_color

;	Draw multi-color block

	shl	ebx,3
	add	ebx,[cb_offset]	;Codeword address
	mov	eax,[ebx]		;Read 1st row of codeword
	mov	edx,[ebx+4]		;Read 2nd row of codeword
	mov	ebx,[bufwidth]
	mov	[edi],eax		;Write 1st row to dest
	mov	[edi+ebx],edx		;Write 2nd row to dest

	add	edi,4		;Next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

;	Draw 1-color block

??One_color:
;	cmp	bx,SKIP_PTR		;Is this a skip block?
;	jne	??Draw_One_Color
;
;	add	edi,4		;Move to next dest block position
;	dec	ecx		;More blocks for this row?
;	jnz	short ??Not_finished_a_line
;	jmp	??Next_row

??Draw_One_Color:
;	not	bx		;NOT pointer value to get color
	mov	bh,bl		;Duplicate color through the
	mov	ax,bx		; entire dword register.
	rol	eax,16
	mov	ax,bx
	mov	ebx,[bufwidth]
	mov	[edi],eax		;Write 1st row to dest
	mov	[edi+ebx],eax		;Write 2nd row to dest

	add	edi,4		;Next dest block positionw
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

??Next_row:
	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

??End_of_data:
	ret

	ENDP	UnVQ_4x2
	ENDIF	;VQABLOCK_4X2


	IF	VQABLOCK_4X4
;****************************************************************************
;*
;* NAME
;*     UnVQ_4x4 - Draw 4x4 block VQ frame to a buffer.
;*
;* SYNOPSIS
;*     UnVQ_4x4(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
;*
;*     void UnVQ_4x4(unsigned char *, unsigned char *, unsigned char *,
;*                        unsigned short, unsigned short, unsigned short);
;*
;* FUNCTION
;*     This function draws an image into the specified buffer from the
;*     pointers and codebook provided. This routine has been optimized for
;*     a 320x200 image.
;*
;* INPUTS
;*     Codebook - Pointer to codebook used to draw image.
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to buffer to draw image into.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*     BufWidth - Width of destination buffer in pixels.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C UnVQ_4x4:NEAR
	PROC	UnVQ_4x4 C NEAR USES ebx ecx edx esi edi

	ARG	codebook:NEAR PTR
	ARG	pointers:NEAR PTR

	IF	PHARLAP_TNT
	ARG	buffer:QWORD	;KLUDGE - bcc32 pads FARPTR
	ELSE
	ARG	buffer:NEAR PTR
	ENDIF

   	ARG	blocksperrow:DWORD
   	ARG	numrows:DWORD
   	ARG	bufwidth:DWORD

   	LOCAL	data_end:DWORD
      	LOCAL	edi_startval:DWORD
      	LOCAL	rowoffset:DWORD
      	LOCAL	entries:DWORD

      ;----------------------------------------------------------------------------
      ;	Initialize
      ;----------------------------------------------------------------------------

      	mov	eax,[bufwidth]		;Compute the offset to the next
      	shl	eax,2		; row of blocks
      	mov	[rowoffset],eax

      	mov	esi,[pointers]
      	mov	eax,[numrows]		;Compute the end address of the
      	mul	[blocksperrow]		; pointer data.
      	mov	[entries],eax
      	add	eax,esi
      	mov	[data_end],eax

      	IF	PHARLAP_TNT
      	push	es
      	les	edi,[FWORD buffer]	;KLUDGE - bcc32 pads FARPTR
      	ELSE
      	mov	edi,[buffer]
      	ENDIF

      	mov	[edi_startval],edi

      ;----------------------------------------------------------------------------
      ;	Drawing loop
      ;----------------------------------------------------------------------------

      ??Start_row:
      	mov	ecx,[blocksperrow]	;Number of blocks in a line

      ??Not_finished_a_line:
      	mov	eax,[entries]
      	xor	ebx,ebx
      	mov	bh,[esi + eax]	;Get the codebook pointer value
      	mov	bl,[esi]
      	inc	esi		; then advance to the next one.

      	cmp	bh,0FFh		;Is it a one color block?
      	je	short ??One_color

      ;	Draw multi-color block

      	shl	ebx,4
      	add	ebx,[codebook]	;Codeword address
      	mov	eax,[ebx]		;Read 1st row of codeword
      	mov	edx,[ebx+4]		;Read 2nd row of codeword

      	IF	PHARLAP_TNT
      	mov	[es:edi],eax		;Write 1st row to dest
      	ELSE
      	mov	[edi],eax		;Write 1st row to dest
      	ENDIF

      	mov	eax,ebx
   	mov	ebx,[bufwidth]

   	IF	PHARLAP_TNT
   	mov	[es:edi+ebx],edx	;Write 2nd row to dest
   	ELSE
   	mov	[edi+ebx],edx		;Write 2nd row to dest
	ENDIF

	mov	ebx,eax
	mov	eax,[ebx+8]
	mov	edx,[ebx+12]
	mov	ebx,[bufwidth]
	shl	ebx,1

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],eax	;Write 2nd row to dest
	ELSE
	mov	[edi+ebx],eax		;Write 2nd row to dest
	ENDIF

	add	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi+ebx],edx	;Write 2nd row to dest
	ELSE
	mov	[edi+ebx],edx		;Write 2nd row to dest
	ENDIF

	add	edi,4		;Next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line

;	Advance to the next destination row of blocks.

	mov	edi,[edi_startval]
	add	edi,[rowoffset]
	mov	[edi_startval],edi

	cmp	esi,[data_end]		;Have we reached the end of the
	jnb	short ??End_of_data	; pointers buffer?
	jmp	??Start_row

;	Draw 1-color block

??One_color:
;	cmp	bx,SKIP_PTR		;Is this a skip block?
;	jne	??Draw_One_Color
;
;	add	edi,4		;Move to next dest block position
;	dec	ecx		;More blocks for this row?
;	jnz	short ??Not_finished_a_line
;	jmp	??Next_row

??Draw_One_Color:
;	not	bx		;NOct color
	mov	bh,bl		;Duplicate color through the
	mov	ax,bx		; entire dword register.
	rol	eax,16
	mov	ax,bx
;	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],eax		;Write 1st row to dest
	mov	ebx,[bufwidth]
	mov	[es:edi+ebx],eax	;Write 2nd row to dest
	ELSE
	mov	[edi],eax		;Write 1st row to dest
	mov	ebx,[bufwidth]
	mov	[edi+ebx],eax		;Write 2nd row to dest
   	ENDIF

   	add	ebx,[bufwidth]

   	IF	PHARLAP_TNT
   	mov	[es:edi+ebx],eax	;Write 3rd row to dest
   	ELSE
   	mov	[edi+ebx],eax		;Write 3rd row to dest
   	ENDIF

   	add	ebx,[bufwidth]

   	IF	PHARLAP_TNT
   	mov	[es:edi+ebx],eax	;Write 4th row to dest
   	ELSE
   	mov	[edi+ebx],eax		;Write 4th row to dest
   	ENDIF

   	add	edi,4		;Next dest block positionw
      	dec	ecx		;More blocks for this row?
      	jnz	??Not_finished_a_line

      ;	Advance to the next destination row of blocks.

      ??Next_row:
      	mov	edi,[edi_startval]
      	add	edi,[rowoffset]
      	mov	[edi_startval],edi

      	cmp	esi,[data_end]		;Have we reached the end of the
      	jnb	short ??End_of_data	; pointers buffer?
      	jmp	??Start_row

      ??End_of_data:
      	IF	PHARLAP_TNT
      	pop	es
      	ENDIF

         	ret

         	ENDP	UnVQ_4x4
         	ENDIF	;VQABLOCK_4X4



         	IF	VQABLOCK_WOOFER
         	IF	VQABLOCK_4X2
         ;****************************************************************************
         ;*
         ;* NAME
         ;*     UnVQ_4x2_Woofer - Draw 4x2 block VQ frame to a buffer.
         ;*
         ;* SYNOPSIS
         ;*     UnVQ_4x2_Woofer(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
         ;*
         ;*     void UnVQ_4x2_Woofer(unsigned char *, unsigned char *,
         ;*                          unsigned char *, long, long, long);
         ;*
         ;* FUNCTION
         ;*     This function draws an image into the specified buffer from the
         ;*     pointers and codebook provided. This routine has been optimized for
         ;*     a 320x200 image.
         ;*
         ;* INPUTS
         ;*     Codebook - Pointer to codebook used to draw image.
         ;*     Pointers - Pointer to vector pointer data.
         ;*     Buffer   - Pointer to buffer to draw image into.
         ;*     BPR      - Number of blocks per row.
         ;*     Rows     - Number of rows.
         ;*     BufWidth - Width of destination buffer in pixels.
         ;*
         ;* RESULT
         ;*     NONE
         ;*
         ;****************************************************************************

         	GLOBAL	C UnVQ_4x2_Woofer:NEAR
         	PROC	UnVQ_4x2_Woofer C NEAR USES ebx ecx edx esi edi

         	ARG	codebook:NEAR PTR
         	ARG	pointers:NEAR PTR

         	IF	PHARLAP_TNT
         	ARG	buffer:QWORD	;KLUDGE - bcc32 pads FARPTR
         	ELSE
         	ARG	buffer:NEAR PTR
         	ENDIF

         	ARG	blocksperrow:DWORD
         	ARG	numrows:DWORD
      	ARG	bufwidth:DWORD

      	LOCAL	data_end:DWORD
      	LOCAL	cb_offset:DWORD
      	LOCAL	edi_startval:DWORD
      	LOCAL	rowoffset:DWORD
      	LOCAL	entries:DWORD

      ;----------------------------------------------------------------------------
      ;	Initialize
      ;----------------------------------------------------------------------------

      	mov	eax,[codebook]		;Adjust the codebook address so
      ;	sub	eax,4		; that the pointer offsets will
      	mov	[cb_offset],eax	; point directly at the codeword.

      	mov	eax,[bufwidth]		;Compute the offset to the next
      	shl	eax,1		; row of blocks.
      	mov	[rowoffset],eax

      	mov	esi,[pointers]
      	mov	eax,[numrows]		;Compute the end address of the
      	mul	[blocksperrow]		; pointer data.
      	mov	[entries],eax
      ;	shl	eax,1
      	add	eax,esi
      	mov	[data_end],eax

      	IF	PHARLAP_TNT
      	push	es
      	les	edi,[FWORD buffer]	;KLUDGE - bcc32 pads FARPTR
      	ELSE
      	mov	edi,[buffer]
      	ENDIF

      	mov	[edi_startval],edi

      ;----------------------------------------------------------------------------
      ;	Drawing loop
      ;----------------------------------------------------------------------------

      ??Start_row:
      	mov	ecx,[blocksperrow]	;Number of blocks in a line

      ??Not_finished_a_line:
      	mov	eax,[entries]
      	xor	ebx,ebx
      ;	mov	bx,[WORD PTR esi]	;Get the codebook pointer value
      ;	add	esi,2		; then advance to the next one.
      	mov	bl,[esi]
      	mov	bh,[esi + eax]
      	inc	esi

      ;	or	bx,bx		;Is it a one color block?
      ;	js	short ??One_color

      	cmp	bh,00Fh
      	je	short ??One_color

      ;	Draw multi-color block

      	shl	ebx,3

      	add	ebx,[cb_offset]	;Codeword address
      	mov	eax,[ebx]		;Read 1st row of codeword
      	mov	edx,[ebx+4]		;Read 2nd row of codeword
      	mov	ebx,[bufwidth]

      	IF	PHARLAP_TNT
      	mov	[es:edi],al		;Write 1st row to dest
      	shr	eax,16
      	mov	[es:edi+2],al
      	mov	[es:edi+ebx+1],dh		;Write 1st row to dest
      	shr	edx,16
      	mov	[es:edi+ebx+3],dh
      	ELSE
      	mov	[edi],al		;Write 1st row to dest
      	shr	eax,16
      	mov	[edi+2],al
      	mov	[edi+ebx+1],dh		;Write 1st row to dest
      	shr	edx,16
      	mov	[edi+ebx+3],dh
      	ENDIF

      	add	edi,4		;Next dest block position
      	dec	ecx		;More blocks for this row?
      	jnz	short ??Not_finished_a_line

      ;	Advance to the next destination row of blocks.

      	mov	edi,[edi_startval]
      	add	edi,[rowoffset]
      	mov	[edi_startval],edi

      	cmp	esi,[data_end]		;Have we reached the end of the
      	jnb	short ??End_of_data	; pointers buffer?
      	jmp	??Start_row

      ;	Draw 1-color block

      ??One_color:
      ;	cmp	bx,SKIP_PTR		;Is this a skip block?
      ;	jne	??Draw_One_Color

      ;	add	edi,4		;Move to next dest block position
      ;	dec	ecx		;More blocks for this row?
      ;	jnz	short ??Not_finished_a_line
      ;	jmp	??Next_row

      ??Draw_One_Color:
      ;	not	bx		;NOT pointer value to get color
      	mov	al,bl
      	mov	ebx,[bufwidth]

      	IF	PHARLAP_TNT
      	mov	[es:edi],al
      	mov	[es:edi+2],al
      	mov	[es:edi+ebx+1],al	;Write 2nd row to dest
      	mov	[es:edi+ebx+3],al	;Write 2nd row to dest
      	ELSE
      	mov	[edi],al
      	mov	[edi+2],al
      	mov	[edi+ebx+1],al		;Write 2nd row to dest
      	mov	[edi+ebx+3],al		;Write 2nd row to dest
      	ENDIF

      	add	edi,4		;Next dest block positionw
      	dec	ecx		;More blocks for this row?
      	jnz	??Not_finished_a_line

      ;	Advance to the next destination row of blocks.

      ??Next_row:
      	mov	edi,[edi_startval]
      	add	edi,[rowoffset]
      	mov	[edi_startval],edi

      	cmp	esi,[data_end]		;Have we reached the end of the
      	jnb	short ??End_of_data	; pointers buffer?
      	jmp	??Start_row

      ??End_of_data:
      	IF	PHARLAP_TNT
      	pop	es
      	ENDIF

      	ret

      	ENDP	UnVQ_4x2_Woofer
      	ENDIF	;VQABLOCK_4X2
      	ENDIF	;VQABLOCK_WOOFER

      	END

