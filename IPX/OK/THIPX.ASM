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
;File Compiled Fri Jan 26 16:12:04 1996

;Command Line: C:\BIN\THUNK.EXE Thipx.thk 

	TITLE	$Thipx.asm

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

public Thipx_ThunkData32	;This symbol must be exported.
Thipx_ThunkData32 label dword
	dd	3130534ch	;Protocol 'LS01'
	dd	0228d3h	;Checksum
	dd	0	;Jump table address.
	dd	3130424ch	;'LB01'
	dd	0	;Flags
	dd	0	;Reserved (MUST BE 0)
	dd	0	;Reserved (MUST BE 0)
	dd	offset QT_Thunk_Thipx - offset Thipx_ThunkData32
	dd	offset FT_Prolog_Thipx - offset Thipx_ThunkData32



	.code 


externDef ThunkConnect32@24:near32

public Thipx_ThunkConnect32@16
Thipx_ThunkConnect32@16:
	pop	edx
	push	offset Thipx_ThkData16
	push	offset Thipx_ThunkData32
	push	edx
	jmp	ThunkConnect32@24
Thipx_ThkData16 label byte
	db	"Thipx_ThunkData16",0


		


pfnQT_Thunk_Thipx	dd offset QT_Thunk_Thipx
pfnFT_Prolog_Thipx	dd offset FT_Prolog_Thipx
	.data
QT_Thunk_Thipx label byte
	db	32 dup(0cch)	;Patch space.

FT_Prolog_Thipx label byte
	db	32 dup(0cch)	;Patch space.


	.code 





;************************ START OF THUNK BODIES************************




;
public _IPX_Close_Socket95@4
_IPX_Close_Socket95@4:
	mov	cl,9
	jmp	II_IPX_Close_Socket95@4
public _IPX_Initialise@4
_IPX_Initialise@4:
	mov	cl,12
	jmp	II_IPX_Close_Socket95@4
public _IPX_Open_Socket95@4
_IPX_Open_Socket95@4:
	mov	cl,10
; _IPX_Close_Socket95(16) = _IPX_Close_Socket95(32) {}
;
; dword ptr [ebp+8]:  param1
;
public II_IPX_Close_Socket95@4
II_IPX_Close_Socket95@4:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	push	word ptr [ebp+8]	;param1: dword->word
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	leave
	retn	4





;
public _IPX_Get_Internet_Address95@12
_IPX_Get_Internet_Address95@12:
	mov	cl,7
; _IPX_Get_Internet_Address95(16) = _IPX_Get_Internet_Address95(32) {}
;
; dword ptr [ebp+8]:  param1
; dword ptr [ebp+12]:  netnum
; dword ptr [ebp+16]:  node
;
public II_IPX_Get_Internet_Address95@12
II_IPX_Get_Internet_Address95@12:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	push	word ptr [ebp+8]	;param1: dword->word
	call	SMapLS_IP_EBP_12
	push	eax
	call	SMapLS_IP_EBP_16
	push	eax
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_12
	call	SUnMapLS_IP_EBP_16
	leave
	retn	12





;
public _IPX_Get_User_ID95@8
_IPX_Get_User_ID95@8:
	mov	cl,6
; _IPX_Get_User_ID95(16) = _IPX_Get_User_ID95(32) {}
;
; dword ptr [ebp+8]:  param1
; dword ptr [ebp+12]:  user_id
;
public II_IPX_Get_User_ID95@8
II_IPX_Get_User_ID95@8:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	push	word ptr [ebp+8]	;param1: dword->word
	call	SMapLS_IP_EBP_12
	push	eax
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_12
	leave
	retn	8





;
public _IPX_Send_Packet95@12
_IPX_Send_Packet95@12:
	mov	cl,5
; _IPX_Send_Packet95(16) = _IPX_Send_Packet95(32) {}
;
; dword ptr [ebp+8]:  address
; dword ptr [ebp+12]:  buffer
; dword ptr [ebp+16]:  param3
;
public II_IPX_Send_Packet95@12
II_IPX_Send_Packet95@12:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	call	SMapLS_IP_EBP_8
	push	eax
	call	SMapLS_IP_EBP_12
	push	eax
	push	word ptr [ebp+16]	;param3: dword->word
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_8
	call	SUnMapLS_IP_EBP_12
	leave
	retn	12





;
public _IPX_Broadcast_Packet95@8
_IPX_Broadcast_Packet95@8:
	mov	cl,4
; _IPX_Broadcast_Packet95(16) = _IPX_Broadcast_Packet95(32) {}
;
; dword ptr [ebp+8]:  buffer
; dword ptr [ebp+12]:  param2
;
public II_IPX_Broadcast_Packet95@8
II_IPX_Broadcast_Packet95@8:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	call	SMapLS_IP_EBP_8
	push	eax
	push	word ptr [ebp+12]	;param2: dword->word
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_8
	leave
	retn	8





;
public _IPX_Get_Local_Target95@16
_IPX_Get_Local_Target95@16:
	mov	cl,3
