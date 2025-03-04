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

/***********************************************************************************************
 ***             C O N F I D E N T I A L  ---  W E S T W O O D   S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Keyboard Test Program                              			  *
 *                                                                                             *
 *                    File Name : TEST.CPP                                                     *
 *                                                                                             *
 *                   Programmer : Phil Gorrow                                                  *
 *                                                                                             *
 *                   Start Date : October 10, 1995                                             *
 *                                                                                             *
 *                  Last Update : October 16, 1995 [PWG]                                       *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *  WndProc			-- Callback procedure for main window                                      *
 *  WinMain 		-- Program entry point                                                     *
 *   Init_Keyboard_Remap_Table -- initializes the keyboard remap table     *
 *   WWKeyboardClass::WWKeyBoardClass -- Construction for Westwood Keyboard* 
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <misc.h>
#include <stdio.h>
#include "keyboard.h"

#define	NAME			"DRAWBUFF test"
#define	TITLE			"DRAWBUFF library test"
BOOL Running = TRUE;
HANDLE ThreadHandle;
BOOL MessageLoopThread = FALSE;
#define	MODE_WIDTH	640						// Width in pixels of required video mode
#define	MODE_HEIGHT	400						// Height in pixels of required video mode
void Message_Loop(void);
HANDLE ActiveEvent;
WWKeyboardClass Kbd;
#if(0)
#define	VK_NONE_00			  0x00
#define	VK_LBUTTON          0x01
#define	VK_RBUTTON          0x02
#define	VK_CANCEL           0x03
#define	VK_MBUTTON          0x04
#define	VK_NONE_05			  0x05
#define	VK_NONE_06			  0x06
#define	VK_NONE_07			  0x07
#define	VK_BACK             0x08
#define	VK_TAB              0x09
#define	VK_NONE_0A			  0x0A
#define	VK_NONE_0B			  0x0B
#define	VK_CLEAR            0x0C
#define	VK_RETURN           0x0D
#define	VK_NONE_0E			  0x0E
#define	VK_NONE_0F			  0x0F
#define	VK_SHIFT            0x10
#define	VK_CONTROL          0x11
#define	VK_MENU             0x12
#define	VK_PAUSE            0x13
#define	VK_CAPITAL          0x14
#define	VK_NONE_15			  0x15
#define	VK_NONE_16			  0x16
#define	VK_NONE_17			  0x17
#define	VK_NONE_18			  0x18
#define	VK_NONE_19			  0x19
#define	VK_NONE_1A			  0x1A
#define	VK_ESCAPE           0x1B
#define	VK_NONE_1C			  0x1C
#define	VK_NONE_1D			  0x1D
#define	VK_NONE_1E			  0x1E
#define	VK_NONE_1F			  0x1F
#define	VK_SPACE            0x20
#define	VK_PRIOR            0x21
#define	VK_NEXT             0x22
#define	VK_END              0x23
#define	VK_HOME             0x24
#define	VK_LEFT             0x25
#define	VK_UP               0x26
#define	VK_RIGHT            0x27
#define	VK_DOWN             0x28
#define	VK_SELECT           0x29
#define	VK_PRINT            0x2A
#define	VK_EXECUTE          0x2B
#define	VK_SNAPSHOT         0x2C
#define	VK_INSERT           0x2D
#define	VK_DELETE           0x2E
#define	VK_HELP             0x2F
#define	VK_0					  0x30
#define	VK_1					  0x31
#define	VK_2					  0x32
#define	VK_3					  0x33
#define	VK_4					  0x34
#define	VK_5					  0x35
#define	VK_6					  0x36
#define	VK_7					  0x37
#define	VK_8					  0x38
#define	VK_9					  0x39
#define	VK_0					  0x3A
#define	VK_NONE_3B			  0x3B
#define	VK_NONE_3C			  0x3C
#define	VK_NONE_3D			  0x3D
#define	VK_NONE_3E			  0x3E
#define	VK_NONE_3F			  0x3F
#define	VK_NONE_40			  0x40
#define	VK_A					  0x41
#define	VK_B					  0x42
#define	VK_C					  0x43
#define	VK_D					  0x44
#define	VK_E					  0x45
#define	VK_F					  0x46
#define	VK_G					  0x47
#define	VK_H					  0x48
#define	VK_I					  0x49
#define	VK_J					  0x4A
#define	VK_K					  0x4B
#define	VK_L					  0x4C
#define	VK_M					  0x4D
#define	VK_N					  0x4E
#define	VK_O					  0x4F
#define	VK_P					  0x50
#define	VK_Q					  0x51
#define	VK_R					  0x52
#define	VK_S					  0x53
#define	VK_T					  0x54
#define	VK_U					  0x55
#define	VK_V					  0x56
#define	VK_W					  0x57
#define	VK_X					  0x58
#define	VK_Y					  0x59
#define	VK_Z					  0x5A
#define	VK_NONE_5B			  0x5B
#define	VK_NONE_5C			  0x5C
#define	VK_NONE_5D			  0x5D
#define	VK_NONE_5E			  0x5E
#define	VK_NONE_5F			  0x5F
#define	VK_NUMPAD0          0x60
#define	VK_NUMPAD1          0x61
#define	VK_NUMPAD2          0x62
#define	VK_NUMPAD3          0x63
#define	VK_NUMPAD4          0x64
#define	VK_NUMPAD5          0x65
#define	VK_NUMPAD6          0x66
#define	VK_NUMPAD7          0x67
#define	VK_NUMPAD8          0x68
#define	VK_NUMPAD9          0x69
#define	VK_MULTIPLY         0x6A
#define	VK_ADD              0x6B
#define	VK_SEPARATOR        0x6C
#define	VK_SUBTRACT         0x6D
#define	VK_DECIMAL          0x6E
#define	VK_DIVIDE           0x6F
#define	VK_F1               0x70
#define	VK_F2               0x71
#define	VK_F3               0x72
#define	VK_F4               0x73
#define	VK_F5               0x74
#define	VK_F6               0x75
#define	VK_F7               0x76
#define	VK_F8               0x77
#define	VK_F9               0x78
#define	VK_F10              0x79
#define	VK_F11              0x7A
#define	VK_F12              0x7B
#define	VK_F13              0x7C
#define	VK_F14              0x7D
#define	VK_F15              0x7E
#define	VK_F16              0x7F
#define	VK_F17              0x80
#define	VK_F18              0x81
#define	VK_F19              0x82
#define	VK_F20              0x83
#define	VK_F21              0x84
#define	VK_F22              0x85
#define	VK_F23              0x86
#define	VK_F24              0x87
#define	VK_NONE_88          0x88
#define	VK_NONE_89          0x89
#define	VK_NONE_8A          0x8A
#define	VK_NONE_8B          0x8B
#define	VK_NONE_8C          0x8C
#define	VK_NONE_8D          0x8D
#define	VK_NONE_8E          0x8E
#define	VK_NONE_8F          0x8F
#define	VK_NUMLOCK          0x90
#define	VK_SCROLL           0x91
#define	VK_NONE_92			  0x92
#define	VK_NONE_93			  0x93
#define	VK_NONE_94			  0x94
#define	VK_NONE_95			  0x95
#define	VK_NONE_96			  0x96
#define	VK_NONE_97			  0x97
#define	VK_NONE_98			  0x98
#define	VK_NONE_99			  0x99
#define	VK_NONE_9A			  0x9A
#define	VK_NONE_9B			  0x9B
#define	VK_NONE_9C			  0x9C
#define	VK_NONE_9D			  0x9D
#define	VK_NONE_9E			  0x9E
#define	VK_NONE_9F			  0x9F
#define	VK_NONE_A0			  0xA0
#define	VK_NONE_A1			  0xA1
#define	VK_NONE_A2			  0xA2
#define	VK_NONE_A3			  0xA3
#define	VK_NONE_A4			  0xA4
#define	VK_NONE_A5			  0xA5
#define	VK_NONE_A6			  0xA6
#define	VK_NONE_A7			  0xA7
#define	VK_NONE_A8			  0xA8
#define	VK_NONE_A9			  0xA9
#define	VK_NONE_AA			  0xAA
#define	VK_NONE_AB			  0xAB
#define	VK_NONE_AC			  0xAC
#define	VK_NONE_AD			  0xAD
#define	VK_NONE_AE			  0xAE
#define	VK_NONE_AF			  0xAF
#define	VK_NONE_B0			  0xB0
#define	VK_NONE_B1			  0xB1
#define	VK_NONE_B2			  0xB2
#define	VK_NONE_B3			  0xB3
#define	VK_NONE_B4			  0xB4
#define	VK_NONE_B5			  0xB5
#define	VK_NONE_B6			  0xB6
#define	VK_NONE_B7			  0xB7
#define	VK_NONE_B8			  0xB8
#define	VK_NONE_B9			  0xB9
#define	VK_NONE_BA			  0xBA
#define	VK_NONE_BB			  0xBB
#define	VK_NONE_BC			  0xBC
#define	VK_NONE_BD			  0xBD
#define	VK_NONE_BE			  0xBE
#define	VK_NONE_BF			  0xBF
#define	VK_NONE_C0			  0xC0
#define	VK_NONE_C1			  0xC1
#define	VK_NONE_C2			  0xC2
#define	VK_NONE_C3			  0xC3
#define	VK_NONE_C4			  0xC4
#define	VK_NONE_C5			  0xC5
#define	VK_NONE_C6			  0xC6
#define	VK_NONE_C7			  0xC7
#define	VK_NONE_C8			  0xC8
#define	VK_NONE_C9			  0xC9
#define	VK_NONE_CA			  0xCA
#define	VK_NONE_CB			  0xCB
#define	VK_NONE_CC			  0xCC
#define	VK_NONE_CD			  0xCD
#define	VK_NONE_CE			  0xCE
#define	VK_NONE_CF			  0xCF
#define	VK_NONE_D0			  0xD0
#define	VK_NONE_D1			  0xD1
#define	VK_NONE_D2			  0xD2
#define	VK_NONE_D3			  0xD3
#define	VK_NONE_D4			  0xD4
#define	VK_NONE_D5			  0xD5
#define	VK_NONE_D6			  0xD6
#define	VK_NONE_D7			  0xD7
#define	VK_NONE_D8			  0xD8
#define	VK_NONE_D9			  0xD9
#define	VK_NONE_DA			  0xDA
#define	VK_NONE_DB			  0xDB
#define	VK_NONE_DC			  0xDC
#define	VK_NONE_DD			  0xDD
#define	VK_NONE_DE			  0xDE
#define	VK_NONE_DF			  0xDF
#define	VK_NONE_E0			  0xE0
#define	VK_NONE_E1			  0xE1
#define	VK_NONE_E2			  0xE2
#define	VK_NONE_E3			  0xE3
#define	VK_NONE_E4			  0xE4
#define	VK_NONE_E5			  0xE5
#define	VK_NONE_E6			  0xE6
#define	VK_NONE_E7			  0xE7
#define	VK_NONE_E8			  0xE8
#define	VK_NONE_E9			  0xE9
#define	VK_NONE_EA			  0xEA
#define	VK_NONE_EB			  0xEB
#define	VK_NONE_EC			  0xEC
#define	VK_NONE_ED			  0xED
#define	VK_NONE_EE			  0xEE
#define	VK_NONE_EF			  0xEF
#define	VK_NONE_F0			  0xF0
#define	VK_NONE_F1			  0xF1
#define	VK_NONE_F2			  0xF2
#define	VK_NONE_F3			  0xF3
#define	VK_NONE_F4			  0xF4
#define	VK_NONE_F5			  0xF5
#define	VK_NONE_F6			  0xF6
#define	VK_NONE_F7			  0xF7
#define	VK_NONE_F8			  0xF8
#define	VK_NONE_F9			  0xF9
#define	VK_NONE_FA			  0xFA
#define	VK_NONE_FB			  0xFB
#define	VK_NONE_FC			  0xFC
#define	VK_NONE_FD			  0xFD
#define	VK_NONE_FE			  0xFE
#define	VK_NONE_FF			  0xFF
#endif

char *VK_Name[] = {
	"VK_NONE_00",
	"VK_LBUTTON",
	"VK_RBUTTON",
	"VK_CANCEL",
	"VK_MBUTTON",
	"VK_NONE_05",
	"VK_NONE_06",
	"VK_NONE_07",
	"VK_BACK",
	"VK_TAB",
	"VK_NONE_0A",
	"VK_NONE_0B",
	"VK_CLEAR",
	"VK_RETURN",
	"VK_NONE_0E",
	"VK_NONE_0F",
	"VK_SHIFT",
	"VK_CONTROL",
	"VK_MENU",
	"VK_PAUSE",
	"VK_CAPITAL",
	"VK_NONE_15",
	"VK_NONE_16",
	"VK_NONE_17",
	"VK_NONE_18",
	"VK_NONE_19",
	"VK_NONE_1A",
	"VK_ESCAPE",
	"VK_NONE_1C",
	"VK_NONE_1D",
	"VK_NONE_1E",
	"VK_NONE_1F",
	"VK_SPACE",
	"VK_PRIOR",
	"VK_NEXT",
	"VK_END",
	"VK_HOME",
	"VK_LEFT",
	"VK_UP",
	"VK_RIGHT",
	"VK_DOWN",
	"VK_SELECT",
	"VK_PRINT",
	"VK_EXECUTE",
	"VK_SNAPSHOT",
	"VK_INSERT",
	"VK_DELETE",
	"VK_HELP",
	"VK_0",
	"VK_1",
	"VK_2",
	"VK_3",
	"VK_4",
	"VK_5",
	"VK_6",
	"VK_7",
	"VK_8",
	"VK_9",
	"VK_0",
	"VK_NONE_3B",
	"VK_NONE_3C",
	"VK_NONE_3D",
	"VK_NONE_3E",
	"VK_NONE_3F",
	"VK_NONE_40",
	"VK_A",
	"VK_B",
	"VK_C",
	"VK_D",
	"VK_E",
	"VK_F",
	"VK_G",
	"VK_H",
	"VK_I",
	"VK_J",
	"VK_K",
	"VK_L",
	"VK_M",
	"VK_N",
	"VK_O",
	"VK_P",
	"VK_Q",
	"VK_R",
	"VK_S",
	"VK_T",
	"VK_U",
	"VK_V",
	"VK_W",
	"VK_X",
	"VK_Y",
	"VK_Z",
	"VK_NONE_5B",
	"VK_NONE_5C",
	"VK_NONE_5D",
	"VK_NONE_5E",
	"VK_NONE_5F",
	"VK_NUMPAD0",
	"VK_NUMPAD1",
	"VK_NUMPAD2",
	"VK_NUMPAD3",
	"VK_NUMPAD4",
	"VK_NUMPAD5",
	"VK_NUMPAD6",
	"VK_NUMPAD7",
	"VK_NUMPAD8",
	"VK_NUMPAD9",
	"VK_MULTIPLY",
	"VK_ADD",
	"VK_SEPARATOR",
	"VK_SUBTRACT",
	"VK_DECIMAL",
	"VK_DIVIDE",
	"VK_F1",
	"VK_F2",
	"VK_F3",
	"VK_F4",
	"VK_F5",
	"VK_F6",
	"VK_F7",
	"VK_F8",
	"VK_F9",
	"VK_F10",
	"VK_F11",
	"VK_F12",
	"VK_F13",
	"VK_F14",
	"VK_F15",
	"VK_F16",
	"VK_F17",
	"VK_F18",
	"VK_F19",
	"VK_F20",
	"VK_F21",
	"VK_F22",
	"VK_F23",
	"VK_F24",
	"VK_NONE_88",
	"VK_NONE_89",
	"VK_NONE_8A",
	"VK_NONE_8B",
	"VK_NONE_8C",
	"VK_NONE_8D",
	"VK_NONE_8E",
	"VK_NONE_8F",
	"VK_NUMLOCK",
	"VK_SCROLL",
	"VK_NONE_92",
	"VK_NONE_93",
	"VK_NONE_94",
	"VK_NONE_95",
	"VK_NONE_96",
	"VK_NONE_97",
	"VK_NONE_98",
	"VK_NONE_99",
	"VK_NONE_9A",
	"VK_NONE_9B",
	"VK_NONE_9C",
	"VK_NONE_9D",
	"VK_NONE_9E",
	"VK_NONE_9F",
	"VK_NONE_A0",
	"VK_NONE_A1",
	"VK_NONE_A2",
	"VK_NONE_A3",
	"VK_NONE_A4",
	"VK_NONE_A5",
	"VK_NONE_A6",
	"VK_NONE_A7",
	"VK_NONE_A8",
	"VK_NONE_A9",
	"VK_NONE_AA",
	"VK_NONE_AB",
	"VK_NONE_AC",
	"VK_NONE_AD",
	"VK_NONE_AE",
	"VK_NONE_AF",
	"VK_NONE_B0",
	"VK_NONE_B1",
	"VK_NONE_B2",
	"VK_NONE_B3",
	"VK_NONE_B4",
	"VK_NONE_B5",
	"VK_NONE_B6",
	"VK_NONE_B7",
	"VK_NONE_B8",
	"VK_NONE_B9",
	"VK_NONE_BA",
	"VK_NONE_BB",
	"VK_NONE_BC",
	"VK_NONE_BD",
	"VK_NONE_BE",
	"VK_NONE_BF",
	"VK_NONE_C0",
	"VK_NONE_C1",
	"VK_NONE_C2",
	"VK_NONE_C3",
	"VK_NONE_C4",
	"VK_NONE_C5",
	"VK_NONE_C6",
	"VK_NONE_C7",
	"VK_NONE_C8",
	"VK_NONE_C9",
	"VK_NONE_CA",
	"VK_NONE_CB",
	"VK_NONE_CC",
	"VK_NONE_CD",
	"VK_NONE_CE",
	"VK_NONE_CF",
	"VK_NONE_D0",
	"VK_NONE_D1",
	"VK_NONE_D2",
	"VK_NONE_D3",
	"VK_NONE_D4",
	"VK_NONE_D5",
	"VK_NONE_D6",
	"VK_NONE_D7",
	"VK_NONE_D8",
	"VK_NONE_D9",
	"VK_NONE_DA",
	"VK_NONE_DB",
	"VK_NONE_DC",
	"VK_NONE_DD",
	"VK_NONE_DE",
	"VK_NONE_DF",
	"VK_NONE_E0",
	"VK_NONE_E1",
	"VK_NONE_E2",
	"VK_NONE_E3",
	"VK_NONE_E4",
	"VK_NONE_E5",
	"VK_NONE_E6",
	"VK_NONE_E7",
	"VK_NONE_E8",
	"VK_NONE_E9",
	"VK_NONE_EA",
	"VK_NONE_EB",
	"VK_NONE_EC",
	"VK_NONE_ED",
	"VK_NONE_EE",
	"VK_NONE_EF",
	"VK_NONE_F0",
	"VK_NONE_F1",
	"VK_NONE_F2",
	"VK_NONE_F3",
	"VK_NONE_F4",
	"VK_NONE_F5",
	"VK_NONE_F6",
	"VK_NONE_F7",
	"VK_NONE_F8",
	"VK_NONE_F9",
	"VK_NONE_FA",
	"VK_NONE_FB",
	"VK_NONE_FC",
	"VK_NONE_FD",
	"VK_NONE_FE",
	"VK_NONE_FF",
};

char *_keyname[] = {
	"KN_NONE",
	"KN_GRAVE",
	"KN_1",
	"KN_2",
	"KN_3",
	"KN_4",
	"KN_5",
	"KN_6",
	"KN_7",
	"KN_8",
	"KN_9",
	"KN_0",
	"KN_MINUS",
	"KN_EQUAL",
	"KN_RESERVED1",
	"KN_BACKSPACE",
	"KN_TAB",
	"KN_Q",
	"KN_W",
	"KN_E",
	"KN_R",
	"KN_T",
	"KN_Y",
	"KN_U",
	"KN_I",
	"KN_O",
	"KN_P",
	"KN_LBRACKET",
	"KN_RBRACKET",
	"KN_BACKSLASH",
	"KN_CAPSLOCK",
	"KN_A",
	"KN_S",
	"KN_D",
	"KN_F",
	"KN_G",
	"KN_H",
	"KN_J",
	"KN_K",
	"KN_L",
	"KN_SEMICOLON",
	"KN_SQUOTE",
	"KN_BACKSLASH2",
	"KN_RETURN",
	"KN_LSHIFT",
	"KN_MOUSE_MOVE",
	"KN_Z",
	"KN_X",
	"KN_C",
	"KN_V",
	"KN_B",
	"KN_N",
	"KN_M",
	"KN_COMMA",								
	"KN_PERIOD",
	"KN_SLASH",
	"KN_RESERVED3",
	"KN_RSHIFT",
	"KN_LCTRL",
	"KN_LCOMM",
	"KN_LALT",
	"KN_SPACE",
	"KN_RALT",
	"KN_RCOMM",
	"KN_RCTRL",
	"KN_LMOUSE",
	"KN_RMOUSE",
	"KN_JBUTTON1",
	"KN_JBUTTON2",
	"KN_J_UP",
	"KN_J_RIGHT",
	"KN_J_DOWN",
	"KN_J_LEFT",
	"KN_SPECIAL9",
	"KN_SPECIAL10",
	"KN_E_INSERT",
	"KN_E_DELETE",
	"KN_RESERVED4",
	"KN_RESERVED5",
	"KN_E_LEFT",
	"KN_E_HOME",
	"KN_E_END",
	"KN_RESERVED6",
	"KN_E_UP",
	"KN_E_DOWN",
	"KN_E_PGUP",
	"KN_E_PGDN",
	"KN_K_LPAREN",
	"KN_K_RPAREN",
	"KN_E_RIGHT",
	"KN_NUMLOCK",
	"KN_HOME",
	"KN_UPLEFT/KN_HOME",
	"KN_LEFT",
	"KN_END",
	"KN_DOWNLEFT/KN_END",
	"KN_RESERVED7",
	"KN_KEYPAD_SLASH",						 
	"KN_UP",									 
	"KN_CENTER",								 
	"KN_DOWN",									 
	"KN_INSERT",								 
	"KN_KEYPAD_ASTERISK",					 
	"KN_PGUP",									 
	"KN_UPRIGHT/KN_PGUP",
	"KN_RIGHT",								 
	"KN_PGDN",									 
	"KN_DOWNRIGHT/KN_PGDN",
	"KN_DELETE",								 
	"KN_KEYPAD_MINUS",						 
	"KN_KEYPAD_PLUS",						 
	"KN_RESERVED8",
	"KN_KEYPAD_RETURN",						 
	"KN_RESERVED9",
	"KN_ESC",
	"KN_HELP",										
	"KN_F1",
	"KN_F2",
	"KN_F3",
	"KN_F4",
	"KN_F5",
	"KN_F6",
	"KN_F7",
	"KN_F8",
	"KN_F9",
	"KN_F10",
	"KN_F11",
	"KN_F12",
	"KN_PRNTSCRN",								
	"KN_SCROLLLOCK",								
	"KN_PAUSE"
};
char *_steve_translate[]={
		"?",
		"ESC-27",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0",
		"-",
		"=",
		"BACKSPACE",
		"TAB",
		"q",
		"w",
		"e",
		"r",
		"t",
		"y",
		"u",
		"i",
		"o",
		"p",
		"[",
		"]",
		"return",
		"?",
		"a",
		"s",
		"d",
		"f",
		"g",
		"h",
		"j",
		"k",
		"l",
		";",
		"'",
		"ESC-27",
		"?",
		"\\",
		"z",
		"x",
		"c",
		"v",
		"b",
		"n",
		"m",
		",",
		".",
		"/",
		"?",
		"*",
		"?",
		" ",
		"?",
		"f1-127",
		"127",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"7",
		"8",
		"9",
		"-",
		"4",
		"5",
		"6",
		"+",
		"1",
		"2",
		"3",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"F12",
};
static short   cxChar, cxCaps, cyChar;

/***********************************************************************************************
 * WndProc -- windows message callback                                                         *
 *                                                                                             *
 *   Pilfered from a windows example program - HELLOWIN.C                                      *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Standard Windoze callback parameters                                              *
 *                                                                                             *
 * OUTPUT:   long                                                                              *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    9/27/95 1:39PM ST : Pilfered                                                             *
 *=============================================================================================*/

