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
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     captoken.c
*
* DESCRIPTION
*     Tokenize a caption script for playback processing.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     July 26, 1995
*
****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <ctype.h>
#include "captoken.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#define STRING_LENGTH 256
#define PADSIZE(size) (((size)+1)&(~1))

typedef enum {
	TOKEN_NULL = 0,
	TOKEN_BGCOL,
	TOKEN_FGCOL,
	TOKEN_XPOS,
	TOKEN_YPOS,
	TOKEN_ABS,
	TOKEN_LEFT,
	TOKEN_RIGHT,
	TOKEN_CENTER,
	TOKEN_FLASH,
	TOKEN_CPF,
	TOKEN_END
} TokenTag;

typedef struct _Token {
	char *name;
	long tag;
} Token;

/* Script tokens:
 * BG/BGCOL     - Background pen color (EX: BG=<color name>)
 * FG/FGCOL     - Foreground pen color (EX: FG=<color name>)
 * X/XPOS       - X pixel position of text (EX: X=<pixel cord>)
 * Y/YPOS       - Y pixel position of text (EX: Y=<pixel cord>)
 * ABS/ABSOLUTE - Absolute justification
 * LEFT         - Left side justification
 * RIGHT        - Right side justification
 * CENTER       - Center justification
 * FLASH        - Enable flashing of text
 * CPF          - Print rate in characters per frame (EX: CPF=<rate>)
 * END          - Terminate compilation of caption script
 */
Token tokens[] = {
	"BG", TOKEN_BGCOL,
	"BGCOL", TOKEN_BGCOL,
	"FG", TOKEN_FGCOL,
	"FGCOL", TOKEN_FGCOL,
	"X", TOKEN_XPOS,
	"XPOS", TOKEN_XPOS,
	"Y", TOKEN_YPOS,
	"YPOS", TOKEN_YPOS,
	"ABS", TOKEN_ABS,
	"ABSOLUTE", TOKEN_ABS,
	"LEFT", TOKEN_LEFT,
	"RIGHT", TOKEN_RIGHT,
	"CENTER", TOKEN_CENTER,
	"FLASH", TOKEN_FLASH,
	"CPF", TOKEN_CPF,
	"END", TOKEN_END,
	NULL, TOKEN_NULL,
};

Token colors[] = {
	"BLACK", 0,
	"WHITE", 251,
	"RED", 252,
	"GREEN", 253,
	"SHADOW", 254,
	"CYCLE", 255,
	NULL, -1,
};

/* Prototypes. */
static long GetColorNum(char *name);
static long IsNumeric(char *string);
static void FormatString(char *string);


/****************************************************************************
*
* NAME
*     BuildCaptions - Compile a caption script.
*
* SYNOPSIS
*     Size = BuildCaptions(Name, Buffer)
*
*     long BuildCaptions(char *, char *);
*
* FUNCTION
*     Generate a compiled caption script for use in VQA playback.
*
* INPUTS
*     Name   - Name of caption script file to compile.
*     Buffer - Buffer to put compiled captions into.
*
* RESULT
*     Size - Size of compiled captions (in bytes).
*
****************************************************************************/

