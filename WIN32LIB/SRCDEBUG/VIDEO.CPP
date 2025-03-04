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
 *                 Project Name : LIBRARY                                  *
 *                                                                         *
 *                    File Name : VIDEO.C                                  *
 *                                                                         *
 *                   Programmer : David Dettmer                            *
 *                                                                         *
 *                  Last Update : June 29, 1995   [PWG]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Find_Video_Mode -- Converts a dos video mode to a WWLIB video mode    *
 *   Get_Video_Mode -- Returns the current video mode.                     *
 *   Set_Video_Mode -- Sets the requested video mode                       *
 *   Set_Lores_Function_Pointers -- Sets up the lowres function pointers   *
 *   Set_HiRes_Function_Pointers -- Sets the HiRes function pointers       *
 *   Set_Original_Video_Mode -- sets mode to restore system to on exit     *
 *   Get_Original_Video_Mode -- Gets the original video mode value         *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <dos.h>
#include "iostream.h"
#include "video.h"
#include "descmgmt.h"
#include "mcgaprim.h"
#include "gbuffer.h"
#include "vbuffer.h"
#include "wwmem.h"

#include "playcd.h"

extern "C" int MInstalled ;
extern "C" void Hide_Mouse(void);
extern "C" void Show_Mouse(void);

extern "C" void Reset_Mouse (void) ;
extern "C" int  Vesa_Hook ( REALPTR function ) ;
extern "C" void Remove_Vesa (void) ;
extern "C" SEGSEL	 RMVesaVectorSel ;
extern "C" REALPTR VesaFunc;

/*=========================================================================*/
/* Define the global variables that we require.										*/
/*=========================================================================*/
long				BankTable[MAX_BANK_ENTRIES];
int				GraphicMode				= UNINITIALIZED_MODE;
long				XRes						= 0;
long				YRes						= 0;
REALPTR			VesaFunc;
unsigned long 	RMVesaVector ;
unsigned	long	RMVesaRegs ;

/*=========================================================================*
 * Private Varirables																		*
 *																									*
 * VInfo      - Protected mode copy of VInfo structure.							*
 * ModeInfo   - Protected mode copy of ModeInfo structure.						*
 * rpModeInfo - Real ptr to ModeInfo structure in conventional memory.		*
 * rpVInfo    - Real ptr to VInfo structure in conventional memory.			*
 * _regs      - Registers used for calling software interrupts.				*
 *=========================================================================*/
PRIVATE void 	* rpModeInfo  	= NULL;
PRIVATE SEGSEL	rpModeInfoSel ;
PRIVATE void 	* rpVInfo	  	= NULL;
PRIVATE SEGSEL	rpVInfoSel	  ;

PRIVATE long					_OriginalVideoMode	= UNINITIALIZED_MODE;
PRIVATE VesaInfoType 		VInfo;
PRIVATE VesaModeInfoType	ModeInfo;


/*=========================================================================*/
/* The following PRIVATE functions are in this file:                       */
/*=========================================================================*/

PRIVATE long Install_Vesa(void);
PRIVATE long Vesa_Get_Mode_Info(long mode);
PRIVATE long Vesa_Set_Mode(long mode);
PRIVATE void Init_Bank_Table(void);
PRIVATE VOID Set_LoRes_Function_Pointers(VOID);
PRIVATE VOID Set_HiRes_Function_Pointers(VOID);

extern "C" long Vesa_XRes(void);
extern "C" long Vesa_YRes(void);

extern "C" char CurrentPalette  [ 256 * 3 ]	;
extern "C" char PaletteTable	  [ 1024 ] ;

/*= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =*/

/***************************************************************************
 * GET_VIDEO_MODE -- Returns the current video mode.                       *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     returns the graphic mode as a WWLIB library define          *
 *                                                                         *
 * WARNINGS:	none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   01/25/1994     : Created.                                             *
 *=========================================================================*/
int Get_Video_Mode(void)			
{
  union REGS 	 regs;

	if( GraphicMode == UNINITIALIZED_MODE ) 
	{		
		regs	. x . eax = 0xf00 ;		// get graphic mode
		int386 ( 0x10 , & regs , & regs ) ;
		return ( regs . w . ax & 0xff ) ;
	}
	return(GraphicMode);									// return the graphic mode
}		   

