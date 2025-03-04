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
*     vesavid.c
*
* DESCRIPTION
*     VESA video manager. (32-Bit protected mode)
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     InitVESA         - Initialize the VESA video manager.
*     UninitVESA       - Uninitialize the VESA video manager.
*     SetVESAMode      - Set the display to the specified VESA video mode.
*     ReadVESAModeInfo - Read the VESA mode information from the video card.
*     SetVESAWindow    - Set VESA window A's start address.
*
****************************************************************************/

#include <stdio.h>
#include <mem.h>
#include <dos.h>

#ifndef __WATCOMC__
#include <pldos32.h>
#include <pharlap.h>
#else
#include "realmode.h"
#endif

#include "vesavid.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#ifdef __WATCOMC__
static short _VInfoSel = NULL;
static short _VInfoSeg = NULL;
static short _ModeInfoSel = NULL;
static short _ModeInfoSeg = NULL;

#else  /* __WATCOMC__ */
/* _regs       - Registers used for calling software interrupts.
 * _rpVInfo    - Real pointer to VInfo structure in conventional memory.
 * _rpModeInfo - Real pointer to ModeInfo structure in conventional memory.
 * _VInfo      - Protected mode copy of VInfo structure.
 * _ModeInfo   - Protected mode copy of ModeInfo structure.
 */
static SWI_REGS _regs;
static REALPTR _rpVInfo = NULL;
static REALPTR _rpModeInfo = NULL;
static VESAInfo _VInfo;
static VESAModeInfo _ModeInfo;

#endif /* __WATCOMC__ */


/****************************************************************************
*
* NAME
*     InitVESA - Initialize the VESA video manager.
*
* SYNOPSIS
*     Error = InitVESA()
*
*     long InitVESA(void);
*
* FUNCTION
*     Initialize the VESA video system. Get the VESA information from the
*     VESA video bios.
*
* INPUTS
*     NONE
*
* RESULT
*     Error - 0 if successful, or -1 error/VESA not supported.
*
****************************************************************************/

long InitVESA(void)
{
	#ifdef __WATCOMC__
	union REGS   r;
	struct SREGS sr;
	RMInfo       rmi;
	long         error = -1;

	/* Allocate real-mode memory for VESA structure. */
	r.x.eax = 0x0100;
	r.x.ebx = (sizeof(VESAInfo) + 15) >> 4;
	int386(0x31, &r, &r);

	if (r.x.cflag == 0) {
		_VInfoSel = r.w.dx;
		_VInfoSeg = r.w.ax;

		/* Allocate real-mode memory for VESAModeInfo structure. */
		r.x.eax = 0x0100;
		r.x.ebx = (sizeof(VESAModeInfo) + 15) >> 4;
		int386(0x31, &r, &r);

		if (r.x.cflag == 0) {
			_ModeInfoSel = r.w.dx;
			_ModeInfoSeg = r.w.ax;

			/* Clear VESAInfo structure. */
			memset(MK_PTR(0, _VInfoSeg), 0, sizeof(VESAInfo));

			/* Get VESA information. */
			memset(&rmi, 0, sizeof(RMInfo));
			rmi.eax = 0x4F00;
			rmi.edi = 0;
			rmi.es = _VInfoSeg;

			segread(&sr);
			r.w.ax = 0x0300;
			r.h.bl = 0x10;
			r.h.bh = 0;
			r.w.cx = 0;
			sr.es = FP_SEG(&rmi);
			r.x.edi = FP_OFF(&rmi);
			int386x(0x31, &r, &r, &sr);

			if ((r.x.cflag == 0) && (rmi.eax == 0x004F)) {
				error = 0;
			}
		}
	}


	if (error != 0) {
		UninitVESA();
	}

	return (error);

	#else  /* __WATCOMC__ */

	unsigned short rseg;
	long           paras;
	long           error = -1;

	/* Calculate size of VESAInfo structure in paragraphs */
	paras = (sizeof(VESAInfo) + 15) >> 4;
	
	/* Allocate real-mode memory for VESA structure. */
	if (_dx_real_alloc(paras, (unsigned short *)&rseg,
			(unsigned short *)&paras) == 0) {

		RP_SET(_rpVInfo, 0, rseg);

		/* Calculate size of VESAModeInfo structure in paragraphs */
		paras = (sizeof(VESAModeInfo) + 15) >> 4;

		/* Allocate real-mode memory for VESAModeInfo structure. */
		if (_dx_real_alloc(paras, (unsigned short *)&rseg,
				(unsigned short *)&paras) == 0) {

			RP_SET(_rpModeInfo, 0, rseg);

			/* Clear the input buffer */
			FillRealMem(_rpVInfo, 0, sizeof(VESAInfo));

			/* Set up function call */
			_regs.eax = 0x4F00;
			_regs.edi = RP_OFF(_rpVInfo);
			_regs.es = RP_SEG(_rpVInfo);
			_dx_real_int(0x10, &_regs);

			if (_regs.eax == 0x004F) {
				ReadRealMem(&_VInfo, _rpVInfo, sizeof(VESAInfo));
				error = 0;
			}
		}
	}

	if (error != 0) {
		UninitVESA();		
	}

	return (error);

	#endif /* __WATCOMC__ */
}


/****************************************************************************
*
* NAME
*     UninitVESA - Uninitialize the VESA video manager.
*
* SYNOPSIS
*     UninitVESA()
*
*     void UninitVESA(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     NONE
*
****************************************************************************/

