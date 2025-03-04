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

/* $Id: soundio.cpp 1.41 1994/06/20 15:01:39 joe_bostic Exp $ */
/***********************************************************************************************
 **             C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S             **
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Sound Library                                                *
 *                                                                                             *
 *                    File Name : SOUND.CPP                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : July 22, 1991                                                *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   Load_Long_Sample -- Loads a sample into XMS for double buffer system.                     *
 *   Read_Long_Sample -- Loads/Processes/Formats/Builds offset.                                             *
 *   Save_Table_Entry -- Put an entry in the offset table.                                     *
 *   Play_Long_Sample -- Calls Init_Long_Sample and Start_Long_Sample.                         *
 *   Start_Long_Sample -- Starts a sample playing that has be initialized.                     *
 *   Get_Table_Entry -- Gets next entry in table.                                              *
 *   Long_Sample_Ticks -- Gets number of ticks in sample if in header.                         *
 *   Long_Sample_Status -- Returns the status of the sample.                                   *
 *   Find_Table_Entry -- Finds next entry in table that matches mask.                          *
 *   Get_Table_Start -- Returns a pointer to first entry in table.                             *
 *   Long_Sample_Ticks_Played -- Number of ticks since sample started.                         *
 *   Install_Sample_Driver_Callback -- Pokes callback function into JM driver                  *
 *   Stop_Long_Sample -- Stops current long sample from playing.                               *
 *   Long_Sample_Loaded_Size -- Max buffer size to load a long sample.                         *
 *   Sound_Callback -- Audio driver callback function.                                         *
 *   DigiCallback -- Low level double buffering handler.                                       *
 *   Load_Sample_Into_Buffer -- Loads a digitized sample into a buffer.                        *
 *   Stream_Sample -- Streams a sample directly from a file.                                   *
 *   Sample_Read -- Reads sample data from an openned file.                                    *
 *   Continue_Sample -- Tags another block of data onto the currently playing.                 *
 *   Sample_Copy -- Copies sound data from source format to raw format.                        *
 *   File_Stream_Preload -- Handles initial proload of a streaming samples bu*
 *   Sample_Length -- returns length of a sample in ticks                  *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

extern	void Colour_Debug (int call_number);
#pragma 	pack(4)

#define WIN32
#ifndef _WIN32 // Denzil 6/2/98 Watcom 11.0 complains without this check
#define _WIN32
#endif // _WIN32

#include	<windows.h>
#include	<windowsx.h>
#include	"dsound.h"

#include	<mem.h>
#include	<wwmem.h>
#include	"soundint.h"
#include	<stdio.h>
#include	<string.h>
#include	<direct.h>
#include	<stdlib.h>
#include <process.h>
#include	<keyboard.h>
#include	<file.h>
#include	<bios.h>
#include	<timer.h>
#include	<math.h>
#pragma		pack(1)
#include	"audio.h"
#pragma		pack(4)

LPDIRECTSOUNDBUFFER	DumpBuffer;
HANDLE						SoundThreadHandle = NULL;
BOOL						SoundThreadActive = FALSE;

/*
**      If this is defined, then the streaming audio buffer will be filled
**      to maximum whenever filling is to occur. If undefined, it will fill
**      the streaming buffer in smaller chunks.
*/
#define SIMPLE_FILLING

/*
**      This is the number of times per sec that the maintenance callback gets called.
*/
#define MAINTENANCE_RATE                        40	//30 times per sec plus a safety margin

/*
**      Size of the temporary buffer in XMS/EMS that direct file
**      streaming of sounds will allocate.
*/
//#define STREAM_BUFFER_SIZE              (128L*1024L)
#define STREAM_BUFFER_SIZE              (128L*1024L)

/*
** Define the number of "StreamBufferSize" blocks that are read in
** at a minimum when the streaming sample load callback routine
** is called.  We will IGNORE loads that are less that this in order
** to avoid constant seeking on the CD.
*/
#define STREAM_CUSHION_BLOCKS   4


/*
**      This is the maximum size that a sonarc block can be.  All sonarc blocks
**      must be either a multiple of this value or a binary root of this value.
*/
#define LARGEST_SONARC_BLOCK            2048


//////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////// structs ///////////////////////////////////////

//void						*DigiBuffer = NULL;
static BOOL				StartingFileStream = FALSE;
int						StreamLowImpact = FALSE;
MemoryFlagType			StreamBufferFlag = MEM_NORMAL;
int							Misc;
SFX_Type					SoundType;
Sample_Type				SampleType;
int							ReverseChannels = FALSE;
LPDIRECTSOUND			SoundObject;			//Direct sound object
LPDIRECTSOUNDBUFFER	PrimaryBufferPtr;		//Pointer to the  buffer that the
unsigned					SoundTimerHandle=0;	//Windows Handle for sound timer
WAVEFORMATEX				DsBuffFormat;			//format of direct sound buffer
DSBUFFERDESC				BufferDesc;				//Buffer description for creating buffers
WAVEFORMATEX				PrimaryBuffFormat;	//Copy of format of direct sound primary buffer
DSBUFFERDESC				PrimaryBufferDesc;	//Copy of buffer description for re-creating primary buffer
CRITICAL_SECTION		GlobalAudioCriticalSection;
/*
** Function to call if we detect focus loss
*/
extern	void (*Audio_Focus_Loss_Function)(void) = NULL;


/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

static BOOL File_Callback(short id, short *odd, void **buffer, long *size);
static int __cdecl Stream_Sample_Vol(void *buffer, long size, BOOL (*callback)(short id, short *odd, void **buffer, long *size), int volume, int handle);
void CALLBACK Sound_Timer_Callback ( UINT, UINT, DWORD, DWORD, DWORD );
//static int __cdecl Stream_Sample(void *buffer, long size, BOOL (*callback)(short id, short *odd, void **buffer, long *size));
void Sound_Thread (void *);
volatile BOOL AudioDone;
/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/



