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

/* $Header:   F:\projects\c&c\vcs\code\audio.cpv   2.17   16 Oct 1995 16:50:20   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : AUDIO.CPP                                                    *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : September 10, 1993                                           *
 *                                                                                             *
 *                  Last Update : May 4, 1995 [JLB]                                            *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   Is_Speaking -- Checks to see if the eva voice is still playing.                           *
 *   Sound_Effect -- General purpose sound player.                                             *
 *   Sound_Effect -- Plays a sound effect in the tactical map.                                 *
 *   Speak -- Computer speaks to the player.                                                   *
 *   Speak_AI -- Handles starting the EVA voices.                                              *
 *   Stop_Speaking -- Forces the EVA voice to stop talking.                                    *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"function.h"


/***************************************************************************
**	Controls what special effects may occur on the sound effect.
*/
typedef enum {
	IN_NOVAR,			// No variation or alterations allowed.
	IN_JUV,				// Juvenile sound effect alternate option.
	IN_VAR,				// Infantry variance response modification.
} ContextType;

static struct {
	char const *Name;		// Digitized voice file name.
	int			Priority;	// Playback priority of this sample.
	ContextType	Where;		// In what game context does this sample exist.
} SoundEffectName[VOC_COUNT] = {

	/*
	**	Special voices (typically associated with the commando).
	*/
	{"BOMBIT1",		20, IN_NOVAR},		//	VOC_RAMBO_PRESENT		"I've got a present for	ya"
	{"CMON1",		20, IN_NOVAR},		//	VOC_RAMBO_CMON			"c'mon"
	{"GOTIT1",		20, IN_NOVAR},		//	VOC_RAMBO_UGOTIT		"you got it" *
	{"KEEPEM1",		20, IN_NOVAR},		//	VOC_RAMBO_COMIN		"keep 'em commin'"
	{"LAUGH1",		20, IN_NOVAR},		//	VOC_RAMBO_LAUGH		"hahaha"
	{"LEFTY1",		20, IN_NOVAR},		//	VOC_RAMBO_LEFTY		"that was left handed" *
	{"NOPRBLM1",	20, IN_NOVAR},		//	VOC_RAMBO_NOPROB		"no problem"
//	{"OHSH1",		20, IN_NOVAR},		//	VOC_RAMBO_OHSH			"oh shiiiiii...."
	{"ONIT1",		20, IN_NOVAR},		//	VOC_RAMBO_ONIT			"I'm on it"
	{"RAMYELL1",	20, IN_NOVAR},		//	VOC_RAMBO_YELL			"ahhhhhhh"
	{"ROKROLL1",	20, IN_NOVAR},		//	VOC_RAMBO_ROCK			"time to rock and roll"
	{"TUFFGUY1",	20, IN_NOVAR},		//	VOC_RAMBO_TUFF			"real tuff guy" *
	{"YEAH1",		20, IN_NOVAR},		//	VOC_RAMBO_YEA			"yea" *
	{"YES1",			20, IN_NOVAR},		//	VOC_RAMBO_YES			"yes" *
	{"YO1",			20, IN_NOVAR},		//	VOC_RAMBO_YO			"yo"

	/*
	**	Civilian voices (technicians too).
	*/
	{"GIRLOKAY",	20, IN_NOVAR},		//	VOC_GIRL_OKAY
	{"GIRLYEAH",	20, IN_NOVAR},		//	VOC_GIRL_YEAH
	{"GUYOKAY1",	20, IN_NOVAR},		//	VOC_GUY_OKAY
	{"GUYYEAH1",	20, IN_NOVAR},		//	VOC_GUY_YEAH

	/*
	**	Infantry and vehicle responses.
	*/
	{"2DANGR1",		10,	IN_VAR},	//	VOC_2DANGER			"negative, too dangerous"
	{"ACKNO",		10,	IN_VAR},	//	VOC_ACKNOWL			"acknowledged"
	{"AFFIRM1",		10,	IN_VAR},	//	VOC_AFFIRM			"affirmative"
	{"AWAIT1",		10,	IN_VAR},	//	VOC_AWAIT1			"awaiting orders"
//	{"BACKUP",		10,	IN_VAR},	// VOC_BACKUP			"send backup"
//	{"HELP",			10,	IN_VAR},	// VOC_HELP				"send help"
	{"MOVOUT1",		10,	IN_VAR},	//	VOC_MOVEOUT			"movin' out"
	{"NEGATV1",		10,	IN_VAR},	//	VOC_NEGATIVE		"negative"
	{"NOPROB",		10,	IN_VAR},	// VOC_NO_PROB			"not a problem"
	{"READY",		10,	IN_VAR},	// VOC_READY			"ready and waiting"
	{"REPORT1",		10,	IN_VAR},	//	VOC_REPORT			"reporting"
	// Nyerguds's TUC Quick Fix Patch v1.02: ritaway
	{"RITAWAY",		10,	IN_VAR},	// VOC_RIGHT_AWAY		"right away sir"
	{"ROGER",		10,	IN_VAR},	// VOC_ROGER			"roger"
//	{"SIR1",			10,	IN_VAR},	//	VOC_SIR1				"sir?"
//	{"SQUAD1",		10,	IN_VAR},	//	VOC_SQUAD1			"squad reporting"
//	{"TARGET1",		10,	IN_VAR},	//	VOC_PRACTICE		"target practice"
	{"OVEROUT",		10,	IN_VAR},	// VOC_OVEROUT			"Over and out"
	{"UGOTIT",		10,	IN_VAR},	// VOC_UGOTIT			"you got it"
	{"UNIT1",		10,	IN_VAR},	//	VOC_UNIT1			"unit reporting"
	{"VEHIC1",		10,	IN_VAR},	//	VOC_VEHIC1			"vehicle reporting"
	{"YESSIR1",		10,	IN_VAR},	//	VOC_YESSIR			"yes sir"

	/*
	**	Sound effects that have a juvenile counterpart.
	*/
	{"BAZOOK1", 	1,		IN_JUV},	// VOC_BAZOOKA			Gunfire
	{"BLEEP2", 		1,		IN_JUV},	// VOC_BLEEP			Clean metal bing
	{"BOMB1", 		1,		IN_JUV},	// VOC_BOMB1			Crunchy parachute bomb type explosion
	{"BUTTON", 		1,		IN_JUV},	// VOC_BUTTON			Dungeon Master button click
	{"COMCNTR1",	10,	IN_JUV},	// VOC_RADAR_ON		Elecronic static with beeps
	{"CONSTRU2",	10,	IN_JUV},	// VOC_CONSTRUCTION	construction sounds
	{"CRUMBLE", 	1,		IN_JUV},	// VOC_CRUMBLE			muffled crumble sound
	{"FLAMER2", 	4,		IN_JUV},	// VOC_FLAMER1			flame thrower
	{"GUN18",		4, 	IN_JUV},	// VOC_RIFLE			rifle shot
	{"GUN19",		4, 	IN_JUV},	// VOC_M60				machine gun burst -- 6 rounds
	{"GUN20",		4, 	IN_JUV},	// VOC_GUN20			bat hitting heavy metal door
	{"GUN5",			4, 	IN_JUV},	// VOC_M60A				medium machine gun burst
	{"GUN8",			4, 	IN_JUV},	// VOC_MINI				mini gun burst
	{"GUNCLIP1",	1, 	IN_JUV},	// VOC_RELOAD			gun clip reload
	{"HVYDOOR1", 	5,		IN_JUV},	// VOC_SLAM				metal plates slamming together
	{"HVYGUN10",	1,		IN_JUV},	//	VOC_HVYGUN10		loud sharp cannon
	{"ION1", 		1,		IN_JUV},	// VOC_ION_CANNON		partical beam
	{"MGUN11", 		1,		IN_JUV},	// VOC_MGUN11			alternate tripple burst
	{"MGUN2", 		1,		IN_JUV},	// VOC_MGUN2			M-16 tripple burst
	{"NUKEMISL",	1,		IN_JUV},	//	VOC_NUKE_FIRE		long missile sound
	{"NUKEXPLO",	1,		IN_JUV},	//	VOC_NUKE_EXPLODE	long but not loud explosion
	{"OBELRAY1",	1,		IN_JUV},	//	VOC_LASER			humming star wars laser beam
	{"OBELPOWR",	1,		IN_JUV},	// VOC_LASER_POWER	warming-up sound of star wars laser beam
	{"POWRDN1",		1,		IN_JUV},	//	VOC_RADAR_OFF		doom door slide
	{"RAMGUN2",		1,		IN_JUV},	//	VOC_SNIPER			silenced rifle fire
	{"ROCKET1",		1,		IN_JUV},	//	VOC_ROCKET1			rocket launch variation #1
	{"ROCKET2",		1,		IN_JUV},	//	VOC_ROCKET2			rocket launch variation #2
	{"SAMMOTR2",	1, 	IN_JUV},	// VOC_MOTOR			dentists drill
	{"SCOLD2",		1, 	IN_JUV},	// VOC_SCOLD			cannot perform action feedback tone
	{"SIDBAR1C", 	1,		IN_JUV},	// VOC_SIDEBAR_OPEN	xylophone clink
	{"SIDBAR2C", 	1,		IN_JUV},	// VOC_SIDEBAR_CLOSE	xylophone clink
	{"SQUISH2", 	1,		IN_JUV},	// VOC_SQUISH2			crushing infantry
	{"TNKFIRE2",	1, 	IN_JUV},	// VOC_TANK1			sharp tank fire with recoil
	{"TNKFIRE3",	1, 	IN_JUV},	// VOC_TANK2			sharp tank fire
	{"TNKFIRE4",	1, 	IN_JUV},	// VOC_TANK3			sharp tank fire
	{"TNKFIRE6",	1, 	IN_JUV},	// VOC_TANK4			big gun tank fire
	{"TONE15",		0, 	IN_JUV},	// VOC_UP				credits counting up
	{"TONE16",		0, 	IN_JUV},	// VOC_DOWN				credits counting down
	{"TONE2",		1, 	IN_JUV},	// VOC_TARGET			target sound
	{"TONE5",		10,	IN_JUV},	// VOC_SONAR			sonar echo
	// Nyerguds's TUC Quick Fix Patch v1.02: grenadesound
	{"TOSS1",			1, 	IN_JUV},	// VOC_TOSS				air swish
	{"TRANS1",		1, 	IN_JUV},	// VOC_CLOAK			stealth tank
	{"TREEBRN1",	1, 	IN_JUV},	// VOC_BURN				burning crackle
	{"TURRFIR5",	1, 	IN_JUV},	// VOC_TURRET			muffled gunfire
	{"XPLOBIG4",	5,		IN_JUV},	//	VOC_XPLOBIG4		very long muffled explosion
	{"XPLOBIG6",	5,		IN_JUV},	//	VOC_XPLOBIG6		very long muffled explosion
	{"XPLOBIG7",	5,		IN_JUV},	//	VOC_XPLOBIG7		very long muffled explosion
	{"XPLODE",		1,		IN_JUV},	// VOC_XPLODE			long soft muffled explosion
	{"XPLOS",		4, 	IN_JUV},	// VOC_XPLOS			short crunchy explosion
	{"XPLOSML2",	5,		IN_JUV},	//	VOC_XPLOSML2		muffled mechanical explosion

	/*
	**	Generic sound effects (no variations).
	*/
	{"NUYELL1", 	10,	IN_NOVAR},	// VOC_SCREAM1			short infantry scream
	{"NUYELL3", 	10,	IN_NOVAR},	// VOC_SCREAM3			short infantry scream
	{"NUYELL4", 	10,	IN_NOVAR},	// VOC_SCREAM4			short infantry scream
	{"NUYELL5", 	10,	IN_NOVAR},	// VOC_SCREAM5			short infantry scream
	{"NUYELL6", 	10,	IN_NOVAR},	// VOC_SCREAM6			short infantry scream
	{"NUYELL7", 	10,	IN_NOVAR},	// VOC_SCREAM7			short infantry scream
	{"NUYELL10", 	10,	IN_NOVAR},	// VOC_SCREAM10		short infantry scream
	{"NUYELL11", 	10,	IN_NOVAR},	// VOC_SCREAM11		short infantry scream
	{"NUYELL12", 	10,	IN_NOVAR},	// VOC_SCREAM12		short infantry scream
	{"YELL1", 		1,		IN_NOVAR},	// VOC_YELL1			long infantry scream

	{"MYES1", 		10,	IN_NOVAR},	// VOC_YES				"Yes?"
	{"MCOMND1", 	10,	IN_NOVAR},	// VOC_COMMANDER		"Commander?"
	{"MHELLO1", 	10,	IN_NOVAR},	//	VOC_HELLO			"Hello?"
	{"MHMMM1", 		10,	IN_NOVAR},	//	VOC_HMMM				"Hmmm?"
//	{"MHASTE1", 	10,	IN_NOVAR},	//	VOC_PROCEED1		"I will proceed, post haste."
//	{"MONCE1", 		10,	IN_NOVAR},	//	VOC_PROCEED2		"I will proceed, at once."
//	{"MIMMD1", 		10,	IN_NOVAR},	//	VOC_PROCEED3		"I will proceed, immediately."
//	{"MPLAN1", 		10,	IN_NOVAR},	//	VOC_EXCELLENT1		"That is an excellent plan."
//	{"MPLAN2", 		10,	IN_NOVAR},	//	VOC_EXCELLENT2		"Yes, that is an excellent plan."
	{"MPLAN3", 		10,	IN_NOVAR},	//	VOC_EXCELLENT3		"A wonderful plan."
//	{"MACTION1", 	10,	IN_NOVAR},	//	VOC_EXCELLENT4		"Astounding plan of action commander."
//	{"MREMARK1", 	10,	IN_NOVAR},	// VOC_EXCELLENT5		"Remarkable contrivance."
	{"MCOURSE1", 	10,	IN_NOVAR},	// VOC_OF_COURSE		"Of course."
	{"MYESYES1", 	10,	IN_NOVAR},	// VOC_YESYES			"Yes yes yes."
	{"MTIBER1", 	10,	IN_NOVAR},	//	VOC_QUIP1			"Mind the Tiberium."
	{"MMG1", 		10,	IN_NOVAR},	//	VOC_QUIP2			"A most remarkable Metasequoia Glyptostroboides."
	{"MTHANKS1", 	10,	IN_NOVAR},	//	VOC_THANKS			"Thank you."

	{"CASHTURN", 	1,		IN_NOVAR},	//	VOC_CASHTURN		Sound of money being piled up.
// Nyerguds's C&C Patch Project v1.04: BLEEP2 has a .juv variant.
	{"BLEEP2", 		10,	IN_JUV},	//	VOC_BLEEPY3			Clean computer bleep sound.
	{"DINOMOUT", 	10,	IN_NOVAR},	//	VOC_DINOMOUT		Movin' out in dino-speak.
	{"DINOYES", 	10,	IN_NOVAR},	//	VOC_DINOYES			Yes Sir in dino-speak.
	{"DINOATK1", 	10,	IN_NOVAR},	//	VOC_DINOATK1		Dino attack sound.
	{"DINODIE1", 	10,	IN_NOVAR},	//	VOC_DINODIE1		Dino die sound.
};


