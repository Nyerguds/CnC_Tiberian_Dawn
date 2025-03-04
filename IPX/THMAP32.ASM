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
;*                 Project Name : Command & Conquer                        *
;*                                                                         *
;*                    File Name : THMAP32.ASM                              *
;*                                                                         *
;*                   Programmer : Steve Tall				   *
;*                                                                         *
;*                   Start Date : January 25th, 1996			   *
;*                                                                         *
;*                  Last Update : January 29th, 1996   [ST]                *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Overview:                                                               *
;*  These functions exist simply to map similar function names to each     *
;* other.                                                                  *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;*                                                                         *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


		.386
		OPTION READONLY
		OPTION OLDSTRUCTS

		.model FLAT



		.code





externdef 	_IPX_Initialise:near
externdef 	__IPX_Initialise@0:near
_IPX_Initialise	proc near

		jmp	__IPX_Initialise@0

_IPX_Initialise endp

externdef 	_IPX_Open_Socket95:near
externdef 	__IPX_Open_Socket95@4:near
_IPX_Open_Socket95	proc near

		jmp	__IPX_Open_Socket95@4

_IPX_Open_Socket95 endp

externdef 	_IPX_Close_Socket95:near
externdef 	__IPX_Close_Socket95@4:near
_IPX_Close_Socket95	proc near

		jmp	__IPX_Close_Socket95@4

_IPX_Close_Socket95 endp

externdef 	_IPX_Get_Connection_Number95:near
externdef 	__IPX_Get_Connection_Number95@0:near
_IPX_Get_Connection_Number95	proc near

		jmp	__IPX_Get_Connection_Number95@0

_IPX_Get_Connection_Number95 endp

externdef 	_IPX_Send_Packet95:near
externdef 	__IPX_Send_Packet95@20:near
_IPX_Send_Packet95	proc near

		jmp	__IPX_Send_Packet95@20

_IPX_Send_Packet95 endp

externdef 	_IPX_Broadcast_Packet95:near
externdef 	__IPX_Broadcast_Packet95@8:near
_IPX_Broadcast_Packet95	proc near

		jmp	__IPX_Broadcast_Packet95@8

_IPX_Broadcast_Packet95 endp

externdef 	_IPX_Get_Local_Target95:near
externdef 	__IPX_Get_Local_Target95@16:near
_IPX_Get_Local_Target95	proc near

		jmp	__IPX_Get_Local_Target95@16

_IPX_Get_Local_Target95 endp

externdef 	_IPX_Start_Listening95:near
externdef 	__IPX_Start_Listening95@0:near
_IPX_Start_Listening95	proc near

		jmp	__IPX_Start_Listening95@0

_IPX_Start_Listening95 endp

externdef 	_IPX_Shut_Down95:near
externdef 	__IPX_Shut_Down95@0:near
_IPX_Shut_Down95	proc near

		jmp	__IPX_Shut_Down95@0

_IPX_Shut_Down95 endp



externdef 	_IPX_Get_Outstanding_Buffer95:near
externdef 	__IPX_Get_Outstanding_Buffer95@4:near

_IPX_Get_Outstanding_Buffer95	proc near

		jmp	__IPX_Get_Outstanding_Buffer95@4

_IPX_Get_Outstanding_Buffer95 endp


	end
