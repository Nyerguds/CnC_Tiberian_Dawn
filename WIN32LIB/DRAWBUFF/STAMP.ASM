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
;**   C O N F I D E N T I A L --- W E S T W O O D    S T U D I O S        **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Westwood Library                         *
;*                                                                         *
;*                    File Name : STAMP.ASM                                *
;*                                                                         *
;*                   Programmer : Joe L. Bostic                            *
;*                                                                         *
;*                   Start Date : August 23, 1993                          *
;*                                                                         *
;*                  Last Update : August 23, 1993   [JLB]                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

IDEAL
P386
MODEL USE32 FLAT

INCLUDE ".\drawbuff.inc"
INCLUDE ".\gbuffer.inc"

INCLUDE	"stamp.inc"

global		C Init_Stamps:near
global		LastIconset:dword
global		MapPtr:dword
global		IconCount:dword
global		IconSize:dword
global		StampPtr:dword

	DATASEG


LastIconset	DD	0	; Pointer to last iconset initialized.
StampPtr	DD	0	; Pointer to icon data.

IsTrans		DD	0	; Pointer to transparent icon flag table.

MapPtr		DD	0	; Pointer to icon map.
IconWidth	DD	0	; Width of icon in pixels.
IconHeight	DD	0	; Height of icon in pixels.
IconSize	DD	0	; Number of bytes for each icon data.
IconCount	DD	0	; Number of icons in the set.

	EVEN

	CODESEG


GLOBAL C	Buffer_Draw_Stamp:near
GLOBAL C	Buffer_Draw_Stamp_Clip:near

; 256 color icon system.

;***********************************************************
; INIT_STAMPS
;
; VOID cdecl Init_Stamps(VOID *icondata);
;
; This routine initializes the stamp data.
; Bounds Checking: NONE
;
;*
	PROC	Init_Stamps C near USES eax ebx edx edi
	ARG	icondata:DWORD

	; Verify legality of parameter.
	cmp	[icondata],0
	je	short ??fini

	; Don't initialize if already initialized to this set (speed reasons).
	mov	edi,[icondata]
	cmp	[LastIconset],edi
	je	short ??fini
	mov	[LastIconset],edi

	; Record number of icons in set.
	movzx	eax,[(IControl_Type edi).Count]
	mov	[IconCount],eax

	; Record width of icon.
	movzx	eax,[(IControl_Type edi).Width]
	mov	[IconWidth],eax

	; Record height of icon.
	movzx	ebx,[(IControl_Type edi).Height]
	mov	[IconHeight],ebx

	; Record size of icon (in bytes).
	mul	ebx
	mov	[IconSize],eax

	; Record hard pointer to icon map data.
	mov	eax,[(IControl_Type edi).Map]
	add	eax,edi
	mov	[MapPtr],eax

??nomap:
	; Record hard pointer to icon data.
	mov	eax,edi
	add	eax,[(IControl_Type edi).Icons]
	mov	[StampPtr],eax

	; Record the transparent table.
	mov	eax,edi
	add	eax,[(IControl_Type edi).TransFlag]
	mov	[IsTrans],eax

??fini:
	ret

	ENDP	Init_Stamps


;***********************************************************


;***********************************************************
; DRAW_STAMP
;
; VOID cdecl Buffer_Draw_Stamp(VOID *icondata, WORD icon, WORD x_pixel, WORD y_pixel, VOID *remap);
;
; This routine renders the icon at the given coordinate.
;
; The remap table is a 256 byte simple pixel translation table to use when
; drawing the icon.  Transparency check is performed AFTER the remap so it is possible to
; remap valid colors to be invisible (for special effect reasons).
; This routine is fastest when no remap table is passed in.
;*
	PROC	Buffer_Draw_Stamp C near

	ARG	this_object:DWORD		; this is a member function
	ARG	icondata:DWORD		; Pointer to icondata.
	ARG	icon:DWORD		; Icon number to draw.
	ARG	x_pixel:DWORD		; X coordinate of icon.
	ARG	y_pixel:DWORD		; Y coordinate of icon.
	ARG	remap:DWORD 		; Remap table.

	LOCAL	modulo:DWORD		; Modulo to get to next row.
	LOCAL	iwidth:DWORD		; Icon width (here for speedy access).
	LOCAL	doremap:BYTE		; Should remapping occur?

	pushad
	cmp	[icondata],0
	je	??out

	; Initialize the stamp data if necessary.
	mov	eax,[icondata]
	cmp	[LastIconset],eax
	je	short ??noreset
	call	Init_Stamps C,eax
