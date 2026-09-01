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

/* $Header:   F:\projects\c&c\vcs\code\terrain.cpv   2.16   16 Oct 1995 16:51:44   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : TERRAIN.CPP                                                  *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : April 29, 1994                                               *
 *                                                                                             *
 *                  Last Update : May 8, 1995 [JLB]                                            *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   TerrainClass::AI -- Process the terrain object AI.                                        *
 *   TerrainClass::As_Target -- Converts the terrain object into a target number.              *
 *   TerrainClass::Can_Enter_Cell -- Determines if the terrain object can exist in the cell.   *
 *   TerrainClass::Catch_Fire -- Catches the terrain object on fire.                           *
 *   TerrainClass::Center_Coord -- Fetches the center point coordinate for terrain object.     *
 *   TerrainClass::Debug_Dump -- Displays the status of the terrain object.                    *
 *   TerrainClass::Draw_It -- Renders the terrain object at the location specified.            *
 *   TerrainClass::Fire_Out -- Handles when fire has gone out.                                 *
 *   TerrainClass::Heath_Ratio -- Determines the health ratio for the terrain object.          *
 *   TerrainClass::Init -- Initialize the terrain object tracking system.                      *
 *   TerrainClass::Limbo -- Handles terrain specific limbo action.                             *
 *   TerrainClass::Mark -- Marks the terrain object on the map.                                *
 *   TerrainClass::Radar_Icon -- Fetches pointer to radar icon to use.                         *
 *   TerrainClass::Read_INI -- Reads terrain objects from INI file.                            *
 *   TerrainClass::Start_To_Crumble -- Initiates crumbling of terrain (tree) object.           *
 *   TerrainClass::Take_Damage -- Damages the terrain object as specified.                     *
 *   TerrainClass::TerrainClass -- Constructor for a terrain class object.                     *
 *   TerrainClass::TerrainClass -- This is the constructor for a terrain object.               *
 *   TerrainClass::Unlimbo -- Unlimbo terrain object onto the map.                             *
 *   TerrainClass::Write_INI -- Writes all terrain objects to the INI file.                    *
 *   TerrainClass::delete -- Deletes a terrain object.                                         *
 *   TerrainClass::new -- Creates a new terrain object.                                        *
 *   TerrainClass::~TerrainClass -- Default destructor for terrain class objects.              *
 *   TerrainClass::Validate -- validates terrain pointer                                       *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"function.h"
#include	"terrain.h"

#define	BARNACLE_STAGE			22
#define	FIRST_SPORE_STAGE		30
#define	FIRST_SPORABLE_LEVEL	7

/*
** This contains the value of the Virtual Function Table Pointer
*/
void * TerrainClass::VTable;


/***********************************************************************************************
 * TerrainClass::Validate -- validates terrain pointer                                         *
 *                                                                                             *
 * INPUT:                                                                                      *
 *    none.                                                                                    *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *    1 = ok, 0 = error                                                                        *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *    none.                                                                                    *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/09/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
#ifdef CHEAT_KEYS
int TerrainClass::Validate(void) const
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("int TerrainClass::Validate(void) const");
#endif
	int num;

	num = Terrains.ID(this);
	if (num < 0 || num >= TERRAIN_MAX) {
		Validate_Error("TERRAIN");
		return (0);
	}
	else
		return (1);
}
#else
#define	Validate()
#endif


/***********************************************************************************************
 * TerrainClass::~TerrainClass -- Default destructor for terrain class objects.                *
 *                                                                                             *
 *    This is the default destructor for terrain objects. It will remove the object from the   *
 *    map and tracking systems, but only if the game is running. Otherwise, it does nothing.   *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/23/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
TerrainClass::~TerrainClass(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("TerrainClass::~TerrainClass(void)");
#endif
	if (GameActive && Class) {
		TerrainClass::Limbo();
	}
}


/***********************************************************************************************
 * TerrainClass::Take_Damage -- Damages the terrain object as specified.                       *
 *                                                                                             *
 *    This routine is called when damage is to be inflicted upon the terrain object. It is     *
 *    through this routine that terrain objects are attacked and thereby destroyed. Not all    *
 *    terrain objects can be damaged by this routine however.                                  *
 *                                                                                             *
 * INPUT:   damage   -- Amount of damage to inflict.                                           *
 *                      This value will be adjusted to the actual taken damage.                *
 *                                                                                             *
 *          distance -- The distance from the damage center point to the object's center point.*
 *                                                                                             *
 *          warhead  -- The warhead type that the damage occurs from.                          *
 *                                                                                             *
 *          source   -- The source of the damage. This is used to change targeting.            *
 *                                                                                             *
 *          house    -- Source of the damage if no techno is available to blame.               *
 *                                                                                             *
 *          fromburn -- The damage is a result of an animation burning the object.             *
 *                                                                                             *
 * OUTPUT:  Returns the ResultType that indicates what the effect of the damage was.           *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/24/1994 JLB : Created.                                                                 *
 *   11/22/1994 JLB : Shares base damage handler for techno objects.                           *
 *   12/11/1994 JLB : Shortens attached burning animations.                                    *
 *=============================================================================================*/