// This callback is called whenever the queue buffer playback has begun
// and another buffer is needed for queuing up.  Returns TRUE if there
// is more data to read from the file.
static BOOL File_Callback(short id, short *odd, void **buffer, long *size)
{
	SampleTrackerType       *st;            // Pointer to sample playback control struct.
	void                    *ptr;           // Pointer to working portion of file buffer.

	if (id != -1) {
		st = &LockedData.SampleTracker[id];
	 	ptr = st->FileBuffer;
	 	if (ptr) {

	 	  	/*
	 	  	** Move the next pending block into the primary
	 	  	** position.  Do this only if the queue pointer is
	 	  	** null.
	 	  	*/
			EnterCriticalSection(&GlobalAudioCriticalSection);
	 	  	st->DontTouch = TRUE;
			LeaveCriticalSection(&GlobalAudioCriticalSection);
	 	  	if (!*buffer && st->FilePending) {
	 	  		*buffer = Add_Long_To_Pointer(ptr, (long)(*odd % LockedData.StreamBufferCount)*(long)LockedData.StreamBufferSize);
	 	  		st->FilePending--;
	 	  		*odd = (short)(*odd + 1);
	 	  		if (!st->FilePending) {
	 	  			*size = st->FilePendingSize;
	 	  		} else {
	 	  			*size = LockedData.StreamBufferSize;
	 	  		}
	 	  	}
			EnterCriticalSection(&GlobalAudioCriticalSection);
	 	  	st->DontTouch = FALSE;
			LeaveCriticalSection(&GlobalAudioCriticalSection);
			Sound_Timer_Callback(0,0,0,0,0);	//Shouldnt block as we are calling it from the same thread

	 	  	/*
	 	  	** If the file handle is still valid, then read in the next
	 	  	** block and add it to the next pending slot available.
	 	  	*/
	 	  	if (st->FilePending <
	 	  		(StreamLowImpact ? (LockedData.StreamBufferCount>>1) : ((LockedData.StreamBufferCount-3))) && st->FileHandle != WW_ERROR) {


	 	  		int num_empty_buffers;

#ifdef SIMPLE_FILLING
				num_empty_buffers = (LockedData.StreamBufferCount-2) - st->FilePending;
#else

				//
				// num_empty_buffers will be from 1 to StreamBufferCount
				//
				if (StreamLowImpact) {
					num_empty_buffers = MIN((LockedData.StreamBufferCount >> 1)+STREAM_CUSHION_BLOCKS, (LockedData.StreamBufferCount - 2) - st->FilePending);
				}
				else {
					num_empty_buffers = (LockedData.StreamBufferCount - 2) - st->FilePending;
				}
#endif

				while (num_empty_buffers && (st->FileHandle != WW_ERROR)) {
					int     tofill;
					long    psize;

					tofill = (*odd + st->FilePending) % LockedData.StreamBufferCount;

					ptr = Add_Long_To_Pointer(st->FileBuffer, (long)tofill * (long)LockedData.StreamBufferSize);
					psize = Read_File(st->FileHandle, ptr, LockedData.StreamBufferSize);

				 	/*
				 	**      If less than the requested amount of data was read, this
				 	**      indicates that the source file is exhausted.  Flag the source
				 	**      file as closed so that no further reading is attempted.
				 	*/
				 	if (psize != LockedData.StreamBufferSize) {
				 		Close_File(st->FileHandle);
						st->FileHandle = WW_ERROR;
				 	}

                /*
				 	**      If any real data went into the pending buffer, then flag
				 	**      that this buffer is valid.
                */
				 	if (psize) {
						EnterCriticalSection(&GlobalAudioCriticalSection);
						st->DontTouch = TRUE;
				 	  	st->FilePendingSize = psize;
				 	  	st->FilePending++;
				 	  	st->DontTouch = FALSE;
						LeaveCriticalSection(&GlobalAudioCriticalSection);
						Sound_Timer_Callback(0,0,0,0,0);	//Shouldnt block as we are calling it from the same thread
				 	}
				 	num_empty_buffers--;
				}

				/*
             **  After filling all pending buffers, check to see if the queue buffer
				**  is empty.  If so, then assign the first available pending buffer to the
             **  queue.
				*/
				EnterCriticalSection(&GlobalAudioCriticalSection);
				st->DontTouch = TRUE;
             if (!st->QueueBuffer && st->FilePending) {
					st->QueueBuffer = Add_Long_To_Pointer(st->FileBuffer, (long)(st->Odd%LockedData.StreamBufferCount)*(long)LockedData.StreamBufferSize);
					st->FilePending--;
                st->Odd++;
                if (!st->FilePending) {
						st->QueueSize = st->FilePendingSize;
					} else {
                	st->QueueSize = LockedData.StreamBufferSize;
					}
				}
				st->DontTouch = FALSE;
				LeaveCriticalSection(&GlobalAudioCriticalSection);
				Sound_Timer_Callback(0,0,0,0,0);	//Shouldnt block as we are calling it from the same thread
			}

			/*
          **      If there are no more buffers that the callback routine
			**      can slot into the primary position, then signal that
			**      no furthur callbacks are needed.
			*/
			if (st->FilePending) {
				//LeaveCriticalSection(&GlobalAudioCriticalSection);
				return(TRUE);
			}
		}
		//LeaveCriticalSection(&GlobalAudioCriticalSection);

	}
  return(FALSE);
}





// Generic streaming sample playback initialization.
static int __cdecl Stream_Sample_Vol(void *buffer, long size, BOOL (*callback)(short id, short *odd, void **buffer, long *size), int volume, int handle)
{
	int								playid=-1;      // Sample play ID.
	SampleTrackerType               *st;                    // Working pointer to sample control structure.
	long							oldsize;                // Copy of original sound size.
	AUDHeaderType                   header;

	if (buffer && size && LockedData.DigiHandle != -1) {

		/*
	 	** Start the first section of the sound playing.
	 	*/
	 	Mem_Copy(buffer, &header, sizeof(header));
	 	oldsize = header.Size;
	 	header.Size = size-sizeof(header);
	 	Mem_Copy(&header, buffer, sizeof(header));
	 	playid = Play_Sample_Handle(buffer, 0xFF, volume, 0x0, handle);
	 	header.Size = oldsize;
	 	Mem_Copy(&header, buffer, sizeof(header));

	 	/*
	 	** If the sample actually started playing, then flag this
	 	** sample as a streaming type and signal for a callback
	 	** to occur.
	 	*/
	 	if (playid != -1) {
	 		st = &LockedData.SampleTracker[playid];

	 		st->Callback = callback;
	 		st->Odd = 0;
//             ServiceSomething = TRUE;
    	}
	}
		  return (playid);
}



#if (0)
static int __cdecl Stream_Sample(void *buffer, long size, BOOL (*callback)(short id, short *odd, void **buffer, long *size), int handle)
{
	return Stream_Sample_Vol(buffer, size, callback, 0xFF, handle);
}
#endif


/***********************************************************************************************
 * File_Stream_Sample -- Streams a sample directly from a file.                                *
 *                                                                                             *
 *    This will take the file specified and play it directly from disk.                        *
 *    It performs this by allocating a temporary buffer in XMS/EMS and                         *
 *    then keeping this buffer filled by the Sound_Callback() routine.                         *
 *                                                                                             *
 * INPUT:   filename -- The name of the file to play.                                          *
 *                                                                                             *
 * OUTPUT:  Returns the handle to the sound -- just like Play_Sample().                        *
 *                                                                                             *
 * WARNINGS:   The temporary buffer is allocated when this routine is                          *
 *             called and then freed when the sound is finished.  Keep                         *
 *             this in mind.                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
int File_Stream_Sample(char const *filename, BOOL real_time_start)
{
	return File_Stream_Sample_Vol(filename, 0xFF, real_time_start);
}

/***************************************************************************
 * FILE_STREAM_PRELOAD -- Handles initial proload of streaming samples     *
 *                                                                         *
 * This function is called before a sample which streams from disk is      *
 * started.  It can be called to either fill the buffer in small chunks    *
 * from the call back routine or to fill the entire buffer at once.  This  *
 * is wholely dependant on whether the Loading bit is set within the       *
 * sample tracker.                                                         *
 *                                                                         *
 * INPUT:LockedData.SampleTracker * to the header which tracks this samples*
 *                                                              processing.*
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/05/1995 PWG : Created.                                             *
 *=========================================================================*/

void File_Stream_Preload(int handle)
{
	SampleTrackerType	*st		= &LockedData.SampleTracker[handle];
	int					fh			= st->FileHandle;
	int					maxnum	= (LockedData.StreamBufferCount >> 1) + STREAM_CUSHION_BLOCKS;
	void					*buffer	= st->FileBuffer;
	int					num;

	/*
    ** Figure just how much we need to load.  If we are doing the load in progress
	** then we will only load two blocks.
	*/
    if (st->Loading) {
    	num = st->FilePending + 2;
       num = MIN(num, maxnum);
    } else {
		num = maxnum;
	}

	//EnterCriticalSection(&GlobalAudioCriticalSection);

    /*
    ** Loop through the blocks and load up the number we need.
    */
    for (int index = st->FilePending; index < num; index++) {
		long s = Read_File(fh, Add_Long_To_Pointer(buffer, (long)index * (long)LockedData.StreamBufferSize), LockedData.StreamBufferSize);
       if (s) {
         	st->FilePendingSize = s;
	  		st->FilePending++;
		}
		if (s < LockedData.StreamBufferSize) break;
    }

	Sound_Timer_Callback(0,0,0,0,0);	//Shouldnt block as we are calling it from the same thread


	/*
	** If the last block was incomplete (ie. it didn't completely fill the buffer) or
	** we have now filled up as much of the Streaming Buffer as we need to, then now is
	** the time to kick off the sample.
	*/
	if (st->FilePendingSize < LockedData.StreamBufferSize || index == maxnum) {

		/*
		** Actually start the sample playing, and don't worry about the file callback
		** it won't be called for a while.
		*/
 		int old						= LockedData.SoundVolume;
		int size						= (st->FilePending == 1) ? st->FilePendingSize : LockedData.StreamBufferSize;
		LockedData.SoundVolume	= LockedData.ScoreVolume;
		StartingFileStream		= TRUE;

		Stream_Sample_Vol(buffer, size, File_Callback, st->Volume, handle);
		StartingFileStream		= FALSE;
       LockedData.SoundVolume	= old;

		/*
		** The Sample is finished loading (if it was loading in small pieces) so record that
		** so that it will now use the active logic in the file call back.
		*/
		st->Loading					= FALSE;

		/*
		** Decrement the file pending because the first block is already playing thanks
		** to the play sample call above.
		*/
		st->FilePending--;

		/*
		** If File pending is now a zero, then we only preloaded one block and there
		** is nothing more to play.  So clear the sample tracing structure of the
		** information it no longer needs.
		*/
		if (!st->FilePending) {
			st->Odd					= 0;
          st->QueueBuffer		= 0;
			st->QueueSize			= 0;
			st->FilePendingSize	= 0;
          st->Callback			= NULL;
			Close_File(fh);
		} else {
			/*
			** The QueueBuffer counts as an already played block so remove it from the total.
          ** Note: We didn't remove it before because there might not have been one.
          */
          st->FilePending--;

          /*
          ** When we start loading we need to start past the first two blocks.  Why this
          ** is called Odd, I haven't got the slightest.
			*/
          st->Odd = 2;

          /*
          ** If the file pending size is less than the stream buffer, then the last block
          ** we loaded was the last block period.  So close the file and reset the handle.
          */
          if (st->FilePendingSize != LockedData.StreamBufferSize) {
				Close_File(fh);
             st->FileHandle = WW_ERROR;
          }

          /*
          ** The Queue buffer needs to point at the next block to be processed.  The size
          ** of the queue is dependant on how many more blocks there are.
          */
			st->QueueBuffer = Add_Long_To_Pointer(buffer, LockedData.StreamBufferSize);
			if (!st->FilePending) {
          	st->QueueSize = st->FilePendingSize;
          } else {
          	st->QueueSize = LockedData.StreamBufferSize;
          }
		}
	}
	//LeaveCriticalSection(&GlobalAudioCriticalSection);

}







