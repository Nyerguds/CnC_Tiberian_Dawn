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
;**      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood 32 bit Library                  *
;*                                                                         *
;*                    File Name : DRAWBUFF.INC                             *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : January 16, 1995                         *
;*                                                                         *
;*                  Last Update : January 16, 1995   [PWG]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

; Externs from REGIONSZ.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Size_Of_Region	:NEAR

; Externs from GETPIX.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Get_Pixel          	:NEAR

; Externs from PUTPIX.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Put_Pixel 		:NEAR

; Externs from CLEAR.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Clear	          	:NEAR

; Externs from BITBLIT.ASM module of the DRAWBUFF library
GLOBAL C Linear_Blit_To_Linear		:NEAR

; Externs from TOBUFF.ASM module of the DRAWBUFF library
GLOBAL C Buffer_To_Buffer		:NEAR

; Externs from TOPAGE.ASM module of the DRAWBUFF library
GLOBAL C Buffer_To_Page		:NEAR

; Externs from SCALE.ASM module of the DRAWBUFF library
GLOBAL C Linear_Scale_To_Linear 	:NEAR

; Externs from TXTPRNT.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Print			:NEAR


;*-------------------------------------------------------------------------*
;* Define Buffer only assembly GLOBALS					   *
;*-------------------------------------------------------------------------*

; Externs from DRAWLINE.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Draw_Line:NEAR

; Externs from FILLQUAD.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Fill_Quad 		:NEAR

; Externs from FILLRECT.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Fill_Rect 		:NEAR

; Externs from REMAP.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Remap      		:NEAR

; Externs from STAMP.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Draw_Stamp 		:NEAR

; Externs from TEXFILL.ASM module of the DRAWBUFF library
GLOBAL C Buffer_Texture_Fill_Rect 		:NEAR

GLOBAL C get_clip	 	   : NEAR

struc  RECTANGLE
		  x0	dd	?
		  y0 dd	?
		  x1	dd	?
		  y1 dd ?
ends 	 RECTANGLE