ResultType TerrainClass::Take_Damage(int & damage, int distance, WarheadType warhead, TechnoClass * source, HousesType house, bool fromburn)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("ResultType TerrainClass::Take_Damage(int & damage, int distance, WarheadType warhead, TechnoClass * source, HousesType house, bool fromburn)");
#endif
	Validate();
	ResultType res = RESULT_NONE;

	/*
	**	Small arms can never destroy a terrain element.
	*/
	// Nyerguds's C&C Patch Project v1.04: Trees can still be damaged while on fire.
	if (!IsCrumbling && warhead != WARHEAD_SA && !Class->IsImmune) {

		// Nyerguds's C&C Patch Project v1.04: Remember IsOnFire status before damage is applied.
		// Dying from fire damage makes the fire animations
		// call the Fire_Out() function, so store this now.
		boolean onFire = IsOnFire;

		res = ObjectClass::Take_Damage(damage, distance, warhead, source, house, fromburn);

		if (res == RESULT_DESTROYED) {
			// Nyerguds's C&C Patch Project v1.04: Fix burnt trees not crubling.

			// This was all vastly simplified. Detach_All() is already called in
			// ObjectClass::Take_Damage(), which kills off all attached anims, too.
			// Start_To_Crumble() checks if it's already crumbling, so just run it.
			Start_To_Crumble();

			// Nyerguds's C&C Patch Project v1.04: Add smoke when dying from burn.
			// Migrated from Fire_Out(). If it died while burning, add smoke.
			if (warhead == WARHEAD_FIRE || fromburn || onFire) {
				new AnimClass(ANIM_SMOKE_M, Coord_Add(Coord, Class->CenterBase));
			}
		} else if (damage && warhead == WARHEAD_FIRE && !fromburn) {
			// Nyerguds's C&C Patch Project v1.04: Only catch on fire when damage is not from anims.
			// -Fire on trees won't self-propagate.
			// -Don't set it on fire if it's destroyed.
			Catch_Fire(source, house);
		}
	}
	return(res);
}


