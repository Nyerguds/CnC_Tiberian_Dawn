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
;* FILE
;*     portio.asm
;*
;* DESCRIPTION
;*     I/O Port access. (32-Bit protected mode)
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     January 26, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     inp  - Read a byte from a hardware port.
;*     outp - Write a byte to a hardware port.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??
	CODESEG

;****************************************************************************
;*
;* NAME
;*     inp - Read a byte from a hardware port.
;*
;* SYNOPSIS
;*     Data = inp(PortID)
;*
;*     short inp(unsinged short);
;*
;* FUNCTION
;*
;* INPUTS
;*     PortID - Address if hardware port.
;*
;* RESULT
;*     Data - Data read from port.
;*
;****************************************************************************

	GLOBAL	C inp:NEAR
	PROC	inp C NEAR USES edx
	ARG	port:WORD

	mov	dx,[port]
	xor	eax,eax
	in	al,dx
	ret

	ENDP	inp


;****************************************************************************
;*
;* NAME
;*     outp - Write a byte to a hardware port.
;*
;* SYNOPSIS
;*     outp(PortID, Value)
;*
;*     void outp(unsinged short, short);
;*
;* FUNCTION
;*
;* INPUTS
;*     PortID - Address if hardware port.
;*     Value  - Value to write.
;*
;* RESULT
;*     NONE
;*
;****************************************************************************

	GLOBAL	C outp:NEAR
	PROC	outp C NEAR USES edx
	ARG	port:WORD
	ARG	value:WORD

	mov	dx,[port]
	mov	ax,[value]
	out	dx,al
	ret

	ENDP	outp

	END
