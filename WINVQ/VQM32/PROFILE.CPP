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
*     profile.c
*
* DESCRIPTION
*     INI file processing. (32-Bit protected mode)
*
* PROGRAMMER
*     Bill Randolph
*     Denzil E. Long, Jr.
*      
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     Get_Frame_Pathname - Get pathname for a given frame and file type.
*     GetINIInt          - Get an integer value from an INI file.
*     GetINIString       - Get a string from the INI file.
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "profile.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#ifndef max
#define max(a,b) (((a)>(b))?(a):(b))
#endif
#ifndef min
#define min(a,b) (((a)<(b))?(a):(b))
#endif

#define isspace(c) ((c==' ')||(c=='\t')||(c=='\n')||(c=='\r')?1:0)

static char *strtrim(char *string);
static long FileGets(FILE *fp, char *buf, long buflen);


/****************************************************************************
*
* NAME
*     Get_Frame_Pathname - Get pathname for a given frame and file type.
*
* SYNOPSIS
*     Error = Get_Frame_Pathname(IniFile, Frame, Extension, Buffer)
*
*     long Get_Frame_Pathname(char *, long, char *, char *);
*
* FUNCTION
*
* INPUTS
*     IniFile   - Pointer to INI filename.
*     Frame     - Number of frame to get filename for.
*     Extension - File extension type.
*     Buffer    - Pointer to buffer to put pathname into.
*
* RESULT
*     Error - 0 if successful, or -1 if error.
*
***************************************************************************/

long Get_Frame_Pathname(char *inifile, long anim_frame, char *ext,
		char *outbuf)
{
	char rootdir[_MAX_PATH];	// Root directory from INI file
	char extdir[_MAX_PATH];		// this extension's directory
	char entry_name[40];			// INI entry name
	char inibuf[80];					// string returned from INI file
	char *prefix;							// 4-char prefix for this scene
	char *startstr;						// starting frame #, string
	char *endstr;							// ending frame #, string
	char *palstr;							// palette filename string
	long startnum;						// scene's starting frame #
	long endnum;							// scene's ending frame #
	long total_frames;				// accumulated frame total
	long scene_frames;				// # frames in a given scene
	long scene_num;						// scene #
	long file_frame;					// file's frame #
	long rc;
	
	/* Get directory for this file type */
	GetINIString("Path", "Root", "", rootdir, 80, inifile);

	if (rootdir[strlen (rootdir) - 1] != '\\') {
		strcat(rootdir,"\\");
	}

	GetINIString("Path", ext, "", extdir, 80, inifile);

	if (extdir[strlen (extdir) - 1] != '\\') {
		strcat(extdir,"\\");
	}

	/* VQG is a special case:
	 *
	 * The VQG files are named based upon the 1st 4 characters of the 'Name'
	 * entry in the INI file, and their numbers match the actual animation
	 * frame numbers, not the scene frame numbers.
	 */
	if (!stricmp(ext, "VQG")) {
		GetINIString("Common", "Name", "", inibuf, 80, inifile);

		if (strlen(inibuf) > 4) {
			inibuf[4] = 0;
		}

		sprintf(outbuf,"%s%s%s%04d.%s",rootdir,extdir,inibuf,anim_frame,ext);
		return (0);
	}

	/*-------------------------------------------------------------------------
	 * Loop through scenes until the desired frame # is found
	 *-----------------------------------------------------------------------*/
	total_frames = 0;
	scene_num = 1;

	while (1) {

		/* Get this scene's entry */
		sprintf(entry_name, "Scene%d", scene_num);
		rc = GetINIString("Scenes",entry_name,"",inibuf,80,inifile);

		if (rc == 0) {
			return (-1);
		}

		/* Parse the INI entry */
		prefix = strtok(inibuf, ",");
		startstr = strtok(NULL, ",");
		endstr = strtok(NULL, ",");
		palstr = strtok(NULL, ",");

		if ((prefix == NULL) || (startstr == NULL) || (endstr == NULL)) {
			return (-1);
		}

		startnum = atoi(startstr);
		endnum = atoi(endstr);
		scene_frames = ((endnum - startnum) + 1);

		/* requested frame is found */
		if (anim_frame < (total_frames + scene_frames)) {

			/* Palette is a special case */
			if (!stricmp(ext, "PAL")) {
				if (palstr == NULL) {
					return (-1);
				} else {
					sprintf(outbuf, "%s%s%s.PAL", rootdir, extdir, palstr);
					return (0);
				}
			} else {
				file_frame = ((anim_frame - total_frames) + startnum);
				sprintf(outbuf,"%s%s%s%04d.%s",rootdir,extdir,prefix,file_frame,ext);
				return (0);
			}
		}

		/* Frame not found; go to next scene */
		total_frames += scene_frames;
		scene_num++;
	}
}


