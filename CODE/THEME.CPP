/*
**	Command & Conquer(tm)
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

/* $Header:   F:\projects\c&c\vcs\code\theme.cpv   2.18   16 Oct 1995 16:51:10   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : THEME.CPP                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : August 14, 1994                                              *
 *                                                                                             *
 *                  Last Update : May 29, 1995 [JLB]                                           *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   ThemeClass::Scan -- Scans all scores for availability.                                    *
 *   ThemeClass::AI -- Process the theme engine and restart songs.                             *
 *   ThemeClass::Base_Name -- Fetches the base filename for the theme specified.               *
 *   ThemeClass::From_Name -- Determines theme number from specified name.                     *
 *   ThemeClass::Full_Name -- Retrieves the full score name.                                   *
 *   ThemeClass::Is_Allowed -- Checks to see if the specified theme is legal.                  *
 *   ThemeClass::Next_Song -- Calculates the next song number to play.                         *
 *   ThemeClass::Play_Song -- Starts the specified song play NOW.                              *
 *   ThemeClass::Queue_Song -- Queues the song to the play queue.                              *
 *   ThemeClass::Still_Playing -- Determines if music is still playing.                        *
 *   ThemeClass::Stop -- Stops the current theme from playing.                                 *
 *   ThemeClass::ThemeClass -- Default constructor for the theme manager class.                *
 *   ThemeClass::Theme_File_Name -- Constructs a filename for the specified theme.             *
 *   ThemeClass::Track_Length -- Caclulates the length of the song (in seconds).               *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"function.h"

#include	"theme.h"


/*
**	These are the actual filename list for the theme sample files.
*/
// Nyerguds's TUC Quick Fix Patch v1.03: var-music-length
// Introduces specific properties for the length and availability of the variations of themes, and
// enabled the tracks "AIRSTRIK", "80MX226M", "DIE", "VALKYRIE", and disables the "Loop" status on "VALKYRIE".
// Also enables the Variation on JUSTDOIT, NOMERCY and STOPTHEM, with their added variation length, since
// they exist on the soundtrack and could be added.
ThemeClass::ThemeControl ThemeClass::_themes[THEME_COUNT] = {
//	Name,		Fullname,		Scen,	Dur,	VarDur,	Normal,	Var,	Rept,	Avlb,	VarAvl
	{"AIRSTRIK",	TXT_THEME_AIRSTRIKE,	0,	200,	0,	true,	false,	false,	true,	false},
	{"80MX226M",	TXT_THEME_80MX,		0,	248,	0,	true,	false,	false,	true,	false},
	{"CHRG226M",	TXT_THEME_CHRG,		0,	256,	0,	true,	false,	false,	true,	false},
	{"CREP226M",	TXT_THEME_CREP,		0,	222,	0,	true,	false,	false,	true,	false},
	{"DRIL226M",	TXT_THEME_DRIL,		0,	272,	0,	true,	false,	false,	true,	false},
	{"DRON226M",	TXT_THEME_DRON,		0,	275,	0,	true,	false,	false,	true,	false},
	{"FIST226M",	TXT_THEME_FIST,		0,	212,	0,	true,	false,	false,	true,	false},
	{"RECN226M",	TXT_THEME_RECON,	0,	261,	0,	true,	false,	false,	true,	false},
	{"VOIC226M",	TXT_THEME_VOICE,	0,	306,	0,	true,	false,	false,	true,	false},
	{"HEAVYG",	TXT_THEME_HEAVYG,	0,	180,	0,	true,	false,	false,	true,	false},
//	{"J1",		TXT_THEME_J1,		4,	187,	0,	false,	false,	false,	true,	false},
	{"J1",		TXT_THEME_J1,		4,	187,	0,	true,	false,	false,	true,	false},
	{"JDI_V2",	TXT_THEME_JDI_V2,	5,	183,	0,	true,	false,	false,	true,	false},
	{"RADIO",	TXT_THEME_RADIO,	6,	183,	0,	true,	false,	false,	true,	false},
	{"RAIN",	TXT_THEME_RAIN,		7,	156,	0,	true,	false,	false,	true,	false},
	{"AOI",		TXT_THEME_AOI,		0,	168,	172,	true,	true,	false,	true,	false},
	{"CCTHANG",	TXT_THEME_CCTHANG,	12,	193,	0,	true,	false,	false,	true,	false},
	{"DIE",		TXT_THEME_DIE,		11,	162,	0,	true,	false,	false,	true,	false},
	{"FWP",		TXT_THEME_FWP,		10,	53,	0,	true,	false,	false,	true,	false},
	{"IND",		TXT_THEME_IND,		1,	175,	0,	true,	false,	false,	true,	false},
	{"IND2",	TXT_THEME_IND2,		1,	38,	0,	true,	false,	false,	true,	false},
	{"JUSTDOIT",	TXT_THEME_JUSTDOIT,	9,	142,	144,	true,	true,	false,	true,	false},
	{"LINEFIRE",	TXT_THEME_LINEFIRE,	8,	125,	0,	true,	false,	false,	true,	false},
	{"MARCH",	TXT_THEME_MARCH,	7,	157,	0,	true,	false,	false,	true,	false},
	{"TARGET",	TXT_THEME_TARGET,	0,	173,	0,	true,	false,	false,	true,	false},
	{"NOMERCY",	TXT_THEME_NOMERCY,	2,	204,	197,	true,	true,	false,	true,	false},
	{"OTP",		TXT_THEME_OTP,		3,	182,	0,	true,	false,	false,	true,	false},
	{"PRP",		TXT_THEME_PRP,		4,	211,	0,	true,	false,	false,	true,	false},
	{"ROUT",	TXT_THEME_ROUT,		12,	0,	121,	false,	true,	false,	true,	false},
	{"HEART",	TXT_THEME_HEART,	5,	0,	206,	false,	true,	false,	true,	false},
	{"STOPTHEM",	TXT_THEME_STOPTHEM,	0,	190,	189,	true,	true,	false,	true,	false},
	{"TROUBLE",	TXT_THEME_TROUBLE,	6,	191,	132,	true,	true,	false,	true,	false},
	{"WARFARE",	TXT_THEME_WARFARE,	0,	182,	0,	true,	false,	false,	true,	false},
	{"BEFEARED",	TXT_THEME_BEFEARED,	13,	164,	101,	true,	true,	false,	true,	false},
	{"I_AM",	TXT_THEME_IAM,		6,	161,	0,	true,	false,	false,	true,	false},
	{"WIN1",	TXT_THEME_WIN1,		0,	41,	56,	false,	true,	true,	true,	false},
	{"MAP1",	TXT_THEME_WIN1,		0,	61,	0,	false,	false,	true,	true,	false},
	{"VALKYRIE",	TXT_THEME_VALK,		0,	306,	0,	true,	false,	false,	true,	false},
};


