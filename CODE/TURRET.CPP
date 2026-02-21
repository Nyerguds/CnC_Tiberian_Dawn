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

/* $Header:   F:\projects\c&c\vcs\code\turret.cpv   2.18   16 Oct 1995 16:50:38   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : TURRET.CPP                                                   *
 *                                                                                             *
 *                   Programmer : Joe L. Bostic                                                *
 *                                                                                             *
 *                   Start Date : April 25, 1994                                               *
 *                                                                                             *
 *                  Last Update : August 13, 1995 [JLB]                                        *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   TurretClass::AI -- Handles the reloading of the turret weapon.                            *
 *   TurretClass::Can_Fire -- Determines if turret can fire upon target.                       *
 *   TurretClass::Debug_Dump -- Debug printing of turret values.                               *
 *   TurretClass::Fire_At -- Try to fire upon the target specified.                            *
 *   TurretClass::Fire_Coord -- Determines the coordinate that projectile would appear.        *
 *   TurretClass::Fire_Direction -- Determines the direction of firing.                        *
 *   TurretClass::Ok_To_Move -- Queries whether the vehicle can move.                          *
 *   TurretClass::TurretClass -- Normal constructor for the turret class.                      *
 *   TurretClass::TurretClass -- The default constructor for turret class objects.             *
 *   TurretClass::Unlimbo -- Unlimboes turret object.                                          *
 *   TurretClass::~TurretClass -- Default destructor for turret class objects.                 *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"function.h"
#include	"turret.h"


/***********************************************************************************************
 * TurretClass::~TurretClass -- Default destructor for turret class objects.                   *
 *                                                                                             *
 *    This is the default destructor for turret class objects. It does nothing.                *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/13/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
TurretClass::~TurretClass(void)
{
}


/***********************************************************************************************
 * TurretClass::TurretClass -- The default constructor for turret class objects.               *
 *                                                                                             *
 *    This is the default constructor for turret class objects. It does nothing.               *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   08/13/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
TurretClass::TurretClass(void)
{
}


/***********************************************************************************************
 * TurretClass::TurretClass -- Normal constructor for the turret class.                        *
 *                                                                                             *
 *    This is the normal constructor for the turret class. It merely sets the turret up to     *
 *    face north.                                                                              *
 *                                                                                             *
 * INPUT:   classid  -- The type id for this particular unit.                                  *
 *                                                                                             *
 *          house    -- The house that this unit will belong to.                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   02/02/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
TurretClass::TurretClass(UnitType classid, HousesType house) :
	DriveClass(classid, house)
{
	Reload = 0;
}


#ifdef CHEAT_KEYS
/***********************************************************************************************
 * TurretClass::Debug_Dump -- Debug printing of turret values.                                 *
 *                                                                                             *
 *    This routine is used to display the current values of this turret                        *
 *    class instance. It is primarily used in the debug output screen.                         *
 *                                                                                             *
 * INPUT:   x,y   -- Monochrome screen coordinates to display data.                            *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/12/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TurretClass::Debug_Dump(MonoClass *mono) const
{
	mono->Set_Cursor(36, 3);mono->Printf("%02X:%02X", SecondaryFacing.Current(), SecondaryFacing.Desired());
	mono->Set_Cursor(28, 7);mono->Printf("%2d", Arm);
	DriveClass::Debug_Dump(mono);
}
#endif


/***********************************************************************************************
 * TurretClass::Ok_To_Move -- Queries whether the vehicle can move.                            *
 *                                                                                             *
 *    This virtual routine is used to determine if the vehicle is allowed                      *
 *    to start moving. It is typically called when the vehicle desires                         *
 *    to move but needs confirmation from the turret logic before                              *
 *    proceeding. This happens when dealing with a vehicle that must have                      *
 *    its turret face the same direction as the body before the vehicle                        *
 *    may begin movement.                                                                      *
 *                                                                                             *
 * INPUT:   dir      -- The facing the unit wants to travel in.                                *
 *                                                                                             *
 * OUTPUT:  bool; Can the unit begin forward movement now?                                     *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   05/12/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
bool TurretClass::Ok_To_Move(DirType dir)
{
	if (Class->IsLockTurret) {
		if (IsRotating) {
			return(false);
		} else {
			if (SecondaryFacing.Difference(dir)) {
				SecondaryFacing.Set_Desired(dir);
				return(false);
			}
		}
	}
	return(true);
}


/***********************************************************************************************
 * TurretClass::AI -- Handles the reloading of the turret weapon.                              *
 *                                                                                             *
 *    This processes the reloading of the turret. It does this by decrementing the arming      *
 *    countdown  timer and when it reaches zero, the turret may fire.                          *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  none                                                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/21/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
void TurretClass::AI(void)
{
	DriveClass::AI();

	/*
	**	A unit with a constant rotating radar dish is handled here.
	*/
	if (Class->IsRadarEquipped) {
		SecondaryFacing.Set((DirType)(SecondaryFacing.Current() + 8));
		Mark(MARK_CHANGE);
	} else {

		IsRotating = false;
		if (Class->IsTurretEquipped) {
			if (IsTurretLockedDown) {
				SecondaryFacing.Set_Desired(PrimaryFacing.Current());
			}

			if (SecondaryFacing.Is_Rotating()) {
				if (SecondaryFacing.Rotation_Adjust(Class->ROT+1)) {
					Mark(MARK_CHANGE);
				}

				/*
				**	If no further rotation is necessary, flag that the rotation
				**	has stopped.
				*/
				IsRotating = SecondaryFacing.Is_Rotating();
			} else {
				if (!IsTurretLockedDown && !Target_Legal(TarCom)) {
					if (!Target_Legal(NavCom)) {
						SecondaryFacing.Set_Desired(PrimaryFacing.Current());
					} else {
						SecondaryFacing.Set_Desired(Direction(NavCom));
					}
				}
			}
		}
	}
}


