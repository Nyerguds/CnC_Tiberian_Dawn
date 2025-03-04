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
;*     xmode.asm
;*
;* DESCRIPTION
;*     Xmode graphics display routines. (32-Bit protected mode)
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
;*     SetXMode                 - Set the specified Xmode video mode.
;*     ClearXMode               - Clear the XMode VRAM.
;*     ShowXPage                - Set a specific page for XMode display.
;*     Xmode_BufferCopy_320x200 - Copy 320x200 buffer to Xmode VRAM.
;*     Xmode_Blit               - Bit blit a block to the XMode display.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"vga.i"
	INCLUDE	"video.i"
	CODESEG

;****************************************************************************
;*
;* NAME
;*     SetXMode - Set the specified Xmode video mode.
;*
;* SYNOPSIS
;*     Error = SetXMode(Mode)
;*
;*     long SetXMode(long);
;*
;* FUNCTION
;*     This routines set the current display adapter to the specified Xmode.
;*     Portions of this routine were take from Dr. Dobb's, written in C, and
;*     portions were taken from Dominic's 320x200 code.
;*
;* INPUTS
;*     Mode - Xmode mode to set display to.
;*
;* RESULT
;*     Error - 0 if successful, or -1 if error.
;*
;****************************************************************************

	GLOBAL	C SetXMode:NEAR
	PROC	SetXMode C NEAR USES edx

	ARG	mode:DWORD

??Set320x200:
	cmp	[mode],XMODE_320X200	;320x200?
	jne	??Set320x240

	IF	0
	mov	eax,MCGA
	int	10h

;	Memory Mode:
;	bit3 (chain) = 0 (planes are accessed via Map Mask)
;	bit2 (odd/even) = 1 (use sequential addressing mode)

	INPORT R_SEQUENCER,SEQ_MEMORY_MODE
	and	al,not 08h			;Turn off chain 4
	or	al,04h			;Turn off odd/even
	out	dx,al

	INPORT R_GRAPHICS_CONTROLLER,GC_MODE
	and	al,not 10h			;Turn off odd/even
	out	dx,al

	INPORT R_GRAPHICS_CONTROLLER,GC_MISC
	and	al,not 02h			;Turn off chain
	out	dx,al

	OUTPORT R_SEQUENCER,SEQ_MAP_MASK,0Fh
	INPORT R_CRT_CONTROLLER, CRT_MAX_SCANLINE
	and	al,not 1fh			;Clear low 5 bits
	or	al,1     			;Mode = 0 => 400 lines
	out	dx,al			;Mode =1  => 200

	INPORT R_CRT_CONTROLLER,CRT_UNDERLINE
	and	al,not 40h			;Turn off doubleword
	out	dx,al

	INPORT R_CRT_CONTROLLER,CRT_MODE_CONTROL
	or	al,40h			;Turn on byte mode bit,
	out	dx,al	    		; so mem scanned linearly
	ENDIF

;	The following section of code is from Roger Stevens' XMode
;	example code; it's the same as 320x400, except the value sent
;	to CRT_MAX_SCANLINE is 41, not 40.

	mov	eax,MCGA
	int	10h

	OUTPORT R_SEQUENCER,SEQ_MEMORY_MODE,06h
	INPORT R_CRT_CONTROLLER,CRT_VERTRET_END
	and	al,07Fh
	out	dx,al

	OUTPORT R_CRT_CONTROLLER,CRT_MAX_SCANLINE,41h
	OUTPORT R_CRT_CONTROLLER,CRT_UNDERLINE,00h
	OUTPORT R_CRT_CONTROLLER,CRT_MODE_CONTROL,0E3h

	mov	eax,0
	jmp	??Done

??Set320x240:
	cmp	[mode],XMODE_320X240	;320x240?
	jne	??Set320x400

;	Start by setting MCGA to let the BIOS program the registers;
;	then, reprogram the registers that need it.

	mov	eax,MCGA
	int	10h