/***********************************************************************************************
 * Sound_Effect -- Plays a sound effect in the tactical map.                                   *
 *                                                                                             *
 *    This routine is used when a sound effect occurs in the game world. It handles fading     *
 *    the sound according to distance.                                                         *
 *                                                                                             *
 * INPUT:   voc   -- The sound effect number to play.                                          *
 *                                                                                             *
 *          coord -- The world location that the sound originates from.                        *
 *                                                                                             *
 * OUTPUT:  false if the sample was not played due to not finding the file.                    *
 *          Any other reasons still return true.                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   11/12/1994 JLB : Created.                                                                 *
 *   01/05/1995 JLB : Reduces sound more dramatically when off screen.                         *
 *=============================================================================================*/
bool Sound_Effect(VocType voc, COORDINATE coord, int variation)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool Sound_Effect(VocType voc, COORDINATE coord, int variation)");
#endif
	unsigned			distance;
	CELL				cell_pos;
	int pan_value;

	if (!Options.Volume || voc == VOC_NONE || !SoundOn || SampleType == SAMPLE_NONE) {
		return(true);
	}
	if (coord) {
		cell_pos = Coord_Cell(coord);
	}

	distance  = 0xFF;
	pan_value = 0;
	if (coord && !Map.In_View(cell_pos)) {
		// Nyerguds's C&C Patch Project v1.04: fadeout now depends on distance outside viewport.
		long lepx1 = MAX(0, Coord_X(Map.TacticalCoord));
		long lepx2 = MIN((long)MAP_CELL_W * CELL_LEPTON_W, (long)lepx1 + Map.TacLeptonWidth);
		long lepy1 = MAX(0, Coord_Y(Map.TacticalCoord));
		long lepy2 = MIN((long)MAP_CELL_H * CELL_LEPTON_H, (long)lepy1 + Map.TacLeptonHeight);
		long coordx = Coord_X(coord);
		long coordy = Coord_Y(coord);

		long dx = 0;
		long dy = 0;

		if (coordx < lepx1)
			dx = lepx1 - coordx;
		else if (coordx > lepx2)
			dx = coordx - lepx2;

		if (coordy < lepy1)
			dy = lepy1 - coordy;
		else if (coordy > lepy2)
			dy = coordy - lepy2;

		distance = Distance(0, 0, dx, dy) / CELL_LEPTON_W;

		// Immediately outside the viewport, drop to offscreen volume.
		// Then fade from that volume down to the 32/256 minimum over 32 cells.
		const unsigned OFFSCREEN_VOLUME = 192; // 75%
		const unsigned MIN_VOLUME = 25;
		const unsigned FADE_DISTANCE = 32;
		if (distance >= FADE_DISTANCE) {
			distance = MIN_VOLUME;
		} else {
			distance = OFFSCREEN_VOLUME	- (distance * (OFFSCREEN_VOLUME - MIN_VOLUME) / FADE_DISTANCE);
		}
#ifdef OBSOLETE_NYERPATCH
		distance = Map.Cell_Distance(cell_pos, Coord_Cell(Map.TacticalCoord));
		distance = (unsigned int)MIN((int)distance, (int)MAP_CELL_W);
		distance = Cardinal_To_Fixed(MAP_CELL_W, distance);
		distance = MIN(distance, 0xFFu);
		distance ^= 0xFF;

		distance /= 2;
		distance = MAX(distance, 25);
#endif
		pan_value  = Cell_X(cell_pos);
		pan_value -= Coord_XCell(Map.TacticalCoord) + (Lepton_To_Cell(Map.TacLeptonWidth) >> 1);
		if (ABS(pan_value) > Lepton_To_Cell(Map.TacLeptonWidth >> 1)) {
			pan_value *= 0x8000;
			pan_value /= (MAP_CELL_W >> 2);
			pan_value = Bound(pan_value, -0x7FFF, 0x7FFF);
//			pan_value  = MAX((int)pan_value, (int)-0x7FFF);
//			pan_value  = MIN((int)pan_value, 0x7FFF);
		} else {
			pan_value  = 0;
		}
	}

	return Sound_Effect(voc, (VolType)Fixed_To_Cardinal(distance, Options.Volume), variation, pan_value) != -1;
}