void UninitVESA(void)
{
	#ifdef __WATCOMC__
	union REGS r;

	/* Free VESAInfo structure */
	if (_VInfoSeg != NULL) {
		r.x.eax = 0x0101;
		r.x.edx = _VInfoSel;
		int386(0x31, &r, &r);

		_VInfoSeg = NULL;
		_VInfoSel = NULL;
	}

	/* Free VESAModeInfo structure */
	if (_ModeInfoSeg != NULL) {
		r.x.eax = 0x0101;
		r.x.edx = _VInfoSel;
		int386(0x31, &r, &r);

		_ModeInfoSeg = NULL;
		_ModeInfoSel = NULL;
	}

	#else  /* __WATCOMC__ */

	/* Free VESAInfo structure */
	if (_rpVInfo != NULL) {
		_dx_real_free(RP_SEG(_rpVInfo));
		_rpVInfo = NULL;
	}

	/* Free VESAModeInfo structure */
	if (_rpModeInfo != NULL) {
		_dx_real_free(RP_SEG(_rpModeInfo));
		_rpModeInfo = NULL;
	}
	#endif /* __WATCOMC__ */
}


/****************************************************************************
*
* NAME
*     SetVESAMode - Set the display adapter to the given VESA video mode.
*
* SYNOPSIS
*     VESAModeInfo = SetVESAMode(Mode)
*
*     VESAModeInfo *SetVESAMode(long);
*
* FUNCTION
*     Set the display adapter to the specified VESA video mode.
*
* INPUTS
*     Mode - VESA video mode to set the display to.
*
* RESULT
*     VESAModeInfo - Pointer to VESA mode information structure or NULL if
*                    error.
*
****************************************************************************/

VESAModeInfo *SetVESAMode(long mode)
{
	VESAModeInfo *vminfo;

	/* Get mode info */
	if ((vminfo = ReadVESAModeInfo(mode)) != NULL) {

		/* If the mode is supported, set it. */
		if ((vminfo->Attributes & 0x01) != 0) {

			#ifdef __WATCOMC__
			{
			union REGS r;
			
			r.x.eax = 0x4F02;
			r.x.ebx = mode;
			int386(0x10, &r, &r);

			if (r.x.eax != 0x004F)
				vminfo = NULL;
			}

			#else  /* __WATCOMC__ */

			/* Set up function call */
			_regs.eax = 0x4F02;
			_regs.ebx = mode;
			_dx_real_int(0x10, &_regs);

			if (_regs.eax != 0x004F) {
				vminfo = NULL;
			}
			#endif /* __WATCOMC__ */
		}
	}

	return (vminfo);
}


/****************************************************************************
*
* NAME
*     ReadVESAModeInfo - Read the VESA mode information from the video card.
*
* SYNOPSIS
*     VESAModeInfo = ReadVESAModeInfo(Mode)
*
*     VESAModeInfo *ReadVESAModeInfo(long);
*
* FUNCTION
*     Read information about the specified mode from the VESA video BIOS.
*
* INPUTS
*     Mode - Mode ID to get information about.
*
* RESULT
*     VESAModeInfo - Pointer to VESA mode information structure or NULL if
*                    error.
*
****************************************************************************/

VESAModeInfo *ReadVESAModeInfo(long mode)
{
	VESAModeInfo *vminfo = NULL;

	#ifdef __WATCOMC__
	union REGS   r;
	struct SREGS sr;
	RMInfo       rmi;

	/* Make sure we have real-mode memory. */
	if (_ModeInfoSeg != NULL) {
		memset(MK_PTR(0, _ModeInfoSeg), 0, sizeof(VESAModeInfo));

		/* Get mode information. */
		memset(&rmi, 0, sizeof(RMInfo));
		rmi.eax = 0x4F01;
		rmi.ecx = mode;
		rmi.edi = 0;
		rmi.es = _ModeInfoSeg;

		segread(&sr);
		r.w.ax = 0x0300;
		r.w.bx = 0x0010;
		r.w.cx = 0;
		sr.es = FP_SEG(&rmi);
		r.x.edi = FP_OFF(&rmi);
		int386x(0x31, &r, &r, &sr);

		if ((r.x.cflag == 0) && (rmi.eax == 0x004F)) {
			vminfo = (VESAModeInfo *)MK_PTR(0, _ModeInfoSeg);
		}
	}

	#else  /* __WATCOMC__ */

	/* Make sure we have real-mode memory. */
	if (_rpModeInfo != NULL) {

		/* Clear the input buffer */
		FillRealMem(_rpModeInfo, 0, sizeof(VESAModeInfo));

		/* Set up function call */
		_regs.eax = 0x4F01;
		_regs.ecx = mode;
		_regs.edi = RP_OFF(_rpModeInfo);
		_regs.es = RP_SEG(_rpModeInfo);
		_dx_real_int(0x10, &_regs);

		if (_regs.eax == 0x004F) {
			ReadRealMem(&_ModeInfo, _rpModeInfo, sizeof(VESAModeInfo));
			vminfo = &_ModeInfo;
		}
	}
	#endif /* __WATCOMC__ */

	return (vminfo);
}


/****************************************************************************
*
* NAME
*     SetVESAWindow - Set VESA window A's start address.
*
* SYNOPSIS
*     Error = SetVESAWindow(GrainNum)
*
*     long SetVESAWindow(long);
*
* FUNCTION
*     This function invokes the Window Function, whose address is provided
*     in the VESAModeInfo structure. The 'GrainNum' must be in granularity
*     units as specified in the ModeInfo structure.
*
* INPUTS
*     GrainNum - Granularity number to set window to.
*
* RESULT
*     NONE
*
****************************************************************************/

void SetVESAWindow(long grain)
{
	#ifdef __WATCOMC__
	#else  /* __WATCOMC__ */

  RMC_BLK regp;
	
	regp.eax = 0x4F05;
	regp.ebx = 0x00;
	regp.edx = grain;
	_dx_call_real(_ModeInfo.WinFunc, &regp, 0);
	#endif /* __WATCOMC__ */
}

