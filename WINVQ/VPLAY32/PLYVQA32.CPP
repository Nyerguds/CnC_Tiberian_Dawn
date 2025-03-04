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
* PROJECT
*     VQA stand-alone player. (32Bit protected mode)
*
* FILE
*     Plyvqa32.c
*
* DESCRIPTION
*     This program is a stand-alone VQA Player, as well as an example of how
*     to incorporate VQAPlay into a program.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     July 7, 1995
*
*----------------------------------------------------------------------------
*
* FUNCTIONS
*     main             - Standard 'C' entry point.
*     Usage            - Display usage information.
*     Options          - Parse user options.
*     Find_File_Name   - Find a filename on the command line.
*     Print_Play_Stats - Print player statistics.
*     Check_Key        - Check keyboard for keypress.
*     Get_Key          - Get a key from the keyboard buffer.
*     HardErr_Handler  - Hardware error handle.
*
****************************************************************************/

#define CAPTIONS 0

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <sys\timeb.h>
#include <mem.h>
#include <io.h>
#include <ctype.h>
#include <process.h>
#include <dos.h>

#include <vqa32\vqaplay.h>
#include <vqa32\vqafile.h>
#include <vqm32\all.h>

#if(CAPTIONS)
#include <vqm32\font.h>
#endif

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

long OutputStats = 0;
long OutputTime = 0;
long LastKey;

/* Embedded version string */
char VerTag[] = {"$VER$VQAPlay 2.6 (07/07/95) 32Bit"};
char ReqTag[] = {"$REQ$VQA32 Version 2.37 & VQM32 Version 2.11 or better."};

/* Prototypes */
void main(long argc, char **argv);
static void Usage(long showall);
static void Options(long argc, char *argv[], VQAConfig *config);
static char *Find_File_Name(long argc, char *argv[], char *desired_ext);
static char *GetFilePart(char *path);
void Print_Play_Stats(VQAConfig *config, VQAStatistics *stats);
long VQCallback(unsigned char *screen, long framenum);

#ifdef __cplusplus
extern "C" {
#endif

int __cdecl Check_Key(void);
int __cdecl Get_Key(void);

#ifdef __cplusplus
}
#endif

#ifndef __WATCOMC__
#if(0)
int HardErr_Handler(int errval, int ax, int bp, int si);
#endif
#else
int __far HardErr_Handler(unsigned deverror, unsigned errcode,
		unsigned __far *devhdr);
#endif


/****************************************************************************
*
* NAME
*     main - Standard 'C' entry point.
*
* SYNOPSIS
*     main(ArgC, ArgV)
*
*     void main(short, char *[]);
*
* FUNCTION
*     Initial 'C' user-routine called by startup code.
*
* INPUTS
*     ArgC - Argument count, number of arguments passed in.
*     ArgV - Argument array, pointers to arguments.
*
* RESULT
*     NONE
*
****************************************************************************/

