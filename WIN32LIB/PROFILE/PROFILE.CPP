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

/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Library profiler                                             *
 *                                                                                             *
 *                    File Name : PROFILE.CPP                                                  *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 11/17/95                                                     *
 *                                                                                             *
 *                  Last Update : November 20th 1995 [ST]                                      *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *  The profiler works by using the function prologue and epilogue hooks available in Watcom                                                                                           *
 *  to register the current functions address in a global variable and then sampling the                                                                                           *
 *  contents of the variable using a windows timer which runs at up to 1000 samples per second.                                                                       *
 *                                                                                             *
 *  Compile the code to be sampled with the -ep and -ee flags to enable the prologue (__PRO)                                                                                           *
 *  and epilogue (__EPI) calls to be generated.                                                                                           *
 *  At the beginning of the section to be profiled (just before main loop normally) call the                                                                                           *
 *  Start_Profiler function to start sampling. At the end of the section, call Stop_Profiler                                                                                           *
 *  which will stop the timer and write the profile data to disk in the PROFILE.BIN file.                                                                                           *
 *  Use                                                                                           *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *  Start_Profiler -- initialises the profiler data and starts gathering data                  *
 *  Stop_Profiler -- stops the timer and writes the profile data to disk                       *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#define WIN32
#ifndef _WIN32 // Denzil 6/2/98 Watcom 11.0 complains without this check
#define _WIN32
#endif // _WIN32
#include <windows.h>
#include <windowsx.h>

#include <wwstd.h>
#include <rawfile.h>
#include <file.h>
#include "profile.h"

extern "C"{
unsigned	ProfileList	[PROFILE_RATE*60*MAX_PROFILE_TIME];
unsigned	ProfilePtr;
}

extern "C" void Profiler_Callback ( UINT, UINT , DWORD, DWORD, DWORD );

unsigned	ProfilerEvent;

void Start_Profiler (void)
{
	memset (&ProfileList[0],-1,PROFILE_RATE*60*MAX_PROFILE_TIME*4);
	Copy_CHK();
	ProfilerEvent = timeSetEvent (1000/PROFILE_RATE , 1 , (void CALLBACK (UINT,UINT,DWORD,DWORD,DWORD))Profiler_Callback , 0 , TIME_PERIODIC);
}

void Stop_Profiler (void)
{
	if (ProfilerEvent){
		timeKillEvent(ProfilerEvent);
		ProfilerEvent=NULL;

		int handle = Open_File ( "profile.bin" , WRITE );
		if (handle != WW_ERROR){
			Write_File (handle , &ProfileList[0] , ProfilePtr*4);
			Close_File (handle);
		}
	}
}


