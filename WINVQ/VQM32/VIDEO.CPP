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
*     video.c
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
*     SetVideoMode   - Set the video mode.
*     GetDisplayInfo - Get the display info for the current video mode.
*     GetVBIBit      - Get the vertical blank bit polarity.
*
****************************************************************************/

#include <stdlib.h>
#include <dos.h>
#include <conio.h>

#ifndef __WATCOMC__
#include <pharlap.h>
#include <pldos32.h>
#else
#include "realmode.h"
#endif

#include "video.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

static DisplayInfo _Display = {-1,0,0,0,NULL};


/****************************************************************************
*
* NAME
*     SetVideoMode - Set the display to the specified video mode.
*
* SYNOPSIS
*     DisplayInfo = SetVideoMode(Mode)
*
*     DisplayInfo *SetVideoMode(long);
*
* FUNCTION
*     Set the video display adapter to the desired video mode.
*
* INPUTS
*     Mode - Desired video mode.
*
* RESULT
*     DisplayInfo - Pointer to DisplayInfo structure, otherwise 0 for error.
*
****************************************************************************/

DisplayInfo *SetVideoMode(long mode)
{
	#ifdef __WATCOMC__
	union REGS   regs;
	struct SREGS sregs;
	#else
	union _REGS  regs;
	#endif

	DisplayInfo  *di = NULL;
	VESAModeInfo *vminfo;
	long         error;

	/* Initialize the video manager on the first invocation of
	 * SetVideoMode()
	 */
	if (_Display.Mode == -1) {
		_Display.VBIbit = TestVBIBit();
	}

	/* Clear the VRAM before enabling the mode so that there is
	 * not any garbage on the screen.
	 */
	ClearVRAM();

	/* If the requested mode is the same as the current mode then
	 * we do not need to do anything.
	 */
	if (mode != _Display.Mode) {

		/* Uninitialize VESA if the previous mode was a VESA mode and the new
		 * mode is not.
		 */
		if (((_Display.Mode >= VESA_MIN) && (_Display.Mode <= VESA_MAX))
				&& ((mode < VESA_MIN) && (mode > VESA_MAX))) {

			UninitVESA();
		}

		/* Set display to an XMode. */
		if ((mode >= XMODE_MIN) && (mode <= XMODE_MAX)) {
			SetXMode(mode);
			ClearXMode();
			SetupXPaging();
			ShowXPage(0);
			_Display.Mode = mode;
			_Display.Extended = NULL;
			di = &_Display;

			/* Set display resolution information */
			switch (mode) {
				case XMODE_320X200:
					_Display.XRes = 320;
					_Display.YRes = 200;
					break;

				case XMODE_320X240:
					_Display.XRes = 320;
					_Display.YRes = 240;
					break;

				case XMODE_320X400:
					_Display.XRes = 320;
					_Display.YRes = 400;
					break;

				case XMODE_320X480:
					_Display.XRes = 320;
					_Display.YRes = 480;
					break;

				case XMODE_360X400:
					_Display.XRes = 360;
					_Display.YRes = 400;
					break;

				case XMODE_360X480:
					_Display.XRes = 360;
					_Display.YRes = 480;
					break;
			}
		}
		else if ((mode >= VESA_MIN) && (mode <= VESA_MAX)) {

			/* Initialize the VESA manager if the current mode is not a VESA
			 * mode.
			 */
			if ((_Display.Mode < VESA_MIN) || (_Display.Mode > VESA_MAX)) {
				 error = InitVESA();
			}

			if (!error) {

				/* Set the display to MCGA before going into VESA. This needs to be
				 * done to ensure that the video ram selector is initialized. This
				 * fixes a bug in some VESA BIOS'.
				 */
				#ifndef __WATCOMC__
				regs.x.ax = mode;
				_int86(0x10, &regs, &regs);
				#else
				segread(&sregs);
				regs.x.eax = mode;
				int386x(0x10, &regs, &regs, &sregs);
				#endif

				if ((vminfo = SetVESAMode(mode)) != NULL) {
					_Display.Mode = mode;
					_Display.XRes = (long)vminfo->XRes;
					_Display.YRes = (long)vminfo->YRes;
					_Display.Extended = vminfo;
					di = &_Display;
				}
			}
		}
		else {
			#ifndef __WATCOMC__
			regs.x.ax = mode;
			_int86(0x10, &regs, &regs);
			#else
			segread(&sregs);
			regs.x.eax = mode;
			int386x(0x10, &regs, &regs, &sregs);
			#endif

			_Display.Mode = mode;
			_Display.XRes = 320;
			_Display.YRes = 200;
			_Display.Extended = NULL;
			di = &_Display;
		}
	} else {
		di = &_Display;
	}

	return (di);
}


/****************************************************************************
*
* NAME
*     GetDisplayInfo - Get the display info for the current video mode.
*
* SYNOPSIS
*     DisplayInfo = GetDisplayInfo()
*
*     DisplayInfo *GetDisplayInfo(void);
*
* FUNCTION
*     Return a pointer to the current display information structure.
*
* INPUTS
*     NONE
*
* RESULT
*     DisplayInfo - Pointer to initialized display info or NULL if not valid.
*
****************************************************************************/

DisplayInfo *GetDisplayInfo(void)
{
	if (_Display.Mode != 0) {
		return (&_Display);
	} else {
		return (NULL);
	}
}


/****************************************************************************
*
* NAME
*     GetVBIBit - Get the vertical blank bit polarity.
*
* SYNOPSIS
*     VBIBit = GetVBIBit()
*
*     long GetVBIBit(void);
*
* FUNCTION
*     Return the polarity of the vertical blank bit.
*
* INPUTS
*     NONE
*
* RESULT
*     VBIBit - Vertical blank bit polarity.
*
****************************************************************************/

long GetVBIBit(void)
{
	return (_Display.VBIbit);
}

