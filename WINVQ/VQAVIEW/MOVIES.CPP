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
 *                    File Name : MOVIES.CPP                               *
 *                                                                         *
 *                   Programmer : Michael Grayford                         *
 *                                                                         *
 *                   Start Date :                                          *
 *                                                                         *
 *                  Last Update : Nov 29, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


//==========================================================================
// INCLUDES
//==========================================================================

#include <windows.h>
#include <westwood.h>
#include <vq.h>
#include <movies.h>
#include <mainwind.h>
#include <main.h>
#include <pal.h>

//==========================================================================
// PRIVATE FUNCTIONS
//==========================================================================

void VQA_Test( char *filename );
void Create_Palette_Interpolation_Table( void );
void Interpolate_2X_Scale( GraphicBufferClass *source, GraphicBufferClass *dest );


//==========================================================================
// PRIVATE GLOBALS
//==========================================================================

extern "C"{
	extern unsigned char *InterpolationPalette;
	extern unsigned char Palette_Interpolation_Table[SIZE_OF_PALETTE][SIZE_OF_PALETTE];
	extern void __cdecl Asm_Create_Palette_Interpolation_Table(void);
	extern void __cdecl Asm_Interpolate (unsigned char* src_ptr ,
						 							unsigned char* dest_ptr ,
													int				lines ,
													int				src_width ,
													int				dest_width);

}
unsigned char Palette_Interpolation_Table[ SIZE_OF_PALETTE ][ SIZE_OF_PALETTE ];
unsigned char *InterpolationPalette;

VQAClass			*TestVqa;

#if( ! DRAW_TO_VIDEO )
	GraphicBufferClass *Draw_Page = NULL;
	GraphicBufferClass *Back_Page = NULL;
	GraphicBufferClass *Hid_Page = NULL;
#endif



/***************************************************************************
 * Initialize_Movie_System - Allocate memory needed for caching and any	  *
 *		permanent Movie data.															  *
 *                                                                         *
 * INPUT: NONE																				  *
 *                                                                         *
 * OUTPUT: int - an error value                                            *
 *                                                                         *
 * WARNINGS: Yellow alert!                                                 *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/29/1995  MG : Created.                                             *
 *=========================================================================*/
int Initialize_Movie_System( void )
{
	#if( ! DRAW_TO_VIDEO )
		//
		// Set up the graphic pages:
		// Draw_Page - the page that the VQA library draws to. (Normal RAM)
		// Back_Page - the page that the drawn image is scaled to. (Normal RAM)
		// Hid_Page - the page in video RAM that the scaled image is copied to before copy to screen.
		//
		Draw_Page = new GraphicBufferClass ( MOVIE_WIDTH, MOVIE_HEIGHT );
		Back_Page = new GraphicBufferClass ( VIDEO_MODE_WIDTH, VIDEO_MODE_HEIGHT );
		Hid_Page = new GraphicBufferClass ( VIDEO_MODE_WIDTH, VIDEO_MODE_HEIGHT, (GBC_Enum)(GBC_VIDEOMEM) );
	#endif

	//
	// Okay, we're cool.
	//
	return( VQA_INIT_NO_ERROR );
}

/***************************************************************************
 * Free_Movie_System - Free up memory used by Movie cache system and any   *
 *		permanent Movie data.															  *
 *                                                                         *
 * INPUT: NONE																				  *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS: Red alert!                                                    *
 *                                                                         *
 * HISTORY:                                                                *
 *   09/29/1995  MG : Created.                                             *
 *=========================================================================*/
void Free_Movie_System( void )
{
	#if( ! DRAW_TO_VIDEO )
		if ( Draw_Page ) {
			delete( Draw_Page );
		}
		if ( Back_Page ) {
			delete( Back_Page );
		}
		if ( Hid_Page ) {
			delete( Hid_Page );
		}
		Draw_Page = NULL;
		Back_Page = NULL;
		Hid_Page = NULL;
	#endif

	return;
}


/***************************************************************************
 * Choose_Movie - Brings up choice of VQA files.									  *
 *                                                                         *
 * INPUT: NONE                                                             *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/15/1995  MG : Created.                                             *
 *=========================================================================*/
