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
 **      C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S      **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Westwood 32 bit Library                  *
 *                                                                         *
 *                    File Name : VBUFFER.CPP                              *
 *                                                                         *
 *                   Programmer : Phil W. Gorrow                           *
 *                                                                         *
 *                   Start Date : January 9, 1995                          *
 *                                                                         *
 *                  Last Update : January 9, 1995   [PWG]                  *
 *                                                                         *
 * This module contains the C++ class definitions for the video buffer     *
 * class.  This include routines for class creation and modification			*
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * VVPC::VideoViewPortClass -- Constructor for basic view port class     	*
 * VVPC::VideoViewPortClass -- Default constructor for view port class		*
 * VVPC::~VideoViewPortClass -- Destructor for GraphicViewPortClass			*
 * VVPC::Attach -- Attaches a viewport to a buffer class                   *
 * VVPC::Change -- Changes position and size of a Video View Port   			*
 * VBC::VideoBufferClass -- Default constuctor for video buffers				*
 * VBC::VideoBufferClass -- Lowlevel constructor for video buffer class    *
 * VBC::~VideoBufferClass -- Destructor for the video buffer class      	*
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "vbuffer.h"

/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/


/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/


/***************************************************************************
 * VVPC::VIDEOVIEWPORTCLASS -- Constructor for basic view port class     	*
 *                                                                         *
 * INPUT:		VideoBufferClass * vbuffer	- buffer to attach to				*
 *					WORD x								- x offset into buffer			*
 *					WORD y								- y offset into buffer			*
 *					WORD w								- view port width in pixels   *
 *					WORD h   							- view port height in pixels	*
 *                                                                         *
 * OUTPUT:     Constructors may not have a return value							*
 *                                                                         *
 * HISTORY:                                                                *
 *   05/09/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoViewPortClass::VideoViewPortClass(VideoBufferClass *vbuffer, int x, int y, int w, int h)
{
	Attach(vbuffer, x, y, w, h);
}

/***************************************************************************
 * VVPC::VIDEOVIEWPORTCLASS -- Default constructor for view port class   *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/09/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoViewPortClass::VideoViewPortClass(void)
{
}

/***************************************************************************
 * VVPC::~VIDEOVIEWPORTCLASS -- Destructor for GraphicViewPortClass			*
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     A destructor may not return a value.                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/10/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoViewPortClass::~VideoViewPortClass(void)
{
}

/***************************************************************************
 * VVPC::ATTACH -- Attaches a viewport to a buffer class                   *
 *                                                                         *
 * INPUT:		GraphicBufferClass *g_buff	- pointer to gbuff to attach to  *
 *					WORD x                     - x position to attach to			*
 *					WORD y 							- y position to attach to			*
 *					WORD w							- width of the view port			*
 *					WORD h							- height of the view port			*
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/10/1994 PWG : Created.                                             *
 *=========================================================================*/
