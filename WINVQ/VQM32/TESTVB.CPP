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
*     testvb.c
*
* DESCRIPTION
*     Video mode setting. (32-Bit protected mode)
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     Febuary 3, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     TestVBIBit     - Test the polarity of the vertical blank bit.
*
****************************************************************************/

#include <sys\timeb.h>

#ifdef __BORLANDC__
#include "portio.h"
#else
#include <conio.h>
#endif

/****************************************************************************
*
* NAME
*     TestVBIBit - Test the polarity of the vertical blank bit.
*
* SYNOPSIS
*     Polarity = TestVBIBit()
*
*     long TestVBIBit(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     Polarity - Polarity of the vertical blank bit.
*
****************************************************************************/

long TestVBIBit(void)
{
	return (1);
#ifdef  OBSOLETE
	// Ancient CRT stuff?
	
	static struct timeb mytime;
	long          curtime;
	long          endtime;
	unsigned long high = 0;
	unsigned long low = 0;

	/* Set the check time for .25 (1/4) of a second. */
	ftime(&mytime);
	curtime = ((mytime.time * 1000) + mytime.millitm);
	endtime = (curtime + (1000 / 4));

	/* Sample the vertical blank bit for the specified period of time.
	 * The state in which it is in the least is the vertical blank state,
	 * the state in which it is in the most is the active scan state.
	 */
	while (endtime >= curtime) {
		ftime(&mytime);
		curtime = ((mytime.time * 1000) + mytime.millitm);

		if (inp(0x3DA) & 0x08) {
			high++;
		} else {
			low++;
		}
	}

	return (high > low);
#endif
}