void main(long argc, char **argv)
{
	VQAConfig     myconfig;
	VQAStatistics stats;
	VQAHandle     *vqa;
	char          *name;
	long          i;

	/* Parse command-line */
	if (argc < 2) {
		Usage(1);
		exit(0);
	}

	/* Get filename */
	name = Find_File_Name(argc, argv, ".VQA");

	if (name == NULL) {
		Usage(1);
		exit(0);
	}

	/*-------------------------------------------------------------------------
	 * INITIALIZE PLAYBACK CONFIGURATION
	 *-----------------------------------------------------------------------*/
	VQA_DefaultConfig(&myconfig);
	myconfig.HMIBufSize = 2048*2;

	#if(CAPTIONS)
	myconfig.CapFont = (char *)Load_Font("caption.fnt");
	myconfig.OptionFlags |= VQAOPTF_CAPTIONS;
	Set_Font(myconfig.CapFont);
	SetDAC(251,255,255,255); // WHITE
	SetDAC(252,255,000,000); // RED
	SetDAC(253,000,255,000); // GREEN
	SetDAC(254,0,0,0);
	SetDAC(255,255,000,255); // CYCLE
	#endif

	/* Configure player with command-line */
	Options(argc, argv, &myconfig);

	/*-------------------------------------------------------------------------
	 * INSTALL THE CUSTOM CRITICAL ERROR HANDLER
	 *-----------------------------------------------------------------------*/
	#ifndef __WATCOMC__
	#if(0)
	harderr(HardErr_Handler);
	#endif
	#else
	_harderr(HardErr_Handler);
	#endif

	/*-------------------------------------------------------------------------
	 * SET THE VIDEO MODE AND VBI POLARITY BIT
	 *-----------------------------------------------------------------------*/
	SetVideoMode(myconfig.Vmode);
	myconfig.VBIBit = GetVBIBit();

	/*-------------------------------------------------------------------------
	 * PLAY THE MOVIE
	 *-----------------------------------------------------------------------*/

	/* Allocate a VQA handle. */
	if ((vqa = VQA_Alloc()) != NULL) {

		/* Initialize the handle as a standard DOS handle. */
		VQA_InitAsDOS(vqa);

		/* Open the movie for playback. */
		if (VQA_Open(vqa, name, &myconfig) == 0) {

			#if(1)
			VQA_Reset(vqa);
			VQA_SetStop(vqa, 100);
			VQA_SeekFrame(vqa, 50, 0);

			for (i = 0; i < 3; i++) {
				/* Actually set the movie off. */
				VQA_Play(vqa, VQAMODE_RUN);
				VQA_Reset(vqa);
				VQA_SeekFrame(vqa, 50, 0);
			}
			#else
			{
			long done = 0;
			long mode = VQAMODE_WALK;
			long key;

			do {
				switch (VQA_Play(vqa, mode)) {
					case VQAERR_NONE:
					case VQAERR_PAUSED:
					case VQAERR_NOT_TIME:
					case VQAERR_SLEEPING:
						key = Check_Key();

						if (key != 0) {
							switch (key) {
								case ' ':
									mode = VQAMODE_PAUSE;
									break;

								case 0x1B:
									done = 1;
									break;

								default:
									mode = VQAMODE_WALK;
									break;
							}
						}
						break;

					default:
						done = 1;
						break;
				}
			} while (done == 0);
			}
			#endif

			/* Retrieve playback statistics (FPS, time, etc...) */
			VQA_GetStats(vqa, &stats);

			/* Close the movie. */
			VQA_Close(vqa);

		}

		/* Free the VQA handle. */
		VQA_Free(vqa);
	}

	/*-------------------------------------------------------------------------
	 * RESTORE DISPLAY TO TEXT AND PRINT STATISTICS
	 *-----------------------------------------------------------------------*/
	SetVideoMode(TEXT);

	#if(CAPTIONS)
	if (myconfig.CapFont != NULL) free(myconfig.CapFont);
	#endif

	Usage(0);

	/* Print play statistics */
	if (OutputStats) {
		printf("Movie Name: %s\n",strupr(name));
		Print_Play_Stats(&myconfig, &stats);
	}

	exit(0);
}


/****************************************************************************
*
* NAME
*     Usage - Display usage information.
*
* SYNOPSIS
*     Usage()
*
*     void Usage(void);
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

static void Usage(long showall)
{
	printf("\n%s Copyright (c) 1995 Westwood Studios.\n", &VerTag[5]);
	printf("Playback library: %s\n", VQA_IDString());
	puts("Written by Denzil E. Long, Jr.\n");

	if (showall) {
		puts("Usage: VPLAY <filename> [options]");

		puts("  -z:     Single-step");
		puts("  -d:     No drawing");
		puts("  -fn:    Draw at 'n' frames per second");
		puts("  -ln:    Load at 'n' frames per second");
		puts("  -b:     Use buffered video");
		puts("  -o:     Output play statistics");

		puts("  -p:     Enable slow palette setting");
		puts("  -w:     Enable woofer drawing.");

		#if(VQAMONO_ON)
		puts("  -m:     Enable mono screen output");
		#endif

		#if(VQAAUDIO_ON)
		puts("  -a:     Audio playback rate");
		puts("  -ac:    Compatibility mode (Force SoundBlaster).");
		puts("  -alt:   Play alternate audio track.");
		puts("  -s:     Disable sound");

		#if(VQAVOC_ON)
		puts("  -cname: Name of VOC file to play instead of interleaved audio");
		#endif
		#endif

		puts("  -t_:    Timer method:");
		puts("    a = Audio DMA position");
		puts("    i = Interrupt");
		puts("    d = DOS");

		puts("  -v_:    Video mode:");

		#if(VQAMCGA_ON)
		puts("    m = MCGA");
		#endif

		#if(VQAXMODE_ON)
		puts("    w = XMODE 320x200");
		puts("    x = XMODE 320x240");
		puts("    y = XMODE 320x200, VRAM mode");
		puts("    z = XMODE 320x240, VRAM mode");
		#endif

		#if(VQAVESA_ON)
		puts("    u = VESA 320x200");
		puts("    v = VESA 640x480 in a window (buffered only)");
		puts("    s = VESA 640x480 scaled to 640x400 (buffered only)");
		#endif
	}
}


/****************************************************************************
*
* NAME
*     Options - Parse user options.
*
* SYNOPSIS
*     Options(ArgC, ArgV, Anim)
*
*     void Options(long, char *[], VQAnim *);
*
* FUNCTION
*
* INPUTS
*     ArgC - Argument count, same as passed to main().
*     ArgV - Argument array, same as passed to main().
*     Anim - Pointer to VQAnim structure.
*
* RESULT
*     NONE
*
****************************************************************************/

