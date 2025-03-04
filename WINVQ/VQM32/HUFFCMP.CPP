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

/****************************************************************************
*
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     huffcmp.h
*
* DESCRIPTION
*     Huffman order 0 compressor.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     May 19, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     HuffCompress    - Compress data using huffman order 0 compression.
*     HuffCount       - Count the frequency of occurence of every byte.
*     HuffScaleCounts - Scale down the frequency counts.
*     RLEHuffCounts   - Run Length Encode the Huffman counts.
*     ConvertToCodes  - Convert the Huffman tree into a table of codes.
*     HuffEncode      - Huffman encode the data.
*
****************************************************************************/

#include <mem.h>
#include "huffman.h"


/****************************************************************************
*
* NAME
*     HuffCompress - Compress data using huffman order 0 compression.
*
* SYNOPSIS
*     Size = HuffCompress(Data, Buffer, Size, Temp)
*
*     long HuffCompress(unsigned char *, unsigned char *, long, char *);
*
* FUNCTION
*     This function performs an order 0 Huffman encoding of the input data.
*     The algorithm used is fairly straightforward. First a count is made of
*     all the bytes in the input data, then the counts are scaled down to
*     a single byte representation in the node array. After the counts are
*     scaled, a Huffman decoding tree is built from the node array. Then
*     a code array is built by traversing the tree for each symbol. Finally,
*     the input data is compressed.
*
* INPUTS
*     Data   - Pointer to data to compress.
*     Buffer - Pointer to compressed data.
*     Size   - Length of data to compress.
*     Temp   - Pointer to temporary working buffer. (Must be >= 5120 bytes!)
*
* RESULT
*     Size - Compressed size.
*
****************************************************************************/

