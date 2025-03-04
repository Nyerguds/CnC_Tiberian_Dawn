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
*----------------------------------------------------------------------------
*
* PROJECT
*     VQA player library. (32-Bit protected mode)
*
* FILE
*     task.c
*
* DESCRIPTION
*     Loading and drawing delegation
*
* PROGRAMMER
*     Bill Randolph
*     Denzil E. Long, Jr.
*
* DATE
*     July 25, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     VQA_Alloc    - Allocate a VQAHandle to use.
*     VQA_Free     - Free a VQAHandle.
*     VQA_Init     - Initialize the VQAHandle IO.
*     VQA_Play     - Play the VQA movie.
*     VQA_SetStop  - Set the frame the player should stop on.
*     VQA_GetInfo  - Get VQA movie information.
*     VQA_GetStats - Get VQA movie statistics.
*     VQA_Version  - Get VQA library version number.
*     VQA_IDString - Get the VQA player library's ID string.
*
* PRIVATE
*     VQA_IO_Task        - Loader task for multitasking.
*     VQA_Rendering_Task - Drawer task for multitasking.
*     User_Update        - Page flip routine called by the task interrupt.
*
****************************************************************************/

#include <stdio.h>
#include <malloc.h>
#include <dos.h>
#include <mem.h>
#include <conio.h>
#include <sys\timeb.h>
#include <vqm32\all.h>
#include "vqaplayp.h"
#include <vqm32\font.h>

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

/* Externals */
#ifdef __cplusplus
extern "C" {
#endif

extern int __cdecl Check_Key(void);
extern int __cdecl Get_Key(void);

#ifdef __cplusplus
}
#endif


/****************************************************************************
*
* NAME
*     VQA_Alloc - Allocate a VQAHandle to use.
*
* SYNOPSIS
*     VQAHandle = VQA_Alloc()
*
*     VQAHandle *VQA_Alloc(void);
*
* FUNCTION
*     Obtain a VQAHandle. This handle is used by most VQA library functions,
*     and contains the current position in the file. This is the only legal
*     way to obtain a VQAHandle.
*
* INPUTS
*     NONE
*
* RESULT
*     VQA - Handle of a VQA.
*
****************************************************************************/

VQAHandle *VQA_Alloc(void)
{
	VQAHandleP *vqa;

	if ((vqa = (VQAHandleP *)malloc(sizeof(VQAHandleP))) != NULL) {
		memset(vqa, 0, sizeof(VQAHandleP));
	}

	return ((VQAHandle *)vqa);
}


/****************************************************************************
*
* NAME
*     VQA_Free - Free a VQAHandle.
*
* SYNOPSIS
*     VQA_Free(VQA)
*
*     void VQA_Free(VQAHandle *);
*
* FUNCTION
*     Dispose of a VQAHandle. This is the only legal way to dispose of a
*     VQAHandle.
*
* INPUTS
*     VQA - Pointer to VQAHandle to dispose of.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_Free(VQAHandle *vqa)
{
	if (vqa) free(vqa);
}


/****************************************************************************
*
* NAME
*     VQA_Init - Initialize the VQAHandle IO handler.
*
* SYNOPSIS
*     VQA_Init(VQA, IOHandler)
*
*     void VQA_Init(VQAHandle *, IOHandler *);
*
* FUNCTION
*     Initialize the specified VQAHandle IO with the client provided custom
*     IO handler.
*
* INPUTS
*     VQA       - Pointer to VQAHandle to initialize.
*     IOHandler - Pointer to custom file I/O handler function.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_Init(VQAHandle *vqa, long(*iohandler)(VQAHandle *vqa, long action,
		void *buffer, long nbytes))
{
	((VQAHandleP *)vqa)->IOHandler = iohandler;
}


/****************************************************************************
*
* NAME
*     VQA_Reset - Reset the VQAHandle.
*
* SYNOPSIS
*     VQA_Reset(VQA)
*
*     void VQA_Reset(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - VQAHandle to reset.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_Reset(VQAHandle *vqa)
{
	VQAData *vqabuf;

	/* Dereference data members for quick access */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;

	vqabuf->Flags = 0;
	vqabuf->LoadedFrames = 0;
	vqabuf->DrawnFrames = 0;
	vqabuf->StartTime = 0;
	vqabuf->EndTime = 0;
}