;	Memory Mode:
;	bit3 (chain) = 0 (planes are accessed via Map Mask)
;	bit2 (odd/even) = 1 (use sequential addressing mode)
;	bit1 (extended mem) = 1 (>64K video RAM)
;	bit0 (alpha/graph) = 0 (graphics mode)

	OUTPORT R_SEQUENCER,SEQ_MEMORY_MODE,06h

;	Issue a Sequencer Reset
	OUTPORT R_SEQUENCER,SEQ_RESET,01h

;	Misc Output: (set to 1100 0011)
;	Bit 7: VSync polarity (1=negative)
;	Bit 6: HSync polarity (1=negative)
;	Bit 5: page bit for odd/even (0=low 64K)
;	Bit 4: Video drivers (0=enable)
;	Bit 3,2: clock select (0=25-MHz clock)
;	Bit 1: VRAM access (1 = enable CPU to access)
;	Bit 0: I/O Address (1=color emulation)

	mov	edx,R_MISC_OUTPUT
	mov	al,0C3h
	out	dx,al

;	Clear Sequencer Reset

	OUTPORT R_SEQUENCER,SEQ_RESET,03h

;	Read Vertical Retrace End, and with 07f to clear high bit
;	(clearing bit 7 enables writing to registers 0-7)

	INPORT R_CRT_CONTROLLER,CRT_VERTRET_END
	and	al,07Fh
	out	dx,al

;	Program the CRT Controller to display 480 scanlines, but to
;	double each scanline so only 240 are displayed:

	OUTPORT R_CRT_CONTROLLER,CRT_UNDERLINE,00h
	OUTPORT R_CRT_CONTROLLER,CRT_MODE_CONTROL,0E3h
	OUTPORT R_CRT_CONTROLLER,CRT_VERT_TOTAL,0Dh
	OUTPORT R_CRT_CONTROLLER,CRT_OVERFLOW,03Eh
	OUTPORT R_CRT_CONTROLLER,CRT_VERTRET_START,0EAh
	OUTPORT R_CRT_CONTROLLER,CRT_VERTRET_END,0ACh
	OUTPORT R_CRT_CONTROLLER,CRT_VERTDISP_END,0DFh
	OUTPORT R_CRT_CONTROLLER,CRT_START_VB,0E7h
	OUTPORT R_CRT_CONTROLLER,CRT_END_VB,06h
	OUTPORT R_CRT_CONTROLLER,CRT_MAX_SCANLINE,041h

	xor	eax,eax
	jmp	??Done

??Set320x400:
	cmp	[mode],XMODE_320X400	;320x400
	jne	??Set320x480

	mov	eax,MCGA
	int	10h

	OUTPORT R_SEQUENCER,04h,06h
	INPORT R_CRT_CONTROLLER,011h
	and	al,07Fh
	out	dx,al

	OUTPORT R_CRT_CONTROLLER,09h,40h
	OUTPORT R_CRT_CONTROLLER,014h,00h
	OUTPORT R_CRT_CONTROLLER,017h,0E3h

	xor	eax,eax
	jmp	??Done

??Set320x480:
	cmp	[mode],XMODE_320X480	;320x480?
	jne	??Set360x400

	mov	eax,MCGA
	int	10h

	mov	edx,R_SEQUENCER
	mov	eax,0604h
	out	dx,ax

	mov	eax,0100h
	out	dx,ax

	mov	edx,R_MISC_OUTPUT
	mov	al,0C3h
	out	dx,al

	mov	edx,R_SEQUENCER
	mov	eax,0300h
	out	dx,ax

	mov	edx,R_CRT_CONTROLLER
	mov	al,011h
	out	dx,al

	mov	edx,03D5h
	in	al,dx
	and	al,07Fh
	out	dx,al

	mov	edx,R_CRT_CONTROLLER
	mov	eax,04009h
	out	dx,ax
	mov	eax,00014h
	out	dx,ax
	mov	eax,0E317h
	out	dx,ax
	mov	eax,00D06h
	out	dx,ax
	mov	eax,03E07h
	out	dx,ax
	mov	eax,0EA10h
	out	dx,ax
	mov	eax,0AC11h
	out	dx,ax
	mov	eax,0DF12h
	out	dx,ax
	mov	eax,0E715h
	out	dx,ax
	mov	eax,00616h
	out	dx,ax
	mov	eax,04009h
	out	dx,ax

	xor	eax,eax
	jmp	??Done

