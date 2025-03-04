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
;*	   Bill Petro		   (Added stereo support)
;* DATE
;*     Febuary 15, 1995
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

	STRUC	sCompInfo
lpSource	DD	?	;Compressed data pointer
lpDest	DD	?	;Uncompressed data pointer
dwCompSize	DD	?	;Compressed size
dwUnCompSize	DD	?	;Uncompressed size
wBitSize	DW	?	;Bit size for decompression
wChannels	DW	?	;number of channels

dwSampleIndex	DD	?	;Index into sample
dwPredicted	DD	?	;Next predicted value
dwDifference	DD	?	;Difference from last sample
wCodeBuf	DW	?	;Holds 2 nibbles for decompression
wCode	DW	?	;Current 4 bit code
wStep	DW	?	;Step value in table
wIndex	DW	?	;Index into step table

dwSampleIndex2	DD	?	;Index into sample
dwPredicted2	DD	?	;Next predicted value
dwDifference2	DD	?	;Difference from last sample
wCodeBuf2 	DW	?	;Holds 2 nibbles for decompression
wCode2	DW	?	;Current 4 bit code
wStep2	DW	?	;Step value in table
wIndex2	DW	?	;Index into step table
	ENDS	sCompInfo

	DATASEG

;* Index table for stepping into step table

wCODECIndexTab	DW	-1,-1,-1,-1,2,4,6,8
		DW	-1,-1,-1,-1,2,4,6,8


;Lookup table of replacement values
;The actual sound value is replaced with an index to lookup in this table
;The index only takes up a nibble(4bits) and represents an int(16bits)
;Essentially:
;Get a value
;compare it with the value before it
;find closest value in table and store the index into the table
;if i'm going down then negitize it
;go to next byte.

;Theory for stereo:
;1)handle stereo and mono in two seperate loops. cleaner...
;start at byte 0 and skip every other byte(or word) both write and read
;when we get done set start byte to 1 and do it again


;This table essentialy round off to closes values in 3 distinct bands
; precalculated and optimized(i guess) for human hearing.

wCODECStepTab	DW	7,8,9,10,11,12,13,14
	DW	16,17,19,21,23,25,28,31
	DW	34,37,41,45,50,55,60,66
	DW	73,80,88,97,107,118,130,143
	DW	157,173,190,209,230,253,279,307
	DW	337,371,408,449,494,544,598,658
	DW	724,796,876,963,1060,1166,1282,1411
	DW	1552,1707,1878,2066,2272,2499,2749,3024
	DW	3327,3660,4026,4428,4871,5358,5894,6484
	DW	7132,7845,8630,9493,10442,11487,12635,13899
	DW	15289,16818,18500,20350,22385,24623,27086,29794
	DW	32767

dwCODECByteIndex		DD	0 ; this is when to stop compressing
dwCODECBytesProcessed		DD	0 ; this is how many so far compressed
dwCODECTempStep		DD	0 ; tempory storage for step value
wCODECMask			DW	0 ; Current mask
	CODESEG

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

	GLOBAL	C VQA_sosCODECInitStream:NEAR
	PROC	VQA_sosCODECInitStream C NEAR

	ARG	sSOSInfo:NEAR PTR

	mov	eax,[sSOSInfo]
	mov	[(sCompInfo eax).wIndex],0 		; starting index 0
	mov	[(sCompInfo eax).wStep],7  		; start with a step of 7
	mov	[(sCompInfo eax).dwPredicted],0 	; no predicted value
	mov	[(sCompInfo eax).dwSampleIndex],0	;start at head of index
	mov	[(sCompInfo eax).wIndex2],0 		; starting index 0
	mov	[(sCompInfo eax).wStep2],7  		; start with a step of 7
	mov	[(sCompInfo eax).dwPredicted2],0 	; no predicted value
	mov	[(sCompInfo eax).dwSampleIndex2],0 	;start at head of index
	ret

	ENDP	VQA_sosCODECInitStream

;****************************************************************************
;*
;* NAME
;*     sosCODECCompressData - Compress audio data.
;*
;* SYNOPSIS
;*     Size = sosCODECCompressData(CompInfo, NumBytes)
;*
;*     long sosCODECCompressData(_SOS_COMPRESS_INFO *, long);
;*
;* FUNCTION
;*     Compress an audio data stream into 4:1 ADPCM. 16 bit data is
;*     compressed 4:1, 8 bit data is compressed 2:1.
;*
;* INPUTS
;*     CompInfo - Pointer to initialized compress information structure.
;*     NumBytes - Number of bytes to compress.
;*
;* RESULT
;*     Size - Size of compressed data.
;*
;****************************************************************************

	GLOBAL	C VQA_sosCODECCompressData:NEAR
	PROC	VQA_sosCODECCompressData C NEAR
	ARG	sSOSInfo:NEAR PTR
	ARG	wBytes:DWORD

	push	esi
	push	edi
	push	ebx
	push	ecx
	push	edx

