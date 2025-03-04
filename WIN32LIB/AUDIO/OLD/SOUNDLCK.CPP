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

/***************************************************************************
 **      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood 32 bit Library                  *
 *                                                                         *
 *                    File Name : SOUNDLCK.CPP                             *
 *                                                                         *
 *                   Programmer : Phil W. Gorrow                           *
 *                                                                         *
 *                   Start Date : June 23, 1995                            *
 *                                                                         *
 *                  Last Update : June 23, 1995   [PWG]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef _WIN32 // Denzil 6/2/98 Watcom 11.0 complains without this check
#define _WIN32
#endif // _WIN32
#define WIN32
#include <windows.h>
#include <windowsx.h>
#include <objbase.h>
#include "dsound.h"
#include <mem.h>
#include "wwmem.h"
#include "wwstd.h"
#include "soundint.h"



LockedDataType LockedData;

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

/***************************************************************************
 * INIT_LOCKED_DATA -- Initializes sound driver locked data                *
 *                                                                         *
 * INPUT:		none                                                          *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/23/1995 PWG : Created.                                             *
 *=========================================================================*/
void Init_Locked_Data(void)
{

	/*
	** Initialize all of the data elements that need to be locked.
	*/
	LockedData.DigiHandle			= -1;
	LockedData.ServiceSomething	= FALSE;
	LockedData.MagicNumber			= 0xDEAF;
	LockedData.UncompBuffer			= NULL;
//	LockedData.StreamBufferSize	= (2*SECONDARY_BUFFER_SIZE)+128;
	LockedData.StreamBufferSize	= (SECONDARY_BUFFER_SIZE/4)+128;
	LockedData.StreamBufferCount	= 16;
	LockedData.SoundVolume			= 255;
	LockedData.ScoreVolume			= 255;
	LockedData._int					= FALSE;

	#ifdef cuts
	/*
	** Lock the sound specific c functions that will cause us problems if
	** they are swapped out during an interrupt.
	*/
	DPMI_Lock(&LockedData,							4096L);
	DPMI_Lock(Simple_Copy, 							4096L);
	DPMI_Lock(Sample_Copy, 							4096L);
	DPMI_Lock((void *)maintenance_callback, 	4096L);
	DPMI_Lock((void *)DigiCallback, 				4096L);
	DPMI_Lock((void *)HMI_TimerCallback, 		4096L);
	DPMI_Lock(Audio_Add_Long_To_Pointer,		4096L);
	DPMI_Lock(DPMI_Unlock,							4096L);

	/*
	** Lock the library functions that will cause us problems if they are
	** swapped out during an interrupt.
	*/
	DPMI_Lock(Mem_Copy,								4096L);
	DPMI_Lock(Audio_Mem_Set,						4096L);
	DPMI_Lock(__GETDS,								4096L);

	/*
	** Finally lock the two assembly modules that need locking.  This can
	** be handled by calling the lock function that is local to thier module
	** swapped out during an interrupt.
	*/
	Decompress_Frame_Lock();
	sosCODEC_Lock();

	#endif	//cuts
}