??Set360x400:
	cmp	[mode],XMODE_360X400	;360x400
	jne	??Set360x480

	mov	eax,MCGA
	int	10h

	mov	edx,R_SEQUENCER
	mov	eax,0604h
	out	dx,ax

	mov	eax,0100h
	out	dx,ax

	mov	edx,R_MISC_OUTPUT
	mov	al,067h
	out	dx,al

	mov	edx,R_SEQUENCER
	mov	eax,0300h
	out	dx,ax

	mov	edx,R_CRT_CONTROLLER
	mov	al,011h
	out	dx,al

	mov	edx,03D5h
	in	al,dx
	and	al,07Fh
	out	dx,al

	mov	edx,R_CRT_CONTROLLER
	mov	eax,06B00h
	out	dx,ax
	mov	eax,05901h
	out	dx,ax
	mov	eax,05A02h
	out	dx,ax
	mov	eax,08E03h
	out	dx,ax
	mov	eax,05E04h
	out	dx,ax
	mov	eax,08A05h
	out	dx,ax
	mov	eax,04009
	out	dx,ax
	mov	eax,00014h
	out	dx,ax
	mov	eax,0E317h
	out	dx,ax
	mov	eax,02D13h
	out	dx,ax

	xor	eax,eax
	jmp	??Done

??Set360x480:
	cmp	[mode],XMODE_360X480	;360x480?
	jne	??Unknown_mode

	mov	eax,MCGA
	int	10h

	mov	edx,R_SEQUENCER
	mov	eax,0604h
	out	dx,ax

	mov	eax,0100h
	out	dx,ax

	mov	edx,R_MISC_OUTPUT
	mov	al,0E7h
	out	dx,al

	mov	edx,R_SEQUENCER
	mov	eax,0300h
	out	dx,ax

	mov	edx,R_CRT_CONTROLLER
	mov	al,011h
	out	dx,al

	mov	edx,03D5h
	in	al,dx
	and	al,07Fh
	out	dx,al

	mov	edx,R_CRT_CONTROLLER
	mov	eax,06B00h
	out	dx,ax
	mov	eax,05901h
	out	dx,ax
	mov	eax,05A02h
	out	dx,ax
	mov	eax,08E03h
	out	dx,ax
	mov	eax,05E04h
	out	dx,ax
	mov	eax,08A05h
	out	dx,ax
	mov	eax,04009h
	out	dx,ax
	mov	eax,00014h
	out	dx,ax
	mov	eax,0E317h
	out	dx,ax
	mov	eax,00D06h
	out	dx,ax
	mov	eax,03E07h
	out	dx,ax
	mov	eax,0EA10h
	out	dx,ax
	mov	eax,0AC11h
	out	dx,ax
	mov	eax,0DF12h
	out	dx,ax
	mov	eax,0E715h
	out	dx,ax
	mov	eax,00616h
	out	dx,ax
	mov	eax,02D13h
	out	dx,ax

	xor	eax,eax
	jmp	??Done

??Unknown_mode:
	mov	eax,0FFFFFFFFh	;Unknown mode

??Done:
	ret

	ENDP	SetXMode


;****************************************************************************
;*
;* NAME
;*     ClearXMode - Clear the XMode VRAM.
;*
;* SYNOPSIS
;*     ClearXMode()
;*
;*     void ClearXMode(void);
;*
;* FUNCTION
;*
;* INPUTS
;*     NONE
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C ClearXMode:NEAR
	PROC	ClearXMode C NEAR USES eax ecx edi es

	IF	PHARLAP_TNT
	mov	eax,01Ch
	mov	es,ax		;Set ES selector to VRAM
	mov	edi,0
	ELSE
	mov	edi,0A0000h
	ENDIF
	SET_PLANE 0Fh
	mov	ecx,((320*240*2)/4/4)
	xor	eax,eax
	rep	stosd
	ret

	ENDP	ClearXMode


