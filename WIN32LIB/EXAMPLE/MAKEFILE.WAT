#
#	Command & Conquer Red Alert(tm)
#	Copyright 2025 Electronic Arts Inc.
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#***************************************************************************
#**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
#***************************************************************************
#*                                                                         *
#*                 Project Name : Westwood Library .EXE makefile	   *
#*                                                                         *
#*                    File Name : MAKEFILE                                 *
#*                                                                         *
#*                   Programmer : Julio R. Jerez			   *
#*                                                                         *
#*                   Start Date : Jan 20, 1995  	                   *
#*                                                                         *
#*                  Last Update : 			                   *
#*                                                                         *
#*-------------------------------------------------------------------------*
#*                                                                         *
#* Required environment variables:					   *
#* WWFLAT	= your root WWFLAT path					   *
#* WWVCS	= root directory for wwlib version control archive	   *
#* WATCOM	= your Watcom installation path				   *
#*                                                                         *
#*									   *
#* Required changes to makefile:					   *
#* PROJ_NAME	= name of the executable program you're building 	   *
#* PROJ_LIBS	= Westwood libraries to link your EXE to 	           *
#* OBJECTS	= list of objects in your current working directory	   *
#*                                                                         *
#* Optional changes to makefile:					   *
#* PROJ_DIR	= full pathname of your working directory		   *
#* .xxx:	= full pathname where various file types live		   *
#*                                                                         *
#***************************************************************************

#---------------------------------------------------------------------------
# Verify user's environment
#---------------------------------------------------------------------------
!ifndef %WWFLAT
!error WWFLAT Environment var not configured.
!endif


!ifndef %WWVCS  
!error WWVCS Environment var not configured.
!endif

!ifndef %WATCOM 
!error WATCOM Environment var not configured.
!endif


#===========================================================================
# User-defined section: the user should tailor this section for each project
#===========================================================================
#---------------------------------------------------------------------------
# PROJ_NAME = library name
# PROJ_DIR = directory containing source & objects
#---------------------------------------------------------------------------
PROJ_NAME	= TEST
PROJ_DIR	= $(%WWFLAT)\example\TEST
LIB_DIR	        = $(%WWFLAT)\lib

!include $(%WWFLAT)\project.cfg

#---------------------------------------------------------------------------
# Project-dependent variables
#---------------------------------------------------------------------------
OBJECTS = 		   	&
	main.obj		&
	startup.obj		&
	globals.obj

PROJ_LIBS = 			&
	    wwflat32.lib
	

#---------------------------------------------------------------------------
# Path macros: one path for each file type.
#	These paths are used to tell make where to find/put each file type.
#---------------------------------------------------------------------------
.asm:	 $(PROJ_DIR)
.c:   	 $(PROJ_DIR)
.cpp:	 $(PROJ_DIR)
.h:   	 $(PROJ_DIR)
.obj:	 $(PROJ_DIR)
.lib:	 $(%WWFLAT)\lib
.exe:	 $(PROJ_DIR)


#---------------------------------------------------------------------------
# Tools/commands
#---------------------------------------------------------------------------
C_CMD	  	= wcc386
CPP_CMD	  	= wpp386
LIB_CMD	  	= wlib
LINK_CMD  	= wlink
ASM_CMD	  	= tasm32

#---------------------------------------------------------------------------
# Include & library paths
# If LIB & INCLUDE are already defined, they are used in addition to the
# WWLIB32 lib & include; otherwise, they're constructed from
# BCDIR 
#---------------------------------------------------------------------------

LIBPATH	  	= $(%WWFLAT)\LIB;$(%WATCOM)\LIB
INCLUDEPATH	= $(%WWFLAT)\INCLUDE;$(%WATCOM)\H

#---------------------------------------------------------------------------
# Implicit rules
# Compiler: 
# 	($< = full dependent with path)
# Assembler:
# 	output obj's are constructed from .obj: & the $& macro
# 	($< = full dependent with path)
# 	tasm's cfg file is not invoked as a response file.
#---------------------------------------------------------------------------

.c.obj:	$(%WWFLAT)\project.cfg .AUTODEPEND 
	$(C_CMD) $(CC_CFG) $<

.cpp.obj: $(%WWFLAT)\project.cfg .AUTODEPEND 
	$(CPP_CMD) $(CC_CFG) $<

.asm.obj: $(%WWFLAT)\project.cfg
	$(ASM_CMD) $(ASM_CFG) $<

#---------------------------------------------------------------------------
# Default target
#---------------------------------------------------------------------------
all:	$(PROJ_NAME).exe 

#---------------------------------------------------------------------------
# Build the EXE
#---------------------------------------------------------------------------
$(PROJ_NAME).exe: $(OBJECTS)  $(PROJ_NAME).lnk $(PROJ_LIBS)
	 $(LINK_CMD) $(LINK_CFG) system dos4g name $^@ @$(PROJ_NAME).lnk


$(PROJ_LIBS):		
	echo updating base library $^@
	cd ..
	wmake
	cd $(PROJ_DIR)


$(PROJ_NAME).lnk : $(OBJECTS)
       %create $^@
       for %index in ($(OBJECTS))  do %append $^@ file %index
       for %index in ($(PROJ_LIBS)) do %append $^@ library $(LIB_DIR)\%index

#**************************** End of makefile ******************************


