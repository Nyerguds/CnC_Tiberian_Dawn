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
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*---------------------------------------------------------------------------
*
* FILE
*     mem.c
*
* DESCRIPTION
*     Memory management.
*
* PROGRAMMER
*     Phil Gorrow
*     Denzil E. Long, Jr.
*
* DATE
*     July 5, 1995
*
*---------------------------------------------------------------------------
*
* PUBLIC
*     DPMI_Lock   - Lock a memory page.
*     DPMI_Unlock - Unlock a locked memory page.
*
****************************************************************************/

#ifdef __WATCOMC__
#include <dos.h>
#include <mem.h>
#include <vqm32\mem.h>


/****************************************************************************
*
* NAME
*     DPMI_Lock - Lock a memory page.
*
* SYNOPSIS
*     DPMI_Lock(Address, Size)
*
*     void DPMI_Lock(void *, long);
*
* FUNCTION
*
* INPUTS
*     Address - Starting linear address of memory to lock.
*     Size    - Size of region to lock in bytes.
*
* RESULT
*     NONE
*
****************************************************************************/

void DPMI_Lock(void const *ptr, long const size)
{
	union REGS   regs;
	struct SREGS sregs;

	memset(&regs, 0, sizeof(REGS));
	segread(&sregs);

	/* Lock the memory page.
	 *
	 * AX    = 0x600
	 * BX:CX = Starting linear address of memory to lock.
	 * SI:DI = Size of region to lock in bytes.
	 */
	regs.x.eax = DPMI_LOCK;
	regs.x.ebx = ((long)ptr & 0xFFFF0000) >> 16;
	regs.x.ecx = ((long)ptr & 0x0000FFFF);
	regs.x.esi = ((long)size & 0xFFFF0000) >> 16;
	regs.x.edi = ((long)size & 0x0000FFFF);
	int386x(DPMI_INT, &regs, &regs, &sregs);
}


/****************************************************************************
*
* NAME
*     DPMI_Unlock - Unlock a locked memory page.
*
* SYNOPSIS
*     DPMI_Unlock(Address, Size)
*
*     void DPMI_Unlock(void *, long);
*
* FUNCTION
*
* INPUTS
*     Address - Starting linear address of memory to unlock.
*     Size    - Size of region to unlock in bytes.
*
* RESULT
*     NONE
*
****************************************************************************/

void DPMI_Unlock(void const *ptr, long const size)
{
	union REGS   regs;
	struct SREGS sregs;

	/* Unlock memory page. */
	memset(&regs, 0 ,sizeof(REGS));
	segread(&sregs);

	regs.x.eax = DPMI_UNLOCK;
	regs.x.ebx = ((long)ptr & 0xFFFF0000) >> 16;
	regs.x.ecx = ((long)ptr & 0x0000FFFF);
	regs.x.esi = ((long)size & 0xFFFF0000) >> 16;
	regs.x.edi = ((long)size & 0x0000FFFF);
	int386x(DPMI_INT, &regs, &regs, &sregs);
}

#endif /* __WATCOMC__ */