/***************************************************************************
 * Install_Vesa -- Initializes the vesa driver if it exists                *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     return -1 if error/VESA not supported.                      *
 *                                                                         *
 * WARNINGS:	This function will not work unless a vesa compatable driver *
 *					is installed in either hardware or software.						*
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE long Install_Vesa(void)
{
	UINT         paras;
	USHORT   	 longest ;
   union REGS 	 regs;
   struct SREGS sregs;

	/* Calculate size of VesaInfo structure in paragraphs */
	paras = ( sizeof(VesaInfoType) + 15 ) >> 4 ;
	
	/* Allocate real-mode memory for VESA structure. */
   if ( DPMI_real_alloc ( paras , & rpVInfoSel  , & longest ) ) return - 1 ;
	rpVInfo = ( void * ) ( rpVInfoSel . seg << 4 ) ;

	/* Calculate size of VesaModeInfo structure in paragraphs */
	paras = ( sizeof(VesaModeInfoType) + 15 ) >> 4 ;

	/* Allocate real-mode memory for VESA structure. */
   if ( DPMI_real_alloc ( paras , & rpModeInfoSel , & longest ) ) 
	{ 
		Remove_Vesa();
		return (-1);
	}
	rpModeInfo = ( void * ) ( rpModeInfoSel . seg << 4 ) ;

	/* Clear the input buffer */
	memset ( rpVInfo , 0 , sizeof ( VesaInfoType) ) ;

	
	/* Read Vesa information  */
	regs . x . eax = 0x4f00 ;	
	regs . x . edi = 0 ;
	sregs . es = rpVInfoSel . seg ;
   DPMI_real_intr ( 0x10 , & regs , & sregs );

	regs . x . eax &= 0xffff ;
	if ( regs . x . eax != 0x004F) return (-1);
	Mem_Copy ( rpVInfo , & VInfo , sizeof(VesaInfoType)) ;

	return 0;
}


/***************************************************************************
 * VESA_GET_MODE_INFO -- Gets info about specified video mode              *
 *                                                                         *
 * INPUT:		long - the mode we are requesting info about                *
 *                                                                         *
 * OUTPUT:     long - 0 if sucessful, -1 if failure                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE long Vesa_Get_Mode_Info(long mode)
{
   union REGS 	 regs;
   struct SREGS sregs;

	if (rpModeInfo ) 
	{
		/* Clear the input buffer */
		memset ( rpModeInfo, 0, sizeof(VesaModeInfoType));

		/* Set up function call */
		regs . x . eax = 0x4F01;
		regs . x . ecx = mode;
		regs . x . edi = 0 ;
		sregs . es = rpModeInfoSel . seg ;
   	DPMI_real_intr ( 0x10 , & regs , & sregs );

		regs . x . eax &= 0xffff ;
		if ( regs . x . eax == 0x004F)  
		{
			Mem_Copy ( rpModeInfo , &ModeInfo , sizeof(VesaModeInfoType));

		// this part is only temporary until Phil get the documentation
		//	for DPMI funtion 0x301 simulate real call
		// in the mean time we will be making call to the vesa driver
		// thru a real interrupt
		  if ( Vesa_Hook ( ModeInfo . WinFunc ) ) return ( -1 ) ;
		  return (0);
		}
	} 
  return (-1);
}

/***************************************************************************
 * VESA_SET_MODE -- Sets the specified Vesa mode                           *
 *                                                                         *
 * INPUT:		long - the mode we wish to set                              *
 *                                                                         *
 * OUTPUT:		long - 0 if all is ok, -1 if we cannot set this mode        *
 *                                                                         *
 * WARNINGS:	You must call Install_Vesa before calling Vesa_Set_Mode     *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE long Vesa_Set_Mode(long mode)
{
   union REGS 	 regs;
   struct SREGS sregs;

	/* Get mode info */
	if ( Vesa_Get_Mode_Info(mode) ) return (-1) ;

	if ((ModeInfo.Attributes & 0x01) == 0) return (-1);

	/* Set vesa VIDEO MODE */
	regs . x . eax = 0x4F02;				// 
	regs . x . ebx = mode;
	int386 ( 0x10 , & regs , & regs ) ;
