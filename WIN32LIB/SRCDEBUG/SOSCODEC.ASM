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
;*          Copyright (c) 1994, HMI, INC. All Rights Reserved
;*
;*---------------------------------------------------------------------------
;*
;* FILE
;*     soscodec.asm
;*
;* DESCRIPTION
;*     HMI SOS ADPCM compression/decompression.
;*
;* PROGRAMMER
;*     Nick Skrepetos
;*     Denzil E. Long, Jr. (Fixed bugs, rewrote for watcom)
;*     Bill Petro		   (Added stereo support)
;*     Jonathan Lanier
;*
;* DATE
;*     Febuary 15, 1995
;*
;* LAST MODIFIED
;*     08/07/95 [jdl] - Rewrote/optimized sosCODECDecompressData
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??

DPMI_INTR		equ	31h
IF_LOCKED_PM_CODE	equ	1h		; Locked PM code for DPMI.
IF_LOCKED_PM_DATA	equ	2h		; Locked PM code for DPMI.

STRUC	sCompInfo
lpSource		DD	?	;Compressed data pointer
lpDest			DD	?	;Uncompressed data pointer
dwCompSize		DD	?	;Compressed size
dwUnCompSize		DD	?	;Uncompressed size

dwSampleIndex		DD	?	;Index into sample
dwPredicted		DD	?	;Next predicted value
dwDifference		DD	?	;Difference from last sample
wCodeBuf		DW	?	;Holds 2 nibbles for decompression
wCode			DW	?	;Current 4 bit code
wStep			DW	?	;Step value in table
wIndex			DW	?	;Index into step table

dwSampleIndex2		DD	?	;Index into sample
dwPredicted2		DD	?	;Next predicted value
dwDifference2		DD	?	;Difference from last sample
wCodeBuf2 		DW	?	;Holds 2 nibbles for decompression
wCode2			DW	?	;Current 4 bit code
wStep2			DW	?	;Step value in table
wIndex2			DW	?	;Index into step table

wBitSize		DW	?	;Bit size for decompression
wChannels		DW	?    	;number of channels
ENDS	sCompInfo


	DATASEG


InitFlags	DD	0		; Flags to indicate what has been initialized.


LABEL	LockedDataStart	BYTE

;* Index table for stepping into step table

INCLUDE		"difftb.inc"
INCLUDE		"indextb.inc"
INCLUDE		"nybbtb.inc"

LABEL	LockedDataEnd	BYTE

	CODESEG

LABEL	LockedCodeStart	BYTE

;****************************************************************************
;*
;* NAME
;*     sosCODECInitStream - Initialize compression stream.
;*
;* SYNOPSIS
;*     sosCODECInitStream(CompInfo)
;*
;*     void sosCODECInitStream(_SOS_COMPRESS_INFO *);
;*
;* FUNCTION
;*     Initialize compression stream for compression and decompression.
;*
;* INPUTS
;*     CompInfo - Compression information structure.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	sosCODECInitStream:NEAR
	PROC	sosCODECInitStream C NEAR

	ARG	sSOSInfo:NEAR PTR

	mov	eax,[sSOSInfo]
	mov	[(sCompInfo eax).wIndex],0 		; starting index 0
	mov	[(sCompInfo eax).dwPredicted],0 	; no predicted value
	mov	[(sCompInfo eax).wIndex2],0 		; starting index 0
	mov	[(sCompInfo eax).dwPredicted2],0 	; no predicted value
	ret

	ENDP	sosCODECInitStream