void Choose_Movie( WindowHandle window_handle )
{
	int	i;
	char	temp_file[_MAX_FNAME + _MAX_EXT];
	static OPENFILENAME open_file_dlg;
	static char path_filename[ _MAX_PATH*500 ];
	static char filename[ _MAX_FNAME + _MAX_EXT ];
	static char *filters[] = {
		"VQA files (*.VQA)",  "*.vqa",
		"All Files", "*.*",
		"" } ;

	filename[0]=0;
	memset (&path_filename[0],0,_MAX_PATH*500);

	open_file_dlg.lStructSize 			= sizeof( OPENFILENAME );
	open_file_dlg.hwndOwner 			= window_handle;
	open_file_dlg.hInstance 			= NULL;
	open_file_dlg.lpstrFilter 			= filters[ 0 ];
	open_file_dlg.lpstrCustomFilter 	= NULL;
	open_file_dlg.nMaxCustFilter 		= 0;
	open_file_dlg.nFilterIndex 		= 1;
	open_file_dlg.lpstrFile 			= path_filename;
	open_file_dlg.nMaxFile 				= _MAX_PATH*500;
	open_file_dlg.lpstrFileTitle 		= filename;
	open_file_dlg.nMaxFileTitle 		= _MAX_FNAME + _MAX_EXT;
	open_file_dlg.lpstrInitialDir 	= NULL;
	open_file_dlg.lpstrTitle 			= "Choose a VQA to run";
	open_file_dlg.Flags 					= OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT;
	open_file_dlg.nFileOffset 			= 0;
	open_file_dlg.nFileExtension 		= 0;
	open_file_dlg.lpstrDefExt			= "vqa";
	open_file_dlg.lCustData				= 0l;
	open_file_dlg.lpfnHook				= NULL;
	open_file_dlg.lpTemplateName		= NULL;

	if ( GetOpenFileName( &open_file_dlg ) ) {

		if ( filename[ 0 ] != '\0' ) {
			VQA_Test( filename );
		} else {

			int	last_file=0;
			for (i=0 ; i<open_file_dlg.nMaxFile ; i++){
				if (path_filename[i]==0 || path_filename[i]==' '){

					if (!(i-last_file)) break;
					memcpy( &temp_file[0] , &path_filename[last_file] , i-last_file);
					temp_file[i-last_file]=0;
					if (last_file){
						VQA_Test(temp_file);
					}else{
						SetCurrentDirectory(temp_file);
					}

					if (path_filename[i]==0){
						break;
					}else{
						last_file = i+1;
					}
				}
			}
		}
   }
}


/***************************************************************************
 * VQA_Test - plays a generic VQA                                          *
 *                                                                         *
 * INPUT: char *filename                                                   *
 *                                                                         *
 * OUTPUT: NONE                                                            *
 *                                                                         *
 * WARNINGS: Red alert!                                                    *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
void VQA_Test( char *filename )
{
	char				*temp_ptr;
	int				i;
	char				*draw_surface_ptr;
	GraphicBufferClass	*draw_buffer_ptr;
	long				(*callback_function_ptr) (unsigned char *, long);

	//
	// Handle windows messages so that any repaint occurs before we start
	// playing the movie.
	//
	Main_Window.Update_Windows_Messages();

	// Strip the extension off the filename.
	filename = strtok( filename, "." );

	#if( DRAW_TO_VIDEO )
		draw_buffer_ptr = Screen_Buffer;
		callback_function_ptr = Draw_To_Video_Callback;
	#else
		draw_buffer_ptr = Draw_Page;
		callback_function_ptr = Draw_To_Buffer_Callback;
	#endif

	//
	// Get the draw buffer.
	//
	draw_buffer_ptr->Lock();
	draw_surface_ptr = (char *) draw_buffer_ptr->Get_Offset();
	draw_buffer_ptr->Unlock();

	//
	// Clear the drawing surface with color 0.
	//
	draw_buffer_ptr->Lock();
	temp_ptr = draw_surface_ptr;
	for ( i = 0; i < (MOVIE_WIDTH * MOVIE_HEIGHT); i ++ ) {
		*temp_ptr = COLOR_BLACK;
		temp_ptr ++;
	}
	draw_buffer_ptr->Unlock();

	//
	// Create a new VQA object.
	//
	TestVqa = new VQAClass(
		filename,
		draw_surface_ptr,
		FROM_DISK,
		callback_function_ptr );

	//
	// Allocate the buffers for the VQA.
	//
	if ( TestVqa->Open_And_Load_Buffers() ) {

		TestVqa->Read_Palettes();

		//
		// Play the VQA.
		//
		TestVqa->Play_VQA( PLAY_ALL_FRAMES );

		//
		// Close the VQA.
		//
		TestVqa->Close_And_Free_VQA();

		TestVqa->Write_Palettes();

		delete TestVqa;
	}
}


/***************************************************************************
 * DRAW_TO_VIDEO_CALLBACK -- Callback after a VQA frame is drawn to video  *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
long Draw_To_Video_Callback( unsigned char *buffer, long frame_number )
{
	return( 0 );
}



/***************************************************************************
 * DRAW_TO_BUFFER_CALLBACK -- Copies the drawn frame to the screen         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1995  MG : Created.                                             *
 *=========================================================================*/
