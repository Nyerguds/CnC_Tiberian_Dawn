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


		.model	large
		option	segment:USE16
		option	readonly
		option	oldstructs


		assume	ds:@data
		assume	es:nothing


RECEIVE_BUFFER_LENGTH	=1024
MAX_RECEIVE_BUFFERS	=32


externdef GLOBALDOSALLOC:far
externdef GLOBALDOSFREE:far


		.data

IPXCallOffset	dw	0
IPXCallSegment	dw	0
RealSegment	dw	0
PseudoES	dw	0



RegisterDump	db	32h dup (0)

MyNetworkNumber	db	4 dup (?)
MyNodeAddress	db	6 dup (?)
MySocket	dw	?

ReceiveBufferSegment	dw	?
ReceiveBufferSelector	dw	?
ReceiveECBOffset	dw	?
CurrentReceiveBuffer	dw	?
LastPassedReceiveBuffer	dw	?
RealModeCallbackSegment	dw	?
RealModeCallbackOffset	dw	?

CallbackRegisterDump	db	32h dup (0)

Listening		db	?
NoReenter		db	0
IPXHold			db	0



OFFS		=0
SEGM		=2


;---------------------------------------------------------------------------
;These defines are for the IPX functions.  The function number is specified
;by placing it in BX when IPX is called.  There are two ways to invoke IPX:
;use interrupt 0x7a, or use a function whose address is obtained by calling
;interrupt 0x2f with AX=0x7a00; the function address is returned in ES:DI.
;This is the preferred method, since other apps are known to use int 0x7a.
;---------------------------------------------------------------------------
IPX_OPEN_SOCKET			= 0000h
IPX_CLOSE_SOCKET		= 0001h
IPX_GET_LOCAL_TARGET		= 0002h
IPX_SEND_PACKET			= 0003h
IPX_LISTEN_FOR_PACKET		= 0004h
IPX_SCHEDULE_EVENT		= 0005h
IPX_CANCEL_EVENT		= 0006h
IPX_GET_INTERVAL_MARKER		= 0008h
IPX_GET_INTERNETWORK_ADDRESS	= 0009h
IPX_RELINQUISH_CONTROL		= 000Ah
IPX_DISCONNECT_FROM_TARGET	= 000Bh

;/*---------------------------------------------------------------------------
;These defines are for various IPX error codes:
;---------------------------------------------------------------------------*/
IPXERR_CONNECTION_SEVERED	= 00ech
IPXERR_CONNECTION_FAILED	= 00edh
IPXERR_NO_CONNECTION		= 00eeh
IPXERR_CONNECTION_TABLE_FULL	= 00efh
IPXERR_NO_CANCEL_ECB		= 00f9h
IPXERR_NO_PATH			= 00fah
IPXERR_ECB_INACTIVE		= 00fch
IPXERR_INVALID_PACKET_LENGTH	= 00fdh
IPXERR_SOCKET_TABLE_FULL	= 00feh
IPXERR_SOCKET_ERROR		= 00ffh

;/*---------------------------------------------------------------------------
;These defines are for various interrupt vectors and DPMI functions:
;---------------------------------------------------------------------------*/
IPX_INT			= 007ah
DPMI_INT		= 0031h
DPMI_ALLOC_DOS_MEM	= 0100h
DPMI_FREE_DOS_MEM	= 0101h
DPMI_CALL_REAL_INT	= 0300h
DPMI_CALL_REAL_PROC	= 0301h
DPMI_ALLOCATE_CALLBACK	= 0303h
DPMI_RELEASE_CALLBACK	= 0304h
DPMI_LOCK_MEM		= 0600h
DPMI_UNLOCK_MEM		= 0601h





request_buffer	struct
		len			word	?
		buffer_type		byte	?
		connect_number		byte	?
request_buffer	ends



request_local_target_buffer struct
		lt_network_number	db	?,?,?,?
		lt_physical_node	db	?,?,?,?,?,?
		lt_socket		dw	?
request_local_target_buffer ends


local_target_reply_buffer struct
		lt_local_target		db	?,?,?,?,?,?
local_target_reply_buffer ends



reply_buffer	struct
		lem			word	?
		network_number		byte	?,?,?,?
		physical_node		byte	?,?,?,?,?,?
		server_socket		word	?
reply_buffer	ends





userid_buffer 	struct
		struct_len		word	?
		object_id	byte	?,?,?,?
		object_type	byte	?,?
		object_name	byte	48 dup(?)
		login_time	byte	7 dup (?)
		reserved	word	?
userid_buffer	ends

		.code

		.386

		include <pcmacro.16>

