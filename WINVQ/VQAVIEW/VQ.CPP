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
 *                 Project Name : VQAVIEW                                  *
 *                                                                         *
 *                    File Name : VQ.CPP                                   *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date :                                          *
 *                                                                         *
 *                  Last Update : May 31, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * Initialize_VQA_System - Allocate memory needed for caching and any		  *
 *		permanent VQA data.																  *
 * Free_VQA_System - Free up memory used by VQA cache system and any 		  *
 *		permanent VQA data.																  *
 *   Disk_VQA_Stream_Handler -- Handles file io for VQAs run from disk.    *
 *   VQ_Drawer_Callback -- Blits the frame to the screen.                  *
 *   VQAClass::VQAClass -- Constructor for VQAClass object.                *
 *   VQAClass::Update_Palette -- Updates the system palette.               *
 *   VQAClass::Open_And_Load_Buffers -- Opens VQA file, fills frame buffers*
 *   VQAClass::Seek_To_Frame -- Performs file seek to specified frame.     *
 *   VQAClass::Play_VQA - Plays from the current frame of the VQA up to    *
 *		and including the last frame specified.									  *
 *   VQAClass::Play_Generic_VQA -- Private func to play any Monopoly VQA.  *
 *   VQAClass::Play_VQA_Frame - Plays the specified frame,seek if necessary*
 *   VQAClass::Pause_VQA - Pauses a VQA in order to freeze the VQA timers. *
 *   VQAClass::Close_And_Free_VQA -- Closes vqa, frees instanc, frees cache*
 *   Check_Key -- NULL function for VQA play library.                      *
 *   Get_Key -- NULL function for VQA play library.                        *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


//==========================================================================
// INCLUDES
//==========================================================================

#include <windows.h>
#include <windowsx.h>
#include <westwood.h>
#include <file.h>
#include <stdio.h>
#include <memflag.h>
#include <vq.h>
#include <mainwind.h>
#include <pal.h>
#include <wwstd.h>
#include <gbuffer.h>
#include <main.h>
#include <monochrm.h>
#include <vidmode.h>
#include <movies.h>
#include <gametime.h>
#include <dialogs.rh>
#include <vqm32\compress.h>

//==========================================================================
// PRIVATE DEFINES
//==========================================================================

#define DEBUG_CODE						TRUE
#define DEBUG_MOVIE_FRAME_RATE    -1


//==========================================================================
// PRIVATE FUNCTIONS
//==========================================================================

long Disk_VQA_Stream_Handler(
		VQAHandle *vqa_handle, long action, void *buffer, long nbytes );

#if( DEBUG_CODE )
BOOL Set_Frame_Rate_Dialog_Procedure(
	WindowHandle window_handle,
	UINT message,
	WPARAM w_param,
	LPARAM l_param );
#endif

//==========================================================================
// PRIVATE GLOBALS
//==========================================================================

#if( DEBUG_CODE )
	int Debug_Movie_Frame_Rate = -1;
#endif


/***************************************************************************
 * VQAClass::VQAClass -- Constructor for VQAClass object.                  *
 *                                                                         *
 * INPUT:                                                                  *
 *   base_filename - vqa filename without the extension.						  *
 *   buffer - buffer to draw to.														  *
 *   callback - pointer to function that will blit the drawn frames.       *
 *   media_source - either FROM_MEMORY or FROM_DISK.							  *
 *   id - more specific info about the vqa, like exact property location.  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY: See PVCS log                                                   *
 *=========================================================================*/
