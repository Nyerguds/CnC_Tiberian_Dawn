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
;*     UnVQxmde.asm
;*
;* DESCRIPTION
;*     XMode VQ decompress/draw routines.
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     May 18, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     UnVQ_4x2_Xmode       - Draw 4x2 VQ frame directly to Xmode.
;*     UnVQ_4x2_XmodeCB     - Draw 4x2 VQ frame to Xmode from VRAM codebook.
;*     Upload_4x2CB         - Upload 4x2 codebook into XMode VRAM.
;*     UnVQ_4x2_VESA320_32K - Draw 4x2 VQ frame to VESA320 32k color.
;*     XlatePointers        - Translate pointer to optimal XMode format.
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

	IF	VQAXMODE_ON

SKIP_PTR	EQU	8000h
CBOOK_SEG	EQU	(0B0000h - 270h)


	IF	VQABLOCK_4X2
;****************************************************************************
;*
;* NAME
;*     UnVQ_4x2_Xmode - Draw 4x2 VQ frame directly to Xmode.
;*
;* SYNOPSIS
;*     UnVQ_4x2_Xmode(Codebook, Pointers, Buffer, BPR, Rows, Dummy)
;*
;*     void UnVQ_4x2_Xmode(unsigned char *, unsigned char *, unsigned char *,
;*                         unsigned short, unsigned short, unsigned short);
;*
;* FUNCTION
;*     This function draws an image to the Xmode display from the pointers
;*     and codebook provided. This routine has been optimized for a 320x200
;*     image.
;*
;* INPUTS
;*     Codebook - Pointer to codebook used to draw image.
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to buffer to draw image into.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*     Dummy    - Not used (prototype placeholder)
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C UnVQ_4x2_Xmode:NEAR
	PROC	UnVQ_4x2_Xmode C NEAR USES

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

	SET_PLANE	XPLANE_1

??Start_row:
	mov	ecx,[blocksperrow]	;Number of blocks in a line

??Not_finished_a_line1:
	sub	ebx,ebx
	mov	bx,[WORD PTR esi]	;Get the codebook pointer value
	add	esi,2		; then advance to the next one.

	or	bx,bx		;Is it a one color block?
	js	short ??One_color1

;	Draw multi-color block

	add	ebx,[cb_offset]	;Codeword address
	mov	eax,[ebx]		;Read 1st row of codeword
	mov	edx,[ebx+4]		;Read 2nd row of codeword
;	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],eax		;Write 1st row to dest
	mov	[es:edi+ebx],edx	;Write 2nd row to dest
	ELSE
	mov	[edi],al		;Write 1st row to dest
	mov	[edi+80],dl		;Write 2nd row to dest
	ENDIF

;	add	edi,4		;Next dest block position
	inc	edi		;Next dest block position
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

??One_color1:
	cmp	bx,SKIP_PTR		;Is this a skip block?
	jne	??Draw_One_Color

	add	edi,4		;Move to next dest block position
	dec	ecx		;More blocks for this row?
	jnz	short ??Not_finished_a_line
	jmp	??Next_row

??Draw_One_Color:
	not	bx		;NOT pointer value to get color
	mov	bh,bl		;Duplicate color through the
	mov	ax,bx		; entire dword register.
	rol	eax,16
	mov	ax,bx
;	mov	ebx,[bufwidth]

	IF	PHARLAP_TNT
	mov	[es:edi],eax		;Write 1st row to dest
	mov	[es:edi+ebx],eax	;Write 2nd row to dest
	ELSE
	mov	[edi],al		;Write 1st row to dest
	mov	[edi+80],al		;Write 2nd row to dest
	ENDIF

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
	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret
	ENDP	UnVQ_4x2_Xmode


;****************************************************************************
;*
;* NAME
;*     UnVQ_4x2_XmodeCB - Draw 4x2 VQ frame to Xmode from VRAM codebook.
;*
;* SYNOPSIS
;*     UnVQ_4x2_XmodeCB(Dummy, Pointers, Buffer, BPR, Rows)
;* 
;*     void UnVQ_4x2_XmodeCB(unsigned char *, unsigned char *,
;*                           unsigned char *, unsigned short,
;*                           unsigned short);
;*
;* FUNCTION
;*     This routine copies codebook entries from video RAM to video RAM.
;*     The procedure for Write Mode 1 is:
;*
;*       - Perform a CPU read at the address of the 4-byte codebook entry;
;*         this will load each byte at that address from all 4 bitplanes
;*         into the VGA's internal latches.
;*
;*       - Perform a CPU write at the destination address, with the BitMask
;*         register set to 0 (this tells the VGA hardware to only use the
;*         data stored in the latches to write with), and the Map Mask
;*         register set to 0Fh (all bitplanes enabled).
;*
;*     Optimized for 320x200.
;*     The codebook must have been downloaded to video RAM before this
;*     routine is called. This routine assumes the multicolor block pointers
;*     have been pre-divided by 4, and have a total of 512 added to them, so
;*     the pointer is an exact offset into the codebook.
;*
;* INPUTS
;*     Dummy    - Not used (prototype placeholder)
;*     Pointers - Pointer to vector pointer data.
;*     Buffer   - Pointer to Xmode buffer.
;*     BPR      - Number of blocks per row.
;*     Rows     - Number of rows.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C UnVQ_4x2_XmodeCB:NEAR
	PROC	UnVQ_4x2_XmodeCB C NEAR USES

	ARG	cbdummy:FAR PTR
	ARG	pointers:FAR PTR
	ARG	buffer:FAR PTR
	ARG	blocksperrow:WORD
	ARG	numrows:WORD