/***********************************************************************************************
 * Sound_Effect -- General purpose sound player.                                               *
 *                                                                                             *
 *    This is used for general purpose sound effects. These are sounds that occur outside      *
 *    of the game world. They do not have a corresponding game world location as their source. *
 *                                                                                             *
 * INPUT:   voc      -- The sound effect number to play.                                       *
 *                                                                                             *
 *          volume   -- The volume to assign to this sound effect.                             *
 *                                                                                             *
 * OUTPUT:  Returns with the sound handle (-1 if no sound was played).                         *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   11/12/1994 JLB : Created.                                                                 *
 *   11/12/1994 JLB : Handles cache logic.                                                     *
 *   05/04/1995 JLB : Variation adjustments.                                                   *
 *=============================================================================================*/
int Sound_Effect(VocType voc, VolType volume, int variation, signed short pan_value)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("int Sound_Effect(VocType voc, VolType volume, int variation, signed short pan_value)");
#endif
	char name[_MAX_FNAME+_MAX_EXT];				// Working filename of sound effect.

	if (!Options.Volume || voc == VOC_NONE || !SoundOn || SampleType == SAMPLE_NONE) {
		return(-1);
	}

	/*
	**	Fetch a pointer to the sound effect data. Modify the sound as appropriate and desired.
	*/
	char const * ext = ".AUD";
	if (Special.IsJuvenile && SoundEffectName[voc].Where == IN_JUV) {
		ext = ".JUV";
	} else {
		if (SoundEffectName[voc].Where == IN_VAR) {

			/*
			**	For infantry, use a variation on the response. For vehicles, always
			**	use the vehicle response table.
			*/
			if (variation < 0) {
				if (ABS(variation) % 2) {
					ext = ".V00";
				} else {
					ext = ".V02";
				}
			} else {
				if (variation % 2) {
					ext = ".V01";
				} else {
					ext = ".V03";
				}
			}
		}
	}
	_makepath(name, NULL, NULL, SoundEffectName[voc].Name, ext);
	void const * ptr = MixFileClass::Retrieve(name);

	/*
	**	If the sound data pointer is not null, then presume that it is valid.
	*/
	if (ptr) {
		return(Play_Sample(ptr, Fixed_To_Cardinal(SoundEffectName[voc].Priority, (int)volume), (int)volume, pan_value));
	}
	return(-1);
}


