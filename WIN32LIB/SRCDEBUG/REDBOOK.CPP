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
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : WWLIB	  											*
 *                                                                         *
 *                    File Name : REDBOOK.CPP										*
 *                                                                         *
 *                   Programmer : STEVE WETHERILL (FROM SCOTT BOWEN CODE)  *
 *                                                                         *
 *                   Start Date : 5/13/94												*
 *                                                                         *
 *                  Last Update : June 4, 1994   [SW]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *		RedBookClass::~RedBookClass(VOID)												*
 *		RedBookClass::RedToHS(ULONG i)													*
 *		RedBookClass::MSFtoRed(UBYTE m, UBYTE s, UBYTE f)							*
 *		RedBookClass::FullCDVolume(UBYTE chan)											*
 *		RedBookClass::PlayTrack(UWORD track)											*
 *		RedBookClass::Play_CD_MSL(UWORD min_sec, UWORD len)						*
 *		RedBookClass::PlayMSF(UBYTE startM, UBYTE startS, UBYTE startF,		*
 * 			  				UBYTE endM, UBYTE endS, UBYTE endF, UBYTE chan)		*
 *		RedBookClass::CheckCDMusic(VOID)													*
 *		RedBookClass::StopCDMusic(VOID)													*
 *= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>

#include "wwstd.h"
#include "playcd.h"
#include "wwmem.h"


/***************************************************************************
 * RedBookClass -- default constructor													*
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *      	none																					*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *		calls GetCDDrive()																	*
 * HISTORY:                                                                *
 *   05/25/1994 SW : Created.																*
 *=========================================================================*/

RedBookClass::RedBookClass(VOID)
	: GetCDClass()			// call the base constructor

{
	SEGSEL tmpadr ;

	tmpadr = cdDrive_addrp;
	memset ( this  , 0 , sizeof ( RedBookClass )	) ;
	cdDrive_addrp = tmpadr ;

	Stop.Length		=	13;
	Stop.Command	=	133;

	Tinfo.Length	=	26;
	Tinfo.Command	=	3;
	Tinfo.CntTrns	=	7;
	Tinfo.TrInfo	=	11;

	Play.Length		=	22;
	Play.Command	=	132;
	Play.AddrMd		=	1;
	
	Volm.Length		=	26;
	Volm.Command	=	12;
	Volm.CntTrns	=	9;
	Volm.TrInfo		=	3;
	Volm.In1			=	1;
	Volm.In2			=	2;
	Volm.In3			=	3;
	
	Stat.Length		=	26;
	Stat.Command	=	3;
	Stat.CntTrns	=	11;
	Stat.StatInfo	=	15;
							
	if	(DPMI_real_alloc(sizeof(TinfoType)/16+1, &Tinfo_addrp, &largestp))
		exit(1);

	if	(DPMI_real_alloc(sizeof(StatType)/16+1, &Stat_addrp, &largestp))
		exit(1);

	if	(DPMI_real_alloc(sizeof(VolmType)/16+1, &Volm_addrp, &largestp))
		exit(1);

	if	(DPMI_real_alloc(sizeof(PlayType)/16+1, &Play_addrp, &largestp))
		exit(1);

	if	(DPMI_real_alloc(sizeof(StopType)/16+1, &Stop_addrp, &largestp))
		exit(1);

	GetCDDrive();

}

/***************************************************************************
 * REDBOOKCLASS -- destructor                                              *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	none																					*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.                                              *
 *=========================================================================*/

RedBookClass::~RedBookClass(VOID)
{
	if(Tinfo_addrp.seg)
		DPMI_real_free(Tinfo_addrp);		// free up those conventional buffers

	if(Stat_addrp.seg)
		DPMI_real_free(Stat_addrp);

	if(Volm_addrp.seg)
		DPMI_real_free(Volm_addrp);

	if(Play_addrp.seg)
		DPMI_real_free(Play_addrp);

	if(Stop_addrp.seg)
		DPMI_real_free(Stop_addrp);
}