;*---------------------------------------------------------------------------
;*	Initialize
;*---------------------------------------------------------------------------

	mov	ebx,[sSOSInfo]
	mov	eax,[wBytes]
	mov	[dwCODECBytesProcessed],eax
	mov	[(sCompInfo ebx).dwSampleIndex],0 	;start at head of index
	mov	[(sCompInfo ebx).dwSampleIndex2],0	;start at head of index

;	Check for 16 bit decompression

	cmp	[(sCompInfo ebx).wBitSize],16		;16 bit requested?
	jne	short ??skipByteDivide			;no so skip divide
	shr	eax,1					;divide size by 2

??skipByteDivide:
	mov	[dwCODECByteIndex],eax
	mov	esi,[(sCompInfo ebx).lpSource]	;ESI = source
	mov	edi,[(sCompInfo ebx).lpDest]		;EDI = dest

	cmp	[(sCompInfo ebx).wChannels],2		;stereo check
	je	??mainloopl

;------------------------------------------------------------------------
; Mono start
;------------------------------------------------------------------------

??mainloop:
	cmp	[(sCompInfo ebx).wBitSize],16  	;are we doing 16 bit
	jne	short ??input8Bit	       		;no. goto 8 bit input

	movsx	eax,[word ptr esi]	       		;Get 16bit sample
	add	esi,2
	jmp	short ??computeDiff				;skip 8 bit load

??input8Bit:
	mov	ah,[esi]					;Get 8bit sample
	inc	esi
	xor	al,al					;zero out low byte
	xor	ah,80h					;flip sign bit
	movsx	eax,ax

??computeDiff:
	movsx	ecx,[word ptr (sCompInfo ebx).dwPredicted]
	sub	eax,ecx					;sample-predicted
	xor	ecx,ecx					;clear ecx
	cmp	eax,0					;Diff > = 0
	jge	??positive

	neg	eax					;else difference= -difference
	or	ecx,8					;set nibble sign bit in ecx

??positive:
	mov	[(sCompInfo ebx).wCode],cx		;Store code
	movsx	ecx,[(sCompInfo ebx).wStep]   	;Get step value
	mov	[dwCODECTempStep],ecx
	mov	edx,4					;mask value (i think)
	mov	ecx,3					;loop count

??quantizeLoop:
	cmp	eax,[dwCODECTempStep]	  		;Diff < step ?
	jl	short ??nextQLoop				;goto nextQloop

	; OR in mask value into code and adjust difference.

	or	[(sCompInfo ebx).wCode],dx		;else or mask into code
	sub	eax,[dwCODECTempStep]			;difference-=tempstep

??nextQLoop:
	shr	[dwCODECTempStep],1				; TempStep>>=1
	shr	edx,1					; mask>>=1
	loop	??quantizeLoop					; back to quatize loop

;-----------------------------------------------------------------------------------------
; now i'v got the new diff and code is masked right
;-----------------------------------------------------------------------------------------

	; store off new difference value

	mov	[(sCompInfo ebx).dwDifference],eax

	; determine if sample index is even or odd.
	; this will determine if we need to get a new token or not.

	test	[(sCompInfo ebx).dwSampleIndex],1 	; is it even? (starts at 0)
	jne	short ??storeToken			; if so goto store token

	; else its odd so get token

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode]		;ax=wCode
	and	eax,0Fh					;and off high nibble
	mov	[(sCompInfo ebx).wCodeBuf],ax		;wCodeBuf=ax
	jmp	short ??calcDifference			;goto calcDifference

??storeToken:
	; fetch new token

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode]		;ax=code
	shl	eax,4					;shift low nibble to high
	or	ax,[(sCompInfo ebx).wCodeBuf]		;or in the stored nibble
	mov	[edi],al				;*dest=al
	inc	edi					;dest++

??calcDifference:
	mov	[(sCompInfo ebx).dwDifference],0	;dwDifference=0
	xor	ecx,ecx					;ecx=0
	mov	cx,[(sCompInfo ebx).wStep]		;cx=Step
	xor	eax,eax					;eax=0
	mov	ax,[(sCompInfo ebx).wCode]		;ax=wCode
	test	eax,4					;Check 0100
	je	short ??no4
	add	[(sCompInfo ebx).dwDifference],ecx  	;difference+=step

??no4:
	test	eax,2					;Check 0010
	je	short ??no2
	mov	edx,ecx					;edx=wStep
	shr	edx,1					;edx>>1
	add	[(sCompInfo ebx).dwDifference],edx 	;Difference=wstep>>1

??no2:
	test	eax,1					;Check 0001
	je	short ??no1
	mov	edx,ecx					;edx=wStep
	shr	edx,2					;edx>>2
	add	[(sCompInfo ebx).dwDifference],edx 	;Difference=wstep>>2