/***********************************************************************************************
 * File_Stream_Sample_Vol -- Streams a sample directly from a file.                            *
 *                                                                                             *
 *    This will take the file specified and play it directly from disk.                        *
 *    It performs this by allocating a temporary buffer in XMS/EMS and                         *
 *    then keeping this buffer filled by the Sound_Callback() routine.                         *
 *                                                                                             *
 * INPUT:   filename -- The name of the file to play.                                          *
 *                                                                                             *
 * OUTPUT:  Returns the handle to the sound -- just like Play_Sample().                        *
 *                                                                                             *
 * WARNINGS:   The temporary buffer is allocated when this routine is                          *
 *             called and then freed when the sound is finished.  Keep                         *
 *             this in mind.                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *=============================================================================================*/

int File_Stream_Sample_Vol(char const *filename, int volume, BOOL real_time_start)
{
	static void     *buffer = NULL;
	SampleTrackerType       *st;
	int     fh;
	int     handle = -1;
	int     index;

	if (LockedData.DigiHandle != -1 && filename && Find_File(filename)) {

	/*
	**  Make sure all sample tracker structures point to the same
	**  upper memory buffer.  This allocation only occurs if at
	**  least one sample gets "streamed".
	*/
	if (!buffer) {
		buffer = Alloc(LockedData.StreamBufferSize * LockedData.StreamBufferCount, (MemoryFlagType)(StreamBufferFlag | MEM_TEMP | MEM_LOCK));
       for (index = 0; index < MAX_SFX; index++) {
       	LockedData.SampleTracker[index].FileBuffer = buffer;
		}
	}
	/*
	** If after trying to allocate the buffer we still fail then
	** we can stream this sample.
	*/
	if (!buffer) return(-1);


    	/*
    	** Lets see if we can sucessfully open up the file.  If we can't,
    	** then there is no point in going any farther.
    	*/
    	if ((fh = Open_File(filename, READ)) == -1) {
 	 			return (-1);
    	}

		/*
		** Reserve a handle so that we can fill in the sample tracker
		** with the needed information.  If we dont get valid handle then
		** we might as well give up.
		*/
		if ((unsigned)(handle = Get_Free_Sample_Handle(0xFF)) >= MAX_SFX) {
 				return(-1);
		}

		/*
		** Now lets get a pointer to the proper sample handler and start
		** our manipulations.
		*/
		st							= &LockedData.SampleTracker[handle];
		st->IsScore				= TRUE;
		st->FilePending		= 0;
		st->FilePendingSize	= 0;
		st->Loading				= real_time_start;
		st->Volume				= volume;
		st->FileHandle			= fh;

		/*
		** Now that we have setup our initial data properly, let load up
		** the beginning of the sample we intend to stream.
		*/
		File_Stream_Preload(handle);
	}

	return (handle);
}

/***********************************************************************************************
 * Sound_Callback -- Audio driver callback function.                                           *
 *                                                                                             *
 *    Maintains the audio buffers.  This routine must be called at least                       *
 *    11 times per second or else audio glitches will occur.                                   *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   If this routine is not called often enough then audio                           *
 *             glitches will occur.                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void __cdecl Sound_Callback(void)
{
	int					index;
    SampleTrackerType	*st;

    if (LockedData.DigiHandle != -1) {

		/*
		** Call the timer callback now as we may block it in this function
		*/
		Sound_Timer_Callback(0,0,0,0,0);

		st = &LockedData.SampleTracker[0];
		for (index = 0; index < MAX_SFX; index++) {
			if (st->Loading) {
				File_Stream_Preload(index);
			} else {
          	/*
          	**  General service routine to handle moving small blocks from the
          	**  source into the low RAM staging buffers.
          	*/

				if (st->Active) {

					/*
          		**  Special check to see if the sample is a fading one AND
          		**  it has faded to silence, then stop it here.
          		*/
          		if (st->Reducer && !st->Volume) {
						//EnterCriticalSection(&GlobalAudioCriticalSection);
						Stop_Sample(index);
						//LeaveCriticalSection(&GlobalAudioCriticalSection);
					} else {

          			/*
             		**  Fill the queuebuffer if it is currently empty
             		**  and there is a callback function defined to fill it.
             		**
             		** PWG/CDY & CO: We should be down by at least two blocks
						**                                        before we bother with this
             		*/

             		if ((!st->QueueBuffer ||
							(st->FileHandle != WW_ERROR && st->FilePending < LockedData.StreamBufferCount-3)) &&
				 			st->Callback) {

                		if (!st->Callback((short)index, (short int *)&st->Odd, &st->QueueBuffer, &st->QueueSize)) {
								st->Callback = NULL;
                		}
             		}
          		}

				} else {

          		/*
          		** This catches the case where a streaming sample gets
          		** aborted prematurely because of failure to call the
          		** callback function frequently enough.  In this case, the
          		** sample will be flagged as inactive, but the file handle
          		** will not have been closed.
          		*/
          		if (st->FileHandle != WW_ERROR) {
						//EnterCriticalSection(&GlobalAudioCriticalSection);
          			Close_File(st->FileHandle);
             		st->FileHandle = WW_ERROR;
						//LeaveCriticalSection(&GlobalAudioCriticalSection);
          		}
				}
			}

          /*
          **      Advance to the next sample control structure.
			*/
    		st++;
		}

    }
}


/***********************************************************************************************
 * Load_Sample -- Loads a digitized sample into RAM.                                           *
 *                                                                                             *
 *    This routine loads a digitized sample into RAM.                                          *
 *                                                                                             *
 * INPUT:   filename -- Name of the sound file to load.                                        *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the loaded sound file.  This pointer                     *
 *          is passed to Play_Sample when playback is desired.                                 *
 *                                                                                             *
 * WARNINGS:   If there is insufficient memory to load the sample, then                        *
 *             NULL will be returned.                                                          *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *   01/06/1994 JLB : HMI version.                                                             *
 *=============================================================================================*/
void *Load_Sample(char const *filename)
{
	void *buffer = NULL;
	long    size;
	int     fh;

	if (LockedData.DigiHandle == -1 || !filename || !Find_File(filename)) {
		return (NULL);
	}

	fh = Open_File(filename, READ);
	if (fh != WW_ERROR) {
		size = File_Size(fh)+sizeof(AUDHeaderType);
		buffer = Alloc(size, MEM_NORMAL);

		if (buffer) {
			Sample_Read(fh, buffer, size);
		}
		Close_File(fh);
		Misc = size;
	}
	return(buffer);
}