externdef	pascal _IPX_Initiialise:far16
externdef	pascal _IPX_Uninitialise:far16


_IPX_Initialise	proc far pascal

		push	ebx
		push	ecx
		push	edx
		push	esi
		push	edi
		push	ebp
		push	ds
		push	es
		push	fs
		push	gs

		mov	ax,7a00h
		int	2fh
		and	eax,0ffh
		cmp	al,-1
		setz	al

		test	al,al
		jz	@f

		mov	bx,@data
		mov	ds,bx
		mov	[IPXCallSegment],es
		mov	[IPXCallOffset],di

@@:		pop	gs
		pop	fs
		pop	es
		pop	ds
		pop	ebp
		pop	edi
		pop	esi
		pop	edx
		pop	ecx
		pop	ebx
		ret

_IPX_Initialise	endp



_IPX_Open_Socket95 proc far pascal uses bx cx dx si di ds es fs gs,
		socket:word

		mov	bx,@data
		mov	ds,bx
		mov	bx,IPX_OPEN_SOCKET	;open socket
		mov_w	dx,[socket]		;socket number
		mov_w	[MySocket],dx		;save it for later
		mov	ax,0ffh			;long lived

		call	Call_IPX

		ret

_IPX_Open_Socket95 endp




_IPX_Close_Socket95 proc far pascal uses ax bx cx dx si di ds es fs gs,
		socket:word

		mov	bx,1
		mov_w	dx,[socket]

		call	Call_IPX

		ret

_IPX_Close_Socket95 endp





_IPX_Uninitialise proc far pascal

		int	3
		ret

_IPX_Uninitialise endp





_IPX_Get_Connection_Number95 proc far pascal uses bx cx dx si di ds es fs gs

		mov	ax,0dc00h
		call	Call_DOS
		and	eax,255
		ret

_IPX_Get_Connection_Number95 endp






_IPX_Get_Internet_Address95 proc far pascal uses bx cx dx si di ds es fs gs,
		connection_number	:dword,
		network_number_off	:word,
		network_number_seg	:word,
		physical_node_off	:word,
		physical_node_seg	:word

		local	selector:word
		local	segmento:word

		ret
ifdef cuts ;(unfinished)
		;
		; Allocate DOS memory for buffers passed to interrupt
		;
		int	3
		xor	ax,ax
		mov	bx,(sizeof reply_buffer + sizeof request_buffer + 15)
		save	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp
		test	ax,ax
		jz	@@dpmi_error

		mov	[segmento],dx
		mov	[selector],ax
		mov	fs,dx
		xor	di,di

		mov_w	fs:[di.len],2
		mov_b	fs:[di.buffer_type],13h
		mov_b	al,[connection_number]
		mov_b	fs:[di.connect_number],al

		mov	di,sizeof request_buffer
		mov	fs:[di.len],12


		mov	ax,0e300h
		mov	ds,[segmento]
		mov	es,[segmento]
		xor	si,si

		pusha
		call	Call_DOS
		popa

		les	di,dword ptr [network_number_off]
		mov	ds,[selector]
		mov	si,sizeof request_buffer + network_number
		movsd

		les	di,dword ptr [physical_node_off]
		mov	si,sizeof request_buffer + physical_node
		movsd
		movsw

		;
		; Save it here for posterity (or perhaps later use)
		;
		mov	di,offset MyNetworkNumber
		mov	ax,@data
		mov	es,ax
		mov	ds,[selector]
		mov	si,sizeof request_buffer + network_number
		movsd

		mov	di,offset MyNodeAddress
		mov	si,sizeof request_buffer + physical_node
		movsd
		movsw


		;
		; Free the DOS memory
		;
		mov	bx,@data
		mov	ds,bx
		mov	es,bx
		mov	fs,bx
		mov	gs,bx
		mov	bx,[selector]
		push	bx
		call	GLOBALDOSFREE

		xor	ax,ax
		ret

@@dpmi_error:	mov	ax,-1
		ret
endif

_IPX_Get_Internet_Address95 endp






