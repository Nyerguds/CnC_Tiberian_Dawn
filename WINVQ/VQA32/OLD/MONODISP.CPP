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
*     monodisp.c
*
* DESCRIPTION
*     Monochrome display (debug)
*
* PROGRAMMER
*     Bill Randolph
*     Denzil E. Long, Jr.
*
* DATE
*     April 6, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     VQA_InitMono   - Initialize the player's mono screen.
*     VQA_UpdateMono - Update the player's mono output.
*
****************************************************************************/

#include <stdio.h>
#include <string.h>
#include "vq.h"
#include "vqaplayp.h"
#include <vqm32\all.h>

#if(VQAMONO_ON)

/* Main window */
#define	MAIN_WX1   0
#define	MAIN_WX2   79
#define	MAIN_WY1   0
#define	MAIN_WY2   9
#define	MAIN_TITLE "VQA Player"

/* Loader data window */
#define	LOADER_WX1   0
#define	LOADER_WX2   39
#define	LOADER_WY1   10
#define	LOADER_WY2   20
#define	LOADER_TITLE " Frame Loader "

/* Drawer data window */
#define	DRAWER_WX1   40
#define	DRAWER_WX2   79
#define	DRAWER_WY1   10
#define	DRAWER_WY2   20
#define	DRAWER_TITLE " Frame Drawer "

/* Audio data window */
#define	AUDIO_WX1   0
#define	AUDIO_WX2   39
#define	AUDIO_WY1   21
#define	AUDIO_WY2   24
#define	AUDIO_TITLE " Audio Callback "

/* Flipper data window */
#define	FLIPPER_WX1   40
#define	FLIPPER_WX2   79
#define	FLIPPER_WY1   21
#define	FLIPPER_WY2   24
#define	FLIPPER_TITLE " Frame Flipper "

extern char *HMIDevName;


/****************************************************************************
*
* NAME
*     VQA_InitMono - Initialize the player's mono screen.
*
* SYNOPSIS
*     VQA_InitMono(VQA)
*
*     void VQA_InitMono(VQAHandleP *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to private VQA handle.
*
* RESULT
*     NONE
*
****************************************************************************/

