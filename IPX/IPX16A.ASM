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
;**   C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S  I N C  **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Command & Conquer                        *
;*                                                                         *
;*                    File Name : IPX16a.asm                               *
;*                                                                         *
;*                   Programmer : Steve Tall                               *
;*                                                                         *
;*                   Start Date : January 26th, 1996                       *
;*                                                                         *
;*                  Last Update : January 26th, 1996  [ST]                 *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Overview:                                                               *
;*  16-bit protected mode windows code. This code sits in a 16 bit .DLL    *
;* and provides access to IPX functions via the standard DOS interface.    *
;*                                                                         *
;*  Strangely enough, although you would expect to have to use segment     *
;* addresses when passing data to and from the DOS IPX services, it only   *
;* seems to work with selector addressing. This could be something to do   *
;* with being in a windows .DLL.                                           *
;*                                                                         *
;*  It seems that in Win95, the DOS services are stubbed to just pass up   *
;* to NWLINK which is the win95 32bit netware services layer. If we ever   *
;* have direct access to that then all this code can go away.              *
;*                                                                         *
;*                                                                         *
;*-----------------------------------------------------------------------------------------------*
;* Functions:                                                                                    *
;* _IPX_Initialise -- confirms the presence of IPX and gets the entry point for subsequent calls *
;* _IPX_Open_Socket95 -- opens the given socket number                                           *
;* IPX_Close_Socket95 -- closes the given socket number                                          *
;* _IPX_Get_Connection_Number95 -- get the users local 'connection number'                       *
;* _IPX_Send_Packet95 -- Send a packet via IPX                                                   *
;* _IPX_Broadcast_Packet95 -- Broadcast a packet via IPX                                         *
;* _IPX_Get_Local_Target95 -- Gets the node address of a destination or bridge                   *
;* _IPX_Get_Outstanding_Buffer95 -- return contents of the next unread buffer in the buffer list *
;* Receive_Callback -- IPX callback function. Called when a new packet arrives                   *
;* Init_Receive_ECB -- initialises an ECB for receiving a packet                                 *
;* _IPX_Start_Listening95 -- initialise DOS memory for receive buffers and start listening for   *
;*                           IPX packets                                                         *
;* _IPX_Shut_Down95 -- finish an IPX session. Releases any allocated resources except the socket *
;* Listen_For_Packet -- Start IPX listening for an incoming packet                               *
;* Call_IPX -- Make a call to the IPX entry point                                                *
;* Call_DOS -- use DPMI to call a DOS interrupt service                                          *
;*                                                                                               *
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


		.8086			;cant specify .386 until we are into the code segment


		.model	large
		option	segment:USE16	;16-bit segment
		option	readonly
		option	oldstructs


		assume	ds:@data	;ds is defauly segment register for our data segment
		assume	es:nothing


;#############################################################################
;
; Constants
;
RECEIVE_BUFFER_LENGTH	=1024		;length of each DOS memory receive buffer
MAX_RECEIVE_BUFFERS	=32		;number of receive buffers allocated

OFFS		=0			;offset of OFFSET part of a far ptr
SEGM		=2			;offset of SEGMENT part of a far ptr

SEND_ECB_OFFSET		=0								;offset of SEND ecb
SEND_HEADER_OFFSET	=(sizeof ECB +3) AND 0fffch					;offset of our send header
SEND_BUFFER_OFFSET	=(SEND_HEADER_OFFSET + sizeof IPXHeaderType +3) AND 0fffch	;offset of our send buffer

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



;#############################################################################
;
; Windows API functions
;
externdef GLOBALDOSALLOC:far
externdef GLOBALDOSFREE:far


;#############################################################################
;
; Global initialised data
;
			.data

IPXCallOffset		dw	0
IPXCallSegment		dw	0

RegisterDump		db	32h dup (0)
NoReenter		db	0


;#############################################################################
;
; Global uninitialised data
;
			.data?