;****************************************************************************
;*
;* NAME
;*     sosCODECDecompressData - Decompress audio data.
;*
;* SYNOPSIS
;*     Size = sosCODECDecompressData(CompInfo, NumBytes)
;*
;*     long sosCODECDecompressData(_SOS_COMPRESS_INFO *, long);
;*
;* FUNCTION
;*     Decompress data from a 4:1 ADPCM compressed stream. The number of
;*     bytes decompressed is returned.
;*
;* INPUTS
;*     CompInfo - Compress information structure.
;*     NumBytes - Number of bytes to decompress.
;*
;* RESULT
;*     Size - Size of decompressed data.
;*
;*
;* NOTES
;*     This routine has been optimized for pipelining on both
;*     486 and Pentium processors.  Changing, inserting, or moving any
;*     instructions will most likely slow down the code, in some cases by
;*     as much as 20%.  It can burst-decompress 16384 samples in about
;*     1940æs on a Pentium 90Mhz, and about 3960æs on a 486 66Mhz.
;*     Instruction reordering could bring this down to below 1870æs on
;*     the Pentium, but this would cause a great degradation in 486
;*     performance.  Since slow 486's are the reason this code was
;*     written to be fast, it has been optimized for the Pentium only where
;*     it would not degrade 486 performance.  So, be careful when changing
;*     ANY of this code, because it is very carefully balanced...
;****************************************************************************

	GLOBAL	C sosCODECDecompressData:NEAR
	PROC	sosCODECDecompressData C NEAR

	ARG	sSOSInfo:NEAR PTR
	ARG	wBytes:DWORD

	push	esi
	push	edi
	push	ebx
	push	ecx
	push	edx			;save all the regs

	mov	ebx,[sSOSInfo]		;get base of sCompInfo struct
	mov	cx,[(sCompInfo ebx).wBitSize] ;check the bit size
	mov	dx,[(sCompInfo ebx).wChannels] ;check the number of channels
;
;
; Determine the correct routine to use for decoding
; (for now only ADPCM 4:1 Mono 16-bit is implemented)
	cmp	cx,8
	jne	??do16Bits

??do8Bits:
	cmp	dx,2
	jne	??not8Stereo
;	jmp	??decomp8Stereo
	jmp	??byeBye

??not8Stereo:
	cmp	dx,1
	jne	??byeBye
;	jmp	decomp8Mono
	jmp	??byeBye

??do16Bits:
	cmp	cx,16
	jne	??byeBye

	cmp	dx,2
	jne	??not16Stereo
;	jmp	??decomp16Stereo
	jmp	??byeBye

??not16Stereo:
	cmp	dx,1
	jne	??byeBye

	push	ebp
;
;
; 16 bit ADPCM 4:1 Mono pre-loop initialization
??decomp16Mono:
	push	ebx			;save struct base
	xor	edx,edx			;clear index
	mov	eax,[(sCompInfo ebx).dwPredicted]	;get last sample
	mov	dx,[(sCompInfo ebx).wIndex]	;get last index value
	mov	esi,[(sCompInfo ebx).lpSource]	;get source address
	mov	edi,[(sCompInfo ebx).lpDest]	;get dest address

	mov	ebp,[wBytes]		;get the number of dest. bytes
	cmp	ebp,16			;less than 16? (less than 8 samples)
	jl	??fixAlign16Mono0	;if so, don't bother with alignment
;
;
; Check to see if we need to fix an alignment problem on the source buffer
; (non-aligned buffers are MUCH slower; if we're given a non-DWORD aligned
; source address, we do as many samples as needed to get to the nearest
; DWORD boundary, then finish the bulk as a DWORD-aligned decompress).
	mov	ebx,esi			;get source address
	and	ebx,03h			;check LSB
	jnz	??fixalign16Mono	;if non-zero, need to align for
					;warp speed
??fixAlign16Mono0:
	push	ebp			;save for later
	shr	ebp,4			;divide by 16 for 16-bit,
					;because we do 8 nybbles per loop,
					;and there are two samples per
					;byte, so there are n/16 iterations
					;required
	xor	ebx,ebx			;clear our nybble index
	or	ebp,ebp			;set flags for EBP
	jmp	??start16Mono		;start with test... don't go if
					;we have zero bytes to do
??fixalign16Mono:
	jmp	[DWORD PTR dwMono16AlignJmpTable+ebx*4] ;do non-aligned first

	align	4
??fixAlign16Mono1:
	sub	ebp,12			;adjust # of dest. bytes
	push	ebp			;save it
	shr	ebp,4			;divide by 16 to get samples/8
	xor	ebx,ebx			;clear our nybble index
	inc	ebp			;adjust ebp for loop
	jmp	??finish16Mono6		;borrow exit code to go through a
					;piece of a loop
	align	4
