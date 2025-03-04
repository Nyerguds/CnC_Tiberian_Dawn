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
;**   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
;***************************************************************************
;*                                                                         *
;*                 Project Name : LIBRARY                                  *
;*                                                                         *
;*                    File Name : VMPAGEIN.ASM                             *
;*                                                                         *
;*                   Programmer : Steve Tall				   *
;*                                                                         *
;*                  Last Update : March 8th, 1996	[ST]               *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*  Force_VM_Page_In -- forces a buffer to be paged in under win95         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

		IDEAL
		P386
		MODEL USE32 FLAT


		LOCALS ??


GLOBAL		C Force_VM_Page_In:near

CODESEG


;***************************************************************************
;* Force_VM_Page_In -- forces a buffer to be paged in under win95          *
;*                                                                         *
;*                                                                         *
;* INPUT: ptr to start of buffer                                           *
;*        length of buffer                                                 *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* Prototype:                                                              *
;*  void Force_VM_Page_In (void *buffer, int length);                      *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   3/8/96 4:18PM ST : Created.                                           *
;*=========================================================================*


proc		Force_VM_Page_In C near
		USES	eax,ecx,edx,edi
		ARG	buffer_start:dword
		ARG	buffer_length:dword

		mov	ecx,[buffer_length]
		xor	al,al
		test	ecx,ecx
		mov	edx,4096
		jz	??out

		mov	edi,[buffer_start]


??next_page:	add	[edi],al
		add	edi,edx
		sub	ecx,edx
		jg	??next_page

??out:		ret

endp		Force_VM_Page_In

END