MySocket		dw	?
ReceiveBufferSegment	dw	?
ReceiveBufferSelector	dw	?
ReceiveECBOffset	dw	?
CurrentReceiveBuffer	dw	?
LastPassedReceiveBuffer	dw	?

ReceiveDescriptor	db	8 dup (?)
OriginalReceiveDescriptor db	8 dup (?)

Listening		db	?
ListeningFailed		db	?


;#############################################################################
;
; Structures
;

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



;
; Structures used for Get_Local_Target calls
;
request_local_target_buffer struct
		lt_network_number	db	?,?,?,?
		lt_physical_node	db	?,?,?,?,?,?
		lt_socket		dw	?
request_local_target_buffer ends


local_target_reply_buffer struct
		lt_local_target		db	?,?,?,?,?,?
local_target_reply_buffer ends






;#############################################################################
;
; Start of code segment
;
;
		.code

		.386			;now we can specify 386 instructions. Its still a 16 bit code segment though.

		include <pcmacro.16>	;include 16 bit instruction macros



;*************************************************************************************************
;* _IPX_Initialise -- confirms the presence of IPX and gets the entry point for subsequent calls *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	eax - nothing                                                                    *
;*                                                                                               *
;* OUTPUT:      true if IPX was initialised                                                      *
;*                                                                                               *
;* 32bit PROTO:	extern BOOL __stdcall IPX_Initialise(void);                                      *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

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

		; Call the multiplex interrupt to confirm the presence of IPX
		; The real mode entry point is returned in es:di if present
		;
		mov	ax,7a00h
		int	2fh
		and	eax,0ffh
		cmp	al,-1
		setz	al

		test	al,al
		jz	@f

		; Save the real mode entry point
		;
		mov	bx,@data
		mov	ds,bx
		mov	[IPXCallSegment],es
		mov	[IPXCallOffset],di
		mov	[Listening],0
		mov	[ListeningFailed],0

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



;*************************************************************************************************
;* _IPX_Open_Socket95 -- opens the given socket number                                           *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	socket - socket number to open                                                   *
;*                                                                                               *
;* OUTPUT:      0 if socket opened successfully                                                  *
;*                                                                                               *
;* 32bit PROTO:	extern int __stdcall IPX_Open_Socket95(int socket);                              *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
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




;*************************************************************************************************
;* IPX_Close_Socket95 -- closes the given socket number                                          *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	socket - socket number to close                                                  *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* 32bit PROTO:	extern void __stdcall IPX_Close_Socket95(int socket);                            *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
_IPX_Close_Socket95 proc far pascal uses ax bx cx dx si di ds es fs gs,
		socket:word

		mov	bx,1
		mov_w	dx,[socket]

		call	Call_IPX

		ret

_IPX_Close_Socket95 endp







;*************************************************************************************************
;* _IPX_Get_Connection_Number95 -- get the users local 'connection number'                       *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      connection number. 0 if user isnt logged into novell                             *
;*                                                                                               *
;* 32bit PROTO:	extern int  __stdcall IPX_Get_Connection_Number95(void);                         *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
_IPX_Get_Connection_Number95 proc far pascal uses bx cx dx si di ds es fs gs

		mov	ax,0dc00h
		call	Call_DOS
		and	eax,255
		ret

_IPX_Get_Connection_Number95 endp