;	;-------------------------------------------------------------------
;	; Local variables:
;	;-------------------------------------------------------------------
;	LOCAL	di_startval:WORD	; init value for DI, for new row
;
;	;===================================================================
;	; Initialization
;	;===================================================================
;	;-------------------------------------------------------------------
;	; Save our registers
;	;-------------------------------------------------------------------
;	push	ds
;	push	es
;	push	fs
;	pushad
;
;	;-------------------------------------------------------------------
;	; Save codebook's segment in DS
;	;-------------------------------------------------------------------
;	mov	ax,CBOOK_SEG
;	mov	ds,ax
;
;	;-------------------------------------------------------------------
;	; Load pointers into FS:BX
;	;-------------------------------------------------------------------
;	les	di,[pointers]
;	mov	ax,es
;	mov	fs,ax
;	mov	bx,di
;
;	;-------------------------------------------------------------------
;	; Load screen address into ES:DI
;	;-------------------------------------------------------------------
;	les	di, [buffer]   			; point ES:DI to dest
;	mov	[di_startval],di		; store it
;
;	;-------------------------------------------------------------------
;	; Initialize VGA registers:
;	; - Enable all bitplanes for writing
;	; - Set the BitMask register to 0, so only the data from the
;	;   VGA latches is written into the bitplanes
;	;-------------------------------------------------------------------
;	SET_PLANE 0fh				; enable all planes for write
;	SET_WRITEMODE 1
;
;	;===================================================================
;	; The drawing loop:
;	; DS:SI = codebook
;	; ES:DI = drawing buffer
;	; FS:BX = pointers
;	;===================================================================
;	;-------------------------------------------------------------------
;	; Start a new row of drawing
;	;-------------------------------------------------------------------
;??Start_row:
;	mov	cx,[blocksperrow]		; # blocks to fill a line
;
;	;-------------------------------------------------------------------
;	; Start a new block
;	;-------------------------------------------------------------------
;??Not_finished_a_line:
;	;
;	;..................... get next pointer word .......................
;	;
;	mov	si,[WORD PTR fs:bx]		; SI = ptr word (cbook offset)
;	add	bx,2				; next ptr word
;	;
;	;................... skip ptr value SKIP_PTR .......................
;	;
;	cmp	si,SKIP_PTR
;	jne	??Draw_Block
;	inc	di
;	dec	cx
;	jnz	short ??Not_finished_a_line
;	jmp	??Next_row
;
;	;-------------------------------------------------------------------
;	; Draw a block via the VGA internal latches:
;	; DS:SI = codebook address
;	; ES:DI = buffer position to draw at
;	; - Load the VGA latches from the 1st 4 codebook bytes
;	; - write 4 pixels with one CPU write
;	; - If this is a one-color block, skip the next codebook read
;	;   (Video RAM reads are very slow); otherwise, latch the next 4
;	;   codebook bytes
;	; - write the next 4 pixels
;	;-------------------------------------------------------------------
;	;
;	;..................... draw 1st 4 pixels ...........................
;	;
;??Draw_Block:
;	mov	al,[ds:si]			; latch 1st 4 cbook bytes
;	mov	[es:di],al			; write 4 pixels
;	;
;	;.................. check for 1-color block ........................
;	;
;	cmp	si,512				; if 1color blk, don't read
;	jb	??One_Color
;	;
;	;..................... draw next 4 pixels ..........................
;	;
;	mov	al,[ds:si+1]			; latch next 4 cbook bytes
;??One_Color:
;	mov	[es:di+80],al			; write next 4 pixels
;	inc	di				; next block position
;	;
;	;...................... check block count ..........................
;	;
;	dec	cx				; decrement block count
;	jnz	short ??Not_finished_a_line
;
;	;-------------------------------------------------------------------
;	; Go to the next block row:
;	; - Add (80*2/16) to ES, and set DI to its start-row value
;	;   (Incrementing the segment allows us to unpack up to 1MB of data)
;	;-------------------------------------------------------------------
;	;
;	;...................... add (320*2/16) to ES .......................
;	;
;??Next_row:
;	mov	ax,es
;	add	ax,10				; add 80*2/16
;	mov	es,ax
;	;
;	;.................. set DI to its start-row value ..................
;	;
;	mov	di,[di_startval]
;	;
;	;............ see if we're past the end of the ptr data ............
;	;
;	dec	[numrows]
;	jg	??Start_row
;
;??End_of_data:
;	;-------------------------------------------------------------------
;	; Restore VGA Write Mode to 0
;	;-------------------------------------------------------------------
;	SET_WRITEMODE 0
;
;	popad
;	pop	fs
;	pop	es
;	pop	ds
	ret

	ENDP	UnVQ_4x2_XmodeCB