_IPX_Get_User_ID95 proc far pascal uses bx cx dx si di ds es fs gs,
		connection_number:dword,
		user_id_off:word,
		user_id_seg:word

		local	segmento:word
		local	selector:word

		int	3

		cmp	[connection_number],0
		jz	@@return_error

		;
		; Allocate DOS memory for buffers passed to interrupt
		;
		xor	ax,ax
		mov	bx,(sizeof reply_buffer + sizeof request_buffer + 15)
		save	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp
		test	ax,ax
		jz	@@return_error

		mov	[segmento],dx
		mov	[selector],ax
		mov	fs,dx
		xor	di,di
		mov	ax,@data
		mov	ds,ax

		mov_w	fs:[di.len],2
		mov_b	fs:[di.buffer_type],16h
		mov_b	al,[connection_number]
		mov_b	fs:[di.connect_number],al

		mov	di,sizeof request_buffer
		mov	fs:[di.struct_len],sizeof userid_buffer-2

		mov	ax,0e300h
		mov	ds,[segmento]
		mov	es,[segmento]
		xor	si,si

		pusha
		call	Call_DOS
		popa

		les	di,dword ptr [user_id_off]
		mov	ds,[selector]
		mov	si,sizeof request_buffer + object_name
		mov	cx,48/4
		rep	movsd

		;
		; Free the DOS memory
		;
		mov	bx,@data
		mov	ds,bx
		mov	es,bx
		mov	fs,bx
		mov	gs,bx
		mov	bx,[selector]
		push	bx
		call	GLOBALDOSFREE

		xor	ax,ax
		ret

@@return_error:	mov	ax,-1
		ret

_IPX_Get_User_ID95 endp




;---------------------------------------------------------------------------
;This is the IPX Packet structure.  It's followed by the data itself, which
;can be up to 546 bytes long.  Annotation of 'IPX' means IPX will set this
;field; annotation of 'APP' means the application must set the field.
;NOTE: All header fields are ordered high-byte,low-byte.
;---------------------------------------------------------------------------*/
IPXHeaderType	struct

		CheckSum		dw	?		; IPX: Not used; always 0xffff
		IPXLength		dw	?               ; IPX: Total size, incl header & data
		TransportControl	db	?               ; IPX: # bridges message crossed
		PacketType		db	?               ; APP: Set to 4 for IPX (5 for SPX)
		DestNetworkNumber	db	?,?,?,?         ; APP: destination Network Number
		DestNetworkNode		db	?,?,?,?,?,?     ; APP: destination Node Address
		DestNetworkSocket	dw	?               ; APP: destination Socket Number
		SourceNetworkNumber	db	?,?,?,?         ; IPX: source Network Number
		SourceNetworkNode	db	?,?,?,?,?,?     ; IPX: source Node Address
		SourceNetworkSocket	dw	?               ; IPX: source Socket Number

IPXHeaderType	ends




;/*---------------------------------------------------------------------------
;This is the IPX Event Control Block.  It serves as a communications area
;between IPX and the application for a single IPX operation.  You should set
;up a separate ECB for each IPX operation you perform.
;---------------------------------------------------------------------------*/

ECB		struct

		Link_Address		dd	?
		Event_Service_Routine	dd	?		; APP: event handler (NULL=none)
		InUse			db	?               ; IPX: 0 = event complete
		CompletionCode		db	?               ; IPX: event's return code
		SocketNumber		dw	?               ; APP: socket to send data through
		ConnectionID		dw	?               ; returned by Listen (???)
		RestOfWorkspace		dw	?
		DriverWorkspace		db	12 dup (?)
		ImmediateAddress	db	6 dup (?)       ; returned by Get_Local_Target
		PacketCount		dw	?
		PacketAddress0		dd	?
		PacketLength0		dw	?
		PacketAddress1		dd	?
		PacketLength1		dw	?

ECB		ends


SEND_ECB_OFFSET		=0
SEND_HEADER_OFFSET	=(sizeof ECB +3) AND 0fffch
SEND_BUFFER_OFFSET	=(SEND_HEADER_OFFSET + sizeof IPXHeaderType +3) AND 0fffch


_IPX_Send_Packet95 proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		send_address	:far ptr byte,
		send_buffer	:far ptr byte,
		send_buffer_len	:word

		local	selector	:word
		local	segmento	:word
		local	dos_send_ecb	:far ptr ECB
		local	dos_send_header	:far ptr IPXHeaderType
		local	dos_send_buffer	:far ptr byte
		local	completion_code	:word

		int	3
		;
		; Allocate required DOS memory
		;
		xor	ax,ax
		mov	bx,(sizeof ECB + sizeof IPXHeaderType + 1024 +31)
		save	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp
		test	ax,ax
		jz	@@error
		mov	[segmento],dx
		mov	[selector],ax

		;
		; Set up the pointers to the dos memory
		;
		mov_w	[dos_send_ecb+OFFS],SEND_ECB_OFFSET
		mov_w	[dos_send_ecb+SEGM],ax
		mov_w	[dos_send_header+OFFS],SEND_HEADER_OFFSET
		mov_w	[dos_send_header+SEGM],ax
		mov_w	[dos_send_buffer+OFFS],SEND_BUFFER_OFFSET
		mov_w	[dos_send_buffer+SEGM],ax

		;
		; Clear out the send ECB
		;
		xor	al,al
		mov	cx,sizeof ECB
		les	di,[dos_send_ecb]
		rep	stosb

		;
		; Clear out the send header
		;
		mov	cx,sizeof IPXHeaderType
		les	di,[dos_send_header]
		rep	stosb

		;
		; Copy the data to be sent into the send buffer
		;
		mov	cx,546
		cmp_w	cx,[send_buffer_len]
		jle	@@got_buffer_len
		mov_w	cx,[send_buffer_len]