/***********************************************************************************************
 * TerrainClass::As_Target -- Converts the terrain object into a target number.                *
 *                                                                                             *
 *    This routine will take the terrain object and generate a unique targeting number. This   *
 *    number is used for the NavCom and TarCom of other units.                                 *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  Returns with the target number of this terrain object.                             *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/24/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
TARGET TerrainClass::As_Target(void) const
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("TARGET TerrainClass::As_Target(void) const");
#endif
	Validate();
	return(Build_Target(KIND_TERRAIN, Terrains.ID(this)));
}


/***********************************************************************************************
 * TerrainClass::new -- Creates a new terrain object.                                          *
 *                                                                                             *
 *    This routine creates a new terrain object by grabbing a free slot                        *
 *    out of the terrain object pool.                                                          *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the terrain object allocated.                            *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/14/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void * TerrainClass::operator new(size_t)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void * TerrainClass::operator new(size_t)");
#endif
	void * ptr = Terrains.Allocate();
	if (ptr) {
		((TerrainClass *)ptr)->IsActive = true;
	}
	return(ptr);
}


/***********************************************************************************************
 * TerrainClass::delete -- Deletes a terrain object.                                           *
 *                                                                                             *
 *    This routine deletes a terrain object by returning it to the                             *
 *    terrain object pool.                                                                     *
 *                                                                                             *
 * INPUT:   ptr   -- Pointer to the terrain object to delete.                                  *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/14/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::operator delete(void *ptr)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::operator delete(void *ptr)");
#endif
	if (ptr) {
		((TerrainClass *)ptr)->IsActive = false;
	}
	Terrains.Free((TerrainClass *)ptr);
}


/***********************************************************************************************
 * TerrainClass::TerrainClass -- This is the constructor for a terrain object                  *
 *                                                                                             *
 *    This constructor for a terrain object will initialize the terrain                        *
 *    object with it's proper type and insert it into the access                               *
 *    tracking system.                                                                         *
 *                                                                                             *
 * INPUT:   type  -- The terrain object type.                                                  *
 *                                                                                             *
 *          cell  -- The location of the terrain object.                                       *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/02/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
TerrainClass::TerrainClass(TerrainType type, CELL cell) :
	Class(&TerrainTypeClass::As_Reference(type))
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("TerrainClass::TerrainClass(TerrainType type, CELL cell)");
#endif
	IsBlossoming = false;
	IsBarnacled = false;
	IsSporing = false;
	IsCrumbling = false;
	IsOnFire = false;
	Strength = Class->MaxStrength;
	if (cell != -1) {
		if (!Unlimbo(Cell_Coord(cell))) {
			delete this;
		}
	}
	Set_Rate(0);	// turn off animation
}


/***********************************************************************************************
 * TerrainClass::Mark -- Marks the terrain object on the map.                                  *
 *                                                                                             *
 *    This routine will mark or remove the terrain object from the map                         *
 *    tracking system. This is typically called when the terrain object                        *
 *    is first created, when it is destroyed, and whenever it needs to be                      *
 *    redrawn.                                                                                 *
 *                                                                                             *
 * INPUT:   mark  -- The marking operation to perform.                                         *
 *                                                                                             *
 * OUTPUT:  bool; Was the terrain object successfully marked?                                  *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/02/1994 JLB : Created.                                                                 *
 *   12/23/1994 JLB : Performs low level legality check before proceeding.                     *
 *=============================================================================================*/
bool TerrainClass::Mark(MarkType mark)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool TerrainClass::Mark(MarkType mark)");
#endif
	Validate();
	if (ObjectClass::Mark(mark)) {
		short const *overlap = Class->Overlap_List();
		short const *occupy = Class->Occupy_List();
		CELL cell = Coord_Cell(Coord);

		switch (mark) {
			case MARK_UP:
				Map.Pick_Up(cell, this);
				break;

			case MARK_DOWN:
				Map.Place_Down(cell, this);
				break;

			default:
				Map.Refresh_Cells(cell, overlap);
				Map.Refresh_Cells(cell, occupy);
				break;
		}
		return(true);
	}
	return(false);
}


/***********************************************************************************************
 * TerrainClass::Draw_It -- Renders the terrain object at the location specified.              *
 *                                                                                             *
 *    This routine is used to render the terrain object at the location specified and          *
 *    clipped to the window specified. This is the gruntwork drawing routine for the           *
 *    terrain objects as they are displayed on the map.                                        *
 *                                                                                             *
 * INPUT:   x,y      -- The coordinate to draw the terrain object at (centered).               *
 *                                                                                             *
 *          window   -- The clipping window to draw to.                                        *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/27/1994 JLB : Created.                                                                 *
 *   11/09/1994 JLB : Changed selected terrain highlight method.                               *
 *=============================================================================================*/
void TerrainClass::Draw_It(int x, int y, WindowNumberType window)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Draw_It(int x, int y, WindowNumberType window)");
#endif
	Validate();
	void const * shapedata;

	shapedata = Class->Get_Image_Data();
	if (shapedata) {
		int	shapenum = 0;

		/*
		**	Determine the animation stage to render the terrain object. If it is crumbling, then
		**	it will display the crumbling animation.
		*/
		if (IsCrumbling || Class->IsTransformable) {
			shapenum = Fetch_Stage()+IsCrumbling;
		} else {
			if (Strength <= 1) {
				shapenum++;
			}
		}

		ShapeFlags_Type flags = SHAPE_NORMAL;
		if (IsSelected && Debug_Map) flags = flags | SHAPE_FADING;

		IsTheaterShape = Class->Image_Is_Theater_Shape();
		CC_Draw_Shape(shapedata, shapenum, x, y, window, flags|SHAPE_WIN_REL|SHAPE_GHOST, Map.FadingLight, Map.UnitShadow);
		IsTheaterShape = false;
	}
}