/****************************************************************************
*
* NAME
*     GetINIInt - Get an integer value from an INI file.
*
* SYNOPSIS
*     Value = GetINIInt(Section, Entry, Default, ININame)
*
*     long GetINIInt(char *, char *, long, char *);
*
* FUNCTION
*     Retrieve an integer value from the INI file at the specified 'Section'
*     and 'Entry' fields. If no value is defined then return the passed in
*     'Default' value.
*
* INPUTS
*     Section - Pointer to section name.
*     Entry   - Pointer to entry name.
*     Default - Default value.
*     ININame - Pointer to INI filename.
*
* RESULT
*     Value - Integer value from INI file or 'Default'.
*
****************************************************************************/

long GetINIInt(char const *section, char const *entry, long deflt, 
		char *fname)
{
	char buffer[20];

	sprintf(buffer, "%d", deflt);
	GetINIString(section, entry, buffer, buffer, sizeof(buffer),
			fname);

	return (atoi(buffer));
}


/****************************************************************************
*
* NAME
*     GetINIString - Get a string from the INI file.
*
* SYNOPSIS
*     Length = GetINIString(Section, Entry, Default, Buffer,
*                                      Length, ININame)
*
*     long GetINIString(char *, char *, char *, char *, long,
*                                  char *);
*
* FUNCTION
*
* INPUTS
*     Section - Pointer to section name.
*     Entry   - Pointer to entry name.
*     Default - Pointer to default string.
*     Buffer  - Pointer to buffer to copy string into.
*     Length  - Maximum length of string.
*     ININame - Pointer to INI filename.
*
* RESULT
*     Length - Length of string copied into the buffer.
*
****************************************************************************/

long GetINIString(char const *section, char const *entry, 
		char const *def, char *retbuffer, long retlen, char *fname)
{
	FILE *fp;
	long retval;
	char txt[80];
	char secname[40];
	long len;
	char *workptr;

	/* Copy default value in case entry isn't found */
	strncpy(retbuffer, def, (retlen - 1));
	retbuffer[retlen - 1] = 0;
	retval = min(strlen(def), (unsigned)retlen);

	/* Open the file */
	if ((fp = fopen(fname, "rt")) == NULL) {
		return (retval);
	}

	/* Generate section name for search */
	sprintf(secname, "[%s]", section);
	len = strlen(secname);

	/* Scan file for section name */
	while (1) {

		/* Read line; return if end-of-file */
		if (FileGets(fp,txt,80)!=0) {
			fclose(fp);
			return (retval);
		}

		/* Skip comments */
		if (txt[0] == ';') continue;

		/* Parse a section name */
		if (txt[0] == '[') {
			if (!memicmp(secname, txt, len)) break;
		}
	}

	/* Scan file for desired entry */
	len = strlen(entry);

	while (1) {

		/* Read line; return if end-of-file */
		if (FileGets(fp, txt, 80) != 0) {
			fclose(fp);
			return (retval);
		}

		/* Skip comments */
		if (txt[0] == ';') continue;

		/* Return if start of next section reached */
		if (txt[0] == '[') {
			fclose(fp);
			return (retval);
		}

		/* Entry found; parse it */
		if (!memicmp(entry, txt, len) && (isspace(txt[len])
				|| txt[len] == '=')) {

			fclose(fp);

			/* Find '=' character */
			workptr = strchr(txt, '=');

			/* Return if not found */
			if (workptr == NULL) return (retval);

			/* Skip past '=' */
			workptr++;

			/* Skip white space */
			while (isspace(*workptr) && strlen(workptr) > 0) {
				workptr++;
			}

			/* Return if no string left */
			if ((*workptr) == 0) return (retval);

			strtrim(workptr);
			strcpy(retbuffer,workptr);

			return (strlen(workptr));
		}
	}
}


/****************************************************************************
*
* NAME
*     strtrim - Trim off trailing spaces from a string.
*
* SYNOPSIS
*     String = strtrim(String)
*
*     char *strtrim(char *);
*
* FUNCTION
*
* INPUTS
*     String - Pointer to string to trim.
*
* RESULT
*     String - Pointer to trimmed string.
*
****************************************************************************/

static char *strtrim(char *string)
{
	long i;

	/* Return if NULL ptr or zero-length string */
	if ((string == NULL) || (strlen(string) == 0)) {
		return (string);
	}

	/* Find 1st non-white-space character from the right */
	i = (strlen(string) - 1);

	while ((i > 0) && isspace(string[i])) {
		i--;
	}

	/* Set end of string */
	i++;
	string[i] = 0;

	return (string);
}


/****************************************************************************
*
* NAME
*     FileGets - A better fgets.
*
* SYNOPSIS
*     Error = FileGets(FilePtr, Buffer, Length)
*
*     long FileGets(FILE *, char *, long);
*
* FUNCTION
*
* INPUTS
*     FilePtr - File pointer.
*     Buffer  - Pointer to buffer to fill.
*     Length  - Maximum length of buffer.
*
* RESULT
*     Error = 0 if successfull, or -1 if error.
*
****************************************************************************/

static long FileGets(FILE *fp, char *buf, long buflen)
{
	if (fgets(buf, buflen, fp)) {
		buf[(strlen(buf) - 1)] = 0;
		return (0);
	} else {
		return (-1);
	}
}

