/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef HUFFMAN_H
#define HUFFMAN_H
/****************************************************************************
*
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     huffman.h
*
* DESCRIPTION
*     Huffman order 0 compress/decompress definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     May 19, 1995
*
****************************************************************************/


/* TreeNode: Huffman decoding tree node.
 *
 * count  - Weight of the node in the tree.
 * child0 - Child node 0
 * child1 - Child node 1
 */
typedef struct _TreeNode {
 	unsigned long  count;
	unsigned short child0;
	unsigned short child1;
} TreeNode;


/* HuffCode: This structure is used for storing the code for each symbol
 *            during encoding. A table of codes for each symbol is built
 *            from the Huffman tree.
 *
 * code - Code used to represent a symbol.
 * bits - Length of code in bits.
 */
typedef struct _HuffCode {
	unsigned short code;
	short          bits;
} HuffCode;


#define HUFF_EOS 256 /* End of stream symbol */

/* Prototypes */
#ifdef __cplusplus
extern "C" {
#endif

long __cdecl HuffCompress(unsigned char *data, unsigned char *buffer,
		long length, char *work);

long __cdecl HuffDecompress(unsigned char *data, unsigned char *buffer,
		long length, char *work);

void __cdecl HuffCount(unsigned char *data, TreeNode *nodes, long length,
		long zero);

void __cdecl HuffScaleCounts(TreeNode *nodes);
long __cdecl RLEHuffCounts(TreeNode *nodes, unsigned char *buffer);
long __cdecl BuildHuffTree(TreeNode *nodes);

void __cdecl ConvertToCodes(TreeNode *nodes, HuffCode *codes,
		unsigned short code, short bits, short node);

long __cdecl HuffEncode(unsigned char *data, unsigned char *buffer,
		HuffCode *codes, long length);

#ifdef __cplusplus
}
#endif

#endif /* HUFFMAN_H */