//	delay ( 1000 ) ;

	if ( VInfo . Capabilities & 1 ) 
	{
		/* Set DAC to 6 bit per color register */ 
		regs . x . eax = 0x4F08;				 
		regs . h . bl  = 0;
		regs . h . bh = 6 ;
		int386 ( 0x10 , & regs , & regs ) ;
//		delay ( 1000 ) ;
	}

	regs . x . eax &= 0xffff ;
	if ( regs . x . eax != 0x004F) return (-1);

	Init_Bank_Table();
	return (0);

}

/***************************************************************************
 * VESA_XRES -- Returns horizontal resolution of vesa mode                 *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     long - the horizontal resolution of vesa mode               *
 *                                                                         *
 * WARNINGS:	You must call Install_Vesa and Vesa_Set_Mode before calling *
 *					Vesa_XRes().																*
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
long Vesa_XRes(void)
{
	return ((long)ModeInfo.XRes);
}

/***************************************************************************
 * VESA_YRES -- Returns vertical resolution of a vesa mode                 *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     long - the horizontal resolution of vesa mode               *
 *                                                                         *
 * WARNINGS:	You must call Install_Vesa and Vesa_Set_Mode before calling *
 *					Vesa_XRes().																*
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
long Vesa_YRes(void)
{
	return ((long)ModeInfo.YRes);
}

/***************************************************************************
 * INIT_BANK_TABLE -- Initializes the values in the bank table             *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/02/1994 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE void Init_Bank_Table(void)
{
	long	size,bankval;
	int	num_banks,lp;
	union REGS 	 regs;
   struct SREGS sregs;


	size			= Vesa_XRes() * Vesa_YRes();	// get video mode size
	num_banks	= size / 65536;					// get number of banks

	if (size % 65536) 								// adjust number of banks if
		num_banks++;									//   they dont break evenly

	bankval	= 64 / ModeInfo.WinGranularity;
	VesaFunc	= ModeInfo.WinFunc;

	for (lp = 0; lp < num_banks; lp++) 
		BankTable[lp] = lp * bankval;


	regs . x . eax = 0x4F05;				// Reset Vesa to Point to Bank 0
	regs . x . ebx = 0x0000;
	regs . x . edx = 0x0000;
	int386 ( 0x10 , & regs , & regs ) ;

}

/***************************************************************************
 * SET_MODE -- Used to set a graphic mode                             		*
 *                                                                         *
 * INPUT:	int  - the mode that we are setting                            *
 *                                                                         *
 * OUTPUT:  int  - FALSE if failure, TRUE otherwise                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   11/21/1994 PWG : Created.                                             *
 *=========================================================================*/
int Set_Video_Mode(int mode)
{
	union   REGS inregs,outregs;
	static  first_time = 0 ;
	int	  oldmode ;
 
	/*======================================================================*/
	/* If this is the first time we have set the mode we need to store		*/
	/*		of the original mode.															*/
	/*======================================================================*/
	if ( ! first_time ) {
		first_time = 1 ;
      Set_Original_Video_Mode(Get_Video_Mode());
  }
 
	/*======================================================================*/
	/* If the mode we are trying to set is mode zero than we are actually	*/
	/*		trying to restore the system to its original video mode.				*/
	/*======================================================================*/
	if (mode == RESET_MODE) 
		mode 	= Get_Original_Video_Mode();	// set mode properly

	if (mode == GraphicMode)			  	// if mode already correct
		return(TRUE);						  	//		get out of here

	oldmode = GraphicMode ;
	GraphicMode	= mode ;

	/**********************************************************************/
	/* make sure the mouse is term off before any change */
	/*********************************************************************/
	if ( MInstalled == TRUE ) Hide_Mouse () ;


	/* clear color palette */
	memset ( CurrentPalette  , 255 , sizeof ( CurrentPalette ) ) ;
	memset ( PaletteTable  , 0 , sizeof ( PaletteTable ) ) ;

	/*======================================================================*/
	/* If we are currently in a vesa mode, free it up so that we can do it	*/
	/*		again.																				*/
	/*======================================================================*/
	if ((oldmode >= VESA_MIN) && (oldmode <= VESA_MAX)) 
		Remove_Vesa();


	/*======================================================================*/
	/* If we are requesting a vesa mode, than use the vesa calls to handle	*/
	/*		it.																					*/
	/*======================================================================*/
	if ( GraphicMode >= VESA_MIN && GraphicMode <= VESA_MAX) 
	{
		inregs . x . eax = MCGA_MODE;
		int386 ( 0x10 , &inregs , &outregs);
//		delay ( 1000 ) ;

		if ( Install_Vesa () != 0 ) {
				Set_Video_Mode(oldmode);
				return(FALSE);
	  	}

		if (Vesa_Set_Mode(GraphicMode) != 0) 
		{
			Set_Video_Mode(oldmode);
			return(FALSE);
		}
		XRes = Vesa_XRes();
		YRes = Vesa_YRes();
		Set_HiRes_Function_Pointers();
	} 
	else 
	{
		/*===================================================================*/
		/* If not a vesa mode, then handle that as well.							*/
		/*===================================================================*/
		inregs . x . eax = GraphicMode ;
		int386( 0x10, &inregs, &outregs);
//		delay ( 1000 ) ;

		if ( GraphicMode == 	MCGA_MODE ) {
			XRes = 320;
			YRes = 200;
			Set_LoRes_Function_Pointers();
		}
	}
	if (  MInstalled == TRUE ) {
		Reset_Mouse () ;
		Show_Mouse () ;
	}
	return(TRUE);
}
/***************************************************************************
 * VESA_INFO -- Debug routine which displays vesa info to stdout           *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   Must call Install_Vesa before attempting to get the vesa		*
 *					info.																			*
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1994 PWG : Created.                                             *
 *=========================================================================*/