??fixAlign16Mono2:
	sub	ebp,8			;adjust # of dest. bytes
	push	ebp			;save it
	shr	ebp,4			;divide by 16 to get samples/8
	xor	ebx,ebx			;clear our nybble index
	inc	ebp			;adjust ebp for loop
	jmp	??finish16Mono4		;borrow exit code to go through a
					;piece of a loop
	align	4
??fixAlign16Mono3:
	sub	ebp,4			;adjust # of dest. bytes
	push	ebp			;save it
	shr	ebp,4			;divide by 16 to get samples/8
	xor	ebx,ebx			;clear our nybble index
	inc	ebp			;adjust ebp for loop
	jmp	??finish16Mono2		;borrow exit code to go through a
					;piece of a loop
; "The Loop"
;
; Process 1st nybble
	align	4
??loop16Mono:
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix1Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix1Smp16MonoU
??fixed1Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	mov	[edi],ax		;save the sample
;
;
; Process 2nd nybble
??finish7Smp16Mono:
	mov	bl,ch			;get next 2 nybbles in ebx
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix2Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix2Smp16MonoU
??fixed2Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	mov	[edi+02h],ax		;save the sample
	shr	ecx,16			;move top four nybbles into bottom
;
;
; Process 3rd nybble
??finish6Smp16Mono:
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix3Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix3Smp16MonoU
??fixed3Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	mov	[edi+04h],ax		;save the sample
;
;
; Process 4th nybble
??finish5Smp16Mono:
	mov	bl,cl
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix4Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix4Smp16MonoU
??fixed4Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	mov	[edi+06h],ax		;save the sample
;
;
; Process 5th nybble
??finish4Smp16Mono:
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix5Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix5Smp16MonoU
??fixed5Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	mov	[edi+08h],ax		;save the sample
;
;
; Process 6th nybble
??finish3Smp16Mono:
	mov	bl,ch
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix6Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix6Smp16MonoU
??fixed6Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	mov	[edi+0Ah],ax		;save the sample
;
;
; Process 7th nybble
??finish2Smp16Mono:
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix7Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix7Smp16MonoU
??fixed7Smp16Mono:
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	mov	[edi+0Ch],ax		;save the sample
;
;
; Process 8th nybble
??finish1Smp16Mono:
	add	eax,[dwDiffTable+edx*2]	;add difference to prev. sample
	mov	dx,[wIndexTable+edx]	;adjust dx to next index base
	cmp	eax,00007FFFh		;check for overflow
	jg	??fix8Smp16MonoO
	cmp	eax,0FFFF8000h		;check for underflow
	jl	??fix8Smp16MonoU
;
;
; Loop cleanup for next pass
??fixed8Smp16Mono:
	mov	[edi+0Eh],ax		;save the sample
	add	esi,04h			;bump esi to point to next longword
	add	edi,10h			;incr. the destination buffer ptr
	dec	ebp			;count down the number of samples/8
??start16Mono:
	jng	??cleanup16Mono		;if done, clean up
	mov	ecx,[esi]		;get 4 nybbles in one whack (whee!)
	mov	bl,cl			;get next 2 nybbles in ebx
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	jmp	??loop16Mono		;loop until done

??cleanup16Mono:
	jnz	??done16Mono		;if ebp is non-zero, we're DONE
					;if exactly zero, finish the tail-end
					;of the conversion (may be a non-
					;multiple of 8 nybbles)
;
;
; Loop cleanup for last (incomplete) pass
	pop	ecx			;restore # of words
	shr	ecx,1			;divide by two to get samples
	and	ecx,07h			;get # of samples we missed
	jmp	[DWORD PTR dwMono16JmpTable+ecx*4] ;go finish the job...
;
;
; Structure cleanup
??done16Mono:
	pop	ebx			;restore struct base
	pop	ebp			;restore stack frame pointer
	mov	[(sCompInfo ebx).dwPredicted],eax ;save last sample
	mov	[(sCompInfo ebx).wIndex],dx ;save last index value
	mov	eax,[wBytes]		;get # of bytes we did
??byeBye:
	pop	edx			;restore all the regs
	pop	ecx
	pop	ebx
	pop	edi
	pop	esi
	ret
;
;
; Jumps for -32768/+32767 bounds check go to these vvvv
	align	4
