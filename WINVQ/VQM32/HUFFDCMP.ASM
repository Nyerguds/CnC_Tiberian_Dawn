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
;*     huffdcmp.asm
;*
;* DESCRIPTION
;*     Huffman order 0 decompressor.
;*
;* PROGRAMMER
;*     Denzil E. Long, Jr.
;*
;* DATE
;*     May 22, 1995
;*
;*---------------------------------------------------------------------------
;*
;* PUBLIC
;*     HuffDecompress - Decompress Huffman order 0 encoded data.
;*     BuildHuffTree  - Build the Huffman decode tree.
;*
;****************************************************************************

	IDEAL
	P386
	MODEL	USE32 FLAT
	LOCALS	??

	STRUC	TreeNode
count	DD	?	;Weight of the node
child0	DW	?	;Child node 0
child1	DW	?	;Child node 1
	ENDS	TreeNode

HUFF_EOS	EQU	256

	CODESEG

;****************************************************************************
;*
;* NAME
;*     HuffDecompress - Decompress Huffman order 0 encoded data.
;*
;* SYNOPSIS
;*     Size = HuffDecompress(Data, Buffer, Length, Temp)
;*
;*     long = HuffDecompress(unsigned char *, unsigned char *, long, char *);
;*
;* FUNCTION
;*     Expand data that has been compressed with order 0 Huffman coding.
;*     The model (counts) are extracted from the data and a decode tree is
;*     built. The data is expanded by reading a bit and traversing the tree
;*     until a leaf node is encountered.
;*
;* INPUTS
;*     Data   - Pointer to Huffman encoded data.
;*     Buffer - Pointer to decompress buffer.
;*     Length - Maximum decompress length.
;*     Temp   - Pointer to temporary working buffer. (Must be >= 5120 bytes!)
;*
;* RESULT
;*     Size - Size of decompressed data.
;*
;****************************************************************************

	GLOBAL	C HuffDecompress:NEAR
	PROC	HuffDecompress C NEAR USES esi edi ebx ecx edx

	ARG	data:NEAR PTR
	ARG	buffer:NEAR PTR
	ARG	length:DWORD
	ARG	temp:NEAR PTR

	LOCAL	next:DWORD

;*---------------------------------------------------------------------------
;*	Read in the set of counts
;*---------------------------------------------------------------------------

	mov	esi,[data]		;Compressed data
	mov	ebx,[temp]		;Nodes array

	mov	ax,[esi]		;Get first and last count
	xor	edx,edx		;i = 0
	xor	ecx,ecx
	add	esi,2

??getcounts:
	cmp	al,dl		;Reached start of run?
	jne	??zerocount

;*	Copy the run of counts to the nodes

	sub	ah,al		;Run length = Stop - Start
	xor	ecx,ecx
	mov	cl,ah
	xor	eax,eax
	inc	ecx		;Run length + 1

??copycounts:
	mov	al,[esi]		;Get count
	inc	edx		;i++
	mov	[ebx],eax		;Write count to node
	inc	esi
	add	ebx,8		;Next node
	dec	ecx
	jnz	??copycounts

	mov	ax,[esi]		;Get next start
	inc	esi
	cmp	al,0		;Terminator?
	je	short ??nextcount

	inc	esi
	jmp	short ??nextcount

;*	Fill empty nodes with 0

??zerocount:
	mov	[DWORD PTR ebx],ecx
	inc	edx		;i++
	add	ebx,8		;Next node

??nextcount:
	cmp	edx,256
	jl	short ??getcounts

	mov	[WORD PTR ebx],1
	mov	[data],esi

;*---------------------------------------------------------------------------
;*	Build the Huffman tree. All active nodes are scanned in order
;*	to locate the two nodes with the minimum weights. These two
;*	weights are added together and assigned a new node. The new
;*	node makes the two minimum nodes into its 0 child and 1 child.
;*	The two minimum nodes are then marked as inactive. This process
;*	repeats until their is only one node left, which is the root.
;*---------------------------------------------------------------------------
	
	mov	eax,[temp]		;Nodes array
	mov	esi,eax
	add	eax,(513 * 8)		;Node[513] = guaranteed maximum
	mov	[DWORD PTR eax],-1

	mov	[next],((HUFF_EOS + 1) * 8)

??sortnext:
	mov	edx,(513 * 8)		;first = 513
	mov	edi,edx		;last = 513
	xor	ecx,ecx		;i = 0
	mov	ebx,esi		;nodes[i]

??sortnodes:
	cmp	[WORD PTR ebx],0	;Only check non-zero nodes
	jz	??nextnode

;*	nodes[i].count < nodes[first].count

	mov	eax,[DWORD PTR esi + edx]
	cmp	eax,[DWORD PTR ebx]
	jbe	??checklast

	mov	edi,edx		;last = first
	mov	edx,ecx		;first = i
	jmp	short ??nextnode

;*	nodes[i].count < nodes[last].count

??checklast:
	mov	eax,[DWORD PTR esi + edi]
	cmp	eax,[DWORD PTR ebx]
	jbe	??nextnode

	mov	edi,ecx		;last = i

??nextnode:
	add	ecx,8		;i++
	add	ebx,8		;nodes[i]
	cmp	ecx,[next]
	jne	short ??sortnodes