static void Options(long argc, char *argv[], VQAConfig *config)
{
	long l;
	long i;

	/* Scan arguments for any options ( / or - followed by a letter) */
	for (l = 0; l < argc; l++) {
		if (argv[l][0] == '/' || argv[l][0] == '-') {

			/* Convert the argument to uppercase. */
			for (i = 1; argv[l][i] != 0; i++) {
				argv[l][i] = toupper(argv[l][i]);
			}

			switch (argv[l][1]) {

				/* Set Audio Playback rate */
				#if(VQAAUDIO_ON)
				case 'A':
					if (isdigit(argv[l][2])) {
						config->AudioRate = atoi(&argv[l][2]);
					} else {
						if (argv[l][2] == 'C') {
							config->DigiCard = 0xE000;
						} else {
							if (strcmpi(&argv[l][2], "LT") == 0) {
								config->OptionFlags |= VQAOPTF_ALTAUDIO;
							}
						}
					}
					break;
				#endif

				/* Turn off UnVQ to screen */
				case 'B':
					config->DrawFlags |= VQACFGF_BUFFER;
					break;

				/* VOC File Name */
				#if(VQAAUDIO_ON && VQAVOC_ON)
				case 'C':
					config->VocFile = (argv[l] + 2);
					break;
				#endif

				/* Turn off vertical blank wait */
				case 'D':
					config->DrawFlags |= VQACFGF_NODRAW;
					break;

				/* Set Drawer's frame rate */
				case 'F':
					config->DrawRate = atoi(&argv[l][2]);
					break;

				/* Set Loader's frame rate */
				case 'L':
					config->FrameRate = atoi(&argv[l][2]);
					break;

				/* Mono mode */
				#if(VQAMONO_ON)
				case 'M':
					config->OptionFlags |= VQAOPTF_MONO;
					break;
				#endif

				/* Output statistics */
				case 'O':
					OutputStats = 1;
					break;

				/* Slow palette mode */
				case 'P':
					config->OptionFlags |= VQAOPTF_SLOWPAL;
					break;

				/* Run with no sound */
				#if(VQAAUDIO_ON)
				case 'S':
					config->OptionFlags &= (~VQAOPTF_AUDIO);
					break;
				#endif

				case 'T':
					switch (argv[l][2]) {
						case 'A':
							config->TimerMethod = VQA_TMETHOD_AUDIO;
							break;

						case 'I':
							config->TimerMethod = VQA_TMETHOD_INT;
							break;

						case 'D':
							config->TimerMethod = VQA_TMETHOD_DOS;
							break;

						default:
							break;
					}
					break;

				/* Set video mode */
				case 'V':
					if (argv[l][2] == 'M') {
						config->Vmode = MCGA;
					}
					#if(VQAXMODE_ON)
					else if (argv[l][2] == 'W') {
						config->Vmode = XMODE_320X200;
					}
					else if (argv[l][2] == 'X') {
						config->Vmode = XMODE_320X240;
					}
					else if (argv[l][2] == 'Y') {
						config->Vmode = XMODE_320X200;
						config->DrawFlags |= VQACFGF_VRAMCB;
					}
					else if (argv[l][2] == 'Z') {
						config->Vmode = XMODE_320X240;
						config->DrawFlags |= VQACFGF_VRAMCB;
					}
					#endif

					#if(VQAVESA_ON)
					else if (argv[l][2] == 'V') {
						config->Vmode = VESA_640X480_256;
						config->DrawFlags |= VQACFGF_BUFFER;
					}
					else if (argv[l][2] == 'S') {
						config->Vmode = VESA_640X480_256;
						config->DrawFlags |= (VQACFGF_BUFFER|VQACFGF_SCALEX2);
					}
					else if (argv[l][2] == 'U') {
						config->Vmode = VESA_320X200_32K_1;
					}
					#endif
					else {
						printf("Unsupported video mode flag: %c\n", argv[l][2]);
						exit(0);
					}
					break;

				#if(VQAWOOFER_ON)
				case 'W':
					config->DrawFlags |= VQACFGB_WOOFER;
					break;
				#endif

				/* Single-step */
				case 'Z':
					config->OptionFlags |= VQAOPTF_STEP;
					config->DrawFlags |= VQACFGF_NOSKIP;
					break;

				default:
					break;
			}
		}
	}

	return;
}


