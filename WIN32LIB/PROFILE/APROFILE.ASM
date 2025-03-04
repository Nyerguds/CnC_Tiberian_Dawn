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

;***************************************************************************
;**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Profiler                                 *
;*                                                                         *
;*                    File Name : APROFILE.ASM                             *
;*                                                                         *
;*                   Programmer : Steve Tall				   *
;*                                                                         *
;*                   Start Date : November 17th, 1995			   *
;*                                                                         *
;*                  Last Update : November 20th, 1995   [ST]               *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   __PRO -- must be called at the beginning of each function             *
;*   __EPI -- must be called at the end of each function	           *
;*   Copy_CHL -- initialise the profiler asm data                          *
;*   Profiler_Callback -- windows callback for millisecond timer           *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *



		p386
		model	flat
		ideal
		jumps


MAX_PROFILE_TIME = 60*1		;1 minute(s)
PROFILE_RATE	 = 1000		;1000 samples per sec


;
; Externs
;
;
global		C ProfileFunctionAddress:dword
global		C ProfilePtr:dword
global		C ProfileList:dword
global		C Stop_Profiler:near
global		New_Profiler_Callback_:near
global		Old_Profiler_Callback_:near
global		C Profile_Init:near
global		C Profile_End:near
global		___begtext:near
global		BaseAddress:dword
global		__PRO:near
global		__EPI:near
global		MyStack:dword
global		MyStackPtr:dword
global		ProAddress:dword
global		EpiAddress:dword


		codeseg


;*********************************************************************************************
;* __PRO -- registers the current procedure                                                  *
;*                                                                                           *
;* INPUT:	Nothing                                                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Warnings:                                                                                 *
;*  Assumes that ss:Esp points to return address in function to be registered                *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:39PM ST : Created.                                                           *
;*===========================================================================================*

proc		__PRO near

		jmp	[ProAddress]
; safe version of prologue code
Pro_Start:	push	eax
		mov	eax,[MyStackPtr]
		push	[ProfileFunctionAddress]
		pop	[eax*4+MyStack]
		inc	[MyStackPtr]
		pop	eax
		push	[dword ss:esp]
		pop	[ProfileFunctionAddress]
Pro_End:	ret

; unsafe (but much faster) prologue code
;		pop	[ProfileFunctionAddress]
;		jmp	[ProfileFunctionAddress]

endp		__PRO


;*********************************************************************************************
;* __EPI -- Registers the privious procedure as current again                                *
;*                                                                                           *
;* INPUT:	Nothing                                                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Warnings:                                                                                 *
;*  Assumes that calling procedure will pop ebp immediately on return so we dont have to     *
;*  preserve it.                                                                             *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:42PM ST : Created.                                                           *
;*===========================================================================================*

proc		__EPI near

		jmp	[EpiAddress]
; Safe version of epilogue code. Uncomment the push and pop for ultimate safety
Epi_Start:	dec	[MyStackPtr]
;		push	ebp
		mov	ebp,[MyStackPtr]
		mov	ebp,[ebp*4+MyStack]
		mov	[ProfileFunctionAddress],ebp
;		pop	ebp
Epi_End:	ret

; Unsafe (but much faster) epilogue code. Makes lots of assumptions.
;		push	[dword esp+8]
;		pop	[ProfileFunctionAddress]
;		ret

endp		__EPI



;*********************************************************************************************
;* Profile_Init -- Initialises the .asm data required for profile session                    *
;*                                                                                           *
;* INPUT:	Nothing                                                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Warnings:                                                                                 *
;*   Assumes that '___begtext' is the first label in the code segment and that its           *
;*   address is within 15 bytes of the start of the code segment                             *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:44PM ST : Created.                                                           *
;*===========================================================================================*

proc		Profile_Init C near

		mov	eax,offset ___begtext
		and	eax,0fffffff0h
		mov	[BaseAddress],eax
		;mov	[MyStackPtr],0
		mov	[ProfileList],PROFILE_RATE
		mov	[ProfilePtr],1
		mov	[ProAddress],offset Pro_Start
		mov	[EpiAddress],offset Epi_Start
		ret

endp		Profile_Init





;*********************************************************************************************
;* Profile_End -- disables the __PRO and __EPI procedures                                    *
;*                                                                                           *
;* INPUT:	Nothing                                                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Warnings:                                                                                 *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:44PM ST : Created.                                                           *
;*===========================================================================================*

proc		Profile_End C near

		mov	[ProAddress],offset Pro_End
		mov	[EpiAddress],offset Epi_End
		ret

endp		Profile_End






;*********************************************************************************************
;* New_Profiler_Callback -- Windows callback used to register function hits                  *
;*                                                                                           *
;* INPUT:	Nothing                                                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Note:                                                                                     *
;*   The frequency that this is called depends on MAX_PROFILE_RATE defined here and in       *
;*   profile.h                                                                               *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:47PM ST : Created.                                                           *
;*===========================================================================================*
proc		New_Profiler_Callback_ near

		push	eax
		push	esi
		mov	esi,[ProfilePtr]
		cmp	esi,MAX_PROFILE_TIME*PROFILE_RATE
		jge	@@out
		mov	eax,[ProfileFunctionAddress]
		sub	eax,[BaseAddress]
		mov	[ProfileList+esi*4],eax
		inc	[ProfilePtr]
		pop	esi
		pop	eax
		ret

@@out:		call	Stop_Profiler
		pop	esi
		pop	eax
		ret

endp		New_Profiler_Callback_



;*********************************************************************************************
;* Old_Profiler_Callback -- Windows callback used to register function hits                  *
;*                                                                                           *
;* INPUT:	Windows timer callback stuff - not used                                      *
;*                                                                                           *
;* OUTPUT:      none                                                                         *
;*                                                                                           *
;* Note:                                                                                     *
;*   The frequency that this is called depends on MAX_PROFILE_RATE defined here and in       *
;*   profile.h                                                                               *
;*                                                                                           *
;* HISTORY:                                                                                  *
;*   11/20/95 4:47PM ST : Created.                                                           *
;*===========================================================================================*

proc		Old_Profiler_Callback_ near

		push	eax
		push	esi
		mov	esi,[ProfilePtr]
		cmp	esi,MAX_PROFILE_TIME*PROFILE_RATE
		jge	@@out
		mov	eax,[ProfileFunctionAddress]
		sub	eax,[BaseAddress]
		mov	[ProfileList+esi*4],eax
		inc	[ProfilePtr]
		pop	esi
		pop	eax
		ret	14h

@@out:		call	Stop_Profiler
		pop	esi
		pop	eax
		ret	14h

endp		Old_Profiler_Callback_



		dataseg
		align	4

ProfileFunctionAddress	dd	0		;Ptr to function we are currently in
BaseAddress		dd	0		;Address of the code segment start
MyStackPtr		dd	0		;offset into my stack table
ProAddress		dd	Pro_Start	;jmp ptr for __PRO procedure
EpiAddress		dd	Epi_Start	;jmp ptr for __EPI procedure

label MyStack dword			;my stack table
			dd	16*1024 dup (?)

end