;*************************************************************************************************
;* _IPX_Send_Packet95 -- Send a packet via IPX                                                   *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	send_address 	- ptr to address of destination for packet                       *
;*              send_buffer  	- ptr to data to be sent                                         *
;*              send_buffer_len	- length of data in send_buffer                                  *
;*              network_num	- network number                                                 *
;*              node_address	- node address                                                   *
;*                                                                                               *
;* OUTPUT:      true if successfully sent                                                        *
;*                                                                                               *
;* 32bit PROTO:	extern int  __stdcall IPX_Send_Packet95(unsigned char *, unsigned char *,        *
;*							int, unsigned char*, unsigned char*);    *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
_IPX_Send_Packet95 proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		send_address	:far ptr byte,
		send_buffer	:far ptr byte,
		send_buffer_len	:word,
		network_num	:far ptr byte,
		node_address	:far ptr byte

		local	selector	:word			;DOS memory selector
		local	segmento	:word			;DOS memory segment
		local	dos_send_ecb	:far ptr ECB		;ptr to send ECB
		local	dos_send_header	:far ptr IPXHeaderType	;ptr to IPX header for sending
		local	dos_send_buffer	:far ptr byte		;ptr to copy of buffer to be sent
		local	completion_code	:word			;IPX send packet completion code

		; Allocate required DOS memory
		; GlobalDosAlloc is a win3.1 API function for allocating and locking DOS memory
		; GlobalDosAlloc returns the segment in dx and a selector in ax
		xor	ax,ax
		mov	bx,(sizeof ECB + sizeof IPXHeaderType + 1024 +31)
		push	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		pop	bp
		test	ax,ax
		jz	@@error
		mov	[segmento],dx	;save the segment pointer
		mov	[selector],ax	;save the selector pointer

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
		; Clear out the send IPX header
		;
		mov	cx,sizeof IPXHeaderType
		les	di,[dos_send_header]
		rep	stosb

		;
		; Copy the data to be sent into the DOS memory send buffer
		;
		mov	cx,546		;maximum size of IPX data packet
		cmp_w	cx,[send_buffer_len]
		jle	@@got_buffer_len
		mov_w	cx,[send_buffer_len]
@@got_buffer_len:
		les	di,[dos_send_buffer]
		lds	si,[send_buffer]
		rep	movsb

		;
		; Fill in the send ECB
		;
		mov	ax,@data
		mov	ds,ax
		mov	fs,ax			;keep ptr to data seg in fs
		les	di,[dos_send_ecb]

		mov	ax,[MySocket]
		mov	es:[di.SocketNumber],ax
		mov	es:[di.PacketCount],2
		mov	ax,[selector]
		shl	eax,16
		mov_w	ax,[dos_send_header+OFFS]
		mov_d	es:[di.PacketAddress0],eax
		mov_w	es:[di.PacketLength0],sizeof IPXHeaderType
		mov_w	ax,[dos_send_buffer+OFFS]
		mov_d	es:[di.PacketAddress1],eax
		mov_w	ax,[send_buffer_len]
		mov_w	es:[di.PacketLength1],ax

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
		; Fill in the network number and node address
		;
		lds	si,[network_num]
		mov_d	eax,[si]
		mov_d	es:[di.DestNetworkNumber],eax
		lds	si,[node_address]
		mov_d	eax,[si]
		mov_d	es:[di.DestNetworkNode],eax
		mov_w	ax,[si+4]
		mov_w	es:[di.DestNetworkNode+4],ax

		;
		; Send that sucker!
		;
		mov	es,[selector]
		mov	si,SEND_ECB_OFFSET
		mov	bx,IPX_SEND_PACKET
		pusha
		call	Call_IPX
		popa

		;
		; Wait for the send to finish by monitoring the 'in use' flag of the ECB
		;
@@wait_send_loop:
		lds	si,[dos_send_ecb]
		cmp	[si.InUse],0
		jz	@@done

		;
		; Let IPX 'breath' if send isnt complete
		;
		mov	bx,IPX_RELINQUISH_CONTROL
		push	bp
		call	Call_IPX
		pop	bp
		jmp	@@wait_send_loop


		;
		; Get the completion code and save it for posterity
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
		push	bp
		push	bx
		call	GLOBALDOSFREE
		pop	bp

		;
		; Set up the return value
		;
		cmp	[completion_code],0
		jnz	@@error

@@success:	mov	ax,1
		ret

@@error:	xor	ax,ax
		ret


_IPX_Send_Packet95 endp