@@got_buffer_len:
		mov_w	[send_buffer_len],546	;always send same size packets (nice and big for Kali hehe)
		les	di,[dos_send_buffer]
		lds	si,[send_buffer]
		rep	movsb

		;
		; Fill in the ECB
		;
		mov	ax,@data
		mov	ds,ax
		mov	fs,ax			;keep ptr to data seg in fs
		les	di,[dos_send_ecb]

		assume	ds:@data
		assume	fs:@data

		mov	ax,[MySocket]
		mov	es:[di.SocketNumber],ax
		mov	es:[di.PacketCount],2
		mov	ax,[segmento]
		shl	eax,16
		mov_w	ax,[dos_send_header+OFFS]
		mov_d	es:[di.PacketAddress0],eax
		mov_w	es:[di.PacketLength0],sizeof IPXHeaderType
		mov_w	ax,[dos_send_buffer+OFFS]
		mov_d	es:[di.PacketAddress1],eax
		mov_w	ax,[send_buffer_len]
		mov_w	es:[di.PacketLength1],ax

		;assume	ds:nothing
		;
		; Fill in the address field
		;
		lds	si,[send_address]
		mov	eax,[si]
		mov_d	es:[di.ImmediateAddress],eax
		mov	ax,[si+4]
		mov_w	es:[di.ImmediateAddress+4],ax

		;
		; Fill in the outgoing header
		;
		les	di,[dos_send_header]
		mov	es:[di.PacketType],4
		push	fs:[MySocket]
		pop	es:[di.DestNetworkSocket]

		;
		; Fill in the nwtowrk number and node address
		;
		mov_d	eax,fs:[MyNetworkNumber]
		mov_d	es:[di.DestNetworkNumber],eax
		mov_d	eax,fs:[MyNodeAddress]
		mov_d	es:[di.DestNetworkNode],eax
		mov_w	ax,fs:[MyNodeAddress+4]
		mov_w	es:[di.DestNetworkNode+4],ax

		;
		; Send that sucker!
		;
		mov	si,[segmento]
		mov	fs:[PseudoES],si
		mov	si,SEND_ECB_OFFSET
		mov	bx,IPX_SEND_PACKET
		pusha
		push	fs
		call	Call_IPX
		pop	fs
		popa
		mov	fs:[PseudoES],0


		assume	fs:nothing
		;
		; Wait for the send to finish
		;
@@wait_send_loop:
		lds	si,[dos_send_ecb]
		cmp	[si.InUse],0
		jz	@@done

		mov	bx,IPX_RELINQUISH_CONTROL
		save	bp
		call	Call_IPX
		restore	bp
		jmp	@@wait_send_loop


		;
		; Get the completion code
		;
@@done:		lds	si,[dos_send_ecb]
		mov	al,[si.CompletionCode]
		xor	ah,ah
		mov	[completion_code],ax

		;
		; Free the DOS memory
		;
		mov	bx,@data
		mov	ds,bx
		mov	es,bx
		mov	fs,bx
		mov	gs,bx
		mov	bx,[selector]
		save	bp
		push	bx
		call	GLOBALDOSFREE
		restore	bp

		cmp	[completion_code],0
		jz	@@error

@@success:	mov	ax,1
		ret


@@error:	xor	ax,ax
		ret


_IPX_Send_Packet95 endp