;****************************************************************************
;*
;* NAME
;*     ShowXPage - Set a specific page for XMode display.
;*
;* SYNOPSIS
;*     ShowXPage(Offset)
;*
;*     void ShowXPage();
;*
;* FUNCTION
;*     Show the page at the specified offset in the bitmap. Page-flip takes
;*     effect on the next active scan cycle.
;*
;* INPUTS
;*     Offset - Offset to set page to.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C ShowXPage:NEAR
	PROC	ShowXPage C NEAR USES eax ebx ecx edx

	ARG	StartOffset:DWORD

	mov	edx,R_CRT_CONTROLLER
	mov	bl,CRT_STARTADDR_LOW
	mov	bh,[byte ptr StartOffset]
	mov	cl,CRT_STARTADDR_HIGH
	mov	ch,[byte ptr StartOffset+1]
	mov	eax,ebx
	out	dx,ax
	mov	eax,ecx
	out	dx,ax
	ret

	ENDP	ShowXPage


;****************************************************************************
;*
;* NAME
;*     Xmode_BufferCopy_320x200 - Copy 320x200 buffer to Xmode VRAM.
;*
;* SYNOPSIS
;*     Xmode_BufferCopy_320x200(Buffer, Screen)
;*
;*     void Xmode_BufferCopy_320x200(char *, char *);
;*
;* FUNCTION
;*     BitBlt copy to VRAM.
;*
;* INPUTS
;*     Buffer - Pointer to buffer to copy to XMode VRAM.
;*     Screen - XMode VRAM screen address to copy buffer to.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C Xmode_BufferCopy_320x200:NEAR
	PROC	Xmode_BufferCopy_320x200 C NEAR USES eax ecx edx edi esi es

	ARG	buffer:NEAR PTR
	ARG	screen:NEAR PTR

	LOCAL	save_esi:DWORD
	LOCAL	save_edi:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------
	
	IF	PHARLAP_TNT
	mov	eax,01Ch	;Set ES selector to VRAM.
	mov	es,ax
	ENDIF

	mov	esi,[buffer]	;Set pointers
	mov	edi,[screen]
	mov	[save_esi],esi
	mov	[save_edi],edi

;----------------------------------------------------------------------------
;	Copy plane 1
;----------------------------------------------------------------------------

	SET_PLANE XPLANE_1
	mov	ecx,4000

x_loop_1:
	mov	al,[esi + 8]	;Get pixel
	mov	ah,[esi + 12]	;Get pixel
	ror	eax,16
	mov	al,[esi]	;Get pixel
	mov	ah,[esi + 4]	;Get pixel
	mov	[es:edi],eax 	;Write plane 1 pixels to VRAM

	add	esi,16	;Next source pixel position
	add	edi,4	;Next VRAM position
	dec	ecx
	jnz	short x_loop_1

;----------------------------------------------------------------------------
;	Copy plane 2
;----------------------------------------------------------------------------

	mov	esi,[save_esi]	;Restore pointers
	mov	edi,[save_edi]
	inc	esi	;Adjust source pointer to plane 2

	SET_PLANE XPLANE_2
	mov	ecx,4000

x_loop_2:
	mov	al,[esi + 8]	;Get pixel
	mov	ah,[esi + 12]	;Get pixel
	ror	eax,16
	mov	al,[esi]	;Get pixel
	mov	ah,[esi + 4]	;Get pixel
	mov	[es:edi],eax	;Write plane 2 pixels to VRAM

	add	esi,16	;Next source pixel position
	add	edi,4	;Next VRAM position
	dec	ecx
	jnz	short x_loop_2

;----------------------------------------------------------------------------
;	Copy plane 3
;----------------------------------------------------------------------------

	mov	esi,[save_esi]	;Restore pointers
	mov	edi,[save_edi]
	add	esi,2	;Adjust source pointer to plane 3

	SET_PLANE XPLANE_3
	mov	ecx,4000

x_loop_3:
	mov	al,[esi + 8]	;Get pixel
	mov	ah,[esi + 12]	;Get pixel
	ror	eax,16
	mov	al,[esi]	;Get pixel
	mov	ah,[esi + 4]	;Get pixel
	mov	[es:edi],eax	;Write plane 3 pixels to VRAM

	add	esi,16	;Next source pixel position
	add	edi,4	;Next VRAM position
	dec	ecx
	jnz	short x_loop_3

