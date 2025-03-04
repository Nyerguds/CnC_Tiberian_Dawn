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
*     xmodepg.c
*
* DESCRIPTION
*     Xmode page access. (32-Bit protected mode)
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
*     SetupXPaging - Setup Xmode paging variables.
*     FlipXPage    - Page flip to next Xmode page.
*     ShowXPage    - Show the specified Xmode page.
*     GetXHidPage  - Get the address of the current Xmode HidPage.
*     GetXSeenPage - Get the address of the current Xmode SeenPage.
*
****************************************************************************/

#include <dos.h>
#include "video.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#define PAGE0_START_OFFSET 0
#define PAGE1_START_OFFSET ((320 * 240) / 4)

/* PageFlip page values. */
static unsigned long PageStartOffsets[2] = {
	PAGE0_START_OFFSET,
	PAGE1_START_OFFSET
};

static long DisplayedPage;
static long NonDisplayedPage;

/****************************************************************************
*
* NAME
*     SetupXPaging - Setup Xmode paging variables.
*
* SYNOPSIS
*     SetupXPaging()
*
*     void SetupXPaging(void);
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

void SetupXPaging(void)
{
	DisplayedPage = 1;
	NonDisplayedPage = DisplayedPage ^ 1;
}


/****************************************************************************
*
* NAME
*     FlipXPage - Page flip to next Xmode page.
*
* SYNOPSIS
*     FlipXPage()
*
*     void FlipXPage(void);
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

void FlipXPage(void)
{
	ShowXPage(PageStartOffsets[NonDisplayedPage]);
	DisplayedPage = NonDisplayedPage;
	NonDisplayedPage = DisplayedPage ^ 1;
}


/****************************************************************************
*
* NAME
*     ShowXPage - Show the specified Xmode page.
*
* SYNOPSIS
*     ShowXPage(page)
*
*     void ShowXPage(long);
*
* FUNCTION
*
* INPUTS
*     Page - Xmode page number to show.
*
* RESULT
*     NONE
*
****************************************************************************/

void DisplayXPage(long page)
{
	ShowXPage(PageStartOffsets[page & 1]);
	DisplayedPage = page;
	NonDisplayedPage = DisplayedPage ^ 1;
}


/****************************************************************************
*
* NAME
*     GetXHidPage - Get the address of the current Xmode HidPage.
*
* SYNOPSIS
*     HidPage = GetXHidPage()
*
*     unsigned char *GetXHidPage(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     HidPage - Address of Xmode HidPage.
*
****************************************************************************/

unsigned char *GetXHidPage(void)
{
	return((unsigned char *)PageStartOffsets[NonDisplayedPage]);
}


/****************************************************************************
*
* NAME
*     GetXSeenPage - Get the address of the current Xmode SeenPage.
*
* SYNOPSIS
*     SeenPage = GetXSeenPage()
*
*     unsigned char *GetXSeenPage(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     SeePage - Address of the Xmode SeenPage.
*
****************************************************************************/

unsigned char *GetXSeenPage(void)
{
	return ((unsigned char *)PageStartOffsets[DisplayedPage]);
}

