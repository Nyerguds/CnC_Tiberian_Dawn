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
;*                 Project Name : WWLIB32                                  *
;*                                                                         *
;*                    File Name : DRAWSHP.ASM                              *
;*                                                                         *
;*                   Programmer : Phil W. Gorrow                           *
;*                                                                         *
;*                   Start Date : April 13, 1992                           *
;*                                                                         *
;*                  Last Update : September 14, 1994   [IML]               *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*   Draw_Shape -- Draws a shape at given buffer coordinates and clips     *
;*   Not_Supported -- Replacement function for Draw_Shape routines not used*
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *
;********************* Model & Processor Directives ************************
IDEAL
P386
MODEL USE32 FLAT


; this struct is here to remove the hardwire way of programing
; implemented in the funtion Draw_Shape in ian image of 

STRUC	VVPC_IMAGE
   		Off  	dd  ?  
		Width  	dd  ?  
		Height  dd  ?  
  		Page    dd  ?  
ENDS



STRUC GVPC_IMAGE 
		 vvpc		VVPC_IMAGE	<>
		 Xpos		dd	   	?
		 Ypos		dd	   	?
		 GraphicBuff	dd	   	?
ENDS


;******************************** Includes *********************************
INCLUDE "shape.inc"


;****************************** Declarations ********************************
GLOBAL	 Draw_Shape:NEAR
GLOBAL	 LCW_Uncompress:NEAR
GLOBAL	_ShapeBuffer:DWORD
GLOBAL	_ShapeBufferSize:DWORD

GLOBAL	MaskPage	       : dword
GLOBAL	BackGroundPage	       : dword


;********************************* Data ************************************
	DATASEG
;---------------------------------------------------------------------------
; Shape buffer & its size, set by Set_Shape_Buffer()
;---------------------------------------------------------------------------
_ShapeBuffer		DD	0
_ShapeBufferSize	DD	0

;---------------------------------------------------------------------------
; Address of MaskPage & BackGroundPage, set by Init_Priority_System()
;---------------------------------------------------------------------------
MaskPage		DD	0
BackGroundPage		DD	0

;---------------------------------------------------------------------------
; Predator effect variables 
;---------------------------------------------------------------------------
PredCount	DD	0
PredTable	DB	1, 3, 2, 5, 4, 3, 2, 1
PredValue	DD	1
PartialPred	DD	0	; partially faded predator effect value
PartialCount	DD	0

;---------------------------------------------------------------------------
; 32 bit versions of 16 bit stack variables
;---------------------------------------------------------------------------
Flags		DD	?	; globally accessible copy of flags

viewport_ptr	DD	?	; pointer to upper-left corner of viewport 
viewport_width	DD	?	; viewport width
viewport_height DD	?	; viewport height
viewport_yadd	DD	?	; viewport y add
viewport_x	DD	?	; viewport x-coord
viewport_y	DD	?	; viewport y-coord
buff_ptr	DD	?	; pointer to buffer containing viewport

;********************************* Code ************************************
	CODESEG


