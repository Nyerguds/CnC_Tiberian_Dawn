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


IDEAL
P386
MODEL USE32 FLAT

LOCALS ??


DPMI_INTR equ	031h

GLOBAL 	DPMI_real_alloc   : near
GLOBAL  DPMI_real_free    : near
GLOBAL  DPMI_real_intr    : near
GLOBAL  DPMI_real_call    : near


STRUC SEGSEL
	  segmen  dw ?
 	  select  dw ?
ENDS

STRUC REGS 
	_eax   dd ?
	_ebx   dd ?
	_ecx   dd ?
	_edx   dd ?
	_esi   dd ?
	_edi   dd ?
	_cflag dd ?
ENDS

STRUC SREGS 
	_es  dw ?
	_cs  dw ?
	_ss  dw ?
	_ds  dw ?
        _fs  dw ?
	_gs  dw ?
ENDS

STRUC DPMI_REGS
       _edi  dd ?
       _esi  dd ?	
       _ebp  dd ?	
       	     dd ?
       _ebx  dd ?	
       _edx  dd ?	
       _ecx  dd ?	
       _eax  dd ?	
       Flags dw ?
       _es   dw ?
       _ds   dw ?
       _fs   dw ?
       _gs   dw ?
       _ip   dw ?
       _cs   dw ?
       _sp   dw ?
       _ss   dw ?
       	     dd ?
	     dd	?
   size_ref  db	?	
ENDS
    
    
CODESEG

; int  DPMI_real_alloc ( UINT , SEGREG * , USHORT * ) ;

PROC DPMI_real_alloc C near 
	USES	ebx , edx
	ARG	paragra        : DWORD
	ARG	blk_segptr    : DWORD
	ARG	largest_blkptr : DWORD

	mov	eax, 0100h
	mov	ebx, [paragra]
	int	DPMI_INTR

	jnc	??dpmi_succed
	mov	ebx, [largest_blkptr]
	mov	[ word ptr ebx ] , bx
	movzx	eax , al
 	ret

??dpmi_succed:
	mov	ebx, [blk_segptr]
	mov	[(type SEGSEL ptr ebx). segmen ] , ax
	mov	[(type SEGSEL ptr ebx). select ] , dx
	xor	eax , eax
	ret
		
ENDP DPMI_real_alloc	


;**************************************************************************
; int  DPMI_real_free ( UINT ) ;

PROC DPMI_real_free C near 
	USES	eax , edx
	ARG	blk_selec  : DWORD

	mov	eax, 0101h
	mov	edx, [blk_selec]
	shr	edx , 16
	int	DPMI_INTR
 	ret
ENDP DPMI_real_free	


PROC DPMI_real_intr C near 
	USES	eax , ebx , ecx , edx , edi , esi 
	ARG	vector  : dword
	ARG     regs_ptr: dword
	ARG     sreg_ptr: dword

	LOCAL	regblk : DPMI_REGS

	lea	edi , [ regblk ]
	xor	eax , eax
	lea	ecx , [ regblk . size_ref ]
	sub	ecx , edi
	shr	ecx , 2
	rep	stosd

  	mov	ebx , [ regs_ptr ]
	mov	eax , [ (type REGS ptr ebx) . _eax ] 
	mov	[ regblk . _eax ] , eax

	mov	eax , [ (type REGS ptr ebx) . _ebx ] 
	mov	[ regblk . _ebx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _ecx ] 
	mov	[ regblk . _ecx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _edx ] 
	mov	[ regblk . _edx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _esi ] 
	mov	[ regblk . _esi ] , eax

	mov	eax , [ (type REGS ptr ebx) . _edi ] 
	mov	[ regblk . _edi ] , eax


  	mov	ebx , [ sreg_ptr ]
	mov	ax , [ (type SREGS ptr ebx) . _es ] 
	mov	[ regblk . _es ] , ax

	mov	ax , [ (type SREGS ptr ebx) . _ds ] 
	mov	[ regblk . _ds ] , ax

	mov	eax , 0300h
	mov	ebx , [ vector ]
	xor     bh , bh
	xor 	ecx , ecx
	lea	edi , [ regblk ]

	int	DPMI_INTR

  	mov	ebx , [ regs_ptr ]
	mov	eax , [ regblk . _eax ] 
	mov	[ (type REGS ptr ebx) . _eax ] , eax

	mov	eax , [ regblk . _ebx ] 
	mov	[ (type REGS ptr ebx) . _ebx ] , eax

	mov	eax , [ regblk . _ecx ] 
	mov	[ (type REGS ptr ebx) . _ecx ] , eax

	mov	eax , [ regblk . _edx ] 
	mov	[ (type REGS ptr ebx) . _edx ] , eax

	mov	eax , [ regblk . _esi ] 
	mov	[ (type REGS ptr ebx) . _esi ] , eax

	mov	eax , [ regblk . _edi ] 
	mov	[ (type REGS ptr ebx) . _edi ] , eax


  	mov	ebx , [ sreg_ptr ]
	mov	ax , [ regblk . _es ] 
	mov	[ (type SREGS ptr ebx) . _es ] , ax

	mov	ax , [ regblk . _ds ] 
	mov	[ (type SREGS ptr ebx) . _ds ] , ax

 	ret
