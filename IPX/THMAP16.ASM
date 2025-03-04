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




	.8086

	OPTION READONLY
	OPTION OLDSTRUCTS
	OPTION SEGMENT:USE16
	.model LARGE,PASCAL


	.code


externdef	pascal Thipx_ThunkConnect16_:far16
extern		pascal Thipx_ThunkConnect16:near16

Thipx_ThunkConnect16_ 	proc	far16 pascal

		jmp	Thipx_ThunkConnect16

Thipx_ThunkConnect16_	endp



externdef	DllEntryPoint:far16
extern		pascal DllEntryPoint_:far16

DllEntryPoint 	proc	far16

		jmp	DllEntryPoint_

DllEntryPoint	endp




	end