long Draw_To_Buffer_Callback( unsigned char *buffer, long frame_number )
{
	//
	// Frame was skipped, bail.
	//
	if ( buffer == NULL ) {
		return( 0 );
	}

	#if( ! DRAW_TO_VIDEO )

		//
		// Do the cool interpolated, interlaced scale.
		//
		#if( 1 )
			Interpolate_2X_Scale( Draw_Page, Back_Page );
			Back_Page->Blit( *Screen_Buffer, 0, 0, 0, 100, 640, 314 );
		#endif

		//
		// Draw 320x200 to Normal RAM, scale to Screen.
		//
		#if( 0 )
			Draw_Page->Scale( *Screen_Buffer );
		#endif

		//
		// Draw 320x200 to Normal RAM, scale to Normal RAM, Blit to Hid, Blit to Screen.
		//
		#if( 0 )
			Draw_Page->Scale( *Back_Page );
			Back_Page->Blit( *Hid_Page );
			Hid_Page->Blit( *Screen_Buffer );
		#endif

		//
		// Draw 320x200 to Normal RAM, scale to Normal RAM, Blit to Screen.
		//
		#if( 0 )
			Draw_Page->Scale( *Back_Page );
			Back_Page->Blit( *Screen_Buffer );
		#endif

		//
		// Draw 320x200 to Normal RAM, Blit to Screen.
		//
		#if( 0 )
			Draw_Page->Blit( *Screen_Buffer );
		#endif

	#endif


	return( 0 );
}



/***************************************************************************
 * CREATE_PALETTE_INTERPOLATION_TABLE                                      *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Create_Palette_Interpolation_Table( void )
{

//	InterpolationPalette = (unsigned char*)CurrentPalette;
//	Asm_Create_Palette_Interpolation_Table();
//#if 0
	int 				i;
	int 				j;
	int 				p;
	unsigned char	*first_palette_ptr;
	unsigned char	*second_palette_ptr;
	unsigned char	*match_pal_ptr;
	int				first_r;
	int				first_g;
	int				first_b;
	int				second_r;
	int				second_g;
	int				second_b;
	int				diff_r;
	int				diff_g;
	int				diff_b;
	int				dest_r;
	int				dest_g;
	int				dest_b;
	int 				distance;
	int 				closest_distance;
	int 				index_of_closest_color;

	//
	// Create an interpolation table for the current palette.
	//
	first_palette_ptr = (unsigned char *) CurrentPalette;
	for ( i = 0; i < SIZE_OF_PALETTE; i ++ ) {

		//
		// Get the first palette entry's RGB.
		//
		first_r = *first_palette_ptr;
		first_palette_ptr ++;
		first_g = *first_palette_ptr;
		first_palette_ptr ++;
		first_b = *first_palette_ptr;
		first_palette_ptr ++;

		second_palette_ptr = (unsigned char *) CurrentPalette;
		for  ( j = 0; j < SIZE_OF_PALETTE; j ++ ) {
			//
			// Get the second palette entry's RGB.
			//
			second_r = *second_palette_ptr;
			second_palette_ptr ++;
			second_g = *second_palette_ptr;
			second_palette_ptr ++;
			second_b = *second_palette_ptr;
			second_palette_ptr ++;

			//
			// Now calculate the RGB halfway between the first and second colors.
			//
			dest_r = ( first_r + second_r ) >> 1;
			dest_g = ( first_g + second_g ) >> 1;
			dest_b = ( first_b + second_b ) >> 1;

			//
			// Now find the color in the palette that most closely matches the interpolated color.
			//
			index_of_closest_color = 0;
//			closest_distance = (256 * 256) * 3;
			closest_distance = 500000;
			match_pal_ptr = (unsigned char *) CurrentPalette;
			for ( p = 0; p < SIZE_OF_PALETTE; p ++ ) {
				diff_r = ( ((int) (*match_pal_ptr)) - dest_r );
				match_pal_ptr ++;
				diff_g = ( ((int) (*match_pal_ptr)) - dest_g );
				match_pal_ptr ++;
				diff_b = ( ((int) (*match_pal_ptr)) - dest_b );
				match_pal_ptr ++;

				distance = ( diff_r * diff_r ) + ( diff_g * diff_g ) + ( diff_b * diff_b );
				if ( distance < closest_distance ) {
					closest_distance = distance;
					index_of_closest_color = p;
				}
			}

			Palette_Interpolation_Table[ i ][ j ] = (unsigned char) index_of_closest_color;
		}
	}

	return;
//#endif
}




#if( 1 )
/***************************************************************************
 * INTERPOLATE_2X_SCALE                                                    *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Interpolate_2X_Scale( GraphicBufferClass *source, GraphicBufferClass *dest)
{
	unsigned char	*src_ptr;
	unsigned char	*dest_ptr;
	unsigned char	*last_dest_ptr;
	unsigned char	*end_of_source;
	int	src_width;
	int	dest_width;
//	int	width_counter;
	BOOL	source_locked = FALSE;
	BOOL	dest_locked = FALSE;

	/*
	** Lock video surfaces if requred
	*/
	if (source->Get_IsDirectDraw()){
		if (!source->Lock()) return;
		source_locked = TRUE;
	}
	if (dest->Get_IsDirectDraw()){
		if (!dest->Lock()) {
			if (source_locked){
				source->Unlock();
			}
			return;
		}
		dest_locked = TRUE;
	}

	//
	// Get pointers to the source and destination buffers.
	//
	src_ptr = (unsigned char *) source->Get_Offset();
	dest_ptr = (unsigned char *) dest->Get_Offset();
	end_of_source = src_ptr + ( source->Get_Width() * source->Get_Height() );

	//
	// Get width of source and dest buffers.
	//
	src_width = source->Get_Width();
	dest_width = 2*(dest->Get_Width() + dest->Get_XAdd() + dest->Get_Pitch());
	last_dest_ptr = dest_ptr;

	Asm_Interpolate ( src_ptr , dest_ptr , source->Get_Height() , src_width , dest_width);

	if (source_locked) source->Unlock();
	if (dest_locked) dest->Unlock();

	return;
}
#endif