ENDP DPMI_real_intr	


PROC DPMI_real_call C near 
	USES	eax , ebx , ecx , edx , edi , esi 
	ARG	vector  : dword
	ARG     regs_ptr: dword
	ARG     sreg_ptr: dword

	LOCAL	regblk : DPMI_REGS


	lea	edi , [ regblk ]
	xor	al , al
	lea	ecx , [ regblk . size_ref ]
	sub	ecx , edi
	rep	movsb


  	mov	ebx , [ regs_ptr ]
	mov	eax , [ (type REGS ptr ebx) . _eax ] 
	mov	[ regblk . _eax ] , eax

	mov	eax , [ (type REGS ptr ebx) . _ebx ] 
	mov	[ regblk . _ebx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _ecx ] 
	mov	[ regblk . _ecx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _edx ] 
	mov	[ regblk . _edx ] , eax

	mov	eax , [ (type REGS ptr ebx) . _esi ] 
	mov	[ regblk . _esi ] , eax

	mov	eax , [ (type REGS ptr ebx) . _edi ] 
	mov	[ regblk . _edi ] , eax


  	mov	ebx , [ sreg_ptr ]
	mov	ax , [ (type SREGS ptr ebx) . _es ] 
	mov	[ regblk . _es ] , ax

	mov	ax , [ (type SREGS ptr ebx) . _ds ] 
	mov	[ regblk . _ds ] , ax

;	mov	eax , 0300h
;	mov	ebx , [ vector ]
;	xor     bh , bh
;	xor 	ecx , ecx
;	lea	edi , [ regblk ]

;	int	DPMI_INTR

  	mov	ebx , [ regs_ptr ]
	mov	eax , [ regblk . _eax ] 
	mov	[ (type REGS ptr ebx) . _eax ] , eax
	mov	eax , [ regblk . _ebx ] 
	mov	[ (type REGS ptr ebx) . _ebx ] , eax
	mov	eax , [ regblk . _ecx ] 
	mov	[ (type REGS ptr ebx) . _ecx ] , eax
	mov	eax , [ regblk . _edx ] 
	mov	[ (type REGS ptr ebx) . _edx ] , eax

	mov	eax , [ regblk . _esi ] 
	mov	[ (type REGS ptr ebx) . _esi ] , eax
	mov	eax , [ regblk . _edi ] 
	mov	[ (type REGS ptr ebx) . _edi ] , eax


  	mov	ebx , [ sreg_ptr ]
	mov	ax , [ regblk . _es ] 
	mov	[ (type SREGS ptr ebx) . _es ] , ax

	mov	ax , [ regblk . _ds ] 
	mov	[ (type SREGS ptr ebx) . _ds ] , ax

 	ret
ENDP DPMI_real_call

END



