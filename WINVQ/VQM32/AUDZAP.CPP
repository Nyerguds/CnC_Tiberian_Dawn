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
*     Audzap.c
*
* DESCRIPTION
*     Lossy audio compression. (32-Bit protected mode)
*
* PROGRAMMER
*     Joe L. Bostic
*      
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     AudioZap - Compress audio sample data.
*
****************************************************************************/

#include <stdio.h>
#include <mem.h>
#include "compress.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#define	MIN(a,b) (((a)<(b)) ? (a) : (b))
#define	MAX(a,b) (((a)>(b)) ? (a) : (b))

typedef enum {
	CODE_2BIT,    /* Bit packed 2 bit delta. */
	CODE_4BIT,    /* Nibble packed 4 bit delta. */
	CODE_RAW,     /* Raw sample. */
	CODE_SILENCE  /* Run of silence. */
} SCodeType;

char _2bitencode[5] = {
	0,1,2,3
};

long _2bitdecode[4] = {
	-2,-1,0,1
};

char _4bitencode[19] = {
	0,1,2,2,3,4,5,6,7,(8),
	8,9,10,11,12,13,13,14,15
};

long _4bitdecode[16] = {
	-9,-8,-6,-5,-4,-3,-2,
	-1,0,1,2,3,4,5,6,8
};


/****************************************************************************
*
* NAME
*     AudioZap - Compress audio sample data.
*
* SYNOPSIS
*     Size = AudioZap(Source, Dest, Size)
*
*     long AudioZap(void *, void *, long);
*
* FUNCTION
*     NOTE - If the compressed size is equal to or greater than the original
*     size then the data could not be compressed and the uncompressed data
*     should be written.
*
* INPUTS
*     Source - Pointer to buffer containing audio sample data.
*     Dest   - Pointer to buffer to put encoded data.
*     Size   - Number of bytes to compress.
*
* RESULT
*     Size - Size in bytes of encoded data.
*
****************************************************************************/