??no1:
	mov	edx,ecx
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference],edx	;Difference=wstep>>3
	test	eax,8					;Check 1000
	je	short ??no8
	neg	[(sCompInfo ebx).dwDifference]		;Negate diff because sign bit was set

??no8:
	mov	eax,[(sCompInfo ebx).dwPredicted]
	add	eax,[(sCompInfo ebx).dwDifference]	;eax=Preditcted+Difference
	cmp	eax,7FFFh
	jl	short ??noOverflow
	mov	eax,7FFFh				;if overflow store 7fff in diff

??noOverflow:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflow
	mov	eax,0FFFF8000h				;if overflow  0FFFF8000 in diff

??noUnderflow:
	mov	[(sCompInfo ebx).dwPredicted],eax 	;store into predicted
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wCode]		;cx=Code
	xor	eax,eax
	shl	ecx,1					;cx<<1
	mov	ax,[wCODECIndexTab + ecx]		;ax=Indextab[ecx]
	add	[(sCompInfo ebx).wIndex],ax   		;wIndex+=ax
	cmp	[(sCompInfo ebx).wIndex],8000h		; check if wIndex < 0
	jb	short ??checkOverflow
	mov	[(sCompInfo ebx).wIndex],0		; reset index to zero
	jmp	short ??adjustStep

??checkOverflow:
	cmp	[(sCompInfo ebx).wIndex],88		; check if wIndex > 88
	jbe	short ??adjustStep
	mov	[(sCompInfo ebx).wIndex],88		; reset index to 88


??adjustStep:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex],1
	mov	[(sCompInfo ebx).wStep],ax

	; decrement bytes processed and loop back.

	dec	[dwCODECByteIndex]
	jne	??mainloop		    		; }while !0

	jmp	??exitout
;-----------------------------------------------------------------------
;Stereo	Left Side
;-----------------------------------------------------------------------

??mainloopl:
; determine bit size for input				;do{

	cmp	[(sCompInfo ebx).wBitSize],16  		;are we doing 16 bit
	jne	short ??input8Bitl	       		;no. goto 8 bit input		**

	movsx	eax,[word ptr esi]	       		;load next word from source
	add	esi,4					;inc source by 2 words  		**
	jmp	short ??computeDiffl			;skip 8 bit load			**

??input8Bitl:
	mov	ah,[esi]				;Get 8 bit sample
	add	esi,2   				;inc source by 2 bytes		**
	xor	al,al					;zero out low byte
	xor	ah,80h					;flip sign bit
	movsx	eax,ax					;sign extend into eax

??computeDiffl:
	; compute difference

	movsx	ecx,[word ptr (sCompInfo ebx).dwPredicted]
							;load predicted (starts at 0)
	sub	eax,ecx					;difference=sample-preditcted

	; check if dwDifference > 0.  ECX is the
	; sign bit, it is initialized to positive.

	xor	ecx,ecx				       	;clear ecx
	cmp	eax,0					;if(difference>=0)
	jge	short ??positivel			;goto positive

	neg	eax					;else difference= -difference
	or	ecx,8					;set nibble sign bit in ecx

??positivel:
	mov	[(sCompInfo ebx).wCode],cx		;Store code from cx into struct

	; set up to quantize difference. initialize
	; wCODECTempStep = step value.

	movsx	ecx,[(sCompInfo ebx).wStep]   		;ecx=step value(starts at 7)
	mov	[dwCODECTempStep],ecx			;tempstep=step
	mov	edx,4					;edx=4   mask value (i think)
	mov	ecx,3					;ecx is loop number so loop 3 times

??quantizeLoopl:
	; check to see if difference > tempstep value.

	cmp	eax,[dwCODECTempStep]	  		;if(difference < tempstep)
	jl	short ??nextQLoopl			;goto nextQloop

	; OR in mask value into code and adjust difference.

	or	[(sCompInfo ebx).wCode],dx		;else or mask into code
	sub	eax,[dwCODECTempStep]			;difference-=tempstep

??nextQLoopl:

	; shift down tempstep and mask

	shr	[dwCODECTempStep],1			; TempStep>>=1
	shr	edx,1					; mask>>=1
	loop	??quantizeLoopl				; back to quatize loop
;------------------------------------------------------------------------------------------
; now i'v got the new diff and code is masked right

	; store off new difference value

	mov	[(sCompInfo ebx).dwDifference],eax

	; determine if sample index is even or odd.
	; this will determine if we need to get a new token or not.

	test	[(sCompInfo ebx).dwSampleIndex],1 	; is it even? (starts at 0)
	jne	short ??storeTokenl			; if so goto store token		**

	; else its odd so get token

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode]		;ax=wCode
	and	eax,0Fh					;and off high nibble
	mov	[(sCompInfo ebx).wCodeBuf],ax		;wCodeBuf=ax
	jmp	short ??calcDifferencel			;goto calcDifference		**

