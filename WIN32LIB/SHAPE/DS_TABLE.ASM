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
;*                 Project Name : Draw Shape Routines for library.         *
;*                                                                         *
;*                    File Name : DS_TABLE.ASM                             *
;*                                                                         *
;*                   Programmer : Scott K. Bowen                           *
;*                                                                         *
;*                   Start Date : August 20, 1993                          *
;*                                                                         *
;*                  Last Update : September 6, 1994   [IML]                *
;*                                                                         *
;* This module sets up a table of procedure addresses for combinations of  *
;* NORMAL, HORZ_REV and SCALING	flags.					   *	
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************** Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT


;******************************** Includes *********************************
INCLUDE "shape.inc"


;******************************** Equates **********************************
;*=========================================================================*/
;* The following are defines used to control what functions are linked	   *
;* in for Draw_Shape.							   *
;*=========================================================================*/
USE_NORMAL	EQU	TRUE
USE_HORZ_REV 	EQU	TRUE
USE_VERT_REV 	EQU	TRUE
USE_SCALING 	EQU	TRUE


;---------------------------------------------------------------------------
;
; Use a macro to make code a little cleaner.
; The parameter varname is optional.
; Syntax to use macro is :
;  WANT equ expression
;  USE func [,varname]
; If the 'varname' is defined, a table declaration is created like:
;	GLOBAL	TableName:DWORD
; Then, the table entry is created:
;  If WANT is true, the table entry is created for the given function:
;	varname	DD	func
;  If WANT is not TRUE, a Not_Supported entry is put in the table:
;	varname	DD	Not_Supported
; The resulting tables look like:
;
;	GLOBAL	ExampTable:DWORD
;	ExampTable	DD	routine1
;			DD	routine2
;			DD	routine3
;			...
; Thus, each table is an array of function pointers.
;
;---------------------------------------------------------------------------
MACRO USE func, varname
 IFNB <varname>
	GLOBAL	varname:DWORD
 ENDIF
 IF WANT
  varname 	DD	func
 ELSE
  varname	DD	Not_Supported
 ENDIF
ENDM


;---------------------------------------------------------------------------
; Data Segment Tables:
; This code uses the USE macro to set up tables of function addresses.
; The tables have the following format:
; Tables defined are:
;	LSkipTable
;	RSkipTable
;	DrawTable
;---------------------------------------------------------------------------

	DATASEG

;---------------------------------------------------------------------------

WANT	equ 	<TRUE>
USE	Left_Skip, LSkipTable

WANT	equ 	<TRUE>
USE	Left_Reverse_Skip

WANT	equ 	<TRUE>
USE	Left_Skip

WANT	equ 	<TRUE>
USE	Left_Reverse_Skip

WANT	equ 	<USE_SCALING>
USE	Left_Scale_Skip

WANT	equ 	<USE_SCALING>
USE	Left_Scale_Reverse_Skip

WANT	equ 	<USE_SCALING>
USE	Left_Scale_Skip

WANT	equ 	<USE_SCALING>
USE	Left_Scale_Reverse_Skip
;---------------------------------------------------------------------------

WANT	equ 	<TRUE>
USE	Right_Skip, RSkipTable

WANT	equ 	<TRUE>
USE	Right_Reverse_Skip

WANT	equ 	<TRUE>
USE	Right_Skip

WANT	equ 	<TRUE>
USE	Right_Reverse_Skip

WANT	equ 	<USE_SCALING>
USE	Right_Scale_Skip

WANT	equ 	<USE_SCALING>
USE	Right_Scale_Reverse_Skip

WANT	equ 	<USE_SCALING>
USE	Right_Scale_Skip

WANT	equ 	<USE_SCALING>
USE	Right_Scale_Reverse_Skip
;---------------------------------------------------------------------------

WANT	equ 	<TRUE>
USE	Draw_Normal, DrawTable

WANT	equ 	<TRUE>
USE	Draw_Reverse

WANT	equ 	<TRUE>
USE	Draw_Normal

WANT	equ 	<TRUE>
USE	Draw_Reverse

WANT	equ 	<USE_SCALING>
USE	Draw_Scale

WANT	equ 	<USE_SCALING>
USE	Draw_Scale_Reverse

WANT	equ 	<USE_SCALING>
USE	Draw_Scale

WANT	equ 	<USE_SCALING>
USE	Draw_Scale_Reverse
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
	END

;************************** End of ds_table.asm ****************************