VQAClass::VQAClass( char *filename, char *buffer, short media_src, long (*callback) (unsigned char *, long) )
{
	// Initialize config options.
	VQA_DefaultConfig( &vqa_config );

	//-------------------------------------------------------------------------
	// Set up video config options.
	//-------------------------------------------------------------------------
	vqa_config.Vmode = 0;
	vqa_config.ImageBuf = (unsigned char *)buffer;

	//
	// Set up draw options.
	//
	vqa_config.DrawFlags = VQACFGF_TOPLEFT;
	vqa_config.DrawFlags |= VQACFGF_BUFFER;
	//vqa_config.DrawFlags |= VQACFGF_NOSKIP;

	//
	// Set the dimensions of the draw buffer.
	//
	vqa_config.ImageWidth = MOVIE_WIDTH;
	vqa_config.ImageHeight = MOVIE_HEIGHT;
	vqa_config.X1 = 0;
	vqa_config.Y1 = 0;

	//
	// Set up the drawer callback for the VQA.
	//
	vqa_config.DrawerCallback = callback;

	//
	// Set the load rate (it is misnamed FrameRate)
	//
	vqa_config.FrameRate = -1;

	//
	// Set the frame rate (DrawRate)
	//
	vqa_config.DrawRate = -1;

	#if( DEBUG_CODE )
		vqa_config.FrameRate = Debug_Movie_Frame_Rate;
		vqa_config.DrawRate = Debug_Movie_Frame_Rate;
		vqa_config.FrameRate = DEBUG_MOVIE_FRAME_RATE;
		vqa_config.DrawRate = DEBUG_MOVIE_FRAME_RATE;
	#endif

	vqa_config.SoundObject = NULL;	//Get_Sound_Object();
	vqa_config.PrimaryBufferPtr = NULL;	//Get_Primart_Buffer();

	//-------------------------------------------------------------------------
	// Create a VQ instance for playing from memory - does not actually allocate buffers.
	//-------------------------------------------------------------------------
	vqa_handle = VQA_Alloc();

	//
	// Set the IO handler for this VQ instance.
	//
	media_source = media_src;
	switch( media_source ) {
		case FROM_DISK:
		default:
			vqa_config.NumFrameBufs = 6;
			vqa_config.NumCBBufs = 3;
			VQA_Init( vqa_handle, Disk_VQA_Stream_Handler );
			break;
	}

	//-------------------------------------------------------------------------
	// Initialize private class variables.
	//-------------------------------------------------------------------------

	for (int i=0 ; i<50 ; i++){
		InterpolatedPalettes[i] = NULL;
	}

	// Init file_handle
	file_handle = NULL;

	// Initialize starting frame number to first frame of movie.
	current_frame = 0;

	// Set total frames.
	total_frames = 0;

	// Save the base filename for this VQA instance.
	strcpy( base_filename, filename );

	// Save the vqa filename for this VQA instance.
	sprintf( vqa_filename, "%s.vqa", filename );

	// Initially, vqa is not open.
	vqa_is_open = FALSE;

}


VQAClass::~VQAClass(void)
{
	for (int i=0 ; i<50 ;i++){
		if (InterpolatedPalettes[i]){
			free (InterpolatedPalettes[i]);
		}
	}
}


/***************************************************************************
 * DISK_VQA_STREAM_HANDLER -- Handles file io for VQAs run from disk.      *
 *                                                                         *
 * INPUT:                                                                  *
 *    vqa_handle - pointer to the vqa instance.                            *
 *    action - specifies the io operation to be performed.					  *
 *    buffer - buffer to write out or read into.									  *
 *    nbytes - number of bytes to read, write, seek...							  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY: See PVCS log                                                   *
 *=========================================================================*/