_IPX_Broadcast_Packet95 proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		send_buffer	:far ptr byte,
		send_buffer_len	:word

		local	selector	:word
		local	segmento	:word
		local	dos_send_ecb	:far ptr ECB
		local	dos_send_header	:far ptr IPXHeaderType
		local	dos_send_buffer	:far ptr byte
		local	completion_code	:word

		int	3
		;
		; Allocate required DOS memory
		;
		xor	ax,ax
		mov	bx,(sizeof ECB + sizeof IPXHeaderType + 1024 +31)
		save	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp
		test	ax,ax
		jz	@@error
		mov	[segmento],dx
		mov	[selector],ax

		;
		; Set up the pointers to the dos memory
		;
		mov_w	[dos_send_ecb+OFFS],SEND_ECB_OFFSET
		mov_w	[dos_send_ecb+SEGM],ax
		mov_w	[dos_send_header+OFFS],SEND_HEADER_OFFSET
		mov_w	[dos_send_header+SEGM],ax
		mov_w	[dos_send_buffer+OFFS],SEND_BUFFER_OFFSET
		mov_w	[dos_send_buffer+SEGM],ax

		;
		; Clear out the send ECB
		;
		xor	al,al
		mov	cx,sizeof ECB
		les	di,[dos_send_ecb]
		rep	stosb

		;
		; Clear out the send header
		;
		mov	cx,sizeof IPXHeaderType
		les	di,[dos_send_header]
		rep	stosb

		;
		; Copy the data to be sent into the send buffer
		;
		mov	cx,546
		cmp_w	cx,[send_buffer_len]
		jle	@@got_buffer_len
		mov_w	cx,[send_buffer_len]
@@got_buffer_len:
		mov_w	[send_buffer_len],546	;always send same size packets (nice and big for Kali hehe)
		les	di,[dos_send_buffer]
		lds	si,[send_buffer]
		rep	movsb

		;
		; Fill in the ECB
		;
		mov	ax,@data
		mov	ds,ax
		mov	fs,ax			;keep ptr to data seg in fs
		les	di,[dos_send_ecb]

		assume	fs:@data
		assume	ds:@data

		mov	ax,[MySocket]
		mov	es:[di.SocketNumber],ax
		mov	es:[di.PacketCount],2
		mov	ax,[segmento]
		shl	eax,16
		mov_w	ax,[dos_send_header+OFFS]
		mov_d	es:[di.PacketAddress0],eax
		mov_w	es:[di.PacketLength0],sizeof IPXHeaderType
		mov_w	ax,[dos_send_buffer+OFFS]
		mov_d	es:[di.PacketAddress1],eax
		mov_w	ax,[send_buffer_len]
		mov_w	es:[di.PacketLength1],ax

		;assume	ds:nothing
		;
		; Fill in the address field
		;
		mov_d	es:[di.ImmediateAddress],0ffffffffh
		mov_w	es:[di.ImmediateAddress+4],0ffffh

		;
		; Fill in the outgoing header
		;
		les	di,[dos_send_header]
		mov	es:[di.PacketType],4
		push	fs:[MySocket]
		pop	es:[di.DestNetworkSocket]

		;
		; Fill in the nwtowrk number and node address
		;
		mov_d	es:[di.DestNetworkNumber],0ffffffffh
		mov_d	es:[di.DestNetworkNode],0ffffffffh
		mov_w	es:[di.DestNetworkNode+4],0ffffh

		;
		; Send that sucker!
		;
		mov	si,[segmento]
		mov	fs:[PseudoES],si
		mov	si,SEND_ECB_OFFSET
		mov	bx,IPX_SEND_PACKET
		pusha
		push	fs
		call	Call_IPX
		pop	fs
		popa
		mov	fs:[PseudoES],0

		assume	fs:nothing
		;
		; Wait for the send to finish
		;
@@wait_send_loop:
		lds	si,[dos_send_ecb]
		cmp	[si.InUse],0
		jz	@@done

		mov	bx,IPX_RELINQUISH_CONTROL
		save	bp
		call	Call_IPX
		restore	bp
		jmp	@@wait_send_loop



		;
		; Get the completion code
		;
@@done:		lds	si,[dos_send_ecb]
		mov	al,[si.CompletionCode]
		xor	ah,ah
		mov	[completion_code],ax

		;
		; Free the DOS memory
		;
		mov	bx,@data
		mov	ds,bx
		mov	es,bx
		mov	fs,bx
		mov	gs,bx
		mov	bx,[selector]
		save	bp
		push	bx
		call	GLOBALDOSFREE
		restore	bp

		cmp	[completion_code],0
		jz	@@error


@@success:	mov	ax,1
		ret


@@error:	xor	ax,ax
		ret


_IPX_Broadcast_Packet95 endp