#pragma argsused
void VQA_InitMono(VQAHandleP *vqap)
{
	VQAData   *vqabuf;
	VQAConfig *config;
	char      txt[80];

	/* Dereference commonly used data members of quick access. */
	vqabuf = vqap->VQABuf;
	config = &vqap->Config;

	/* Enable and clear the mono screen */
	Mono_Enable();
	Mono_Clear_Screen();

	/* Init main window */
	Mono_Draw_Rect(MAIN_WX1, MAIN_WY1, (MAIN_WX2 - MAIN_WX1 + 1),
			(MAIN_WY2 - MAIN_WY1 + 1), 2, 1);

	Mono_Set_Cursor((MAIN_WX2 + MAIN_WX1 - strlen(MAIN_TITLE)) / 2, MAIN_WY1);
	Mono_Print(MAIN_TITLE);

	/* Video mode */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 1);
	Mono_Print("Video Mode: ");

	switch (config->Vmode) {

		#if(VQAMONO_ON)
		case MCGA:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				Mono_Print("MCGA Buffered");
			} else {
				Mono_Print("MCGA Direct to screen");
			}
			break;
		#endif

		#if(VQAXMODE_ON)
		case XMODE_320X200:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				Mono_Print("XMODE 320x200 Buffered");
			} else {
				if (config->DrawFlags & VQACFGF_VRAMCB) {
					Mono_Print("XMODE 320x200 VRAM Copy");
				} else {
					Mono_Print("XMODE 320x200 Linear->Banked");
				}
			}
			break;

		case XMODE_320X240:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				Mono_Print("XMODE 320x240 Buffered");
			} else {
				if (config->DrawFlags & VQACFGF_VRAMCB) {
					Mono_Print("XMODE 320x240 VRAM Copy");
				} else {
					Mono_Print("XMODE 320x240 Linear->Banked");
				}
			}
			break;
		#endif

		#if(VQAVESA_ON)
		case VESA_640X480_256:
			Mono_Print("VESA 640x480");
			break;

		case VESA_320X200_32K_1:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				Mono_Print("VESA 320x200 Buffered");
			} else {
				Mono_Print("VESA 320x200 Direct to screen");
			}
			break;
		#endif

		default:
			Mono_Print("UNKNOWN");
			break;
	}

	/* Sound status */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 2);
	Mono_Print("               Sound: ");

	if (config->OptionFlags & VQAOPTF_AUDIO) {
		sprintf(txt,"%u Hz", config->AudioRate);
		Mono_Print(txt);
	}	else {
		Mono_Print("OFF");
	}

	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 3);
	Mono_Print("         Driver Name: ");
	Mono_Print(HMIDevName);

	/* Frame rates */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 4);
	sprintf(txt,"     Load Frame Rate: %d", config->FrameRate);
	Mono_Print(txt);

	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 5);
	sprintf(txt,"     Draw Frame Rate: %d", config->DrawRate);
	Mono_Print(txt);

	/* Slow palette */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 6);
	Mono_Print("        Slow palette: ");

	if (config->OptionFlags & VQAOPTF_SLOWPAL) {
		Mono_Print("ON");
	} else {
		Mono_Print("OFF");
	}

	/* Memory Usage */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 7);
	sprintf(txt,"         Memory Used: %ld", vqabuf->MemUsed);
	Mono_Print(txt);

	/* Timer Method */
	Mono_Set_Cursor(MAIN_WX1 + 18, MAIN_WY1 + 8);

	if (VQA_TimerMethod() == VQA_TMETHOD_DOS) {
		Mono_Print("           DOS Timer:");
	} else if (VQA_TimerMethod() == VQA_TMETHOD_INT) {
		Mono_Print("     Interrupt Timer:");
	} else if (VQA_TimerMethod() == VQA_TMETHOD_AUDIO) {
		Mono_Print("     Audio DMA Timer:");
	} else {
		Mono_Print("             Defualt:");
	}

	/* Init loader data window */
	Mono_Draw_Rect(LOADER_WX1, LOADER_WY1, (LOADER_WX2 - LOADER_WX1 + 1),
			(LOADER_WY2 - LOADER_WY1 + 1), 2, 1);

	Mono_Set_Cursor((LOADER_WX2 + LOADER_WX1 - strlen(LOADER_TITLE)) / 2,
			LOADER_WY1);

	Mono_Print(LOADER_TITLE);

	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY1 + 1);
	Mono_Print("  Current Frame #:");
	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY1 + 2);
	Mono_Print("# Waits on Drawer:");
	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY1 + 3);
	Mono_Print(" # Waits on Audio:");
	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY1 + 4);
	Mono_Print("       Frame Size:");
	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY1 + 5);
	Mono_Print("   Max Frame Size:");
	Mono_Set_Cursor(LOADER_WX1 + 2, LOADER_WY2 - 2);
	Mono_Print("Audio:");

	/* Init drawer data window */
	Mono_Draw_Rect(DRAWER_WX1, DRAWER_WY1, (DRAWER_WX2 - DRAWER_WX1 + 1),
			(DRAWER_WY2 - DRAWER_WY1 + 1), 2, 1);

	Mono_Set_Cursor((DRAWER_WX2 + DRAWER_WX1 - strlen(DRAWER_TITLE)) / 2,
			DRAWER_WY1);

	Mono_Print(DRAWER_TITLE);

	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 1);
	Mono_Print("   Current Frame #:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 2);
	Mono_Print("   Desired Frame #:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 3);
	Mono_Print("# Waits on Flipper:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 4);
	Mono_Print(" # Waits on Loader:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 5);
	Mono_Print("  # Frames Skipped:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY1 + 6);
	Mono_Print("     VQ Block Size:");
	Mono_Set_Cursor(DRAWER_WX1 + 2, DRAWER_WY2 - 2);
	Mono_Print("Frames:                 Cbooks:");

	/* Init audio data window */
	Mono_Draw_Rect(AUDIO_WX1, AUDIO_WY1, (AUDIO_WX2 - AUDIO_WX1 + 1),
			(AUDIO_WY2 - AUDIO_WY1 + 1), 2, 1);

	Mono_Set_Cursor((AUDIO_WX2 + AUDIO_WX1 - strlen(AUDIO_TITLE)) / 2,
			AUDIO_WY1);

	Mono_Print(AUDIO_TITLE);

	Mono_Set_Cursor(AUDIO_WX1 + 2, AUDIO_WY1 + 1);
	Mono_Print("# Repeated Buffers:");

	/* Init flipper data window */
	Mono_Draw_Rect(FLIPPER_WX1, FLIPPER_WY1, (FLIPPER_WX2 - FLIPPER_WX1 + 1),
			(FLIPPER_WY2 - FLIPPER_WY1 + 1), 2, 1);

	Mono_Set_Cursor((FLIPPER_WX2 + FLIPPER_WX1 - strlen(FLIPPER_TITLE)) / 2,
			FLIPPER_WY1);

	Mono_Print(FLIPPER_TITLE);

	Mono_Set_Cursor(FLIPPER_WX1 + 2, FLIPPER_WY1 + 1);
	Mono_Print("Current Frame #:");
}


/****************************************************************************
*
* NAME
*     VQA_UpdateMono - Update the player's mono output.
*
* SYNOPSIS
*     VQA_UpdateMono(VQA)
*
*     void VQA_UpdateMono(VQAHandleP *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to private VQA handle.
*
* RESULT
*     NONE
*
****************************************************************************/

#pragma argsused
void VQA_UpdateMono(VQAHandleP *vqap)
{
	VQAData       *vqabuf;
	VQAConfig     *config;
	VQAFrameNode  *frame;
	VQACBNode     *cbook;
	long          frameindex = -1;
	long          loadcb = -1;
	long          drawcb = -1;
	long          i;
	unsigned long curtime;
	char          txt[80];

	/* Dereference commonly used data members for quick access. */
	vqabuf = vqap->VQABuf;
	config = &vqap->Config;

	/* Timer value */
	curtime = VQA_GetTime(vqap);
	Mono_Set_Cursor(MAIN_WX1 + 40, MAIN_WY1 + 8);
	sprintf(txt,"%02ld:%02ld.%02ld",curtime / (VQA_TIMETICKS * VQA_TIMETICKS),
			curtime / VQA_TIMETICKS,((curtime * 100L) / VQA_TIMETICKS)
			-((curtime / VQA_TIMETICKS) * 100L));

	Mono_Print(txt);

	/* Loader data */
	Mono_Set_Cursor(LOADER_WX1 + 22, LOADER_WY1 + 1);
	sprintf(txt,"%4d",vqabuf->Loader.LastFrameNum);
	Mono_Print(txt);

	Mono_Set_Cursor(LOADER_WX1 + 22, LOADER_WY1 + 2);
	sprintf(txt,"%4ld",vqabuf->Loader.WaitsOnDrawer);
	Mono_Print(txt);

	Mono_Set_Cursor(LOADER_WX1 + 22, LOADER_WY1 + 3);
	sprintf(txt,"%4ld",vqabuf->Loader.WaitsOnAudio);
	Mono_Print(txt);

	Mono_Set_Cursor(LOADER_WX1 + 22, LOADER_WY1 + 4);
	sprintf(txt,"%5u",vqabuf->Loader.FrameSize);
	Mono_Print(txt);

	Mono_Set_Cursor(LOADER_WX1 + 22, LOADER_WY1 + 5);
	sprintf(txt,"%5u",vqabuf->Loader.MaxFrameSize);
	Mono_Print(txt);

	#if(VQAAUDIO_ON)
	/* Draw a picture of the audio buffers */
	for (i = 0; i < vqabuf->Audio.NumAudBlocks; i++) {
		if (vqabuf->Audio.IsLoaded[i] == 0) {
			txt[i] = '_';
		} else {
			txt[i] = 'X';
		}
	}

	txt[i] = 0;
	Mono_Set_Cursor(LOADER_WX1 + 9,LOADER_WY2 - 2);
	Mono_Print(txt);

	Mono_Set_Cursor(LOADER_WX1 + 9,LOADER_WY2-1); 
	Mono_Print("                        ");

	Mono_Set_Cursor(LOADER_WX1 + 9 + vqabuf->Audio.PlayPosition
			/ config->HMIBufSize,LOADER_WY2 - 1);

	Mono_Print("P");

	Mono_Set_Cursor(LOADER_WX1 + 9 + vqabuf->Audio.AudBufPos
			/ config->HMIBufSize,LOADER_WY2 - 1);

	Mono_Print("L");
	#endif /* VQAAUDIO_ON */

	/* Drawer data */
	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 1);
	sprintf(txt,"%4d", vqabuf->Drawer.LastFrameNum);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 2);
	sprintf(txt,"%4d", vqabuf->Drawer.DesiredFrame);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 3);
	sprintf(txt,"%4ld", vqabuf->Drawer.WaitsOnFlipper);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 4);
	sprintf(txt,"%4ld", vqabuf->Drawer.WaitsOnLoader);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 5);
	sprintf(txt,"%4d", vqabuf->Drawer.NumSkipped);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 22,DRAWER_WY1 + 6);
	sprintf(txt," %dx%d", vqap->Header.BlockWidth, vqap->Header.BlockHeight);
	Mono_Print(txt);

	/* Draw a picture of the frame buffers */
	frame = vqabuf->FrameData;

	for (i = 0; i < config->NumFrameBufs; i++) {
		if (frame->Flags & VQAFRMF_LOADED) {
			txt[i] = 'X';
		} else {
			txt[i] = '_';
		}

		if (vqabuf->Flipper.CurFrame == frame) {
			frameindex = i;
		}

		frame = frame->Next;
	}

	txt[i] = 0;
	Mono_Set_Cursor(DRAWER_WX1 + 10,DRAWER_WY2 - 2);
	Mono_Print(txt);

	Mono_Set_Cursor(DRAWER_WX1 + 10,DRAWER_WY2 - 1);
	Mono_Print("              ");

	Mono_Set_Cursor(DRAWER_WX1 + 10 + frameindex,DRAWER_WY2 - 1);
	Mono_Print("^");

	/* Draw a picture of the codebook buffers */
	cbook = vqabuf->CBData;

	for (i = 0; i < config->NumCBBufs; i++) {
		if (vqabuf->Loader.CurCB == cbook) {
			loadcb = i;
		}

		if (vqabuf->Flipper.CurFrame->Codebook == cbook) {
			drawcb = i;
		}

		cbook = cbook->Next;
	}

	Mono_Set_Cursor(DRAWER_WX1 + 34,DRAWER_WY2 - 2);
	Mono_Print("___");

	Mono_Set_Cursor(DRAWER_WX1 + 34,DRAWER_WY2 - 1);
	Mono_Print("   ");

	Mono_Set_Cursor(DRAWER_WX1 + 34 + loadcb,DRAWER_WY2 - 1);
	Mono_Print("L");

	Mono_Set_Cursor(DRAWER_WX1 + 34 + drawcb,DRAWER_WY2 - 1);
	Mono_Print("D");

	/* Audio data */
	#if(VQAAUDIO_ON)
	Mono_Set_Cursor(AUDIO_WX1 + 22, AUDIO_WY1 + 1);
	sprintf(txt,"%4ld", vqabuf->Audio.NumSkipped);
	Mono_Print(txt);
	#endif

	/* Flipper data */
	Mono_Set_Cursor(FLIPPER_WX1 + 22,FLIPPER_WY1 + 1);
	sprintf(txt,"%4d", vqabuf->Flipper.LastFrameNum);
	Mono_Print(txt);
	Mono_Set_Cursor(0,0);
}

#endif /* VQAMONO_ON */