;***************************************************************************
;* Draw_Shape -- Draws a shape at given buffer coordinates and clips       *
;*                                                                         *
;* INPUT:                                                                  *
;*  DWORD	gvp_ptr		; pointer to graphic viewport info	   *
;*  DWORD	shape_ptr	; the shape pointer to draw		   *
;*  DWORD	draw_x		; x-coord of hotspot in viewport	   *
;*  DWORD	draw_y		; y-coord of hotspot in viewport	   *
;*  DWORD	flags		; the flags for drawing the shape	   *
;*									   *
;* Optional Arguments: If the following flags are used, the given args	   *
;* MUST be present.  Note that, if more than one one set of args is used,  *
;* they must appear in this order (alphabetical).			   *
;*  SHAPE_COLOR:	DWORD color_table (256 bytes)			   *
;*  SHAPE_FADING:	DWORD fade_table (256 bytes), DWORD fade_count	   *
;*  SHAPE_GHOST:	DWORD is_translucent tbl, DWORD translucent tbl    *
;*  SHAPE_PARTIAL:	DWORD predator partial_value (0-255)		   *
;*  SHAPE_PRIORITY:	DWORD priority_level				   *
;*  SHAPE_SCALING:	DWORD x_scale, WORD y_scale			   *
;*  SHAPE_SHADOW:	DWORD shadowing_table (256 bytes)		   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*  none.								   *
;*                                                                         *
;* WARNINGS:								   *
;*  none.								   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;*									   *
;* File Organization:							   *
;* drawshp.asm : this file						   *
;* shape.inc   : main shape header file; contains declarations for all	   *
;* 		  globals, procedures and constants			   *
;* ds_table.asm: contains the procedure address tables for LSkipRout,	   *
;*		  RSkipRout, DrawRout, & PixelRout			   *
;* ds_l*.asm   : left-skip routines					   *
;* ds_r*.asm   : right-skip routines					   *
;* ds_d*.asm   : drawing routines					   *
;* 									   *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* Shape format:							   *
;* Header:								   *
;*   UWORD  SType (0=normal, 1=16-color, 2=uncompressed, 4=variable-color) *
;*   UBYTE  Height							   *
;*   UWORD  Width							   *
;*   UBYTE  unmodified height						   *
;*   UWORD  size of shape in memory, including this header		   *
;*   UWORD  uncompressed data size					   *
;* Normal Shape:							   *
;*   UBYTE  [compressed] Shape data					   *
;* 16-color shape:							   *
;*   UBYTE  16-color table						   *
;*   UBYTE  [compressed] Shape data					   *
;* variable-color shape:						   *
;*   UBYTE  # colors							   *
;*   UBYTE  color table (variable-length)				   *
;*   UBYTE  [compressed] Shape data					   *
;*									   *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* Uncompressed shape data format:					   *
;* Data is stored as a bitmap, with 0's treated as a special case.  Every  *
;* 0 byte is followed by a repetition count byte.  Every scan line is	   *
;* compressed separately.  Thus, the following bitmap results in the	   *
;* following shape data:						   *
;*	0 0 0 5 6 7 0 0 0 0						   *
;*	0 0 0 5 6 7 0 0 0 0						   *
;*	0 0 0 5 6 7 0 0 0 0						   *
;*									   *
;*	0 3 5 6 7 0 4							   *
;*	0 3 5 6 7 0 4							   *
;*	0 3 5 6 7 0 4							   *
;*                                                                         *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* How scaling is handled:						   *
;*  Scaling is done by accumulating the x & y scale values.  When the high *
;*  byte of the accumulated value is set, the pixel (for x-scaling) or	   *
;*  the line (for y-scaling) is drawn.  The high byte is then cleared,	   *
;*  and the low byte is left so roundoffs continue to accumulate.	   *
;*									   *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* Drawing Procedures:							   *
;*                                                                         *
;*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*
;*                                                                         *
;*  RSkipRout: skips given # bytes of data on the right-hand side of a	   *
;*  shape.  Just has to handle changing the current byte offset in the 	   *
;*  shape data buffer, since the draw routine knows where the left-hand	   *
;*  side of the drawable region is.  The routine may skip more bytes than  *
;*  it was told if it encounters a run of 0's, but it's assumed that a	   *
;*  run of 0's will never go past the right edge of a shape.		   *
;*    Input:								   *
;*		ECX - number of uncompressed bytes to skip		   *
;*		ESI - shape buffer data address				   *
;*    Output:								   *
;* 		ECX - negative # bytes overrun, or 0			   *
;*		ESI - updated to the current location in the shape data	   *
;*									   *
;*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*
;*                                                                         *
;*  LSkipRout: skips given # bytes of data on the left-hand side of a	   *
;*  shape.  This routine must update the shape data byte offset, and it	   *
;*  must properly update the current drawing position due to scaling, so   *
;*  it's a little more involved than the RSkip routine.  The routine may   *
;*  skip more bytes than it's told if it encounters a run of 0's.  If this *
;*  happens, the draw routine must take these extra bytes into 		   *
;*  consideration.							   *
;*    Input:								   *
;*		ECX = number of uncompressed bytes to skip		   *
;*		ESI = shape (source) buffer data address		   *
;*		EDI = viewport (destination) address			   *
;*		[WidthCount] = shape's width in bytes			   *
;*    Output:								   *
;* 		ECX - negative # pixels (not bytes) overrun, or 0	   *
;*		EDX - accumulated XTotal value at new pixel location	   *
;*		ESI - updated to the current location in the shape data	   *
;*		EDI - incr/decr by # pixels (not bytes) overrun		   *
;*		[WidthCount] - decremented by # bytes skipped		   *
;*									   *
;*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*
;*									   *
;*  DrawRout: draws one row of pixels, handles scaling, reversal and 	   *
;*	      any per pixel effects like predator, shadow etc.		   *
;*  EDX must be set up as follows:					   *
;*  - No scaling: 0							   *
;*  - No left-clipping: 0						   *
;*  - Left clipping, but no overrun: set to computed initial value for	   *
;*    that viewport coordinate						   *
;*  - Left clipping, with overrun: set to XTotal value for that coordinate *
;*  In any case, only the low byte of DL should contain data; the current  *
;*  byte in the shapebuffer should always be the first drawable pixel,	   *
;*  even if it's partially clipped (in which case DL will contain data).   *
;*    Input:								   *
;*		ECX = number of pixels (not bytes) to draw		   *
;*		EDX = XTotal initializer value				   *
;*		ESI = shape (source) buffer address			   *
;*		EDI = viewport (destination) address			   *
;*		[WidthCount] = remaining bytes on the line		   *
;*    Output:								   *
;*		ESI - updated to current location in the shape data	   *
;*		EDI - incr/decr by # pixels (not bytes) drawn/skipped	   *
;*		[WidthCount] - decremented by # bytes (not pixels) drawn   *
;*									   *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* Algorithm:								   *
;* - Initialize globals							   *
;* - Pull optional arguments off the stack				   *
;* - Set up drawing procedure pointers based on drawing flags		   *
;* - Read the values from the shape header				   *
;* - Compute the shape's scaled width & height				   *
;* - Adjust the shape's drawing coordinates based on centering & 	   *
;*   viewport-relative flag settings					   *
;* - Compute the clipped areas of the shape				   *
;* - Compute the number of drawn pixels horizontally & vertically	   *
;* - Compute the starting drawing offset in the viewport		   *
;* - Draw the shape							   *
;*									   *
;*-------------------------------------------------------------------------*
;*                                                                         *
;* HISTORY:                                                                *
;*   04/13/1992 PWG : Created.                                             *
;*   08/19/1993 SKB : Split drawshp.asm into several modules.              *
;*   05/26/1994 BR  : Converted to 32-bit, restructured quite a bit.	   *
;*   08/09/1994 IML : Added C++ style interface. Various optimizations.	   *	
;*   09/06/1994 IML : Ammendments for integration of p_* and ds_* routines.*
;*   09/14/1994 IML : Now handles LCW compression.			   *		
;*=========================================================================*
PROC	Draw_Shape C NEAR 	
	USES eax,ebx,ecx,edx,edi,esi

	;--------------------------------------------------------------------
	; Arguments:
	;--------------------------------------------------------------------
	ARG	gvp_ptr:DWORD		; pointer to graphic viewport info
	ARG	shape_ptr:DWORD		; the shape pointer to draw
	ARG	draw_x:DWORD		; the destination x pixel
	ARG	draw_y:DWORD		; the destination y pixel
	ARG	flags:DWORD		; the flags for drawing the shape

