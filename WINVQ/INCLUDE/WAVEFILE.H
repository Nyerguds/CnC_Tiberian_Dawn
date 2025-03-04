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

#ifndef WAVEFILE_H
#define WAVEFILE_H
/****************************************************************************
*
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     wavefile.c
*
* DESCRIPTION
*     WAVE file format definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*      
* DATE
*     February 21, 1995
*
****************************************************************************/

/* WAVHeader: WAVE file header.
 *
 * RIFF - 4 byte identifier (always "RIFF").
 * Size - Size in bytes of entire file.
 * WAVE - 4 byte identifier (always "WAVE").
 */
typedef struct _WAVHeader {
	long RIFF;
	long Size;
	long WAVE;
} WAVHeader;

/* WAVFormat: This structure describes the format of the audio data contained
 *            in the WAV file.
 *
 * FormatTag      - 
 * Channels       - Number of channels (1 = mono, 2 = stereo).
 * SamplesPerSec  - Sampling rate.
 * AvgBytesPerSec - Bytes in 1 second of audio (Rate * SampleSize * Channels)
 * BlockAlign     - padding.
 * BitsPerSample  - Number of bits per sample (8, 16).
 */
typedef struct _WAVFormat {
	short FormatTag;
	short Channels;
	long  SamplesPerSec;
 	long  AvgBytesPerSec;
	short BlockAlign;
	short BitsPerSample;
} WAVFormat;

#endif /* WAVEFILE_H */

