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
;*                 Project Name : Memory System                            *
;*                                                                         *
;*                    File Name : WWMEM.INC                                *
;*                                                                         *
;*                   Programmer : Ian M. Leslie                            *
;*                                                                         *
;*                   Start Date : August 11, 1994                          *
;*                                                                         *
;*                  Last Update : August 17, 1994   [IML]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


MEM_NORMAL EQU 0000h		; Default memory (normal).
MEM_NEW	   EQU 0001h		; Called by the operator new and was overloaded.
MEM_CLEAR  EQU 0002h 		;

GLOBAL		@Alloc$qul14MemoryFlagType:PROC
GLOBAL		@Free$qpv:PROC
