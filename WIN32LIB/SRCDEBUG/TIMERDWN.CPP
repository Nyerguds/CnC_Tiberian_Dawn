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
 *                 Project Name : Temp timer for 32bit lib                 *
 *                                                                         *
 *                    File Name : TIMER.CPP                                *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : July 6, 1994                             *
 *                                                                         *
 *                  Last Update : July 12, 1994   [SKB]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   CDTC::Time -- Return the time on the timer.                           *
 *   CDTC::Stop -- Stop the timer.                                         *
 *   CDTC::Start -- Start a timer.                                         *
 *   CDTC::DownTimerClass -- Construct a timer class object.               *
 *   CDTC::Set -- Set the time of a timer.                           		*
 *   CDTC::Reset -- Clear the timer.                                       *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <wwstd.h>
#include "timer.H"

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Defines /////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Code ////////////////////////////////////////


/***************************************************************************
 * TC::CountDownTimerClass -- Construct a timer class object.              *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/12/1994 SKB : Created.                                             *
 *=========================================================================*/
CountDownTimerClass::CountDownTimerClass(BaseTimerEnum timer, long set, int on)
							:TimerClass(timer, on)
{
	Set(set, on);
}

CountDownTimerClass::CountDownTimerClass(BaseTimerEnum timer, int on)
							:TimerClass(timer, FALSE)
{
	DelayTime = 0;
	if (on) Start();
}


/***************************************************************************
 * CDTC::TIME -- Return the time on the timer.                             *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/12/1994 SKB : Created.                                             *
 *=========================================================================*/
long CountDownTimerClass::Time()
{
	long ticks = DelayTime - TimerClass::Time();

	if (ticks < 0) {
		ticks = 0;
	}
	return(ticks);
}


/***************************************************************************
 * CDTC::SET -- Set the time of a timer.                             		*
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:  ULONG value to set timer at.                                    *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   07/12/1994 SKB : Created.                                             *
 *=========================================================================*/
long CountDownTimerClass::Set(long value, BOOL start)
{
	DelayTime = value;
	TimerClass::Reset(start);
	return(Time());
}