long BuildCaptions(char *name, char *buffer)
{
	FILE        *fp;
	char        *ptr;
	char        *ptr1;
	long        size = 0;
	long        error;
	long        i;
	long        tag;
	CaptionText caption;
	char        string[STRING_LENGTH];

	/* Initialize the caption parameters. */
	memset(&caption, 0, sizeof(CaptionText));

	/* Open the captions script file. */
	fp = fopen(name, "r");

	if (fp != NULL) {
		error = 0;

		while (!error) {
			if (fgets(string, STRING_LENGTH, fp) == NULL) {
				if (errno == 0) {
					error = 1;
				}

				break;
			}
	
			/* Replace the newline with a NULL terminator. */
			string[strlen(string) - 1] = 0;

			/* Ignore comment lines. */
			if (string[0] == ';') continue;

			ptr = strtok(string, "=");

			if (ptr != NULL) {

				/* Check for a comma */
				ptr1 = strchr(ptr, ',');

				if (ptr1 != NULL) {
					*ptr1++ = 0;
				}

				/* Is this a frame number. */
				if (IsNumeric(ptr) && IsNumeric(ptr1)) {
					i = atoi(ptr);

					/* Frames must be defined in ascending order. */
					if ((unsigned short)i >= caption.OnFrame) {
						caption.OnFrame = i;
						caption.OffFrame = atoi(ptr1);
						caption.Size = sizeof(CaptionText);

						/* Get caption text. */
						ptr = strtok(NULL, "");

						if (ptr != NULL) {
							FormatString(ptr);
							i = strlen(ptr) + 1;
							caption.Size += PADSIZE(i);
							size += caption.Size;

							/* Copy the caption structure. */
							memcpy(buffer, &caption, sizeof(CaptionText));
							buffer += sizeof(CaptionText);

							/* Copy the caption text. */
							memcpy(buffer, ptr, i);
							buffer += i;

							/* WORD align */
							if (PADSIZE(i) > i) {
								*buffer++ = 0;
							}
						}
					} else {
						error = 1;
						break;
					}
				} else {

					/* Search for matching token. */
					tag = TOKEN_NULL;
					i = 0;

					while (tokens[i].name != NULL) {
						if (strcmpi(tokens[i].name, ptr) == 0) {
							tag = tokens[i].tag;
							break;
						}

						i++;
					}

					/* Get the data element. */
					ptr = strtok(NULL, "");

					switch (tag) {
						case TOKEN_BGCOL:
							caption.BgPen = (char)GetColorNum(ptr);
							break;

						case TOKEN_FGCOL:
							caption.FgPen = (char)GetColorNum(ptr);
							break;

						case TOKEN_XPOS:
							caption.Xpos = (unsigned short)atoi(ptr);
							break;

						case TOKEN_YPOS:
							caption.Ypos = (unsigned short)atoi(ptr);
							break;

						case TOKEN_ABS:
							caption.Flags &= ~CTF_JUSTIFY;
							caption.Flags |= CTF_ABS;
							break;

						case TOKEN_LEFT:
							caption.Flags &= ~CTF_JUSTIFY;
							caption.Flags |= CTF_LEFT;
							break;

						case TOKEN_RIGHT:
							caption.Flags &= ~CTF_JUSTIFY;
							caption.Flags |= CTF_RIGHT;
							break;

						case TOKEN_CENTER:
							caption.Flags &= ~CTF_JUSTIFY;
							caption.Flags |= CTF_CENTER;
							break;

						case TOKEN_FLASH:
							if (strcmpi(ptr, "OFF") == 0) {
								caption.Flags &= ~CTF_FLASH;
							} else {
								caption.Flags |= CTF_FLASH;
							}
							break;

						case TOKEN_CPF:
							caption.CPF = (char)atoi(ptr);
							break;

						/* Termination captions */
						case TOKEN_END:
							caption.Size = sizeof(CaptionText);
							caption.OnFrame = (unsigned short)-1;
							memcpy(buffer, &caption, sizeof(CaptionText));
							buffer += sizeof(CaptionText);
							break;

						default:
							break;
					}
				}
			}
		}

		/* Close the script file. */
		fclose(fp);
	}

	return (size);
}


/****************************************************************************
*
* NAME
*     GetColorNum - Get the color number from the color name.
*
* SYNOPSIS
*     Color = GetColorNum(Name)
*
*     long GetColorNum(char *);
*
* FUNCTION
*     Look the color number that corresponds to the color name.
*
* INPUTS
*     Name - Name of color.
*
* RESULT
*     Color - Color number.
*
****************************************************************************/

static long GetColorNum(char *name)
{
	long color = -1;
	long i;

	i = 0;

	/* Scan for a matching name and return the corresponding color number. */
	while (colors[i].name != NULL) {
		if (strcmpi(colors[i].name, name) == 0) {
			color = colors[i].tag;
		}

		i++;
	}

	return (color);
}


/****************************************************************************
*
* NAME
*     IsNumeric - Check if a string is numeric.
*
* SYNOPSIS
*     Condition = IsNumeric(String)
*
*     long IsNumeric(char *);
*
* FUNCTION
*     Interogate the string to see if it represents a numeric value. Each
*     byte of the string must be between 0x30 and 0x39 inclusively.
*
* INPUTS
*     String - String to check.
*
* RESULT
*     Condition - 1 if numeric, 0 if not.
*
****************************************************************************/

static long IsNumeric(char *string)
{
	long flag = 1;

	/* Ignore any proceeding sign designation. */
	if ((*string == '-') || (*string == '+')) {
		string++;
	}

	/* Check to see if every byte in the string is a digit. */
	while (flag && (*string != 0)) {
		if (!isdigit(*string++)) {
			flag = 0;
		}
	}

	return (flag);
}


/****************************************************************************
*
* NAME
*     FormatString - Parse any format codes in the string.
*
* SYNOPSIS
*     FormatString(String)
*
*     void FormatString(char *);
*
* FUNCTION
*     Format a string with any embedded format commands contained in the
*     input string.
*
*     Supported format commands:
*       /n - Insert carriage return. (0x0D)
*       /r - Insert carriage return. (0x0D)
*       // - Literal backslash.
*
* INPUTS
*     String - Pointer to string to format.
*
* RESULT
*     NONE
*
****************************************************************************/

static void FormatString(char *string)
{
	char *ptr;

	/* NULL strings are invalid. */
	if (string != NULL) {
		ptr = string;

		/* Scan the string for embedded format commands. */
		while ((ptr = strchr(ptr, '/')) != NULL) {
			switch (*(ptr + 1)) {

				/* Carriage return. */
				case 'n':
				case 'r':
					*ptr = 0x0D;
					break;

				/* Literal backslash. */
				case '/':
					break;

				default:
					break;
			}

			/* Remove the unwanted character. */
			strcpy((ptr + 1), (ptr + 2));
		}
	}
}

