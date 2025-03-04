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
 *                  Last Update : January 12, 1995   [PWG]                 *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Find_Video_Mode -- Converts a dos video mode to a WWLIB video mode    *
 *   Get_Video_Mode -- Returns the current video mode.                     *
 *   Set_Video_Mode -- Sets the requested video mode                       *
 *   Set_Lores_Function_Pointers -- Sets up the lowres function pointers   *
 *   Set_HiRes_Function_Pointers -- Sets the HiRes function pointers       *
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


/***************************************************************************
 * VESA_INFO -- Debug routine which displays vesa info to stdout           *
 *                                                                         *
 * INPUT:		none                                                        *
 *                                                                         *
 * OUTPUT:     none                                                        *
 *                                                                         *
 * WARNINGS:   																				*
 *																									*
 *                                                                         *
 * HISTORY:                                                                *
 *   11/22/1994 PWG : Created.                                             *
 *=========================================================================*/
void Vesa_Info(int vesa_mode)
{
	UINT         paras;
	USHORT   	 longest ;
   union REGS 	 regs;
   struct SREGS sregs;
	SEGSEL		   VInfoSel ;			 
	VesaInfoType *	VInfo ;
	SEGSEL		 	ModeInfoSel ;
	VesaModeInfoType * ModeInfo ;			 
	unsigned   temp ;
	short		* ptr ;
	char       buff [ 256 ] ;
	short mode_table [][4] = { { 0x100 , 640 , 400 , 256 }, 
					  				   { 0x101 , 640 , 480 , 256 },							  
									   { 0x103 , 800 , 600 , 256 },							  
									 } ;

	cout << "\n\nWWESTWOOD STUDIOS. Vesa Driver attributes.\n" ;

	// verifie that this is a standard VESA MODE
	if ( (vesa_mode < VESA_640X400_256) || ( vesa_mode > VESA_TEXT_132X60 )) {
	  cout << "this is not a standard VESA mode\n" ;
	  return ;
	}

	// Compute size of VesaInfo structure in paragraphs 
	paras = ( sizeof(VesaInfoType) + 15 ) >> 4 ;
	
	// Alloc real-mode memory for VESA structure. 
   if ( DPMI_real_alloc ( paras , & VInfoSel  , & longest ) ) return ;
	VInfo = ( VesaInfoType * ) ( VInfoSel . seg << 4 ) ;

	// Compute size of VesaModeInfo structure in paragraphs 
	paras = ( sizeof(VesaModeInfoType) + 15 ) >> 4 ;

	//Alloc real-mode memory for VesaModeInfoType structure. 
   if ( DPMI_real_alloc ( paras , & ModeInfoSel , & longest ) ) 
	{ 
		DPMI_real_free	( VInfoSel ) ;
		return ;
	}
	ModeInfo = ( VesaModeInfoType * ) ( ModeInfoSel . seg << 4 ) ;

	// Get Read Vesa Driver Vesa
	regs . x . eax = 0x4f00 ;	
	regs . x . edi = 0 ;
	sregs . es = VInfoSel . seg ;
   DPMI_real_intr ( 0x10 , & regs , & sregs );

	regs . x . eax &= 0xffff ;
	if ( regs . x . eax != 0x004F) {
	  cout << "\nNot Vesa Driver Present\n" ;
	  DPMI_real_free	( ModeInfoSel ) ;
  	  DPMI_real_free	( VInfoSel ) ;
	  return	;
	}

	temp = ( unsigned ) VInfo->AvailModes ;
	ptr = ( short * ) ( ( ( temp & 0xffff0000 ) >> 12 ) + ( temp & 0xffff ) ) ;
	cout << "Available Video Modes\n" ;
	for ( ; * ptr != -1 ; ptr ++ ) 
	 for ( temp = 0 ; temp < 3 ; temp ++ )	
		 if ( * ptr == mode_table [ temp ] [ 0 ] ) {
			sprintf ( buff , "%d\t%d x %d x %d\n" ,  
							      mode_table [ temp ] [ 0 ],
							      mode_table [ temp ] [ 1 ],
							      mode_table [ temp ] [ 2 ],
							      mode_table [ temp ] [ 3 ] ) ;
			cout << buff ;
		 }

   // Get Info for this particular graphic mode
  	regs . x . eax = 0x4F01;
  	regs . x . ecx = vesa_mode;
  	regs . x . edi = 0 ;
  	sregs . es = ModeInfoSel . seg ;
   DPMI_real_intr ( 0x10 , & regs , & sregs );
	regs . x . eax &= 0xffff ;
	if ( regs . x . eax != 0x004F) {
	  cout << "\nGraphic mode " << vesa_mode << " is not supported by this video card\n" ;
	  DPMI_real_free	( ModeInfoSel ) ;
  	  DPMI_real_free	( VInfoSel ) ;
	  return	;
	}

	cout << "\nMode attributes\n" ;
	temp = ( unsigned ) ModeInfo->Attributes ;
	if ( temp & 0x01 ) cout << "\tMode supported in hardware\n" ;
	else				    cout << "\tMode is not supported in hardware\n" ;
	if ( temp & 0x20 ) cout << "\tMode is not VGA Windowed memory compatible\n" ;
	else				    cout << "\tMode is VGA Windowed memory compatible\n" ;

	cout << "Window A attributes\n" ;
	temp = ( unsigned ) ModeInfo->WinA_Attributes; ;
	if ( temp & 0x02 ) cout << "\tWindow A is Readable\n" ;
	else				    cout << "\tWindow A is not Readable\n" ;
	if ( temp & 0x04 ) cout << "\tWindow A is Writeable\n" ;
	else				    cout << "\tWindow A is not Writeable\n" ;
	sprintf ( buff , "%P\n" , ModeInfo->WinA_Segment ) ;
	cout << "\tWindow A segment address 0x" << buff + 4 ;



	cout << "Window B attributes\n" ;
	temp = ( unsigned ) ModeInfo->WinB_Attributes; ;
	if ( temp & 0x02 ) cout << "\tWindow B is Readable\n" ;
	else				    cout << "\tWindow B is not Readable\n" ;
	if ( temp & 0x04 ) cout << "\tWindow B is Writeable\n" ;
	else				    cout << "\tWindow B is not Writeable\n" ;
	sprintf ( buff , "%P\n" , ModeInfo->WinB_Segment ) ;
	cout << "\tWindow B segment address 0x" << buff + 4 ;

	cout << "Window shared attributes\n" ;
	cout << "\tWindow Granularity (KB) :"	<< ModeInfo->WinGranularity << "\n" ;
	cout << "\tWindow Size (KB) : " << ModeInfo->WinSize	<< "\n";
	cout << "\tNumber of Banks : " << (long)ModeInfo->NumBanks << "\n";
	cout << "\tBytes per ScanLine : " << (long)ModeInfo->BytesPerScanline << "\n";
	cout << "\tXResolution : " << (long)ModeInfo->XRes << "\n";
	cout << "\tYResolution : " << (long)ModeInfo->YRes << "\n";
	cout << "\tX Char Size : " << (long)ModeInfo->XCharSize << "\n";
	cout << "\tY Char Size : " << (long)ModeInfo->YCharSize << "\n";
	cout << "\tMemory Model : " << (long)ModeInfo->MemoryModel << "\n";
	cout << "\tNumber of planes : " << (long)ModeInfo->NumPlanes << "\n"	;
	cout << "\tBits per pixels : " << (long)ModeInfo->BitsPerPixel	<< "\n" ;


/*
	cout	<< "Bttributes:                    " << (long)ModeInfo.Bttributes			<< "\n"
			<< "Win B Bttributes:              " << (long)ModeInfo.WinB_Bttributes	<< "\n"
			<< "Win B Bttributes:              " << (long)ModeInfo.WinB_Bttributes	<< "\n"
			<< "Win Granularity                " << (long)ModeInfo.WinGranularity   << "\n"
			<< "Win Size:                      " << (long)ModeInfo.WinSize				<< "\n"
			<< "Win B Segment:                 " << hex << (unsigned short)ModeInfo.WinB_Segment		<< "\n"
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
*/
  	DPMI_real_free	( ModeInfoSel ) ;
  	DPMI_real_free	( VInfoSel ) ;
}