void Vesa_Info(void)
{
	cout	<< "Attributes:                    " << (long)ModeInfo.Attributes			<< "\n"
			<< "Win A Attributes:              " << (long)ModeInfo.WinA_Attributes	<< "\n"
			<< "Win B Attributes:              " << (long)ModeInfo.WinB_Attributes	<< "\n"
			<< "Win Granularity                " << (long)ModeInfo.WinGranularity   << "\n"
			<< "Win Size:                      " << (long)ModeInfo.WinSize				<< "\n"
			<< "Win A Segment:                 " << hex << (unsigned short)ModeInfo.WinA_Segment		<< "\n"
			<< "Win B Segment:                 " << (unsigned short)ModeInfo.WinB_Segment		<< "\n"
			<< "Bytes per scan line:           " << dec << (unsigned short)ModeInfo.BytesPerScanline	<< "\n"
			<< "X resolution:                  " << (long)ModeInfo.XRes					<< "\n"
			<< "Y resolution:                  " << (long)ModeInfo.YRes             << "\n"
			<< "X Char Size:                   " << (long)ModeInfo.XCharSize        << "\n"
			<< "Y Char Size:                   " << (long)ModeInfo.YCharSize        << "\n"
			<< "Number of planes:              " << (long)ModeInfo.NumPlanes			<< "\n"
			<< "Bits per pixels:               " << (long)ModeInfo.BitsPerPixel		<< "\n"
			<< "Number of Banks:               " << (long)ModeInfo.NumBanks			<< "\n"
			<< "Memory Model:                  " << (long)ModeInfo.MemoryModel		<< "\n"
			<< "Bank Size:                     " << (long)ModeInfo.BankSize         << "\n";
}


/***************************************************************************
 * VESA_SET_WINDOW -- Sets given vesa window to given grain                *
 *                                                                         *
 * INPUT:		int window	- 0 for window A, 1 for window B                *
 *					int grain   - the granularity point for window					*
 *                                                                         *
 * OUTPUT:		none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   12/05/1994 PWG : Created.                                             *
 *=========================================================================*/
void Vesa_Set_Window(long grain_num)
{
    union REGS 	 regs;
    struct SREGS sregs;

	regs . x . eax = 0x4f05 ;
	regs . x . ebx = 0 ;
	regs . x . edx = grain_num;
//	DPMI_real_call ( ModeInfo.WinFunc , & regs , & sregs ) ;
	DPMI_real_intr ( VesaFunc , & regs , & sregs ) ;

}