/****************************************************************************
*
* NAME
*     Find_File_Name - Find a filename on the command line.
*
* SYNOPSIS
*     Name = Fine_File_Name(ArgC, ArgV, Ext, Anim)
*
*     char * Fine_File_Name(short, char *[], char *, VQAnim);
*
* FUNCTION
*      Finds a file name on the command line, excluding anything with "/" or
*      "-" on it. The given extension is added to the name if there is no
*      extension in the filename.
*
* INPUTS
*      ArgC - Argument count same as in main().
*      ArgV - Argument array same as in main().
*      Ext  - Pointer to filename extension.
*      Anim - Pointer to VQAnim structure.
*
* RESULT
*      Name = Pointer to filename.
*
****************************************************************************/

static char *Find_File_Name(long argc, char *argv[], char *desired_ext)
{
	long        opt = 1;
	static char drive[_MAX_DRIVE] = {0};
	static char dir[_MAX_DIR] = {0};
	static char fname[_MAX_FNAME] = {0};
	static char ext[_MAX_EXT] = {0};
	static char pathname[_MAX_PATH] = {0};

	/* Search for a non '-' option */
	while ((argv[opt][0] == '/') || (argv[opt][0] == '-')) {
		opt++;
	}

	if (argc == opt) {
	 	return (NULL);
	}

	/* Split the filename into its components */
	_splitpath(argv[opt],drive,dir,fname,ext);

	if (strlen(ext) == 0) {
		strcpy(ext,desired_ext);
	}

	/* Rebuild the complete filename */
	_makepath(pathname, drive, dir, fname, ext);

	return (pathname);
}


/****************************************************************************
*
* NAME
*     Print_Play_Stats - Print player statistics.
*
* SYNOPSIS
*     Print_Play_Stats(Anim)
*
*     void Print_Play_Stats(VQAnim);
*
* FUNCTION
*
* INPUTS
*     Anim - Pointer to VQAnim structure.
*
* RESULT
*     NONE
*
****************************************************************************/