/***********************************************************************************************
 * TurretClass::Fire_At -- Try to fire upon the target specified.                              *
 *                                                                                             *
 *    This routine is the auto-fire logic for the turret. It will check                        *
 *    to see if firing is technically legal given the specified target.                        *
 *    If it is legal to fire, it does so. It is safe to call this routine                      *
 *    every game tick.                                                                         *
 *                                                                                             *
 * INPUT:   target   -- The target to fire upon.                                               *
 *                                                                                             *
 *          which    -- Which weapon to use when firing. 0=primary, 1=secondary.               *
 *                                                                                             *
 * OUTPUT:  bool; Did firing occur?                                                            *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/26/1994 JLB : Created.                                                                 *
 *=============================================================================================*/
BulletClass * TurretClass::Fire_At(TARGET target, int which)
{
	BulletClass * bullet = NULL;
	WeaponTypeClass const * weapon = (which == 0) ? &Weapons[Class->Primary] : &Weapons[Class->Secondary];

	if (Can_Fire(target, which) == FIRE_OK) {
		bullet = DriveClass::Fire_At(target, which);

		if (bullet) {

			/*
			**	Possible reload timer set.
			*/
			if (*this == UNIT_SSM && Reload == 0) {
				Reload = TICKS_PER_SECOND * 30;
			}
		}
	}

	return(bullet);
}


/***********************************************************************************************
 * TurretClass::Can_Fire -- Determines if turret can fire upon target.                         *
 *                                                                                             *
 *    This routine determines if the turret can fire upon the target                           *
 *    specified.                                                                               *
 *                                                                                             *
 * INPUT:   target   -- The target to fire upon.                                               *
 *                                                                                             *
 *          which    -- Which weapon to use to determine legality to fire. 0=primary,          *
 *                      1=secondary.                                                           *
 *                                                                                             *
 * OUTPUT:  Returns the fire status type that indicates if firing is allowed and if not, why.  *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   04/26/1994 JLB : Created.                                                                 *
 *   06/01/1994 JLB : Returns reason why it can't fire.                                        *
 *=============================================================================================*/