long FAR PASCAL _export WndProc (HWND hwnd, UINT message, UINT wParam, LONG lParam)
{
	HDC				hdc;
	PAINTSTRUCT		ps;
	static int		line 	= 1;
	char 				buffer[100];
	TEXTMETRIC		tm;
	RECT				rect;
	int				transition;
	int				previous;
	int				context;
	int				extended;
	int				oem;
	int				rep;
	int				shift,ctrl,alt,caps,nums;
	int				vk_key;
	BYTE				remaptbl[256];
	WORD				key;
	char				srcstr[2];
	char				dststr[2];

	switch (message) {
		case WM_SYSKEYDOWN:
		case WM_SYSKEYUP:
			Kbd.Message_Handler(hwnd, message, wParam, lParam);
			break;

		case WM_KEYDOWN:
		case WM_KEYUP:
		case WM_LBUTTONDOWN:
		case WM_LBUTTONUP:
		case WM_LBUTTONDBLCLK:
		case WM_MBUTTONDOWN:
		case WM_MBUTTONUP:
		case WM_MBUTTONDBLCLK:
		case WM_RBUTTONDOWN:
		case WM_RBUTTONUP:
		case WM_RBUTTONDBLCLK:
			Kbd.Message_Handler(hwnd, message, wParam, lParam);
//			Message_Loop();
			return(0);

		case WM_CREATE:
			hdc = GetDC(hwnd);
			GetTextMetrics(hdc, &tm);
			cxChar = tm.tmAveCharWidth;
			cxCaps = (tm.tmPitchAndFamily & 1 ? 3 : 2) * cxChar / 2;
			cyChar = tm.tmHeight + tm.tmExternalLeading;
			ReleaseDC(hwnd, hdc);
			return(0);


  		case WM_PAINT:
			hdc = BeginPaint(hwnd, &ps);
			GetTextMetrics(hdc, &tm);
			EndPaint(hwnd, &ps);
			return(0);

//		case WM_CLOSE:
		case WM_DESTROY:
			Running = FALSE;
			WaitForSingleObject(ThreadHandle, INFINITE);
			PostQuitMessage (0);
			Reset_Video_Mode();
			return(0);
		case WM_ACTIVATEAPP:
			if ((BOOL)wParam)	{
				SetEvent(ActiveEvent);
			} else {
				ResetEvent(ActiveEvent);				
			}
			break;
	}

	if (line == 23) {
		InvalidateRect(hwnd, NULL, TRUE);
		line = 1;
	}

	return DefWindowProc (hwnd, message, wParam, lParam) ;
}