??noreset:

	; Determine if the icon number requested is actually in the set.
	; Perform the logical icon to actual icon number remap if necessary.
	mov	ebx,[icon]
	cmp	[MapPtr],0
	je	short ??notmap
	mov	edi,[MapPtr]
	mov	bl,[edi+ebx]
??notmap:
	cmp	ebx,[IconCount]
	jae	??out
	mov	[icon],ebx		; Updated icon number.

	; If the remap table pointer passed in is NULL, then flag this condition
	; so that the faster (non-remapping) icon draw loop will be used.
	cmp	[remap],0
	setne	[doremap]

	; Get pointer to position to render icon. EDI = ptr to destination page.
	mov	ebx,[this_object]
	mov	edi,[(GraphicViewPort ebx).GVPOffset]
	mov	eax,[(GraphicViewPort ebx).GVPWidth]
	add	eax,[(GraphicViewPort ebx).GVPXAdd]
	add	eax,[(GraphicViewPort ebx).GVPPitch]
	push	eax			; save viewport full width for lower
	mul	[y_pixel]
	add	edi,eax
	add	edi,[x_pixel]

	; Determine row modulo for advancing to next line.
	pop	eax			; retrieve viewport width
	sub	eax,[IconWidth]
	mov	[modulo],eax

	; Setup some working variables.
	mov	ecx,[IconHeight]	; Row counter.
	mov	eax,[IconWidth]
	mov	[iwidth],eax		; Stack copy of byte width for easy BP access.

	; Fetch pointer to start of icon's data.  ESI = ptr to icon data.
	mov	eax,[icon]
	mul	[IconSize]
	mov	esi,[StampPtr]
	add	esi,eax

	; Determine whether simple icon draw is sufficient or whether the
	; extra remapping icon draw is needed.
	cmp	[BYTE PTR doremap],0
	je	short ??istranscheck

	;************************************************************
	; Complex icon draw -- extended remap.
	; EBX = Palette pointer (ready for XLAT instruction).
	; EDI = Pointer to icon destination in page.
	; ESI = Pointer to icon data.
	; ECX = Number of pixel rows.
;;;	mov	edx,[remap]
 mov ebx,[remap]
	xor	eax,eax
??xrowloop:
	push	ecx
	mov	ecx,[iwidth]

??xcolumnloop:
	lodsb
;;;	mov	ebx,edx
;;;	add	ebx,eax
;;;	mov	al,[ebx]		; New real color to draw.
 xlatb
	or	al,al
	jz	short ??xskip1		; Transparency skip check.
	mov	[edi],al
??xskip1:
	inc	edi
	loop	??xcolumnloop

	pop	ecx
	add	edi,[modulo]
	loop	??xrowloop
	jmp	short ??out


	;************************************************************
	; Check to see if transparent or generic draw is necessary.
??istranscheck:
	mov	ebx,[IsTrans]
	add	ebx,[icon]
	cmp	[BYTE PTR ebx],0
	jne	short ??rowloop

	;************************************************************
	; Fast non-transparent icon draw routine.
	; ES:DI = Pointer to icon destination in page.
	; DS:SI = Pointer to icon data.
	; CX = Number of pixel rows.
	mov	ebx,ecx
	shr	ebx,2
	mov	edx,[modulo]
	mov	eax,[iwidth]
	shr	eax,2
??loop1:
	mov	ecx,eax
	rep movsd
	add	edi,edx

	mov	ecx,eax
	rep movsd
	add	edi,edx

	mov	ecx,eax
	rep movsd
	add	edi,edx

	mov	ecx,eax
	rep movsd
	add	edi,edx

	dec	ebx
	jnz	??loop1
	jmp	short ??out

	;************************************************************
	; Transparent icon draw routine -- no extended remap.
	; ES:DI = Pointer to icon destination in page.
	; DS:SI = Pointer to icon data.
	; CX = Number of pixel rows.
??rowloop:
	push	ecx
	mov	ecx,[iwidth]

??columnloop:
	lodsb
	or	al,al
	jz	short ??skip1		; Transparency check.
	mov	[edi],al
??skip1:
	inc	edi
	loop	??columnloop

	pop	ecx
	add	edi,[modulo]
	loop	??rowloop

	; Cleanup and exit icon drawing routine.
??out:
	popad
	ret

	ENDP	Buffer_Draw_Stamp