/***************************************************************************
 * REDTOHS -- RedBook to High-Sierra conversion                            *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	ULONG																					*
 * OUTPUT:    																					*
 *			ULONG																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.																*
 *=========================================================================*/

ULONG RedBookClass::RedToHS(ULONG i)
{
	return( ((i>>16) & 0xFF) * 60 * 75) + ( ((i>>8) & 0xFF) * 75) + (i & 0xFF);
}

/***************************************************************************
 * MSFTORED -- Minute, Second, Frame to RedBook conversion                 *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *   		UBYTE	minute																		*
 * 		UBYTE	second																		*
 *	  		UBYTE	frame																			*
 * OUTPUT:          																			*
 *			ULONG	RedBook																		*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.                                              *
 *=========================================================================*/

ULONG  RedBookClass::MSFtoRed(UBYTE m, UBYTE s, UBYTE f)
{
	return( ((ULONG)m << 16) + ((ULONG)s << 8) + (ULONG)f );
}

/***************************************************************************
 * FULLCDVOLUME -- set full volume                                         *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *		UBYTE channel																			*
 *						 																			*
 *				CHLEFT																			*
 *				CHRIGHT																			*
 *				CHBOTH																			*
 *																									*
 * OUTPUT:																						*
 *    		none																				*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.                                              *
 *=========================================================================*/

VOID  RedBookClass::FullCDVolume(UBYTE chan)
{

	Volm.Vol0 = Volm.Vol1 = Volm.Vol2 = Volm.Vol3 = 255;

	Volm.TrnsAdOff = offsetof	(VolmType, TrInfo);
	Volm.TrnsAdSeg = Volm_addrp.seg;

	if(chan == CHLEFT)
	{
//		Volm.In0 = 0;
//		Volm.In1 = 3;
//		Volm.In2 = 3;
//		Volm.In3 = 3;
		Volm.Vol1 = 0;
	}
	else if(chan == CHRIGHT)
	{
//		Volm.In0 = 3;
//		Volm.In1 = 1;
//		Volm.In2 = 3;
//		Volm.In3 = 3;
		Volm.Vol0 = 0;
	}
	else			/* both channels */
	{
		Volm.In0 = 0;
		Volm.In1 = 1;
		Volm.In2 = 2;
		Volm.In3 = 3;
	}

//	WriteRealMem(REALPTR(Volm_addrp) << 16, &Volm, sizeof(VolmType));
	Mem_Copy ( &Volm , (void *) ( Volm_addrp.seg << 4 ) , sizeof(VolmType));

	regs.x.eax = 0x1510;
	regs.x.ecx = cdDrive[0];
	regs.x.ebx = 0x0000;
	sregs.es   = Volm_addrp.seg;

	DPMI_real_intr(0x2F, &regs, & sregs);

//	ReadRealMem(&Volm, REALPTR(Volm_addrp) << 16, sizeof(VolmType));
	Mem_Copy ( (void *) ( Volm_addrp . seg << 4 ), &Volm ,sizeof(VolmType));
}



/***************************************************************************
 * PLAYTRACK -- play a track                                               *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 * 		UWORD	track																			*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.                                              *
 *=========================================================================*/

