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
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : IFF                                      *
 *                                                                         *
 *                    File Name : LOADPCX.CPP                              *
 *                                                                         *
 *                   Programmer : Julio R. Jerez                           *
 *                                                                         *
 *                   Start Date : May 2, 1995                              *
 *                                                                         *
 *                  Last Update : May 3, 1995   [JRJ]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * GraphicBufferClass* Read_PCX_File (char* name, void *Buff, long size ); *
 * int Get_PCX_Palette (char * name, void& palette )								*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include  <wwlib32.h>
#include "filepcx.h"

/***************************************************************************
 * READ_PCX_FILE -- read a pcx file into a Graphic Buffer                  *
 *                                                                         *
 *	GraphicBufferClass* Read_PCX_File (char* name, char* palette ,void *Buff, long size );	*
 *  																								*
 *                                                                         *
 * INPUT: name is a NULL terminated string of the fromat [xxxx.pcx]        *
 *        palette is optional, if palette != NULL the the color palette of *
 *					 the pcx file will be place in the memory block pointed	   *
 *               by palette.																*
 *			 Buff is optinal, if Buff == NULL a new memory Buffer		 			*
 *					 will be allocated, otherwise the file will be placed 		*
 *					 at location pointd by Buffer;										*
 *			Size is the size in bytes of the memory block pointed by Buff		*
 *				  is also optional;
 *                                                                         *
 * OUTPUT: on succes a pointer to a GraphicBufferClass cointaining the     *
 *         pcx file, NULL othewise.                                        *
 *																									*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/03/1995 JRJ : Created.                                             *
 *=========================================================================*/

#define	POOL_SIZE 2048
#define	READ_CHAR()  *file_ptr++ ; \
							 if ( file_ptr	>= & pool [ POOL_SIZE ]	) { \
								 Read_File ( file_handle, pool , POOL_SIZE ) ; \
								 file_ptr = pool ; \
							 }


GraphicBufferClass* Read_PCX_File(char* name, char* Palette, void *Buff, long Size)
{
  unsigned     i , j ;
  unsigned     rle ;
  unsigned     color ;
  unsigned		scan_pos ;
  char		 * file_ptr ;
  int				width	;
  int				height ;
  int 	      file_handle ;
  char		 * buffer ;
  PCX_HEADER   header ;
  RGB  		 * pal ;
  char 			pool [ POOL_SIZE ] ;
  GraphicBufferClass * pic	;

  // Open file name
  file_handle = Open_File ( name , READ ) ;
  if ( file_handle == WW_ERROR ) return NULL ;

  Read_File ( file_handle, & header , sizeof (PCX_HEADER)) ;
  if ( header.id != 10 &&  header.version != 5 &&
	   header.pixelsize != 8 ) return NULL ;

  width = header.width - header.x + 1 ;
  height = header.height - header.y + 1 ;

  if ( Buff ) {
	  buffer = ( char * ) Buff;
	  i = Size / width;
	  height = MIN ( i - 1, height);
	  pic = new GraphicBufferClass( width, height, buffer ,Size);
	  if ( !(pic && pic->Get_Buffer()))return NULL ;
  } else {
	  pic = new GraphicBufferClass( width, height, NULL, width*(height+4));
	  if ( !(pic && pic->Get_Buffer()))return NULL ;
  }

  buffer = (char *) pic->Get_Buffer() ;
  file_ptr = pool ;
  Read_File ( file_handle, pool , POOL_SIZE ) ;

  if ( header.byte_per_line != width )
	 for ( scan_pos = j = 0 ; j < height ; j ++, scan_pos += width ) {
      for ( i = 0 ; i < width ; ) {
				 rle = READ_CHAR ();
				 if ( rle > 192 ) {
				 rle -= 192 ;
				 color =	READ_CHAR (); ;
		 		 memset ( buffer + scan_pos + i , color , rle ) ;
		 		 i += rle ;
	        } else * ( buffer + scan_pos + i ++ ) = (char)rle ;
	    }
		 if ( i == width )
		 rle = READ_CHAR () ;
//		 if ( rle > 192 ) rle = READ_CHAR ();
    }


  else for ( i = 0 ; i < width * height ; ) {
		rle = READ_CHAR ();
		rle &= 0xff;
		if ( rle > 192 ) {
	      rle -= 192 ;
	      color = READ_CHAR ();
			memset ( buffer + i , color , rle ) ;
	      i += rle ;
	    }	else * ( buffer + i ++ ) = (char)rle ;
  }

 if ( Palette ) {
	  //Seek_File ( file_handle , - 256 * sizeof ( RGB ) , SEEK_END ) ;
	  Seek_File ( file_handle , 256 * sizeof ( RGB ) , SEEK_END ) ;
	  Read_File ( file_handle,	Palette , 256L * sizeof ( RGB )) ;

	  pal = ( RGB * ) Palette ;
	  for ( i = 0 ; i < 256 ; i ++ ) {
		 pal -> red >>= 2 ;
		 pal -> green >>= 2 ;
		 pal -> blue >>= 2 ;
		 pal ++ ;
	  }
  }
 Close_File (file_handle) ;
 return pic ;
}

/***************************************************************************
 * READ_PCX_FILE -- read a pcx file into a Graphic Buffer                  *
 *                                                                         *
 *	GraphicBufferClass* Read_PCX_File (char* name, BufferClass& Buff,			*
 *																  char* palette)	*			*
 *  																								*
 *                                                                         *
 * INPUT: name is a NULL terminated string of the fromat [xxxx.pcx]        *
 *			 Buff is a pointer to a BufferClass the will hold the pcx file 	*
 *					 at location pointd by Buffer;										*
 *        palette is optional, if palette != NULL the the color palette of *
 *					 the pcx file will be place in the memory block pointed	   *
 *               by palette.																*
 *                                                                         *
 * OUTPUT: on succes a pointer to a GraphicBufferClass cointaining the     *
 *         pcx file, NULL othewise.                                        *
 *																									*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/03/1995 JRJ : Created.                                             *
 *=========================================================================*/

GraphicBufferClass* Read_PCX_File (char* name, BufferClass& Buff,char* palette)
{
  return Read_PCX_File(name, palette, (void*)Buff.Get_Buffer(), Buff.Get_Size());
}