;***********************************************************
; DRAW_STAMP_CLIP
;
; VOID cdecl MCGA_Draw_Stamp_Clip(VOID *icondata, WORD icon, WORD x_pixel, WORD y_pixel, VOID *remap, LONG min_x, LONG min_y, LONG max_x, LONG max_y);
;
; This routine renders the icon at the given coordinate.
;
; The remap table is a 256 byte simple pixel translation table to use when
; drawing the icon.  Transparency check is performed AFTER the remap so it is possible to
; remap valid colors to be invisible (for special effect reasons).
; This routine is fastest when no remap table is passed in.
;*
	PROC	Buffer_Draw_Stamp_Clip C near

	ARG	this_object:DWORD	; this is a member function
	ARG	icondata:DWORD		; Pointer to icondata.
	ARG	icon:DWORD		; Icon number to draw.
	ARG	x_pixel:DWORD		; X coordinate of icon.
	ARG	y_pixel:DWORD		; Y coordinate of icon.
	ARG	remap:DWORD 		; Remap table.
	ARG	min_x:DWORD		; Clipping rectangle boundary
	ARG	min_y:DWORD		; Clipping rectangle boundary
	ARG	max_x:DWORD		; Clipping rectangle boundary
	ARG	max_y:DWORD		; Clipping rectangle boundary

	LOCAL	modulo:DWORD		; Modulo to get to next row.
	LOCAL	iwidth:DWORD		; Icon width (here for speedy access).
	LOCAL	skip:DWORD		; amount to skip per row of icon data
	LOCAL	doremap:BYTE		; Should remapping occur?

	pushad
	cmp	[icondata],0
	je	??out2

	; Initialize the stamp data if necessary.
	mov	eax,[icondata]
	cmp	[LastIconset],eax
	je	short ??noreset2
	call	Init_Stamps C,eax
??noreset2:

	; Determine if the icon number requested is actually in the set.
	; Perform the logical icon to actual icon number remap if necessary.
	mov	ebx,[icon]
	cmp	[MapPtr],0
	je	short ??notmap2
	mov	edi,[MapPtr]
	mov	bl,[edi+ebx]
??notmap2:
	cmp	ebx,[IconCount]
	jae	??out2
	mov	[icon],ebx		; Updated icon number.

	; Setup some working variables.
	mov	ecx,[IconHeight]	; Row counter.
	mov	eax,[IconWidth]
	mov	[iwidth],eax		; Stack copy of byte width for easy BP access.

	; Fetch pointer to start of icon's data.  ESI = ptr to icon data.
	mov	eax,[icon]
	mul	[IconSize]
	mov	esi,[StampPtr]
	add	esi,eax

	; Update the clipping window coordinates to be valid maxes instead of width & height
	; , and change the coordinates to be window-relative
	mov	ebx,[min_x]
	add	[max_x],ebx
	add	[x_pixel],ebx		; make it window-relative
	mov	ebx,[min_y]
	add	[max_y],ebx
	add	[y_pixel],ebx		; make it window-relative

	; See if the icon is within the clipping window
	; First, verify that the icon position is less than the maximums
	mov	ebx,[x_pixel]
	cmp	ebx,[max_x]
	jge	??out2
	mov	ebx,[y_pixel]
	cmp	ebx,[max_y]
	jge	??out2
	; Now verify that the icon position is >= the minimums
	add	ebx,[IconHeight]
	cmp	ebx,[min_y]
	jle	??out2
	mov	ebx,[x_pixel]
	add	ebx,[IconWidth]
	cmp	ebx,[min_x]
	jle	??out2

	; Now, clip the x, y, width, and height variables to be within the
	; clipping rectangle
	mov	ebx,[x_pixel]
	cmp	ebx,[min_x]
	jge	??nominxclip
	; x < minx, so must clip
	mov	ebx,[min_x]
	sub	ebx,[x_pixel]
	add	esi,ebx		; source ptr += (minx - x)
	sub	[iwidth],ebx	; icon width -= (minx - x)
	mov	ebx,[min_x]
	mov	[x_pixel],ebx

??nominxclip:
	mov	eax,[IconWidth]
	sub	eax,[iwidth]
	mov	[skip],eax

	; Check for x+width > max_x
	mov	eax,[x_pixel]
	add	eax,[iwidth]
	cmp	eax,[max_x]
	jle	??nomaxxclip
	; x+width is greater than max_x, so must clip width down
	mov	eax,[iwidth]	; eax = old width
	mov	ebx,[max_x]
	sub	ebx,[x_pixel]
	mov	[iwidth],ebx	; iwidth = max_x - xpixel
	sub	eax,ebx
	add	[skip],eax	; skip += (old width - iwidth)
