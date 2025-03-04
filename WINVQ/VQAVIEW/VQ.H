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
 *                    File Name : VQ.H                                     *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date :                                          *
 *                                                                         *
 *                  Last Update : Nov 22, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

//==========================================================================
// INCLUDES
//==========================================================================

#include <vqa32\vqaplay.h>
#include <vidmode.h>
#define bool BOOL
#define true 1
#define false 0
#include <rawfile.h>

//==========================================================================
// PUBLIC FUNCTIONS
//==========================================================================

void Set_Movie_Frame_Rate( void );

//==========================================================================
// PRIVATE DEFINES
//==========================================================================

//--------------------------------------------------------------------------
// GENERAL DEFINES
//--------------------------------------------------------------------------

#define VQ_BLOCK_WIDTH		4
#define VQ_BLOCK_HEIGHT		4
#define VQ_COLUMNS			( VQ_MOVIE_WIDTH / VQ_BLOCK_WIDTH )
#define VQ_ROWS				( VQ_MOVIE_HEIGHT / VQ_BLOCK_HEIGHT )

// Codes for media_src parameter of VQAClass constructor:
#define FROM_DISK				0
#define FROM_MEMORY			1

// CODES for Play_VQA:
#define PLAY_ALL_FRAMES		 	-1
#define PLAY_TO_END_OF_MOVIE	-2

// CODES for Play_VQA_Frame:
#define PLAY_LAST_FRAME			-1

// Error codes returned by VQA_INIT:
#define VQA_INIT_NO_ERROR					-1
#define VQA_INIT_FAILED_MEM_POOL_ALLOC	-2
#define VQA_INIT_FAILED_SCRATCH_ALLOC	-3

// Codes for Cache_VQA:
#define CACHE_REST_OF_FILE		0

// Error codes returned by CACHE_VQA
#define CACHE_NO_ERROR			-1
#define CACHE_EOF					-2
#define CACHE_FAILED_MEM_ALLOC	-3
#define CACHE_OPEN_FILE_ERROR	-4
#define CACHE_READ_ERROR			-5

// Error codes returned by Play_VQA:
#define VQA_PLAY_NO_ERROR		0
#define VQA_PLAY_USER_BREAK		1

#define VECTOR_FORMAT_OFFSETS	1
#define VECTOR_FORMAT_INDEXES	2
#define MAX_CODEBOOK_OFFSET		32766

//==========================================================================
// PUBLIC DATA
//==========================================================================

extern unsigned char 		*Movie_Scratch_Buffer;

//==========================================================================
// CLASSES
//==========================================================================

class VQAClass {
	private:
		char 				base_filename[ _MAX_PATH ];
		char 				vqa_filename[ _MAX_PATH ];
		char				PaletteFilename [_MAX_PATH];
		VQAConfig		vqa_config;
		VQAHandle		*vqa_handle;
		short				media_source;
		int				file_handle;
		unsigned char	palette[ SIZE_OF_PALETTE * 3 ];
		int				current_frame;
		int				total_frames;
		BOOL				vqa_is_open;
		unsigned char	*InterpolatedPalettes[50];		//Max 50 palette changes in a vq
		BOOL				PalettesRead;
		RawFileClass	*PaletteFile;
		unsigned			NumPalettes;



		/*=========================================================================*/
		/* Private functions.																		*/
		/*=========================================================================*/
		int VQAClass::Play_Generic_VQA( int last_frame_to_play );

	public:
		VQAClass( char *filename, char *buffer, short media_src, long (*callback) (unsigned char *, long) );
		~VQAClass (void);
		BOOL VQAClass::Update_Palette( unsigned char *newpalette );
		BOOL Open_And_Load_Buffers( void );
		void Seek_To_Frame( unsigned long frame );
		int Play_VQA( int last_frame_to_play );
		void Play_VQA_Frame( int frame_number );
		void Pause_VQA( void );
		void Close_And_Free_VQA( void );
		void VQAClass::Read_Palettes(void);
		void VQAClass::Write_Palettes(void);
}; /* VQAClass */


//==========================================================================
// TYPES
//==========================================================================

typedef struct {
	unsigned long	file_offset;
	unsigned long	file_size;
} VQACacheHeader;