;****************************************************************************
;*
;* NAME
;*     Upload_4x2CB - Upload 4x2 codebook into XMode VRAM.
;*
;* SYNOPSIS
;*     Upload_4x2CB(Codebook, Entries)
;*
;*     void Upload_4x2CB(unsigned char *, unsigned short);
;*
;* FUNCTION
;*     This routine copies the given codebook into Xmode VRAM, so that it
;*     can be used later for direct video-to-video copies. The address used
;*     is the end of video memory minus 02700h (10K). This should be plenty
;*     for a 3000-entry codebook; each 4x2 codebook entry will take up 8
;*     8 bytes, or 2 addresses in XMode (6000 addresses).
;*
;*     The routine also creates a 1-color-block table in VRAM, so the 1-color
;*     blocks can be generated the same way as the multicolor blocks.
;*
;*     XMode 320x200 uses 320x200/4 addresses per page, for a total of 32000
;*     addresses.  XMode 320x240 uses 320x240/4 addresses per page, for a
;*     total of 38400 addresses.  This leaves 27136 addresses unused.
;*
;* INPUTS
;*     Codebook - Pointer to codebook to copy.
;*     Entries  - Number of codebook entries to copy.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Upload_4x2CB:NEAR
	PROC	Upload_4x2CB C NEAR USES

	ARG	codebook:NEAR PTR
	ARG	numentries:DWORD