/****************************************************************************
*
* NAME
*     VQA_Play - Play the VQA movie.
*
* SYNOPSIS
*     Error = VQA_Play(VQA, Mode)
*
*     long VQA_Play(VQAHandle *, long);
*
* FUNCTION
*     Playback the movie associated with the specified VQAHandle.
*
* INPUTS
*     VQA  - Pointer to handle of movie to play.
*     Mode - Playback mode.
*              VQAMODE_RUN   - Run the movie until completion.
*              VQAMODE_WALK  - Walk the movie frame by frame.
*              VQAMODE_PAUSE - Pause the movie.
*              VQAMODE_STOP  - Stop the movie (Shutdown).
*
* RESULT
*     Error - 0 if successful, or error code.
*
****************************************************************************/

long VQA_Play(VQAHandle *vqa, long mode)
{
	VQAData   *vqabuf;
	VQAConfig *config;
	VQADrawer *drawer;
	long      rc;
	long      i;
	long      key;

	/* Dereference commonly used data members for quick access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;
	config = &((VQAHandleP *)vqa)->Config;

	/* One time player priming. */
	if (!(vqabuf->Flags & VQADATF_PRIMED)) {

		/* Init the Drawer's configuration */
		VQA_Configure_Drawer((VQAHandleP *)vqa);

		/* If audio enabled & loaded, start playing */
		#if(VQAAUDIO_ON)
		if ((config->OptionFlags & VQAOPTF_AUDIO) && vqabuf->Audio.IsLoaded[0]) {
			VQA_StartAudio((VQAHandleP *)vqa);
		}
		#endif

		/* Initialize the timer */
		i = ((vqabuf->Drawer.CurFrame->FrameNum * VQA_TIMETICKS)
				/ config->DrawRate);

		VQA_SetTimer((VQAHandleP *)vqa, i, config->TimerMethod);
		vqabuf->StartTime = VQA_GetTime((VQAHandleP *)vqa);

		/* Set up the Mono screen */
		#if(VQAMONO_ON)
		if (config->OptionFlags & VQAOPTF_MONO) {
			VQA_InitMono((VQAHandleP *)vqa);
		}
		#endif

		/* Priming is complete. */
		vqabuf->Flags |= VQADATF_PRIMED;
	}

	/* Main Player Loop */
	switch (mode) {
		case VQAMODE_PAUSE:
			if ((vqabuf->Flags & VQADATF_PAUSED) == 0) {
				vqabuf->Flags |= VQADATF_PAUSED;
				vqabuf->EndTime = VQA_GetTime((VQAHandleP *)vqa);

				/* Stop the audio while the movie is paused. */
				#if(VQAAUDIO_ON)
				if (vqabuf->Audio.Flags & VQAAUDF_ISPLAYING) {
					VQA_StopAudio((VQAHandleP *)vqa);
				}
				#endif
			}

			rc = VQAERR_PAUSED;
			break;

		case VQAMODE_RUN:
		case VQAMODE_WALK:
		default:

			/* Start up the movie if is it currently paused. */
			if (vqabuf->Flags & VQADATF_PAUSED) {
				vqabuf->Flags &= ~VQADATF_PAUSED;

				/* Start the audio if it was previously on. */
				#if(VQAAUDIO_ON)
				if (config->OptionFlags & VQAOPTF_AUDIO) {
					VQA_StartAudio((VQAHandleP *)vqa);
				}
				#endif

				VQA_SetTimer((VQAHandleP *)vqa, vqabuf->EndTime, config->TimerMethod);
			}

			/* Load, Draw, Load, Draw, Load, Draw ... */
			while ((vqabuf->Flags & (VQADATF_DDONE|VQADATF_LDONE))
					!= (VQADATF_DDONE|VQADATF_LDONE)) {

				/* Load a frame */
				if (!(vqabuf->Flags & VQADATF_LDONE)) {
					if ((rc = VQA_LoadFrame(vqa)) == 0) {
						vqabuf->LoadedFrames++;
					}
					else if ((rc != VQAERR_NOBUFFER) && (rc != VQAERR_SLEEPING)) {
						vqabuf->Flags |= VQADATF_LDONE;
						rc = 0;
					}
				}

				/* Draw a frame */
				if ((config->DrawFlags & VQACFGF_NODRAW) == 0) {
					if ((rc = (*(vqabuf->Draw_Frame))(vqa)) == 0) {
						vqabuf->DrawnFrames++;
						rc = vqabuf->Drawer.LastFrameNum;

						if (User_Update(vqa)) {
							vqabuf->Flags |= (VQADATF_DDONE|VQADATF_LDONE);
						}
					}
					else if ((vqabuf->Flags & VQADATF_LDONE)
							&& (rc == VQAERR_NOBUFFER)) {
						vqabuf->Flags |= VQADATF_DDONE;
					}
				} else {
					vqabuf->Flags |= VQADATF_DDONE;
					drawer->CurFrame->Flags = 0L;
					drawer->CurFrame = drawer->CurFrame->Next;
				}

				/* Update Mono output */
				#if(VQAMONO_ON)
				if (config->OptionFlags & VQAOPTF_MONO) {
					VQA_UpdateMono((VQAHandleP *)vqa);
				}
				#endif

				if (mode == VQAMODE_WALK) {
					break;
				}
				#if(VQASTANDALONE)
				else {

					/* Do single-stepping check. */
					if (config->OptionFlags & VQAOPTF_STEP) {
						while ((key = Check_Key()) == 0);
						Get_Key();

						/* Escape key still quits. */
						if (key == 27) {
							break;
						}
					}

					/* Check for ESC */
					if ((key = Check_Key()) != 0) {
						mode = VQAMODE_STOP;
						break;
					}
				}
				#endif
			}
			break;
	}

	/* If the movie is finished or we are requested to stop then shutdown. */
	if (((vqabuf->Flags & (VQADATF_DDONE|VQADATF_LDONE))
			== (VQADATF_DDONE|VQADATF_LDONE)) || (mode == VQAMODE_STOP)) {

		/* Record the end time; must be done before stopping audio, since we're
		 * getting the elapsed time from the audio DMA position.
		 */
		vqabuf->EndTime = VQA_GetTime((VQAHandleP *)vqa);

		/* Stop audio, if it's playing. */
		#if(VQAAUDIO_ON)
		if (vqabuf->Audio.Flags & VQAAUDF_ISPLAYING) {
			VQA_StopAudio((VQAHandleP *)vqa);
		}
		#endif

		/* Movie is finished. */
		rc = VQAERR_EOF;
	}

	return (rc);
}