/*
**	This elaborates all the EVA speech voices.
*/
char const * Speech[VOX_COUNT] =  {
	"ACCOM1",		//	VOX_ACCOMPLISHED - mission accomplished
	"FAIL1",			//	VOX_FAIL - your mission has failed
	"BLDG1",			//	VOX_NO_FACTORY - unable to comply, building in progress
	"CONSTRU1",		//	VOX_CONSTRUCTION - construction complete
	"UNITREDY",		//	VOX_UNIT_READY - unit ready
	"NEWOPT1",		//	VOX_NEW_CONSTRUCT - new construction options
	"DEPLOY1",		//	VOX_DEPLOY - cannot deploy here
	"GDIDEAD1",		//	VOX_DEAD_GDI - GDI unit destroyed
	"NODDEAD1",		//	VOX_DEAD_NOD - Nod unit destroyed
	"CIVDEAD1",		//	VOX_DEAD_CIV - civilian killed
//	"EVAYES1",		//	VOX_AFFIRMATIVE - affirmative
//	"EVANO1",		//	VOX_NEGATIVE - negative
//	"UPUNIT1",		//	VOX_UPGRADE_UNIT - upgrade complete, new unit available
//	"UPSTRUC1",		//	VOX_UPGRADE_STRUCT - upgrade complete, new structure available
	"NOCASH1",		//	VOX_NO_CASH - insufficient funds
	"BATLCON1",		//	VOX_CONTROL_EXIT - battle control terminated
	"REINFOR1",		//	VOX_REINFORCEMENTS - reinforcements have arrived
	"CANCEL1",		//	VOX_CANCELED - canceled
	"BLDGING1",		//	VOX_BUILDING - building
	"LOPOWER1",		//	VOX_LOW_POWER - low power
	"NOPOWER1",		//	VOX_NO_POWER - insufficient power
	"MOCASH1",		//	VOX_NEED_MO_MONEY - need more funds
	"BASEATK1",		//	VOX_BASE_UNDER_ATTACK - our base is under attack
	"INCOME1",		//	VOX_INCOMING_MISSILE - incoming missile
	"ENEMYA",		//	VOX_ENEMY_PLANES - enemy planes approaching
	"NUKE1",			//	VOX_INCOMING_NUKE - nuclear warhead approaching
//	"RADOK1",		//	VOX_RADIATION_OK - radiation levels are acceptable
//	"RADFATL1",		//	VOX_RADIATION_FATAL - radiation levels are fatal
	"NOBUILD1",		//	VOX_UNABLE_TO_BUILD - unable to build more
	"PRIBLDG1",		//	VOX_PRIMARY_SELECTED - primary building selected
//	"REPDONE1",		//	VOX_REPAIRS_COMPLETE - repairs completed
	"NODCAPT1",		//	VOX_NOD_CAPTURED - Nod building captured
	"GDICAPT1",		//	VOX_GDI_CAPTURED - GDI building captured
//	"SOLD1",			//	VOX_STRUCTURE_SOLD - structure sold
	"IONCHRG1",		//	VOX_ION_CHARGING - ion cannon charging
	"IONREDY1",		//	VOX_ION_READY - ion cannon ready
	"NUKAVAIL",		//	VOX_NUKE_AVAILABLE - nuclear weapon available
	"NUKLNCH1",		//	VOX_NUKE_LAUNCHED - nuclear weapon launched
	"UNITLOST",		// VOX_UNIT_LOST - unit lost
	"STRCLOST",		// VOX_STRUCTURE_LOST - structure lost
	"NEEDHARV",		//	VOX_NEED_HARVESTER - need harvester
	"SELECT1",		// VOX_SELECT_TARGET - select target
	"AIRREDY1",		// VOX_AIRSTRIKE_READY - airstrike ready
	"NOREDY1",		//	VOX_NOT_READY - not ready
	"TRANSSEE",		// VOX_TRANSPORT_SIGHTED - Nod transport sighted
	"TRANLOAD",		// VOX_TRANSPORT_LOADED - Nod transport loaded
	"ENMYAPP1",		//	VOX_PREPARE - enemy approaching
	"SILOS1",		//	VOX_NEED_MO_CAPACITY - silos needed
	"ONHOLD1",		//	VOX_SUSPENDED - on hold
	"REPAIR1",		//	VOX_REPAIRING - repairing
	"ESTRUCX",		//	VOX_ENEMY_STRUCTURE - enemy structure destroyed
	"GSTRUC1",		//	VOX_GDI_STRUCTURE - GDI structure destroyed
	"NSTRUC1",		//	VOX_NOD_STRUCTURE - NOD structure destroyed
	"ENMYUNIT",		// VOX_ENEMY_UNIT - Enemy unit destroyed
//	"GUKILL1",		//	VOX_GOLD_UNIT - gold unit destroyed
//	"GSTRUD1",		//	VOX_GOLD_STRUCTURE - gold structure destroyed
//	"GONLINE1",		//	VOX_GOLD_ONLINE - gold player online
//	"GLEFT1",		//	VOX_GOLD_OFFLINE - gold player has departed
//	"GOLDKILT",		//	VOX_GOLD_LOST - gold player destroyed
//	"GOLDWIN",		//	VOX_GOLD_WON - gold player is victorious
//	"RUKILL1",		//	VOX_RED_UNIT - red unit destroyed
//	"RSTRUD1",		//	VOX_RED_STRUCTURE - red structure destroyed
//	"RONLINE1",		//	VOX_RED_ONLINE - red player online
//	"RLEFT1",		//	VOX_RED_OFFLINE - red player has departed
//	"REDKILT",		//	VOX_RED_LOST - red player destroyed
//	"REDWIN",		//	VOX_RED_WON - red player is victorious
//	"GYUKILL1",		//	VOX_GREY_UNIT - grey unit destroyed
//	"GYSTRUD1",		//	VOX_GREY_STRUCTURE - grey structure destroyed
//	"GYONLINE",		//	VOX_GREY_ONLINE - grey player online
//	"GYLEFT1",		//	VOX_GREY_OFFLINE - grey player has departed
//	"GREYKILT",		//	VOX_GREY_LOST - grey player destroyed
//	"GREYWIN",		//	VOX_GREY_WON - grey player is victorious
//	"OUKILL1",		//	VOX_ORANGE_UNIT - orange unit destroyed
//	"OSTRUD1",		//	VOX_ORANGE_STRUCTURE - orange structure destroyed
//	"OONLINE1",		//	VOX_ORANGE_ONLINE - orange player online
//	"OLEFT1",		//	VOX_ORANGE_OFFLINE - orange player has departed
//	"ORANKILT",		//	VOX_ORANGE_LOST - orange player destroyed
//	"ORANWIN",		//	VOX_ORANGE_WON - orange player is victorious
//	"GNUKILL1",		//	VOX_GREEN_UNIT - green unit destroyed
//	"GNSTRUD1",		//	VOX_GREEN_STRUCTURE - green structure destroyed
//	"GNONLINE",		//	VOX_GREEN_ONLINE - green player online
//	"GNLEFT1",		//	VOX_GREEN_OFFLINE - green player has departed
//	"GRENKILT",		//	VOX_GREEN_LOST - green player destroyed
//	"GRENWIN",		//	VOX_GREEN_WON - green player is victorious
//	"BUKILL1",		//	VOX_BLUE_UNIT - blue unit destroyed
//	"BSTRUD1",		//	VOX_BLUE_STRUCTURE - blue structure destroyed
//	"BONLINE1",		//	VOX_BLUE_ONLINE - blue player online
//	"BLEFT1",		//	VOX_BLUE_OFFLINE - blue player has departed
//	"BLUEKILT",		//	VOX_BLUE_LOST - blue player destroyed
//	"BLUEWIN"		//	VOX_BLUE_WON - blue player is victorious
};
static VoxType CurrentVoice = VOX_NONE;


