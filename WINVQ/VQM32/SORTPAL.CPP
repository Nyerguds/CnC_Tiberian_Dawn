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
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     sortpal.c
*
* DESCRIPTION
*     Palette sorting routines. (32-Bit protected mode)
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*     Bill Randolph
*
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     SortPalette    - Sort a palette.
*     Comp_Luminance - Compare the luminace of two 24-bit palette entries.
*     Comp_HSV       - Compare the HSV of two 24-bit palette entries.
*     RGB_To_HSV     - Convert RGB color to HSV color.
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "palette.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

/* HSV color model */
#define DIVIDE_WITH_ROUND(n,d) (unsigned short)(((n)/(d))+ \
		(unsigned short)(((n)%(d)) >= (((d)+1)>>1)))

#define HSV_BASE          255
#define HUE_WEIGHT        10L
#define SATURATION_WEIGHT 100L
#define VALUE_WEIGHT      1000L

/* Prototypes */
static int Comp_Luminance(const void *elem1, const void *elem2);
static int Comp_HSV(const void *elem1, const void *elem2);
static void RGB_To_HSV(unsigned short r, unsigned short g, unsigned short b, 
		unsigned short *h, unsigned short *s, unsigned short *v);


/****************************************************************************
*
* NAME
*     SortPalette - Sort a palette.
*
* SYNOPSIS
*     SortPalette(Palette, NumColors)
*
*     void SortPalette(unsigned char *, long);
*
* FUNCTION
*     Sort the palette colors.
*
* INPUTS
*     Palette   - Pointer to palette to sort.
*     NumColors - Number of colors in the palette.
*
* RESULT
*     NONE
*
****************************************************************************/

void SortPalette(unsigned char *pal, long numcolors)
{
	qsort(pal, numcolors, 3, Comp_Luminance);

	pal[0] = 0;
	pal[1] = 0;
	pal[2] = 0;
}


/****************************************************************************
*
* NAME
*     Comp_Luminance - Compare the luminace of two 24-bit palette entries.
*
* SYNOPSIS
*     Result = Comp_Luminance(Color1, Color2)
*
*     long Comp_Luminance(void *, void *);
*
* FUNCTION
*     Compare the luminace of the two colors and determine which color is
*     brighter than the other.
*
*     The computation used is:
*       Luminance = (red * .299) + (green * .587) + (blue * .114)
*
* INPUTS
*     Color1 - Pointer to palette entry.
*     Color2 - Pointer to palette entry.
*
* RESULT
*     Result - 0 = same, 1 = Color1 > Color2, -1 = Color1 < Color2
*
****************************************************************************/

static int Comp_Luminance(const void *elem1, const void *elem2)
{
	unsigned char *pal;
	long          r,g,b;
	long          total1,total2;

	/* Compute luminance for color1 */
	pal = (unsigned char *)elem1;
	r = ((long)pal[0]);
	g = ((long)pal[1]);
	b = ((long)pal[2]);
	total1 = ((r * 19595L) + (g * 38470L) + (b * 7471L));

	/* Compute luminance for color2 */
	pal = (unsigned char *)elem2;
	r = ((long)pal[0]);
	g = ((long)pal[1]);
	b = ((long)pal[2]);
	total2 = ((r * 19595L) + (g * 38470L) + (b * 7471L));

	if (total1 < total2) {
		return (-1);
	} else if (total1 > total2) {
		return (1);
	} else {
		return (0);
	}
}


/****************************************************************************
*
* NAME
*     Comp_HSV - Compare the HSV of two 24-bit palette entries.
*
* SYNOPSIS
*     Result = Comp_HSV(Color1, Color2)
*
*     long Comp_HSV(void *, void *);
*
* FUNCTION
*     Compare the HSV color values of two colors and determine the
*     relationship between the colors in the color space.
*
* INPUTS
*     Color1 - Pointer to 1st palette entry.
*     Color2 - Pointer to 2nd palette entry.
*
* RESULT
*     Result - 0 = same, 1 = Color1 > Color2, -1 = Color1 < Color2
*
****************************************************************************/