long __cdecl HuffCompress(unsigned char *data, unsigned char *buffer,
		long length, char *temp)
{
	#if(1)
	TreeNode *nodes;
	HuffCode *codes;
	long     size;
	long     root;

	/* Initialize variables */
	nodes = (TreeNode *)temp;
	temp += (514 * sizeof(TreeNode));
	codes = (HuffCode *)temp;

	/* Analyze the frequency of the data. */
	HuffCount(data, nodes, length, 1);
	HuffScaleCounts(nodes);

	/* Save the counts for the decompression. */
	size = RLEHuffCounts(nodes, buffer);
	buffer += size;

	/* Build the Huffman decode tree and generate codes for encoding. */
	root = BuildHuffTree(nodes);
	ConvertToCodes(nodes, codes, 0, 0, root);

	/* Encode the data. */
	size += HuffEncode(data, buffer, codes, length);

	return (size);
	#else
	TreeNode      *nodes;
	HuffCode      *codes;
	unsigned long *counts;
	unsigned long max_count;
	long          i;
	long          size;
	long          first;
	long          last;
	long          next;
	unsigned long symbol;
	unsigned long mask;

	/* Initialize variables. */
	nodes = (TreeNode *)temp;
	temp += (514 * sizeof(TreeNode));
	counts = (unsigned long *)temp;
	codes = (HuffCode *)temp;

	/* Zero the initial counts. */
	memset(temp, 0, 256 * sizeof(unsigned long));
	size = 0;

	/*-------------------------------------------------------------------------
	 * Calculate the distribution of the data then scale down the counts so
	 * they fit in an 8 bit value. This is done in order to limit the size of
	 * the codes to 16 bits.
	 *-----------------------------------------------------------------------*/
	i = 0;

	while (i < length) {
		counts[((unsigned char *)data)[i]]++;
		i++;
	}

	/* Scale down the counts. */
	max_count = 0;

	/* Find the maximum count. */
	for (i = 0; i < 256; i++) {
		if (counts[i] > max_count) {
			max_count = counts[i];
		}
	}

	if (max_count == 0) {
		counts[0] = 1;
		max_count = 1;
	}

	max_count /= 255;
	max_count++;

	/* Scale down the counts. */
	for (i = 0; i < 256; i++) {
		nodes[i].count = (unsigned long)(counts[i] / max_count);

		/* Make sure that a node with a non-zero count does not get scaled
		 * down to zero.
		 */
		if ((nodes[i].count == 0) && (counts[i] != 0)) {
			nodes[i].count = 1;
		}
	}

	nodes[HUFF_EOS].count = 1;

	/*-------------------------------------------------------------------------
	 * OUTPUT THE COUNTS
	 *
	 * In order to save space, we store runs of counts in the following format:
	 *
	 *   Start, Stop, Counts..., Start, Stop, Counts..., ..., 0
	 *
	 * The list is terminated by storing a start value of zero (0).
	 *
	 * In order to efficiently use this format, we do not want to stop a run
	 * because of just one or two zero counts. So we include zero counts of
	 * less than three (3) in the run.
	 *-----------------------------------------------------------------------*/

	/* Find the first occurance of a non-zero count. */
	first = 0;

	while ((first < 255) && (nodes[first].count == 0)) {
		first++;
	}

	/* Each time I hit the start of the loop, I assume that first is the
	 * number for a run of non-zero values.  The rest of the loop is
	 * concerned with finding the value for last, which is the end of the
	 * run, and the value of next, which is the start of the next run.
	 * At the end of the loop, I assign next to first, so it starts in on
	 * the next run.
	 */
	for (; first < 256; first = next) {
		last = first + 1;

		for (;;) {

			/* Find the end of the run of non-zeros. */
			for (; last < 256; last++) {
				if (nodes[last].count == 0) {
					break;
				}
			}

	    last--;

			/* Check the beginning of the next run of non-zero counts. */
			for (next = last + 1; next < 256; next++) {
				if (nodes[next].count != 0) {
					break;
				}
			}

			/* Quit the run if we have reached the end. */
			if (next > 255) {
				break;
			}

			/* Quit the run if there is more than three non-zero counts. */
			if ((next - last) > 3) {
				break;
			}

		  last = next;
		};

		/* Output Start and Stop. */
		*buffer++ = first;
		*buffer++ = last;

		/* Output the run of counts. */
		for (i = first; i <= last; i++) {
			*buffer++ = (char)nodes[i].count;
		}

		size += (((last - first) + 1) + 2);
	}

	/* Output terminator. */
	*buffer++ = 0;
	size++;

	/*-------------------------------------------------------------------------
	 * Build the Huffman tree. All active nodes are scanned in order to locate
	 * the two nodes with the minimum weights. These two weights are added
	 * together and assigned to a new node. The new node makes the two minimum
	 * nodes into its 0 child and 1 child. The two minimum nodes are then
	 * marked as inactive. This process repeats until their is only one node
	 * left, which is the root node.
	 *-----------------------------------------------------------------------*/

	/* Node 513 is used to arbitratilly provide a node with a guaranteed
	 * maximum value.
	 */
	nodes[513].count = 0xFFFF;

	for (next = (HUFF_EOS + 1); ; next++) {
		first = 513;
		last = 513;

		for (i = 0; i < next; i++) {

			/* We are only concerned with non-zero count nodes. */
			if (nodes[i].count != 0) {
				if (nodes[i].count < nodes[first].count) {
					last = first;
					first = i;
				} else if (nodes[i].count < nodes[last].count) {
					last = i;
				}
			}
		}

		if (last == 513) {
			break;
		}

		nodes[next].count = (nodes[first].count + nodes[last].count);
		nodes[first].count = 0;
		nodes[last].count = 0;
		nodes[next].child0 = (first << 3);
		nodes[next].child1 = (last << 3);
	}

	next--;

	/*-------------------------------------------------------------------------
	 * Convert the Huffman tree into an encoding table then encode the data.
	 *-----------------------------------------------------------------------*/
	ConvertToCodes(nodes, codes, 0, 0, (next << 3));

	/* Encode the data. */
	*buffer = 0;
	next = 0x80;
	i = 0;

	do {
		if (i < length) {
			symbol = ((unsigned char *)data)[i];
		} else {
			symbol = HUFF_EOS;
		}

		mask = 1L << (codes[symbol].bits - 1);

		while (mask != 0) {

			/* Set a bit in the output stream for each bit in the code. */
			if (mask & codes[symbol].code) {
				*buffer |= next;
			}

			/* Next bit position. */
			next >>= 1;

			/* Advance to the next byte in the output stream when the current
			 * byte is full.
			 */
			if (next == 0) {
				buffer++;
				*buffer = 0;
				next = 0x80;
				size++;
			}

			/* Next bit in the code. */
			mask >>= 1;
		}

		i++;
	} while (symbol != HUFF_EOS);

	if (next != 0x80) {
		size++;
	}

	return (size);
	#endif
}