FireErrorType TurretClass::Can_Fire(TARGET target, int which) const
{
	DirType			dir;					// The facing to impart upon the projectile.
	int				diff;
	FireErrorType	fire = DriveClass::Can_Fire(target, which);

	if (fire == FIRE_OK) {
		WeaponTypeClass const * weapon = (which == 0) ? &Weapons[Class->Primary] : &Weapons[Class->Secondary];

		/*
		**	If this unit cannot fire while moving, then bail.
		*/
		if ((!Class->IsTurretEquipped || Class->IsLockTurret) && Target_Legal(NavCom)) {
			return(FIRE_MOVING);
		}

		/*
		**	If the turret is rotating and the projectile isn't a homing type, then
		**	firing must be delayed until the rotation stops.
		*/
		if (!IsFiring && IsRotating && !BulletTypeClass::As_Reference(weapon->Fires).IsHoming) {
			return(FIRE_ROTATING);
		}

		dir = Direction(target);

		/*
		**	Determine if the turret facing isn't too far off of facing the target.
		*/
		if (Class->IsTurretEquipped) {
			diff = SecondaryFacing.Difference(dir);
		} else {
			diff = PrimaryFacing.Difference(dir);
		}
		diff = ABS(diff);

		/*
		**	Special flame tank logic.
		*/
		if (weapon->Fires == BULLET_FLAME) {
			if (Dir_Facing(dir) == Dir_Facing(PrimaryFacing)) {
				diff = 0;
			}
		}

		if (BulletTypeClass::As_Reference(weapon->Fires).IsHoming) {
			diff >>= 2;
		}
		if (diff < 8) {
			return(DriveClass::Can_Fire(target, which));
		}
		return(FIRE_FACING);
	}
	return(fire);
}


/***********************************************************************************************
 * TurretClass::Fire_Coord -- Calculates the origin point for projectiles fired.               *
 *                                                                                             *
 *    Use this routine to determine the exact coordinate that a projectile would appear if it  *
 *    were fired from this unit. For units with turrets, typically, this would be at the end   *
 *    of the barrel.                                                                           *
 *                                                                                             *
 * INPUT:   which    -- Which weapon to use in the attack. 0=primary, 1=secondary.             *
 *                                                                                             *
 *          forrange -- if true, the facing will always be assumed to be towards the given     *
 *                      coordinates. This is used to perform facing-independent range checks.  *
 *                                                                                             *
 *          coords   -- The coordinates to face when calculating the fire coords. Only used    *
 *                      when forrange is true.                                                 *
 *                                                                                             *
 * OUTPUT:  Returns with coordinate of where a projectile should appear if this unit were      *
 *          to fire one.                                                                       *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   12/28/1994 JLB : Created.                                                                 *
 *   09/04/2025 MM  : Added arg to correctly calculate range to target regardless of facing.   *
 *=============================================================================================*/