;	;===================================================================
;	; Generate the 1-color block table by writing each color value from
;	; 0-255 into all 4 bitplanes, at 256 consecutive addresses:
;	;===================================================================
;	SET_PLANE 0fh			; enable all bitplanes for writing
;	;...................................................................
;	; Set ES:DI to destination address, set up CX for the loop
;	;...................................................................
;	mov	ax,CBOOK_SEG
;	mov	es,ax
;	mov	di,0
;	mov	cx,256
;	mov	ax,0
;??1_Color_Loop:
;	mov	[es:di],al			; write 4 bytes
;	inc	di				; next 4-byte position
;	mov	[es:di],al			; write 4 bytes
;	inc	di				; next 4-byte position
;	inc	ax				; next color #
;	dec	cx				; decrement loop counter
;	jnz	??1_Color_Loop
;
;	;===================================================================
;	; Copy the codebook into video RAM, one plane at a time:
;	;===================================================================
;	;-------------------------------------------------------------------
;	; Copy codebook byte 0 into Plane 1
;	;-------------------------------------------------------------------
;	;...................................................................
;	; Set DS:SI to codebook address, ES:DI to screen address
;	; (Codebook is stored at offset 1, so the pointers will point at
;	; exactly the right offset.)
;	;...................................................................
;	lds	si, [codebook]			; DS:SI = codebook
;	mov	ax,CBOOK_SEG
;	mov	es,ax
;	mov	di,512
;
;	;...................................................................
;	; Set up the loop
;	;...................................................................
;	SET_PLANE XPLANE_1
;	mov	cx,[numentries]			; set loop counter
;	shl	cx,1				; do 2 DWORDS per cbook entry
;
;	;...................................................................
;	; Loop through codebook entries
;	;...................................................................
;??CB_Loop_1:
;	mov	al,[ds:si]
;	mov	[es:di],al
;	add	si,4
;	inc	di
;	dec	cx
;	jnz	??CB_Loop_1
;
;	;-------------------------------------------------------------------
;	; Copy codebook byte 1 Plane 2
;	;-------------------------------------------------------------------
;	;...................................................................
;	; Set DS:SI to codebook address, ES:DI to screen address
;	; (Codebook is stored at offset 1, so the pointers will point at
;	; exactly the right offset.)
;	;...................................................................
;	lds	si, [codebook]			; DS:SI = codebook
;	mov	ax,CBOOK_SEG
;	mov	es,ax
;	mov	di,512
;	add	si,1				; use 2nd byte value
;
;	;...................................................................
;	; Set up the loop
;	;...................................................................
;	SET_PLANE XPLANE_2
;	mov	cx,[numentries]			; set loop counter
;	shl	cx,1				; do 2 DWORDS per cbook entry
;
;	;...................................................................
;	; Loop through codebook entries
;	;...................................................................
;??CB_Loop_2:
;	mov	al,[ds:si]
;	mov	[es:di],al
;	add	si,4
;	inc	di
;	dec	cx
;	jnz	??CB_Loop_2
;
;	;-------------------------------------------------------------------
;	; Copy codebook byte 2 Plane 3
;	;-------------------------------------------------------------------
;	;...................................................................
;	; Set DS:SI to codebook address, ES:DI to screen address
;	; (Codebook is stored at offset 1, so the pointers will point at
;	; exactly the right offset.)
;	;...................................................................
;	lds	si, [codebook]			; DS:SI = codebook
;	mov	ax,CBOOK_SEG
;	mov	es,ax
;	mov	di,512
;	add	si,2				; use 3rd byte value
;
;	;...................................................................
;	; Set up the loop
;	;...................................................................
;	SET_PLANE XPLANE_3
;	mov	cx,[numentries]			; set loop counter
;	shl	cx,1				; do 2 DWORDS per cbook entry
;
;	;...................................................................
;	; Loop through codebook entries
;	;...................................................................
;??CB_Loop_3:
;	mov	al,[ds:si]
;	mov	[es:di],al
;	add	si,4
;	inc	di
;	dec	cx
;	jnz	??CB_Loop_3
;
;	;-------------------------------------------------------------------
;	; Copy codebook byte 3 Plane 4
;	;-------------------------------------------------------------------
;	;...................................................................
;	; Set DS:SI to codebook address, ES:DI to screen address
;	; (Codebook is stored at offset 1, so the pointers will point at
;	; exactly the right offset.)
;	;...................................................................
;	lds	si, [codebook]			; DS:SI = codebook
;	mov	ax,CBOOK_SEG
;	mov	es,ax
;	mov	di,512
;	add	si,3				; use 4th byte value
;
;	;...................................................................
;	; Set up the loop
;	;...................................................................
;	SET_PLANE XPLANE_4
;	mov	cx,[numentries]			; set loop counter
;	shl	cx,1				; do 2 DWORDS per cbook entry
;
;	;...................................................................
;	; Loop through codebook entries
;	;...................................................................
;??CB_Loop_4:
;	mov	al,[ds:si]
;	mov	[es:di],al
;	add	si,4
;	inc	di
;	dec	cx
;	jnz	??CB_Loop_4
;
	ret

	ENDP	Upload_4x2CB

	ENDIF	;VQABLOCK_4X2

;****************************************************************************
;*
;* NAME
;*     XlatePointers - Translate pointer to optimal XMode format.
;*
;* SYNOPSIS
;*     XlatePointers(Pointers, Entries)
;*
;*     void XlatePointers(unsigned char *, unsigned short);
;*
;* FUNCTION
;*
;* INPUTS
;*     Pointers - Pointer to vector pointers to translate.
;*     Entries  - Number of pointer entries.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C XlatePointers:NEAR
	PROC	XlatePointers C NEAR USES

	ARG	pointers:NEAR PTR
	ARG	numpointers:DWORD

;	;-------------------------------------------------------------------
;	; Load pointers into DS:SI
;	;-------------------------------------------------------------------
;	lds	si,[pointers]
;
;	mov	cx,[numpointers]		; init to # pointers on scrn
;
;??Process_pointer:
;	;
;	;..................... get next pointer word .......................
;	;
;	mov	ax,[WORD PTR ds:si]		; SI = ptr word (cbook offset)
;	;
;	;.................... check for a 1-color block ....................
;	;
;	or	ax,ax				; check to see if high bit set
;	js	short ??One_color
;	;
;	;....................... multi-color pointer .......................
;	;
;	sub	ax,4				; subtract 4
;	shr	ax,2				; divide by 4
;	add	ax,512				; add 512
;	mov	[WORD PTR ds:si],ax		; save new value
;	add	si,2				; next ptr word
;	;
;	;....................... see if we're done .........................
;	;
;	dec	cx
;	jnz	??Process_pointer
;	jmp	??Done
;
;??One_color:
;	;
;	;......................... 1-color pointer .........................
;	;
;	not	ax				; get actual color value
;	shl	ax,1				; multiply by 2
;	mov	[WORD PTR ds:si],ax		; save new value
;	add	si,2				; next ptr word
;	;
;	;....................... see if we're done .........................
;	;
;	dec	cx
;	jnz	??Process_pointer
;
;??Done:
	ret

	ENDP	XlatePointers

	ENDIF	;VQAXMODE_ON
	END