/***********************************************************************************************
 * TerrainClass::Init -- Initialize the terrain object tracking system.                        *
 *                                                                                             *
 *    This routine will clear out the terrain object system so that no terrain objects will    *
 *    exists. It is called prior to loading or starting a scenario.                            *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/24/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::Init(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Init(void)");
#endif
	TerrainClass *ptr;

	Terrains.Free_All();

	ptr = new TerrainClass();
	VTable = ((void **)(((char *)ptr) + sizeof(AbstractClass) - 4))[0];
	delete ptr;
}


/***********************************************************************************************
 * TerrainClass::Can_Enter_Cell -- Determines if the terrain object can exist in the cell.     *
 *                                                                                             *
 *    This routine will examine the cell specified and determine if the the terrain object     *
 *    can legally exist there.                                                                 *
 *                                                                                             *
 * INPUT:   cell  -- The cell to examine.                                                      *
 *                                                                                             *
 * OUTPUT:  If the terrain object can be placed in the cell specified, then a value less than  *
 *          256 will be returned.                                                              *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/24/1994 JLB : Created.                                                                 *
 *   01/01/1995 JLB : Actually works now.                                                      *
 *=============================================================================================*/
MoveType TerrainClass::Can_Enter_Cell(CELL cell, FacingType) const
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("MoveType TerrainClass::Can_Enter_Cell(CELL cell, FacingType) const");
#endif
	Validate();
	short const	*offset;		// Pointer to cell offset list.

	if ((unsigned)cell >= MAP_CELL_TOTAL) return(MOVE_NO);

	offset = Occupy_List();
	while (*offset != REFRESH_EOL) {
		if (!Map[(CELL)(cell + *offset++)].Is_Generally_Clear()) {
			return(MOVE_NO);
		}
	}
	return(MOVE_OK);
}


/***********************************************************************************************
 * TerrainClass::Catch_Fire -- Catches the terrain object on fire.                             *
 *                                                                                             *
 *    This routine is called if the terrain object is supposed to catch on fire. The routine   *
 *    performs checking to make sure that only flammable terrain objects that aren't already   *
 *    on fire get caught on fire.                                                              *
 *                                                                                             *
 * INPUT:   source   -- The culprit who set it on fire.                                        *
 *                                                                                             *
 *          house    -- Source of the damage if no source is available.                        *
 *                                                                                             *
 * OUTPUT:  bool; Was the terrain object caught on fire by this routine?                       *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/27/1994 JLB : Created.                                                                 *
 *   12/11/1994 JLB : Don't catch fire if already on fire or crumbling.                        *
 *   11/26/2025 MM  : If already on fire, renew fire rather than ignoring it.                  *
 *=============================================================================================*/
bool TerrainClass::Catch_Fire(TechnoClass * source, HousesType house)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool TerrainClass::Catch_Fire(TechnoClass * source, HousesType house)");
#endif
	Validate();
	if (!IsCrumbling && Strength && Class->IsFlammable) {
		bool fireadded = false;
		// Nyerguds's C&C Patch Project v1.04: Fire damage renews existing burn anim.
		// Allow renewing of burn by making previous burns
		// end gracefully and then adding new ones.
		if (IsOnFire) {
			Shorten_Attached_Anims(this, ANIM_BURN_BIG);
			Shorten_Attached_Anims(this, ANIM_BURN_MED);
		}
		AnimClass * anim = new AnimClass(ANIM_BURN_BIG, Coord_Add(Sort_Y(), 0xFFB00000L));
		if (anim) {
			fireadded = true;
			anim->Attach_To(this);
			anim->Set_Payback(source, house);
		}
		anim = new AnimClass(ANIM_BURN_MED, Coord_Add(Sort_Y(), 0xFF200000L), 15);
		if (anim) {
			fireadded = true;
			anim->Attach_To(this);
			anim->Set_Payback(source, house);
		}
		if (fireadded) {
			IsOnFire = true;
		}
		return(fireadded);
	}
	return(false);
}


