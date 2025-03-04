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
#*                 Project Name : Westwood Library .LIB makefile	   		*
#*                                                                         *
#*                    File Name : MAKEFILE                                 *
#*                                                                         *
#*                   Programmer : Julio R. Jerez			   					*
#*                                                                         *
#*                   Start Date : Jan 26, 1995                           	*
#*                                                                         *
#*                                                                         *
#*-------------------------------------------------------------------------*
#*                                                                         *
#* Required environment variables:					   								*
#* WIN32LIB		= your root WIN32LIB path					   							*
#* WIN32VCS		= root directory for wwlib version control archive	   		*
#* COMPILER		= your Watcom installation path				   					*
#*									   															*
#* Required changes to makefile:					   									*
#* PROJ_NAME	= name of the library you're building			   				*
#* OBJECTS		= list of objects in your library			   					*
#*                                                                         *
#* Optional changes to makefile:					   									*
#* PROJ_DIR		= full pathname of your working directory		   				*
#* .path.xxx	= full pathname where various file types live		   		*
#*                                                                         *
#***************************************************************************

#---------------------------------------------------------------------------
# Verify user's environment
#---------------------------------------------------------------------------
!ifndef %WIN32LIB
!error WIN32LIB Environment var not configured.
!endif

!ifndef %WIN32VCS
!error WIN32VCS Environment var not configured.
!endif

!ifndef %WATCOM
!error WATCOM Environment var not configured.
!endif


#===========================================================================
# User-defined section: the user should tailor this section for each project
#===========================================================================

PROJ_NAME   = mem
PROJ_DIR    = $(%WIN32LIB)\$(PROJ_NAME)
LIB_DIR	    = $(%WIN32LIB)\lib

!include $(%WIN32LIB)\project.cfg

CC_CFG += /zm									# Each routine to be in its own segment.

#---------------------------------------------------------------------------
# Project-dependent variables
#---------------------------------------------------------------------------
OBJECTS = 		&
	alloc.obj  	&
	mem.obj  	&
	newdel.obj  	&
	mem_copy.obj	&
	vmpagein.obj

#---------------------------------------------------------------------------
# Path macros: one path for each file type.
#	These paths are used to tell make where to find/put each file type.
#---------------------------------------------------------------------------
.asm:	$(PROJ_DIR)
.c:	$(PROJ_DIR)
.cpp:	$(PROJ_DIR)
.h:	$(PROJ_DIR)
.obj:	$(PROJ_DIR)
.lib:	$(%WIN32LIB)\lib
.exe:	$(PROJ_DIR)

#===========================================================================
# Pre-defined section: there should be little need to modify this section.
#===========================================================================

#---------------------------------------------------------------------------
# Tools/commands
#---------------------------------------------------------------------------
C_CMD	  	= wcc386
CPP_CMD	  	= wpp386
LIB_CMD	  	= wlib
LINK_CMD  	= wlink
ASM_CMD	  	= tasm

#---------------------------------------------------------------------------
# Include & library paths
#	If LIB & INCLUDE are already defined, they are used in addition to the
#	WWLIB32 lib & include; otherwise, they're constructed from
#	BCDIR & TNTDIR
#---------------------------------------------------------------------------
LIBPATH	  	= $(%WIN32LIB)\LIB;$(%WATCOM)\LIB
INCLUDEPATH	= $(%WIN32LIB)\INCLUDE;$(%WATCOM)\H


#---------------------------------------------------------------------------
# Implicit rules
# Compiler:
# 	($< = full dependent with path)
# Assembler:
# 	output obj's are constructed from .obj: & the $& macro
# 	($< = full dependent with path)
# 	tasm's cfg file is not invoked as a response file.
#---------------------------------------------------------------------------

.c.obj:	$(%WIN32LIB)\project.cfg .AUTODEPEND
	*$(C_CMD) $(CC_CFG) $<

.cpp.obj: $(%WIN32LIB)\project.cfg .AUTODEPEND
	*$(CPP_CMD) $(CC_CFG) $(PROJ_DIR)\$^*.cpp

.asm.obj: $(%WIN32LIB)\project.cfg
	$(ASM_CMD) $(ASM_CFG) $<


#---------------------------------------------------------------------------
# Default target: configuration files & library (in that order)
#---------------------------------------------------------------------------
all:	$(LIB_DIR)\$(PROJ_NAME).lib .SYMBOLIC

#---------------------------------------------------------------------------
# Build the library
# The original library is deleted by the librarian
# Lib objects & -+ commands are constructed by substituting within the
# $^@ macro (which expands to all target dependents, separated with
# spaces)
# Tlib's cfg file is not invoked as a response file.
# All headers & source files are copied into WIN32LIB\SRCDEBUG, for debugging
#---------------------------------------------------------------------------
$(LIB_DIR)\$(PROJ_NAME).lib: $(OBJECTS) objects.lbc
	 copy *.h   $(%WIN32LIB)\include
	 copy *.inc $(%WIN32LIB)\include
	 copy *.cpp $(%WIN32LIB)\srcdebug
	 copy *.asm $(%WIN32LIB)\srcdebug
	$(LIB_CMD) $(LIB_CFG) $^@ @objects.lbc

#---------------------------------------------------------------------------
# Objects now have a link file which is NOT generated everytime.  Instead
# it just has its own dependacy rule.
#---------------------------------------------------------------------------
objects.lbc : $(OBJECTS)
	      %create $^@
	      for %index in ($(OBJECTS)) do %append $^@ +%index


#---------------------------------------------------------------------------
# Create the test directory and make it.
#---------------------------------------------------------------------------
test:
	mkdir test
	cd test
	copy $(%WWVCS)\$(PROJ_NAME)\test\vcs.cfg
	update
	wmake
	cd ..

#**************************** End of makefile ******************************