??fix1Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed1Smp16Mono	;go back

	align	4
??fix1Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed1Smp16Mono	;go back

	align	4
??fix2Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed2Smp16Mono	;go back

	align	4
??fix2Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed2Smp16Mono	;go back

	align	4
??fix3Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed3Smp16Mono	;go back

	align	4
??fix3Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed3Smp16Mono	;go back

	align	4
??fix4Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed4Smp16Mono	;go back

	align	4
??fix4Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed4Smp16Mono	;go back

	align	4
??fix5Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed5Smp16Mono	;go back

	align	4
??fix5Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed5Smp16Mono	;go back

	align	4
??fix6Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed6Smp16Mono	;go back

	align	4
??fix6Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed6Smp16Mono	;go back

	align	4
??fix7Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed7Smp16Mono	;go back

	align	4
??fix7Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed7Smp16Mono	;go back

	align	4
??fix8Smp16MonoO:
	mov	eax,00007FFFh		;Overflow - truncate to +32767
	jmp	??fixed8Smp16Mono	;go back

	align	4
??fix8Smp16MonoU:
	mov	eax,0FFFF8000h		;Underflow - truncate to -32768
	jmp	??fixed8Smp16Mono	;go back
;
;
; Jump tables for cleanup after loop unroll point to these vvvv
	align	4
??finish16Mono1:
	xor	ecx,ecx			;clear nybble bucket
	mov	ch,[esi]		;get 1 nybble (1 byte)
	shl	ch,4			;move it over
	mov	bl,ch			;get nybble in ebx
	sub	edi,0Eh			;back edi up
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	jmp	??finish1Smp16Mono	;go finish it

	align	4
??finish16Mono2:
	xor	ecx,ecx			;clear nybble bucket
	mov	ch,[esi]		;get 2 nybbles (1 byte)
	mov	bl,ch			;get nybbles in ebx
	sub	edi,0Ch			;back edi up
	sub	esi,3			;adjust esi (used for dword aligning)
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	jmp	??finish2Smp16Mono	;go finish it

	align	4
??finish16Mono3:
	xor	ecx,ecx			;clear nybble bucket
	mov	cx,[esi]		;get 3 nybbles (2 bytes)
	shl	cx,4			;move it over
	mov	bl,cl			;get nybbles in ebx
	sub	edi,0Ah			;back edi up
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	jmp	??finish3Smp16Mono	;go finish it

	align	4
??finish16Mono4:
	xor	ecx,ecx			;clear nybble bucket
	mov	cx,[esi]		;get 4 nybbles (2 bytes)
	mov	bl,cl			;get nybbles in ebx
	sub	edi,08h			;back edi up
	sub	esi,2			;adjust esi (used for dword aligning)
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	jmp	??finish4Smp16Mono	;go finish it

	align	4
??finish16Mono5:
	xor	ecx,ecx			;clear nybble bucket
	mov	cl,[esi+2]		;get 1 nybble (1 byte)
	shl	ecx,16			;shift it over
	mov	cx,[esi]		;get 4 nybbles (2 bytes)
	mov	bl,cl			;get nybbles in ebx
	shr	ecx,4			;move it over
	shl	bl,4			;move it over
	sub	edi,06h			;back edi up
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	jmp	??finish5Smp16Mono	;go finish it

	align	4
??finish16Mono6:
	xor	ecx,ecx			;clear nybble bucket
	mov	cl,[esi+2]		;get 2 nybbles (1 byte)
	shl	ecx,16			;move it over
	mov	cx,[esi]		;get 4 nybbles (2 bytes)
	mov	bl,cl			;get nybbles in ebx
	shr	ecx,8			;move it over
	sub	esi,1			;adjust esi (used for dword aligning)
	sub	edi,04h			;back edi up
	or	dl,[BYTE PTR bNybbleTableLow+ebx] ;adjust index for nybble
	jmp	??finish6Smp16Mono	;go finish it

	align	4
??finish16Mono7:
	xor	ecx,ecx			;clear nybble bucket
	mov	ecx,[esi]		;get 7 nybbles (4 bytes)
	shl	ecx,4			;move it over
	mov	bl,cl			;get nybbles in ebx
	sub	edi,02h			;back edi up
	or	dl,[BYTE PTR bNybbleTableHigh+ebx] ;adjust index for nybble
	jmp	??finish7Smp16Mono	;go finish it