/***********************************************************************************************
 * Load_Sample_Into_Buffer -- Loads a digitized sample into a buffer.                          *
 *                                                                                             *
 *    This routine is used to load a digitized sample into a buffer                            *
 *    provided by the programmer.  This buffer can be in XMS or EMS.                           *
 *                                                                                             *
 * INPUT:   filename -- The filename to load.                                                  *
 *                                                                                             *
 *          buffer   -- Pointer to the buffer to load into.                                    *
 *                                                                                             *
 *          size     -- The size of the buffer to load into.                                   *
 *                                                                                             *
 * OUTPUT:  Returns the number of bytes actually used in the buffer.                           *
 *                                                                                             *
 * WARNINGS:   This routine will not overflow the buffer provided.  This                       *
 *             means that the buffer must be big enough to hold the data                       *
 *             or else the sound will be cut short.                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
long Load_Sample_Into_Buffer(char const *filename, void *buffer, long size)
{
	int     fh;

	/*
	**      Verify legality of parameters.
	*/
	if (!buffer || !size || LockedData.DigiHandle == -1 || !filename || !Find_File(filename)) {
		return (NULL);
	}

	fh = Open_File(filename, READ);
	if (fh != WW_ERROR) {
		size = Sample_Read(fh, buffer, size);
       Close_File(fh);
	} else {
		return(0);
	}
	return(size);
}


/***********************************************************************************************
 * Sample_Read -- Reads sample data from an openned file.                                      *
 *                                                                                             *
 *    This routine reads a sample file.  It is presumed that the file is                       *
 *    already positioned at the start of the sample.  From this, it can                        *
 *    determine if it is a VOC or raw data and proceed accordingly.                            *
 *                                                                                             *
 * INPUT:   fh       -- File handle of already openned sample file.                            *
 *                                                                                             *
 *          buffer   -- Pointer to the buffer to load data into.                               *
 *                                                                                             *
 *          size     -- The size of the buffer.                                                *
 *                                                                                             *
 * OUTPUT:  Returns the number of bytes actually used in the buffer.                           *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/06/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
long Sample_Read(int fh, void *buffer, long size)
{

	AUDHeaderType	RawHeader;
	void    			*outbuffer;				// Pointer to start of raw data.
	long    			actual_bytes_read;	// Actual bytes read in, including header

/*
** Conversion formula for TCrate and Hz rate.
**
** TC = 256 - 1m/rate
** rate = 1m / (256-TC)
*/

	if (!buffer || fh == WW_ERROR || size <= sizeof(RawHeader)) return(NULL);

	size -= sizeof(RawHeader);
	outbuffer = Add_Long_To_Pointer(buffer, sizeof(RawHeader));
  	actual_bytes_read = Read_File(fh, &RawHeader, sizeof(RawHeader));
	actual_bytes_read +=Read_File(fh, outbuffer, MIN(size, RawHeader.Size));
	Mem_Copy(&RawHeader, buffer, sizeof(RawHeader));
	return(actual_bytes_read);
}


/***********************************************************************************************
 * Free_Sample -- Frees a previously loaded digitized sample.                                  *
 *                                                                                             *
 *    Use this routine to free the memory allocated by a previous call to                      *
 *    Load_Sample.                                                                             *
 *                                                                                             *
 * INPUT:   sample   -- Pointer to the sample to be freed.                                     *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *=============================================================================================*/
void Free_Sample(void const *sample)
{
	if (sample) Free((void *)sample);
}











/***********************************************************************************************
 * Sound_Timer_Callback -- windows timer callback for sound maintenance                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:01PM ST : Created                                                              *
 *=============================================================================================*/

void CALLBACK Sound_Timer_Callback ( UINT, UINT, DWORD, DWORD, DWORD )
{
	//if (!InTimerCallback){
		//InTimerCallback++;
		//Colour_Debug (5);
		EnterCriticalSection(&GlobalAudioCriticalSection);
		maintenance_callback();
		LeaveCriticalSection(&GlobalAudioCriticalSection);
		//Colour_Debug (0);
		//InTimerCallback--;
	//}
}

void Sound_Thread (void *)
{
	DuplicateHandle (GetCurrentProcess(), GetCurrentThread() , GetCurrentProcess() ,&SoundThreadHandle , THREAD_ALL_ACCESS , TRUE , 0);
	SetThreadPriority (SoundThreadHandle, THREAD_PRIORITY_TIME_CRITICAL);
	SoundThreadActive = TRUE;

	while (!AudioDone){

		EnterCriticalSection(&GlobalAudioCriticalSection);
		maintenance_callback();
		LeaveCriticalSection(&GlobalAudioCriticalSection);
		Sleep(1000/40);
	}

	SoundThreadActive = FALSE;
}







/***********************************************************************************************
 * Set_Primary_Buffer_Format -- set the format of the primary sound buffer                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   TRUE if successfully set                                                          *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/22/95 4:06PM ST : Created                                                             *
 *=============================================================================================*/

BOOL Set_Primary_Buffer_Format(void)
{
	if (SoundObject && PrimaryBufferPtr){
		return (PrimaryBufferPtr->SetFormat ( &PrimaryBuffFormat ) == DS_OK);
	}
	return (FALSE);
}



/***********************************************************************************************
 * Print_Sound_Error -- show error messages from failed sound initialisation                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    error text                                                                        *
 *           handle to window                                                                  *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    2/7/96 10:17AM ST : Created                                                              *
 *=============================================================================================*/

void Print_Sound_Error(char *sound_error, HWND window)
{
	MessageBox(window, sound_error, "Command & Conquer", MB_ICONEXCLAMATION|MB_OK);
}



/***********************************************************************************************
 * Audio_Init -- Initialise the sound system                                                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    window - window to send callback messages to                                      *
 *           maximum bits_per_sample - 8 or 16                                                 *
 *           stereo - will stereo samples be played                                            *
 *           rate - maximum sample rate required                                               *
 *           reverse_channels                                                                  *
 *                                                                                             *
 * OUTPUT:   TRUE if correctly initialised                                                     *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   Unknown....                                                                               *
 *   08-24-95 10:01am ST : Modified for Windows 95 Direct Sound                                *
 *=============================================================================================*/

