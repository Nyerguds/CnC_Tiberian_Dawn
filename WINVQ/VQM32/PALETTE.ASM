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
;*     palette.asm
;*
;* DESCRIPTION
;*     Hardware level palette routines. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Bill Randolph
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* To write palette colors:
;* - Out color # to 3c8h
;* - Out RGB values to 3c9h (data must be written in three's; PEL address
;*   register auto-increments after 3 reads or writes)
;*
;* A time interval of about 240 ns is required between successive reads/
;* writes; on very fast machines, this means that the system may not be
;* able to handle a rapid-fire of RGB values.  So, a "safe" routine is
;* provided that has wait states between each out.
;* 
;* Reference: Progammers Guide to the EGA & VGA Cards, Ferraro, 2nd ed.
;* (Chapter 8.)
;*
;* Note that, if you set the palette in active scan, the screen will
;* flash; to prevent this, wait for vertical retrace (Vertical Blank
;* Interval), or turn the display off by using the Screen Off field in
;* the Clocking Mode register (Hmmmm....).
;*
;* To read palette colors:
;* - Out color # to 3c7h
;* - In RGB values from 3c9h (data must be read in three's; PEL address
;*   register auto-increments after 3 reads or writes)
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     SetPalette       - Set the palette without waiting to Vblank.
;*     ReadPalette      - Read the palette from the display adapter.
;*     SetDAC           - Set a single palette color in the DAC.
;*     TranslatePalette - Translate 24-bit color to 15-bit color.
;*      
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	INCLUDE	"vga.i"
	CODESEG

;****************************************************************************
;*
;* NAME
;*     SetPalette - Set the palette without waiting to Vblank.
;*
;* SYNOPSIS
;*     SetPalette(Palette, Numbytes, SlowFlag)
;*
;*     void SetPalette(char *, long, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Palette  - Pointer to the palette to set.
;*     NumBytes - Number of bytes of palette to transfer (multiple of 3).
;*     SlowFlag - Slow palette set flag.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C SetPalette:NEAR
	PROC	SetPalette C NEAR USES eax ecx edx esi ds

	ARG	palette:NEAR PTR
	ARG	numbytes:DWORD
	ARG	slowpal:DWORD

	pushf
	cld

	cmp	[slowpal],0	;Do slow palette?
	jne	??safe_palette_routine

;----------------------------------------------------------------------------
;	Fast palette set
;----------------------------------------------------------------------------

	mov	esi,[palette]
	mov	edx,PEL_WRITE_ADDR
	xor	al,al			
	out	dx,al	;Select color to write too.
	inc	al	;Step to the next color for next loop
	inc	edx	;DX = PEL_DATA
	mov	ecx,[numbytes]	;Max # colors to set
	rep 	outsb	;Write 256 * RGB out to the palette
	popf
	ret
	
;----------------------------------------------------------------------------
;	Safe palette set
;----------------------------------------------------------------------------

??safe_palette_routine:
	mov	esi,[palette]
	mov	ecx,[numbytes]
	mov	edx,PEL_WRITE_ADDR
	sub	eax,eax
	out	dx,al
	mov	edx,PEL_DATA

??Write_loop:
	lodsb
	out	dx,al	;Red
	jmp	$+02	;Delay (flush instruction cache)

	lodsb
	out	dx,al	;Green
	jmp	$+02	;Delay (flush instruction cache)

	lodsb
	out	dx,al	;Blue
	jmp	$+02	;Delay (flush instruction cache)

	sub	cx,3
	ja	??Write_loop

	popf
	ret

	ENDP	SetPalette


;****************************************************************************
;*
;* NAME
;*     ReadPalette - Read the palette from the display adapter.
;*
;* SYNOPSIS
;*     ReadPalette(Palette)
;*
;*     void SetPalette(char *);
;*
;* FUNCTION
;*
;* INPUTS
;*     Palette - Pointer buffer to copy palette into.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C ReadPalette:NEAR
	PROC	ReadPalette C NEAR USES ecx edx edi es

	ARG	palette:NEAR PTR

	mov	edi,[palette]
	mov	ecx,256
	mov	edx,PEL_READ_ADDR
	sub	eax,eax
	out	dx,al
	mov	edx,PEL_DATA

??Read_loop:
	in	al,dx	;Red
	stosb		;Save the byte
	jmp	$+02	;Delay (flush instruction cache)

	in	al,dx	;Green
	stosb		;Save the byte
	jmp	$+02	;Delay (flush instruction cache)

	in	al,dx	;Blue
	stosb		;Save the byte
	jmp	$+02	;Delay (flush instruction cache)

	dec	ecx
	jnz	??Read_loop
	ret

	ENDP	ReadPalette


;****************************************************************************
;*
;* NAME
;*     SetDAC - Set a single palette color in the DAC.
;*
;* SYNOPSIS
;*     SetDAC(ColorNum, Red, Green, Blue)
;*
;*     void SetPalette(long, char, char);
;*
;* FUNCTION
;*
;* INPUTS
;*     ColorNum - Position number in palette of color to set.
;*     Red      - Red gun value.
;*     Green    - Green gun value.
;*     Blue     - Blue gun value.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C SetDAC:NEAR
	PROC	SetDAC C NEAR USES edx

	ARG	color_num:DWORD
	ARG	red:BYTE
	ARG	green:BYTE
	ARG	blue:BYTE

	mov	edx,PEL_WRITE_ADDR
	mov	eax,[color_num]
	out	dx,al	;Set color position
	inc	edx
	jmp	$+02	;Delay (flush instruction cache)

	mov	al,[red]
	out	dx,al	;Set red gun
	jmp	$+02	;Delay (flush instruction cache)

	mov	al,[green]
	out	dx,al	;Set green gun
	jmp	$+02	;Delay (flush instruction cache)

	mov	al,[blue]
	out	dx,al	;Set blue gun
	ret

	ENDP	SetDAC


;****************************************************************************
;*
;* NAME
;*     TranslatePalette - Translate 24-bit color to 15-bit color.
;*
;* SYNOPSIS
;*     TranslatePalette(Pal24, Pal15, NumBytes)
;*
;*     void TranslatePalette(char *, char *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Pal24 - Pointer to 24-bit palette. (Input)
;*     Pal15 - Pointer to 15-bit palette. (Output)
;*     NumBytes - Number of bytes to translate. (divisible by 3)
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C TranslatePalette:NEAR
	PROC	TranslatePalette C NEAR USES ecx edx edi esi

	ARG	pal24:NEAR PTR
	ARG	pal15:NEAR PTR
	ARG	numbytes:DWORD

	mov	esi,[pal24]
	mov	edi,[pal15]
	mov	ecx,[numbytes]

??TranslatePalette:
	mov	ah,[BYTE PTR esi]	;AH = red
	mov	al,[BYTE PTR esi+1]	;AL = green
	mov	dl,[BYTE PTR esi+2]	;DL = blue
	shr	ah,1		;Red = lower 5 bits of AH
	shl	al,2		;Green = upper 6 bits of AL
	shr	dl,1		;Blue = lower 5 bits of DL
	shl	eax,2		;Make room for blue
	and	al,0E0h		;Trim off bottom bit of green
	or	al,dl		;Load in blue bits
	mov	[WORD PTR edi],ax	;Store the value
	add	esi,3		;Increment to next RGB values
	add	edi,2		;Increment to next palette word
	sub	ecx,3
	ja	??TranslatePalette
	ret

	ENDP	TranslatePalette

	END