/****************************************************************************
*
* NAME
*     VQA_SetStop - Set the frame the player should stop on.
*
* SYNOPSIS
*     OldStop = VQA_SetStop(VQA, Frame)
*
*     long = VQA_SetStop(VQAHandle *, long);
*
* FUNCTION
*     Set the frame that the player should stop on. This function will only
*     work on movies that are already open.
*
* INPUTS
*     VQA   - VQAHandle of movie to set the stop frame for.
*     Frame - Frame number to stop on.
*
* RESULT
*     OldStop - Previous stop frame. (-1 = invalid stop frame)
*
****************************************************************************/

long VQA_SetStop(VQAHandle *vqa, long stop)
{
	long      oldstop = -1;
	VQAHeader *header;

	/* Get a local pointer to the header. */
	header = &((VQAHandleP *)vqa)->Header;

	if ((stop > 0) && (header->Frames >= stop)) {
		oldstop = header->Frames;
		header->Frames = stop;
	}

	return (oldstop);
}


/****************************************************************************
*
* NAME
*     VQA_GetInfo - Get VQA movie information.
*
* SYNOPSIS
*     VQA_GetInfo(VQA, Info)
*
*     void VQA_GetInfo(VQAHandle *, VQAInfo *);
*
* FUNCTION
*     Retrieve information about the opened movie.
*
* INPUTS
*     VQA  - Pointer to VQAHandle of opened movie.
*     Info - Pointer to VQAInfo structure to fill.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_GetInfo(VQAHandle *vqa, VQAInfo *info)
{
	VQAHeader *header;

	/* Dereference header structure. */
	header = &((VQAHandleP *)vqa)->Header;

	info->NumFrames = header->Frames;
	info->ImageHeight = header->ImageHeight;
	info->ImageWidth = header->ImageWidth;
	info->ImageBuf = ((VQAHandleP *)vqa)->VQABuf->Drawer.ImageBuf;
}