; _IPX_Get_Local_Target95(16) = _IPX_Get_Local_Target95(32) {}
;
; dword ptr [ebp+8]:  netnum
; dword ptr [ebp+12]:  node
; dword ptr [ebp+16]:  param3
; dword ptr [ebp+20]:  address
;
public II_IPX_Get_Local_Target95@16
II_IPX_Get_Local_Target95@16:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	call	SMapLS_IP_EBP_8
	push	eax
	call	SMapLS_IP_EBP_12
	push	eax
	push	word ptr [ebp+16]	;param3: dword->word
	call	SMapLS_IP_EBP_20
	push	eax
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_8
	call	SUnMapLS_IP_EBP_12
	call	SUnMapLS_IP_EBP_20
	leave
	retn	16





;
public _IPX_Shut_Down95@0
_IPX_Shut_Down95@0:
	mov	cl,1
	jmp	II_IPX_Shut_Down95@0
public _IPX_Uninitialise@0
_IPX_Uninitialise@0:
	mov	cl,11
	jmp	II_IPX_Shut_Down95@0
public _IPX_Get_Connection_Number95@0
_IPX_Get_Connection_Number95@0:
	mov	cl,8
	jmp	II_IPX_Shut_Down95@0
public _IPX_Start_Listening95@0
_IPX_Start_Listening95@0:
	mov	cl,2
; _IPX_Shut_Down95(16) = _IPX_Shut_Down95(32) {}
;
;
public II_IPX_Shut_Down95@0
II_IPX_Shut_Down95@0:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	leave
	retn





;
public _IPX_Get_Outstanding_Buffer95@4
_IPX_Get_Outstanding_Buffer95@4:
	mov	cl,0
; _IPX_Get_Outstanding_Buffer95(16) = _IPX_Get_Outstanding_Buffer95(32) {}
;
; dword ptr [ebp+8]:  buffer
;
public II_IPX_Get_Outstanding_Buffer95@4
II_IPX_Get_Outstanding_Buffer95@4:
	push	ebp
	mov	ebp,esp
	push	ecx
	sub	esp,60
	call	SMapLS_IP_EBP_8
	push	eax
	call	dword ptr [pfnQT_Thunk_Thipx]
	cwde
	call	SUnMapLS_IP_EBP_8
	leave
	retn	4




ELSE
;************************* START OF 16-BIT CODE *************************




	OPTION SEGMENT:USE16
	.model LARGE,PASCAL


	.code	



externDef _IPX_Get_Outstanding_Buffer95:far16
externDef _IPX_Shut_Down95:far16
externDef _IPX_Start_Listening95:far16
externDef _IPX_Get_Local_Target95:far16
externDef _IPX_Broadcast_Packet95:far16
externDef _IPX_Send_Packet95:far16
externDef _IPX_Get_User_ID95:far16
externDef _IPX_Get_Internet_Address95:far16
externDef _IPX_Get_Connection_Number95:far16
externDef _IPX_Close_Socket95:far16
externDef _IPX_Open_Socket95:far16
externDef _IPX_Uninitialise:far16
externDef _IPX_Initialise:far16


FT_ThipxTargetTable label word
	dw	offset _IPX_Get_Outstanding_Buffer95
	dw	   seg _IPX_Get_Outstanding_Buffer95
	dw	offset _IPX_Shut_Down95
	dw	   seg _IPX_Shut_Down95
	dw	offset _IPX_Start_Listening95
	dw	   seg _IPX_Start_Listening95
	dw	offset _IPX_Get_Local_Target95
	dw	   seg _IPX_Get_Local_Target95
	dw	offset _IPX_Broadcast_Packet95
	dw	   seg _IPX_Broadcast_Packet95
	dw	offset _IPX_Send_Packet95
	dw	   seg _IPX_Send_Packet95
	dw	offset _IPX_Get_User_ID95
	dw	   seg _IPX_Get_User_ID95
	dw	offset _IPX_Get_Internet_Address95
	dw	   seg _IPX_Get_Internet_Address95
	dw	offset _IPX_Get_Connection_Number95
	dw	   seg _IPX_Get_Connection_Number95
	dw	offset _IPX_Close_Socket95
	dw	   seg _IPX_Close_Socket95
	dw	offset _IPX_Open_Socket95
	dw	   seg _IPX_Open_Socket95
	dw	offset _IPX_Uninitialise
	dw	   seg _IPX_Uninitialise
	dw	offset _IPX_Initialise
	dw	   seg _IPX_Initialise




	.data

public Thipx_ThunkData16	;This symbol must be exported.
Thipx_ThunkData16	dd	3130534ch	;Protocol 'LS01'
	dd	0228d3h	;Checksum
	dw	offset FT_ThipxTargetTable
	dw	seg    FT_ThipxTargetTable
	dd	0	;First-time flag.



	.code 


externDef ThunkConnect16:far16

public Thipx_ThunkConnect16
Thipx_ThunkConnect16:
	pop	ax
	pop	dx
	push	seg    Thipx_ThunkData16
	push	offset Thipx_ThunkData16
	push	seg    Thipx_ThkData32
	push	offset Thipx_ThkData32
	push	cs
	push	dx
	push	ax
	jmp	ThunkConnect16
Thipx_ThkData32 label byte
	db	"Thipx_ThunkData32",0





ENDIF
END