VOID  RedBookClass::PlayTrack(UWORD track)
{

	StopCDMusic();

	Tinfo.Track = track;

	Tinfo.TrnsAdOff = offsetof	(TinfoType, TrInfo);
	Tinfo.TrnsAdSeg = Tinfo_addrp.seg;

//	WriteRealMem(REALPTR(Tinfo_addrp) << 16, &Tinfo, sizeof(TinfoType));
	Mem_Copy ( &Tinfo , (void *) ( Tinfo_addrp.seg << 4 ) , sizeof(TinfoType));

	regs.x.eax = 0x1510;
	regs.x.ecx	= cdDrive[0];
	regs.x.ebx = 0x0000;
	sregs.es 	= Tinfo_addrp.seg;

	DPMI_real_intr(0x2F, &regs, &sregs);		// gets start time of track in Tinfo.Start

//	ReadRealMem(&Tinfo, REALPTR(Tinfo_addrp) << 16, sizeof(TinfoType));
	Mem_Copy ( (void *) ( Tinfo_addrp.seg << 4 ) , &Tinfo, sizeof(TinfoType));




	Play.Start = Tinfo.Start;
	Tinfo.Track++;

	Tinfo.TrnsAdOff = offsetof	(TinfoType, TrInfo);
	Tinfo.TrnsAdSeg = Tinfo_addrp.seg;

//	WriteRealMem(REALPTR(Tinfo_addrp) << 16, &Tinfo, sizeof(TinfoType));
	Mem_Copy ( &Tinfo , (void *) ( Tinfo_addrp.seg << 4 ) , sizeof(TinfoType));

	regs.x.eax = 0x1510;
	regs.x.ecx = cdDrive[0];
	regs.x.ebx = 0x0000;
	sregs.es  = Tinfo_addrp.seg;

	DPMI_real_intr(0x2F, &regs , &sregs);		// gets start time of following track in Tinfo.Start

//	ReadRealMem(&Tinfo, REALPTR(Tinfo_addrp) << 16, sizeof(TinfoType));
	Mem_Copy ( (void *) ( Tinfo_addrp.seg << 4 ) , &Tinfo, sizeof(TinfoType));



	Play.CntSect  = RedToHS(Tinfo.Start) - RedToHS(Play.Start) - 1;

//	WriteRealMem(REALPTR(Play_addrp) << 16, &Play, sizeof(PlayType));
	Mem_Copy ( &Play , (void *) ( Play_addrp.seg << 4 ) , sizeof(PlayType));

	regs.x.eax = 0x1510;
	regs.x.ecx = cdDrive[0];
	regs.x.ebx = 0x0000;
	sregs.es 	= Play_addrp.seg;

  	DPMI_real_intr(0x2F, &regs, &sregs);

//	ReadRealMem(&Play, REALPTR(Play_addrp) << 16, sizeof(PlayType));
	Mem_Copy ( (void *) ( Play_addrp.seg << 4 ) , &Play, sizeof(PlayType));


	FullCDVolume(CHBOTH);
}


/***************************************************************************
 * PLAY_CD_MSL -- play cd from start min_sec for len                       *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	UWORD	min_sec																		*
 *			UWORD	Len																			*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/26/1994 SW : Created.                                              *
 *=========================================================================*/


VOID  RedBookClass::Play_CD_MSL(UWORD min_sec, UWORD len) 
{
	UWORD startM, startS, startF;
	UWORD endM, endS, endF;

	if (!len)
		return;

	endM = startM = (min_sec >> 8) + AUDIO_START_MIN;
	endS = startS = (min_sec & 0xFF) + AUDIO_START_SEC;
	startF = endF = 0;

	while (len > 59) {
		endM++;
		len -= 60;
	}

	endS += len;
	if (endS > 59) {
		endM++;
		endS -= 60;
	}

	PlayMSF((UBYTE) startM, (UBYTE)startS, (UBYTE)startF, (UBYTE)endM, (UBYTE)endS, (UBYTE)endF, 2 /* chan */);
}


/***************************************************************************
 * PlayMSF -- Play Minute, Second, Frame to Minute, Second, Frame				*
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	UBYTE	startM																		*
 *			UBYTE	startS																		*
 *			UBYTE	startF																		*
 *    	UBYTE	endM																			*
 *			UBYTE	endS																			*
 *			UBYTE	endF																			*
 *			UBYTE	chan																			*
 * OUTPUT:                                                                 *
 *			none																					*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/27/1994 SW : Created.                                              *
 *=========================================================================*/