IF FALSE
	;--------------------------------------------------------------------
	; Define the local stack variables that Draw_Shape needs. These 
	; parameters are defined in shape.inc.  They're included here 
	; just for reference.
	;--------------------------------------------------------------------
	;
	;...................... proc addresses ..............................
	;
	LOCAL	LSkipRout:DWORD		; pointer to the skip routine
	LOCAL	RSkipRout:DWORD		; pointer to the skip routine
	LOCAL	DrawRout:DWORD		; pointer to the draw routine
	;
	;.................... optional arguments ............................
	;
	LOCAL	ColorTable:DWORD	; ptr to the shapes color table
	LOCAL	FadingTable:DWORD	; extracted fading table pointer
	LOCAL	FadingNum:DWORD		; get the number of times to fade
	LOCAL	IsTranslucent:DWORD	; ptr to "are we translucent?" tbl
	LOCAL	Translucent:DWORD	; ptr to "ok we are translucent!" tbl
	LOCAL	PriLevel:BYTE		; the priority level of the object
	LOCAL	ScaleX:DWORD		; the x increment to scale by
	LOCAL	ScaleY:DWORD		; the y increment to scale by
	LOCAL	ShadowingTable:DWORD	; ptr to the shadowing table
	;
	;.................... Shape header values ...........................
	;
	LOCAL	ShapeType:DWORD		; shape type
	LOCAL	ShapeWidth:DWORD	; shape's unscaled width
	LOCAL	ShapeHeight:DWORD	; shape's unscaled height
	LOCAL	UncompDataLen:DWORD	; uncompressed data length
	LOCAL	ShapeData:DWORD		; pointer to [compressed] shape data
	;
	;.................. Scaled shape dimensions .........................
	;
	LOCAL	ScaledWidth:DWORD	; shape's scaled width
	LOCAL	ScaledHeight:DWORD	; shape's scaled height
	;
	;.................. Pixel clipping variables ........................
	;
	LOCAL	LeftClipPixels:DWORD	; # left-clipped pixels
	LOCAL	RightClipPixels:DWORD	; # right-clipped pixels
	LOCAL	TopClipPixels:DWORD	; # top-clipped pixels
	LOCAL	BotClipPixels:DWORD	; # bottom-clipped pixels
	LOCAL	PixelWidth:DWORD	; width of drawable area in pixels
	LOCAL	PixelHeight:DWORD	; height of drawable area in pixels
	;
	;..................... Drawing variables ............................
	;
	LOCAL	NumColors:DWORD		; # colors for 16-color shapes
	LOCAL	StartDraw:DWORD		; ptr to starting draw position
	LOCAL	NextLine:DWORD		; offset of next drawing line
	LOCAL	LeftClipBytes:DWORD	; # left-clipped bytes
	LOCAL	XTotal:DWORD		; accumulated x-pixels for scaling
	LOCAL	XTotalInit:DWORD	; initial roundoff bits for XTotal
	LOCAL	YTotal:DWORD		; accumulated y-pixels for scaling
	LOCAL	HeightCount:DWORD	; height counter for drawing lines
	LOCAL	LineStart:DWORD		; address of start of line
	LOCAL	WidthCount:DWORD	; counts down # bytes skipped
	LOCAL	StashReg:DWORD		; temp variable for draw routines
	LOCAL	MaskAdjust:DWORD	; priority buffer offset
	LOCAL	BackAdjust:DWORD	; background buffer offset
	LOCAL	StashECX:DWORD		; temp variable for ECX register
	LOCAL	StashEDX:DWORD		; temp variable for EDX register

ENDIF

	;====================================================================
	; Initialization:
	; - allocate space for globals
	; - validate shape pointer
	; - set SHAPE_COMPACT flag if needed
	;====================================================================
	;--------------------------------------------------------------------
	; Allocate stack space for our local variables.
	;--------------------------------------------------------------------
	LOCAL	Local_Stack:BYTE:Local_Size

	;--------------------------------------------------------------------
	; Make sure the shape pointer is not NULL
	;--------------------------------------------------------------------
	cmp	[shape_ptr],0			; compare shape ptr value to NULL
	jnz	??valid_shp			; if non-zero, it's valid
	jmp	??exit				; otherwise get the heck outta here

	;--------------------------------------------------------------------
	; Move gvp info into local variables
	;--------------------------------------------------------------------
??valid_shp:
	mov	edi,[gvp_ptr]					; get pointer to graphic viewport info
	mov	esi, [(type GVPC_IMAGE  ptr edi). vvpc . Off ] ; extract viewport pointer
	mov	[viewport_ptr],esi
	mov	ebx,[(type GVPC_IMAGE ptr edi) . vvpc . Width ]	; extract viewport width
	mov	[viewport_width],ebx			
	mov	eax,[(type GVPC_IMAGE ptr edi) . vvpc . Height ]	; extract viewport height
	mov	[viewport_height],eax				
	mov	ecx,[(type GVPC_IMAGE ptr edi) . vvpc . Page ]	; calculate y add value
	add	ecx,ebx
	mov	[viewport_yadd],ecx
	mov	eax,[(type GVPC_IMAGE ptr edi) . Xpos ]		; extract viewport x-coord
	mov	[viewport_x],eax
	mov	eax, [(type GVPC_IMAGE ptr edi) . Ypos ]	; extract viewport y-coord
	mov	[viewport_y],eax
	mul	ecx				; calculate buffer pointer
	add	eax,[viewport_x]
	sub	esi,eax
	mov	[buff_ptr],esi


	;--------------------------------------------------------------------
	; If this shape is a compact shape, set that bit in the flags arg
	;--------------------------------------------------------------------
	mov	edi,[shape_ptr]			; check for compact shape flag
	test	[BYTE PTR edi],MAKESHAPE_COMPACT	 
							
	jz	??do_args			; if not process flags as is
	or	[flags],SHAPE_COMPACT		; mark it as a compact shape

	;====================================================================
	; Pull off optional arguments:
	; EDI is used as an offset from the 'flags' parameter, to point
	; to the optional argument currently being processed.
	;====================================================================