COORDINATE TurretClass::Fire_Coord(int which, bool forrange, COORDINATE coords) const
{
	COORDINATE coord = Center_Coord();
	int barrellen = 0;
	int lateral = 0;
	DirType shiftdir = PrimaryFacing.Current();
	DirType barreldir = PrimaryFacing.Current();

	// Nyerguds's C&C Patch Project v1.04: Specific code to get fire coords for range checks.
	// Allow getting the fire coords for any given target to correctly calculate range.
	if (forrange) {
		barreldir = ::Direction(Coord, coords);
		shiftdir = barreldir;
	} else if (Class->IsTurretEquipped) {
		barreldir = SecondaryFacing.Current();
	}

	// Nyerguds's visual representation of coordinate adjustments, to give clarity to this mess.
	// In this example, the unit is facing to the east, with its turret aimed towards the north-east.
	// C = coord (unit center coords)
	// S = TurretShift (Shift of turret coords towards front facing of unit)
	// O = WeaponOffset (perspective shift of turret towards the north. The cause of all South Advantage bugs!)
	// B = BarrelLength (barrel length; shift towards facing)
	// L = BarrelLateral (adjustment to the left/right for double barreled units)
	//      L
	//     / \
	//    /   B
	//    \  / \
	//     \/   L
	//     O\  /
	//     | \/
	//  C--S

	if (Class->TurretShift) {
		// Chunky units are typically not rotatable. Only apply shift in optimal direction if unit can rotate.
		coord = Coord_Move(coord, Class->IsChunkyShape ? PrimaryFacing.Current() : shiftdir, Class->TurretShift);
	}
	// For range calculations, remove the north shift. Bye-bye, South Advantage!
	if (Class->WeaponOffset && !forrange) {
		coord = Coord_Move(coord, DIR_N, Class->WeaponOffset);
	}
	if (which == 0) {
		barrellen = Class->BarrelLengthPrimary;
		lateral = Class->BarrelLateralPrimary;
	} else {
		barrellen = Class->BarrelLengthSecondary;
		lateral = Class->BarrelLateralSecondary;
	}
	if (barrellen) {
		coord = Coord_Move(coord, barreldir, barrellen);
	}
	// For range calculations, remove the side shift.
	if (lateral && !forrange) {
		int yval1 = Coord_Y(coord);
		if (IsSecondShot) {
			coord = Coord_Move(coord, (DirType)(barreldir+DIR_E), lateral);
		} else {
			coord = Coord_Move(coord, (DirType)(barreldir+DIR_W), lateral);
		}
		int xval2 = Coord_X(coord);
		int yval2 = Coord_Y(coord);
		// Rough adjustment to perspective, by dividing the vertical difference by 2.
		int yvalpersp = yval1 + (yval2 - yval1) / 2;
		coord = XY_Coord(xval2, yvalpersp);
	}

	return(coord);
}


/***********************************************************************************************
 * TurretClass::Unlimbo -- Unlimboes turret object.                                            *
 *                                                                                             *
 *    This routine is called when a turret equipped unit unlimboes. It sets the turret to      *
 *    face the same direction as the body.                                                     *
 *                                                                                             *
 * INPUT:   coord -- The coordinate where the unit is unlimboing.                              *
 *                                                                                             *
 *          dir   -- The desired body and turret facing to use.                                *
 *                                                                                             *
 * OUTPUT:  Was the unit unlimboed successfully?                                               *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/25/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
bool TurretClass::Unlimbo(COORDINATE coord, DirType dir)
{
	if (DriveClass::Unlimbo(coord, dir)) {
		SecondaryFacing = dir;
		return(true);
	}
	return(false);
}


/***********************************************************************************************
 * TurretClass::Fire_Direction -- Determines the direction of firing.                          *
 *                                                                                             *
 *    This routine will return with the facing that a projectile will travel if it was         *
 *    fired at this instant. The facing should match the turret facing for those units         *
 *    equipped with a turret. If the unit doesn't have a turret, then it will be the facing    *
 *    of the body.                                                                             *
 *                                                                                             *
 * INPUT:   none                                                                               *
 *                                                                                             *
 * OUTPUT:  Returns with the default firing direction for a projectile.                        *
 *                                                                                             *
 * WARNINGS:   none                                                                            *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   06/25/1995 JLB : Created.                                                                 *
 *=============================================================================================*/
DirType TurretClass::Fire_Direction(void) const
{
	if (Class->IsTurretEquipped) {
		if (*this == UNIT_SSM) {
			int diff1 = SecondaryFacing.Difference(DIR_E);
			int diff2 = SecondaryFacing.Difference(DIR_W);
			diff1 = ABS(diff1);
			diff2 = ABS(diff2);
			int diff = MIN(diff1, diff2);
			int adj = Fixed_To_Cardinal(ABS(SecondaryFacing.Difference(DIR_N)), 64-diff);
			if (SecondaryFacing.Difference(DIR_N) < 0) {
				return(DirType)(SecondaryFacing - (DirType)adj);
			} else {
				return(DirType)(SecondaryFacing + (DirType)adj);
			}
		}
		return(SecondaryFacing.Current());
	}

	return(PrimaryFacing.Current());
}
