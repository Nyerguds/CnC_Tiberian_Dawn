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

/* $Header:   F:\projects\c&c\vcs\code\base.cpv   1.9   16 Oct 1995 16:48:56   JOE_BOSTIC  $ */
/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer                                            *
 *                                                                                             *
 *                    File Name : BASE.CPP                                                     *
 *                                                                                             *
 *                   Programmer : Bill Randolph                                                *
 *                                                                                             *
 *                   Start Date : 03/27/95                                                     *
 *                                                                                             *
 *                  Last Update : March 27, 1995                                               *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *   BaseClass::Get_Building -- Returns ptr to the built building for the given node           *
 *   BaseClass::Get_Node -- Returns ptr to the node corresponding to given object              *
 *   BaseClass::Is_Built -- Tells if given item in the list has been built yet                 *
 *   BaseClass::Is_Node -- Tells if the given building is part of our base list                *
 *   BaseClass::Load -- loads from a saved game file                                           *
 *   BaseClass::Next_Buildable -- returns ptr to the next node that needs to be built          *
 *   BaseClass::Read_INI -- INI reading routine                                                *
 *   BaseClass::Save -- saves to a saved game file                                             *
 *   BaseClass::Write_INI -- INI writing routine                                               *
 *   BaseNodeClass::operator != -- inequality operator                                         *
 *   BaseNodeClass::operator == -- equality operator                                           *
 *   BaseNodeClass::operator > -- greater-than operator                                        *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "function.h"


/***********************************************************************************************
 * BaseNodeClass::operator == -- equality operator                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      node      node to test against                                                         *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      true = equal, false = not equal                                                        *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
int BaseNodeClass::operator == (BaseNodeClass const & node)
{
	return(Type == node.Type && Coord == node.Coord);
}


/***********************************************************************************************
 * BaseNodeClass::operator != -- inequality operator                                           *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      node      node to test against                                                         *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      comparison result                                                                      *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
int BaseNodeClass::operator !=(BaseNodeClass const & node)
{
	return(Type != node.Type || Coord != node.Coord);
}


/***********************************************************************************************
 * BaseNodeClass::operator > -- greater-than operator                                          *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      node      node to test against                                                         *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      comparison result                                                                      *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
int BaseNodeClass::operator > (BaseNodeClass const & )
{
	return(true);
}


/***********************************************************************************************
 * BaseClass::Read_INI -- INI reading routine                                                  *
 *                                                                                             *
 * INI entry format:                                                                           *
 *      BLDG=COORD                                                                             *
 *      BLDG=COORD                                                                             *
 *        ...                                                                                  *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      buffer      pointer to loaded INI file                                                 *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      none.                                                                                  *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      This routines assumes there is only one base defined for the scenario.                 *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
void BaseClass::Read_INI(char *buffer)
{
	char buf[128];
	char uname[10];
	BaseNodeClass node;						// node to add to list

	/*
	**	First, determine the house of the human player, and set the Base's house
	**	accordingly.
	*/
	WWGetPrivateProfileString("BASIC", "Player", "GoodGuy", buf, 20, buffer);
	if (HouseTypeClass::From_Name(buf) == HOUSE_GOOD) {
		House = HOUSE_BAD;
	} else {
		House = HOUSE_GOOD;
	}

	/*
	**	Read the number of buildings that will go into the base node list
	*/
	int count = WWGetPrivateProfileInt (INI_Name(),"Count",0,buffer);

	/*
	**	Read each entry in turn, in the same order they were written out.
	*/
	for (int i = 0; i < count; i++) {

		/*
		** Get an INI entry
		*/
		sprintf(uname,"%03d",i);
		WWGetPrivateProfileString(INI_Name(), uname, NULL, buf, sizeof(buf)-1, buffer);

		/*
		** Set the node's building type
		*/
		node.Type = BuildingTypeClass::From_Name(strtok(buf,","));

		/*
		** Read & set the node's coordinate
		*/
		node.Coord = atol(strtok(NULL,","));

		/*
		** Add this node to the Base's list
		*/
		Nodes.Add(node);
	}
}