VOID  RedBookClass::PlayMSF(UBYTE startM, UBYTE startS, UBYTE startF, UBYTE endM, UBYTE endS, UBYTE endF, UBYTE chan)
{

	Play.Start = MSFtoRed(startM, startS, startF);
	Play.CntSect  = RedToHS(MSFtoRed(endM, endS, endF)) - RedToHS(Play.Start) - 1;

//	WriteRealMem(REALPTR(Play_addrp) << 16, &Play, sizeof(PlayType));
	Mem_Copy ( &Play , (void *) ( Play_addrp.seg << 4 ) , sizeof(PlayType));

	regs.x.eax = 0x1510;
	regs.x.ecx = cdDrive[0];
	regs.x.ebx = offsetof (PlayType, Length);
	sregs.es 	= Play_addrp.seg;

	DPMI_real_intr(0x2F, &regs, &sregs);

//	ReadRealMem(&Play, REALPTR(Play_addrp) << 16, sizeof(PlayType));
	Mem_Copy ( (void *) ( Play_addrp.seg << 4 ) , &Play, sizeof(PlayType));

	FullCDVolume(chan);

}

/***************************************************************************
 * CheckCDMusic -- Check for CD playing					   						*
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *    	UBYTE	startM			  										 					*
 *			UBYTE	startS					  													*
 *			UBYTE	startF					  													*
 *    	UBYTE	endM				  										 					*
 *			UBYTE	endS						  													*
 *			UBYTE	endF						  													*
 *			UBYTE	chan						  													*
 * OUTPUT:                                             							*
 *			UWORD	TRUE if playing else FALSE                 						*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/27/1994 SW : Created.                                              *
 *=========================================================================*/


UWORD  RedBookClass::CheckCDMusic(VOID)
{
	
	Stat.TrnsAdOff = offsetof	(StatType, StatInfo);
	Stat.TrnsAdSeg = Stat_addrp.seg;

//	WriteRealMem(REALPTR(Stat_addrp) << 16, &Stat, sizeof(StatType));
	Mem_Copy ( &Stat , (void *) ( Stat_addrp.seg << 4 ) , sizeof(StatType));

	regs.x.ecx = cdDrive[0];
	regs.x.ebx = offsetof (StatType, Length);
	regs.x.eax = 0x1510;
	sregs.es 	= Stat_addrp.seg;

	DPMI_real_intr(0x2F, &regs, &sregs);

//	ReadRealMem(&Stat, REALPTR(Stat_addrp) << 16, sizeof(StatType));
	Mem_Copy ( (void *) ( Stat_addrp.seg << 4 ) , &Stat, sizeof(StatType));

	return (Stat.Status&0x200);
}

/***************************************************************************
 * STOPCDMUSIC -- stop CD playing                                          *
 *                                                                         *
 *                                                                         *
 *                                                                         *
 * INPUT:                                                                  *
 *		none							  															*
 * OUTPUT:                                                                 *
 *		none							  															*
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   05/27/1994  SW : Created.                                             *
 *=========================================================================*/

VOID  RedBookClass::StopCDMusic(VOID)
{

//	WriteRealMem(REALPTR(Stop_addrp) << 16, &Stop, sizeof(StopType));
	Mem_Copy ( &Stop , (void *) ( Stop_addrp.seg << 4 ) , sizeof(StopType));

	regs.x.eax = 0x1510;
	regs.x.ecx = cdDrive[0];
	regs.x.ebx = offsetof (StopType, Length);
	sregs.es 	= Stop_addrp.seg;

	DPMI_real_intr(0x2F, &regs, &sregs);

//	ReadRealMem(&Stop, REALPTR(Stop_addrp) << 16, sizeof(StopType));
	Mem_Copy ( (void *) ( Stop_addrp.seg << 4 ) , &Stop, sizeof(StopType));

}