??do_args:
	mov	edi,4	 			; optional params start past flags

	;--------------------------------------------------------------------
	; Initialize optional argument values:
	;--------------------------------------------------------------------
	mov	[ColorTable],0			; default = NULL
	mov	[FadingTable],0			; default = NULL
	mov	[FadingNum],0			; default = no fading
	mov	[IsTranslucent],0		; default = NULL
	mov	[Translucent],0			; default = NULL
	mov	[PriLevel],0			; default = no priority
	mov	[ScaleX],100h			; default = unity X scaling
	mov	[ScaleY],100h			; default = unity Y scaling
	mov	[ShadowingTable],0		; default = NULL

	;--------------------------------------------------------------------
	; SHAPE_COLOR: DWORD color_table[256]
	;--------------------------------------------------------------------
??color:
	test	[flags],SHAPE_COLOR 		; does it have a color table
	jz	??fading 			; if not skip to fading 
	or	[flags],SHAPE_COMPACT		; mark it as a compact shape
						;  (for remapping purposes only)
	mov	eax,[flags + edi]
	mov	[ColorTable],eax		; save address of color table
	add	edi,4				; point to next optional argument

	;--------------------------------------------------------------------
	; SHAPE_FADING: DWORD fade_table[256], DWORD fade_count
	;--------------------------------------------------------------------
??fading:
	test	[flags],SHAPE_FADING		; are we fading this shape
	jz	??ghost				; skip to ghosting check
	mov	eax,[flags + edi]
	mov	[FadingTable],eax		; save address of fading tbl

	mov	eax,[flags + edi + 4]		; get fade num

	add	edi,8				; next argument
	cmp	eax,0				; check if it's 0
	jnz	??set_fading			; if not, store fade num
	and	[flags],NOT SHAPE_FADING	; otherwise, don't fade

??set_fading:
	mov	[FadingNum],eax

	;--------------------------------------------------------------------
	; SHAPE_GHOST: DWORD is_translucent tbl, DWORD translucent tbl
	;--------------------------------------------------------------------
??ghost:
	test	[flags],SHAPE_GHOST		; are we ghosting this shape
	jz	??init_predator			; skip to predator check
	mov	eax,[flags + edi]
	mov	[IsTranslucent],eax		; save ptr to is_trans. tbl
	mov	eax,[flags + edi + 4]
	mov	[Translucent],eax		; save ptr to translucent tbl
	add	edi,8				; next argument

	;--------------------------------------------------------------------
	; SHAPE_PREDATOR: Initialize the predator effect variables
	;--------------------------------------------------------------------
??init_predator:
	test	[flags],SHAPE_PREDATOR		; is predator effect on
	jz	??partial			; if not skip to partial 
	inc	[PredCount]			; the pred table is byte aligned
	and	[PredCount],PRED_MASK		; keep entries within bounds
	mov	eax,[PredCount]		 
	mov	al,[BYTE PTR PredTable + eax]
	mov	[PredValue],eax			; put the pred value cs
	mov	[PartialCount],0		; clear the partial count
	mov	[PartialPred],100h		; init partial to off

	;--------------------------------------------------------------------
	; SHAPE_PARTIAL: DWORD partial_pred_value (0-255)
	;--------------------------------------------------------------------
??partial:
	test	[flags],SHAPE_PARTIAL		; is this a partial pred?
	jz	??priority			; if not check priority
	mov	eax,[flags + edi]		; pull the partial value
	mov	[PartialPred],eax		; store it off
	add	edi,4				; next argument

	;--------------------------------------------------------------------
	; SHAPE_PRIORITY: DWORD priority_level
	;--------------------------------------------------------------------
??priority:
	test	[flags],SHAPE_PRIORITY		; is this a priority draw
	jz	??scale				; if not skip to scale
	mov	eax,[flags + edi]
	mov	[PriLevel],al			; store priority level
	add	edi,4				; next argument
	mov	eax,[MaskPage]			; calculate priority buffer
	sub	eax,[buff_ptr]			;  offset
	mov	[MaskAdjust],eax
	mov	eax,[BackGroundPage]		; calculate background buffer
	sub	eax,[buff_ptr]			;  offset
	mov	[BackAdjust],eax

	;--------------------------------------------------------------------
	; SHAPE_SCALING: DWORD x_scale, WORD y_scale
	;--------------------------------------------------------------------
??scale:
	test	[flags],SHAPE_SCALING		; are we scaling this shape.
	jz	??shadow			; if not then skip scale y value
	mov	eax,[flags + edi]	
	mov	[ScaleX],eax
	mov	eax,[flags + edi + 4]	
	mov	[ScaleY],eax
	add	edi,8				; next argument

	;--------------------------------------------------------------------
	; SHAPE_SHADOW: DWORD shadow_table[256]
	;--------------------------------------------------------------------
??shadow:
	test	[flags],SHAPE_SHADOW		; are we ghosting this shape
	jz	short ??get_header		; if not then skip
	mov	eax,[flags + edi]
	mov	[ShadowingTable],eax		; save address of shadow table 
	add	edi,4				; next argument