/***********************************************************************************************
 * Speak -- Computer speaks to the player.                                                     *
 *                                                                                             *
 *    This routine is used to have the game computer (EVA) speak to the player.                *
 *                                                                                             *
 * INPUT:   voice -- The voice number to speak (see defines.h).                                *
 *                                                                                             *
 * OUTPUT:  Returns with the handle of the playing speech (-1 if no voice started).            *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   11/12/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void Speak(VoxType voice)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void Speak(VoxType voice)");
#endif
	if (Options.Volume && SampleType != 0 && voice != VOX_NONE && voice != SpeakQueue && voice != CurrentVoice && SpeakQueue == VOX_NONE) {
		SpeakQueue = voice;
	}
}


/***********************************************************************************************
 * Speak_AI -- Handles starting the EVA voices.                                                *
 *                                                                                             *
 *    This starts the EVA voice talking as well. If there is any speech request in the queue,  *
 *    it will be started when the current voice is finished. Call this routine as often as     *
 *    possible (once per game tick is sufficient).                                             *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/27/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void Speak_AI(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void Speak_AI(void)");
#endif
	static VoxType _last = VOX_NONE;
	if (SampleType == 0) return;

	if (!Is_Sample_Playing(SpeechBuffer)) {
		CurrentVoice = VOX_NONE;
		if (SpeakQueue != VOX_NONE) {
			if (SpeakQueue != _last) {
				char name[_MAX_FNAME+_MAX_EXT];

				_makepath(name, NULL, NULL, Speech[SpeakQueue], ".AUD");
				if (CCFileClass(name).Read(SpeechBuffer, SPEECH_BUFFER_SIZE)) {
					Play_Sample(SpeechBuffer, 254, Options.Volume);
				}
				_last = SpeakQueue;
			} else {
				Play_Sample(SpeechBuffer, 254, Options.Volume);
			}
			SpeakQueue = VOX_NONE;
		}
	}
}


/***********************************************************************************************
 * Stop_Speaking -- Forces the EVA voice to stop talking.                                      *
 *                                                                                             *
 *    Use this routine to immediately stop the EVA voice from speaking. It also clears out     *
 *    the pending voice queue.                                                                 *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/27/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void Stop_Speaking(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void Stop_Speaking(void)");
#endif
	SpeakQueue = VOX_NONE;
	if (SampleType != 0) {
		Stop_Sample_Playing(SpeechBuffer);
	}
}


/***********************************************************************************************
 * Is_Speaking -- Checks to see if the eva voice is still playing.                             *
 *                                                                                             *
 *    Call this routine when the EVA voice being played needs to be checked. A typical use     *
 *    of this would be when some action needs to be delayed until the voice has finished --    *
 *    say the end of the game.                                                                 *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  bool; Is the EVA voice still playing?                                              *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/12/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
bool Is_Speaking(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool Is_Speaking(void)");
#endif
	Speak_AI();
	if (SampleType != 0 && (SpeakQueue != VOX_NONE || Is_Sample_Playing(SpeechBuffer))) {
		return(true);
	}
	return(false);
}