BOOL Audio_Init( HWND window , int bits_per_sample, BOOL stereo , int rate , int reverse_channels)
{
	int	index;
	int	sample=1;
	short old_bits_per_sample;
	short old_block_align;
	long	old_bytes_per_sec;


	Init_Locked_Data();
	memset(&LockedData.SampleTracker[0], 0, sizeof(LockedData.SampleTracker));

	if ( !SoundObject ){

		/*
		**	Create the direct sound object
		*/
		if ( DirectSoundCreate (NULL,&SoundObject,NULL) !=DS_OK ) {
			Print_Sound_Error("Warning - Unable to create Direct Sound Object",window);
			return (FALSE);
		}

		/*
		**	Give ourselves exclusive access to it
		*/
		if ( SoundObject->SetCooperativeLevel( window, DSSCL_PRIORITY ) != DS_OK){
			Print_Sound_Error("Warning - Unable to set Direct Sound cooperative level",window);
			SoundObject->Release();
			SoundObject = NULL;
			return (FALSE);
		}

		/*
		** Set up the primary buffer structure
		*/
		memset (&BufferDesc , 0 , sizeof(DSBUFFERDESC));
		BufferDesc.dwSize=sizeof(DSBUFFERDESC);
		BufferDesc.dwFlags=DSBCAPS_PRIMARYBUFFER | DSBCAPS_CTRLVOLUME;

		/*
		**	Set up the primary buffer format
		*/
		memset (&DsBuffFormat , 0 , sizeof(WAVEFORMATEX));
		DsBuffFormat.wFormatTag		= WAVE_FORMAT_PCM;
		DsBuffFormat.nChannels		= (unsigned short) (1 + stereo);
		DsBuffFormat.nSamplesPerSec	= rate;
		DsBuffFormat.wBitsPerSample	= (short) bits_per_sample;
		DsBuffFormat.nBlockAlign	= (unsigned short)( (DsBuffFormat.wBitsPerSample/8) * DsBuffFormat.nChannels);
		DsBuffFormat.nAvgBytesPerSec= DsBuffFormat.nSamplesPerSec * DsBuffFormat.nBlockAlign;
		DsBuffFormat.cbSize = 0;


		/*
		** Make a copy of the primary buffer description so we can reset its format later
		*/
		memcpy (&PrimaryBufferDesc , &BufferDesc , sizeof(DSBUFFERDESC));
		memcpy (&PrimaryBuffFormat , &DsBuffFormat , sizeof(WAVEFORMATEX));

		/*
		**	Create the primary buffer object
		*/
		if ( SoundObject->CreateSoundBuffer (&PrimaryBufferDesc ,
														&PrimaryBufferPtr ,
														NULL ) !=DS_OK ){
			Print_Sound_Error("Warning - Unable to create Direct Sound primary buffer",window);
			SoundObject->Release();
			SoundObject = NULL;
			return (FALSE);
		}

		/*
		** Set the format of the primary sound buffer
		**
		*/
		if (!Set_Primary_Buffer_Format()){

			/*
			** If we failed to create a 16 bit primary buffer - try for an 8bit one
			*/
			if (DsBuffFormat.wBitsPerSample == 16){
				/*
				** Save the old values
				*/
				old_bits_per_sample	= DsBuffFormat.wBitsPerSample;
				old_block_align		= DsBuffFormat.nBlockAlign;
				old_bytes_per_sec		= DsBuffFormat.nAvgBytesPerSec;

				/*
				** Set up the 8-bit ones
				*/
				DsBuffFormat.wBitsPerSample	= 8;
				DsBuffFormat.nBlockAlign	= (unsigned short)( (DsBuffFormat.wBitsPerSample/8) * DsBuffFormat.nChannels);
				DsBuffFormat.nAvgBytesPerSec= DsBuffFormat.nSamplesPerSec * DsBuffFormat.nBlockAlign;

				/*
				** Make a copy of the primary buffer description so we can reset its format later
				*/
				memcpy (&PrimaryBufferDesc , &BufferDesc , sizeof(DSBUFFERDESC));
				memcpy (&PrimaryBuffFormat , &DsBuffFormat , sizeof(WAVEFORMATEX));
			}

			if (!Set_Primary_Buffer_Format()){

				/*
				** We failed to set any useful format so print up an error message and give up
				*/
				PrimaryBufferPtr->Release();
				PrimaryBufferPtr = NULL;
				SoundObject->Release();
				SoundObject = NULL;

				Print_Sound_Error("Warning - Your sound card does not meet the products audio requirements",window);

				return (FALSE);
			}else{

				/*
				** OK, got an 8bit sound buffer. Not perfect but it will do
				** We still want 16 bit secondary buffers so restore those values
				*/
				DsBuffFormat.wBitsPerSample	= old_bits_per_sample;
				DsBuffFormat.nBlockAlign		= old_block_align;
				DsBuffFormat.nAvgBytesPerSec	= old_bytes_per_sec;
			}
		}


		/*
		** Start the primary sound buffer playing
		**
		*/if ( PrimaryBufferPtr->Play(0,0,DSBPLAY_LOOPING) != DS_OK ){
			Print_Sound_Error("Unable to play Direct Sound primary buffer",window);
			PrimaryBufferPtr->Release();
			PrimaryBufferPtr = NULL;
			SoundObject->Release();
			SoundObject = NULL;
			return (FALSE);
		}

		LockedData.DigiHandle=1;


		/*
		** Initialise the global critical section object for sound thread syncronisation
		*/
		InitializeCriticalSection(&GlobalAudioCriticalSection);

		/*
		** Initialise the Windows timer system to provide us with a callback
		**
		*/
		SoundTimerHandle = timeSetEvent ( 1000/MAINTENANCE_RATE , 1 , Sound_Timer_Callback , 0 , TIME_PERIODIC);
		AudioDone = FALSE;
		//_beginthread(&Sound_Thread, NULL, 16*1024, NULL);

		/*
		**	Define the format for the secondary sound buffers
		*/
		BufferDesc.dwFlags=DSBCAPS_CTRLVOLUME;
		BufferDesc.dwBufferBytes=SECONDARY_BUFFER_SIZE;
		BufferDesc.lpwfxFormat = (LPWAVEFORMATEX) &DsBuffFormat;



		/*
    	** Allocate a decompression buffer equal to the size of a SONARC frame
		** block.
    	*/
    	LockedData.UncompBuffer = Alloc(LARGEST_SONARC_BLOCK + 50, (MemoryFlagType)(MEM_NORMAL|MEM_CLEAR|MEM_LOCK));

    	/*
    	** Allocate once secondary direct sound buffer for each simultaneous sound effect
		**
    	*/
		for (index = 0; index < MAX_SFX; index++) {

			SoundObject->CreateSoundBuffer (&BufferDesc , &LockedData.SampleTracker[index].PlayBuffer , NULL);

			LockedData.SampleTracker[index].PlaybackRate	= rate;
			LockedData.SampleTracker[index].Stereo			= (stereo) ? AUD_FLAG_STEREO : 0;
			LockedData.SampleTracker[index].BitSize 		= (bits_per_sample == 16) ? AUD_FLAG_16BIT : 0;
			LockedData.SampleTracker[index].FileHandle 	= WW_ERROR;
			LockedData.SampleTracker[index].QueueBuffer 	= NULL;
			InitializeCriticalSection (&LockedData.SampleTracker[index].AudioCriticalSection);

		}

		SoundType = (SFX_Type)sample;
		SampleType = (Sample_Type)sample;
		ReverseChannels = reverse_channels;

	}

	return(TRUE);
}


/***********************************************************************************************
 * Sound_End -- Uninitializes the sound driver.                                                *
 *                                                                                             *
 *    This routine will uninitialize the sound driver (if any was                              *
 *    installed).  This routine must be called at program termination                          *
 *    time.                                                                                    *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   07/23/1991 JLB : Created.                                                                 *
 *   11/02/1995 ST  : Modified for Direct Sound                                                *
 *=============================================================================================*/
void Sound_End(void)
{

	int	index;

	if (SoundObject && PrimaryBufferPtr){
		/*
		** Stop all sounds and release the Direct Sound secondary sound buffers
		*/
		for (index=0 ; index < MAX_SFX; index++){
			if ( LockedData.SampleTracker[index].PlayBuffer ){
				Stop_Sample (index);
				LockedData.SampleTracker[index].PlayBuffer->Stop();
				LockedData.SampleTracker[index].PlayBuffer->Release();
				LockedData.SampleTracker[index].PlayBuffer = NULL;
				DeleteCriticalSection(&LockedData.SampleTracker[index].AudioCriticalSection);
			}
		}
	}

	/*
	** Stop and release the direct sound primary buffer
	*/
	if (PrimaryBufferPtr){
		PrimaryBufferPtr->Stop();
		PrimaryBufferPtr->Release();
		PrimaryBufferPtr = NULL;
	}

	/*
	** Release the Direct Sound Object
	*/
	if (SoundObject){
		SoundObject->Release();
		SoundObject = NULL;
	}


	if (LockedData.UncompBuffer) {
    	Free(LockedData.UncompBuffer);
		LockedData.UncompBuffer = 0;
	}

	/*
	** Remove the Windows timer event we installed for the sound callback
	*/
	if (SoundTimerHandle){
		timeKillEvent(SoundTimerHandle);
		SoundTimerHandle = 0;
	}
	AudioDone = TRUE;

	/*
	** Since the timer has stopped, we are finished with our global critical section.
	*/
	DeleteCriticalSection(&GlobalAudioCriticalSection);
}




/***********************************************************************************************
 * Stop_Sample -- Stops any currently playing sampled sound.                                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/02/1992 JLB : Created.                                                                 *
 *   11/2/95 4:09PM ST : Modified for Direct Sound                                             *
 *=============================================================================================*/
