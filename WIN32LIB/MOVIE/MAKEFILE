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

#* $Header$
#***********************************************************************************************
#***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
#***********************************************************************************************
#*                                                                                             *
#*                 Project Name : Command & Conquer                                            *
#*                                                                                             *
#*                    File Name : MAKEFILE                                                     *
#*                                                                                             *
#*                   Programmer : Joe L. Bostic                                                *
#*                                                                                             *
#*                   Start Date : 03/02/95                                                     *
#*                                                                                             *
#*                  Last Update : March 2, 1995 [JLB]                                          *
#*                                                                                             *
#*---------------------------------------------------------------------------------------------*
#* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *

.SILENT
.OPTIMIZE
.ERASE

#---------------------------------------------------------------------------
# Working values depending on what target executable will be created.
#---------------------------------------------------------------------------
OBJ=obj
CC=..\..\WAT11\BINNT\wpp386
LIB=..\..\WATCOM\BINNT\wlib

#---------------------------------------------------------------------------
# Path macros: one path for each file type.
#  These paths are used to tell make where to find/put each file type.
#---------------------------------------------------------------------------
.cpp:  .
.h:    .
.obj:  $(OBJ)


#===========================================================================
# Compiler and assembler flags.
#===========================================================================
CC_CFG = /d0                            # No debugging information
CC_CFG += /DWIN32=1
CC_CFG += /D_WIN32
CC_CFG += /i=..\..\dxmedia\include
CC_CFG += /i=..\..\dxmedia\classes\base
CC_CFG += /i=..\..\dxsdk\inc
CC_CFG += /i=..\..\wat11\h\nt                # NT include directory.
CC_CFG += /i=..\..\wat11\H                   # Normal Watcom include directory.
CC_CFG += /bt=NT
CC_CFG += /otxan
CC_CFG += /5r                           # Pentium optimized register calling conventions.
CC_CFG += /of+                          # Generate traceable stack frames.
CC_CFG += /zp1                          # Pack structures on byte boundary.
CC_CFG += /s                            # Remove stack check calls.
CC_CFG += /j                            # char is now signed.
CC_CFG += /fhq
CC_CFG += /we                           # Treat all warnings as errors.
CC_CFG += /w8                           # Most warnings enabled.
CC_CFG += /ri                           # char and shorts are returned as int.
CC_CFG += /zq                           # Operate quietly.

#---------------------------------------------------------------------------
# Implicit rules
# Compiler:
# 	($< = full dependent with path)
# Assembler:
# 	output obj's are constructed from .obj: & the $& macro
# 	($< = full dependent with path)
# 	tasm's cfg file is not invoked as a response file.
#---------------------------------------------------------------------------

.c.obj: .AUTODEPEND
	echo Compiling $<
	*$(CC) $(CC_CFG) -fo$(OBJ)\$^. $<

.cpp.obj: .AUTODEPEND
	echo Compiling $<
	*$(CC) $(CC_CFG) -fo$(OBJ)\$^. $<

#---------------------------------------------------------------------------
# Object modules.
#---------------------------------------------------------------------------
OBJECTS = &
	movie.obj

############################################################################
# If there is an abnormal termination in make process (e.g., error in compile).
.ERROR


#############################################################################
# Default target
all: mpeg.lib


#############################################################################
# Builds the MPEG.LIB file.
mpeg.lib: $(OBJECTS) mpeg.lnk
	$(LIB) -c $^@ @mpeg.lnk

mpeg.lnk: makefile
	%create $^@
	for %index in ($(OBJECTS))  do %append $^@ -+ $(OBJ)\%index