/****************************************************************************
*
* NAME
*     HuffCount - Count the frequency of occurence of every byte.
*
* SYNOPSIS
*     HuffCount(Data, Nodes, Length, Zero)
*
*     void HuffCounts(unsigned char *, TreeNode *, long, long);
*
* FUNCTION
*     This function counts the frequency of occurence of every byte in the
*     input data. The nodes must be initialized to zero prior to calling this
*     function for the first time, otherwise the counts will be flawed.
*
* INPUTS
*     Data     - Pointer to data to analyze.
*     TreeNode - Pointer to array of nodes.
*     Length   - Length of data to analyze.
*     Zero     - Zero any previous counts flag. (TRUE = zero counts)
*
* RESULT
*     Size - Amount of buffer used to hold counts.
*
****************************************************************************/

void __cdecl HuffCount(unsigned char *data, TreeNode *nodes, long length,
		long zero)
{
	long i;

	/* Zero any previous counts. */
	if (zero) {
		for (i = 0; i < 256; i++) {
			nodes[i].count = 0;
		}
	}

	/* Calculate the distribution of the data. */
	i = 0;

	while (i < length) {
		nodes[((unsigned char *)data)[i]].count++;
		i++;
	}
}


/****************************************************************************
*
* NAME
*     HuffScaleCounts - Scale down the frequency counts.
*
* SYNOPSIS
*     HuffScaleCounts(Nodes)
*
*     void HuffScaleCounts(TreeNode *);
*
* FUNCTION
*     In order to limit the size of the Huffman codes to 16 bits, we must
*     scale down the counts so they can be represented by a BYTE size value.
*
* INPUTS
*     Nodes  - Pointer to nodes to scale counts for.
*
* RESULT
*     NONE
*
****************************************************************************/

void __cdecl HuffScaleCounts(TreeNode *nodes)
{
	unsigned long max_count;
	unsigned long unscaled;
	long          i;
	long          first;
	long          last;
	long          next;

	/* Scale down the counts so they fit in an 8 bit value. This is done in
	 * order to limit the size of the codes to 16 bits.
	 */
	max_count = 0;

	/* Find the maximum count. */
	for (i = 0; i < 256; i++) {
		if (nodes[i].count > max_count) {
			max_count = nodes[i].count;
		}
	}

	if (max_count == 0) {
		nodes[0].count = 1;
		max_count = 1;
	}

	max_count /= 255;
	max_count++;

	/* Scale down the counts. */
	for (i = 0; i < 256; i++) {
		unscaled = nodes[i].count;
		nodes[i].count /= max_count;

		/* Make sure that a node with a non-zero count does not get scaled
		 * down to zero.
		 */
		if ((nodes[i].count == 0) && (unscaled != 0)) {
			nodes[i].count = 1;
		}
	}

	nodes[HUFF_EOS].count = 1;
}


/****************************************************************************
*
* NAME
*     RLEHuffCounts - Run Length Encode the Huffman counts.
*
* SYNOPSIS
*     Size = RLEHuffCounts(Nodes, Buffer)
*
*     long RLEHuffCounts(TreeNode *, unsigned char *);
*
* FUNCTION
*     In order for the decoder to build the same model, we have to transmit
*     the symbol counts to it. To save space we do not save all 256 symbols
*     unconditionally, instead we run length encode the counts. The format
*     used to store the counts is as follows:
*
*       Start, Stop, Counts[n], Start, Stop, Counts[n], .... 0
*
*     Note: The sequence is terminated by a start value of 0. Also at least
*     1 run of counts has to be stored, even if the first start value is 0.
*
* INPUTS
*     Nodes  - Pointer to initialized nodes.
*     Buffer - Pointer to buffer to store RLE'd counts.
*
* RESULT
*     Size - Size of the RLE'd counts.
*
****************************************************************************/