void Message_Loop(void)
{
	int					key,shift,ctrl,alt,rls,dbl;
	char					buffer[255];
	HDC				hdc;
	static int				line=0;

	while (Running) {
		WaitForSingleObject(ActiveEvent, INFINITE);
		if (Kbd.Check()) {
			int key = Kbd.Get();
			if (key & WWKEY_VK_BIT) {
				Kbd.Split(key, shift, ctrl, alt,rls,dbl);
				if (!Kbd.Is_Mouse_Key(key)) {
					sprintf(buffer, "Key (VK) = %d (%s)  shift = %d  control = %d  menu = %d  rls = %d  dbl = %d", key, VK_Name[key], shift, ctrl, alt, rls, dbl);
					if (key == 27)	{
						PostMessage (MainWindow, WM_DESTROY,0,0);
					}
				} else {
					sprintf(buffer, "Mouse = %d @ (%d,%d) shift = %d  control = %d  menu = %d", key, Kbd.MouseQX, Kbd.MouseQY, shift, ctrl, alt);
				}
			} else {
				Kbd.Split(key, shift, ctrl, alt, rls, dbl);
				sprintf(buffer, "Key (ACSII) = %d (%c)  shift = %d  control = %d  menu = %d  rls = %d  dbl = %d", key, key, shift, ctrl, alt, rls, dbl);
			}
			hdc = GetDC(MainWindow);
			TextOut(hdc, cxChar, cyChar * (line + 1), buffer, lstrlen(buffer));
			sprintf(buffer, "Mouses current status:  x = %3d,  y = %3d", Kbd.Get_Mouse_X(), Kbd.Get_Mouse_Y());
			TextOut(hdc, cxChar, cyChar * (1), buffer, lstrlen(buffer));
			line++;
			if (line == 23) {
				InvalidateRect(MainWindow, NULL, TRUE);
				line = 1;
			}
			ReleaseDC(MainWindow, hdc);
		}
	}

}	