void Stop_Sample(int handle)
{
	if (LockedData.DigiHandle != -1 && (unsigned)handle < MAX_SFX) {

		EnterCriticalSection (&GlobalAudioCriticalSection);

		if (LockedData.SampleTracker[handle].Active || LockedData.SampleTracker[handle].Loading) {

			LockedData.SampleTracker[handle].Active = FALSE;

			if (!LockedData.SampleTracker[handle].IsScore) {
          	LockedData.SampleTracker[handle].Original = NULL;
			}

			LockedData.SampleTracker[handle].Priority = 0;

			/*
          **  Stop the sample if it is playing.
          */
			if (!LockedData.SampleTracker[handle].Loading) {
				LockedData.SampleTracker[handle].PlayBuffer->Stop();
          }

			LockedData.SampleTracker[handle].Loading = FALSE;

          /*
			**  If this is a streaming sample, then close the source file.
          */
			if (LockedData.SampleTracker[handle].FileHandle != WW_ERROR) {
				Close_File(LockedData.SampleTracker[handle].FileHandle);
				LockedData.SampleTracker[handle].FileHandle = WW_ERROR;
			}

			LockedData.SampleTracker[handle].QueueBuffer = NULL;
		}
		LeaveCriticalSection (&GlobalAudioCriticalSection);
	}
}


/***********************************************************************************************
 * Sample_Status -- Queries the current playing sample status (if any).                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/02/1992 JLB : Created.                                                                 *
 *=============================================================================================*/
BOOL Sample_Status(int handle)
{
	DWORD	status;

	/*
	** If its an invalid handle or we do not have a sound driver then
	** the sample in question is not playing.
	*/
	if (LockedData.DigiHandle == -1 || (unsigned)handle >= MAX_SFX) return(FALSE);

	/*
	** If the sample is loading, then for all intents and purposes the
	** sample is playing.
	*/
	if (LockedData.SampleTracker[handle].Loading) return(TRUE);

	/*
	** If the sample is not active, then it is not playing
	*/
	if (!LockedData.SampleTracker[handle].Active) return(FALSE);

	/*
	** If we made it this far, then the Sample is still playing if sos says
	** that it is.
	*/
	DumpBuffer = LockedData.SampleTracker[handle].PlayBuffer;
	if (LockedData.SampleTracker[handle].PlayBuffer->GetStatus( &status ) == DS_OK){
		return ( (DSBSTATUS_PLAYING & status) || (DSBSTATUS_LOOPING & status) );
	}else{
		return (TRUE);
	}
}



/***********************************************************************************************
 * Is_Sample_Playing -- returns the play state of a sample                                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to sample data                                                                *
 *                                                                                             *
 * OUTPUT:   TRUE if sample is currently playing                                               *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:11PM ST : Commented                                                            *
 *=============================================================================================*/

BOOL Is_Sample_Playing(void const * sample)
{
	int index;

	//EnterCriticalSection(&GlobalAudioCriticalSection);

	if (!sample) {
		//LeaveCriticalSection(&GlobalAudioCriticalSection);
		return FALSE;
	}
	for (index = 0; index < MAX_SFX; index++) {
		if (LockedData.SampleTracker[index].Original == sample && Sample_Status(index)) {
			//LeaveCriticalSection(&GlobalAudioCriticalSection);
			return (TRUE);
		}
	}
	//LeaveCriticalSection(&GlobalAudioCriticalSection);
	return (FALSE);
}


/***********************************************************************************************
 * Stop_Sample_Playing -- stops a playing sample                                               *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to sample data                                                                *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:13PM ST : Commented                                                            *
 *=============================================================================================*/

void Stop_Sample_Playing(void const * sample)
{
	int index;

	if (sample) {
		for (index = 0; index < MAX_SFX; index++) {
			if (LockedData.SampleTracker[index].Original == sample) {
				Stop_Sample(index);
				break;
			}
		}
	}
}





/***********************************************************************************************
 * Get_Free_Sample_Handle -- finds a free slot in which to play a new sample                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    priority of sample we want to play                                                *
 *                                                                                             *
 * OUTPUT:   Handle or -1 if none free                                                         *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:14PM ST : Added function header                                                *
 *=============================================================================================*/

int Get_Free_Sample_Handle(int priority)
{
	int     id;

	/*
	**      Find a free SFX holding buffer slot.
	*/
	for (id = MAX_SFX - 1; id >= 0; id--) {
		if (!LockedData.SampleTracker[id].Active && !LockedData.SampleTracker[id].Loading) {
			if (!StartingFileStream && LockedData.SampleTracker[id].IsScore) {
				StartingFileStream = TRUE;      // Ensures only one channel is kept free for scores.
				continue;
			}
			break;
		}
	}

	if (id < 0) {
		for (id = 0; id < MAX_SFX; id++) {
			if (LockedData.SampleTracker[id].Priority <= priority) break;
		}

		if (id == MAX_SFX) {
			return(-1);             // Cannot play!
		}
		Stop_Sample(id);                                                        // This sample gets clobbered.
	}

	if (id == -1) {
		return -1;
	}

	if (LockedData.SampleTracker[id].FileHandle != WW_ERROR) {
		Close_File(LockedData.SampleTracker[id].FileHandle);
		LockedData.SampleTracker[id].FileHandle = WW_ERROR;
	}

	if (LockedData.SampleTracker[id].Original && !LockedData.SampleTracker[id].IsScore) {
		LockedData.SampleTracker[id].Original = NULL;
	}
	LockedData.SampleTracker[id].IsScore = FALSE;
	return(id);
}

int Play_Sample(void const *sample, int priority, int volume, signed short panloc)
{
		  return(Play_Sample_Handle(sample, priority, volume, panloc, Get_Free_Sample_Handle(priority)));
}





/***********************************************************************************************
 * Attempt_Audio_Restore -- tries to restore the direct sound buffers                          *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to direct sound buffer                                                        *
 *                                                                                             *
 * OUTPUT:   TRUE if buffer was successfully restored                                          *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    3/20/96 9:47AM ST : Created                                                              *
 *=============================================================================================*/

BOOL Attempt_Audio_Restore (LPDIRECTSOUNDBUFFER sound_buffer)
{

	int 	return_code;
	DWORD	play_status;
	int	restore_attempts=0;

	/*
	** Call the audio focus loss function if it has been set up
	*/
	if (Audio_Focus_Loss_Function){
		Audio_Focus_Loss_Function();
	}

	/*
	** Try to restore the sound buffer
	*/
	do{
		Restore_Sound_Buffers();
		return_code = sound_buffer->GetStatus ( &play_status );

	} while (restore_attempts++<2 && return_code == DSERR_BUFFERLOST);

	return ((BOOL) ~(return_code == DSERR_BUFFERLOST));
}



/***********************************************************************************************
 * Convert_HMI_To_Direct_Sound_Volume -- Converts a linear volume value into an expotential    *
 *                                        value                                                *
 *                                                                                             *
 * This function converts a linear C&C volume in the range 0-255 (255 loudest) to a direct     *
 *  sound volume in the range 0 to -10000 (with 0 being the loadest)                           *
 *                                                                                             *
 * INPUT:    volume in range 0-255                                                             *
 *                                                                                             *
 * OUTPUT:   volume in range -10000 to 0                                                       *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * Note: The 27.685 value comes from 255 divided by the log of 10001                           *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    9/18/96 11:36AM ST : Created                                                             *
 *=============================================================================================*/
int Convert_HMI_To_Direct_Sound_Volume(int volume)
{
	if (volume == 0) return -10000;
	if (volume == 255) return 0;

	float vol = (float)volume;
	float retval = exp ( (255.0-vol)/27.68597374) -1;
	return ((int)-retval);
}





/***********************************************************************************************
 * Play_Sample_Vol -- Plays a digitized sample.                                                *
 *                                                                                             *
 *    Use this routine to play a previously loaded digitized sample.                           *
 *                                                                                             *
 * INPUT:   sample   -- Sample pointer as returned from Load_Sample.                           *
 *                                                                                             *
 *          volume   -- The volume to play (0..255 with 255=loudest).                          *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/17/1992 JLB : Created.                                                                 *
 *   05/24/1992 JLB : Volume support -- Soundblaster Pro                                       *
 *   04/22/1994 JLB : Multiple sample playback rates.                                          *
 *   11/02/1995 ST  : Windows Direct Sound support                                             *
 *=============================================================================================*/
