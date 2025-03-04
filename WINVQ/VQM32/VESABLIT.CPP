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
*     vesablit.c
*
* DESCRIPTION
*     VESA bitblit routines. (32-Bit protected mode)
*
* PROGRAMMER
*     Bill Randolph
*     Denzil E. Long, Jr.
*
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     VESA_Blit_640x480 - Blit to 640x480 256 color VESA mode.
*
****************************************************************************/

#include <stdio.h>
#include <mem.h>
#include <dos.h>
#include "video.h"
#include "vesavid.h"
#include "vesablit.h"


/****************************************************************************
*
* NAME
*     VESA_Blit_640x480 - Blit to 640x480 256 color VESA mode.
*
* SYNOPSIS
*     VESA_Blit_640x480(DisplayInfo, Buffer, X, Y, Width, Height)
*
*     void VESA_Blit_640x480(DisplayInfo *, char *, long, long, long, long);
*
* FUNCTION
*
* INPUTS
*     DisplayInfo - Pointer to display information structure.
*     Buffer      - Pointer to buffer to blit to VRAM.
*     X           - Destination X coordinate of blit (upper left).
*     Y           - Destination Y coordinate of blit (upper left).
*     Width       - Width of blit.
*     Height      - Height of blit.
*
* RESULT
*     NONE
*
****************************************************************************/

void VESA_Blit_640x480(DisplayInfo *disp,unsigned char *buf,long x1,long y1,
		long width,long height)
{
	VESAModeInfo *vminfo;
	long         bank;
	long         last_bank;
	long         bank_offset;
	long         scrn_offset;
	long         grains_per_win;
	long         part1;
	long         part2;
	long         i;

	/* Initialize values */
	vminfo = (VESAModeInfo *)disp->Extended;
	scrn_offset = ((disp->XRes * y1) + x1);
	grains_per_win = ((long)vminfo->WinSize / (long)vminfo->WinGranularity);
	bank_offset = scrn_offset % 65536L;
	last_bank = -1;

	for (i = 0; i < height; i++) {

		/* Compute which bank this scanline is in */
		bank = (scrn_offset / 65536L);

		/* Set a new bank */
		if (bank != last_bank) {
			SetVESAWindow(bank);
			last_bank = bank;
			bank_offset = (scrn_offset % 65536L);
		}

		/* Copy a full scanline */
		if ((bank_offset + width) < 65536L) {
			Copy_Row((char *)buf, (char *)bank_offset, width);
			buf += width;
			scrn_offset += disp->XRes;
			bank_offset += disp->XRes;
		}

		/* Copy two partial scanlines */
		else {
			part1 = (65536L - bank_offset);
			part2 = (width - part1);
			Copy_Row((char *)buf, (char *)bank_offset, part1);

			buf += part1;
			bank += grains_per_win;
			last_bank += grains_per_win;
			SetVESAWindow(bank);
			Copy_Row((char *)buf, (char *)0, part2);

			buf += part2;
			scrn_offset += disp->XRes;
			bank_offset = (scrn_offset % 65536L);
		}
	}
}