_IPX_Get_Local_Target95	proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		dest_network	:far ptr byte,
		dest_node	:far ptr byte,
		socket		:word,
		bridge_address	:far ptr byte


		local	segmento	:word
		local	selector	:word
		local	result_code	:word

		int	3
		;
		; Allocate DOS memory for buffers passed to interrupt
		;
		xor	ax,ax
		mov	bx,(sizeof local_target_reply_buffer + \
			    sizeof request_local_target_buffer + 15)
		save	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp
		test	ax,ax
		jz	@@return_error

		mov	[segmento],dx
		mov	[selector],ax
		mov	fs,dx
		xor	di,di

		;
		; Init the request structure
		;
		mov_d	eax,[dest_network]
		mov_d	fs:[di.lt_network_number],eax
		mov_d	eax,[dest_node]
		mov_d	fs:[di.lt_physical_node],eax
		mov_w	ax,[dest_node+4]
		mov_w	fs:[di.lt_physical_node+4],ax
		mov	ax,[socket]
		mov	fs:[di.lt_socket],ax

		mov	bx,IPX_GET_LOCAL_TARGET
		mov	ax,[segmento]
		mov	ds,ax
		xor	si,si
		mov	es,ax
		mov	di,sizeof request_local_target_buffer

		push	bp
		call	Call_IPX
		pop	bp

		mov	[result_code],ax

		mov	ds,[selector]
		mov	si,sizeof request_local_target_buffer + lt_local_target
		les	di,bridge_address
		movsd
		movsw

		;
		; Free the DOS memory
		;
		mov	bx,@data
		mov	ds,bx
		mov	es,bx
		mov	fs,bx
		mov	gs,bx
		mov	bx,[selector]
		save	bp
		push	bx
		call	GLOBALDOSFREE
		restore	bp

		;
		; Return the IPX result code
		;
		mov	ax,[result_code]
		ret

@@return_error:	mov	ax,-1
		ret

_IPX_Get_Local_Target95	endp




_IPX_Get_Outstanding_Buffer95 proc far pascal uses ebx ecx edx esi edi ebp ds es fs gs,
		copy_receive_buffer:far ptr byte

		int	3
		mov	ax,@data
		mov	ds,ax

		xor	ax,ax
		mov	si,[LastPassedReceiveBuffer]
		cmp	si,[CurrentReceiveBuffer]
		jz	@@done

		push	ds
		mov	cx,RECEIVE_BUFFER_LENGTH/4
		mov	ds,[ReceiveBufferSelector]
		les	di,[copy_receive_buffer]
		rep	movsd
		pop	ds

		cmp	si,RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS
		jc	@@no_wrap
		xor	si,si
@@no_wrap:	mov	[LastPassedReceiveBuffer],si

		mov	ax,1

@@done:		ret

_IPX_Get_Outstanding_Buffer95 endp




Receive_Callback proc far

		pushf
		cli
		cld
		pushad
		push	ds
		push	es
		push	fs
		push	gs
		mov	ax,@data
		mov	ds,ax
		cmp	[NoReenter],0
		jnz	@@out
		mov	[NoReenter],1
		mov	ax,[CurrentReceiveBuffer]

		add	ax,RECEIVE_BUFFER_LENGTH
		cmp	ax,RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS
		jc	@@no_wrap
		xor	ax,ax
@@no_wrap:	mov	[CurrentReceiveBuffer],ax

		call	Listen_For_Packet
		mov	ax,@data
		mov	ds,ax
		mov	[NoReenter],0

@@out:		pop	gs
		pop	fs
		pop	es
		pop	ds
		popad
		popf
		ret

Receive_Callback endp





Init_Receive_ECB proc near uses eax ebx ecx edx esi edi ebp ds es

		mov	ax,@data
		mov	ds,ax
		mov	es,[ReceiveBufferSelector]

		;
		; Clear out the ECB
		;
		mov	di,[ReceiveECBOffset]
		mov	cx,sizeof ECB
		xor	al,al
		rep	stosb


;
; Set up the ECB
;
		;
		;General ECB data
		mov	di,[ReceiveECBOffset]
		mov	ax,[MySocket]
		mov	es:[di.SocketNumber],ax
		mov	es:[di.PacketCount],2

		;
		; Packet address for IPX header
		mov	ax,[CurrentReceiveBuffer]
		mov	bx,[ReceiveBufferSegment]
		mov_w	es:[di.PacketAddress0+OFFS],ax
		mov_w	es:[di.PacketAddress0+SEGM],bx
		mov	es:[di.PacketLength0],sizeof IPXHeaderType

		;
		; Packet address for receive buffer
		mov	ax,[CurrentReceiveBuffer]
		add	ax,sizeof IPXHeaderType
		mov_w	es:[di.PacketAddress1+OFFS],ax
		mov_w	es:[di.PacketAddress1+SEGM],bx
		mov	es:[di.PacketLength1],546

		;
		; Set up the callback address
		mov	ax,[RealModeCallbackOffset]
		mov_w	es:[di.Event_Service_Routine+OFFS],ax
		mov	ax,[RealModeCallbackSegment]
		mov_w	es:[di.Event_Service_Routine+SEGM],ax

		ret