#if( 0 )
/***************************************************************************
 * INTERPOLATE_2X_SCALE                                                    *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Interpolate_2X_Scale( GraphicBufferClass *source, GraphicBufferClass *dest )
{
	unsigned char	*src_ptr;
	unsigned char	*dest_ptr;
	unsigned char	*end_of_source;
	int	src_width;
	int	dest_width;
	int	width_counter;

	//
	// Get pointers to the source and destination buffers.
	//
	src_ptr = (unsigned char *) source->Get_Offset();
	dest_ptr = (unsigned char *) dest->Get_Offset();
	end_of_source = src_ptr + ( source->Get_Width() * source->Get_Height() );

	//
	// Get width of source and dest buffers.
	//
	src_width = source->Get_Width();
	dest_width = dest->Get_Width();

	//
	// Copy over the first pixel (upper left).
	//
	*dest_ptr = *src_ptr;
	src_ptr ++;
	dest_ptr ++;

	//
	// Scale copy.
	//
	width_counter = 0;
	while ( src_ptr < end_of_source ) {

		//
		// Blend this pixel with the one to the left and place this new color in the dest buffer.
		//
		*dest_ptr = Palette_Interpolation_Table[ (*src_ptr) ][ (*( src_ptr - 1 )) ];
		dest_ptr ++;

		//
		// Now place the source pixel into the dest buffer.
		//
		*dest_ptr = *src_ptr;

		src_ptr ++;
		dest_ptr ++;

		width_counter ++;
		if ( width_counter == src_width ) {
			width_counter = 0;
			dest_ptr += dest_width;
		}
	}


	return;
}
#endif


#if( 0 )
/***************************************************************************
 * INTERPOLATE_2X_SCALE                                                    *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/06/1995  MG : Created.                                             *
 *=========================================================================*/
void Interpolate_2X_Scale( GraphicBufferClass *source, GraphicBufferClass *dest )
{
	unsigned char	*src_ptr;
	unsigned char	*dest_ptr;
	unsigned char	*dest2_ptr;
	unsigned char	*end_of_source;
	int	src_width;
	int	dest_width;
	int	width_counter;

	//
	// Get pointers to the source and destination buffers.
	//
	src_ptr = (unsigned char *) source->Get_Offset();
	dest_ptr = (unsigned char *) dest->Get_Offset();
	end_of_source = src_ptr + ( source->Get_Width() * source->Get_Height() );

	//
	// Get width of source and dest buffers.
	//
	src_width = source->Get_Width();
	dest_width = dest->Get_Width();

	//
	// Copy over the first pixel (upper left).
	//
	*dest_ptr = *src_ptr;
	src_ptr ++;
	dest_ptr += 2;
	dest2_ptr = dest_ptr + dest_width + 1;

	//
	// Scale copy.
	//
	width_counter = 0;
	while ( src_ptr < end_of_source ) {

		//
		// Blend this pixel with the one to the left and place this new color in the dest buffer.
		//
		*dest2_ptr = Palette_Interpolation_Table[ (*src_ptr) ][ (*( src_ptr - 1 )) ];
		dest2_ptr += 2;

		//
		// Now place the source pixel into the dest buffer.
		//
		*dest_ptr = *src_ptr;

		src_ptr ++;
		dest_ptr += 2;

		width_counter ++;
		if ( width_counter == src_width ) {
			width_counter = 0;
			dest_ptr += dest_width;
			dest2_ptr += dest_width;
		}
	}


	return;
}

#endif