/***********************************************************************************************
 * TerrainClass::Fire_Out -- Handles when fire has gone out.                                   *
 *                                                                                             *
 *    When the fire has gone out on a burning terrain object, this routine is called. The      *
 *    animation has already been terminated prior to calling this routine. All this routine    *
 *    needs to perform is any necessary local flag updating.                                   *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   This is only called when all DAMAGE-DEALING animations expire.                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/27/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::Fire_Out()
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Fire_Out()");
#endif
	Validate();
	if (IsOnFire) {
		IsOnFire = false;
		// Nyerguds's C&C Patch Project v1.04: Removed crumble logic in Fire_Out().
		// Crumble logic is now handled by Take_Damage(), as it should be.

		// Since this function can now be called from Detach(), Detach_All()
		// should never be called from here since that can cause a stack overflow.
		#ifdef NYERPATCH_OBSOLETE
		if (!IsCrumbling && !Strength) {
			Detach_All();
			Mark();
			Start_To_Crumble();
			new AnimClass(ANIM_SMOKE_M, Coord_Add(Coord, Class->CenterBase));
		}
#endif
	}
}


/***********************************************************************************************
 * TerrainClass::AI -- Process the terrain object AI.                                          *
 *                                                                                             *
 *    This is used to handle any AI processing necessary for terrain objects. This might       *
 *    include animation effects.                                                               *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/27/1994 JLB : Created.                                                                 *
 *   09/28/1994 JLB : Crumbling animation.                                                     *
 *=============================================================================================*/
void TerrainClass::AI(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::AI(void)");
#endif
	Validate();
	ObjectClass::AI();

	if (StageClass::Graphic_Logic()) {
		Mark();

		/*
		**	If the terrain object is in the process of crumbling, then when at the
		**	last stage of the crumbling animation, delete the terrain object.
		*/
		if (IsCrumbling && Fetch_Stage() == Get_Build_Frame_Count(Class->Get_Image_Data())-1) {
			delete this;
			return;
		}
	}

	/*
	** if this is a blossom tree, let's update it at this time
	*/
	if (Class->IsTransformable) {
		// If it's already blossomed, is it at barnacled stage?
		if (IsBlossoming) {
			// if it's not barnacled yet, check if we're at that stage
			if (!IsBarnacled) {
				if (Fetch_Stage() == BARNACLE_STAGE) {
					IsBarnacled = true;
					Set_Rate(0);	// turn off animation
				}
			} else {
				/*
				** If it's barnacled, see if it's pulsing and spore-ing
				*/
				if (IsSporing) {
					if (Fetch_Stage() >= Get_Build_Frame_Count(Class->Get_Image_Data())-1) {
						Explosion_Damage(Sort_Y(), 5, NULL, HOUSE_NONE, WARHEAD_SPORE);
						Set_Stage(FIRST_SPORE_STAGE);
						if (Random() & 1) {
							IsSporing = false;
							StageClass::Set_Rate(0);
						}
					}
				} else {
					if (Random() == 255) {	// is it time to start sporing?
						IsSporing = true;
						StageClass::Set_Rate(Options.Normalize_Delay(1));
					}
				}
			}
		} else {

			// If it hasn't tried to blossom yet, can it do so now?
			if (Random_Picky((int)1, (int)5000, (char*)NULL, (int)0) == 1) {
				IsBlossoming = true;
				StageClass::Set_Stage(1);
				StageClass::Set_Rate(Options.Normalize_Delay(1));
			}
		}
	}
}


#ifdef CHEAT_KEYS
/***********************************************************************************************
 * TerrainClass::Debug_Dump -- Displays the status of the terrain object.                      *
 *                                                                                             *
 *    This debugging support routine is used to display the status of the terrain object to    *
 *    the debug screen.                                                                        *
 *                                                                                             *
 * INPUT:   mono  -- The mono screen to display the status to.                                 *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   09/27/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::Debug_Dump(MonoClass *mono) const
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Debug_Dump(MonoClass *mono) const");
#endif
	Validate();
	ObjectClass::Debug_Dump(mono);
}
#endif


/***********************************************************************************************
 * TerrainClass::Unlimbo -- Unlimbo terrain object onto the map.                               *
 *                                                                                             *
 *    This routine is used to unlimbo the terrain object onto a location on the map. Normal    *
 *    unlimbo procedures are sufficient except that the coordinate location of a terrain       *
 *    object is based on the upper left corner of a cell rather than the center. Mask the      *
 *    coordinate value so that it snaps to the upper left corner and then proceed with a       *
 *    normal unlimbo process.                                                                  *
 *                                                                                             *
 * INPUT:   coord    -- The coordinate to mark as the terrain's location.                      *
 *                                                                                             *
 *          dir      -- unused                                                                 *
 *                                                                                             *
 * OUTPUT:  bool; Was the terrain object successful in the unlimbo process? Failure could be   *
 *                the result of illegal positioning.                                           *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   11/02/1994 JLB : Created.                                                                 *
 *   11/16/1994 JLB : Checks for theater legality.                                             *
 *=============================================================================================*/
