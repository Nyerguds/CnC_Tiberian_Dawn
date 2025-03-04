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
 *                    File Name : WPROFILE.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 11/17/95                                                     *
 *                                                                                             *
 *                  Last Update : November 20th 1995 [ST]                                      *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *                                                                                             *
 *  New System                                                                                 *
 * ~~~~~~~~~~~                                                                                 *
 *                                                                                             *
 *  The new profiler system creates a seperate thread and then starts a timer off there. The   *
 *  timer in the second thread uses GetThreadContext to sample the IP address of each user     *
 *  thread. This system has the advantage of being able to sample what is happening in all the *
 *  threads we own not just the main thread. Another advantage is that it doesnt require a     *
 *  major recompilation.                                                                       *
 *  The disadvantage is that we dont really know what is going on when the IP is outside the   *
 *  scope of our threads - We could be in direct draw, direct sound or even something like the *
 *  VMM and there is no way to tell.                                                           *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 *  Old System                                                                                 *
 * ~~~~~~~~~~~                                                                                 *
 *                                                                                             *
 *  The profiler works by using the function prologue and epilogue hooks available in Watcom   *
 *  to register the current functions address in a global variable and then sampling the       *
 *  contents of the variable using a windows timer which runs at up to 1000 samples per second.*
 *                                                                                             *
 *  Compile the code to be sampled with the -ep and -ee flags to enable the prologue (__PRO)   *
 *  and epilogue (__EPI) calls to be generated.                                                *
 *  At the beginning of the section to be profiled (just before main loop normally) call the   *
 *  Start_Profiler function to start sampling. At the end of the section, call Stop_Profiler   *
 *  which will stop the timer and write the profile data to disk in the PROFILE.BIN file.      *
 *                                                                                             *
 *  Use PROFILE.EXE to view the results of the session.                                        *
 *                                                                                             *
 *  The addition of prologue and epilogue code will slow down the product and the profiler     *
 *  allocates a huge buffer for data so it should not be linked in unless it is going to be    *
 *  used.                                                                                      *
 *                                                                                             *
 *  The advantage of the prologue/epilogue approach is that all samples represent valid        *
 *  addresses within our code so we get valid results we can use even when the IP is in system *
 *  code.                                                                                      *
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
#include <vdmdbg.h>
#include <timer.h>

#define PROFILE

extern "C"{
#ifdef PROFILE
unsigned	ProfileList	[PROFILE_RATE*MAX_PROFILE_TIME];
#else
unsigned	ProfileList	[2];
#endif
unsigned	ProfilePtr;
}

extern "C" void Old_Profiler_Callback ( UINT, UINT , DWORD, DWORD, DWORD );
extern "C" void New_Profiler_Callback (void);
extern "C" {
	extern unsigned ProfileFunctionAddress;
}

unsigned long	ProfilerEvent;		//Handle for profiler callback
unsigned long	ProfilerThread;	//Handle for profiler thread


HANDLE		CCThreadHandle;
CONTEXT	ThreadContext;


#if (PROFILE_SYSTEM == NEW_PROFILE_SYSTEM)

/***********************************************************************************************
 * Thread_Callback -- gets the IP address of our thread and registers it                       *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Windows timer callback parms - not used                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/2/96 6:37AM ST : Created                                                               *
 *=============================================================================================*/

void CALLBACK Thread_Callback (UINT,UINT,DWORD,DWORD,DWORD)
{
	ThreadContext.ContextFlags = VDMCONTEXT_CONTROL;
	if (!InTimerCallback){
		GetThreadContext ( CCThreadHandle , &ThreadContext );
	}else{
		GetThreadContext (TimerThreadHandle , &ThreadContext);
	}

	ProfileFunctionAddress = ThreadContext.Eip;
	New_Profiler_Callback();
}


/***********************************************************************************************
 * Profile_Thread -- this is the thread our profiler runs in. It just starts off a timer and   *
 *                   then buggers off into an infinite message loop. We shouldnt get messages  *
 *                   here as this isnt our primary thread                                      *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/2/96 6:39AM ST : Created                                                               *
 *=============================================================================================*/
void Profile_Thread (void)
{
	MSG msg;
	ProfilerEvent = timeSetEvent (1000/PROFILE_RATE , 1 , Thread_Callback , 0 , TIME_PERIODIC);
	//ProfilerEvent = timeSetEvent (100 , 1 , Thread_Callback , 0 , TIME_ONESHOT);
	do  {
		GetMessage(&msg,NULL,0,0);
	} while(1);
}

#endif //(PROFILE_SYSTEM == OLD_PROFILE_SYSTEM)


/***********************************************************************************************
 * Start_Profiler -- initialises the profiler system and starts sampling                       *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: There may be a pause when sampling starts as Win95 does some VMM stuff            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:12PM ST : Created                                                             *
 *=============================================================================================*/

void __cdecl Start_Profiler (void)
{
#ifdef PROFILE
	if (!ProfilerEvent){
		memset (&ProfileList[0],-1,PROFILE_RATE*MAX_PROFILE_TIME*4);
	}

	Profile_Init();

	if (!ProfilerEvent){

#if (PROFILE_SYSTEM == OLD_PROFILE_SYSTEM)
		/*
		** Old profile system - just set up a timer to monitor the global variable based on
		** the last place __PRO was called from
		*/
		ProfilerEvent = timeSetEvent (1000/PROFILE_RATE , 1 , (void CALLBACK (UINT,UINT,DWORD,DWORD,DWORD))Old_Profiler_Callback , 0 , TIME_PERIODIC);
#else
		/*
		** New profile system - create a second thread that will do all the profiling
		** using GetThreadContext
		*/
		if ( DuplicateHandle( GetCurrentProcess(), GetCurrentThread() , GetCurrentProcess() ,&CCThreadHandle , 0 , TRUE , DUPLICATE_SAME_ACCESS) ){
			ProfilerEvent= (unsigned)CreateThread(NULL,2048,(LPTHREAD_START_ROUTINE)&Profile_Thread,NULL,0,&ProfilerThread);
		}
#endif

	}

#else
	ProfilerEvent = 0;
#endif

}



/***********************************************************************************************
 * Stop_Profiler -- stops the sampling timer and writes the colledted data to disk             *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: Writes to file PROFILE.BIN                                                        *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:13PM ST : Created                                                             *
 *=============================================================================================*/

void __cdecl Stop_Profiler (void)
{
	if (ProfilerEvent){

#if (PROFILE_SYSTEM == OLD_PROFILE_SYSTEM)
		//
		// Old system - just remove the timer event
		//
		timeKillEvent(ProfilerEvent);
#else
		//
		// New system - kill the profiling thread
		//
		TerminateThread((HANDLE)ProfilerThread,0);
#endif

		ProfilerEvent=NULL;

		Profile_End();

		int handle = Open_File ( "profile.bin" , WRITE );
		if (handle != WW_ERROR){
			Write_File (handle , &ProfileList[0] , ProfilePtr*4);
			Close_File (handle);
		}
	}
}