/***********************************************************************************************
 * ThemeClass::Base_Name -- Fetches the base filename for the theme specified.                 *
 *                                                                                             *
 *    This routine is used to retrieve a pointer to the base filename for the theme            *
 *    specified.                                                                               *
 *                                                                                             *
 * INPUT:   theme -- The theme number to convert into a base filename.                         *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the base filename for the theme specified. If the        *
 *          theme number is invalid, then a pointer to "No Theme" is returned instead.         *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/29/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
char const * ThemeClass::Base_Name(ThemeType theme) const
{
	if (theme != THEME_NONE) {
		return(_themes[theme].Name);
	}
	return("No theme");
}


/***********************************************************************************************
 * ThemeClass::ThemeClass -- Default constructor for the theme manager class.                  *
 *                                                                                             *
 *    This is the default constructor for the theme class object.                              *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
ThemeClass::ThemeClass(void)
{
	Current = -1;
	Score = THEME_NONE;
	Pending = THEME_NONE;
}


/***********************************************************************************************
 * ThemeClass::Full_Name -- Retrieves the full score name.                                     *
 *                                                                                             *
 *    This routine will fetch and return with a pointer to the full name of the theme          *
 *    specified.                                                                               *
 *                                                                                             *
 * INPUT:   theme -- The theme to fetch the full name for.                                     *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the full name for this score. This pointer may point to  *
 *          EMS memory.                                                                        *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
char const * ThemeClass::Full_Name(ThemeType theme) const
{
	if (theme != THEME_NONE) {
		return(Text_String(_themes[theme].Fullname));
	}
	return(NULL);
}


/***********************************************************************************************
 * ThemeClass::AI -- Process the theme engine and restart songs.                               *
 *                                                                                             *
 *    This is a maintenance function that will restart an appropriate theme if the current one *
 *    has finished. This routine should be called frequently.                                  *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/08/1994 JLB : Created.                                                                 *
 *   01/23/1995 JLB : Picks new song just as it is about to play it.                           *
 *=============================================================================================*/