/****************************************************************************
*
* NAME
*     VQA_GetStats - Get VQA movie statistics.
*
* SYNOPSIS
*     VQA_GetStats(VQA, Stats)
*
*     void VQA_GetStats(VQAHandle *, VQAStatistics *);
*
* FUNCTION
*     Retrieve the statistics for the VQA movie.
*
* INPUTS
*     VQA   - Handle of VQA movie to get statistics for.
*     Stats - Pointer to VQAStatistics to fill.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_GetStats(VQAHandle *vqa, VQAStatistics *stats)
{
	VQAData *vqabuf;

	/* Dereference VQAData structure from VQAHandle */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;

	stats->MemUsed = vqabuf->MemUsed;
	stats->StartTime = vqabuf->StartTime;
	stats->EndTime = vqabuf->EndTime;
	stats->FramesLoaded = vqabuf->LoadedFrames;
	stats->FramesDrawn = vqabuf->DrawnFrames;
	stats->FramesSkipped = vqabuf->Drawer.NumSkipped;
	stats->MaxFrameSize = vqabuf->Loader.MaxFrameSize;

	#if(VQAAUDIO_ON)
	stats->SamplesPlayed = vqabuf->Audio.SamplesPlayed;
	#else
	stats->SamplesPlayed = 0;
	#endif
}


/****************************************************************************
*
* NAME
*     VQA_Version - Get VQA library version number.
*
* SYNOPSIS
*     Version = VQA_Version()
*
*     char *VQA_Version(void);
*
* FUNCTION
*     Return the version of the VQA player library.
*
* INPUTS
*     NONE
*
* RESULT
*     Version - Pointer to version number string.
*
****************************************************************************/

char *VQA_Version(void)
{
	return(VQA_VERSION);
}


/****************************************************************************
*
* NAME
*     VQA_IDString - Get the VQA player library's ID string.
*
* SYNOPSIS
*     IDString = VQA_IDString()
*
*     char *VQA_IDString(void);
*
* FUNCTION
*     Return the ID string of this VQA player library.
*
* INPUTS
*     NONE
*
* RESULT
*     IDString - Pointer to ID string.
*
****************************************************************************/

char *VQA_IDString(void)
{
	return (VQA_IDSTRING);
}


/****************************************************************************
*
* NAME
*     User_Update - Page flip routine called by the task interrupt.
*
* SYNOPSIS
*     User_Update(VQA)
*
*     long User_Update(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Handle of VQA movie.
*
* RESULT
*     NONE
*
****************************************************************************/

long User_Update(VQAHandle *vqa)
{
	VQAData *vqabuf;
	long    rc = 0;

	/* Dereference data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;

	if (vqabuf->Flags & VQADATF_UPDATE) {

		/* Invoke the page flip routine */
		rc = (*(vqabuf->Page_Flip))(vqa);

		/* Update data for mono output */
		vqabuf->Flipper.LastFrameNum = vqabuf->Flipper.CurFrame->FrameNum;

		/* Mark the frame as loadable */
		vqabuf->Flipper.CurFrame->Flags = 0L;
		vqabuf->Flags &= (~VQADATF_UPDATE);
	}

	return (rc);
}

void VQA_Dummy(void)
{
	Set_Font(NULL);
}