void VideoViewPortClass::Attach(VideoBufferClass *vbuffer, int x, int y, int w, int h)
{
	/*======================================================================*/
	/* Verify that the x and y coordinates are valid and placed within the	*/
	/*		physical buffer.																	*/
	/*======================================================================*/
	if (x < 0) 										// you cannot place view port off
		x = 0;										//		the left edge of physical buf
	if (x >= vbuffer->Get_Width())			// you cannot place left edge off
		x = vbuffer->Get_Width() - 1;			//		the right edge of physical buf
	if (y < 0) 										// you cannot place view port off
		y = 0;										//		the top edge of physical buf
	if (y >= vbuffer->Get_Height()) 			// you cannot place view port off
		y = vbuffer->Get_Height() - 1;		//		bottom edge of physical buf

	/*======================================================================*/
	/* Adjust the width and height of necessary										*/
	/*======================================================================*/
	if (x + w > vbuffer->Get_Width()) 		// if the x plus width is larger
		w = vbuffer->Get_Width() - x;			//		than physical, fix width

	if (y + h > vbuffer->Get_Height()) 		// if the y plus height is larger
		h = vbuffer->Get_Height() - y;		//		than physical, fix height

	/*======================================================================*/
	/* Get a pointer to the top left edge of the buffer.							*/
	/*======================================================================*/
 	Offset 		= vbuffer->Get_Offset() + (vbuffer->Get_Width() * y) + x;

	/*======================================================================*/
	/* Copy over all of the variables that we need to store.						*/
	/*======================================================================*/
 	XPos			= x;
 	YPos			= y;
 	XAdd			= vbuffer->Get_Width() - w;
 	Width			= w;
 	Height		= h;
 	VideoBuff 	= vbuffer;
}
/***************************************************************************
 * VVPC::CHANGE -- Changes position and size of a Video View Port   			*
 *                                                                  			*
 * INPUT:   	WORD the new x pixel position of the Video view port 			*
 *					WORD the new y pixel position of the Video view port 			*
 *					WORD the new width of the viewport in pixels			  			*
 *					WORD the new height of the viewport in pixels		  			*
 *                                                                  			*
 * OUTPUT:  	BOOL whether the Video View Port could be sucessfully			*
 *				      resized.														  			*
 *                                                                  			*
 * WARNINGS:   You may not resize a Video View Port which is derived			*
 *						from a Video View Port Buffer, 						  			*
 *                                                                  			*
 * HISTORY:                                                         			*
 *   09/14/1994 SKB : Created.                                      			*
 *=========================================================================*/
BOOL VideoViewPortClass::Change(int x, int y, int w, int h)
{
	/*======================================================================*/
	/* Can not change a Video View Port if it is actually the physical		*/
	/*	   representation of a Video Buffer.											*/
	/*======================================================================*/
	if (this == Get_Video_Buffer())  {
		return(FALSE);
	}

	/*======================================================================*/
	/* Since there is no allocated information, just re-attach it to the		*/
	/*		existing Video buffer as if we were creating the						*/
	/*		VideoViewPort.																		*/
	/*======================================================================*/
	Attach(Get_Video_Buffer(), x, y, w, h);
	return(TRUE);
}
/***************************************************************************
 * VBC::VIDEOBUFFERCLASS -- Default constuctor for video buffers				*
 *                                                                         *
 * INPUT:		WORD w			- width of buffer in pixels (default = 320)  *
 *					WORD h			- height of buffer in pixels (default = 200) *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/13/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoBufferClass::VideoBufferClass(int w, int h)
{
	Offset		= 0xa0000;								// Get offset to the buffer
	Width			= w;										// Record width of Buffer
	Height		= h;										// Record height of Buffer
	XAdd			= 0;										// Record XAdd of Buffer
	XPos			= 0;										// Record XPos of Buffer
	YPos			= 0;										// Record YPos of Buffer
	VideoBuff	= this;									// Get a pointer to our self
}

/***************************************************************************
 * VBC::VIDEOBUFFERCLASS -- Lowlevel constructor for video buffer class    *
 *                                                                         *
 * INPUT:		UWORD		the selector of the memory reference					*
 *					long		the offset of the memory reference						*
 *					WORD		the width of the video buffer								*
 *					WORD		the height of the video buffer							*
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/07/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoBufferClass::VideoBufferClass(unsigned short selector, long offset, int w, int h)
{
	Offset		= offset;								// Get offset to the buffer
	Width			= w;										// Record width of Buffer
	Height		= h;										// Record height of Buffer
	XAdd			= 0;										// Record XAdd of Buffer
	XPos			= 0;										// Record XPos of Buffer
	YPos			= 0;										// Record YPos of Buffer
	VideoBuff	= this;									// Get a pointer to our self
}
/*=========================================================================*
 * VBC::~VIDEOBUFFERCLASS -- Destructor for the video buffer class      	*
 *                                                                         *
 *	INPUT:		none																			*
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/03/1994 PWG : Created.                                             *
 *=========================================================================*/
VideoBufferClass::~VideoBufferClass()
{
}