??storeTokenl:
	; fetch new token

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode]		;ax=code
	shl	eax,4					;shift low nibble to hign nibble
	or	ax,[(sCompInfo ebx).wCodeBuf]		;or in the stored nibble
	mov	[edi],al				;*dest=al
	add	edi,2					;dest+=2					**

??calcDifferencel:
	mov	[(sCompInfo ebx).dwDifference],0;dwDifference=0
	xor	ecx,ecx					;ecx=0
	mov	cx,[(sCompInfo ebx).wStep]		;cx=Step
	xor	eax,eax					;eax=0
	mov	ax,[(sCompInfo ebx).wCode]		;ax=wCode
	test	eax,4					;Check 0100
	je	short ??no4l				;						**
	add	[(sCompInfo ebx).dwDifference],ecx  	;difference+=step

??no4l:
	test	eax,2					;Check 0010
	je	short ??no2l				;						**
	mov	edx,ecx					;edx=wStep
	shr	edx,1					;edx>>1
	add	[(sCompInfo ebx).dwDifference],edx 	;Difference=wstep>>1

??no2l:
	test	eax,1					;Check 0001
	je	short ??no1l				;						**
	mov	edx,ecx					;edx=wStep
	shr	edx,2					;edx>>2
	add	[(sCompInfo ebx).dwDifference],edx 	;Difference=wstep>>2

??no1l:
	mov	edx,ecx
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference],edx	;Difference=wstep>>3
	test	eax,8					;Check 1000
	je	short ??no8l

	;Negate diff because sign bit was set

	neg	[(sCompInfo ebx).dwDifference]

??no8l:
	mov	eax,[(sCompInfo ebx).dwPredicted]
	add	eax,[(sCompInfo ebx).dwDifference]	;eax=Preditcted+Difference
	cmp	eax,7FFFh
	jl	short ??noOverflowl
	mov	eax,7FFFh				;if overflow store 7fff in diff

??noOverflowl:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflowl
	mov	eax,0FFFF8000h				;if overflow  0FFFF8000 in diff

??noUnderflowl:
	mov	[(sCompInfo ebx).dwPredicted],eax 	;store into predicted
	xor	ecx,ecx					;adjust index
	mov	cx,[(sCompInfo ebx).wCode]		;cx=Code
	xor	eax,eax
	shl	ecx,1					;cx<<1
	mov	ax,[wCODECIndexTab + ecx]		;ax=Indextab[ecx]
	add	[(sCompInfo ebx).wIndex],ax   		;wIndex+=ax


	cmp	[(sCompInfo ebx).wIndex],8000h		;check if wIndex < 0
	jb	short ??checkOverflowl			;								**
	mov	[(sCompInfo ebx).wIndex],0		; reset index to zero
	jmp	short ??adjustStepl			;							**

??checkOverflowl:
	; check if wIndex > 88

	cmp	[(sCompInfo ebx).wIndex],88
	jbe	short ??adjustStepl			;							**

	; reset index to 88

	mov	[(sCompInfo ebx).wIndex],88

??adjustStepl:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex],1
	mov	[(sCompInfo ebx).wStep],ax

	; decrement bytes processed and loop back.

	sub	[dwCODECByteIndex],2    ; sub 2 for stereo					**
	jne	??mainloopl		    ; }while !0						**

;-------------------------------------------------------------------------
;Right channel re-set up varibles
;-------------------------------------------------------------------------

	mov	eax,[wBytes]
	mov	esi,[(sCompInfo ebx).lpSource] 		; point to source buffer
	mov	edi,[(sCompInfo ebx).lpDest]   		; point to destination buffer
	inc esi						; skip first byte
	inc edi						; ship first byte

;	Check for 16 bit compression

	cmp	[(sCompInfo ebx).wBitSize],16
	je	short ??do16bit
	mov	[dwCODECByteIndex],eax
	jmp	short ??mainloopr

??do16bit:
	shr	eax,1					;16 bit so half as many bytes
	inc	esi					;16 bit so 1 more byte to skip
	mov	[dwCODECByteIndex],eax


;-----------------------------------------------------------------------
;Start of Stereo Right Side
;-----------------------------------------------------------------------