/***********************************************************************************************
 * WinMain -- Program entry point                                                              *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Standard Windows startup parameters                                               *
 *                                                                                             *
 * OUTPUT:   msg.wParam                                                                        *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    9/27/95 1:28PM ST : Created                                                              *
 *=============================================================================================*/

int PASCAL WinMain (HANDLE hInstance, HANDLE hPrevInstance,
						  LPSTR /*lpszCmdParam*/, int nCmdShow)
{
	HWND        		hwnd ;
	WNDCLASS    		wndclass ;
	MSG         		msg ;
	int					i,j,k;
	int					key,shift,ctrl,alt,rls,dbl;
	char					buffer[255];
	HDC				hdc;

	//
	// Register the window class
	//

	if (!hPrevInstance)
		{
		wndclass.style         = CS_HREDRAW | CS_VREDRAW ;
		wndclass.lpfnWndProc   = WndProc ;
		wndclass.cbClsExtra    = 0 ;
		wndclass.cbWndExtra    = 0 ;
		wndclass.hInstance     = hInstance ;
		wndclass.hIcon         = LoadIcon (hInstance, IDI_APPLICATION) ;
		wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
		wndclass.hbrBackground = GetStockObject(WHITE_BRUSH);
		wndclass.lpszMenuName  = NULL;
		wndclass.lpszClassName = NAME;

		RegisterClass (&wndclass) ;
	}


	//
	// Create our main window
	//
	hwnd = MainWindow = CreateWindowEx (
							WS_EX_TOPMOST,
							NAME,
							TITLE,
							WS_POPUP | WS_MAXIMIZE,
							0,
							0,
							MODE_WIDTH,
							MODE_HEIGHT,
							NULL,
							NULL,
							hInstance,
							NULL );

	ShowWindow (hwnd, nCmdShow) ;
	UpdateWindow (hwnd) ;
	SetFocus (hwnd);

	Set_Video_Mode( MainWindow , MODE_WIDTH , MODE_HEIGHT , 8 );
//	ShowWindow (hwnd, nCmdShow) ;
//	UpdateWindow (hwnd) ;
//	SetFocus (hwnd);
								// (Dangerous  if Windoze can change the handle)

//	Set_Video_Mode( MainWindow , MODE_WIDTH , MODE_HEIGHT , 8 );
#if(TRUE)
	DWORD threadid;
	ActiveEvent = CreateEvent(NULL, TRUE, TRUE, "Active Event");
	ThreadHandle = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)Message_Loop, NULL, 0, &threadid);
	if (!ThreadHandle)	{
		DWORD error = GetLastError();
		sprintf(buffer, "Last Error was equal to %d", error);
		MessageBox(hwnd, buffer,"Error",MB_ICONEXCLAMATION|MB_OK);
		return(0);
	}
#endif

	while (1) {
		if (!GetMessage(&msg, NULL, 0, 0)) {
			break;
		}
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return(0);
//	return msg.wParam;
}