long Disk_VQA_Stream_Handler(
	VQAHandle *vqa_handle, long action, void *buffer, long nbytes)
{
	unsigned char	temp_char;
	int				fh;
	long				error;

	fh = vqa_handle->VQAio;

	//
	// Perform the action specified by the stream command.
	//
	switch ( action ) {

		//
		// VQACMD_READ means read NBytes from the stream and place it in the
		// memory pointed to by Buffer.
		//
		// Any error code returned will be remapped by VQA library into
		// VQAERR_READ.
		//
		case VQACMD_READ:
			error = ( Read_File( fh, buffer, nbytes ) != nbytes );
			break;

		//
		// VQACMD_WRITE is analogous to VQACMD_READ.
		//
		// Writing is not allowed to the VQA file, VQA library will remap the
		// error into VQAERR_WRITE.
		//
		case VQACMD_WRITE:
			error = 1;
			break;

		//
		// VQACMD_SEEK asks that you perform a seek relative to the current
		// position. NBytes is a signed number, indicating seek direction
		// (positive for forward, negative for backward). Buffer has no meaning
		// here.
		//
		// Any error code returned will be remapped by VQA library into
		// VQAERR_SEEK.
		//
		case VQACMD_SEEK:
			//
			// In order to force a physical seek, we must seek to a position that
			// is one byte before our real destination, and then read one byte.
			//
			if ( nbytes > 0 ) {
				nbytes -= 1;
				error = ( Seek_File( fh, nbytes, (long) buffer ) == 0 );
				Read_File( fh, &temp_char, 1 );
			}
			else {
				error = ( Seek_File( fh, nbytes, (long) buffer ) == 0 );
			}
			break;

		//
		// VQACMD_OPEN asks that you open your stream for access.
		//
		case VQACMD_OPEN:
			error = Open_File( (char const *) buffer, READ );
			if ( error != WW_ERROR ) {
				vqa_handle->VQAio = error;
				error = 0;
			}
			else {
				error = TRUE;
			}

			break;

		case VQACMD_CLOSE:
			Close_File( fh );
			error = 0;
			break;

		//
		// VQACMD_INIT means to prepare your stream for reading. This is used for
		// certain streams that can't be read immediately upon opening, and need
		// further preparation. This operation is allowed to fail; the error code
		// will be returned directly to the client.
		//
		case VQACMD_INIT:
			error = 0;
			break;

		//
		// VQACMD_CLEANUP means to terminate the transaction with the associated
		// stream. This is used for streams that can't simply be closed. This
		// operation is not allowed to fail; any error returned will be ignored.
		//
		case VQACMD_CLEANUP:
			error = 0;
			break;
	}

	return ( error );
}



/***********************************************************************************************
 * Increase_Palette_Luminance -- increase contrast of colours in a palette                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to palette                                                                    *
 *           percentage increase of red                                                        *
 *           percentage increase of green                                                      *
 *           percentage increase of blue                                                       *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/12/95 12:16PM ST : Created                                                            *
 *=============================================================================================*/

void Increase_Palette_Luminance (unsigned char *palette , int red_percentage , int green_percentage , int blue_percentage)
{

	unsigned	int	red;
	unsigned	int	green;
	unsigned	int	blue;
	for (int i=0 ; i<SIZE_OF_PALETTE*3 ; i+=3){

		red 	= (unsigned)*(palette+i);
		green = (unsigned)*(palette+i+1);
		blue	= (unsigned)*(palette+i+2);

		red 	+= red*red_percentage/100;
		green	+= green*green_percentage/100;
		blue	+= blue*blue_percentage/100;

		red 	= MIN (255,red);
		green	= MIN (255,green);
		blue	= MIN (255,blue);

		*(palette+i)	=(unsigned char)red;
		*(palette+i+1)	=(unsigned char)green;
		*(palette+i+2)	=(unsigned char)blue;

	}

}

/***************************************************************************
 * VQACLASS::UPDATE_PALETTE -- Updates the system and WinG palettes.       *
 *                                                                         *
 * INPUT:                                                                  *
 *    none																					  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *    TRUE																					  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *    See PVCS log																			  *
 *=========================================================================*/