/***************************************************************************
 * SET_LORES_FUNCTION_POINTERS -- Sets up the lowres function pointers     *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   01/12/1995 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE VOID Set_LoRes_Function_Pointers(VOID)
{
	VVPC_Clear_Func			= MCGA_Clear;
	VVPC_To_Buffer_Func		= MCGA_To_Buffer;
	VVPC_Put_Pixel_Func		= MCGA_Put_Pixel;
	VVPC_Get_Pixel_Func		= MCGA_Get_Pixel;
	GVPC_Blit_to_VVPC_Func	= Linear_Blit_To_Linear;
	VVPC_Blit_to_GVPC_Func	= Linear_Blit_To_Linear;
	VVPC_Blit_to_VVPC_Func	= Linear_Blit_To_Linear;
	VVPC_Buffer_To_Page		= MCGA_Buffer_To_Page;
	GVPC_Scale_To_VVPC		= Linear_Scale_To_Linear;
	VVPC_Scale_To_GVPC		= Linear_Scale_To_Linear;
	VVPC_Scale_To_VVPC		= Linear_Scale_To_Linear;
	VVPC_Print_Func			= MCGA_Print;
}
/***************************************************************************
 * SET_HIRES_FUNCTION_POINTERS -- Sets the HiRes function pointers         *
 *                                                                         *
 * INPUT:                                                                  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   01/12/1995 PWG : Created.                                             *
 *=========================================================================*/
PRIVATE VOID Set_HiRes_Function_Pointers(VOID)
{
	VVPC_Clear_Func			= Vesa_Clear;
	VVPC_To_Buffer_Func		= Vesa_To_Buffer;
	VVPC_Put_Pixel_Func		= Vesa_Put_Pixel;
	VVPC_Get_Pixel_Func		= Vesa_Get_Pixel;
	GVPC_Blit_to_VVPC_Func	= Linear_Blit_To_Vesa;
	VVPC_Blit_to_GVPC_Func	= Vesa_Blit_To_Linear;
	VVPC_Blit_to_VVPC_Func	= Vesa_Blit_To_Vesa;
	VVPC_Buffer_To_Page		= Vesa_Buffer_To_Page;
	GVPC_Scale_To_VVPC		= Linear_Scale_To_Vesa;
	VVPC_Scale_To_GVPC		= Vesa_Scale_To_Linear;
	VVPC_Scale_To_VVPC		= Vesa_Scale_To_Vesa;
	VVPC_Print_Func			= Vesa_Print;
}

/***************************************************************************
 * Update_Video_Mode -- used to reprogram the current graphic mode afte    *
 * 							a task swicthing from windows								*
 *                                                                         *
 * INPUT:																						*
 *                                                                         *
 * OUTPUT:  																					*
 *                                                                         *
 * HISTORY:                                                                *
 *   03/18/94 JRJ : Created.                                               *
 *=========================================================================*/
void Update_Video_Mode (void) 
{
	union   REGS inregs,outregs;

	/* clear color palette */
	memset ( CurrentPalette  , 255 , sizeof ( CurrentPalette ) ) ;
	memset ( PaletteTable  , 0 , sizeof ( PaletteTable ) ) ;

 
	/**********************************************************************/
	/* make sure the mouse is term off before any change */
	/*********************************************************************/
	if ( MInstalled == TRUE ) 
								Hide_Mouse () ;

	/*======================================================================*/
	/* If we are requesting a vesa mode, than use the vesa calls to handle	*/
	/*		it.																					*/
	/*======================================================================*/
	if ( GraphicMode >= VESA_MIN && GraphicMode <= VESA_MAX) {
		inregs . x . eax = MCGA_MODE;
		int386 ( 0x10 , &inregs , &outregs);
		Vesa_Set_Mode(GraphicMode);  
	} 
	else {
		/*===================================================================*/
		/* If not a vesa mode, then handle that as well.							*/
		/*===================================================================*/
		inregs . x . eax = GraphicMode ;
		int386( 0x10, &inregs, &outregs);
	}
	if (  MInstalled == TRUE ) {
		Reset_Mouse () ;
		Show_Mouse () ;
	}
}


/***************************************************************************
 * SET_ORIGINAL_VIDEO_MODE -- sets mode to restore system to on exit       *
 *                                                                         *
 * INPUT:		int video mode number                                       *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/29/1995 PWG : Created.                                             *
 *=========================================================================*/
void Set_Original_Video_Mode(int mode)
{
	_OriginalVideoMode = mode;
}


/***************************************************************************
 * GET_ORIGINAL_VIDEO_MODE -- Gets the original video mode value           *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     int the video mode set when we entered                      *
 *                                                                         *
 * HISTORY:                                                                *
 *   06/29/1995 PWG : Created.                                             *
 *=========================================================================*/

int Get_Original_Video_Mode(void)
{
	return(_OriginalVideoMode);
}
