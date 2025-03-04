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
;*     vesabuf.asm
;*
;* DESCRIPTION
;*     VESA buffered blit routines.  (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Bill Randolph
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     Febuary 3, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     Buf_320x200_To_VESA_320x200 - Buffer copy, unscaled
;*     Buf_320x200_To_VESA_640x400 - Scales and copies 320x200 to 640x400
;*     Buf_320x200_To_VESA_32K     - Copies 320x200 buffer to VESA 32K
;*                                   colors
;*     Copy_Row                    - Copy a row of pixels to VRAM.
;*     Copy_Word_Row               - Copy a row of 15-bit pixels to VRAM
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"video.i"
	CODESEG

;---------------------------------------------------------------------------
; DRAW_BLOCK_ROWS: draws 'numrows' rows of 2x2 blocks
; Set ES:DI to current screen location
; Set DS:SI to current source location
; Uses: ax, cx, dx
;---------------------------------------------------------------------------
	MACRO	DRAW_BLOCK_ROWS numrows
	LOCAL	??Start_row
	LOCAL	??Not_finished_a_line
	LOCAL	??Done

	mov	edx,numrows
??Start_row:
	mov	ecx,320

??Not_finished_a_line:
	mov	al,[BYTE PTR esi]
	mov	ah,al
	inc	esi

	IF	PHARLAP_TNT
	mov	[WORD PTR es:edi],ax
	mov	[WORD PTR es:edi+640],ax
	ELSE
	mov	[WORD PTR edi],ax
	mov	[WORD PTR edi+640],ax
	ENDIF

	add	edi,2
	dec	ecx
	jnz	??Not_finished_a_line

	add	edi,640
	dec	edx
	jz	??Done
	jmp	??Start_row

??Done:
	ENDM

;---------------------------------------------------------------------------
; DRAW_BLOCK_ROW: draws one row of 'numblks' 2x2 blocks
; Set ES:DI to current screen location
; Set DS:SI to current source location
; Uses: ax, cx
;---------------------------------------------------------------------------
	MACRO	DRAW_BLOCK_ROW numblks
	LOCAL	??Not_done

	mov	ecx,numblks

??Not_done:
	mov	al,[BYTE PTR esi]
	mov	ah,al
	inc	esi

	IF	PHARLAP_TNT
	mov	[WORD PTR es:edi],ax
	mov	[WORD PTR es:edi+640],ax
	ELSE
	mov	[WORD PTR edi],ax
	mov	[WORD PTR edi+640],ax
	ENDIF

	add	edi,2
	dec	ecx
	jnz	??Not_done

	ENDM

;---------------------------------------------------------------------------
; DRAW_PIXEL_ROW: draws 'numblks' 2x1 blocks
; Set ES:DI to current screen location
; Set DS:SI to current source location
; Uses: ax, cx
;---------------------------------------------------------------------------
	MACRO	DRAW_PIXEL_ROW numblks
	LOCAL	??Not_done

	mov	ecx,numblks

??Not_done:
	mov	al,[BYTE PTR esi]
	mov	ah,al
	inc	esi

	IF	PHARLAP_TNT
	mov	[WORD PTR es:edi],ax
	ELSE
	mov	[WORD PTR edi],ax
	ENDIF

	add	edi,2
	dec	ecx
	jnz	??Not_done

	ENDM

;****************************************************************************
;*
;* NAME
;*     Blit_VESA640x480 - Blit to 640x480 256 color VESA mode.
;*
;* SYNOPSIS
;*     Blit_VESA640x480(DisplayInfo, Buffer, X, Y, Width, Height)
;*
;*     void Blit_VESA640x480(DisplayInfo *, char *, long, long, long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     DisplayInfo - Pointer to display information structure.
;*     Buffer      - Pointer to buffer to blit to VRAM.
;*     X           - Destination X coordinate of blit (upper left).
;*     Y           - Destination Y coordinate of blit (upper left).
;*     Width       - Width of blit.
;*     Height      - Height of blit.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

;	GLOBAL	C Blit_VESA640x480:NEAR
;	PROC	Blit_VESA640x480 C NEAR USES
;
;	ARG	disp:NEAR PTR DisplayInfo
;	ARG	buffer:NEAR PTR
;	ARG	x:DWORD
;	ARG	y:DWORD
;	ARG	width:DWORD
;	ARG	height:DWORD
;
;	LOCAL	grain:DWORD
;	LOCAL	scrn_offset:DWORD
;	LOCAL	bank_offset:DWORD
;	LOCAL	bank:DWORD
;	LOCAL	xres:DWORD
;
;;----------------------------------------------------------------------------
;;	INITIALIZE
;;----------------------------------------------------------------------------
;
;	pushad
;
;;	Calculate granularity units per window
;
;	mov	esi,[disp]
;	xor	eax,eax
;	mov	edi,[(DisplayInfo esi).Extended]
;	xor	ebx,ebx
;	mov	ax,[(VESAModeInfo edi).WinSize]
;	xor	edx,edx
;	mov	bx,[(VESAModeInfo edi).WinGranularity]
;	idiv	ebx
;	mov	[grain],eax
;
;;	Calculate screen offset
;
;	mov	eax,[(DisplayInfo esi).XRes]
;	mov	[xres],eax
;	imul	[y]
;	add	eax,[x]
;	mov	[scrn_offset],eax
;
;;	Calculate bank offset
;
;	mov	ebx,65536
;	idiv	ebx
;	mov	[bank_offset],edx
;	mov	[bank],eax
;
;	popad
;	ret
;
;	ENDP	Blit_VESA640x480


;****************************************************************************
;*
;* NAME
;*     Buf_320x200_To_VESA_320x200 - Buffer copy, unscaled
;*
;* SYNOPSIS
;*     Buf_320x200_To_VESA_320x200(Buffer, GrainPerWin)
;*
;*     void Buf_320x200_To_VESA_320x200(char *, long);
;*
;* FUNCTION
;*     To center the buffer on the screen, it's upper-left corner goes at
;*     (160,140).  This means the buffer spans VESA banks 1,2 & 3, so it must
;*     be copied in 3 parts:
;*
;*     Bank 1: starting offset 24224, 65 lines
;*     Bank 2: starting offset 288, 102 lines
;*     Bank 3: starting offset 32, 33 lines
;*
;* INPUTS
;*     Buffer      - Pointer to buffer to transfer to VRAM
;*     GrainPerWin - Granularity units per 64k window.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Buf_320x200_To_VESA_320x200:NEAR
	PROC	Buf_320x200_To_VESA_320x200 C NEAR USES ebx ecx edx esi edi

	ARG	buffer:NEAR PTR
	ARG	grains_per_win:DWORD

	LOCAL	grain_num:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	IF	PHARLAP_TNT
	push	es
	mov	eax,01Ch	;Set ES selector to VRAM
	mov	es,ax
	ENDIF

	mov	eax,[grains_per_win]
	mov	esi,[buffer]
	mov	[grain_num],eax

;----------------------------------------------------------------------------
;	Copy Bank 1
;----------------------------------------------------------------------------

	SET_WINDOW [grain_num]
	mov	edi,24224	;Starting screen address
	mov	edx,65	;Lines to copy

??SetBank1:
	mov	ecx,80	;DWORDS to copy
	rep	movsd	;Move the pixels
	add	edi,320	;Wrap to start of next line
	dec	edx	;Decrement our line counter
	jnz	??SetBank1	;Draw more lines

;----------------------------------------------------------------------------
;	Copy Bank 2
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax

	SET_WINDOW [grain_num]
	mov	edi,288	;Starting screen address
	mov	edx,102	;Lines to copy

??SetBank2:
	mov	ecx,80	;DWORDS to copy
	rep	movsd	;Move the pixels
	add	edi,320	;Wrap to start of next line
	dec	edx	;Decrement our line counter
	jnz	??SetBank2	;Draw more lines

;----------------------------------------------------------------------------
;	Copy Bank 3
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax

	SET_WINDOW [grain_num]
	mov	edi,32	;Starting screen address
	mov	edx,33	;Lines to copy

??SetBank3:
	mov	ecx,80	;DWORDS to copy
	rep	movsd	;Move the pixels
	add	edi,320	;Wrap to start of next line
	dec	edx	;Decrement our line counter
	jnz	??SetBank3	;Draw more lines

	IF	PHARLAP_TNT
	pop	es
	ENDIF
	ret

	ENDP	Buf_320x200_To_VESA_320x200


;****************************************************************************
;*
;* NAME
;*     Buf_320x200_To_VESA_640x400 - Scales and copies 320x200 to 640x400
;*
;* SYNOPSIS
;*     Buf_320x200_To_VESA_640x400(Buffer, GrainPerWin)
;*     
;*     void Buf_320x200_To_VESA_640x400(char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Buffer      - Pointer to buffer to transfer to VRAM
;*     GrainPerWin - Granularity units per 64k window.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Buf_320x200_To_VESA_640x400:NEAR
	PROC	Buf_320x200_To_VESA_640x400 C NEAR USES ebx ecx edx esi edi

	ARG	buffer:NEAR PTR
	ARG	grains_per_win:DWORD

	LOCAL	grain_num:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	IF	PHARLAP_TNT
	push	es
	mov	eax,01Ch	;Set ES selector to VRAM
	mov	es,ax
	ENDIF

	mov	esi,[buffer]
	mov	[grain_num],0

;----------------------------------------------------------------------------
;	Copy Bank 0
;	- Skip down 40 scanlines (to center the image)
;	- Draw 62 scanlines (31 rows of blocks)
;	- Draw top half of 128 blocks
;----------------------------------------------------------------------------

	SET_WINDOW [grain_num]
	mov	edi,25600	;Starting screen address

	DRAW_BLOCK_ROWS 62/2	;Draw 31 rows of blocks
	DRAW_PIXEL_ROW 256/2	;Draw top half of next 128 blocks

;----------------------------------------------------------------------------
;	Copy Bank 1
;	- Draw bottom half of previous 128 blocks
;	- Finish the scan line with full blocks
;	- Draw 100 scanlines of blocks
;	- last line: top half of 256 blocks
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax
	SET_WINDOW [grain_num]

	sub	esi,256/2	;Draw bottom half of prev 128 blks
	mov	edi,384
	DRAW_PIXEL_ROW 256/2

	mov	edi,0
	DRAW_BLOCK_ROW 384/2	;Fill rest of this block row

	add	edi,640
	DRAW_BLOCK_ROWS 100/2	;Draw the block rows
	DRAW_PIXEL_ROW 512/2	;Draw top half of next 512 blocks

;----------------------------------------------------------------------------
;	Copy Bank 2
;	- Draw bottom half of previous 256 blocks
;	- Finish the scan line with full blocks
;	- Draw 101 scanlines of blocks
;	- last line: 64 full blocks plus top half of 256 blocks
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax
	SET_WINDOW [grain_num]

	sub	esi,512/2	;Draw bottom half of prev 256 blks
	mov	edi,128
	DRAW_PIXEL_ROW 512/2

	mov	edi,0
	DRAW_BLOCK_ROW 128/2	;Fill rest of this block row

	add	edi,640
	DRAW_BLOCK_ROWS 101/2	;Draw the block rows
	DRAW_BLOCK_ROW 128/2	;Draw next 64 blocks
	DRAW_PIXEL_ROW 512/2	;Top half of 256 blocks

;----------------------------------------------------------------------------
;	Copy Bank 3
;	- Draw bottom half of previous 256 blocks
;	- Finish the scan line with full blocks
;	- Draw 101 scanlines of blocks
;	- last line: 192 full blocks, top half of 128 blocks
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax
	SET_WINDOW [grain_num]

	sub	esi,512/2	;Draw bottom half of prev 256 blks
	mov	edi,0
	DRAW_PIXEL_ROW 512/2
	DRAW_BLOCK_ROWS 101/2	;Draw the block rows
	DRAW_BLOCK_ROW 384/2	;Last row of full blocks
	DRAW_PIXEL_ROW 256/2	;Top half of 128 blocks

;----------------------------------------------------------------------------
;	Copy Bank 4
;	- Draw bottom half of previous 128 blocks
;	- Draw 30 scanlines of blocks
;----------------------------------------------------------------------------

	mov	eax,[grains_per_win]
	add	[grain_num],eax
	SET_WINDOW [grain_num]

	sub	esi,256/2	;Draw bottom half of prev 256 blks
	mov	edi,0
	DRAW_PIXEL_ROW 256/2
	DRAW_BLOCK_ROWS 30/2	;Draw the block rows

	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	Buf_320x200_To_VESA_640x400


;****************************************************************************
;*
;* NAME
;*     Buf_320x200_To_VESA_32K - Copies 320x200 buffer to VESA 32K colors
;*
;* SYNOPSIS
;*     Buf_320x200_To_VESA_32K(Buffer, Palette, GrainPerWin)
;*     
;*     void Buf_320x200_To_VESA_32K(char *, char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Buffer      - Pointer to buffer to transfer to VRAM
;*     Palette     - Pointer to 15-bit palette to use.
;*     GrainPerWin - Granularity units per 64k window.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Buf_320x200_To_VESA_32K:NEAR
	PROC	Buf_320x200_To_VESA_32K C NEAR USES ebx ecx edx esi edi

	ARG	buffer:NEAR PTR
	ARG	palette:NEAR PTR
	ARG	grains_per_win:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	IF	PHARLAP_TNT
	push	es
	mov	eax,01Ch	;Set ES selector to VRAM
	mov	es,ax
	ENDIF

	mov	esi,[buffer]

;----------------------------------------------------------------------------
;	Copy Bank 0
;----------------------------------------------------------------------------

	SET_WINDOW 0
	mov	edi,0	;Start at Bank 0, offset 0
	mov	ecx,32768	;# words we'll be setting

;	Get the pixel's offset into the palette

??Buf0Loop:
	xor	eax,eax
	mov	ebx,[palette]
	mov	al,[BYTE PTR esi]
	add	ebx,eax
	inc	esi
	add	ebx,eax

;	store the 15-bit palette value

	mov	ax,[WORD PTR ebx]

	IF	PHARLAP_TNT
	mov	[WORD PTR es:edi],ax
	ELSE
	mov	[WORD PTR edi],ax
	ENDIF

	add	edi,2
	dec	ecx
	jnz	??Buf0Loop

;----------------------------------------------------------------------------
;	Copy Bank 1
;----------------------------------------------------------------------------

	SET_WINDOW [grains_per_win]
	mov	edi,0	;Start at Bank 1, offset 0
	mov	ecx,31232	;# words we'll be setting

;	Get the pixel's offset into the palette

??Buf1Loop:
	xor	eax,eax
	mov	ebx,[palette]
	mov	al,[BYTE PTR esi]
	add	ebx,eax
	inc	esi
	add	ebx,eax

;	Store the 15-bit palette value

	mov	ax,[WORD PTR ebx]

	IF	PHARLAP_TNT
	mov	[WORD PTR es:edi],ax
	ELSE
	mov	[WORD PTR edi],ax
	ENDIF

	add	edi,2
	dec	ecx
	jnz	??Buf1Loop

	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	Buf_320x200_To_VESA_32K


;****************************************************************************
;*
;* NAME
;*     Copy_Row - Copy a row of pixels to VRAM.
;*
;* SYNOPSIS
;*     Copy_Row(Source, Dest, Length)
;*
;*     void Copy_Row(char *, char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Source - Pointer to data to copy to VRAM
;*     Dest   - Destination VRAM address.
;*     Length - Number of bytes to copy.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Copy_Row:NEAR
	PROC	Copy_Row C NEAR USES ecx esi edi
	
	ARG	source:NEAR PTR
	ARG	dest:NEAR PTR
	ARG	numbytes:DWORD

	IF	PHARLAP_TNT
	push	es
	mov	eax,01Ch
	mov	es,ax
	ENDIF

	cld
	mov	esi,[source]
	mov	edi,[dest]
	mov	ecx,[numbytes]
	rep	movsb

	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret

	ENDP	Copy_Row


;****************************************************************************
;*
;* NAME
;*     Copy_Word_Row - Copy a row of 15-bit pixels to VRAM
;*
;* SYNOPSIS
;*     Copy_Word_Row(Source, Dest, Palette, Length)
;*
;*     void Copy_Word_Row(char *, char *, char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Source  - Pointer to data to transfer.
;*     Dest    - Destination screen address.
;*     Palette - 15bit palette to use.
;*     Length  - Bytes to transfer.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Copy_Word_Row:NEAR
	PROC	Copy_Word_Row C NEAR USES ebx ecx esi edi

	ARG	source:NEAR PTR
	ARG	dest:NEAR PTR
	ARG	palette:NEAR PTR
	ARG	numbytes:DWORD

	IF	PHARLAP_TNT
	push	es
	mov	eax,01Ch
	mov	es,ax
	ENDIF

	mov	esi,[source]
	mov	edi,[dest]
	mov	ecx,[numbytes]

??loop:
	mov	ebx,[palette]
	xor	eax,eax
	mov	al,[esi]	;Get pixel value
	shl	eax,1	;Adjust for word entry
	add	ebx,eax	;Compute color address
	mov	ax,[ebx]	;Get color

	IF	PHARLAP_TNT
	mov	[es:edi],ax	;Set 16bit pixel
	ELSE
	mov	[edi],ax	;Set 16bit pixel
	ENDIF

	inc	esi	;Next source pixel
	add	edi,2	;Next dest pixel
	dec	ecx	;Decrement pixel count
	jnz	??loop

	IF	PHARLAP_TNT
	pop	es
	ENDIF

	ret  

	ENDP	Copy_Word_Row

	END

