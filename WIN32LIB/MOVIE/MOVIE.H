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

#ifndef _MOVIE_H_
#define _MOVIE_H_
/****************************************************************************
*
* FILE
*     Movie.h
*
* DESCRIPTION
*     Movie playback using DirectShow Multimedia streaming and DirectDraw
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     May 27, 1998
*
****************************************************************************/

#include <ddraw.h>

class Movie
	{
	public:
		Movie(IDirectDraw* dd);
		~Movie();

		bool Open(const char* name);
		bool Play(IDirectDrawSurface* surface);
		bool Update(void);
		void Close(void);

		bool IsPlaying(void) const
			{return mPlaying;}

		DWORD GetWidth(void) const
			{return mWidth;}

		DWORD GetHeight(void) const
			{return mHeight;}

	protected:
		DWORD mWidth;
		DWORD mHeight;
		bool mPlaying;
	};

#endif // _MOVIE_H_