;*************************************************************************************************
;* _IPX_Broadcast_Packet95 -- Broadcast a packet via IPX                                         *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	send_buffer  	- ptr to data to be sent                                         *
;*              send_buffer_len	- length of data in send_buffer                                  *
;*                                                                                               *
;* OUTPUT:      true if successfully sent                                                        *
;*                                                                                               *
;* 32bit PROTO:	extern int  __stdcall IPX_Broadcast_Packet95(unsigned char *, int);              *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
_IPX_Broadcast_Packet95 proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		send_buffer	:far ptr byte,
		send_buffer_len	:word

		local	selector	:word			;DOS memory selector
		local	segmento	:word                   ;DOS memory segment
		local	dos_send_ecb	:far ptr ECB            ;ptr to send ECB
		local	dos_send_header	:far ptr IPXHeaderType  ;ptr to IPX header for sending
		local	dos_send_buffer	:far ptr byte           ;ptr to copy of buffer to be sent
		local	completion_code	:word                   ;IPX send packet completion code

		; Allocate required DOS memory
		; GlobalDosAlloc is a win3.1 API function for allocating and locking DOS memory
		; GlobalDosAlloc returns the segment in dx and a selector in ax
		xor	ax,ax
		mov	bx,(sizeof ECB + sizeof IPXHeaderType + 1024 +31)
		push	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		pop	bp
		test	ax,ax
		jz	@@error
		mov	[segmento],dx	;save the segment pointer
		mov	[selector],ax   ;save the selector pointer

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
		mov	cx,546		;maximum size of IPX data packet
		cmp_w	cx,[send_buffer_len]
		jle	@@got_buffer_len
		mov_w	cx,[send_buffer_len]
@@got_buffer_len:
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

		mov	ax,[MySocket]
		mov	es:[di.SocketNumber],ax
		mov	es:[di.PacketCount],2
		mov	ax,[selector]
		shl	eax,16
		mov_w	ax,[dos_send_header+OFFS]
		mov_d	es:[di.PacketAddress0],eax
		mov_w	es:[di.PacketLength0],sizeof IPXHeaderType
		mov_w	ax,[dos_send_buffer+OFFS]
		mov_d	es:[di.PacketAddress1],eax
		mov_w	ax,[send_buffer_len]
		mov_w	es:[di.PacketLength1],ax

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
		; Fill in the network number and node address
		;
		mov_d	es:[di.DestNetworkNumber],0ffffffffh
		mov_d	es:[di.DestNetworkNode],0ffffffffh
		mov_w	es:[di.DestNetworkNode+4],0ffffh

		;
		; Send that sucker!
		;
		mov	es,[selector]
		mov	si,SEND_ECB_OFFSET
		mov	bx,IPX_SEND_PACKET
		pusha
		push	fs
		call	Call_IPX
		pop	fs
		popa

		;
		; Wait for the send to finish by monitoring the 'in use' flag of the ECB
		;
@@wait_send_loop:
		lds	si,[dos_send_ecb]
		cmp	[si.InUse],0
		jz	@@done

		;
		; Let IPX 'breath' if send isnt complete
		;
		mov	bx,IPX_RELINQUISH_CONTROL
		push	bp
		call	Call_IPX
		pop	bp
		jmp	@@wait_send_loop


		;
		; Get the completion code and save it for posterity
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
		push	bp
		push	bx
		call	GLOBALDOSFREE
		pop	bp

		;
		; Set up the return value
		;
		cmp	[completion_code],0
		jnz	@@error

@@success:	mov	ax,1
		ret

@@error:	xor	ax,ax
		ret


_IPX_Broadcast_Packet95 endp






;*************************************************************************************************
;* _IPX_Get_Local_Target95 -- Gets the node address of a destination or bridge                   *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	dest_network 	- ptr to network number of target                                *
;*              dest_node	- ptr to node number of target                                   *
;*              socket		- socket number                                                  *
;*              bridge_address	- ptr to buffer to store immediate address in                    *
;*                                                                                               *
;* OUTPUT:      IPX result code. -1 if error                                                     *
;*                                                                                               *
;* 32bit PROTO:	extern int  __stdcall IPX_Get_Local_Target95(unsigned char *, unsigned char*,    *
;*							 unsigned short, unsigned char*);        *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

