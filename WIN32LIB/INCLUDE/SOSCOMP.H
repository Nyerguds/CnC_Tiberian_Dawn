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
*  File              : soscomp.h
*  Date Created      : 6/1/94
*  Description       :
*
*  Programmer(s)     : Nick Skrepetos
*  Last Modification : 10/1/94 - 11:37:9 AM
*  Additional Notes  : Modified by Denzil E. Long, Jr.
*
*****************************************************************************
*            Copyright (c) 1994,  HMI, Inc.  All Rights Reserved            *
****************************************************************************/

#ifndef  _SOS_COMPRESS
#define  _SOS_COMPRESS

/* compression types */
enum {
	_ADPCM_TYPE_1,
	};

/* define compression structure */
typedef struct _tagCOMPRESS_INFO {
	char       *lpSource;
	char       *lpDest;
	unsigned long dwCompSize;
	unsigned long dwUnCompSize;
	unsigned long dwSampleIndex;
	long          dwPredicted;
	long          dwDifference;
	short         wCodeBuf;
	short         wCode;
	short         wStep;
	short         wIndex;

	unsigned long dwSampleIndex2; //added BP for channel 2
	long          dwPredicted2;   //added BP for channel 2
	long          dwDifference2; 	//added BP for channel 2
	short         wCodeBuf2; 		//added BP for channel 2
	short         wCode2; 			//added BP for channel 2
	short         wStep2; 			//added BP for channel 2
	short         wIndex2; 			//added BP for channel 2
	short         wBitSize;
	short			  wChannels;		//added BP for # of channels
	} _SOS_COMPRESS_INFO;

/* compressed file type header */
typedef struct _tagCOMPRESS_HEADER {
	unsigned long dwType;              // type of compression
	unsigned long dwCompressedSize;    // compressed file size
	unsigned long dwUnCompressedSize;  // uncompressed file size
	unsigned long dwSourceBitSize;     // original bit size
	char          szName[16];          // file type, for error checking
	} _SOS_COMPRESS_HEADER;

/* Prototypes */
extern "C" {
	void __cdecl sosCODECInitStream(_SOS_COMPRESS_INFO *);
	unsigned long __cdecl sosCODECCompressData(_SOS_COMPRESS_INFO *,	unsigned long);
	unsigned long __cdecl sosCODECDecompressData(_SOS_COMPRESS_INFO *, unsigned long);
	unsigned long __cdecl General_sosCODECDecompressData(_SOS_COMPRESS_INFO *, unsigned long);
}

#endif