??get_header:	
	;====================================================================
	; Get Shape header values
	;====================================================================
	mov	esi,[shape_ptr]			; prepare to read header
	movzx	eax,[WORD PTR esi]
	mov	[ShapeType],eax			; extract shape type
	movzx	eax,[BYTE PTR esi + 2]
	mov	[ShapeHeight],eax
	movzx	eax,[WORD PTR esi + 3]		; extract shape height
	mov	[ShapeWidth],eax
	movzx	eax,[WORD PTR esi + 8]		; extract uncompressed data length
	mov	[UncompDataLen],eax
	add	esi,10				; reposition index

	;--------------------------------------------------------------------
	; Now get NumColors, ColorTable address, & data pointer:
	; <16-color shape:
	;   shape.Colortable[0] = # colors
	;   shape data is after that many colors
	; 16-color shape:
	;   shape.Colortable[] contains colors
	;   shape data is after those colors
	; default 256-color shape:
	;   shape data starts at shape.Colortable[0]
	; Note: ColorTable is set only if flags & SHAPE_COLOR is 0; otherwise,
	;   the color table was passed in & we already have a pointer to it
	;--------------------------------------------------------------------
	;
	;....................... <16-color shape: ...........................
	;
	test	[ShapeType],MAKESHAPE_VARIABLE
	jz	??check_16
	movzx	eax,[BYTE PTR esi]		; read # colors
	mov	[NumColors],eax			; save # colors
	inc	esi
	test	[flags],SHAPE_COLOR		; don't set ColorTable if
	jnz	??norm_get_data_addr		;  it was passed in
	mov	[ColorTable],esi		; save color table pointer

??norm_get_data_addr:
	add	esi,[NumColors]			; skip past color data
	mov	[ShapeData],esi			; set data address
	jmp	??setup_procs

	;....................... 16-color shape: ............................
??check_16:
	test	[ShapeType],MAKESHAPE_COMPACT
	jz	??256_get_data_addr
	mov	[NumColors],16			; save # colors
	test	[flags],SHAPE_COLOR		; don't set ColorTable if
	jnz	??16_get_data_addr		;  it was passed in
	mov	[ColorTable],esi		; save color table pointer

??16_get_data_addr:
	add	esi,[NumColors]			; skip past color data
	mov	[ShapeData],esi			; set data address
	jmp	??setup_procs
	;
	;....................... 256-color shape: ...........................
	;
??256_get_data_addr:
	mov	[ShapeData],esi			; set data address

	;====================================================================
	; Set up the drawing procedure addresses
	;====================================================================
	;--------------------------------------------------------------------
	; This code uses HORZ_REV, VERT_REV, & SCALING flags as an 
	; offset into the LSkipTable, RSkipTable, and DrawTable.  These
	; flags combined have values from 00h-07h, so each table must have
	; at least 8 entries.
	;--------------------------------------------------------------------
??setup_procs:
	mov	ebx,[flags]		; load flags value
	and	ebx,07h			; clip high bits
	add	ebx,ebx			; mult by 4 to get DWORD offset
	add	ebx,ebx
	mov	eax,[LSkipTable + ebx]	; get table value
	mov	[LSkipRout],eax		; store it in the function pointer
	mov	eax,[RSkipTable + ebx]	; get table value
	mov	[RSkipRout],eax		; store it in the function pointer
	mov	eax,[DrawTable + ebx]	; get table value
	mov	[DrawRout],eax		; store it in the function pointer

??compute_scalevals:
	;====================================================================
	; Now compute scaled width & height.  If the shape scales down to 0 
	; either horizontally or vertically, exit.
	;====================================================================
	test	[flags],SHAPE_SCALING	; skip if no scaling
	jz	??no_scaling
	;
	;........................ scaled width: .............................
	;
	mov	eax,[ShapeWidth]	; get byte width
	mov	ebx,[ScaleX]		; prepare for register mul
	mul	ebx			; EDX:EAX = result
	shrd	eax,edx,8		; EAX = result rounded down
	or	eax,eax
	jz	??exit			; exit if EAX is 0
	mov	[ScaledWidth],eax	; save the scaled width
	;
	;........................ scaled height: ............................
	;
	mov	eax,[ShapeHeight]	; get byte height
	mov	ebx,[ScaleY]		; prepare for register mul
	mul	ebx			; EDX:EAX = result
	shrd	eax,edx,8		; EAX = result rounded down
	or	eax,eax
	jz	??exit			; exit if EAX is 0
	mov	[ScaledHeight],eax	; save the scaled height
	jmp	??handle_centering
	;
	;......................... no scaling: ..............................
	;
??no_scaling:
	mov	eax,[ShapeWidth]
	mov	[ScaledWidth],eax	; pixel width = byte width
	mov	eax,[ShapeHeight]
	mov	[ScaledHeight],eax	; pixel height = byte height

	;====================================================================
	; Allow for SHAPE_CENTER by adjusting the draw_x & draw_y arguments:
	; draw_x -= ScaledWidth / 2
	; draw_y -= ScaledHeight / 2
	;====================================================================
??handle_centering:
	;
	;........................ adjust draw_x .............................
	;
	test	[flags],SHAPE_CENTER	; skip if not centered
	jz	??handle_vp_rel
	mov	eax,[draw_x]		; load in draw_x
	mov	edx,[ScaledWidth]	; load in ScaledWidth
	shr	edx,1			; divide it by 2
	sub	eax,edx			; subract it from eax
	mov	[draw_x],eax		; store it back into draw_x
	;
	;........................ adjust draw_y .............................
	;
	mov	eax,[draw_y]		; load in draw_y
	mov	edx,[ScaledHeight]	; load in ScaledHeight
	shr	edx,1			; divide it by 2
	sub	eax,edx			; subract it from eax
	mov	[draw_y],eax		; store it back into draw_y

	;====================================================================
	; Allow for SHAPE_VIEWPORT_REL by adjusting draw_x & draw_y by the 
	; viewport's coordinates
	;====================================================================
