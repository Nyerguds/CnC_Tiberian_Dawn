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
# PROJECT
#     VQAPlay 32-bit library.
#
# FILE
#     makefile (Watcom C/C++ 10.0a)
#
# DESCRIPTION
#     Makefile for generating the 32-bit VQAPlay library.
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
# PROJECTS DEPENDENT MACROS
#----------------------------------------------------------------------------

PRJNAME = vqa32wp
PRJDIR  = $(%PRJ)\VQA32

OBJECTS = &
	config.obj &
	task.obj &
	loader.obj &
	drawer.obj &
	audio.obj &
	monodisp.obj &
	dstream.obj &
	unvqbuff.obj &
	unvqvesa.obj &
	vertag.obj &
	caption.obj &
#	unvqxmde.obj

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
.h : $(path_h)
.asm : $(path_asm)
.i : $(path_i)
.obj : $(path_obj)
.lib : $(path_lib)
.exe : $(path_exe)

#----------------------------------------------------------------------------
# Tools/commands & configurations
#----------------------------------------------------------------------------

CC_CMD   = wcc386
CCP_CMD  = wpp386
ASM_CMD  = tasm32
LINK_CMD = wlink
LIB_CMD  = wlib

CC_OPTS  = -i$(INCLUDEPATH) -j -zp1 -5s -mf -oaeilrt -s -zq
ASM_OPTS = /t /m /w+ /jJUMPS /ml /p /z /i$(%PRJ)\INCLUDE\VQM32 /dPHARLAP_TNT=0
LIB_OPTS = /b /c /q
LINK_CFG = $(PRJNAME).lnk

#----------------------------------------------------------------------------
# DEFAULT TARGET
#----------------------------------------------------------------------------

all : $(PRJNAME).lib .SYMBOLIC

$(PRJNAME).lib : $(OBJECTS) .SYMBOLIC

#----------------------------------------------------------------------------
# IMPLICIT RULES
#----------------------------------------------------------------------------

.c.obj :
  $(CC_CMD) $(CC_OPTS) -fo=$(PATH_OBJ)\$^. $<
	$(LIB_CMD) $(LIB_OPTS) $(path_lib)\$(PRJNAME).lib -+$(path_obj)\$]&

.cpp.obj :
  $(CCP_CMD) $(CC_OPTS) -fo=$(PATH_OBJ)\$^. $<
	$(LIB_CMD) $(LIB_OPTS) $(path_lib)\$(PRJNAME).lib -+$(path_obj)\$]&

.asm.obj:
	$(ASM_CMD) $(ASM_OPTS) $<,$(path_obj)\$^.
	$(LIB_CMD) $(LIB_OPTS) $(path_lib)\$(PRJNAME).lib -+$(path_obj)\$]&

update: .SYMBOLIC
	@echo Updating VQAPlay32 header files!
	@copy vqaplay.h ..\include\vqa32 >NUL
	@copy vqafile.h ..\include\vqa32 >NUL