long __cdecl RLEHuffCounts(TreeNode *nodes, unsigned char *buffer)
{
	long i;
	long first;
	long last;
	long next;
	long size = 0;

	/* Find the first occurance of a non-zero count. */
	first = 0;

	while ((first < 255) && (nodes[first].count == 0)) {
		first++;
	}

	/* Each time I hit the start of the loop, I assume that first is the
	 * number for a run of non-zero values.  The rest of the loop is
	 * concerned with finding the value for last, which is the end of the
	 * run, and the value of next, which is the start of the next run.
	 * At the end of the loop, I assign next to first, so it starts in on
	 * the next run.
	 */
	for (; first < 256; first = next) {
		last = first + 1;

		for (;;) {

			/* Find the end of the run of non-zeros. */
			for (; last < 256; last++) {
				if (nodes[last].count == 0) {
					break;
				}
			}

	    last--;

			/* Check the beginning of the next run of non-zero counts. */
			for (next = last + 1; next < 256; next++) {
				if (nodes[next].count != 0) {
					break;
				}
			}

			/* Quit the run if we have reached the end. */
			if (next > 255) {
				break;
			}

			/* Quit the run if there is more than three non-zero counts. */
			if ((next - last) > 3) {
				break;
			}

		  last = next;
		};

		/* Output Start and Stop. */
		*buffer++ = first;
		*buffer++ = last;

		/* Output the run of counts. */
		for (i = first; i <= last; i++) {
			*buffer++ = (unsigned char)nodes[i].count;
		}

		size += (((last - first) + 1) + 2);
	}

	/* Output terminator. */
	*buffer = 0;
	size++;

	return (size);
}


/****************************************************************************
*
* NAME
*     ConvertToCodes - Convert the Huffman tree into a table of codes.
*
* SYNOPSIS
*     ConvertToCodes(Nodes, Codes, Code, Bits, Node)
*
*     void ConvertToCodes(TreeNode *, HuffCode *, unsigned short, short,
*                         short);
*
* FUNCTION
*     Since the Huffman tree is built as a decoding tree, there is no simple
*     way to get the encoding values for each symbol. This routine
*     recursively walks through the tree, adding the child bits to each code
*     until it gets to a leaf. When it gets to a leaf, it stores the code
*     value.
*
* INPUTS
*     Nodes - Pointer to the Huffman tree.
*     Codes - Pointer to the table of codes to generate.
*     Code  - Code being built (initialize with 0).
*     Bits  - Number of bits the code is comprised of (initialize with 0).
*     Node  - Number of the current node.
*
* RESULT
*     NONE
*
****************************************************************************/

void __cdecl ConvertToCodes(TreeNode *nodes, HuffCode *codes,
		unsigned short code, short bits, short node)
{
	node >>= 3;

	if (node <= HUFF_EOS) {
		codes[node].code = code;
		codes[node].bits = bits;
		return;
	}

	code <<= 1;
	bits++;
	ConvertToCodes(nodes, codes, code, bits, nodes[node].child0);
	ConvertToCodes(nodes, codes, code|1, bits, nodes[node].child1);
}


/****************************************************************************
*
* NAME
*     HuffEncode - Huffman encode the data.
*
* SYNOPSIS
*     Size = HuffEncode(Data, Buffer, Codes, Length);
*
*     long HuffEncode(unsigned char *, unsigned char *, HuffCodes *, long);
*
* FUNCTION
*     Encoding of the data is simple. Each byte of data is taken as the index
*     of the codes array, the corresponding code is then put in the output.
*
* INPUTS
*     Data   - Pointer to data to encode.
*     Buffer - Pointer to buffer to hold encoded data.
*     Codes  - Pointer to array of Huffman codes.
*     Length - Length of data buffer to encode.
*
* RESULT
*     Size - Size of encoded data.
*
****************************************************************************/

long __cdecl HuffEncode(unsigned char *data, unsigned char *buffer,
		HuffCode *codes, long length)
{
	long          i;
	long          size;
	long          next;
	unsigned long mask;
	unsigned long symbol;

	/* Initialize */
	*buffer = 0;
	next = 0x80;
	i = 0;

	do {
		if (i < length) {
			symbol = ((unsigned char *)data)[i];
		} else {
			symbol = HUFF_EOS;
		}

		mask = 1L << (codes[symbol].bits - 1);

		while (mask != 0) {

			/* Set a bit in the output stream for each bit in the code. */
			if (mask & codes[symbol].code) {
				*buffer |= next;
			}

			/* Next bit position. */
			next >>= 1;

			/* Advance to the next byte in the output stream when the current
			 * byte is full.
			 */
			if (next == 0) {
				buffer++;
				*buffer = 0;
				next = 0x80;
				size++;
			}

			/* Next bit in the code. */
			mask >>= 1;
		}

		i++;
	} while (symbol != HUFF_EOS);

	if (next != 0x80) {
		size++;
	}

	return (size);
}

