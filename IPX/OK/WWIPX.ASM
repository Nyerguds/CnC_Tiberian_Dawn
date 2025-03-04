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

	page	,132

;Thunk Compiler Version 1.8  May 11 1995 13:16:19
;File Compiled Tue Jan 16 13:53:22 1996

;Command Line: D:\MSTOOLS\BIN\THUNK.EXE wwipx.thk 

	TITLE	$wwipx.asm

	.386
	OPTION READONLY
	OPTION OLDSTRUCTS

IFNDEF IS_16
IFNDEF IS_32
%out command line error: specify one of -DIS_16, -DIS_32
.err
ENDIF  ;IS_32
ENDIF  ;IS_16


IFDEF IS_32
IFDEF IS_16
%out command line error: you can't specify both -DIS_16 and -DIS_32
.err
ENDIF ;IS_16
;************************* START OF 32-BIT CODE *************************


	.model FLAT,STDCALL


;-- Import common flat thunk routines (in k32)

externDef MapHInstLS	:near32
externDef MapHInstLS_PN	:near32
externDef MapHInstSL	:near32
externDef MapHInstSL_PN	:near32
externDef FT_Prolog	:near32
externDef FT_Thunk	:near32
externDef QT_Thunk	:near32
externDef FT_Exit0	:near32
externDef FT_Exit4	:near32
externDef FT_Exit8	:near32
externDef FT_Exit12	:near32
externDef FT_Exit16	:near32
externDef FT_Exit20	:near32
externDef FT_Exit24	:near32
externDef FT_Exit28	:near32
externDef FT_Exit32	:near32
externDef FT_Exit36	:near32
externDef FT_Exit40	:near32
externDef FT_Exit44	:near32
externDef FT_Exit48	:near32
externDef FT_Exit52	:near32
externDef FT_Exit56	:near32
externDef SMapLS	:near32
externDef SUnMapLS	:near32
externDef SMapLS_IP_EBP_8	:near32
externDef SUnMapLS_IP_EBP_8	:near32
externDef SMapLS_IP_EBP_12	:near32
externDef SUnMapLS_IP_EBP_12	:near32
externDef SMapLS_IP_EBP_16	:near32
externDef SUnMapLS_IP_EBP_16	:near32
externDef SMapLS_IP_EBP_20	:near32
externDef SUnMapLS_IP_EBP_20	:near32
externDef SMapLS_IP_EBP_24	:near32
externDef SUnMapLS_IP_EBP_24	:near32
externDef SMapLS_IP_EBP_28	:near32
externDef SUnMapLS_IP_EBP_28	:near32
externDef SMapLS_IP_EBP_32	:near32
externDef SUnMapLS_IP_EBP_32	:near32
externDef SMapLS_IP_EBP_36	:near32
externDef SUnMapLS_IP_EBP_36	:near32
externDef SMapLS_IP_EBP_40	:near32
externDef SUnMapLS_IP_EBP_40	:near32

MapSL	PROTO NEAR STDCALL p32:DWORD



	.code 

;************************* COMMON PER-MODULE ROUTINES *************************

	.data

public wwipx_ThunkData32	;This symbol must be exported.
wwipx_ThunkData32 label dword
	dd	3130534ch	;Protocol 'LS01'
	dd	043bh	;Checksum
	dd	0	;Jump table address.
	dd	3130424ch	;'LB01'
	dd	0	;Flags
	dd	0	;Reserved (MUST BE 0)
	dd	0	;Reserved (MUST BE 0)
	dd	offset QT_Thunk_wwipx - offset wwipx_ThunkData32
	dd	offset FT_Prolog_wwipx - offset wwipx_ThunkData32



	.code 


externDef ThunkConnect32@24:near32

public wwipx_ThunkConnect32@16
wwipx_ThunkConnect32@16:
	pop	edx
	push	offset wwipx_ThkData16
	push	offset wwipx_ThunkData32
	push	edx
	jmp	ThunkConnect32@24
wwipx_ThkData16 label byte
	db	"wwipx_ThunkData16",0


		


pfnQT_Thunk_wwipx	dd offset QT_Thunk_wwipx
pfnFT_Prolog_wwipx	dd offset FT_Prolog_wwipx
	.data
QT_Thunk_wwipx label byte
	db	32 dup(0cch)	;Patch space.

FT_Prolog_wwipx label byte
	db	32 dup(0cch)	;Patch space.


	.code 





;************************ START OF THUNK BODIES************************




;
public IPX_Initialise@4
IPX_Initialise@4:
	mov	cl,0
; IPX_Initialise(16) = IPX_Initialise(32) {}
;
; dword ptr [ebp+8]:  param1
;
public IIIPX_Initialise@4
IIIPX_Initialise@4:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	push	word ptr [ebp+8]	;param1: dword->word
	call	dword ptr [pfnQT_Thunk_wwipx]
	cwde
	leave
	retn	4




ELSE
;************************* START OF 16-BIT CODE *************************




	OPTION SEGMENT:USE16
	.model LARGE,PASCAL


	.code	



externDef IPX_Initialise:far16


FT_wwipxTargetTable label word
	dw	offset IPX_Initialise
	dw	   seg IPX_Initialise




	.data

public wwipx_ThunkData16	;This symbol must be exported.
wwipx_ThunkData16	dd	3130534ch	;Protocol 'LS01'
	dd	043bh	;Checksum
	dw	offset FT_wwipxTargetTable
	dw	seg    FT_wwipxTargetTable
	dd	0	;First-time flag.



	.code 


externDef ThunkConnect16:far16

public wwipx_ThunkConnect16
wwipx_ThunkConnect16:
	pop	ax
	pop	dx
	push	seg    wwipx_ThunkData16
	push	offset wwipx_ThunkData16
	push	seg    wwipx_ThkData32
	push	offset wwipx_ThkData32
	push	cs
	push	dx
	push	ax
	jmp	ThunkConnect16
wwipx_ThkData32 label byte
	db	"wwipx_ThunkData32",0





ENDIF
END
