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
;*     lcwcomp.asm
;*
;* DESCRIPTION
;*     LCW compression code. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Louis Castle
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     LCW_Compress - LCW compress a buffer of memory.
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
;*     LCW_Compress - LCW compress a buffer of memory.
;*
;* SYNOPSIS
;*     Size = LCW_Compress(Source, Dest, Length)
;*
;*     long LCW_Compress(void *, void *, long);
;*
;* FUNCTION
;*
;* INPUTS
;*     Source - Pointer to data to compress.
;*     Dest   - Pointer to buffer to put compressed data.
;*     Length - Length in bytes of data to compress.
;*
;* RESULT
;*     Size - Size in bytes of compresed data.
;*
;****************************************************************************

	GLOBAL	C LCW_Compress:NEAR
	PROC	LCW_Compress C NEAR USES ebx ecx edx esi edi

	ARG	source:DWORD
	ARG	dest:DWORD
	ARG	datasize:DWORD

	LOCAL	inlen:DWORD
	LOCAL	a1stdest:DWORD
	LOCAL	a1stsrc:DWORD
	LOCAL	lenoff:DWORD
	LOCAL	ndest:DWORD
	LOCAL	count:DWORD
	LOCAL	matchoff:DWORD
	LOCAL	end_of_data:DWORD

	mov	esi,[source]
	mov	edi,[dest]
	mov	edx,[datasize]

	cld			;Forward direction
	mov	ebx,esi
	add	ebx,edx
	mov	[end_of_data],ebx	;Save end of source address
	mov	[inlen],1		;Set the in-length flag
	mov	[a1stdest],edi	 	;Save original dest
	mov	[a1stsrc],esi	 	;Save original source
	mov	[lenoff],edi	 	;Save offset length

	mov	al,081h		;First byte is always a len
	stosb			;Write out a len of 1
	lodsb			;Get the byte
	stosb			;Save it

??loop:
	mov	[ndest],edi		;Save offset of compressed data
	mov	edi,[a1stsrc]		;Get address of first byte
	mov	[count],1		;Set the count of run to 0

??searchloop:
 	sub	eax,eax
	mov	al,[esi]		;Get the current byte of data
	cmp	al,[esi + 64]
	jne	short ??notrunlength

	mov	ebx,edi
	mov	edi,esi
	mov	ecx,[end_of_data]
	sub	ecx,edi
   	repe	scasb
	dec	edi
	mov	ecx,edi
	sub	ecx,esi
	cmp	ecx,65
	jb	short ??notlongenough

	mov	[inlen],0		;Clear the in-length flag
	mov	esi,edi
	mov	edi,[ndest]
	mov	ah,al
	mov	al,0FEh
	stosb
	xchg	ecx,eax
	stosw
	mov	al,ch
	stosb

	mov	[ndest],edi		;Save offset of compressed data
	mov	edi,ebx
	jmp	??searchloop

??notlongenough:
	mov	edi,ebx

??notrunlength:
??oploop:
	mov	ecx,esi		;Address of the last byte +1
	sub	ecx,edi		;Total number of bytes left
	jz	short ??searchdone

	repne	scasb		;Look for a match
	jne	short ??searchdone	;If we don't find one we're done

	mov	ebx,[count]
	mov	ah,[esi+ebx-1]
	cmp	ah,[edi+ebx-2]
	jne	??oploop

	mov	edx,esi		;Save address for the next search
	mov	ebx,edi		;Save address for the length calc
	dec	edi		;Back up one for compare
	mov	ecx,[end_of_data]	;Get the end of data
	sub	ecx,esi		;Sub current source for max len
	repe	cmpsb  		;See how many bytes match
	jne	short ??notend

	inc	edi

??notend:
	mov	esi,edx
	mov	eax,edi		;Get the dest
	sub	eax,ebx		;Sub the start for total bytes that match
	mov	edi,ebx		;Restore dest
	cmp	eax,[count]		;See if its better than before
	jb	??searchloop		;If not keep looking

	mov	[count],eax		;If so keep the count
	dec	ebx		;Back it up for the actual match offset
	mov	[matchoff],ebx 	;Save the offset for later
	jmp	??searchloop		;Loop until we searched it all

??searchdone:
	mov	ecx,[count]		;Get the count of the longest run
	mov	edi,[ndest]		;Get the paragraph of our compressed data
	cmp	ecx,2		;See if its not enough run to matter
	jbe	short ??lenin		;If its 0,1, or 2 its too small

	cmp	ecx,10		;If not, see if it would fit in a short
	ja	short ??medrun		;If not, see if its a medium run

	mov	eax,esi		;If its short get the current address
	sub	eax,[matchoff] 	;Sub the offset of the match
	cmp	eax,0FFFh		;If its less than 12 bits its a short
	ja	short ??medrun		;If its not, its a medium

??shortrun:
	mov	bl,cl		;Get the length (3-10)
	sub	bl,3		;Sub 3 for a 3 bit number 0-7
	shl	bl,4
	add	ah,bl
	xchg	ah,al
	jmp	short ??srunnxt	;Do the run fixup code

??medrun:
	cmp	ecx,64		;See if its a short run
	ja	short ??longrun	;If not, oh well at least its long

	sub	cl,3		;Back down 3 to keep it in 6 bits
	or	cl,0C0h		;The highest bits are always on
	mov	al,cl		;Put it in al for the stosb
	stosb			;Store it
	jmp	short ??medrunnxt 	;Do the run fixup code

??lenin:
	cmp	[inlen],0		;Is it doing a length?
	jnz	short ??len		;If so, skip code

??lenin1:
	mov	[lenoff],edi		;Save the length code offset
	mov	al,80h		;Set the length to 0
	stosb			;Save it

??len:
	mov	ebx,[lenoff]		;Get the offset of the length code
	cmp	[BYTE PTR ebx],0BFh	;See if its maxed out
	je	??lenin1		;If so put out a new len code

??stolen:
	inc	[BYTE PTR ebx] 	;Inc the count code
	lodsb			;Get the byte
	stosb			;Store it
	mov	[inlen],1		;We are now in a length so save it
	jmp	short ??nxt		;Do the next code

??longrun:
	mov	al,0FFh		;Its a long so set a code of FF
	stosb			;Store it
	mov	eax,[count]		;Send out the count
	stosw			;Store it

??medrunnxt:
	mov	eax,[matchoff] 	;Get the offset
	sub	eax,[a1stsrc]		;Make it relative tot he start of data

??srunnxt:
	stosw			;Store it
	add	esi,[count]		;Add in the length of the run to the source
	mov	[inlen],0		;Set the in leght flag to false

??nxt:
	cmp	esi,[end_of_data]	;See if we did the whole pic
	jae	short ??out		;If so, cool! were done
	jmp	??loop

??out:
	mov	eax,080h		;Remember to send an end of data code
	stosb			;Store it
	mov	eax,edi		;Get the last compressed address
	sub	eax,[a1stdest]		;Sub the first for the compressed size
	ret

	ENDP	LCW_Compress

	END
