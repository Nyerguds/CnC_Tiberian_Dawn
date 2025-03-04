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
 *                    File Name : PAL.CPP                                  *
 *                                                                         *
 *                   Programmer : Mike Grayford                            *
 *                                                                         *
 *                   Start Date : November 20, 1995                        *
 *                                                                         *
 *                  Last Update : Nov 20, 1995   [MG]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *                                                                         *
 * Update_Full_Palette -- Modifies the Windows palette                     *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <windows.h>

#include <westwood.h>
#include <vidmode.h>
#include <pal.h>
#include <gbuffer.h>
#include <main.h>
#include <monochrm.h>
#include <wwlib.h>
#include <memflag.h>
#include <vq.h>


//---------------------------------------------------------------------------------------------
//	PUBLIC DATA
//---------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------
//	PRIVATE GLOBALS
//---------------------------------------------------------------------------------------------


/***************************************************************************
 * Update_Full_Palette -- Modifies the Windows palette                     *
 *                                                                         *
 * INPUT: unsigned char *palette - pointer to the entire raw palette		  *
 *                                                                         *
 * OUTPUT: NONE																				  *
 *                                                                         *
 * WARNINGS: Watch out for falling bricks.											  *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/27/1995  MG : Created.                                             *
 *=========================================================================*/
void Update_Full_Palette( unsigned char *palette )
{
	PALETTEENTRY	pe[ SIZE_OF_PALETTE ];
	unsigned char	*pal_pos;
	int				i;

	pal_pos = palette;
	for ( i = 0; i < SIZE_OF_PALETTE; i ++ ) {
		pe[ i ].peRed = *pal_pos;
		pal_pos ++;
		pe[ i ].peGreen = *pal_pos;
		pal_pos ++;
		pe[ i ].peBlue = *pal_pos;
		pal_pos ++;
	}

  	Mem_Copy( palette, CurrentPalette, SIZE_OF_PALETTE * 3 );

	DirectDrawObject->CreatePalette( DDPCAPS_8BIT, &pe[ 0 ], &PalettePtr, NULL );
	Screen_Buffer->Get_Graphic_Buffer()->Get_DD_Surface()->SetPalette( PalettePtr );
	PalettePtr->SetEntries( DDPSETPAL_VSYNC , 0 , SIZE_OF_PALETTE , &pe[ 0 ] );
}






extern	VQAClass	*TestVqa;

extern "C"{
	void __cdecl SetPalette(unsigned char *palette,long ,unsigned long );
}

void __cdecl SetPalette(unsigned char *palette,long ,unsigned long )
{
	TestVqa->Update_Palette(palette);
}