??mainloopr:
; determine bit size for input				;do{

	cmp	[(sCompInfo ebx).wBitSize],16  		;are we doing 16 bit
	jne	short ??input8Bitr	       		;no. goto 8 bit input		**

	movsx	eax,[word ptr esi]	       		;load next word from source
	add	esi,4					;inc source by 2 words  		**
	jmp	short ??computeDiffr			;skip 8 bit load			**

??input8Bitr:
	mov	ah,[esi]				;Get 8 bit sample
	add	esi,2   				;inc source by 2 bytes		**
	xor	al,al					;zero out low byte
	xor	ah,80h					;flip sign bit
	movsx eax,ax					;sign extend into eax

??computeDiffr:
	; compute difference

	movsx ecx,[word ptr (sCompInfo ebx).dwPredicted2]
							;load predicted (starts at 0)
	sub	eax,ecx					;difference=sample-preditcted

	; check if dwDifference > 0.  ECX is the
	; sign bit, it is initialized to positive.

	xor	ecx,ecx					;clear ecx
	cmp	eax,0					;if(difference>=0)
	jge	short ??positiver 			;goto positive

	neg	eax					;else difference= -difference
	or	ecx,8					;set nibble sign bit in ecx

??positiver:
	mov	[(sCompInfo ebx).wCode2],cx		;Store code from cx into struct

	; set up to quantize difference. initialize
	; wCODECTempStep = step value.

	movsx	ecx,[(sCompInfo ebx).wStep2]   		;ecx=step value(starts at 7)
	mov	[dwCODECTempStep],ecx			;tempstep=step
	mov	edx,4					;edx=4   mask value (i think)
	mov	ecx,3					;ecx is loop number so loop 3 times

??quantizeLoopr:
	; check to see if difference > tempstep value.

	cmp	eax,[dwCODECTempStep]	  		;if(difference < tempstep)
	jl	short ??nextQLoopr			;goto nextQloop

	; OR in mask value into code and adjust difference.

	or	[(sCompInfo ebx).wCode2],dx		;else or mask into code
	sub	eax,[dwCODECTempStep]			;difference-=tempstep

??nextQLoopr:

	; shift down tempstep and mask

	shr	[dwCODECTempStep],1			; TempStep>>=1
	shr	edx,1					; mask>>=1
	loop	??quantizeLoopr				; back to quatize loop
;------------------------------------------------------------------------------------------
; now i'v got the new diff and code is masked right

	; store off new difference value

	mov	[(sCompInfo ebx).dwDifference2],eax

	; determine if sample index is even or odd.
	; this will determine if we need to get a new token or not.

	test	[(sCompInfo ebx).dwSampleIndex2],1	; is it even? (starts at 0)
	jne	short ??storeTokenr			; if so goto store token		**

	; else its odd so get token

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode2]		;ax=wCode
	and	eax,0Fh					;and off high nibble
	mov	[(sCompInfo ebx).wCodeBuf2],ax		;wCodeBuf=ax
	jmp	short ??calcDifferencer			;goto calcDifference		**

??storeTokenr:
	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCode2]		;ax=code
	shl	eax,4					;shift low nibble to hign nibble
	or	ax,[(sCompInfo ebx).wCodeBuf2]		;or in the stored nibble
	mov	[edi],al				;*dest=al
	add	edi,2					;dest+=2					**

??calcDifferencer:
	mov	[(sCompInfo ebx).dwDifference2],0	;dwDifference=0
	xor	ecx,ecx					;ecx=0
	mov	cx,[(sCompInfo ebx).wStep2]		;cx=Step
	xor	eax,eax					;eax=0
	mov	ax,[(sCompInfo ebx).wCode2]		;ax=wCode
	test	eax,4					;Check 0100
	je	short ??no4r
	add	[(sCompInfo ebx).dwDifference2],ecx  	;difference+=step

??no4r:
	test	eax,2					;Check 0010
	je	short ??no2r
	mov	edx,ecx					;edx=wStep
	shr	edx,1					;edx>>1
	add	[(sCompInfo ebx).dwDifference2],edx ;Difference=wstep>>1

??no2r:
	test	eax,1					;Check 0001
	je	short ??no1r
	mov	edx,ecx					;edx=wStep
	shr	edx,2					;edx>>2
	add	[(sCompInfo ebx).dwDifference2],edx 	;Difference=wstep>>2

??no1r:
	mov	edx,ecx
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference2],edx	;Difference=wstep>>3
	test	eax,8					;Check 1000
	je	short ??no8r
	neg	[(sCompInfo ebx).dwDifference2]

??no8r:
	; add difference to predicted value.
	mov	eax,[(sCompInfo ebx).dwPredicted2]
	add	eax,[(sCompInfo ebx).dwDifference2]	;eax=Preditcted+Difference
	cmp	eax,7FFFh
	jl	short ??noOverflowr
	mov	eax,7FFFh				;if overflow store 7fff in diff

??noOverflowr:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflowr
	mov	eax,0FFFF8000h				;if overflow  0FFFF8000 in diff