;----------------------------------------------------------------------------
;	Copy plane 4
;----------------------------------------------------------------------------

	mov	esi,[save_esi]	;Restore pointers
	mov	edi,[save_edi]
	add	esi,3	;Adjust source pointer to plane 4

	SET_PLANE XPLANE_4
	mov	ecx,4000
x_loop_4:
	mov	al,[esi + 8]	;Get pixel
	mov	ah,[esi + 12]	;Get pixel
	ror	eax,16
	mov	al,[esi]	;Get pixel
	mov	ah,[esi + 4]	;Get pixel
	mov	[es:edi],eax	;Write plane 4 pixels to VRAM

	add	esi,16	;Next source pixel position
	add	edi,4	;Next screen position
	dec	ecx
	jnz	short x_loop_4
	ret

	ENDP	Xmode_BufferCopy_320x200


;****************************************************************************
;*
;* NAME
;*     Xmode_Blit - Bit blit a block to the XMode display.
;*
;* SYNOPSIS
;*     XMode_Blit(Buffer, Screen, Width, Height)
;*
;*     void XMode_Blit(char *, char *, long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Buffer - Pointer buffer to blit to screen.
;*     Screen - Screen address to blit buffer to.
;*     Width  - Width of buffer.
;*     Height - Height of buffer.
;*
;* RESULT
;*     NONE
;*
;* WARNINGS
;*     Assumes the screen to be 320 pixels wide and the source buffer width
;*     to be divisible by 16.
;*
;****************************************************************************

	GLOBAL	C Xmode_Blit:NEAR
	PROC	Xmode_Blit C NEAR USES ecx edx esi edi es

	ARG	buffer:NEAR PTR
	ARG	screen:NEAR PTR
	ARG	imgwidth:DWORD
	ARG	imgheight:DWORD

	LOCAL	rowcount:DWORD
	LOCAL	xplane:DWORD
	LOCAL	edi_startval:DWORD
	LOCAL	esi_startval:DWORD
	LOCAL	xadd:DWORD

;----------------------------------------------------------------------------
;	Initialize
;----------------------------------------------------------------------------

	IF	PHARLAP_TNT
	mov	eax,01Ch	;Set ES selector to VRAM
	mov	es,ax
	ENDIF

	mov	esi,[buffer]
	mov	edi,[screen]
	mov	[esi_startval],esi
	mov	[edi_startval],edi

	mov	edx,320	;Compute modulo
	sub	edx,[imgwidth]
	shr	edx,2
	mov	[xadd],edx

;----------------------------------------------------------------------------
;	Transfer the data on plane at a time.
;----------------------------------------------------------------------------

	mov	[xplane],1

??Do_plane:
	SET_PLANE [xplane]	;Set plane to transfer to
	mov	eax,[imgheight]
	mov	[rowcount],eax
	mov	edx,[xadd]

??Do_row:
	mov	ecx,[imgwidth]	;Length of row to copy in DWORDS
	shr	ecx,4

;	Transfer a row of pixels

??Not_done:
	mov	al,[esi + 8]	;Get pixel
	mov	ah,[esi + 12]	;Get pixel
	ror	eax,16
	mov	al,[esi]	;Get pixel
	mov	ah,[esi + 4]	;Get pixel
	mov	[es:edi],eax	;Write pixels to VRAM plane

	add	esi,16	;Next source position
	add	edi,4	;Next VRAM position
	dec	ecx
	jnz	??Not_done

	add	edi,edx	;Next VRAM row
	dec	[rowcount]	;Decrement the row count
	jnz	??Do_row

;	Go to next X-Plane

	inc	[esi_startval]
	mov	eax,[esi_startval]
	mov	esi,eax
	mov	eax,[edi_startval]
	mov	edi,eax
	shl	[xplane],1
	cmp	[xplane],16
	jnz	??Do_plane
	ret

	ENDP	Xmode_Blit

	END