;
;
; Jump Tables
			align 4

dwMono16JmpTable	DD	??done16Mono
			DD	??finish16Mono1
			DD	??finish16Mono2
			DD	??finish16Mono3
			DD	??finish16Mono4
			DD	??finish16Mono5
			DD	??finish16Mono6
			DD	??finish16Mono7

			align 4
dwMono16AlignJmpTable	DD	??fixAlign16Mono0
			DD	??fixAlign16Mono1
			DD	??fixAlign16Mono2
			DD	??fixAlign16Mono3

	ENDP	sosCODECDecompressData

LABEL	LockedCodeEnd	BYTE

;***************************************************************************
;* sosCODEC_LOCK -- locks the JLB audio decompression code		   *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      BOOL true is lock sucessful, false otherwise		   *
;*                                                                         *
;* PROTO:       BOOL sosCODEC_Lock(void);                         	   *
;*                                                                         *
;* HISTORY:								   *
;*   06/26/1995 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	sosCODEC_Lock:NEAR
	PROC	sosCODEC_Lock C NEAR USES ebx ecx edx esi edi

	;
	; Lock the code that is used by the sos decompression method.
	;
	mov	eax,0600h			; function number.
	mov	ecx,OFFSET LockedCodeStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedCodeEnd	; edi will have size of region in bytes.
	shld	ebx,ecx,16
	sub	edi, ecx
	shld	esi,edi,16
  	int	DPMI_INTR			; do call.
	jc	??error
	or	[InitFlags], IF_LOCKED_PM_CODE

	;
	; Lock the data used by the sos decompression method.
	;
	mov	eax,0600h			; function number.
	mov	ecx,OFFSET LockedDataStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedDataEnd	; edi will have size of region in bytes.
	shld	ebx,ecx,16
	sub	edi, ecx
	shld	esi,edi,16
   	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.
	or	[InitFlags], IF_LOCKED_PM_DATA

	mov	eax,1
	jmp	??exit
??error:
	xor	eax,eax
??exit:
	ret
	ENDP	sosCODEC_Lock

;***************************************************************************
;* DECOMPRESS_FRAME_UNLOCK -- Unlocks the JLB audio compression code       *
;*                                                                         *
;* INPUT:	none                                                       *
;*                                                                         *
;* OUTPUT:      BOOL true is unlock sucessful, false otherwise		   *
;*                                                                         *
;* PROTO:	BOOL sosCODEC_Unlock(void);                        	   *
;*                                                                         *
;* HISTORY:								   *
;*   06/26/1995 PWG : Created.                                             *
;*=========================================================================*
	GLOBAL	sosCODEC_Unlock:NEAR
	PROC	sosCODEC_Unlock C NEAR USES ebx ecx edx esi edi

	test	[InitFlags],IF_LOCKED_PM_CODE
	jz	??code_not_locked

	mov	eax , 0601h
	mov	ecx,OFFSET LockedCodeStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedCodeEnd	; edx will have size of region in bytes.
	sub	edi,ecx				;  - figure size.
	shld	ebx , ecx , 16
	shld	esi , edi , 16
	int	DPMI_INTR			; do call.
	jc	??error

??code_not_locked:
	test	[InitFlags],IF_LOCKED_PM_DATA
	jz	??data_not_locked

	mov	ax,0601h				; set es to descriptor of data.
	mov	ecx,OFFSET LockedDataStart	; ecx must have start of memory.
	mov	edi,OFFSET LockedDataEnd	; edx will have size of region in bytes.
	sub	edi,ecx				;  - figure size.
	shld	ebx , ecx , 16
	shld	esi , edi , 16
	int	DPMI_INTR			; do call.
	jc	??error				; eax = 8 if mem err, eax = 9 if invalid mem region.

??data_not_locked:
	mov	[InitFlags],0
	mov	eax,1
	jmp	??exit
??error:
	xor	eax,eax
??exit:
	ret
	ENDP	sosCODEC_Unlock

	END