Init_Receive_ECB endp


_IPX_Start_Listening95 proc far pascal uses ebx ecx edx esi edi ebp ds es fs gs

		mov	ax,@data
		mov	ds,ax
		cmp	[Listening],0
		jnz	@@restart		;already listening

		;
		; Allocate and lock DOS memory for listen
		;  ECB and receive buffers
		;
		mov	bx,(RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS + sizeof ECB + 15)
		xor	ax,ax
		save	bp,ds
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp,ds
		test	ax,ax
		jz	@@error

		mov	[ReceiveBufferSegment],dx
		mov	[ReceiveBufferSelector],ax

		;
		; Set up pointers to the DOS memory
		;
		mov	[ReceiveECBOffset],RECEIVE_BUFFER_LENGTH * MAX_RECEIVE_BUFFERS
		mov	[CurrentReceiveBuffer],0	;1st receive buffer
		mov	[LastPassedReceiveBuffer],0

		;
		; Set up a real mode callback function
		;
		mov	ax,DPMI_ALLOCATE_CALLBACK
		mov	si,offset Receive_Callback
		mov	di,offset CallbackRegisterDump
		push	cs
		pop	ds
		mov	bx,@data
		mov	es,bx
		save	bp
		int	31h
		restore	bp
		bcs	@@error

		mov	ax,@data
		mov	ds,ax
		mov	[RealModeCallbackSegment],cx
		mov	[RealModeCallbackOffset],dx

@@restart:	save	ds
		call	Listen_For_Packet
		restore	ds
		mov	[Listening],1

@@out:		mov	ax,1
		ret

@@error:	xor	ax,ax
		ret

_IPX_Start_Listening95 endp




_IPX_Shut_Down95 proc far pascal uses eax ebx ecx edx esi edi ebp ds es fs gs

		int	3
		mov	ax,@data
		mov	ds,ax
		cmp	[Listening],0
		jz	@@out

		;
		; Stop listening for a packet
		;
		mov	es,[ReceiveBufferSegment]
		mov	si,[ReceiveECBOffset]
		mov	bx,IPX_CANCEL_EVENT
		save	bp,ds
		call	Call_IPX
		save	bp,ds

		;
		; Remove the real mode callback function
		;
		mov	cx,[RealModeCallbackSegment]
		mov	dx,[RealModeCallbackOffset]
		mov	ax,DPMI_RELEASE_CALLBACK
		save	bp,ds
		int	31h
		restore	bp,ds

		;
		; Free the DOS memory
		;
		mov	ax,@data
		mov	ds,ax
		mov	es,ax
		mov	fs,ax
		mov	gs,ax
		mov	ax,[ReceiveBufferSelector]
		save	bp,ds
		push	ax
		call	GLOBALDOSFREE
		restore	bp,ds

		mov	[Listening],0

@@out:		ret

_IPX_Shut_Down95 endp




Listen_For_Packet proc near uses ebx ecx edx esi edi ebp ds es fs gs

		call	Init_Receive_ECB

		mov	ax,@data
		mov	ds,ax
		mov	si,[ReceiveBufferSegment]
		mov	[PseudoES],si
		mov	si,[ReceiveECBOffset]
		mov	bx,IPX_LISTEN_FOR_PACKET
		save	ds
		call	Call_IPX
		restore	ds
		mov	[PseudoES],0

		ret

Listen_For_Packet endp






Call_IPX	proc far

		push	gs
		push	ax
		mov	ax,@data
		mov	gs,ax
		pop	ax

	       	push	bp
		mov	bp,offset IPXCallOffset
		call	dword ptr gs:[bp]
		pop	bp

		pop	gs
		ret






		push	gs
		push	ax
		mov	ax,@data
		mov	gs,ax
		pop	ax

		;
		; Prevent reenterancy
		;
@@hold:		;cmp	gs:[IPXHold],0
		;jnz	@@hold

		mov	gs:[IPXHold],1

		;
		; Dump the registers first so we can use them
		;
		mov_d	gs:[RegisterDump+0ch],0
		mov_d	gs:[RegisterDump],edi
		mov_d	gs:[RegisterDump+4],esi
		mov_d	gs:[RegisterDump+8],ebp
		mov_d	gs:[RegisterDump+10h],ebx
		mov_d	gs:[RegisterDump+14h],edx
		mov_d	gs:[RegisterDump+18h],ecx
		mov_d	gs:[RegisterDump+1ch],eax

		int	3

		push	gs
		xor	ax,ax
		push	ax
		mov	ax,4096	;4k real mode stack
		push	ax
		call	GLOBALDOSALLOC
		pop	gs
		mov	bx,4094	;stack ptr
		test	ax,ax
		jnz	@f
		xor	bx,bx

		;
		; Set up stack addr to zero - DPMI will supply a real mode stack
		;