/***********************************************************************************************
 * BaseClass::Write_INI -- INI writing routine                                                 *
 *                                                                                             *
 * INI entry format:                                                                           *
 *      BLDG=COORD                                                                             *
 *      BLDG=COORD                                                                             *
 *        ...                                                                                  *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      buffer      pointer to loaded INI file staging area                                    *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      none.                                                                                  *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      This routines assumes there is only one base defined for the scenario.                 *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
#ifdef SCENARIO_EDITOR
void BaseClass::Write_INI(char *buffer)
{
	char buf[128];
	char uname[10];

	/*
	**	Clear out all existing teamtype data from the INI file.
	*/
	WWWritePrivateProfileString(INI_Name(), NULL, NULL, buffer);

	/*
	**	Save the # of buildings in the Nodes list.  This is essential because
	**	they must be read in the same order they were created, so "000" must be
	**	read first, etc.
	*/
	WWWritePrivateProfileInt (INI_Name(),"Count",Nodes.Count(),buffer);

	/*
	**	Write each entry into the INI
	*/
	for (int i = 0; i < Nodes.Count(); i++) {
		sprintf(uname,"%03d",i);
		sprintf(buf,"%s,%d",
			BuildingTypeClass::As_Reference(Nodes[i].Type).IniName,
			Nodes[i].Coord);

		WWWritePrivateProfileString(INI_Name(), uname, buf, buffer);
	}
}
#endif // SCENARIO_EDITOR


/***********************************************************************************************
 * BaseClass::Load -- loads from a saved game file                                             *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      file      open file                                                                    *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      true = success, false = failure                                                        *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
bool BaseClass::Load(FileClass &file)
{
	int num_struct;
	int i;
	BaseNodeClass node;

	/*
	** Read in & check the size of this class
	*/
	if (file.Read(&i, sizeof(i)) != sizeof(i)) {
		return(false);
	}

	if (i != sizeof(*this)) {
		return(false);
	}

	/*
	** Read in the House & the number of structures in the base
	*/
	if (file.Read(&House,sizeof(House)) != sizeof(House)) {
		return(false);
	}

	if (file.Read(&num_struct,sizeof(num_struct)) != sizeof(num_struct)) {
		return(false);
	}

	/*
	** Read each node entry & add it to the list
	*/
	for (i = 0; i < num_struct; i++) {
		if (file.Read(&node,sizeof(node)) != sizeof(node)) {
			return(false);
		}
		Nodes.Add(node);
	}

	return(true);
}


/***********************************************************************************************
 * BaseClass::Save -- saves to a saved game file                                               *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      file      open file                                                                    *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      true = success, false = failure                                                        *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
bool BaseClass::Save(FileClass &file)
{
	int num_struct;
	int i;
	BaseNodeClass node;

	/*
	** Write the size of this class
	*/
	i = sizeof(*this);
	if (file.Write(&i,sizeof(i)) != sizeof(i)) {
		return(false);
	}

	/*
	** Write the House & the number of structures in the base
	*/
	if (file.Write(&House,sizeof(House)) != sizeof(House)) {
		return(false);
	}

	num_struct = Nodes.Count();
	if (file.Write(&num_struct,sizeof(num_struct)) != sizeof(num_struct)) {
		return(false);
	}

	/*
	** Write each node entry
	*/
	for (i = 0; i < num_struct; i++) {
		node = Nodes[i];
		if (file.Write(&node,sizeof(node)) != sizeof(node)) {
			return(false);
		}
	}

	return(true);
}


/***********************************************************************************************
 * BaseClass::Is_Built -- Tells if given item in the list has been built yet                   *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      index      index into base list                                                        *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      true = yes, false = no                                                                 *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
bool BaseClass::Is_Built(int index)
{
	if (Get_Built_Overlay(index) != NULL || Get_Building(index) != NULL) {
		return(true);
	} else {
		return(false);
	}
}

/***********************************************************************************************
 * BaseClass::Get_Building -- Returns ptr to the built building for the given node.            *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      index    Node index of building to test                                                *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      ptr to already-built building, NULL if none.                                           *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
BuildingClass * BaseClass::Get_Building(int index)
{
	BaseNodeClass * node = &Nodes[index];
	StructType nodestruct = node->Type;
	if (nodestruct == STRUCT_NONE) {
		return(NULL);
	}
	BuildingTypeClass structinfo = BuildingTypeClass::As_Reference(nodestruct);
	if (structinfo.IsWall) {
		return(NULL);
	}
	BuildingClass *bldg;
	ObjectClass *obj[4];

	/*
	** Check the location on the map where this building should be; if it's
	** there, return a pointer to it.
	*/
	CELL cell = Coord_Cell(node->Coord);

	obj[0] = Map[cell].Cell_Building();
	obj[1] = Map[cell].Overlapper[0];
	obj[2] = Map[cell].Overlapper[1];
	obj[3] = Map[cell].Overlapper[2];

	bldg = NULL;
	for (int i = 0; i < 4; i++) {
		if (obj[i] &&
			obj[i]->Coord == Nodes[index].Coord &&
			obj[i]->What_Am_I() == RTTI_BUILDING &&
			((BuildingClass *)obj[i])->Class->Type == Nodes[index].Type) {

				bldg = (BuildingClass *)obj[i];
				break;
		}
	}

	return(bldg);
}