extern BOOL SuspendAudioCallback;
extern "C" unsigned char Palette_Interpolation_Table[ SIZE_OF_PALETTE ][ SIZE_OF_PALETTE ];
BOOL VQAClass::Update_Palette( unsigned char *newpalette )
{
	unsigned char *pal_src = newpalette;
	unsigned char *pal_dst = palette;

	for (int j=0 ; j<SIZE_OF_PALETTE*3 ; j++){
		*pal_dst++ = (*pal_src++)<<2;
	}

	//Increase_Palette_Luminance(palette , 30 , 30 , 30);
	Update_Full_Palette( palette );


	/*
	**  If there was no palette table on disk then create one
	*/
	if (PalettesRead){
		memcpy (&Palette_Interpolation_Table[0][0] , InterpolatedPalettes[NumPalettes] , 65536);
		NumPalettes++;
	} else {

		SuspendAudioCallback = TRUE;
		Create_Palette_Interpolation_Table();

		for (int i=0 ; i<50 ;i++){
			if (!InterpolatedPalettes[i]){
				InterpolatedPalettes[i] = (unsigned char*)malloc (SIZE_OF_PALETTE*SIZE_OF_PALETTE);
				memcpy (InterpolatedPalettes[i] , &Palette_Interpolation_Table[0][0] , SIZE_OF_PALETTE*SIZE_OF_PALETTE);
				NumPalettes++;
				break;
			}
		}

		SuspendAudioCallback = FALSE;
	}

	return( TRUE );
}




/***********************************************************************************************
 * Strip_Interpolated_Palette -- strip the redundancy out of an interpolated palette table     *
 *                                                                                             *
 * This just replaces the redundant entries with zeros so the palette will compress better     *
 *                                                                                             *
 * INPUT:    ptr to palette                                                                    *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/21/95 10:34AM ST : Created                                                            *
 *=============================================================================================*/
void Strip_Interpolated_Palette(unsigned char *interpal)
{
	for (int y=0 ; y<255 ;y++){
		memset (interpal + (y*256+y+1), 0 , 256-y-1);
	}
}


/***********************************************************************************************
 * Rebuild_Interpolated_Palette -- rebuilds the entries stripped by Strip_Interpolated_Palette *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to palette                                                                    *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    12/21/95 10:35AM ST : Created                                                            *
 *=============================================================================================*/
void Rebuild_Interpolated_Palette(unsigned char *interpal)
{
	for (int y=0 ; y<255 ; y++){
		for (int x=y+1 ; x<256 ; x++){
			*(interpal + (y*256+x)) = *(interpal + (x*256+y));
		}
	}
}



/***********************************************************************************************
 * VQAC::Read_Palettes -- read the associated palette interpolation tables from disk           *
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
 *    12/21/95 10:36AM ST : Created                                                            *
 *=============================================================================================*/

void VQAClass::Read_Palettes(void)
{
	unsigned char 	*comp_buff = (unsigned char*)malloc(65536);
	unsigned			comp_size;

	NumPalettes=0;
	PalettesRead = FALSE;

	/*
	** Create the palette file name from the VQ file name. Palette files have .VQP ext
	*/
	memcpy (&PaletteFilename[0] , &vqa_filename[0] , _MAX_PATH);
	for (int i=0 ; i<_MAX_PATH ; i++){
		if (PaletteFilename[i] == '.'){
			PaletteFilename[i+1] = 'V';
			PaletteFilename[i+2] = 'Q';
			PaletteFilename[i+3] = 'P';
			PaletteFilename[i+4] = 0;
			break;
		}
	}

	/*
	** If the palette file is available the open it
	*/
	PaletteFile = new RawFileClass (PaletteFilename);
	if (PaletteFile->Is_Available()){

		PaletteFile->Open(READ);

		/*
		** Find out how many palettes are in the file
		*/
		PaletteFile->Read(&NumPalettes , 4);

		/*
		** Read each palette. Palettes are all the same size.
		*/
		for (i=0 ; i<NumPalettes ; i++){
			InterpolatedPalettes[i] = (unsigned char *)malloc (65536);
			memset (InterpolatedPalettes[i],0,65536);

			for (int y=0 ; y<256 ;y++){
				PaletteFile->Read (InterpolatedPalettes[i] + y*256 , y+1);
			}

			//PaletteFile->Read(&comp_size,4);
			//PaletteFile->Read(comp_buff , comp_size);
			//LCW_Uncompress((char const*)comp_buff,(char*)InterpolatedPalettes[i],65536);

			/*
			** Rebuild the entries that were lost when the palette was written to disk
			*/
			Rebuild_Interpolated_Palette(InterpolatedPalettes[i]);
		}

		PalettesRead = TRUE;
		PaletteFile->Close();
		NumPalettes = 0;

	}
	delete PaletteFile;
}