??handle_vp_rel:
	test	[flags],SHAPE_VIEWPORT_REL	; skip if not vp-relative
	jz	??compute_horz_clip
	mov	eax,[viewport_x]
	add	[draw_x],eax			; draw_x += viewport_x
	mov	eax,[viewport_y]
	add	[draw_y],eax			; draw_y += viewport_y

	;====================================================================
	; Now that we have the scaled size and adjusted x & y drawing
	; coordinates, we can compute the clipped areas of the shape:
	;   LeftClipPixels =	viewport_x - draw_x
	;	- if negative, set to 0
	;   RightClipPixels =	(draw_x + ScaledWidth) - 
	;				(viewport_x + viewport_width)
	;	- if negative, set to 0
	;
	;   TopClipPixels =	viewport_y - draw_y
	;	- if negative, set to 0
	;   BotClipPixels =	(draw_y + ScaledHeight) -
	;				(viewport_y + viewport_height)
	;	- if negative, set to 0
	;====================================================================
??compute_horz_clip:
	;
	;...................... left-clipped pixels .........................
	;
	mov	eax,[viewport_x]
	sub	eax,[draw_x]		; EAX = viewport_x - draw_x
	jge	??set_left_clip
	mov	eax,0			; if EAX<0, set to 0
??set_left_clip:
	mov	[LeftClipPixels],eax	; store # left-clipped pixels
	;
	;...................... right-clipped pixels ........................
	;
	mov	eax,[draw_x]
	add	eax,[ScaledWidth]	; EAX = draw_x + ScaledWidth
	mov	edx,[viewport_x]
	add	edx,[viewport_width]	; EDX = viewport_x + viewport_width
	sub	eax,edx
	jge	??set_right_clip
	mov	eax,0			; if EAX<0, set to 0
??set_right_clip:
	mov	[RightClipPixels],eax	; store # right-clipped pixels
	;
	;...................... top-clipped pixels ..........................
	;
??compute_vert_clip:
	mov	eax,[viewport_y]
	sub	eax,[draw_y]		; EAX = viewport_y - draw_y
	jge	??set_top_clip
	mov	eax,0			; if EAX<0, set to 0
??set_top_clip:
	mov	[TopClipPixels],eax	; store # top-clipped pixels
	;
	;.................... bottom-clipped pixels .........................
	;
	mov	eax,[draw_y]
	add	eax,[ScaledHeight]	; EAX = draw_y + ScaledHeight
	mov	edx,[viewport_y]
	add	edx,[viewport_height]	; EDX = viewport_y + viewport_height
	sub	eax,edx
	jge	??set_bottom_clip
	mov	eax,0			; if EAX<0, set to 0
??set_bottom_clip:
	mov	[BotClipPixels],eax	; store # bottom-clipped pixels

	;====================================================================
	; Now compute the number of pixels actually drawn, horizontally and
	; vertically; exit if either is <= 0
	;====================================================================