/***********************************************************************************************
 * BaseClass::Get_Built_Overlay -- Returns ptr to the built overlay cell for the given node.   *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      index    Node index of building to test                                                *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      ptr to cell containing the correct wall type, or NULL if none.                         *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
CellClass * BaseClass::Get_Built_Overlay(int index) 
{
	BaseNodeClass * node = &Nodes[index];
	StructType nodestruct = node->Type;
	if (nodestruct == STRUCT_NONE) {
		return(NULL);
	}
	BuildingTypeClass structinfo = BuildingTypeClass::As_Reference(nodestruct);
	if (!structinfo.IsWall) {
		return(NULL);
	}
	CELL cell = Coord_Cell(node->Coord);
	CellClass * cellptr = &Map[cell];
	if (cellptr->Overlay != OVERLAY_NONE) {
		OverlayTypeClass ovt = OverlayTypeClass::As_Reference(cellptr->Overlay);
		if (ovt.WallStructureType == nodestruct) {
			return (cellptr);
		}
	}
	return(NULL);
}


/***********************************************************************************************
 * BaseClass::Is_Node -- Tells if the given building is part of our base list                  *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      obj      pointer to building to test                                                   *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      true = building is a node in the list, false = isn't                                   *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
bool BaseClass::Is_Node(BuildingClass *obj)
{
	if (Get_Node(obj) != NULL) {
		return(true);
	} else {
		return(false);
	}
}


/***********************************************************************************************
 * BaseClass::Get_Node -- Returns ptr to the node corresponding to given object                *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      obj      pointer to building to test                                                   *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      ptr to node                                                                            *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
BaseNodeClass * BaseClass::Get_Node(BuildingClass *obj)
{
	for (int i = 0; i < Nodes.Count(); i++) {
		if (obj->Class->Type == Nodes[i].Type && obj->Coord == Nodes[i].Coord) {
			return(&Nodes[i]);
		}
	}
	return(NULL);
}


/***********************************************************************************************
 * BaseClass::Next_Buildable -- returns ptr to the next node that needs to be built            *
 *                                                                                             *
 * If 'type' is not NONE, returns ptr to the next "hole" in the list of the given type.        *
 * Otherwise, returns ptr to the next hole in the list of any type.                            *
 *                                                                                             *
 * INPUT:                                                                                      *
 *      type        Type of building to check for.                                             *
 *                                                                                             *
 *      afterthis   Previous scanned and rejected node; skip ahead until after this node.      *
 *                                                                                             *
 * OUTPUT:                                                                                     *
 *      ptr to a BaseNodeClass, NULL if none                                                   *
 *                                                                                             *
 * WARNINGS:                                                                                   *
 *      none.                                                                                  *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *   03/24/1995 BRR : Created.                                                                 *
 *=============================================================================================*/
BaseNodeClass * BaseClass::Next_Buildable(StructType type, BaseNodeClass * afterthis)
{
	/*
	** Loop through all node entries, returning a pointer to the first
	** un-built one that matches the requested type.
	*/
	// Nyerguds's C&C Patch Project v1.04: Allow scanning further in base nodes.
	BaseNodeClass * tofind = afterthis;
	for (int i = 0; i < Nodes.Count(); i++) {
		// Skip ahead until after specified node.
		if (tofind != NULL) {
			if (&Nodes[i] != tofind) {
				continue;
			} else {
				tofind = NULL;
				continue;
			}
		}
		/*
		** For STRUCT_NONE, return the first hole found
		*/
		if (type == STRUCT_NONE) {
			if (!Is_Built(i)) {
				return(&Nodes[i]);
			}

		} else {

			/*
			** For a "real" building type, return the first hold for that type
			*/
			if (Nodes[i].Type==type && !Is_Built(i)) {
				return(&Nodes[i]);
			}
		}
	}


// If no entry could be found, then create a fake one that will allow
// placement of the building. Make it static and reuse the next time this
// routine is called.

	return(NULL);
}