/***********************************************************************************************
 * VQAC::Write_Palettes -- write the palette interpolation tables to disk                      *
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
 *    12/21/95 10:37AM ST : Created                                                            *
 *=============================================================================================*/

void VQAClass::Write_Palettes(void)
{
	unsigned char 	*comp_buff = (unsigned char*)malloc(65536);
	unsigned			comp_size;

	/*
	** If the palette file wasnt there when we started playing the VQ then create one
	*/
	if (NumPalettes && !PalettesRead){

		PaletteFile = new RawFileClass (PaletteFilename);
		PaletteFile->Open(WRITE);

		/*
		** Write the number of palettes we created
		*/
		PaletteFile->Write(&NumPalettes , 4);

		/*
		** Write the non-redundant palette table entries for each palette table
		*/
		for (int i=0 ; i<NumPalettes ; i++){
			//Strip_Interpolated_Palette(InterpolatedPalettes[i]);
			//comp_size = LCW_Compress ((char const*)InterpolatedPalettes[i] , (char*)comp_buff , 65536);


			for (int y=0 ; y<256 ;y++){
				PaletteFile->Write (InterpolatedPalettes[i] + y*256 , y+1);
			}
		}
		PaletteFile->Close();
		delete PaletteFile;
	}
}



/***************************************************************************
 * VQACLASS::OPEN_AND_LOAD_BUFFERS -- Opens VQA file and fills frame buffrs*
 *                                                                         *
 * INPUT:                                                                  *
 *    none																					  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *    TRUE if successful        														  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log																			  *
 *=========================================================================*/
BOOL VQAClass::Open_And_Load_Buffers( void )
{
	VQAInfo	vqa_info;
	unsigned char		*pal_ptr;
	INT		i;


	//
	// Open the VQA file, allocate the buffers for this VQ instance, and pre-
	// load the buffers.
	//
	if ( VQA_Open( vqa_handle, vqa_filename, &vqa_config ) != 0 ) {
		vqa_is_open = FALSE;
		return( FALSE );
	}
#if (0)
	//
	// Get the VQA's palette.
	//
	pal_ptr = (unsigned char *) VQA_GetPalette( vqa_handle );
	if ( pal_ptr ) {

		//
		// Get a copy of the VQA's palette.
		//
		Mem_Copy( pal_ptr, palette, ( SIZE_OF_PALETTE * 3 ) );

		//
		// The palette in the VQA files is 6-bit per pixel, so shift all the
		// values to make them 8-bits per pixel.
		//
		for ( i = 0; i < ( SIZE_OF_PALETTE * 3 ); i ++ ) {
			palette[ i ] <<= 2;
		}
	}
#endif
	//
	// Get frame information about the VQA.
	//
	VQA_GetInfo( vqa_handle, &vqa_info );
	total_frames = vqa_info.NumFrames;

	vqa_is_open = TRUE;

	return( TRUE );
}



/***************************************************************************
 * VQACLASS::SEEK_TO_FRAME -- Performs file seek to specified frame.       *
 *                                                                         *
 * INPUT:                                                                  *
 *    frame - frame number to seek to.												  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *    none																					  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log																			  *
 *=========================================================================*/
