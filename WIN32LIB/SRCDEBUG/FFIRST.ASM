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
;*                 Project Name : First First				   *
;*                                                                         *
;*                    File Name : FFIRST.ASM                               *
;*                                                                         *
;*                   Programmer : Jeff Wilson                              *
;*                                                                         *
;*                   Start Date : March 28, 1994                           *
;*                                                                         *
;*                  Last Update : April 15, 1994   []                      *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Find_First -- Find a file spec                                        *
;*   Find_Next -- Find next file in sreach params                          *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *



IDEAL
P386
MODEL USE32 FLAT

LOCALS ??

GLOBAL             Find_First         :NEAR
GLOBAL             Find_Next          :NEAR
		    
;============================================================================
CODESEG


;***************************************************************************
;* FIND_FIRST -- Find a file spec                                          *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*	file_name		File spec to find. Maybe a wildcard name   *
;*      mode                    File type                                  *
;*      ffblk                   file data block ptr to write info into     *
;*                                                                         *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/15/1994  jaw: Created.                                             *
;*=========================================================================*

PROC Find_First 	C near 
     	USES ebx,ecx,edx,esi,edi,es,ds
     	ARG file_name:DWORD,mode:WORD,ffblk:DWORD
     	   
     	mov	edx,[file_name]
     	mov	cx,[mode]
     		
     	mov	eax,4e00h		;first firstg function
     	
     	int	21h
     					;Find it?
     	jnc	??found_it		;=>yes
     	
	; ax holds the error code
	;insure high word of eax is clear
	or	eax,0ffffffffh
	jmp	??exit
	
??found_it:
     	; found something
     	;copy the DTA into the user block
     	mov	eax,2f00h	;get DTA address
     	int	21h
     	
     	mov	ax,es		;switch selectors
     	mov	dx,ds
     	mov	ds,ax
     	mov	es,dx
     
     	mov	esi,ebx
     	mov	edi,[ffblk]
     	
	add	esi,21		;SKIP RESERVED
	add	edi,4		;SKIP RESERVED
		 
	sub	eax,eax
	mov	al,[esi]	;get attrib byte
	mov	[es:edi+4],eax
	inc	esi
	
	;get time
	mov	ax,[esi]
	add	esi,2
	mov	[es:edi+8],ax
	
	;get date
	mov	ax,[esi]
	add	esi,2
	mov	[es:edi+10],ax
	
	;get file size
	mov	eax,[esi]
	add	esi,4
	mov	[es:edi],eax
	
	add	edi,12
		    
     	mov	ecx,13
     		    
     	rep	movsb		;copy the DTA name
     	
     	mov	ax,es
     	mov	ds,ax
     	
 	xor	eax,eax
??exit:	
	ret
;====================
ENDP Find_First	



;***************************************************************************
;* FIND_NEXT -- Find next file in sreach params                            *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*              NONE                                                       *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   04/15/1994  jaw: Created.                                             *
;*=========================================================================*
     
PROC Find_Next C near
	USES ebx,ecx,edx,esi,edi,ds,es
	
     	ARG ffblk:DWORD
     	    
	mov	eax,04f00h		;Find Next function
	
	int 21h
	       				;Find anything?
     	jnc	??found_it		;=>no
     	
	; ax holds the error code
	;insure high word of eax is clear
	or	eax,0ffffffffh
	jmp	??exit
	
??found_it:
     	; found something
     	;copy the DTA into the user block
     	mov	eax,2f00h		;get DTA address
     	int	21h
     	
     	mov	ax,es			;switch selectors
     	mov	dx,ds
     	mov	ds,ax
     	mov	es,dx
     
     	mov	esi,ebx
     	mov	edi,[ffblk]
     	
	add	esi,21			;SKIP RESERVED
	add	edi,4			;SKIP RESERVED
		 
	sub	eax,eax
	mov	al,[esi]		;get attrib byte
	mov	[es:edi+4],eax
	inc	esi
	
	;get time
	mov	ax,[esi]
	add	esi,2
	mov	[es:edi+8],ax
	
	;get date
	mov	ax,[esi]
	add	esi,2
	mov	[es:edi+10],ax
	
	;get file size
	mov	eax,[esi]
	add	esi,4
	mov	[es:edi],eax
	
	add	edi,12
		    
     	mov	ecx,13
     		    
     	rep	movsb		;copy the DTA name
     	
     	mov	ax,es
     	mov	ds,ax
     	
	xor	eax,eax
??exit:	
	ret
	
ENDP Find_Next


END