bool TerrainClass::Unlimbo(COORDINATE coord, DirType dir)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool TerrainClass::Unlimbo(COORDINATE coord, DirType dir)");
#endif
	Validate();
	if (Class->Theater & (1 << Map.Theater)) {
		return(ObjectClass::Unlimbo(coord, dir));
	}
	return(false);
}


/***********************************************************************************************
 * TerrainClass::Start_To_Crumble -- Initiates crumbling of terrain (tree) object.             *
 *                                                                                             *
 *    This routine is used to start the crumbling process for terrain object. This only        *
 *    applies to trees.                                                                        *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/22/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::Start_To_Crumble(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Start_To_Crumble(void)");
#endif
	Validate();
	if (!IsCrumbling) {
		IsCrumbling = true;
		Set_Rate(2);
		Set_Stage(0);
	}
}


/***********************************************************************************************
 * TerrainClass::Limbo -- Handles terrain specific limbo action.                               *
 *                                                                                             *
 *    This routine (called as a part of the limbo process) will remove the terrain occupation  *
 *    flag in the cell it occupies.                                                            *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  bool; Was the terrain object unlimboed?                                            *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/22/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
bool TerrainClass::Limbo(void)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("bool TerrainClass::Limbo(void)");
#endif
	Validate();
	if (!IsInLimbo) {
		CELL cell = Coord_Cell(Coord);
		Map[cell].Flag.Occupy.Monolith = false;
	}
	return(ObjectClass::Limbo());
}


/***********************************************************************************************
 * TerrainClass::Center_Coord -- Fetches the center point coordinate for terrain object.       *
 *                                                                                             *
 *    Use this routine to fetch the center point terrain                                       *
 *                                                                                             *
 * INPUT:                                                                                      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   01/23/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
COORDINATE TerrainClass::Center_Coord(void) const
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("COORDINATE TerrainClass::Center_Coord(void) const");
#endif
	Validate();
	return(Coord_Add(Coord, Class->CenterBase));
}


/***********************************************************************************************
 * TerrainClass::TerrainClass -- Constructor for a terrain class object.                       *
 *                                                                                             *
 *    This is the default constructor for a terrain class object. It basically initializes     *
 *    the object to a null -- do nothing -- state.                                             *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/10/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
TerrainClass::TerrainClass(void) :
	Class(0)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("TerrainClass::TerrainClass(void)");
#endif
	IsOnFire = false;
	IsCrumbling = false;
	IsBlossoming = false;
	IsBarnacled = false;
	IsSporing = false;
	Strength = 0;
}


/***********************************************************************************************
 * TerrainClass::Radar_Icon -- Fetches pointer to radar icon to use.                           *
 *                                                                                             *
 *    This routine will return with a pointer to the radar icon to use for the cell number     *
 *    specified.                                                                               *
 *                                                                                             *
 * INPUT:   cell  -- The cell number to use when determine what icon pointer to return.        *
 *                                                                                             *
 * OUTPUT:  Returns with a pointer to the 9 pixel values that make up the icon of this         *
 *          terrain object located at the cell specified.                                      *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/08/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
unsigned char * TerrainClass::Radar_Icon(CELL cell)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("unsigned char * TerrainClass::Radar_Icon(CELL cell)");
#endif
	Validate();
	unsigned char *icon = (unsigned char *)Class->Get_Radar_Data();	// get a pointer to radar icons
	if (!icon) {
		return(NULL);
	}
	int  width = *icon++;							// extract the width from data
	int  height = *icon++;							// extract the width from data

	/*
	** Icon number that we need can be found by converting the cell and base
	** cell to and x and y offset from the upper left of the cell, and then
	** multiplying it by the width of the terrain in icons, which we
	** conveniantly stored out as the first byte of every icon we made.
	*/
	int basecell = Coord_Cell(Coord);				// find the base cell of terrain
	int ydiff = Cell_Y(cell) - Cell_Y(basecell);
	int xdiff = Cell_X(cell) - Cell_X(basecell);
	if (xdiff < width && ydiff < height) {
		int iconnum = (ydiff * width) + xdiff;
		return(icon + (iconnum * 9));
	}
	return(NULL);
}


