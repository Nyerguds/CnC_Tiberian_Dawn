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

#****************************************************************************
#
#        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
#
#----------------------------------------------------------------------------
#
# FILE
#     makefile (Watcom C/C++ 10.0a)
#
# DESCRIPTION
#     Makefile for test program
#
# PROGRAMMER
#     Denzil E. Long, Jr.
# 
# DATE
#     February 10, 1995
#
# ENVIROMENT
#     PRJ    - Projects path.
#     PRJVCS - Version control archive path.
#     WATCOM - Watcom C installation path.
#
#****************************************************************************

#----------------------------------------------------------------------------
# VERIFY ENVIROMENT
#----------------------------------------------------------------------------

!ifndef %PRJ || %PRJVCS || %WATCOM
!error Environment not configured.
!endif

.OPTIMIZE
.ERASE

#----------------------------------------------------------------------------
# PROJECT DEPENDENT MACROS
#----------------------------------------------------------------------------

PRJNAME = VPLAY4GW
PRJDIR  = $(%PRJ)\VPLAY32

OBJECTS = &
	plyvqa32.obj

#LIBRARYS = vqm32w.lib vqa32w.lib sosdw1cs.lib
LIBRARYS = vqm32wp.lib vqa32wp.lib sosdw1ps.lib

#----------------------------------------------------------------------------
# PATH MACROS
#----------------------------------------------------------------------------

!ifdef %LIB
LIBPATH = $(%PRJ)\LIB;$(%LIB)
!else
LIBPATH = $(%PRJ)\LIB;$(%WATCOM)\LIB386
!endif

!ifdef %INCLUDE
INCLUDEPATH = $(%PRJ)\INCLUDE;$(%INCLUDE)
!else
INCLUDEPATH = $(%PRJ)\INCLUDE;$(%WATCOM)\H
!endif

path_c   = .\
path_cpp = .\
path_h   = .\
path_asm = .\
path_i   = .\
path_obj = .\O
path_lib = $(%PRJ)\LIB
path_exe = .\

#----------------------------------------------------------------------------
# IMPLICIT RULE EXTENSIONS AND PATHS
#----------------------------------------------------------------------------

.EXTENSIONS :
.EXTENSIONS : .exe .lib .obj .c .cpp .asm .h .i

.c : $(path_c)
.cpp : $(path_cpp)
.cpp : $(path_cpp)
.h : $(path_h)
.asm : $(path_asm)
.i : $(path_i)
.obj : $(path_obj)
.lib : $(path_lib)
.exe : $(path_exe)

#----------------------------------------------------------------------------
# TOOLS, COMMANDS AND CONFIGURATIONS
#----------------------------------------------------------------------------

CC_CMD   = wcc386
CCP_CMD  = wpp386
ASM_CMD  = tasm32
LINK_CMD = wlink
LIB_CMD  = wlib

CC_OPTS  = -i$(INCLUDEPATH) -j -zp1 -5s -mf -oaeilrt -s -zq
ASM_OPTS = /t /m /w+ /jJUMPS /ml /p /z /dPHARLAP_TNT=0
LIB_OPTS = /b /c /q /t
LINK_CFG = $(PRJNAME).lnk

#----------------------------------------------------------------------------
# DEFAULT TARGET
#----------------------------------------------------------------------------

all : $(LINK_CFG) $(PRJNAME).exe .SYMBOLIC

#----------------------------------------------------------------------------
# IMPLICIT RULES
#----------------------------------------------------------------------------

.c.obj :
  $(CC_CMD) $(CC_OPTS) -fo=$(PATH_OBJ)\$^. $<

.cpp.obj :
  $(CCP_CMD) $(CC_OPTS) -fo=$(PATH_OBJ)\$^. $<

.asm.obj :
	$(ASM_CMD) $(ASM_OPTS) $<,$(path_obj)\$^.

#----------------------------------------------------------------------------
# BUILD THE APPLICATION
#----------------------------------------------------------------------------

$(PRJNAME).exe : $(OBJECTS) $(LIBRARYS) $(LINK_CFG)
	$(LINK_CMD) @$(LINK_CFG)

#----------------------------------------------------------------------------
# LINKER CONFIGURATION
#----------------------------------------------------------------------------

$(LINK_CFG) : makefile
	@echo Updating $(LINK_CFG)!
	@%create $(LINK_CFG)
	@%write $(LINK_CFG) SYSTEM dos4g
	@%write $(LINK_CFG) OPTION map
	@%write $(LINK_CFG) NAME $(PRJNAME)
	@%write $(LINK_CFG) DEBUG ALL
	@%write $(LINK_CFG) LIBPATH $(LIBPATH)
	@for %i in ($(OBJECTS)) do @%write $(LINK_CFG) FILE $(path_obj)\%i
	@for %i in ($(LIBRARYS)) do @%write $(LINK_CFG) LIBRARY %i

