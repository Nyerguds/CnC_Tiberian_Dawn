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
 *                    File Name : MONOCHRM.CPP                             *
 *                                                                         *
 *                   Programmer : Michael Legg                             *
 *                                                                         *
 *                   Start Date : May 10, 1995                             *
 *                                                                         *
 *                  Last Update : May 30, 1995   [ML]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *                                                                         *
 *  These are not our functions, but Microsoft's from DBWIN.EXE            *
 *                                                                         *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <mem.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <monochrm.h>
#include <westwood.h>

typedef struct
{
	 char ch;
	 char attr;
} CA;

#define CCOLMAX         80
#define CROWMAX       	25

#define ESC             27
#define BELL            7
#define DEFATTR       	0x07
#define CA_SPACE        ((DEFATTR << 8) | ' ')

// row+1 = DBWIN
#define PCA(row, col)   (0xB0000 + ( (((row+0)*CCOLMAX)+col) * sizeof(CA)))

static void Monochrome_Output( char *string );
static void CACopy( CA *pcaDst, CA *pcaSrc, int cca );
static void CAFill( CA *pcaDst, int cca, int ca );

int rowCur = 0;
int colCur = 0;

/***************************************************************************
 * DEBUG_PRINTF - works like printf, with limit of 10 variable args        *
 *                                                                         *
 * INPUT: same as printf                                                   *
 *                                                                         *
 * OUTPUT: a message on the monochrome monitor display                     *
 *                                                                         *
 * WARNINGS: try to end messages with \r\n!                                *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
void Debug_Printf( char *format_string, ... )
{
	va_list ap;
	int arg[ 10 ];
	char output_string[ 255 ];

	va_start( ap, format_string );
	arg[ 0 ] = va_arg( ap, int );
	arg[ 1 ] = va_arg( ap, int );
	arg[ 2 ] = va_arg( ap, int );
	arg[ 3 ] = va_arg( ap, int );
	arg[ 4 ] = va_arg( ap, int );
	arg[ 5 ] = va_arg( ap, int );
	arg[ 6 ] = va_arg( ap, int );
	arg[ 7 ] = va_arg( ap, int );
	arg[ 8 ] = va_arg( ap, int );
	arg[ 9 ] = va_arg( ap, int );
	va_end( ap );

	sprintf( (char *) output_string,
				(char *) format_string,
				arg[ 0 ],
				arg[ 1 ],
				arg[ 2 ],
				arg[ 3 ],
				arg[ 4 ],
				arg[ 5 ],
				arg[ 6 ],
				arg[ 7 ],
				arg[ 8 ],
				arg[ 9 ] );

	Debug_Mono_Message( (char *) output_string );
}

/***************************************************************************
 * DEBUG_MONO_MESSAGE -- Post a line to the monochrome monitor             *
 *                                                                         *
 * INPUT: the message to print                                             *
 *                                                                         *
 * OUTPUT: a message on the monochrome monitor display                     *
 *                                                                         *
 * WARNINGS: try to end messages with \r\n!                                *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
void Debug_Mono_Message( char *message )
{
	char *temp_string;
	char *temp_null_position;
	char temp_char;
	int length_left;

	length_left = strlen( message );
	temp_null_position = message;
	while ( length_left > CCOLMAX ) {
		temp_string = temp_null_position;
		temp_null_position += CCOLMAX;
		temp_char = *temp_null_position;
		temp_null_position[ 0 ] = '\0';

		Monochrome_Output( temp_string );

		*temp_null_position = temp_char;
		length_left -= CCOLMAX;
	}
	temp_string = temp_null_position;

	Monochrome_Output( temp_string );
}

static void Monochrome_Output( char *string )
{
	 CA *pca;
	 char ch;
	 static int _initialized = FALSE;

	 pca = (CA *) PCA(rowCur, colCur);

	 if ( ! _initialized ) {
		  CAFill( (CA *) PCA(0, 0),
					 (CCOLMAX * CROWMAX),
					 CA_SPACE );
		  colCur = 0;
		  rowCur = 0;
		  _initialized = TRUE;
	 }

	 while ( TRUE ) {

		ch = *string++;
		if ( ! ch ) {
			break;
		}

		switch (ch) {

		  case '\b':
				if (colCur > 0)
				{
					 colCur--;
					 pca--;
					 pca->ch = ' ';
					 pca->attr = DEFATTR;
				}
				break;

		  case BELL:
//				MessageBeep(0);
				break;

		  case '\t':
				pca    += 8 - colCur % 8;
				colCur += 8 - colCur % 8;
				break;

		  case '\r':
				colCur = 0;
				pca = (CA *) PCA(rowCur, colCur);
				break;

		  default:
				pca->ch = ch;
				pca->attr = DEFATTR;
				pca++;
				colCur++;

				if (colCur < CCOLMAX)
					 break;

				// fall through to handle LF

		  case '\n':
				colCur = 0;
				rowCur++;

				if (rowCur >= CROWMAX)
				{
					 CACopy( (CA *) PCA(0, 0), (CA *) PCA(1, 0), CCOLMAX * (CROWMAX - 1));
					 CAFill( (CA *) PCA(CROWMAX - 1, 0), CCOLMAX, CA_SPACE);
					 rowCur = CROWMAX - 1;
				}

				pca = (CA *) PCA(rowCur, colCur);
				break;

		  case ESC:
				//
				// ANSI clear screen escape
				//
				if (string[1] == '[' && string[2] == '2' && string[3] == 'J')
				{
					 CAFill( (CA *)PCA(0,0), CCOLMAX * CROWMAX, CA_SPACE);
					 rowCur = colCur = 0;
					 string += 3;
				}
		  }
	 }
}

static void CACopy( CA *pcaDst, CA *pcaSrc, int cca )
{
	int i;

	for ( i = 0; i < cca; i ++ ) {
		*pcaDst = *pcaSrc;
		pcaDst ++;
		pcaSrc ++;
	}
}

static void CAFill( CA *pcaDst, int cca, int ca )
{
	int i;

	for ( i = 0; i < cca; i ++ ) {
		memcpy( pcaDst, &ca, sizeof( int ) );
		pcaDst ++;
	}
}