void Print_Play_Stats(VQAConfig *config, VQAStatistics *stats)
{
	long tim1,tim2;
	long fps1,fps2;

	/* Video mode name */
	printf("Video Mode: ");

	if (config->Vmode == MCGA) {
		if (config->DrawFlags & VQACFGF_BUFFER) {
			puts("MCGA Buffered");
		} else {
			puts("MCGA");
		}
	}
	#if(VQAXMODE_ON)
	else if (config->Vmode == XMODE_320X200) {
		if (config->DrawFlags & VQACFGF_BUFFER) {
			puts("XMODE 320x200 Buffered");
		} else {
			if (config->DrawFlags & VQACFGF_VRAMCB) {
				puts("XMODE 320x200 VRAM");
			} else {
				puts("XMODE 320x200");
			}
		}
	}
	else if (config->Vmode == XMODE_320X240) {
		if (config->DrawFlags & VQACFGF_BUFFER) {
			puts("XMODE 320x240 Buffered");
		} else {
			if (config->DrawFlags & VQACFGF_VRAMCB) {
				puts("XMODE 320x240 VRAM");
			} else {
				puts("XMODE 320x240");
			}
		}
	}
	#endif

	#if(VQAVESA_ON)
	else if (config->Vmode == VESA_640X480_256) {
		if (config->DrawFlags & VQACFGF_SCALEX2) {
			puts("VESA 640x480 Scaled");
		} else {
			puts("VESA 640x480 Windowed");
		}
	} else if (config->Vmode==VESA_320X200_32K_1) {
		if (config->DrawFlags & VQACFGF_BUFFER) {
			puts("VESA 320x200 Buffered");
		} else {
			puts("VESA 320x200");
		}
	}
	#endif
	else {
		puts("UNKNOWN");
	}

	printf("%lu bytes used.\n", stats->MemUsed);

	tim1 = ((stats->EndTime - stats->StartTime) / VQA_TIMETICKS);
	tim2 = (((stats->EndTime - stats->StartTime) * 10) / VQA_TIMETICKS);
	printf("Elapsed time %d.%d seconds.\n", tim1, tim2 - (tim1 * 10));

	printf("%u frames loaded.\n", stats->FramesLoaded);
	printf("%u frames drawn.\n", stats->FramesDrawn);
	printf("%u frames skipped.\n", stats->FramesSkipped);

	/* Frame rates */
	fps1 = ((stats->FramesLoaded * VQA_TIMETICKS)
			/ (stats->EndTime - stats->StartTime));
	fps2 = (stats->FramesLoaded * VQA_TIMETICKS * 10)
			/ (stats->EndTime - stats->StartTime);
	printf("Load rate: %d.%d FPS\n", fps1, fps2 - (fps1 * 10));

	fps1 = (stats->FramesDrawn * VQA_TIMETICKS)
			/ (stats->EndTime -stats->StartTime);
	fps2 = (stats->FramesDrawn * VQA_TIMETICKS * 10)
			/ (stats->EndTime - stats->StartTime);
	printf("Draw rate: %d.%d FPS\n", fps1, fps2 - (fps1 * 10));

	/* Audio */
	printf("Audio samples played: %lu\n", stats->SamplesPlayed);
}


/****************************************************************************
*
* NAME
*     Check_Key - Check keyboard for keypress.
*
* SYNOPSIS
*     Key = Check_Key()
*
*     short Check_Key(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     Key - Value of key pressed.
*
****************************************************************************/

int Check_Key(void)
{
	if (kbhit()) {
		LastKey = getch();
		return (LastKey);
	} else {
		return (0);
	}
}


/****************************************************************************
*
* NAME
*     Get_Key - Get a key from the keyboard buffer.
*
* SYNOPSIS
*     Key = Get_Key()
*
*     short Get_Key(void);
*
* FUNCTION
*
* INPUTS
*     NONE
*
* RESULT
*     Key - Value of key.
*
****************************************************************************/

int Get_Key(void)
{
	return (LastKey);
}


#ifndef __WATCOMC__
#if(0)
/****************************************************************************
*
* NAME
*     HardErr_Handler - Hardware error handle.
*
* SYNOPSIS
*     HardErr_Handler(Error, AX, BP, SI)
*
*     int HardErr_Handler(int, int, int, int);
*
* FUNCTION
*     DOS calls 1 through 0xc are OK; any other will corrupt DOS.
*     Important safety tip: The arguments for this function are NOT the
*     same as those for the Microsoft '_harderr()' function.
*
* INPUTS
*     Error - Error type value. Low order byte can be:
*
*             0  = Attempt to write to write-protected disk.
*             1  = Unknown unit.
*             2  = Drive not ready.
*             3  = Unknown command.
*             4  = CRC error.
*             5  = Bad drive-request structure length.
*             6  = Seek error.
*             7  = Unknown media type.
*             8  = Sector not found.
*             9  = Printer out of paper.
*             10 = Write fault.
*             11 = Read fault.
*             12 = General failure.
*
*     AX    - Will be non-negative if this is a disk error, negative
*             otherwise. low-order byte of ax gives failing drive number
*             high bits:
*
*             15 0 = disk error
*             14     not used
*             13 0 = "Ignore" not allowed
*             12 0 = "Retry" not allowed
*             11 0 = "Fail" not allowed (fail is same as abort)
*             10,9:
*             00     DOS
*             01     File allocation table
*             10     Directory
*             11     Data area
*             8 0  = Read error, 1 = Write error
*
*     BP,SI - Not used
*
* RESULT
*     NONE
*
****************************************************************************/

