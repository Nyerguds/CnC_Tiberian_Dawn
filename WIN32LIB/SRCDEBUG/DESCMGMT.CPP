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
 *                 Project Name : Descriptor management                    *
 *                                                                         *
 *                    File Name : DESCMGMT.CPP                             *
 *                                                                         *
 *                   Programmer : Jeff Wilson                              *
 *                                                                         *
 *                   Start Date : March 28, 1994                           *
 *                                                                         *
 *                  Last Update : March 28, 1994   []                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * MAP_SEGMENT_TO_ADDRESS -- Maps a physical address into a selector       *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include "descmgmt.h"
#include "misc.h"


/***************************************************************************
 * MAP_SEGMENT_TO_ADDRESS -- Maps a physical address into a selector       *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT: selector UWORD The selector mapped to address. exit on error.   *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   03/25/1994  jaw: Created.                                             *
 *=========================================================================*/

ULONG Map_Segment_To_Address(ULONG address, ULONG length)
{							 				

// this function is not longer needed by RATIONAL SYSTEM DOS4GW
// linear addressing mode.
// a> the first megabyte of memory is mapped to linear adress 0 - 0x10000h
// b> all other addresses are linear offset from either ds: or es:

/*
	UWORD segment;
	UWORD curDS;
	CD_DES desc;
	CD_DES cur_desc;

	// allocate a selector
	if(_dos_allocmem(0, &segment) != 0) {
		Exit(1, "Allocation of Descriptor.\n");
	}

	// get the data for this selector
	if(_dx_ldt_rd(segment, (UCHAR *)&desc) != 0) {
		Exit(1, "Reading Descriptor.\n");
	}

	// get the data for current data segment
	curDS = GetDs();
	if(_dx_ldt_rd(curDS, (UCHAR *)&cur_desc) != 0) {
		Exit(1, "Reading Descriptor.\n");
	}
	
	// set limit
	desc.limit0_15 		= (USHORT)(length & 0xffff);
	desc.limit16_19 	= ((UCHAR)(length >> 16L)) | DOS_32;

	// set base address
	desc.base0_15 		= (USHORT)(address & 0xffff);
	desc.base16_23		= (UCHAR)((address >> 16) & 0xff);
	desc.base24_31		= (UCHAR)((address >> 24) & 0xff);

	// set rights mark as icurrent data segment
	desc.arights 		= cur_desc.arights;
							 
	// write to LDT selector
	if(_dx_ldt_wr(segment, (UCHAR *)&desc) != 0) {
		Exit(1, "Failed writing descriptor.\n");
	}

	// return selector number
	return segment;
 */

       if ( address & 0xfff0ffff ) 
	    Exit ( 1 , "Error mapping real address to lineal address.\n" ) ;

       return address ;
}