static int Comp_HSV(const void *elem1, const void *elem2)
{
	unsigned char  *pal;
	unsigned char  r,g,b;
	unsigned short h,s,v;
	unsigned long  key1,key2;
	long           retval;

	/* Convert 1st element to HSV */
	pal = (unsigned char *)elem1;
	r = pal[0];
	g = pal[1];
	b = pal[2];

	RGB_To_HSV((unsigned short)r,(unsigned short)g,(unsigned short)b,&h,&s,&v);
	key1 = ((h * HUE_WEIGHT) + (s * SATURATION_WEIGHT) + (v * VALUE_WEIGHT));

	/* Convert 2nd element to HSV */
	pal = (unsigned char *)elem2;
	r = pal[0];
	g = pal[1];
	b = pal[2];

	RGB_To_HSV((unsigned short)r,(unsigned short)g,(unsigned short)b,&h,&s,&v);
	key2 = ((h * HUE_WEIGHT) + (s * SATURATION_WEIGHT) + (v * VALUE_WEIGHT));

	if (key1 != key2) {
		retval = ((key1 < key2) ? -1 : 1);
	} else {
		retval = 0;
	}

	return (retval);
}


/***************************************************************************
*
* NAME
*     RGB_To_HSV - Convert RGB color to HSV color.
*
* SYNOPSIS
*     RGB_To_HSV(R, G, B, H, S, V)
*
*     void RGB_To_HSV(unsigned short, unsigned short, unsigned short,
*                     unsigned short *, unsigned short *, unsigned short *);
*
* FUNCTION
*     Convert the RBG color to a HSV color. Assumes 8 bits per gun of R, G
*     and B data. Also the HSV is based on a 255 degree scale rather than
*     the more accurate 360 degree scale.
*
* INPUTS
*     R - Red gun value.
*     G - Green gun value.
*     B - Blue gun value.
*     H - Pointer to H value. (H will be set upon return of this function)
*     S - Pointer to S value. (S will be set upon return of this function)
*     V - Pointer to V value. (V will be set upon return of this function)
*
* RESULT
*     NONE
*
***************************************************************************/

static void RGB_To_HSV(unsigned short r, unsigned short g, unsigned short b, 
		unsigned short *h, unsigned short *s, unsigned short *v)
{
 	unsigned short m;
	unsigned short r1;
	unsigned short g1;
	unsigned short b1;
	unsigned short tmp;

	/* Set hue to default. */
	*h = 0;

	/* Set v = Max(r,g,b) to find dominant primary color. */
	*v = ((r > g) ? r : g);

	if (b > *v) {
		*v = b;
	}

	/* Set m = min(r,g,b) to find amount of white. */
	m = ((r < g) ? r : g);

	if (b < m) {
		m = b;
	}

	/* Determine the normalized saturation. */
	if (*v != 0) {
		*s = DIVIDE_WITH_ROUND((*v - m) * HSV_BASE, *v);
	} else {
		*s = 0;
	}

	if (*s != 0) {
		tmp = *v - m;
	 	r1 = DIVIDE_WITH_ROUND((*v - r) * HSV_BASE, tmp);
	 	g1 = DIVIDE_WITH_ROUND((*v - g) * HSV_BASE, tmp);
	 	b1 = DIVIDE_WITH_ROUND((*v - b) * HSV_BASE, tmp);

		/* Find effect of second most predominant color.
		 * In which section of the hexagon of colors does the color lie?
		 */
		if ((*v) == r) {
		 	if (m == g) {
				*h = 5 * HSV_BASE + b1;
			} else {
				*h = 1 * HSV_BASE - g1;
			}
		} else {
			if ((*v) == g) {
			 	if (m == b) {
					*h = 1 * HSV_BASE + r1;
				} else {
					*h = 3 * HSV_BASE - b1;
				}
			} else {
			 	if (m == r) {
					*h = 3 * HSV_BASE + g1;
				} else {
					*h = 5 * HSV_BASE - r1;
				}
			}
		}

		/* Divide by six and round. */
		*h = DIVIDE_WITH_ROUND(*h, 6);
	}
}