int HardErr_Handler(int errval, int ax, int bp, int si)
{
	/* Suppress compiler warnings */
	errval = errval;
	bp = bp;
	si = si;

	/* If AX < 0, this was not a disk error, so return the ABORT code */
	if (ax < 0) {
		hardretn(_HARDERR_ABORT);
	}

	/* Otherwise, if this is a drive-not-ready error, retry 5 times */
	if (kbhit() != 0) {
		if (ax & (1 << 13)) {
			hardresume(_HARDERR_IGNORE);
		} else if (ax & (1 << 11)) {
			hardresume(_HARDERR_FAIL);
		} else {
			hardresume(_HARDERR_RETRY);
		}
	} else {
		if (ax & (1 << 12)) {
			hardresume(_HARDERR_RETRY);
		} else {
			hardresume(_HARDERR_IGNORE);
		}
	}

	return (0);
}
#endif

#else
/****************************************************************************
*
* NAME
*     HardErr_Handler - Critical error handler for INT 0x24.
*
* SYNOPSIS
*     Action = HardErr_Handler(DeviceError, ErrorCode, DeviceHeader)
*
*     int HardErr_Handler(unsigned, unsigned, unsigned __far *);
*
* FUNCTION
*
* INPUTS
*     DeviceError  - Device error description.
*
*                    bit 15    0 indicates disk error.
*                    bit 14    not used
*                    bit 13    0 indicates "Ignore" response not allowed.
*                    bit 12    0 indicates "Retry" response not allowed.
*                    bit 11    0 indicates "Fail" response not allowed.
*                    bit 9,10  location of error.
*
*                              Value   Meaning
*
*                              00      MS-DOS
*                              01      File Allocation Table (FAT)
*                              10      Directory
*                              11      Data area
*
*                    bit 8     0 indicates read error,1 indicates write error
*
*                    The low-order byte indicates the drive where the error
*                    occurred; (0 = drive A, 1 = drive B, etc.).
*
*   	ErrorCode    - Type of error.
*
*                    The low-order byte can be one of the following values:
*
*                    0x00  Attempt to write to a write-protected disk.
*                    0x01  Unknown unit.
*                    0x02  Drive not ready.
*                    0x03  Unknown command.
*                    0x04  CRC error in data.
*                    0x05  Bad drive-request structure length.
*                    0x06  Seek error.
*                    0x07  Unknown media type.
*                    0x08  Sector not found.
*                    0x09  Printer out of paper.
*                    0x0A  Write fault.
*                    0x0B  Read fault.
*                    0x0C  General fault.
*
*     DeviceHeader - Pointer to a device header control-block that contains
*                    information about the device on which the error
*                    occurred.
*
* RESULT
*     Action - Indication of what action to take using one of the following
*              values:
*
*              Value             Meaning
*
*              _HARDERR_IGNORE   Ignore the error.
*              _HARDERR_RETRY    Retry the operation.
*              _HARDERR_ABORT    Abort the program issuing INT 0x23
*              _HARDERR_FAIL     Fail the system call that is in progress
*                                (DOS 3.0 or higher)
*
****************************************************************************/

int __far HardErr_Handler(unsigned deverror, unsigned errcode,
		unsigned __far *devhdr)
{
	/* Prevent compiler warnings. */
	errcode = errcode;
	devhdr = devhdr;

	/* If this is not a disk error, then return the ABORT code. */
	if (deverror & (1 << 15)) {
		return (_HARDERR_ABORT);
	}

	/* If this is a drive-not-ready error then continue to retry. */
	if (kbhit() != 0) {
		if (deverror & (1 << 13)) {
			_hardresume(_HARDERR_IGNORE);
		}
		else if (deverror & (1 << 11)) {
			_hardresume(_HARDERR_FAIL);
		}
		else {
			_hardresume(_HARDERR_RETRY);
		}
	} else {
		if (deverror & (1 << 12)) {
			_hardresume(_HARDERR_RETRY);
		} else {
			_hardresume(_HARDERR_IGNORE);
		}
	}

	return (0);
}
#endif


/****************************************************************************
*
* NAME
*     GetFilePart - Get the filename part of path/filename.
*
* SYNOPSIS
*     Filename = GetFilePart(Path)
*
*     char *GetFilePart(char *);
*
* FUNCTION
*
* INPUTS
*     Path - Full path to retrieve filename from.
*
* RESULT
*     Filename - Pointer to filename or NULL if no filename.
*
****************************************************************************/

static char *GetFilePart(char *path)
{
	char *ptr;

	ptr = strrchr(path, '\\');

	if (ptr == NULL) {
		ptr = strrchr(path, ':');
	}

	if (strlen(ptr) > 1) {
		ptr++;
	}

	return (ptr);
}

