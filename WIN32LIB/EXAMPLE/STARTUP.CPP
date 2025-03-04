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
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Library startup routine.						*
 *                                                                         *
 *                    File Name : STARTUP.CPP                              *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : July 14, 1994                            *
 *                                                                         *
 *                  Last Update : August 1, 1994   [SKB]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Prog_End -- Called to shutdown Westood's library.                     *
 *   main -- Programs main entry point.                                    *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "function.h"
#include <stdio.h>
#include <stdlib.h>

#define	GRAPHICS		TRUE
void *ShapeBuffer = NULL;


/***************************************************************************
 * MAIN -- Programs main entry point.                                      *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/01/1994 SKB : Created.                                             *
 *=========================================================================*/
#pragma argsused
WORD main(WORD argc, BYTE *argv[])
{
	void *fontptr;

	/*======================================================================*/
	/* Install page fault handle in case of fatal crash.						   */
	/*======================================================================*/
	  Install_Page_Fault_Handle ();

	/*======================================================================*/
	/* Setup the monochrome monitor for testing.										*/
	/*======================================================================*/

	MonoEnabled = (Find_Argv("-MONO") ? TRUE : FALSE);
	Mono_Clear_Screen();

	/*======================================================================*/
	/* Initialize the file data table.													*/
	/*======================================================================*/
	WWDOS_Init(200, NULL, NULL);

	/*======================================================================*/
	/* Initialize the system font.														*/
	/*======================================================================*/
#if GRAPHICS
	fontptr = Load_Font("STD6P.FNT");
	if (!fontptr)  {
		printf("Unable to load font.");
		exit(1);
	}
	Set_Font(fontptr);
#endif

	/*======================================================================*/
	/* Setup the timer system.																*/
	/*======================================================================*/
	if (Find_Argv("-NOTIME"))  {
		NoTimer = TRUE;
	} else {
		Init_Timer_System(USER_TIMER_FREQ);
		NoTimer = FALSE;
	}

	/*======================================================================*/
	/* Get the initial graphic mode.														*/
	/*======================================================================*/
#if GRAPHICS
	 if ( Set_Video_Mode(MCGA_MODE) == FALSE ) 
	 {
		printf("Unable to Set Graphic Mode\n");
		exit ( 0 ) ;
	 }
#endif


	/*======================================================================*/
	/* Now we get a keyboard handler.													*/
	/*======================================================================*/
	if (Find_Argv("-NOKEY")) {
		NoKeyBoard = TRUE;
	} else {
		NoKeyBoard = FALSE;
		Install_Keyboard_Interrupt(	Get_RM_Keyboard_Address(),	Get_RM_Keyboard_Size());

		ShapeBuffer = Alloc(5000, MEM_NORMAL);
		Set_Shape_Buffer(ShapeBuffer, 5000);
		Install_Mouse(20, 20, 320, 200);
	}

	/*======================================================================*/
	/* Give the game some variance.														*/
	/*======================================================================*/
	randomize();

	/*======================================================================*/
	/* Call the user main program.														*/
	/*======================================================================*/
	Main_Program(argc, argv);

	/*======================================================================*/
	/* Exit gracefully.																		*/
	/*======================================================================*/
	Prog_End();

	return(0);
}



/***************************************************************************
 * PROG_END -- Called to shutdown Westood's library.                       *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:  exit() should not be called until this has been called       *
 *                                                                         *
 * HISTORY:                                                                *
 *   08/01/1994 SKB : Created.                                             *
 *=========================================================================*/
VOID Prog_End(VOID)
{
	
	/*======================================================================*/
	/* Get rid of the keyboard handler.													*/
	/*======================================================================*/
	if (!NoKeyBoard) {
		Remove_Mouse();
		Free(ShapeBuffer);
		Remove_Keyboard_Interrupt();
	}

	/*======================================================================*/
	/* Get rid of the timer system.														*/
	/*======================================================================*/
	if (!NoTimer)  {
		Remove_Timer_System();
	}

	/*======================================================================*/
	/* Restore the Video mode.																*/
	/*======================================================================*/
#if GRAPHICS
	Set_Video_Mode(RESET_MODE);
#endif

	/*======================================================================*/
	/* Close down the file system.														*/
	/*======================================================================*/
	WWDOS_Shutdown();
}