extern BOOL Any_Locked(void);
int Play_Sample_Handle(void const *sample, int priority, int volume, signed short , int id)
{
	AUDHeaderType                   RawHeader;
	SampleTrackerType               *st=NULL;       // Working pointer to sample tracker structure.

	LPVOID				play_buffer_ptr;		//pointer to locked direct sound buffer
	LPVOID				dummy_buffer_ptr;		//dummy pointer to second area of locked direct sound buffer
	DWORD					lock_length1;
	DWORD					lock_length2;
	DWORD					play_status;
	HRESULT				return_code;
	int					retries=0;


	if (Any_Locked()) return(0);

	st = &LockedData.SampleTracker[id];
	//EnterCriticalSection (&GlobalAudioCriticalSection);

	if (!sample || LockedData.DigiHandle == -1) {
		//LeaveCriticalSection (&GlobalAudioCriticalSection);
		return(-1);
	}

	if (id == -1) {
		//LeaveCriticalSection (&GlobalAudioCriticalSection);
		return -1;
	}

	/*
	**      Fetch the control bytes from the start of the sample data.
	*/
	Mem_Copy((void *)sample, (void *)&RawHeader, sizeof(RawHeader));

	/*
	** Fudge the sample rate to 22k
	*/
	if (RawHeader.Rate <24000 && RawHeader.Rate >20000) RawHeader.Rate = 22050;

	/*
	**      Prepare the sample tracker structure for processing of this
	**      sample.  Fill the structure with data that can be determined
	**      before the sample is started.
	*/
	EnterCriticalSection(&GlobalAudioCriticalSection);
	st->Compression 			= (SCompressType) ((unsigned char)RawHeader.Compression);
	st->Original            = sample;
	st->OriginalSize        = RawHeader.Size + sizeof(RawHeader);
	st->Priority            = (short)priority;
	st->DontTouch           = TRUE;
	st->Odd						= 0;
	st->Reducer             = 0;
	st->Restart             = FALSE;
	st->QueueBuffer 			= NULL;
	st->QueueSize           = NULL;
	st->TrailerLen  			= 0;
	st->Remainder           = RawHeader.Size;
	st->Source              = Add_Long_To_Pointer((void *)sample, sizeof(RawHeader));
	st->Service             = FALSE;
	LeaveCriticalSection(&GlobalAudioCriticalSection);

    /*
	 ** If the code in question using HMI based compression then we need
    ** to set up for uncompressing it.
	 */
    if (st->Compression == SCOMP_SOS) {
		st->sosinfo.wChannels    = (RawHeader.Flags & AUD_FLAG_STEREO) ? 2  : 1;
		st->sosinfo.wBitSize             = (RawHeader.Flags & AUD_FLAG_16BIT)  ? 16 : 8;
		st->sosinfo.dwCompSize   = RawHeader.Size;
		st->sosinfo.dwUnCompSize = RawHeader.Size * ( st->sosinfo.wBitSize / 4 );
		sosCODECInitStream(&st->sosinfo);
	}

	/*
	** If the sample rate , bits per sample or stereo capabilities of the buffer do not
	** match the sample then reallocate the direct sound buffer with the required capabilities
	*/
	if (  ( RawHeader.Rate != st->PlaybackRate ) ||
			( ( RawHeader.Flags & AUD_FLAG_16BIT ) != ( st->BitSize & AUD_FLAG_16BIT ) ) ||
			( ( RawHeader.Flags & AUD_FLAG_STEREO) != ( st->Stereo & AUD_FLAG_STEREO ) ) ) {

		st->Active=0;
		st->Service=0;
		st->MoreSource=0;

		/*
		** Stop the sound buffer playing
		*/
		DumpBuffer = st->PlayBuffer;
		do {
			return_code = st->PlayBuffer->GetStatus ( &play_status );
			if (return_code==DSERR_BUFFERLOST){
				if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
			}
		}while (return_code == DSERR_BUFFERLOST);

		if (play_status & (DSBSTATUS_PLAYING | DSBSTATUS_LOOPING) ){
			st->PlayBuffer->Stop();
			if (return_code==DSERR_BUFFERLOST){
				if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
			}
		}

		st->PlayBuffer->Release();
		st->PlayBuffer=NULL;

		DsBuffFormat.nSamplesPerSec	= (unsigned short int) RawHeader.Rate;
		DsBuffFormat.nChannels			= (RawHeader.Flags & AUD_FLAG_STEREO) ? 2 : 1 ;
		DsBuffFormat.wBitsPerSample	= (RawHeader.Flags & AUD_FLAG_16BIT) ? 16 : 8 ;
		DsBuffFormat.nBlockAlign	= (short) ((DsBuffFormat.wBitsPerSample/8) * DsBuffFormat.nChannels);
		DsBuffFormat.nAvgBytesPerSec= DsBuffFormat.nSamplesPerSec * DsBuffFormat.nBlockAlign;

		/*
		** Create the new sound buffer
		*/
		return_code= SoundObject->CreateSoundBuffer (&BufferDesc , &st->PlayBuffer , NULL);
		if (return_code==DSERR_BUFFERLOST){
			if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
		}
		/*
		** Just return if the create failed unexpectedly
		**
		** If we failed then flag the buffer as having an impossible format so it wont match
		** any sample. This will ensure that we try and create the buffer again next time its used.
		*/
		if (return_code!=DS_OK && return_code!=DSERR_BUFFERLOST){
			st->PlaybackRate = 0;
			st->Stereo = 0;
			st->BitSize = 0;
			return(-1);
		}

		/*
		** Remember the format of the new buffer
		*/
		st->PlaybackRate 	= RawHeader.Rate;
		st->Stereo			= RawHeader.Flags & AUD_FLAG_STEREO;
		st->BitSize 		= RawHeader.Flags & AUD_FLAG_16BIT;
	}

	/*
	**      Fill in 3/4 of the play buffer.
	*/

	//
	// Stop the sound buffer playing before we lock it
	//
	do {
		DumpBuffer = st->PlayBuffer;
		return_code = st->PlayBuffer->GetStatus ( &play_status );
		if (return_code==DSERR_BUFFERLOST){
			if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
		}
	} while (return_code==DSERR_BUFFERLOST);

	if (play_status & (DSBSTATUS_PLAYING | DSBSTATUS_LOOPING) ){
		st->Active=0;
		st->Service=0;
		st->MoreSource=0;
		st->PlayBuffer->Stop();
	}
	//
	// Lock the direct sound buffer so we can write to it
	//
	do {
		return_code = st->PlayBuffer->Lock (	0 ,
										SECONDARY_BUFFER_SIZE,
										&play_buffer_ptr,
										&lock_length1,
										&dummy_buffer_ptr,
										&lock_length2,
										0 );
		if (return_code==DSERR_BUFFERLOST){
			if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
		}
	} while (return_code==DSERR_BUFFERLOST);

	if (return_code != DS_OK) {
		//LeaveCriticalSection (&GlobalAudioCriticalSection);
		return (-1);
	}

	//
	// Decompress the sample into the direct sound buffer
	//
	st->DestPtr=(void*)Sample_Copy ( 	st,
								&st->Source,
								&st->Remainder,
								&st->QueueBuffer,
								&st->QueueSize,
								play_buffer_ptr,
								SECONDARY_BUFFER_SIZE*1/4,
								st->Compression,
								&st->Trailer[0],
								&st->TrailerLen);

	if ( st->DestPtr==(void*) (SECONDARY_BUFFER_SIZE*1/4) ){

		// Must be more data to copy so we dont need to zero the buffer
		st->MoreSource=TRUE;
		st->Service=TRUE;
		st->OneShot=FALSE;
	} else {

		// Whole sample is in the buffer so flag that we dont need to
		// copy more. Clear out the end of the buffer so that it
		// goes quiet if we play past the end
		st->MoreSource=FALSE;
		st->OneShot=TRUE;
		st->Service=TRUE;				//We still need to service it so that we can stop it when
											// it plays past the end of the sample data
		//memset ( (char*)( (unsigned)play_buffer_ptr + (unsigned)st->DestPtr ), 0 , SECONDARY_BUFFER_SIZE - (unsigned)st->DestPtr );
		memset ( (char*)( (unsigned)play_buffer_ptr + (unsigned)st->DestPtr ), 0 , SECONDARY_BUFFER_SIZE/4);
	}

	st->PlayBuffer->Unlock(	play_buffer_ptr,
							lock_length1,
							dummy_buffer_ptr,
							lock_length2);


	/*
    **
    **  Set the volume of the sample.
    **
    */
	st->Volume = (volume << 7);
	do {

		//return_code = st->PlayBuffer->SetVolume ( Convert_HMI_To_Direct_Sound_Volume(volume));
		st->PlayBuffer->SetVolume ( Convert_HMI_To_Direct_Sound_Volume( ( LockedData.SoundVolume*volume)/256) );
		//return_code = st->PlayBuffer->SetVolume (- ( ( (32768- ( (st->Volume >> 8) *LockedData.SoundVolume) )
		//															*1000) >>15 ) );
		if (return_code==DSERR_BUFFERLOST){
			if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
		}
	} while (return_code==DSERR_BUFFERLOST);


	/*
	** Make sure the primary sound buffer is playing
	*/
	if (!Start_Primary_Sound_Buffer(FALSE)){
		//LeaveCriticalSection (&GlobalAudioCriticalSection);
		return(-1);
	}


	/*
	** Set the buffers play pointer to the beginning of the buffer
	*/
	do {
		return_code = st->PlayBuffer->SetCurrentPosition (0);
		if (return_code==DSERR_BUFFERLOST){
			if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
		}
	} while (return_code==DSERR_BUFFERLOST);


	/*
    ** Start the sample playing now.
	*/
	do
	{
		return_code = st->PlayBuffer->Play (0,0,DSBPLAY_LOOPING);

		switch (return_code){

			case DS_OK :
				EnterCriticalSection (&GlobalAudioCriticalSection);
				st->Active=TRUE;
				st->Handle=(short)id;
				st->DontTouch = FALSE;
				LeaveCriticalSection (&GlobalAudioCriticalSection);
				return (st->Handle);

			case DSERR_BUFFERLOST :
				if (!Attempt_Audio_Restore(st->PlayBuffer)) return(-1);
				break;

			default:
				st->Active=FALSE;
				//LeaveCriticalSection (&GlobalAudioCriticalSection);
				return (st->Handle);
		}

	} while (return_code==DSERR_BUFFERLOST);

	//LeaveCriticalSection (&GlobalAudioCriticalSection);
	return (st->Handle);
}