_IPX_Get_Local_Target95	proc far pascal uses ebx ecx edx esi edi ds es fs gs,
		dest_network	:far ptr byte,
		dest_node	:far ptr byte,
		socket		:word,
		bridge_address	:far ptr byte

		local	segmento	:word	; DOS memory segment
		local	selector	:word	; DOS memory selector
		local	result_code	:word	; return code

		; Allocate required DOS memory for data passed to IPX
		; GlobalDosAlloc is a win3.1 API function for allocating and locking DOS memory
		; GlobalDosAlloc returns the segment in dx and a selector in ax
		xor	ax,ax
		mov	bx,(sizeof local_target_reply_buffer + \
			    sizeof request_local_target_buffer + 15)
		push	bp
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		pop	bp
		test	ax,ax
		jz	@@return_error

		mov	[segmento],dx	; save the segment
		mov	[selector],ax	; save the selector
		mov	fs,ax
		xor	di,di

		;
		; Init the request structure
		;
		lds	si,[dest_network]
		mov_d	eax,[si]
		mov_d	fs:[di.lt_network_number],eax
		lds	si,[dest_node]
		mov	eax,[si]
		mov_d	fs:[di.lt_physical_node],eax
		mov_w	ax,[si+4]
		mov_w	fs:[di.lt_physical_node+4],ax
		mov	ax,[socket]
		mov	fs:[di.lt_socket],ax

		;
		; Set up the registers to call IPX
		;
		mov	bx,IPX_GET_LOCAL_TARGET
		mov	ax,[selector]
		mov	ds,ax
		xor	si,si
		mov	es,ax
		mov	di,sizeof request_local_target_buffer

		;
		; Call IPX
		;
		push	bp
		call	Call_IPX
		pop	bp

		;
		; Save the result code so we can return it
		;
		mov	[result_code],ax

		;
		; Copy the bridge address into the return buffer
		;
		mov	ds,[selector]
		mov	si,sizeof request_local_target_buffer + lt_local_target
		les	di,[bridge_address]
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
		push	bp
		push	bx
		call	GLOBALDOSFREE
		pop	bp

		;
		; Return the IPX result code
		;
		mov	ax,[result_code]
		ret

@@return_error:	mov	ax,-1
		ret

_IPX_Get_Local_Target95	endp



;*************************************************************************************************
;* _IPX_Get_Outstanding_Buffer95 -- return contents of the next unread buffer in the buffer list *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	copy_receive_buffer -- ptr to buffer that data will be copied to                 *
;*                                                                                               *
;* OUTPUT:      number of buffers returned (0 or 1)                                              *
;*                                                                                               *
;* 32bit PROTO:	extern BOOL __stdcall IPX_Get_Outstanding_Buffer95(unsigned char *buffer);       *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

_IPX_Get_Outstanding_Buffer95 proc far pascal uses ebx ecx edx esi edi ebp ds es fs gs,
		copy_receive_buffer:far ptr byte

		mov	ax,@data
		mov	ds,ax

		;
		; If the receive buffer pointer is the same as the pointer to the last buffer
		; returned then there is no outstanding data to return so just exit
		;
		xor	ax,ax
		mov	si,[LastPassedReceiveBuffer]
		cmp	si,[CurrentReceiveBuffer]
		jz	@@done

		;
		; Copy the IPX receive data buffer into the buffer provided by the caller
		;
		push	ds
		mov	cx,RECEIVE_BUFFER_LENGTH/4
		mov	ds,[ReceiveBufferSelector]
		les	di,[copy_receive_buffer]
		rep	movsd
		pop	ds

		;
		; Update the pointer to the last buffer we copied
		;
		cmp	si,RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS
		jc	@@no_wrap
		xor	si,si
@@no_wrap:	mov	[LastPassedReceiveBuffer],si

		mov	ax,1