long AudioZap(void *source, void *dest, long size)
{
	unsigned char *s = (unsigned char *)source;
	unsigned char *d = (unsigned char *)dest;
	long          delta;
	unsigned long previous = 0x80;
	long          outcount = 0;
	unsigned char *s4;
	unsigned long p4;
	long          max4;
	unsigned char *lastraw = 0;
	long          osize = size;
	unsigned long i;
	unsigned long dd;

	/* Reduce very small amplitudes to silence.  Usually a rather large
	 * portion of a sample is hovering around the silence value.  This is
	 * due, in part, to the artifacting of the sample process.  These low
	 * amplitudes are not audible.
	 */
	max4 = size;
	s = (unsigned char *)source;

	while (size > 0 && outcount < osize) {

		/* First check for runs of zero deltas.  If a run of at least
		 * any can be found, then output it.
		 */
		s4 = s;
		max4 = MIN(63 + 1, size);

		for (i = 0; i < max4; i++) {
			if (previous != *s4++)
				break;
		}

		/* When there is a code transition, terminate any run of raw
		 * samples.
		 */
		if (i > 2) {
			lastraw = 0;
			*d++ = ((i - 1)|(CODE_SILENCE << 6));
			outcount++;
			s += i;
			size -= i;
			continue;
		}

		/* If there are fewer than 4 samples remaining, then using delta
		 * compression is inefficient.  Just drop into the raw routine
		 */
		if (size > 4) {
			s4 = s;
			p4 = previous;

			/* Find out the number of lossless 2 bit deltas available.  These
			 * deltas are always present in quads.  The compressed code is
			 * the delta quad count followed by the deltas in bit packed bytes.
			 */
			max4 = MIN(64L * 4L + 4L + 4L, size);

			for (i = 0; i < max4; i++) {
				delta = (((int)*s4++) - p4);

				if ((delta < -2) || (delta > 1)) {
					break;
				}

				p4 += _2bitdecode[_2bitencode[delta + 2]];

				if (((signed)p4) < 0) {
					p4 = 0;
				}

				if (((signed)p4) > 255) {
					p4 = 255;
				}
			}

			i >>= 2;  // Delta 2 always occur in quads -- force this.

			/* If there is the minimum benificial number of delta 2s available,
			 * then compress them.
			 */
			if (i) {

				/* When there is a code transition, terminate any run of raw
				 * samples.
				 */
				lastraw = 0;

				/* Output the delta 4 pair count.  This is the number of pairs
				 * minus the 'free' two pairs already assumed to be there.
				 */
				i = MIN(i, (63 + 1));
				*d++ = ((i - 1)|(CODE_2BIT << 6));
				outcount++;

				for (dd = 0; dd < i; dd++) {
					int delta1, delta2, delta3, delta4;

					delta1 = _2bitencode[((((int)*s++) - previous) + 2)];
					previous += _2bitdecode[delta1];

					if (((signed)previous) < 0) {
						previous = 0;
					}

					if (((signed)previous) > 255) {
						previous = 255;
					}

					size--;
					delta2 = _2bitencode[((((int)*s++) - previous) + 2)];
					previous += _2bitdecode[delta2];

					if (((signed)previous) < 0) {
						previous = 0;
					}

					if (((signed)previous) > 255) {
						previous = 255;
					}

					size--;
					delta3 = _2bitencode[((((int)*s++) - previous) + 2)];
					previous += _2bitdecode[delta3];

					if (((signed)previous) < 0) {
						previous = 0;
					}

					if (((signed)previous) > 255) {
						previous = 255;
					}

					size--;
					delta4 = _2bitencode[((((int)*s++) - previous) + 2)];
					previous += _2bitdecode[delta4];

					if (((signed)previous) < 0) {
						previous = 0;
					}

					if (((signed)previous) > 255) {
						previous = 255;
					}

					size--;
					*d++ = ((delta4 << 6)|(delta3 << 4)|(delta2 << 2)|delta1);
					outcount++;
				}
				continue;
			} else {
				s4 = s;
				p4 = previous;

				/* Find out the number of lossless 4 bit deltas follow.  These
				 * deltas are always present in pairs.  The compressed code is
				 * the delta pair count followed by the deltas in nibble packed
				 * bytes.
				 */
				max4 = MIN(64L * 2L + 4L + 4L, size);

				for (i = 0; i < max4; i++) {
					delta = (((int)*s4++) - p4);

					if (delta < -9 || delta >= 9) {
						break;
					}

					p4 += _4bitdecode[_4bitencode[(delta + 9)]];

					if (((signed)p4) < 0) {
						p4 = 0;
					}

					if (((signed)p4) > 255) {
						p4 = 255;
					}
				}

				i >>= 1; // Delta 4 always occur in pairs -- force this.

				/* If there is the minimum benificial number of delta 4s available,
				 * then compress them.
				 */
				if (i) {

					/* When there is a code transition, terminate any run of raw
					 * samples.
					 */
					lastraw = 0;

					/* Output the delta 4 pair count.  This is the number of pairs
					 * minus the 'free' two pairs already assumed to be there.
					 */
					i = MIN(i, (63 + 1));
					*d++ = ((i - 1)|(CODE_4BIT << 6));
					outcount++;

					for (dd = 0; dd < i; dd++) {
						int delta1, delta2;

						delta1 = _4bitencode[((((int)*s++) - previous) + 9)];
						previous += _4bitdecode[delta1];

						if (((signed)previous) < 0) {
							previous = 0;
						}

						if (((signed)previous) > 255) {
							previous = 255;
						}

						size--;
						delta2 = _4bitencode[((((int)*s++) - previous) + 9)];
						previous += _4bitdecode[delta2];
						
						if (((signed)previous) < 0) {
							previous = 0;
						}

						if (((signed)previous) > 255) {
							previous = 255;
						}

						size--;
						*d++ = ((delta2 << 4)|(delta1 & 0x0F));
						outcount++;
					}
					continue;
				}
			}
		}

		/* Raw output since deltas were unsuccessful.  If this is a run
		 * of raw output, then merely tack it onto the run rather than
		 * create a new code sequence.
		 */
		if (lastraw) {
			*lastraw = ((*lastraw) + 1);

			/* There is only so much a run code can accomodate.  If the limit
			 * has been reached, then terminate this code.  A new one will be
			 * created if necessary.
			 */
			if ((*lastraw & 0x1F) == 0x1F) {
				lastraw = 0;
			}
		} else {
			
			/* If there is no current raw dump of samples, then check to see if
			 * this sample can fit into a 5 bit delta.  If it can, then store
			 * it as such as a parasite to the "raw" code.  This will save a byte
			 * for any stray 5 bit deltas that happen along.  It is expected that
			 * this is more frequent than 6 or more bit deltas that would necessitate
			 * the use of the RAW code.
			 */
			delta = (((int)*s) - previous);

			if ((delta >= -16) && (delta <= 15)) {
				lastraw = 0;
				*d++ = ((CODE_RAW << 6)|0x20|(delta & 0x1F));
				outcount++;
				previous = *s++;
				size--;
				continue;
			} else {
				lastraw = d;
				*d++ = (CODE_RAW << 6);
				outcount++;
			}
		}

		*d++ = previous = *s++;
		size--;
		outcount++;
	}

	/* Check to see if the compression process actually resulted in smaller
	 * data size.  In some cases, the 'compressed' data is actually larger.  In
	 * this case, just output the raw frame.  If the compressed and actual frame
	 * size match, then it is presumed that no compression occurs.
	 */
	if (outcount >= osize) {
		memcpy(dest, source, (size_t)osize);
		outcount = osize;
	}

	return(outcount);
}