;*	Tree done when last = 513

	cmp	edi,(513 * 8)
	je	short ??decode

	mov	ebx,[next]
	add	ebx,esi
	mov	[WORD PTR ebx+4],dx	;nodes[next].child0 = first
	mov	[WORD PTR ebx+6],di	;nodes[next].child1 = last

	add	edx,esi
	mov	eax,[DWORD PTR edx]	;nodes[first].count
	add	edi,esi
	mov	[DWORD PTR ebx],eax
	
	mov	ecx,[DWORD PTR edi]	;nodes[last].count
	xor	eax,eax
	add	[DWORD PTR ebx],ecx

	mov	[DWORD PTR edx],eax	;nodes[first].count = 0
	mov	[DWORD PTR edi],eax	;nodes[lats].count = 0
	add	[next],8
	jmp	??sortnext

;*---------------------------------------------------------------------------
;*	Expand the compressed data. As each new symbol is decoded, the
;*	tree is traversed, starting at the root node, reading a bit in,
;*	and taking either the child0 or child1 path. Eventually, the
;*	tree winds down to a leaf node, and the corresponding symbol is
;*	output. If the symbol is the HUFF_EOS symbol the process
;*	terminates.
;*---------------------------------------------------------------------------

??decode:
	sub	[next],8		;rootnode - 1
	xor	ecx,ecx
	mov	esi,[data]		;Input data buffer
	mov	al,080h		;mask = 0x80
	mov	edi,[buffer]		;Output buffer
	mov	ah,[esi]		;Data byte
	mov	ebx,[temp]
	inc	esi

??decodeloop:
	mov	edx,[next]		;node = root
	
??walktree:
	mov	ecx,4
	add	ecx,edx
	test	al,ah
	jz	short ??getnode

	add	ecx,2

??getnode:
	mov	dx,[WORD PTR ebx + ecx]		;nodes[node].child
	shr	al,1
	jnz	short ??checkleaf

	mov	ah,[esi]		;Get next data byte
	mov	al,080h		;Reset mask
	inc	esi

??checkleaf:
	cmp	edx,(HUFF_EOS * 8)
	jg	short ??walktree
	je	short ??done

	shr	edx,3
	mov	[edi],dl
	inc	edi
	jmp	short ??decodeloop

??done:
	mov	eax,edi
	sub	eax,[buffer]
	ret

	ENDP	HuffDecompress


;****************************************************************************
;*
;* NAME
;*     BuildHuffTree - Build the Huffman decode tree.
;*
;* SYNOPSIS
;*     Root = BuildHuffTree(Nodes)
;*
;*     long BuildHuffTree(TreeNode *);
;*
;* FUNCTION
;*     Build the Huffman tree. All active nodes are scanned in order to
;*     locate the two nodes with the minimum weights. These two weights are
;*     added together and assigned a new node. The new node makes the two
;*     minimum nodes into its 0 child and 1 child. The two minimum nodes are
;*     then marked as inactive. This process repeats until their is only one
;*     node left, which is the root.
;*
;* INPUTS
;*     Nodes - Pointer to array of nodes.
;*
;* RESULT
;*     Root - Number of root node.
;*
;****************************************************************************

	GLOBAL	C BuildHuffTree:NEAR
	PROC	BuildHuffTree C NEAR USES esi edi ebx ecx edx

	ARG	temp:NEAR PTR
	
	LOCAL	next:DWORD

	mov	eax,[temp]		;Nodes array
	mov	esi,eax
	add	eax,(513 * 8)		;Node[513] = guaranteed maximum
	mov	[DWORD PTR eax],-1

	mov	[next],((HUFF_EOS + 1) * 8)

??sortnext:
	mov	edx,(513 * 8)		;first = 513
	mov	edi,edx		;last = 513
	xor	ecx,ecx		;i = 0
	mov	ebx,esi		;nodes[i]

??sortnodes:
	cmp	[WORD PTR ebx],0	;Only check non-zero nodes
	jz	??nextnode

;*	nodes[i].count < nodes[first].count

	mov	eax,[DWORD PTR esi + edx]
	cmp	eax,[DWORD PTR ebx]
	jbe	??checklast

	mov	edi,edx		;last = first
	mov	edx,ecx		;first = i
	jmp	short ??nextnode

;*	nodes[i].count < nodes[last].count

??checklast:
	mov	eax,[DWORD PTR esi + edi]
	cmp	eax,[DWORD PTR ebx]
	jbe	??nextnode

	mov	edi,ecx		;last = i

??nextnode:
	add	ecx,8		;i++
	add	ebx,8
	cmp	ecx,[next]
	jne	short ??sortnodes

;*	Tree done when last = 513

	cmp	edi,(513 * 8)
	je	short ??done

	mov	ebx,[next]
	add	ebx,esi		;nodes[next]
	mov	[WORD PTR ebx+4],dx	;nodes[next].child0 = first
	mov	[WORD PTR ebx+6],di	;nodes[next].child1 = last

	add	edx,esi
	mov	eax,[DWORD PTR edx]	;nodes[first].count
	add	edi,esi
	mov	[DWORD PTR ebx],eax

	mov	ecx,[DWORD PTR edi]	;nodes[last].count
	xor	eax,eax 
	add	[DWORD PTR ebx],ecx

	mov	[DWORD PTR edx],eax	;nodes[first].count = 0
	mov	[DWORD PTR edi],eax	;nodes[lats].count = 0
	add	[next],8
	jmp	??sortnext

??done:
	mov	eax,[next]
	sub	eax,8
	ret

	ENDP	BuildHuffTree

	END

