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
 *                 Project Name : Testing memory.                          *
 *                                                                         *
 *                    File Name : TEST.CPP                                 *
 *                                                                         *
 *                   Programmer : Julio Jerez                              *
 *                                                                         *
 *                   Start Date : Feb 13, 1995                             *
 *                                                                         *
 *                                                                         *
 *-------------------------------------------------------------------------*
*/
#include <mcgaprim.h>
#include <gbuffer.h>
#include <vbuffer.h>

int Vesa_Scale_To_Linear ( void * scr,  void * dst, 
									int src_x  , int src_y  , int dst_x , int dst_y , 
									int src_wd , int src_hg , int dst_wd, int dst_hg, 
									BOOL trans , char * remap )
{
  int	   area ;
  int    width , height ;
  char * temp ;

  VideoViewPortClass * scr1 = ( VideoViewPortClass * ) scr ;

  width  = src_wd - src_x ;
  height = src_hg - src_y ;
  area = width * height ;
  temp = ( char * ) malloc ( area ) ;
  if ( ! temp ) return 0 ;

  scr1 -> To_Buffer ( 0, 0, width , height , temp, area );
  GraphicBufferClass tempbuffer ( area , width , height , temp ) ;

  Linear_Scale_To_Linear ( & tempbuffer , dst , 
  									  0 , 0 , dst_x , dst_y ,
  									  width , height , dst_wd , dst_hg ,
									  trans , remap ) ;

  free ( temp ) ;
  return 0 ;
}
