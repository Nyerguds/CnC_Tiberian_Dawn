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
;* PROJECT
;*     VQAPlay 32 library.
;*
;* FILE
;*     vqaplay.i
;*
;* DESCRIPTION
;*      VQA player definitions.
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 30, 1995
;*
;****************************************************************************

;*---------------------------------------------------------------------------
;* CONDITIONAL COMPILATION FLAGS
;*---------------------------------------------------------------------------

	IF	PHARLAP_TNT

VQASTANDALONE	EQU	0	;Stand alone player
VQAMONO_ON	EQU	1	;Mono display output enable/disable
VQAAUDIO_ON	EQU	0	;Audio playback enable/disable
VQAVIDEO_ON	EQU	0	;Video manager enable/disable
VQAMCGA_ON	EQU	1	;MCGA enable/disable
VQAXMODE_ON	EQU	0	;Xmode enable/disable
VQAVESA_ON	EQU	0	;VESA enable/disable
VQABLOCK_2X2	EQU	0	;2x2 block decode enable/disable
VQABLOCK_2X3	EQU	0	;2x3 block decode enable/disable
VQABLOCK_4X2	EQU	1	;4x2 block decode enable/disable
VQABLOCK_4X4	EQU	0	;4x4 block decode enable/disable
VQABLOCK_WOOFER	EQU	0

	ELSE

VQASTANDALONE	EQU	0	;Stand alone player
VQAMONO_ON	EQU	0	;Mono display output enable/disable
VQAAUDIO_ON	EQU	1	;Audio playback enable/disable
VQAVIDEO_ON	EQU	0	;Video manager enable/disable
VQAMCGA_ON	EQU	1	;MCGA enable/disable
VQAXMODE_ON	EQU	0	;Xmode enable/disable
VQAVESA_ON	EQU	0	;VESA enable/disable
VQABLOCK_2X2	EQU	0	;2x2 block decode enable/disable
VQABLOCK_2X3	EQU	0	;2x3 block decode enable/disable
VQABLOCK_4X2	EQU	1	;4x2 block decode enable/disable
VQABLOCK_4X4	EQU	0	;4x4 block decode enable/disable
VQABLOCK_WOOFER	EQU	0

	ENDIF
