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

; This is the control structure at the start of a loaded icon set.  It must match
; the structure in ICONSET.C!  This structure MUST be a multiple of 16 bytes long.

	STRUC	IControl_Type
Width		DW	?	; Width in pixels (per icon).
Height		DW	?	; Height in pixels (per icon).
Count		DW	?	; Number of icons in this set.
Allocated	DW	?	; Was this iconset allocated?
Size		DD	?	; Size of entire iconset memory block.
Icons		DD	?	; Offset from buffer start to icon data.
Palettes	DD	?	; Offset from buffer start to palette data.
Remaps		DD	?	; Offset from buffer start to remap index data.
TransFlag	DD	?	; Offset for transparency flag data.
Map		DD	?	; Icon map offset.
	ENDS

ICON256	EQU	1