??compute_drawn_pixels:
	;
	;.................... pixel width of drawn area .....................
	;
	mov	eax,[ScaledWidth]	; get total width in pixels
	sub	eax,[LeftClipPixels]	; subtract off left-clipped pixels
	sub	eax,[RightClipPixels]	; subtract off right-clipped pixels
	jle	??exit			; exit if no horizontal pixels drawn
	mov	[PixelWidth],eax	; store drawn pixel width
	;
	;.................... pixel height of drawn area ....................
	;
	mov	eax,[ScaledHeight]	; get total height in pixels
	sub	eax,[TopClipPixels]	; subtract off top-clipped pixels
	sub	eax,[BotClipPixels]	; subtract off bottom-clipped pixels
	jle	??exit			; exit if no horizontal pixels drawn
	mov	[PixelHeight],eax	; store drawn pixel height

	;====================================================================
	; So, we're actually going to draw something; if (ShapeType & 
	; MAKESHAPE_NOCOMP == 0) decompress the shape data into _ShapeBuffer:
	; LCW_Uncompress(ShapeData, _ShapeBuffer, UncompDataLen);
	;	shape.DataLength
	;	&_ShapeBuffer
	;	&(shape's data)
	; - otherwise the shape data is already uncompressed
	;====================================================================
	test	[ShapeType],MAKESHAPE_NOCOMP
	jnz	??uncompressed

	mov	eax,[UncompDataLen]
	push	eax			; push arg 3
	mov	eax,[_ShapeBuffer]
	push	eax			; push arg 2
	mov	eax,[ShapeData]
	push	eax			; push arg 1
	call	LCW_Uncompress		; call routine
	add	esp,12			; restore stack
	mov	eax,[_ShapeBuffer]
	mov	[ShapeData],eax
	jmp	??copy_flags

??uncompressed:
;	mov	eax,[ShapeData]		; set up pointer to shape data
;	mov	[_ShapeBuffer],eax


	;--------------------------------------------------------------------
	; Set the global Flags variable
	;--------------------------------------------------------------------
??copy_flags:
	mov	eax,[flags]
	mov	[Flags],eax		

	;====================================================================
	; Now compute the actual buffer offset where drawing (not skipping)
	; will begin
	;====================================================================
	;--------------------------------------------------------------------
	; First, compute the x & y offsets of the shape's clipped upper-left 
	; corner,  relative to the viewport's upper-left corner:
	; x-offset = draw_x + LeftClipPixels - viewport_x
	; y-offset = draw_y + TopClipPixels - viewport_y
	;--------------------------------------------------------------------
	mov	ebx,[draw_x]
	add	ebx,[LeftClipPixels]
	sub	ebx,[viewport_x]	; EBX = viewport x-offset

	mov	eax,[draw_y]
	add	eax,[TopClipPixels]
	sub	eax,[viewport_y]	; EAX = viewport y-offset

	;--------------------------------------------------------------------
	; Then, adjust the viewport offsets due to horizontal & vertical
	; reversal:
	; if HORZ_REV, x-offset += (PixelWidth - 1)
	; if VERT_REV, y-offset += (PixelHeight - 1)
	;--------------------------------------------------------------------
	;
	;................. Adjust for horizontal reversal ...................
	;
	test	[flags],SHAPE_HORZ_REV
	jz	??adjust_vert_offset
	add	ebx,[PixelWidth]
	dec	ebx			; EBX = true x-offset
	;
	;................ Swap LeftClip & RightClip pixels ..................
	;
	mov	edx,[LeftClipPixels]	; exchange left & right-clipped pixels
	xchg	edx,[RightClipPixels]
	mov	[LeftClipPixels],edx

	;
	;.................. Adjust for vertical reversal ....................
	;
??adjust_vert_offset:
	test	[flags],SHAPE_VERT_REV
	jz	??adjust_pointer
	add	eax,[PixelHeight]
	dec	eax			; EAX = true y-offset
	;
	;.................. Swap TopClip & BotClip pixels ...................
	;
	mov	edx,[TopClipPixels]
	xchg	edx,[BotClipPixels]
	mov	[TopClipPixels],edx

	;--------------------------------------------------------------------
	; Now, adjust the starting position pointer:
	;--------------------------------------------------------------------
??adjust_pointer:	;!!!!!!! convert to register mul for speed !!!!!!!!
	add	ebx,[viewport_ptr]	; add initial ptr to x-offset
	mul	[viewport_yadd]		; convert y-offset (EAX) to bytes
	add	ebx,eax			; add those bytes in
	mov	[StartDraw],ebx		; store the starting pointer

	;--------------------------------------------------------------------
	; Finally, if VERT_REV, negate yadd to move up not down:
	;--------------------------------------------------------------------
	test	[flags],SHAPE_VERT_REV
	jz	??init_xtotal
	neg	[viewport_yadd]		; move up, not down

	;====================================================================
	; Initialize the horizontal scale accumulation value:
	;   If there are any left-clipped pixels, the scale accumulator will
	;   have to be initialized with the value it >would< have by stepping
	;   over that many pixels.  This initial value can be computed by
	;   dividing the # of left-clipped pixels by the x-scale value itself,
	;   picking off the remainder from this division & negating it.  This
	;   sets the low byte of the remainder to the correct accumulation
	;   value (the high bytes will be garbage).
	;   (The alternative to this approach would be to multiply the
	;   scale factor by the # clipped bytes, which is the result of the
	;   division; however, negating the remainder is much faster than
	;   the multiply would be.)
	;====================================================================
??init_xtotal:
	mov	edx,0			; prepare for divide
	mov	eax,[LeftClipPixels]	; get # left-clipped pixels
	shl	eax,8			; multiply by 100h
	mov	ebx,[ScaleX]		; load ScaleX value
	div	bx			; 16-bit div: AX = rslt, DX = rem
	mov	[LeftClipBytes],eax	; save # left-clipped bytes
	neg	edx			; generate roundoff bits
	and	edx,0Fh			; only save low byte
	mov	[XTotalInit],edx	; save initial roundoff value

	;====================================================================
	; Initialize drawing variables:
	;====================================================================
	mov	esi,[ShapeData]		; ESI = shape buffer starting point
	mov	edi,[StartDraw]		; EDI = drawing address
	mov	[YTotal],0		; initialize accumulated scale

	;====================================================================
	; Clip the top-clipped lines. The object here is to set ESI to the 
	; first drawable line in the _ShapeBuffer, and YTotal to: 
	;   high byte = # times to draw that line, 
	;   low byte = roundoff bits
	;
	; - Initialize values (ESI, HeightCount, YTotal)
	; - Skip loop if no top lines to clip
	; - Loop:
	;   - save this line's byte position in _ShapeBuffer, in case we
	;     overrun
	;   - call RSkipRout with ECX set to # bytes to skip (one row)
	;   - accumulate ScaleY into YTotal
	;   - if high byte is non-zero, there are that many drawn lines:
	;     - decrement HeightCount by that many lines
	;     - clear the high byte in YTotal, but keep the roundoff bits
	;     - if HeightCount > 0, loop again to clip more lines
	;     - if HeightCount is 0, start drawing:
	;	- ESI points to first non-clipped line in _ShapeBuffer
	;	- YTotal contains 0 in high byte, roundoff bits in low byte
	;     - otherwise, we've clipped too many lines:
	;	- put ESI back to the line we just clipped
	;	- set high byte of YTotal to # lines overrun
	;	- subtract ScaleY from YTotal, to set it up for drawing loop
	;====================================================================
	;
	;..................... skip if nothing to clip ......................
	;
	mov	eax,[TopClipPixels]
	cmp	eax,0			; see if any top-clipped pixels
	jz	??draw_loop		; if not, skip this
	mov	[HeightCount],eax	; save off # lines to clip

??clip_y_loop:
	;
	;...................... skip this row of bytes ......................
	;
	mov	[LineStart],esi		; save this line's byte position
	mov	ecx,[ShapeWidth]	; set up ECX for RSkipRout
	call	[RSkipRout]		; skip 'ShapeWidth' bytes
	;
	;............... see if this row would have been drawn ..............
	;
	mov	eax,[ScaleY]
	add	[YTotal],eax		; accumulate scale factor
	test	[YTotal],0FF00h		; check to see if we draw the line
	jz	??clip_y_loop		; if not loop again
	;
	;...................... decrement HeightCount .......................
	;
	mov	eax,0			; clear EAX
	xchg	al,[BYTE PTR YTotal+1]	; get # lines, clear it in YTotal
	sub	[HeightCount],eax	; subtract # drawn lines from HtCt
	jg	??clip_y_loop		; if more lines remain, loop again
	jns	??draw_loop		; is exactly 0; we're done clipping
	;
	;....................... adjust for overrun .........................
	;
	mov	esi,[LineStart]		; point ESI back to this line
	mov	eax,[HeightCount]
	neg	eax			; EAX = # lines overrun
	shl	eax,8			; multiply by 100h
	add	eax,[YTotal]		; add in roundoff bits
	sub	eax,[ScaleY]		; adjust down by y-scale
	mov	[YTotal],eax		; store in YTotal

	;====================================================================
	; The drawing loop (at long last!):
	; - Accumulate YTotal; if high byte is 0, skip this row of bytes & 
	;   loop again
	; - Skip left-clipped pixels:
	;   - If we've skipped all the bytes on the line, just go to the
	;     next line
	; - Draw middle pixels:
	;   - Add the shape's pixel width to ECX (which could be negative 
	;     if we left-skipped into the drawable area)
	;   - If ECX is still 0, there are no pixels to draw
	;   - Otherwise, leave ECX as is & draw the pixels
	; - Skip right-clipped pixels:
	;   - Add # right-clipped pixels to ECX (which could be negative if
	;     the draw routine  uncompressed 0's into the right-clipped 
	;     region)
	;   - if ECX > 0, skip the remaining bytes
	; - Go to the next line:
	;   - point EDI to the start of the next line in the viewport
	;   - decrement the height counter, exit if it's 0
	;   - decrement YTotal's high byte
	;     - if it's 0, go to the loop top
	;     - otherwise, reset ESI to this line's start & redraw the line,
	;       starting at left-clipped pixels
	;       (NOTE: why not start drawing at middle pixels??????????)
	;====================================================================
