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
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : VBITBLIT.ASM                             *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : June 8, 1994                             *
;*                                                                         *
;*                  Last Update : January 16, 1995   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Linear_Blit_To_Vesa -- copies graphic buffer to vesa screen           *
;*   Vesa_Blit_To_Linear -- Copies vesa screen to graphic buffer           *
;*   Vesa_Blit_To_Vesa -- Copies a section of vesa screen to vesa screen   *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE "mcgaprim.inc"
INCLUDE ".\gbuffer.inc"


GLOBAL	Linear_Blit_To_Vesa		:NEAR
GLOBAL	Vesa_Blit_To_Linear		:NEAR
GLOBAL	Vesa_Blit_To_Vesa		:NEAR

CODESEG

;***************************************************************************
;* LINEAR_BLIT_TO_VESA -- copies graphic buffer to vesa screen             *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/16/1995 PWG : Created.                                             *
;*=========================================================================*
      	PROC	Linear_Blit_To_Vesa C near 
	ret
	ENDP	Linear_Blit_To_Vesa

;***************************************************************************
;* VESA_BLIT_TO_LINEAR -- Copies vesa screen to graphic buffer             *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/16/1995 PWG : Created.                                             *
;*=========================================================================*
      	PROC	Vesa_Blit_To_Linear C near 
	ret
	ENDP	Vesa_Blit_To_Linear

;***************************************************************************
;* VESA_BLIT_TO_VESA -- Copies a section of vesa screen to vesa screen     *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* PROTO:                                                                  *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   01/16/1995 PWG : Created.                                             *
;*=========================================================================*
      	PROC	Vesa_Blit_To_Vesa C near 
	ret
	ENDP	Vesa_Blit_To_Vesa
END	


