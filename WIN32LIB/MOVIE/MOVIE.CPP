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
* FILE
*     Movie.cpp
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

#include "movie.h"
#include <mmstream.h>
#include <streams.h>
#include <amstream.h>
#include <ddstream.h>
#include <stdio.h>

// We declare these variables global because RA doesn't like the DirectXMedia
// header files.
IDirectDraw* gDDraw = NULL;
IGraphBuilder* gGB = NULL;
IMultiMediaStream* gMMStream = NULL;
IMediaStream* gVideoStream = NULL;
IDirectDrawMediaStream* gDDStream = NULL;
IDirectDrawStreamSample* gDDSample = NULL;


/****************************************************************************
*
* NAME
*     Movie - Constructor
*
* DESCRIPTION
*
* INPUTS
*
* RESULT
*
****************************************************************************/

Movie::Movie(IDirectDraw* dd)
	{
	mPlaying = false;

	Close();

	gDDraw = dd;

	// Initialize COM library
	CoInitialize(NULL);
	}


/****************************************************************************
*
* NAME
*     ~Movie - Destructor
*
* DESCRIPTION
*
* INPUTS
*
* RESULT
*
****************************************************************************/

Movie::~Movie()
	{
	// Release all
	Close();

	// Release COM library
	CoUninitialize();
	}


/****************************************************************************
*
* NAME
*     Open
*
* DESCRIPTION
*
* INPUTS
*     Name - Name of movie
*
* RESULT
*
****************************************************************************/

bool Movie::Open(const char* name)
	{
	WCHAR wFile[MAX_PATH];
	IAMMultiMediaStream* amStream;
	DDSURFACEDESC ddsd;
	
	Close();

	//-------------------------------------------------------------------------
	// CREATE FILTER GRAPH FOR FILE TYPE
	//-------------------------------------------------------------------------
	if (FAILED(CoCreateInstance(CLSID_FilterGraph, NULL, CLSCTX_INPROC_SERVER,
			IID_IGraphBuilder, (void **)&gGB)))
		{
		MessageBox(GetDesktopWindow(), "Couldn't create a CLSID_FilterGraph object.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	//-------------------------------------------------------------------------
	// CREATE MULTIMEDIA STREAM
	//-------------------------------------------------------------------------
	if (FAILED(CoCreateInstance(CLSID_AMMultiMediaStream, NULL,
			CLSCTX_INPROC_SERVER, IID_IAMMultiMediaStream, (void**)&amStream)))
		{
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't create a CLSID_MultiMediaStream object.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	// Initialize stream for reading
	if (FAILED(amStream->Initialize(STREAMTYPE_READ, 0, gGB)))
		{
		amStream->Release();
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't initialize MultiMediaStream object.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	// We want video
	if (FAILED(amStream->AddMediaStream(gDDraw, &MSPID_PrimaryVideo, 0, NULL)))
		{
		amStream->Release();
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't add primary video stream.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	// We want audio
	if (FAILED(amStream->AddMediaStream(NULL, &MSPID_PrimaryAudio,
			AMMSF_ADDDEFAULTRENDERER, NULL)))
		{
		amStream->Release();
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't add primary audio stream.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	gMMStream = amStream;

	// Convert the filename
	MultiByteToWideChar(CP_ACP,0,name,-1,wFile,sizeof(wFile)/sizeof(wFile[0]));

	if (FAILED(gGB->RenderFile(wFile, NULL)))
		{
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't build filter graph.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

	// Get video stream
 	if (FAILED(gMMStream->GetMediaStream(MSPID_PrimaryVideo, &gVideoStream)))
		{
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't obtain video stream.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

 	if (FAILED(gVideoStream->QueryInterface(IID_IDirectDrawMediaStream,
			(void **)&gDDStream)))
		{
		Close();
		MessageBox(GetDesktopWindow(), "Couldn't obtain video stream interface.\n",
				"DirectMedia", MB_ICONSTOP|MB_OK);
		return false;
		}

 	ddsd.dwSize = sizeof(ddsd);
 	gDDStream->GetFormat(&ddsd, NULL, NULL, NULL);
	mHeight = ddsd.dwHeight;
	mWidth = ddsd.dwWidth;
	return true;
	}


/****************************************************************************
*
* NAME
*
* DESCRIPTION
*
* INPUTS
*
* RESULT
*
****************************************************************************/

void Movie::Close(void)
	{
	// Stop currently playing movie
	if ((gMMStream != NULL) && (mPlaying == true))
		{
		gMMStream->SetState(STREAMSTATE_STOP);
		mPlaying = false;
		}

	// Release video sample
	if (gDDSample)
		{
		gDDSample->Release();
		gDDSample = NULL;
		}

	// Release DirectDrawMediaStream interface
	if (gDDStream)
		{
		gDDStream->Release();
		gDDStream = NULL;
		}

	// Release video stream
	if (gVideoStream)
		{
		gVideoStream->Release();
		gVideoStream = NULL;
		}

	// Release multimedia stream
	if (gMMStream)
		{
		gMMStream->Release();
		gMMStream = NULL;
		}

	// Release filter graph
	if (gGB)
		{
		gGB->Release();
		gGB = NULL;
		}
	}


/****************************************************************************
*
* NAME
*     Play
*
* DESCRIPTION
*
* INPUTS
*
* RESULT
*
****************************************************************************/

bool Movie::Play(IDirectDrawSurface* surface)
	{
	RECT rect;

	rect.top = rect.left = 0;
	rect.bottom = mHeight;
	rect.right = mWidth;

 	if (FAILED(gDDStream->CreateSample(surface, &rect, 0, &gDDSample)))
		{
		return false;
		}

	gMMStream->SetState(STREAMSTATE_RUN);
	mPlaying = true;
	return true;
	}


/****************************************************************************
*
* NAME
*     Update
*
* DESCRIPTION
*
* INPUTS
*
* RESULT
*
****************************************************************************/

bool Movie::Update(void)
	{
	// Update each frame
	if (gDDSample->Update(0, NULL, NULL, 0) != S_OK)
		{
		gMMStream->SetState(STREAMSTATE_STOP);		
		return false;
		}

	return true;
	}