/***********************************************************************************************
 * Restore_Sound_Buffers -- restore the sound buffers                                          *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/3/95 3:53PM ST : Created                                                              *
 *=============================================================================================*/

void Restore_Sound_Buffers ( void )
{

	if (PrimaryBufferPtr){
		PrimaryBufferPtr->Restore();
	}


	for ( int index = 0; index < MAX_SFX; index++) {
		if (LockedData.SampleTracker[index].PlayBuffer){
			LockedData.SampleTracker[index].PlayBuffer->Restore();
		}
	}
}








/***********************************************************************************************
 * Set_Sound_Vol -- sets the overall volume for sampled sounds                                 *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    volume                                                                            *
 *                                                                                             *
 * OUTPUT:   the previous volume setting                                                       *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:19PM ST : Added function header                                                *
 *=============================================================================================*/

int Set_Sound_Vol(int volume)
{
	int old;
 	old = LockedData.SoundVolume;
 	LockedData.SoundVolume = volume & 0xFF;
	return(old);
}


/***********************************************************************************************
 * Set_Score_Vol -- sets the overall volume for music scores                                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    volume                                                                            *
 *                                                                                             *
 * OUTPUT:   the previous volume setting                                                       *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:19PM ST : Added function header                                                *
 *=============================================================================================*/
int Set_Score_Vol(int volume)
{
	int old;
	SampleTrackerType	*st;					//ptr to SampleTracker structure

	old = LockedData.ScoreVolume;
	LockedData.ScoreVolume = volume & 0xFF;

	for (int index=0 ; index<MAX_SFX ; index++){
		st = &LockedData.SampleTracker[index];

		if (st->IsScore && st->Active){
			//st->PlayBuffer->SetVolume (- ( ( (32768- ( (st->Volume >> 8) *LockedData.ScoreVolume) )
			//														*1000) >>15 ) );

			//st->PlayBuffer->SetVolume ( Convert_HMI_To_Direct_Sound_Volume ( st->Volume >>7 ) );
			st->PlayBuffer->SetVolume ( Convert_HMI_To_Direct_Sound_Volume( ( LockedData.ScoreVolume*(st->Volume >>7))/256) );
		}
	}
	return(old);
}



/***********************************************************************************************
 * Fade_Sample -- Start a sample fading                                                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Sample handle                                                                     *
 *           fade rate                                                                         *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/2/95 4:21PM ST : Added function header                                                *
 *=============================================================================================*/

void Fade_Sample(int handle, int ticks)
{
	if (Sample_Status(handle)) {
    	if (!ticks || LockedData.SampleTracker[handle].Loading) {
       	Stop_Sample(handle);
			} else {
				SampleTrackerType * st;
				st = &LockedData.SampleTracker[handle];
				st->Reducer = (short) ((st->Volume / ticks)+1);
			}
	}
}



int Get_Digi_Handle(void)
{
        return(LockedData.DigiHandle);
}



/***************************************************************************
 * SAMPLE_LENGTH -- returns length of a sample in ticks                    *
 *                                                                         *
 * INPUT:  void const *sample - pointer to the sample to get length of.    *
 *                                                                         *
 * OUTPUT: long - length of the sample in ticks (60/sec)                   *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/05/1995 PWG : Created.                                             *
 *=========================================================================*/
long Sample_Length(void const *sample)
{
	AUDHeaderType	RawHeader;

	if (!sample) return(0);

	Mem_Copy((void *)sample, (void *)&RawHeader, sizeof(RawHeader));

	long time = RawHeader.UncompSize;

	/*
	** If the sample is a 16 bit sample, then it will take only half
	** as long to play.
	*/
	if (RawHeader.Flags & AUD_FLAG_16BIT) {
		time >>= 1;
	}

	/*
	** If the sample is a stereo sample, then it will take only half
	** as long to play.
	*/
	if (RawHeader.Flags & AUD_FLAG_STEREO) {
		time >>= 1;
	}

	if (RawHeader.Rate/60) {
		time /= (RawHeader.Rate/60);
	}
	return(time);
}



/***********************************************************************************************
 * Start_Primary_Sound_Buffer -- start the primary sound buffer playing                        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    2/1/96 12:28PM ST : Created                                                              *
 *=============================================================================================*/
extern BOOL GameInFocus;
BOOL Start_Primary_Sound_Buffer (BOOL forced)
{
	DWORD status;

	if (PrimaryBufferPtr && GameInFocus){
		if (forced){
			PrimaryBufferPtr->Play(0,0,DSBPLAY_LOOPING);
			return (TRUE);
		} else {

			if (PrimaryBufferPtr->GetStatus (&status) == DS_OK){
				if (! ((status & DSBSTATUS_PLAYING) || (status & DSBSTATUS_LOOPING))){
					PrimaryBufferPtr->Play(0,0,DSBPLAY_LOOPING);
					return (TRUE);
				}else{
					return (TRUE);
				}
			}
		}
	}
	return (FALSE);
}


/***********************************************************************************************
 * Stop_Primary_Sound_Buffer -- stops the primary sound buffer from playing.                   *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: This stops all sound playback                                                     *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    2/1/96 12:28PM ST : Created                                                              *
 *=============================================================================================*/

void Stop_Primary_Sound_Buffer (void)
{
	if (PrimaryBufferPtr){
		PrimaryBufferPtr->Stop();
		PrimaryBufferPtr->Stop();	      // Oh I
		PrimaryBufferPtr->Stop();			// Hate Direct Sound
		PrimaryBufferPtr->Stop();			// So much.....
	}

	for ( int index = 0; index < MAX_SFX; index++) {
		Stop_Sample(index);
	}

}


void Suspend_Audio_Thread(void)
{
	if (SoundThreadActive){
		//SuspendThread(SoundThreadHandle);
		timeKillEvent(SoundTimerHandle);
		SoundTimerHandle = NULL;
		SoundThreadActive = FALSE;
	}
}




void Resume_Audio_Thread(void)
{
	if (!SoundThreadActive){
		//ResumeThread(SoundThreadHandle);
		SoundTimerHandle = timeSetEvent ( 1000/MAINTENANCE_RATE , 1 , Sound_Timer_Callback , 0 , TIME_PERIODIC);
		SoundThreadActive = TRUE;
	}
}