??noUnderflowr:
	mov	[(sCompInfo ebx).dwPredicted2],eax 	;store into predicted
	xor	ecx,ecx					;adjust index
	mov	cx,[(sCompInfo ebx).wCode2]		;cx=Code
	xor	eax,eax
	shl	ecx,1					;cx<<1
	mov	ax,[wCODECIndexTab + ecx]		;ax=Indextab[ecx]
	add	[(sCompInfo ebx).wIndex2],ax   		;wIndex+=ax
	cmp	[(sCompInfo ebx).wIndex2],8000h		;check if wIndex < 0
	jb	short ??checkOverflowr
	mov	[(sCompInfo ebx).wIndex2],0		;reset index to zero
	jmp	short ??adjustStepr

??checkOverflowr:

	cmp	[(sCompInfo ebx).wIndex2],88		;check if wIndex > 88
	jbe	short ??adjustStepr
	mov	[(sCompInfo ebx).wIndex2],88		;reset index to 88


??adjustStepr:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex2]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex2],1
	mov	[(sCompInfo ebx).wStep2],ax

	; decrement bytes processed and loop back.

	sub	[dwCODECByteIndex],2    		; sub 2 for stereo
	jne	??mainloopr		    		; }while !0


;-------------------------------------------------------------------------
;Final clean up
;-------------------------------------------------------------------------

??exitout:
	; save off ESI and EDI back into compress info structure.

;	mov	[(sCompInfo ebx).lpSource],esi
;	mov	[(sCompInfo ebx).lpDest],edi

	; set up return value for number of bytes processed.

	mov	eax,[dwCODECBytesProcessed]
	shr	eax,1
	cmp	[(sCompInfo ebx).wBitSize],16
	jne	??leave
	shr	eax,1					;if not 16 bit then div/2

??leave:
	pop	edx
	pop	ecx
	pop	ebx
	pop	edi
	pop	esi
	ret

	ENDP	VQA_sosCODECCompressData


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
;*     NumBytes - Number of bytes to compress.
;*
;* RESULT
;*     Size - Size of decompressed data.
;*
;****************************************************************************

	GLOBAL	C VQA_sosCODECDecompressData:NEAR
	PROC	VQA_sosCODECDecompressData C NEAR

	ARG	sSOSInfo:NEAR PTR
	ARG	wBytes:DWORD

	push	esi
	push	edi
	push	ebx
	push	ecx
	push	edx

;*---------------------------------------------------------------------------
;*	Initialize
;*---------------------------------------------------------------------------

	mov	ebx,[sSOSInfo]
	mov	eax,[wBytes]
	mov	[dwCODECBytesProcessed],eax
	mov	[(sCompInfo ebx).dwSampleIndex],0 	;start at head of index
	mov	[(sCompInfo ebx).dwSampleIndex2],0 	;start at head of index

;*	Check for 16 bit decompression

	cmp	[(sCompInfo ebx).wBitSize],16
	jne	short ??skipByteDivide
	shr	eax,1

??skipByteDivide:
	mov	[dwCODECByteIndex],eax
	mov	esi,[(sCompInfo ebx).lpSource]
	mov	edi,[(sCompInfo ebx).lpDest]
	cmp	[(sCompInfo ebx).wChannels],2		;stereo check
	je	??mainloopl				;do left side first

;	Determine if sample index is even or odd. This will determine
;	if we need to get a new token or not.

;*---------------------------------------------------------------------------
;*	Main Mono Loop
;*---------------------------------------------------------------------------

??mainloop:
	test	[(sCompInfo ebx).dwSampleIndex],1	;odd ??
	je	short ??fetchToken				;if so get new token
	xor	eax,eax					;else shift int codebuf
	mov	ax,[(sCompInfo ebx).wCodeBuf]		;ored with Code
	shr	eax,4
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode],ax
	jmp	short ??calcDifference

??fetchToken:
	xor	eax,eax					;get a new token
	mov	al,[esi]					;put in codebuf
	mov	[(sCompInfo ebx).wCodeBuf],ax
	inc	esi
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode],ax		;and then code

??calcDifference:
	mov	[(sCompInfo ebx).dwDifference],0	;reset diff
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wStep]		;cx is step value
	test	eax,4					;Check for wCode & 4
	je	short ??no4
	add	[(sCompInfo ebx).dwDifference],ecx	;Add wStep

??no4:
	test	eax,2					;Check for wCode & 2
	je	short ??no2
	mov	edx,ecx					;Add wStep >> 1
	shr	edx,1
	add	[(sCompInfo ebx).dwDifference],edx

??no2:
	test	eax,1					;Check for wCode & 1
	je	short ??no1
	mov	edx,ecx					;Add wStep >> 2
	shr	edx,2
	add	[(sCompInfo ebx).dwDifference],edx

??no1:
	mov	edx,ecx					;Add in wStep >> 3
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference],edx
	test	eax,8					;Check for wCode & 8
	je	short ??no8
	neg	[(sCompInfo ebx).dwDifference]	;Negate diff