void ThemeClass::AI(void)
{
	if (SampleType && !Debug_Quiet) {
		if (ScoresPresent && Options.ScoreVolume && !Still_Playing() && Pending != THEME_NONE) {

			/*
			**	If the pending song needs to be picked, then pick it now.
			*/
			if (Pending == THEME_PICK_ANOTHER) {
				Pending = Next_Song(Score);
			}

			/*
			**	Start the song playing and then flag it so that a new song will
			**	be picked when this one ends.
			*/
			Play_Song(Pending);
			Pending = THEME_PICK_ANOTHER;
		}
		Sound_Callback();
	}
}


/***********************************************************************************************
 * ThemeClass::Next_Song -- Calculates the next song number to play.                           *
 *                                                                                             *
 *    use this routine to figure out what song number to play. It examines the option settings *
 *    for repeat and shuffle so that it can return the correct value.                          *
 *                                                                                             *
 * INPUT:   theme -- The origin (last) index. The new value is related to this for all but     *
 *                   the shuffling method of play.                                             *
 *                                                                                             *
 * OUTPUT:  Returns with the song number for the next song to play.                            *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *   01/19/1995 JLB : Will not play the same song twice when in shuffle mode.                  *
 *=============================================================================================*/
ThemeType ThemeClass::Next_Song(ThemeType theme)
{
	if (theme == THEME_NONE) {
		theme = Next_Song(THEME_PICK_ANOTHER);
	} else {
		if (theme == THEME_PICK_ANOTHER || (!_themes[theme].Repeat && !Options.IsScoreRepeat)) {
			if (Options.IsScoreShuffle) {

				/*
				**	Shuffle the theme, but never pick the same theme that was just
				**	playing.
				*/
				ThemeType newtheme;
				do {
					newtheme = Sim_Random_Pick(THEME_FIRST, THEME_LAST);
				} while(newtheme == theme || !Is_Allowed(newtheme));
				theme = newtheme;

			} else {

				/*
				**	Sequential score playing.
				*/
				do {
					theme++;
					if (theme > THEME_LAST) {
						theme = THEME_FIRST;
					}
				} while(!Is_Allowed(theme));
			}
		}
	}
	return(theme);
}


/***********************************************************************************************
 * ThemeClass::Queue_Song -- Queues the song to the play queue.                                *
 *                                                                                             *
 *    This routine will cause the current song to fade and the specified song to start. This   *
 *    is the normal and friendly method of changing the current song.                          *
 *                                                                                             *
 * INPUT:   theme -- The song to start playing. If -1 is pssed in, then just the current song  *
 *                   is faded.                                                                 *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
void ThemeClass::Queue_Song(ThemeType theme)
{
	if (ScoresPresent && SampleType && !Debug_Quiet && (Pending == THEME_NONE || Pending == THEME_PICK_ANOTHER)) {
		if (!Options.ScoreVolume && theme != THEME_NONE) return;

		Pending = theme;
		Fade_Sample(Current, THEME_DELAY);
	}
}


/***********************************************************************************************
 * ThemeClass::Play_Song -- Starts the specified song play NOW.                                *
 *                                                                                             *
 *    This routine is used to start the specified theme playing right now. If there is already *
 *    a theme playing, it is cut short so that this one may start.                             *
 *                                                                                             *
 * INPUT:   theme -- The theme number to start playing.                                        *
 *                                                                                             *
 * OUTPUT:  Returns with the sample play handle.                                               *
 *                                                                                             *
 * WARNINGS:   This cuts off any current song in a abrubt manner. Only use this routine when   *
 *             necessary.                                                                      *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
int ThemeClass::Play_Song(ThemeType theme)
{
	if (ScoresPresent && SampleType && !Debug_Quiet && Options.ScoreVolume) {
		Stop();
		Score = theme;
		if (theme >= THEME_FIRST) {

#ifdef DEMO
			if (_themes[theme].Scenario != 99) {
				CCFileClass file(Theme_File_Name(theme));
				if (file.Is_Available()) {
					Current = File_Stream_Sample_Vol(Theme_File_Name(theme), 0xFF, true);
				} else {
					Current = -1;
				}
			} else {
				Current = -1;
			}
#else
			Current = File_Stream_Sample_Vol(Theme_File_Name(theme), 0xFF, true);
#endif
		}
	}
	return(Current);
}


/***********************************************************************************************
 * ThemeClass::Theme_File_Name -- Constructs a filename for the specified theme.               *
 *                                                                                             *
 *    This routine will construct (into a static buffer) a filename that matches the theme     *
 *    number specified. This constructed filename is returned as a pointer. The filename will  *
 *    remain valid until the next call to this routine.                                        *
 *                                                                                             *
 * INPUT:   theme -- The theme number to convert to a filename.                                *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the constructed filename for the specified theme number. *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *   05/09/1995 JLB : Theme variation support.                                                 *
 *   06/12/2025 MM  : Adapted to use VariationAvailable and leave the rest to the overload.    *
 *=============================================================================================*/