??draw_loop:
	;
	;................... accumulate YTotal & test it ....................
	;
	mov	eax,[ScaleY]		; get y scaling factor
	add	[YTotal],eax		; accumulate YTotal
	test	[YTotal],0FF00h		; see if we need to draw anything
	jnz  	??draw_line		; draw this line
	;
	;......................... skip this line ...........................
	;
	mov	ecx,[ShapeWidth]	; load shape's width in bytes
	call	[RSkipRout]		; skip this row & loop again
	jmp	??draw_loop

	;
	;--------------------- start drawing this line ----------------------
	;
??draw_line:
	mov	[LineStart],esi		; save current byte position
	;....................................................................
	; Skip left-clipped pixels:
	; - initialize [WidthCount] to total shape width in bytes
	; - set ECX to # >bytes< to clip
	; When LSkipRout returns: 
	;	- ECX will contain # >pixels< overrun
	;	- EDX will contain the XTotal init value
	;	- [WidthCount] will be decremented by total bytes skipped
	;....................................................................
??draw_left:
	mov	eax,[ShapeWidth]	; load shape width
	mov	[WidthCount],eax	; set up for LSkipRout
	mov	ecx,[LeftClipBytes]	; bytes, not pixels!
	call	[LSkipRout]		; skip the bytes
	cmp	[WidthCount],0
	jz	??next_line		; The whole line was 0's
	;....................................................................
	; Draw middle pixels:
	; - add PixelWidth to ECX (which may be negative)
	; - if ECX is 0, don't bother drawing
	; When DrawRout returns:
	;	- ECX will contain # >pixels< overrun
	;	- [WidthCount] will be decremented by # bytes drawn
	;....................................................................
??draw_middle:
	add	ecx,[PixelWidth]	; since ECX could overrun, add width
	jle	??draw_right		; if ECX<=0, no middle pixels to draw
	call	[DrawRout]		; draw the pixels
	;
	;................... skip past right-clipped pixels .................
	;
??draw_right:
	mov	ecx,[WidthCount]	; ECX = remaining # bytes
	jecxz	??next_line		; don't bother if no bytes remain
	call	[RSkipRout]		; skip right-clipped bytes
	;
	;----------------------- go to the next line ------------------------
	;
??next_line:
	;
	;................. adjust EDI to start of next line .................
	;
	mov	eax,[viewport_yadd]	; get yadd
	add	[StartDraw],eax		; add it to this line's position
	mov	edi,[StartDraw]		; EDI = next line
	;
	;................. decrement our pixel row counter ..................
	;
	dec	[PixelHeight]		; count down a line
	jz	??exit			; we're done!
	;
	;.................. decrement YTotal's high byte ....................
	;
	dec	[BYTE PTR YTotal + 1]	; decrement high byte
	jz	??draw_loop		; draw next line if 0
	;
	;....................... re-draw this line ..........................
	;
	mov	esi,[LineStart]		; reset to this line's start
	jmp	??draw_left		; redraw this line

??exit:
	ret

	ENDP	Draw_Shape


;***************************************************************************
;* Not_Supported -- Replacement function for Draw_Shape routines not used. *
;*                                                                         *
;* INPUT:                                                                  *
;*	none.								   *
;*                                                                         *
;* OUTPUT:                                                                 *
;*	none.								   *
;*                                                                         *
;* WARNINGS:                                                               *
;*	none.								   *
;*                                                                         *
;* HISTORY:                                                                *
;*   08/24/1993 SKB : Created.                                             *
;*=========================================================================*
PROC	Not_Supported NOLANGUAGE NEAR

	ret

	ENDP Not_Supported 

	END

;************************** End of drawshp.asm *****************************