void VQAClass::Seek_To_Frame( unsigned long frame )
{
	//
	// Don't bother seeking if already there.
	//
	if ( frame == current_frame ) {
		return;
	}

	if ( VQA_SeekFrame( vqa_handle, frame, SEEK_SET ) != -1 ) {
		current_frame = frame;
	}
}

/***************************************************************************
 * Play_VQA - Plays from the current frame of the VQA up to and including  *
 *		the last frame specified.														  *
 *                                                                         *
 * INPUT: INT last_frame - last frame to be displayed                      *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   02/20/1995  MG : Created.                                             *
 *=========================================================================*/
int VQAClass::Play_VQA( int last_frame_to_play )
{
	INT return_code;

	#if( DEBUG_CODE )
		VQAStatistics	vqa_stats;
		float				frames_per_sec;
		unsigned long	start_time;
		unsigned long	end_time;
	#endif

	//
	// Before starting to play, make sure we have the correct palette.
	//
	//Update_Palette();

//
// Create table for scaling low-res VQA's.
//

	//Create_Palette_Interpolation_Table();

	//
	// Get current time for timing purposes.
	//
	#if( DEBUG_CODE )
		start_time = Get_Game_Time();
	#endif

	//
	// Call the appropriate play routine.
	//
	return_code = Play_Generic_VQA( last_frame_to_play );

	//
	// Get VQA statistics.
	//
	#if( DEBUG_CODE )
		end_time = Get_Game_Time();
		VQA_GetStats( vqa_handle, &vqa_stats );
		if ( ( end_time - start_time ) <= 0.0 ) {
			frames_per_sec = 0.0;
		}
		else {
			frames_per_sec = vqa_stats.FramesDrawn / ( ( end_time - start_time ) / 1000.0 );
		}
		Debug_Printf( "Frames drawn=%d. Frames/sec=%03.02f. Frames skipped = %d\r\n", vqa_stats.FramesDrawn, frames_per_sec, vqa_stats.FramesSkipped );
	#endif

	//
	// If PLAY_ALL_FRAMES was specified, reset curr frame to beginning of movie.
	//
	if ( last_frame_to_play == PLAY_ALL_FRAMES ) {
		current_frame = 0;
	}

	return( return_code );
}


/***************************************************************************
 * VQACLASS::PLAY_GENERIC_VQA -- Private func to play any Monopoly VQA.    *
 *                                                                         *
 * INPUT:                                                                  *
 *   last_frame_to_play - last frame to be drawn.								  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *   INT error code.																		  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log																			  *
 *=========================================================================*/
int VQAClass::Play_Generic_VQA( int last_frame_to_play )
{
	long				errval;

	switch( last_frame_to_play ) {
		case PLAY_ALL_FRAMES:
			Seek_To_Frame( 0 );
			// FALL THROUGH...
		case PLAY_TO_END_OF_MOVIE:
			last_frame_to_play = total_frames - 1;
			break;
	}

	//
	// Play frames until the last desired frame is drawn.
	//
	errval = 0;

	while (
		( errval == VQAERR_NOT_TIME || errval >= 0 || errval == VQAERR_NOBUFFER || errval == VQAERR_SLEEPING ) &&
		( current_frame <= last_frame_to_play ) ) {

		//
		// Check for Windows Messages.
		//
		Main_Window.Update_Windows_Messages();

		#if( DRAW_TO_VIDEO )
			Screen_Buffer->Lock();
		#endif

		//
		// Maybe draw another frame.
		//
		errval = VQA_Play( vqa_handle, VQAMODE_WALK );

		#if( DRAW_TO_VIDEO )
			Screen_Buffer->Unlock();
		#endif

		// If we actually played a frame update the current frame number.
		if ( errval >= 0 ) {
			current_frame = errval;
         current_frame ++;
		}
	}

	return( VQA_PLAY_NO_ERROR );
}