??no8:
	; add difference to predicted value.

	mov	eax,[(sCompInfo ebx).dwPredicted]
	add	eax,[(sCompInfo ebx).dwDifference]

	; make sure there is no under or  overflow.

	cmp	eax,7FFFh
	jl	short ??noOverflow
	mov	eax,7FFFh

??noOverflow:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflow
	mov	eax,0FFFF8000h

??noUnderflow:
	mov	[(sCompInfo ebx).dwPredicted],eax
	cmp	[(sCompInfo ebx).wBitSize],16
	jne	short ??output8Bit
	mov	[edi],ax				;Output 16bit sample
	add	edi,2
	jmp	short ??adjustIndex

??output8Bit:
	; output 8 bit sample

	xor	ah,80h
	mov	[edi],ah
	inc	edi

??adjustIndex:
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wCode]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECIndexTab + ecx]
	add	[(sCompInfo ebx).wIndex],ax 		;check if wIndex < 0
	cmp	[(sCompInfo ebx).wIndex],8000h
	jb	short ??checkOverflow
	mov	[(sCompInfo ebx).wIndex],0		;reset index to zero
	jmp	short ??adjustStep

??checkOverflow:
	cmp	[(sCompInfo ebx).wIndex],88		;check if wIndex > 88
	jbe	short ??adjustStep
	mov	[(sCompInfo ebx).wIndex],88		;reset index to 88

??adjustStep:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex],1
	mov	[(sCompInfo ebx).wStep],ax

	; decrement bytes processed and loop back.

	dec	[dwCODECByteIndex]
	jne	??mainloop
	jmp	??exitout

;--------------------------------------------------------------------------
;Left Channel Start
;--------------------------------------------------------------------------


??mainloopl:
	test	[(sCompInfo ebx).dwSampleIndex],1
	je	short ??fetchTokenl

	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCodeBuf]
	shr	eax,4
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode],ax
	jmp	short ??calcDifferencel

??fetchTokenl:
	xor	eax,eax
	mov	al,[esi]
	mov	[(sCompInfo ebx).wCodeBuf],ax
	add	esi,2					;2 for stereo
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode],ax

??calcDifferencel:
							; reset difference

	mov	[(sCompInfo ebx).dwDifference],0
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wStep]
	test	eax,4					;Check for wCode & 4
	je	short ??no4l
	add	[(sCompInfo ebx).dwDifference],ecx	;Add wStep

??no4l:
	test	eax,2					;Check for wCode & 2
	je	short ??no2l
	mov	edx,ecx					;Add wStep >> 1
	shr	edx,1
	add	[(sCompInfo ebx).dwDifference],edx

??no2l:
	test	eax,1					;Check for wCode & 1
	je	short ??no1l
	mov	edx,ecx					;Add wStep >> 2
	shr	edx,2
	add	[(sCompInfo ebx).dwDifference],edx

??no1l:
	mov	edx,ecx					;Add in wStep >> 3
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference],edx
	test	eax,8					;Check for wCode & 8
	je	short ??no8l
	neg	[(sCompInfo ebx).dwDifference]		;Negate diff

??no8l:
		; add difference to predicted value.

	mov	eax,[(sCompInfo ebx).dwPredicted]
	add	eax,[(sCompInfo ebx).dwDifference]

		; make sure there is no under or  overflow.

	cmp	eax,7FFFh
	jl	short ??noOverflowl
	mov	eax,7FFFh

??noOverflowl:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflowl
	mov	eax,0FFFF8000h

??noUnderflowl:
	mov	[(sCompInfo ebx).dwPredicted],eax
	cmp	[(sCompInfo ebx).wBitSize],16
	jne	short ??output8Bitl
	mov	[edi],ax				;Output 16bit sample
	add	edi,4					;4 for stereo
	jmp	short ??adjustIndexl

??output8Bitl:
	; output 8 bit sample

	xor	ah,80h
	mov	[edi],ah
	add	edi,2					;2 for stereo

??adjustIndexl:
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wCode]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECIndexTab + ecx]
	add	[(sCompInfo ebx).wIndex],ax
							; check if wIndex < 0
	cmp	[(sCompInfo ebx).wIndex],8000h
	jb	short ??checkOverflowl
	mov	[(sCompInfo ebx).wIndex],0
	jmp	short ??adjustStepl			;reset index to zero


??checkOverflowl:

	cmp	[(sCompInfo ebx).wIndex],88		; check if wIndex > 88
	jbe	short ??adjustStepl
	mov	[(sCompInfo ebx).wIndex],88		; reset index to 88

??adjustStepl:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex],1
	mov	[(sCompInfo ebx).wStep],ax

	; decrement bytes processed and loop back.

	sub	[dwCODECByteIndex],2
	jne	??mainloopl