char const * ThemeClass::Theme_File_Name(ThemeType theme)
{
	// Nyerguds's TUC Quick Fix Patch v1.03: var-music-length
	return Theme_File_Name(theme, _themes[theme].VariationAvailable);
}


/***********************************************************************************************
 * ThemeClass::Theme_File_Name -- Constructs a filename for the specified theme.               *
 *                                                                                             *
 *    This routine will construct (into a static buffer) a filename that matches the theme     *
 *    number specified. This constructed filename is returned as a pointer. The filename will  *
 *    remain valid until the next call to this routine.                                        *
 *                                                                                             *
 * INPUT:   theme -- The theme number to convert to a filename.                                *
 *          variation -- whether to get the normal filename, or the one for the variation      *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the constructed filename for the specified theme number. *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/12/2025 MM  : Created overload with specific argument for getting the variation.       *
 *=============================================================================================*/
char const * ThemeClass::Theme_File_Name(ThemeType theme, bool variation)
{
	static char name[_MAX_FNAME+_MAX_EXT];

	if (variation) {
		_makepath(name, NULL, NULL, _themes[theme].Name, ".VAR");
	}
	_makepath(name, NULL, NULL, _themes[theme].Name, ".AUD");
	return((char const *)(&name[0]));
}


/***********************************************************************************************
 * ThemeClass::Track_Length -- Caclulates the length of the song (in seconds).                 *
 *                                                                                             *
 *    Use this routine to calculate the length of the song. The length is determined by        *
 *    reading the header of the song and dividing the sample rate into the sample length.      *
 *                                                                                             *
 * INPUT:   theme -- The song number to examine to find its length.                            *
 *                                                                                             *
 * OUTPUT:  Returns with the length of the specified theme. This length is in the form of      *
 *          seconds.                                                                           *
 *                                                                                             *
 * WARNINGS:   This routine goes to disk to fetch this information. Don't call frivolously.    *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/16/1995 JLB : Created.                                                                 *
 *   06/12/2025 MM  : Added specific variation version.                                        * 
 *=============================================================================================*/
int ThemeClass::Track_Length(ThemeType theme)
{
	// Nyerguds's TUC Quick Fix Patch v1.03: var-music-length
	if ((unsigned)theme < THEME_COUNT) {
		if (Special.IsVariation && _themes[theme].VariationAvailable) {
			return _themes[theme].VariationDuration;
	 	} else {
			return _themes[theme].Duration;
		}
	}
	return(0);
}