@@:		mov_w	gs:[RegisterDump+2eh],bx	;sp
		mov_w	gs:[RegisterDump+30h],dx	;ss
		save	ax	;save selector so we can free the memory later


		;
		; Dump the flags
		;
		pushf
		pop	gs:[word ptr RegisterDump+20h]

		;
		; Set up all segment register areas to point to our real mode segment
		;
		mov_w	gs:[RegisterDump+22h],es
		mov_w	gs:[RegisterDump+24h],ds
		mov_w	gs:[RegisterDump+26h],fs
		mov_w	gs:[RegisterDump+28h],gs

		cmp	gs:[PseudoES],0
		jz	@f
		mov	ax,gs:[PseudoES]
		mov_w	gs:[RegisterDump+22h],ax
@@:


		;
		; Set up the address to call
		;
		mov	ax,gs:[IPXCallSegment]
		mov_w	gs:[RegisterDump+2ch],ax
		mov	ax,gs:[IPXCallOffset]
		mov_w	gs:[RegisterDump+2ah],ax

		mov	ax,DPMI_CALL_REAL_INT	; Call real mode procedure with far return frame
		xor	bh,bh			; flags - should be zero
		mov	bl,07ah			; IPX interrupt
		mov	ecx,0 ;512			; number of words to copy from the protected mode stack
		mov	di,offset RegisterDump
		push	gs
		pop	es
		save	gs
		;push	ss
		;push	sp
		int	31h		;DPMI interrupt

		;pop	ax
		;pop	bx
		;pushf
		;pop	cx
		;cli
		;mov	sp,ax
		;mov	ss,bx
		;add	sp,2
		;push	cx
		;popf

		restore	gs

		mov	ax,@data
		mov	ds,ax
		mov	es,ax
		mov	fs,ax
		mov	gs,ax
		call	GLOBALDOSFREE


		mov_d	eax,gs:[RegisterDump+1ch]
		mov	gs:[IPXHold],0
		pop	gs

		ret


Call_IPX	endp








Call_DOS	proc far

		push	gs
		push	ax
		mov	ax,@data
		mov	gs,ax
		pop	ax
		;
		; Dump the registers first so we can use them
		;
		mov_d	gs:[RegisterDump],edi
		mov_d	gs:[RegisterDump+4],esi
		mov_d	gs:[RegisterDump+8],ebp
		mov_d	gs:[RegisterDump+10h],ebx
		mov_d	gs:[RegisterDump+14h],edx
		mov_d	gs:[RegisterDump+18h],ecx
		mov_d	gs:[RegisterDump+1ch],eax

		;
		; Dump the flags
		;
		pushf
		pop	gs:[word ptr RegisterDump+20h]

		;
		; Set up all segment register areas to point to our real mode segment
		;
		mov_w	gs:[RegisterDump+22h],es
		mov_w	gs:[RegisterDump+24h],ds
		mov_w	gs:[RegisterDump+26h],fs
		mov_w	gs:[RegisterDump+28h],gs

		;
		; Set up stack addr to zero - DPMI will supply a real mode stack
		;
		xor	ax,ax
		mov_w	gs:[RegisterDump+2eh],ax	;sp
		mov_w	gs:[RegisterDump+30h],ax	;ss

		mov	ax,DPMI_CALL_REAL_INT; Simulate real mode interrupt
		xor	bh,bh		; flags - should be zero
		mov	bl,21h		; interrupt number
		mov	ecx,0 ;512		; number of words to copy from the protected mode stack
		mov	di,offset RegisterDump
		push	gs
		pop	es
		save	gs
		int	31h		;DPMI interrupt
		restore	gs

		mov_d	edi,gs:[RegisterDump]
		mov_d	esi,gs:[RegisterDump+4]
		mov_d	ebp,gs:[RegisterDump+8]
		mov_d	ebx,gs:[RegisterDump+10h]
		mov_d	edx,gs:[RegisterDump+14h]
		mov_d	ecx,gs:[RegisterDump+18h]
		mov_d	eax,gs:[RegisterDump+1ch]
		mov_w	es,gs:[RegisterDump+22h]
		mov_w	ds,gs:[RegisterDump+24h]
		pop	gs

		ret


Call_DOS	endp




		end