;----------------------------------------------------------------------------
; Right Side Setup
;----------------------------------------------------------------------------
	mov	eax,[wBytes]
	mov	[dwCODECBytesProcessed],eax
	mov	esi,[(sCompInfo ebx).lpSource]
	mov	edi,[(sCompInfo ebx).lpDest]
	inc	esi					; skip left channel
	inc	edi				     	; skip left channel
	cmp	[(sCompInfo ebx).wBitSize],16		;16 bit ??
	je	short ??doByteDivide
	mov	[dwCODECByteIndex],eax
	jmp  short ??mainloopr

??doByteDivide:
	shr	eax,1 					;Divide size by two
	inc	edi   					; 16 bit so skip 1 more
	mov	[dwCODECByteIndex],eax


;--------------------------------------------------------------------------
;Right Channel Start
;--------------------------------------------------------------------------


??mainloopr:
	test	[(sCompInfo ebx).dwSampleIndex2],1
	je	short ??fetchTokenr
	xor	eax,eax
	mov	ax,[(sCompInfo ebx).wCodeBuf2]
	shr	eax,4
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode2],ax
	jmp	short ??calcDifferencer

??fetchTokenr:
	xor	eax,eax
	mov	al,[esi]
	mov	[(sCompInfo ebx).wCodeBuf2],ax
	add	esi,2				     	;2 for stereo
	and	eax,000Fh
	mov	[(sCompInfo ebx).wCode2],ax

??calcDifferencer:
							; reset difference

	mov	[(sCompInfo ebx).dwDifference2],0
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wStep2]
	test	eax,4					;Check for wCode & 4
	je	short ??no4r
	add	[(sCompInfo ebx).dwDifference2],ecx	;Add wStep

??no4r:
	test	eax,2					;Check for wCode & 2
	je	short ??no2r
	mov	edx,ecx					;Add wStep >> 1
	shr	edx,1
	add	[(sCompInfo ebx).dwDifference2],edx

??no2r:
	test	eax,1					;Check for wCode & 1
	je	short ??no1r
	mov	edx,ecx					;Add wStep >> 2
	shr	edx,2
	add	[(sCompInfo ebx).dwDifference2],edx

??no1r:
	mov	edx,ecx					;Add in wStep >> 3
	shr	edx,3
	add	[(sCompInfo ebx).dwDifference2],edx
	test	eax,8					;Check for wCode & 8
	je	short ??no8r
	neg	[(sCompInfo ebx).dwDifference2]		;Negate diff

??no8r:
	; add difference to predicted value.
	mov	eax,[(sCompInfo ebx).dwPredicted2]
	add	eax,[(sCompInfo ebx).dwDifference2]
	cmp	eax,7FFFh
	jl	short ??noOverflowr
	mov	eax,7FFFh

??noOverflowr:
	cmp	eax,0FFFF8000h
	jg	short ??noUnderflowr
	mov	eax,0FFFF8000h

??noUnderflowr:
	mov	[(sCompInfo ebx).dwPredicted2],eax
	cmp	[(sCompInfo ebx).wBitSize],16
	jne	short ??output8Bitr
	mov	[edi],ax				;Output 16bit sample
	add	edi,4					;4 for stereo		***
	jmp	short ??adjustIndexr

??output8Bitr:
							; output 8 bit sample
	xor	ah,80h
	mov	[edi],ah
	add	edi,2					;2 for stereo

??adjustIndexr:
	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wCode2]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECIndexTab + ecx]
	add	[(sCompInfo ebx).wIndex2],ax
							; check if wIndex < 0
	cmp	[(sCompInfo ebx).wIndex2],8000h
	jb	short ??checkOverflowr
							; reset index to zero
	mov	[(sCompInfo ebx).wIndex2],0
	jmp	short ??adjustStepr

??checkOverflowr:
							; check if wIndex > 88
	cmp	[(sCompInfo ebx).wIndex2],88
	jbe	short ??adjustStepr
	mov	[(sCompInfo ebx).wIndex2],88		; reset index to 88

??adjustStepr:
	; fetch wIndex so we can fetch new step value

	xor	ecx,ecx
	mov	cx,[(sCompInfo ebx).wIndex2]
	xor	eax,eax
	shl	ecx,1
	mov	ax,[wCODECStepTab + ecx]

	; advance index and store step value

	add	[(sCompInfo ebx).dwSampleIndex2],1
	mov	[(sCompInfo ebx).wStep2],ax

	; decrement bytes processed and loop back.

	sub	[dwCODECByteIndex],2
	jne	??mainloopr


??exitout:
;		don't think we need this but just in case i'll leave it here!!

;	mov	[(sCompInfo ebx).lpSource],esi
;	mov	[(sCompInfo ebx).lpDest],edi
	; set up return value for number of bytes processed.
	mov	eax,[dwCODECBytesProcessed]
	pop	edx
	pop	ecx
	pop	ebx
	pop	edi
	pop	esi
	ret

	ENDP	VQA_sosCODECDecompressData
	END