/***********************************************************************************************
 * ThemeClass::Stop -- Stops the current theme from playing.                                   *
 *                                                                                             *
 *    Use this routine to stop the current theme. After this routine is called, no more music  *
 *    will play until the Start() function is called.                                          *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/08/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void ThemeClass::Stop(void)
{
	if (ScoresPresent && SampleType && !Debug_Quiet) {
		if (Current != -1) {
			Stop_Sample(Current);
			Current = -1;
			Score = THEME_NONE;
			Pending = THEME_NONE;
		}
	}
}


/***********************************************************************************************
 * ThemeClass::Still_Playing -- Determines if music is still playing.                          *
 *                                                                                             *
 *    Use this routine to determine if music is still playing.                                 *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  bool; Is the music still audible?                                                  *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/20/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
int ThemeClass::Still_Playing(void)
{
	if (ScoresPresent && SampleType && Current != -1 && !Debug_Quiet) {
		return(Sample_Status(Current));
	}
	return(false);
}


/***********************************************************************************************
 * ThemeClass::Is_Allowed -- Checks to see if the specified theme is legal.                    *
 *                                                                                             *
 *    Use this routine to determine if a theme is allowed to be played. A theme is not allowed *
 *    if the scenario is too early for that score, or the score only is allowed in special     *
 *    cases.                                                                                   *
 *                                                                                             *
 * INPUT:   index -- The score the check to see if it is allowed to play.                      *
 *                                                                                             *
 * OUTPUT:  Is the specified score allowed to play in the normal score playlist?               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/09/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
bool ThemeClass::Is_Allowed(ThemeType index) const
{
#ifdef DEMO
	char buffer[128];

	sprintf(buffer, "%s.AUD", Base_Name(index));
	CCFileClass file(buffer);
	if (_themes[index].Scenario == 99 || !file.Is_Available()) {
		_themes[index].Scenario = 99;
		return(false);
	}
#endif

	return(
		_themes[index].Available &&
		(_themes[index].Normal ||
//		(index == THEME_MAP1 && ScenarioInit) ||
		((Special.IsVariation && _themes[index].Variation && index != THEME_WIN1) &&
#ifndef DEMO
		(GameToPlay != GAME_NORMAL || _themes[index].Scenario <= Scenario) &&
#endif
		(index != THEME_J1 || Special.IsJurassic))));
}


/***********************************************************************************************
 * ThemeClass::From_Name -- Determines theme number from specified name.                       *
 *                                                                                             *
 *    Use this routine to convert a name (either the base filename of the theme, or a partial  *
 *    substring of the full name) into the matching ThemeType value. Typical use of this is    *
 *    when parsing the INI file for theme control values.                                      *
 *                                                                                             *
 * INPUT:   name  -- Pointer to base filename of theme or a partial substring of the full      *
 *                   theme name.                                                               *
 *                                                                                             *
 * OUTPUT:  Returns with the matching theme number. If no match could be found, then           *
 *          THEME_NONE is returned.                                                            *
 *                                                                                             *
 * WARNINGS:   If a filename is specified the comparison is case insensitive. When scanning    *
 *             the full theme name, the comparison is case sensitive.                          *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/29/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
ThemeType ThemeClass::From_Name(char const * name)
{
	if (name && strlen(name) > 0) {
		/*
		**	First search for an exact name match with the filename
		**	of the theme. This is guaranteed to be unique.
		*/
		for (ThemeType theme = THEME_FIRST; theme < THEME_COUNT; theme++) {
			if (stricmp(_themes[theme].Name, name) == 0) {
				return(theme);
			}
		}

		/*
		**	If the filename scan failed to find a match, then scan for
		**	a substring within the full name of the score. This might
		**	yeild a match, but is not guaranteed to be unique.
		*/
		for (theme = THEME_FIRST; theme < THEME_COUNT; theme++) {
			if (strstr(Text_String(_themes[theme].Fullname), name) != NULL) {
				return(theme);
			}
		}
	}

	return(THEME_NONE);
}


/***********************************************************************************************
 * ThemeClass::Scan -- Scans all scores for availability.                                      *
 *                                                                                             *
 *    This routine should be called whenever a score mixfile is registered. It will scan       *
 *    to see if any score is unavailable. If this is the case, then the score will be so       *
 *    flagged in order not to appear on the play list. This condition is likely to occur       *
 *    when expansion mission disks contain a different score mix than the release version.     *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/04/1996 JLB : Created.                                                                 *
 *   06/12/2025 MM  : Added specific variation scan.                                           * 
 *=============================================================================================*/
void ThemeClass::Scan(void)
{
	// Nyerguds's TUC Quick Fix Patch v1.03: var-music-length
	for (ThemeType theme = THEME_FIRST; theme < THEME_COUNT; theme++) {
		if (Special.IsVariation && _themes[theme].Variation && CCFileClass(Theme_File_Name(theme, true)).Is_Available()) {
			_themes[theme].Available = true;
			_themes[theme].VariationAvailable = true;
		} else {
			_themes[theme].Available = CCFileClass(Theme_File_Name(theme, false)).Is_Available();
			_themes[theme].VariationAvailable = false;
		}
	}
//	for (ThemeType theme = THEME_FIRST; theme < THEME_COUNT; theme++) {
//		if (theme == THEME_J1 && !Special.IsJurassic) {
//			_themes[theme].Available = false;
//		} else {
//			_themes[theme].Available = CCFileClass(Theme_File_Name(theme)).Is_Available();
//		}
//	}
}