@@done:		ret

_IPX_Get_Outstanding_Buffer95 endp




;*************************************************************************************************
;* Receive_Callback -- IPX callback function. Called when a new packet arrives                   *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
Receive_Callback proc far

		;
		; Save everything
		;
		pushf
		cli
		cld
		pushad
		push	ds
		push	es
		push	fs
		push	gs

		;
		; Dont reenter
		;
		mov	ax,@data
		mov	ds,ax
		cmp	[NoReenter],0
		jnz	@@out
		mov	[NoReenter],1

		;
		; Update the receive buffer pointer to point to the next buffer
		;
		mov	ax,[CurrentReceiveBuffer]
		add	ax,RECEIVE_BUFFER_LENGTH
		cmp	ax,RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS
		jc	@@no_wrap
		xor	ax,ax
@@no_wrap:	mov	[CurrentReceiveBuffer],ax

		;
		; Listen for another packet
		;
		call	Listen_For_Packet
		mov	ax,@data
		mov	ds,ax
		mov	[NoReenter],0

		;
		; Restore everything and exit
		;
@@out:		pop	gs
		pop	fs
		pop	es
		pop	ds
		popad
		popf
		ret

Receive_Callback endp




;*************************************************************************************************
;* Init_Receive_ECB -- initialises an ECB for receiving a packet                                 *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

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
		mov	bx,[ReceiveBufferSelector]
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
		mov_w	es:[di.Event_Service_Routine+OFFS],offset Receive_Callback
		mov_w	es:[di.Event_Service_Routine+SEGM],cs

		ret

Init_Receive_ECB endp



;*************************************************************************************************
;* _IPX_Start_Listening95 -- initialise DOS memory for receive buffers and start listening for   *
;*                           IPX packets                                                         *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      true if we started listening                                                     *
;*                                                                                               *
;* 32bit PROTO:	extern BOOL __stdcall IPX_Start_Listening95(void);                               *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
_IPX_Start_Listening95 proc far pascal uses ebx ecx edx esi edi ebp ds es fs gs

		;
		; Check that we arent already listening
		;
		mov	ax,@data
		mov	ds,ax
		cmp	[ListeningFailed],0
		jnz	@@restart
		cmp	[Listening],0
		jnz	@@out		;already listening

		;
		; Allocate and lock DOS memory for listen ECB and receive buffers
		; GlobalDosAlloc is a win3.1 API function for allocating and locking DOS memory
		; GlobalDosAlloc returns the segment in dx and a selector in ax
		mov	bx,(RECEIVE_BUFFER_LENGTH*MAX_RECEIVE_BUFFERS + sizeof ECB + 15)
		xor	ax,ax
		save	bp,ds
		push	ax
		push	bx
		call	GLOBALDOSALLOC
		restore	bp,ds
		test	ax,ax
		jz	@@error

		mov	[ReceiveBufferSegment],dx	;save the DOS memory segment in a global
		mov	[ReceiveBufferSelector],ax      ;save the DOS memory selector in a global

	saveall
;	int	3
	mov	ax,@data
	mov	es,ax
	mov	ax,0bh
	mov	bx,es:[ReceiveBufferSelector]
	mov	di,offset OriginalReceiveDescriptor
	int	31h
	bcc	@f
;	int	3
@@:	restall


		;
		; Set up pointers to the DOS memory
		;
		mov	[ReceiveECBOffset],RECEIVE_BUFFER_LENGTH * MAX_RECEIVE_BUFFERS
		mov	[CurrentReceiveBuffer],0	;1st receive buffer
		mov	[LastPassedReceiveBuffer],0

		;
		; Start listening
		;
@@restart:	mov	[ListeningFailed],0
		push	ds
		call	Listen_For_Packet
		pop	ds
		mov	[Listening],1

@@out:		mov	ax,1
		ret

@@error:	xor	ax,ax
		ret

_IPX_Start_Listening95 endp