/***********************************************************************************************
 * TerrainClass::Read_INI -- Reads terrain objects from INI file.                              *
 *                                                                                             *
 *    This routine reads a scenario control INI file and creates all                           *
 *    terrain objects specified therein. Objects so created are placed                         *
 *    upon the map.                                                                            *
 *                                                                                             *
 *      INI entry format:                                                                      *
 *      cellnum = TypeName, Triggername                                                        *
 *                                                                                             *
 * INPUT:   buffer   -- Pointer to the loaded scenario INI file data.                          *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/24/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TerrainClass::Read_INI(char *buffer)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Read_INI(char *buffer)");
#endif
	char	*tbuffer;	// Accumulation buffer of unit IDs.
	int	len;			// Size of data in buffer.
	char	buf[128];
	TerrainClass * tptr;

	len = strlen(buffer) + 2;
	tbuffer = buffer + len;

	WWGetPrivateProfileString(INI_Name(), NULL, NULL, tbuffer, ShapeBufferSize-len, buffer);
	while (*tbuffer != '\0') {
		TerrainType	terrain;		// Terrain type.
		CELL			cell;

		cell = atoi(tbuffer);
		WWGetPrivateProfileString(INI_Name(), tbuffer, NULL, buf, sizeof(buf)-1, buffer);
		terrain = TerrainTypeClass::From_Name(strtok(buf, ","));
		if (terrain != TERRAIN_NONE) {
			tptr = new TerrainClass(terrain, cell);
			tptr->Trigger = TriggerClass::As_Pointer(strtok(NULL,","));
			if (tptr->Trigger)
				tptr->Trigger->AttachCount++;
		}
		tbuffer += strlen(tbuffer)+1;
	}
}


/***********************************************************************************************
 * TerrainClass::Write_INI -- Writes all terrain objects to the INI file.                      *
 *                                                                                             *
 *    This routine is used to write all the terrain objects out to the INI file specified.     *
 *    It is used by the scenario editor to write out the map data.                             *
 *                                                                                             *
 *      INI entry format:                                                                      *
 *      cellnum = TypeName, Triggername                                                        *
 *                                                                                             *
 * INPUT:   buffer   -- Pointer to the INI file staging area.                                  *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/28/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
#ifdef SCENARIO_EDITOR
void TerrainClass::Write_INI(char *buffer)
{
#ifdef INCLUDE_FUNCTION_NAMES
	CCDebugFunc("void TerrainClass::Write_INI(char *buffer)");
#endif
	int	index;
	char	uname[10];
	char	buf[127];
	char	*tbuffer;		// Accumulation buffer of unit IDs.

	/*
	**	First, clear out all existing terrain data from the ini file.
	*/
	tbuffer = buffer + strlen(buffer) + 2;
	WWGetPrivateProfileString(INI_Name(), NULL, NULL, tbuffer, ShapeBufferSize-strlen(buffer), buffer);
	while (*tbuffer != '\0') {
		WWWritePrivateProfileString(INI_Name(), tbuffer, NULL, buffer);
		tbuffer += strlen(tbuffer)+1;
	}

	/*
	**	Write the terrain data out.
	*/
	for (index = 0; index < Terrains.Count(); index++) {
		TerrainClass * terrain;

		terrain = Terrains.Ptr(index);
		if (!terrain->IsInLimbo && terrain->IsActive) {

			sprintf(uname, "%d", Coord_Cell(terrain->Coord));
			sprintf(buf, "%s,%s",
				terrain->Class->IniName,
				terrain->Trigger ? terrain->Trigger->Get_Name() : "None" );
			WWWritePrivateProfileString(INI_Name(), uname, buf, buffer);
		}
	}
}
#endif // SCENARIO_EDITOR
