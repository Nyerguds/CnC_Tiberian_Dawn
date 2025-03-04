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
;*                 Project Name : Westwood 32 Bit Library		   *
;*                                                                         *
;*                    File Name : GBUFFER.INC                              *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : May 26, 1994                             *
;*                                                                         *
;*                  Last Update : May 26, 1994   [PWG]                     *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

;******************************************************************************
; Much testing was done to determine that only when there are 14 or more bytes
; being copied does it speed the time it takes to do copies in this algorithm.
; For this reason and because 1 and 2 byte copies crash, is the special case
; used.  SKB 4/21/94.  Tested on 486 66mhz.  Copied by PWG 6/7/04.
OPTIMAL_BYTE_COPY	equ	14

STRUC GraphicViewPort
GVPOffset		DD		?		; offset to virtual viewport
GVPWidth			DD		?		; width of virtual viewport
GVPHeight		DD		?		; height of virtual viewport
GVPXAdd			DD		?		; x mod to get to next line
GVPXPos			DD		?		; x pos relative to Graphic Buff
GVPYPos			DD		?		; y pos relative to Graphic Buff
GVPPitch		dd		?		; modulo of graphic view port
GVPBuffPtr		DD		?		; ptr to associated Graphic Buff
ENDS