;*************************************************************************************************
;* _IPX_Shut_Down95 -- finish an IPX session. Releases any allocated resources except the socket *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* 32bit PROTO:	extern void __stdcall IPX_Shut_Down95(void);                                     *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

_IPX_Shut_Down95 proc far pascal uses eax ebx ecx edx esi edi ebp ds es fs gs

		;
		; If we aren't listening then we cant stop
		;
		mov	ax,@data
		mov	ds,ax
		cmp	[Listening],0
		jz	@@out

		;
		; Stop listening for a packet
		;
		mov	es,[ReceiveBufferSelector]
		mov	si,[ReceiveECBOffset]
		mov	bx,IPX_CANCEL_EVENT
		save	bp,ds
		call	Call_IPX
		restore	bp,ds

		;
		; Free the DOS memory
		;
		mov	ax,@data
		mov	ds,ax
		mov	es,ax
		mov	ax,[ReceiveBufferSelector]
		save	bp,ds
		push	ax
		call	GLOBALDOSFREE
		restore	bp,ds

		mov	[Listening],0

@@out:		ret

_IPX_Shut_Down95 endp





Verify_Selectors proc near uses eax ebx ecx edx esi edi ebp ds es fs gs

;		int 	3
		mov	ax,1686h
		int	2fh
		test	ax,ax
		jnz	@@fail

		mov	ax,@data
		mov	es,ax
		mov	ax,0bh
		mov	bx,es:[ReceiveBufferSelector]
		mov	di,offset ReceiveDescriptor
		int	31h
		bcs	@@fail

		mov	ax,@data
		mov	ds,ax
		mov_d	eax,[ReceiveDescriptor]
		cmp_d	eax,[OriginalReceiveDescriptor]
		jnz	@@fail
		mov_d	eax,[ReceiveDescriptor+4]
		cmp_d	eax,[OriginalReceiveDescriptor+4]
		jnz	@@fail
		clc
		ret

@@fail:		stc
		ret

Verify_Selectors endp




;*************************************************************************************************
;* Listen_For_Packet -- Start IPX listening for an incoming packet                               *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	nothing                                                                          *
;*                                                                                               *
;* OUTPUT:      nothing                                                                          *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

Listen_For_Packet proc near uses eax ebx ecx edx esi edi ebp ds es fs gs

		call	Verify_Selectors
		bcs	@@fail

		call	Init_Receive_ECB

		mov	ax,@data
		mov	ds,ax
		mov	es,[ReceiveBufferSelector]
		mov	si,[ReceiveECBOffset]
		mov	bx,IPX_LISTEN_FOR_PACKET
		push	ds
		call	Call_IPX
		pop	ds
		ret

@@fail:		mov	ax,@data
		mov	ds,ax
		mov	[ListeningFailed],1
		ret


Listen_For_Packet endp





;*************************************************************************************************
;* Call_IPX -- Make a call to the IPX entry point                                                *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	registers set up for the IPX call                                                *
;*                                                                                               *
;* OUTPUT:      registers returned by IPX                                                        *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*
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

Call_IPX	endp







;*************************************************************************************************
;* Call_DOS -- use DPMI to call a DOS interrupt service                                          *
;*                                                                                               *
;*                                                                                               *
;* INPUT:	registers set up for the DOS call                                                *
;*                                                                                               *
;* OUTPUT:      registers returned by DOS                                                        *
;*                                                                                               *
;* HISTORY:                                                                                      *
;*   01/29/96 ST: Created.                                                                       *
;*===============================================================================================*

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
		; Save the segment registers
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

		mov	ax,DPMI_CALL_REAL_INT	; Simulate real mode interrupt
		xor	bh,bh			; flags - should be zero
		mov	bl,21h			; interrupt number
		mov	ecx,0			; number of words to copy from the protected mode stack
		mov	di,offset RegisterDump
		push	gs
		pop	es
		push	gs
		int	31h			;DPMI interrupt
		pop	gs

		;
		; Get the return registers
		;
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