/***************************************************************************
 * Play_VQA_Frame - Plays the specified frame, seeking to it if necessary. *
 *                                                                         *
 * INPUT: INT frame_number                                                 *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   02/20/1995  MG : Created.                                             *
 *=========================================================================*/
void VQAClass::Play_VQA_Frame( INT frame_number )
{
	if ( frame_number == PLAY_LAST_FRAME ) {
		frame_number = total_frames - 1;
	}

	//
	// If not currently at the desired frame, seek to it.
	//
	if ( current_frame != frame_number ) {
		Seek_To_Frame( frame_number );
		current_frame = frame_number;
	}

	//
	// Display the frame.
	//
	Play_VQA( frame_number );

	//
	// If at end of movie, reset to start of movie.
	//
	if ( current_frame >= total_frames ) {
		current_frame = 0;
	}
}

/***************************************************************************
 * Pause_VQA - Pauses a VQA in order to freeze the VQA timers.				  *
 *                                                                         *
 * INPUT: 																					  *
 *                                                                         *
 * OUTPUT:                                                             	  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   03/29/1995  MG : Created.                                             *
 *=========================================================================*/
void VQAClass::Pause_VQA( void )
{
	VQA_Play( vqa_handle, VQAMODE_PAUSE );
}



/***************************************************************************
 * VQACLASS::CLOSE_AND_FREE_VQA -- Closes vqa, frees instance, frees cache *
 *                                                                         *
 * INPUT:                                                                  *
 *   none																						  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *   none																						  *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log.																			  *
 *=========================================================================*/
void VQAClass::Close_And_Free_VQA( void )
{
	if ( vqa_is_open ) {
		VQA_Close( vqa_handle );
	}
	VQA_Free( vqa_handle );
}



/***************************************************************************
 * CHECK_KEY -- NULL function for VQA play library.                        *
 *                                                                         *
 * INPUT: NONE                                                             *
 *                                                                         *
 * OUTPUT: 0                                                               *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log																			  *
 *=========================================================================*/
unsigned short Check_Key( void )
{
	return( 0 );
}



/***************************************************************************
 * GET_KEY -- NULL function for VQA play library.                          *
 *                                                                         *
 * INPUT: NONE                                                             *
 *                                                                         *
 * OUTPUT: 0                                                               *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   See PVCS log																			  *
 *=========================================================================*/
unsigned short Get_Key( void )
{
	return( 0 );
}


/***************************************************************************
 * Set_Movie_Frame_Rate - Debug function for setting movie playback rate   *
 *                                                                         *
 * INPUT: NONE                                                             *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *=========================================================================*/
void Set_Movie_Frame_Rate( void )
{
	int retval;

	#if( 0 )

	retval = DialogBox(
		Main_Window.Get_Instance_Handle(),
		"GEEB",
		Main_Window.Get_Window_Handle(),
		(DLGPROC) Set_Frame_Rate_Dialog_Procedure );

	Debug_Printf( "retval = %d\r\n", retval );

	#endif
}


/***************************************************************************
 * SET_FRAME_RATE_DIALOG_PROCEDURE                                         *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
BOOL Set_Frame_Rate_Dialog_Procedure(
	WindowHandle window_handle,
	UINT message,
	WPARAM w_param,
	LPARAM l_param )
{
	char frame_rate_string[ 5 ];

	switch( message ) {

		case WM_COMMAND:

			if ( LOWORD( w_param ) == IDOK ) {

				GetDlgItemText( window_handle, FRAME_RATE, frame_rate_string, sizeof( frame_rate_string ) );
				Debug_Movie_Frame_Rate = atoi( frame_rate_string );

				if ( Debug_Movie_Frame_Rate < -1 ) {
					Debug_Movie_Frame_Rate = -1;
				}

				Debug_Printf( "Setting movie frame rate to %d\r\n", Debug_Movie_Frame_Rate );

				EndDialog( window_handle, TRUE );
				return( TRUE );
			}
			break;

		default:
			break;

	}
	return( FALSE );
}