??nomaxxclip:
	; check if y < miny
	mov	eax,[min_y]
	cmp	eax,[y_pixel]	; if(miny <= y_pixel), no clip needed
	jle	??nominyclip
	sub	eax,[y_pixel]
	sub	ecx,eax		; height -= (miny - y)
	mul	[IconWidth]
	add	esi,eax		; icon source ptr += (width * (miny - y))
	mov	eax,[min_y]
	mov	[y_pixel],eax	; y = miny
??nominyclip:
	; check if (y+height) > max y
	mov	eax,[y_pixel]
	add	eax,ecx
	cmp	eax,[max_y]	; if (y + height <= max_y), no clip needed
	jle	??nomaxyclip
	mov	ecx,[max_y]	; height = max_y - y_pixel
	sub	ecx,[y_pixel]
??nomaxyclip:

	; If the remap table pointer passed in is NULL, then flag this condition
	; so that the faster (non-remapping) icon draw loop will be used.
	cmp	[remap],0
	setne	[doremap]

	; Get pointer to position to render icon. EDI = ptr to destination page.
	mov	ebx,[this_object]
	mov	edi,[(GraphicViewPort ebx).GVPOffset]
	mov	eax,[(GraphicViewPort ebx).GVPWidth]
	add	eax,[(GraphicViewPort ebx).GVPXAdd]
	add	eax,[(GraphicViewPort ebx).GVPPitch]
	push	eax			; save viewport full width for lower
	mul	[y_pixel]
	add	edi,eax
	add	edi,[x_pixel]

	; Determine row modulo for advancing to next line.
	pop	eax			; retrieve viewport width
	sub	eax,[iwidth]
	mov	[modulo],eax

	; Determine whether simple icon draw is sufficient or whether the
	; extra remapping icon draw is needed.
	cmp	[BYTE PTR doremap],0
	je	short ??istranscheck2

	;************************************************************
	; Complex icon draw -- extended remap.
	; EBX = Palette pointer (ready for XLAT instruction).
	; EDI = Pointer to icon destination in page.
	; ESI = Pointer to icon data.
	; ECX = Number of pixel rows.
	mov	ebx,[remap]
	xor	eax,eax
??xrowloopc:
	push	ecx
	mov	ecx,[iwidth]

??xcolumnloopc:
	lodsb
	xlatb
	or	al,al
	jz	short ??xskip1c		; Transparency skip check.
	mov	[edi],al
??xskip1c:
	inc	edi
	loop	??xcolumnloopc

	pop	ecx
	add	edi,[modulo]
 add esi,[skip]
	loop	??xrowloopc
	jmp	short ??out2


	;************************************************************
	; Check to see if transparent or generic draw is necessary.
??istranscheck2:
	mov	ebx,[IsTrans]
	add	ebx,[icon]
	cmp	[BYTE PTR ebx],0
	jne	short ??rowloopc

	;************************************************************
	; Fast non-transparent icon draw routine.
	; ES:DI = Pointer to icon destination in page.
	; DS:SI = Pointer to icon data.
	; CX = Number of pixel rows.
	mov	ebx,ecx
	mov	edx,[modulo]
	mov	eax,[iwidth]

	;
	; Optimise copy by dword aligning the destination
	;
??loop1c:
	push	eax
 rept 3
	test	edi,3
	jz	??aligned
	movsb
	dec	eax
	jz	??finishedit
 endm
??aligned:
	mov	ecx,eax
	shr	ecx,2
	rep	movsd
	mov	ecx,eax
	and	ecx,3
	rep	movsb

??finishedit:
	add	edi,edx
	add	esi,[skip]
	pop	eax

	dec	ebx
	jnz	??loop1c
	jmp	short ??out2

	;************************************************************
	; Transparent icon draw routine -- no extended remap.
	; ES:DI = Pointer to icon destination in page.
	; DS:SI = Pointer to icon data.
	; CX = Number of pixel rows.
??rowloopc:
	push	ecx
	mov	ecx,[iwidth]

??columnloopc:
	lodsb
	or	al,al
	jz	short ??skip1c		; Transparency check.
	mov	[edi],al
??skip1c:
	inc	edi
	loop	??columnloopc

	pop	ecx
	add	edi,[modulo]
 add esi,[skip]
	loop	??rowloopc

	; Cleanup and exit icon drawing routine.
??out2:
	popad
	ret

	ENDP	Buffer_Draw_Stamp_Clip

	END
