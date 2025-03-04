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
;*     lcwuncmp.asm
;*
;* DESCRIPTION
;*     LCW uncompress routine. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Chris Yates
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     LCW_Uncompress - Uncompress LCW encoded data.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

;****************************************************************************
;*
;* NAME
;*     LCW_Uncompress - Uncompress LCW encoded data.
;*
;* SYNOPSIS
;*     Size = LCW_Uncompress(Source, Dest, Length)
;*
;*     LONG LCW_Uncompress(void *, void *, long);
;*
;* FUNCTION
;*     Uncompress data to the following codes in the format b = byte,
;*     w = word, n = byte code pulled from compressed data.
;*
;*     Bit field of n            Command     Description
;*     ------------------------------------------------------------------
;*     n=0xxxyyyy,yyyyyyyy       short run   back y bytes and run x+3
;*     n=10xxxxxx,n1,n2,..,nx+1  med length  copy the next x+1 bytes
;*     n=11xxxxxx,w1             med run     run x+3 bytes from offset w1
;*     n=11111111,w1,w2          long copy   copy w1 bytes from offset w2
;*     n=11111110,w1,b1          long run    run byte b1 for w1 bytes
;*     n=10000000                end         end of data reached
;*
;* INPUTS
;*     Source - Pointer to LCW encoded data.
;*     Dest   - Pointer to buffer to uncompress into.
;*     Length -
;*
;* RESULT
;*     Size - Size of uncompressed data in bytes.
;*
;****************************************************************************

	GLOBAL	C LCW_Uncompress:NEAR
	PROC	LCW_Uncompress C NEAR USES ebx ecx edx esi edi

	ARG	source:DWORD
	ARG	dest:DWORD
	ARG	length:DWORD

	LOCAL	a1stdest:DWORD
	LOCAL	maxlen:DWORD
	LOCAL	lastbyte:DWORD
	LOCAL	lastcom:DWORD
	LOCAL	lastcom1:DWORD

	mov	esi,[source]		;ESI - Source address
	mov	edi,[dest]		;EDI - Destination address
	mov	edx,[length]		;EDX - Maximum length

	mov	[a1stdest],edi		;Save dest address
	add	edx,edi		;Last address (Dest + length)
	mov	[lastbyte],edx

	cld			;Forward direction
	mov	ebx,esi		;Save source address

??loop:
;	Exit if no bytes are remaining.

	mov	eax,[lastbyte]
	sub	eax,edi
	jz	short ??out

	mov	[maxlen],eax		;Save for string commands
	mov	esi,ebx		;Restore source address
	lodsb
	or	al,al		;See if its a short run
	js	short ??notshort

	mov	ah,al		;Put rel offset high nibble in ah
	and	ah,0Fh		; Only 4 bits count
 	sub	ecx,ecx
	mov	ch,al		;Put count nibble in ch
	shr	ch,4
	mov	cl,ch
	xor	ch,ch
	add	ecx,3		;Get actual run length
	cmp	ecx,[maxlen]		;Is it too big to fit?
	jbe	short ??rsok		;If not, its ok

	mov	ecx,[maxlen]		;If so, max it out so it dosen't overrun

??rsok:
	lodsb			;Get rel offset low byte
	mov	ebx,esi		;Save the source address
	mov	esi,edi		;Get the current dest
	sub	esi,eax		;Get relative offset
	rep	movsb
	jmp	??loop

??notshort:
	test	al,40h		;Is it a length?
	jne	short ??notlength	;If not it could be med or long run

;	If end code then exit.

	cmp	al,80h
	je	short ??out

	mov	cl,al		;Put the byte in count register
	and	ecx,3Fh		;Mask off the extra bits
	cmp	ecx,[maxlen]		;Is it too big to fit?
	jbe	short ??lenok		;If not, its ok

	mov	ecx,[maxlen]		;If so, max it out so it dosen't overrun

??lenok:
	rep	movsb
	mov	ebx,esi		;Save the source offset
	jmp	??loop

??out:
      	mov	eax,edi
	sub	eax,[a1stdest]
	jmp	short ??exit

??notlength:
	mov	cl,al		;Get the entire code
	and	ecx,3Fh		;Mask off all but the size -3
	add	ecx,3		;Add 3 for byte count
	cmp	al,0FEh
	jne	short ??notrunlength

	sub	eax,eax
	lodsw
	mov	ecx,eax
	sub	eax,eax
	lodsb
	mov	ebx,esi		;Save the source offset
	cmp	ecx,[maxlen]		;Is it too big to fit?
	jbe	short ??runlenok	;If not, its ok

	mov	ecx,[maxlen]		;If so, max it out so it dosen't overrun

??runlenok:
	rep	stosb
	jmp	??loop

??notrunlength:
	cmp	al,0FFh		;Is it a long run?
	jne	short ??notlong	;If not use the code as the size

	sub	eax,eax
	lodsw			;If so, get the size
	mov	ecx,eax		;Put int the count byte

??notlong:
	lodsw			;Get the rel index
	mov	ebx,esi		;Save the source offset
	add	eax,[a1stdest]		;Add in the first index
	mov	esi,eax		;Use this as a source
	cmp	ecx,[maxlen]		;Is it too big to fit?
	jbe	short ??runok		;If not, its ok

	mov	ecx,[maxlen]		;If so, max it out so it dosen't overrun

??runok:
	rep	movsb
	jmp	??loop

??exit:
	mov	eax,edi
	mov	ebx,[dest]
	sub	eax,ebx		;Calculate bytes uncompressed.
	ret

	ENDP	LCW_Uncompress

	END
        
