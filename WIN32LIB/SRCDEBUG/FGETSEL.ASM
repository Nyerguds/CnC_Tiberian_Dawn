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
;*                 Project Name : Get the Defines selectors		   *
;*                                                                         *
;*                    File Name : FGETSEL.ASM                              *
;*                                                                         *
;*                   Programmer : Jeff Wilson                              *
;*                                                                         *
;*                   Start Date : March 28, 1994                           *
;*                                                                         *
;*                  Last Update : March 28, 1994   []                      *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   GetDefaultSelectors -- Return the current default selectors. 	   *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT


GLOBAL      GetDefaultSelectors :NEAR

GLOBAL 	    DataSelector	:WORD
GLOBAL 	    ScreenSelector	:WORD
GLOBAL 	    GraphicsSelector	:WORD
GLOBAL 	    PspSelector		:WORD
GLOBAL 	    EnvSelector		:WORD
GLOBAL 	    DosMemSelector	:WORD
GLOBAL 	    Fp1167Selector	:WORD
GLOBAL 	    FpWeitekSelector	:WORD
GLOBAL 	    FpCyrixSelector	:WORD
GLOBAL 	    CodeSelector	:WORD


DATASEG

; It is very important that this section remain untouch
; is not really needed by Rational System but is here to
; keep compatibility with the TNT dos extender.
DataSelector		dw	0
ScreenSelector		dw	0
GraphicsSelector	dw	0

PspSelector		dw	0
EnvSelector		dw	0
DosMemSelector		dw	0

Fp1167Selector		dw	0
FpWeitekSelector	dw	0
FpCyrixSelector		dw	0

CodeSelector		dw	0

		    
;============================================================================
CODESEG

;***************************************************************************
;*  GetDefaultSelectors -- Setup the defaults selector values to have the  *
;*    Correct Descriptor table and IOPL.				   *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT: NONE                                                             *
;*                                                                         *
;* OUTPUT: 								   *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   03/28/1994  jaw: Created.                                             *
;*=========================================================================*

PROC GetDefaultSelectors 	C near 
	USES eax,esi,ecx

	lea	edi,[DataSelector]
	lea	ecx,[CodeSelector]
 	sub	ecx,edi
	shr	ecx,1
	mov	ax,ds
	rep	stosw
	mov	ax,cs
	mov	[word ptr CodeSelector] , ax
     
	ret	   
;====================
ENDP GetDefaultSelectors	
     

END




