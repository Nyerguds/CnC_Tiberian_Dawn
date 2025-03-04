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
 *                 Project Name : Virtual Monopoly                         *
 *                                                                         *
 *                    File Name : DEBUG.CPP                                *
 *                                                                         *
 *                   Programmer : Michael Legg                             *
 *                                                                         *
 *                   Start Date : November 22, 1994                        *
 *                                                                         *
 *                  Last Update : May 30, 1995   [ML]                      *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Get_And_Display_Windows_Debug -- GetWinDebugInfo() called for checking*
 *   Debug_Mono_Message -- Post a line to the monochrome monitor           *
 *   Debug_Window_Message -- One of many ways to pop up a debug msg window *
 *   Debug_Show_Palette -- Display the current 256 color palette           *
 *   Debug_Draw_Line_Test -- Tests Westwood library Draw_Line()            *
 *   Debug_Put_Pixel_Test -- Tests the Westwood library Put_Pixel()        *
 *   Debug_Shape_Test -- Tests the Westwood Library Draw_Shape()           *
 *   Debug_Print_Game_Stats -- Code to display player stats w/ text        *
 *   Debug_Rig_Roll -- Pops up dialog to fix the next dice roll            *
 *   Debug_Adjust_Players_Cash -- Changes the current players money        *
 *   Debug_Rig_Roll_Dialog_Procedure -- Handles commands to dialog         *
 *   Debug_Adjust_Cash_Dialog_Proc -- Handles dialog messages for this     *
 *   Debug_Mono_Print_Whose_Turn -- Displays current turn on MONO display  *
 *   Build_Debug_Log_File_Name -- Based on the date and time of system     *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
#include "function.h"
#include "debug.rh"
#include "strings.rh"

#if( RIG_ROLL_FOR_PLAYTEST )
VOID Debug_Rig_Roll( WindowHandle window_handle );
PRIVATE BOOL Debug_Rig_Roll_Dialog_Procedure( WindowHandle window_handle,
															 UINT message,
															 WPARAM w_param,
															 LPARAM l_param );
#endif

#if( DEBUG_CODE )
/*
	public functions
*/
VOID Get_And_Display_Windows_Debug_Info( BYTE *command_line_string );
VOID Debug_Mono_Message( BYTE *message );
//VOID Debug_Window_Message( BYTE *message );
VOID Debug_Show_Palette( VOID );
VOID Debug_Draw_Line_Test( VOID );
VOID Debug_Put_Pixel_Test( VOID );
VOID Debug_Shape_Test( VOID );
VOID Debug_Print_Game_Stats( VOID );
VOID Debug_Adjust_Players_Cash( WindowHandle window_handle );
VOID Debug_Mono_Print_Whose_Turn( PlayerType player );
VOID Build_Debug_Log_File_Name( BYTE *name_string );

/*
	private functions
*/
PRIVATE BOOL Debug_Adjust_Cash_Dialog_Procedure( WindowHandle window_handle,
																 UINT message,
																 WPARAM w_param,
																 LPARAM l_param );
#endif



#if( DEBUG_CHECKSUM_ALL_SITES_DATA )
PRIVATE VOID Give_To_The_Mikes( VOID );
#endif

#if( DEBUG_CODE )
/*
	code begins...
*/

/***************************************************************************
 * DEBUG_MONO_MESSAGE -- Post a line to the monochrome monitor             *
 *                                                                         *
 * INPUT: the message to print                                             *
 *                                                                         *
 * OUTPUT: a message on the monochrome monitor display                     *
 *                                                                         *
 * WARNINGS: try to end messages with \r\n!                                *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
#pragma argsused
VOID Debug_Mono_Message( BYTE *message )
{
	#if( DEBUG_LOG_TO_MONO_DISPLAY )
		BYTE *temp_string;
		BYTE *temp_null_position;
		BYTE temp_char;	
		INT length_left;
	#endif
	#if( DEBUG_LOG_TO_FILE )
		INT fh;
		static BOOL _errored_once = FALSE;
		BYTE name_path_string[ _MAX_PATH ];
      BOOL danger;
	#endif

	#if( DEBUG_LOG_TO_FILE )

		danger = Danger_Test_Hard_Drive_Space();

		if ( ! _errored_once && ! danger ) {

			if ( *(Executable_Path+0) != '\0' ) {
				sprintf( name_path_string,
							"%s%s",
							Executable_Path,
							Debug_Log_File_Name );
				fh = Open_File( name_path_string, READ|WRITE );
				if ( fh == FILEOPENERROR || fh == -1 ) {
					sprintf( Text_String,
								"Unable to open %s for WRITE.\r\n",
								Debug_Log_File_Name );
					#if( DEBUG_CODE )
						Debug_Error_Window_Message( Text_String );
               #endif
					_errored_once = TRUE;
				}
				else {
					Seek_File( fh, 0, SEEK_END );
					Write_File( (INT)fh, (BYTE *)message, (ULONG)(strlen(message)) );
					Close_File( fh );
				}
			}
		}
	#endif


	#if( DEBUG_LOG_TO_MONO_DISPLAY )

		if ( ! Debug_Mono_Messages ) {
			return;
		}

		if ( ! Windows_95_Detected_Flag ) {
			OutputDebugString( "." );
		}
//		else {
//			Monochrome_Output( "> " );
//		}

		length_left = strlen( message );
		temp_null_position = message;
		while ( length_left > 80 ) {
			temp_string = temp_null_position;
			temp_null_position += 80;
			temp_char = *temp_null_position;
			temp_null_position[ 0 ] = '\0';

			if ( Windows_95_Detected_Flag ) {
				Monochrome_Output( temp_string );
			}
			else {
				OutputDebugString( temp_string );
			}

			*temp_null_position = temp_char;
			length_left -= 80;
		}
		temp_string = temp_null_position;

		if ( Windows_95_Detected_Flag ) {
			Monochrome_Output( temp_string );
		}
		else {
			OutputDebugString( temp_string );
		}

	#endif

}

/***************************************************************************
 * DEBUG_SHOW_PALETTE -- Display the current 256 color palette             *
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Show_Palette( VOID )
{
	#define PIXEL_SIZE 19
	INT i, j, x, y;
	UBYTE color;
	DeviceContextHandle screen_dc;

	if ( Game_Is_Now_Currently_Interrupted ) {
		Standard_Window_Message( "Game_Is_Now_Currently_Interrupted = TRUE", "X" );
		if ( Current_Interrupting_Player > NO_PLAYER ) {
			sprintf( Text_String,
						"Current_Interrupting_Player = %s\r\n",
						Players[ Current_Interrupting_Player ].Get_Name() );
		}
		else {
			sprintf( Text_String,
						"Current_Interrupting_Player = unknown\r\n" );
		}
		Standard_Window_Message( Text_String, "X" );
	}
	else {
		Standard_Window_Message( "Game_Is_Now_Currently_Interrupted = FALSE", "X" );
	}

	color = 0;
	for ( i = 0; i < 16; i ++ ) { 
		for ( j = 0; j < 16; j ++ ) { 
			x = VQ_MOVIE_X + (j * PIXEL_SIZE);
			y = VQ_MOVIE_Y + (i * PIXEL_SIZE);
			Monopoly_Fill_Rect( x, y, x+PIXEL_SIZE-1, y+PIXEL_SIZE-1, COLOR_BLACK );
			Monopoly_Fill_Rect( x+1, y+1, x+PIXEL_SIZE-2, y+PIXEL_SIZE-2, color++ );
		}
	}

	screen_dc = GetDC( Main_Window_Handle );
//	WinGBitBlt( Screen_DC, 
	WinGBitBlt( screen_dc, 
					VQ_MOVIE_X, VQ_MOVIE_Y,
					VQ_MOVIE_WIDTH, 
					VQ_MOVIE_HEIGHT,
					WinG_DC, 
					VQ_MOVIE_X, VQ_MOVIE_Y );
	ReleaseDC( Main_Window_Handle, screen_dc );
}


/***************************************************************************
 * DEBUG_DRAW_LINE_TEST -- Tests Westwood library Draw_Line()              *
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: make sure WinG buffer is active!                              *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Draw_Line_Test( VOID )
{
#if( 0 )
//	INT x1=0, y1=0, x2=638, y2=438;
	INT x1, y1=0, x2=638, y2=438;
	
	for ( x1=0; x1<=638; x1+=10 ) {
		HidBuff_Class_Ptr->Draw_Line( x1,y1,x2,y2,255 );
		WinGBitBlt( Screen_DC, 
						min(x1,x2), min(y1,y2),
						abs(x2-x1)+1, 
						abs(y2-y1)+1,
						WinG_DC, 
						min(x1,x2), min(y1,y2) );
		x2-=10;
	}
	x1=0;
//	y1=0;
	x2=638;
	y2=438;
	for ( y1=0; y1<=438; y1+=10 ) {
	HidBuff_Class_Ptr->Draw_Line( x1,y1,x2,y2,255 );
		WinGBitBlt( Screen_DC, 
						min(x1,x2), min(y1,y2),
						abs(x2-x1)+1, 
						abs(y2-y1)+1,
						WinG_DC, 
						min(x1,x2), min(y1,y2) );
		y2-=10;
	}
#endif
}


/***************************************************************************
 * DEBUG_PUT_PIXEL_TEST -- Tests the Westwood library Put_Pixel()          *
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: Make sure WinG buffer is active                               *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Put_Pixel_Test( VOID )
{
#if( 0 )
	INT x = random( 640 );
	INT y = random( 440 );
	INT xweight=1; int yweight=1; 
	LONG i;
	static UBYTE color = 0;

	color++;
	for ( i=0; i<100000; i ++ ) {
	
		HidBuff_Class_Ptr->Put_Pixel( x, y, color );
		WinGBitBlt( Screen_DC, 
						x, y,
						1, 
						1,
						WinG_DC, 
						x, y );
		
		if ( x <= 0 ) {
			x = 0;
			xweight = 1;
		}
		if ( y <= 0 ) {
			y = 0;
			yweight = 1;
		}
		if ( x >= WING_BITMAP_WIDTH-1 ) {
			x = WING_BITMAP_WIDTH-1;
			xweight = -1;
		}
		if ( y >= WING_BITMAP_HEIGHT-1 ) {
			y = WING_BITMAP_HEIGHT-1;
			yweight = -1;
		}
		if ( xweight > 0 ) {
			/* 0-9 */
			/* 0-9 */
			if ( random( 10 ) <= 4 ) { 
				x ++;
			}
			else { /* 0 */
				x --;
			}
		}
		else {
			/* 0-9 */
			if ( random( 10 ) <= 4 ) { 
				x --;
			}
			else { /* 0 */
				x ++;
			}
		}
		if ( yweight > 0 ) {
			/* 0-9 */
			if ( random( 10 ) <= 4 ) { 
				y ++;
			}
			else { /* 0 */
				y --;
			}
		}
		else {
			/* 0-9 */
			if ( random( 10 ) <= 4 ) { 
				y --;
			}
			else { /* 0 */
				y ++;
			}
		}
	}
#endif
}


/***************************************************************************
 * DEBUG_SHAPE_TEST -- Tests the Westwood Library Draw_Shape()             *
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: Make sure the WinG buffer is active!                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Shape_Test( VOID )
{
#if( 0 )
	BYTE *shapebuf, *shapes;
	LONG fsize;
	CHAR *shape_ptr[ 37 ];
	INT i, j, x;

	INT wwfh;
	
	Debug_Mono_Message( "------------------------------------------\r\n" );
	sprintf( Text_String, "Mem before shape buff alloc(5000): %ld\r\n", Ram_Free( MEM_NORMAL ) );
	Debug_Mono_Message( Text_String );
	
	shapebuf = (char *) Alloc( 5000, MEM_NORMAL );
	
	sprintf( Text_String, "Mem after shape buff alloc(5000): %ld\r\n", Ram_Free( MEM_NORMAL ) );
	Debug_Mono_Message( Text_String );
	
	if ( shapebuf == NULL ) {
		Debug_Mono_Message("shapebuf alloc failed.\n");
	}
	Set_Shape_Buffer (shapebuf,5000);

	wwfh = Open_File( "MSW00.SHP", READ );
	sprintf( Text_String, "File opened with wwfh %d\r\n", wwfh );
	Debug_Mono_Message( Text_String );
	if( wwfh == -1 ) {
		Debug_Mono_Message("File not found\n");
	}
	fsize = File_Size( wwfh );
	sprintf( Text_String, "File_Size( %d ) = %d\r\n", wwfh, fsize );
	Debug_Mono_Message( Text_String );
	if ( fsize > 0 ) {
		shapes = (char *) Alloc( fsize, MEM_NORMAL );
		if( shapes == NULL) {
			Debug_Mono_Message("shapes alloc failed\n");
		}
		Read_File( wwfh, shapes, fsize ); 
		Close_File( wwfh );
	}
	
	sprintf( Text_String, "Mem after shapedata alloc: %ld\r\n", Ram_Free( MEM_NORMAL ) );
	Debug_Mono_Message( Text_String );

	for( i = 0; i <= 36; i++ ) {
		shape_ptr[ i ] = Get_Shape( shapes, i );
	}

	sprintf( Text_String, "Mem after all shapes alloc: %ld\r\n", Ram_Free( MEM_NORMAL ) );
	Debug_Mono_Message( Text_String );
	
	Free( shapes );
	
	x = -64;
	for ( j = 0; j < 20; j ++ ) {
		for ( i = 21; i <= 28; i ++ ) {
			Refresh_Board_BMP_On_Hid();
			if ( shape_ptr[ i ] ) {
//				Draw_Shape( HidBuff_Class_Ptr, shape_ptr[ i ], x, 71, SHAPE_NORMAL );
				Draw_Shape( HidBuff_Class_Ptr, shape_ptr[ i ], x, 0, SHAPE_SCALING, 340, 340 );
				HidBuff_Class_Ptr->Put_Pixel( x, 100, 3 );

				WinGBitBlt( Screen_DC, 
								x, 0,
								200, 200,
								WinG_DC, 
								x, 0 );
			}
			x += 4;
		}
	}
	if ( shape_ptr[ 0 ] ) {
		Refresh_Board_BMP_On_Hid();
//		Draw_Shape( HidBuff_Class_Ptr, shape_ptr[ 0 ], x, 71, SHAPE_NORMAL );
		Draw_Shape( HidBuff_Class_Ptr, shape_ptr[ 0 ], x, 0, SHAPE_SCALING, 340, 340 );
		HidBuff_Class_Ptr->Put_Pixel( x, 100, 3 );
		WinGBitBlt( Screen_DC, 
						x, 0,
						200, 200,
						WinG_DC, 
						x, 0 );
	}

	for( i = 0; i <= 36; i++ ) {
		Free( shape_ptr[ i ] );
	}
	
	Free( shapebuf );

	sprintf( Text_String, "Mem when all done: %ld\r\n", Ram_Free( MEM_NORMAL ) );
	Debug_Mono_Message( Text_String );
	Debug_Mono_Message( "------------------------------------------\r\n" );
#endif
}

#if( 0 )
#define DEBUG_TEXT_X			4
#define DEBUG_TEXT_Y			12
#define DEBUG_TEXT_SPACING 13
/***************************************************************************
 * DEBUG_PRINT_GAME_STATS -- Code to display player stats w/ text          *
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Print_Game_Stats( VOID )
{
	INT i;
	INT x;
	INT y;
	PlayerType whos_turn;
	BYTE temp_token_string[ 50 ];
	BYTE temp_ai_string[ 50 ];
	BYTE temp_string[ 50 ];

	/*
		no game, no stats
	*/
	if ( ! Game_Status.Is_Game_In_Progress() ) {
		return;
	}

	x = DEBUG_TEXT_X;
	y = DEBUG_TEXT_Y;

	whos_turn = Game_Status.Get_Whos_Turn_Is_It_Now();

	SetTextAlign( Screen_DC, TA_LEFT ); 
	SelectObject( Screen_DC, GetStockObject( ANSI_VAR_FONT ) );
	SetTextCharacterExtra( Screen_DC, 0 );

	for ( i = PLAYER_1; i < TOTAL_PLAYERS; i ++ ) {
		if ( Players[ i ].Is_Active() ) {
			if ( whos_turn == i ) {
				strcpy( Text_String_2, "*" );
				rgb_vals = PALETTERGB( 0, 0, 255 );
			}
			else {
				strcpy( Text_String_2, " " );
				rgb_vals = WHITE_RGB_COLOR_REF;
			}

			sprintf( temp_string, "%d: ", i+1 );
			strcat( Text_String_2, temp_string );

			// grab token name
			if ( Players[ i ].Get_Token() >= TOKEN_FIRST ) {
				LoadString( Global_Instance_Handle, 
								STRING_TOKEN_FIRST + Players[ i ].Get_Token(),
								temp_token_string, 
								50 );
			}
			else {
				*temp_token_string = '\0';
			}

			// grab ai name
			if ( Players[ i ].Get_AI_Type() >= AI_FIRST ) {
				LoadString( Global_Instance_Handle, 
								STRING_AI_FIRST + Players[ i ].Get_AI_Type(),
								temp_ai_string, 
								50 );
			}
			else {
				*temp_ai_string = '\0';
			}

			sprintf( Text_String, 
						"%s%s, $%d, %s ",
						Text_String_2,
						Players[ i ].Get_Name(),
						Players[ i ].Get_Cash(),
						temp_token_string );

			SetTextColor( Screen_DC, rgb_vals );
			TextOut( Screen_DC, 
						x, 
						y,
						Text_String, 
						strlen( Text_String ) );

			/*
				now print liquid assets, available assets, tradable assets,
					total assets and monopolies...
			*/
			y += DEBUG_TEXT_SPACING;
			sprintf( Text_String, "     AI: $%s       ", temp_ai_string );
			TextOut( Screen_DC, 
						x, 
						y,
						Text_String, 
						strlen( Text_String ) );
			y += DEBUG_TEXT_SPACING;
			sprintf( Text_String, "     Liquid Assets: $%u       ", Players[ i ].Get_Liquid_Assets() );
			TextOut( Screen_DC, 
						x, 
						y,
						Text_String, 
						strlen( Text_String ) );
			y += DEBUG_TEXT_SPACING;
			sprintf( Text_String, "     Available Assets: $%u       ", Players[ i ].Get_Available_Assets() );
			TextOut( Screen_DC, 
						x, 
						y,
						Text_String, 
						strlen( Text_String ) );
//			y += DEBUG_TEXT_SPACING;
//			sprintf( Text_String, "   Tradable Assets: $%u       ", Players[ i ].Get_Tradable_Assets() );
//			TextOut( Screen_DC, 
//						x, 
//						y,
//						Text_String, 
//						strlen( Text_String ) );
			y += DEBUG_TEXT_SPACING;
			sprintf( Text_String, "     Total Assets: $%u       ", Players[ i ].Get_Total_Assets( FALSE ) );
			TextOut( Screen_DC, 
						x, 
						y,
						Text_String, 
						strlen( Text_String ) );
			y += DEBUG_TEXT_SPACING;
//			sprintf( Text_String, "     Monopolies: %u       ", Players[ i ].Get_Monopolies() );
//			TextOut( Screen_DC, 
//						x, 
//						y,
//						Text_String, 
//						strlen( Text_String ) );
//			y += DEBUG_TEXT_SPACING;
		}
	}

	/*
		Free parking!
	*/
	y += DEBUG_TEXT_SPACING;
	if ( Game_Status.Does_Free_Parking_Collect_Cash() ) {
		strcpy( Text_String_2, "Active" );
	}
	else {
		strcpy( Text_String_2, "Inactive" );
	}
	sprintf( Text_String,
				"Free Parking: $%d, %s      ",
				Game_Status.Get_Free_Parking_Money(),
				Text_String_2 );

	rgb_vals = BLACK_RGB_COLOR_REF;
	SetTextColor( Screen_DC, rgb_vals );
	TextOut( Screen_DC, 
				x, 
				y,
				Text_String, 
				strlen( Text_String ) );

	/*
		Bank
	*/
	y += DEBUG_TEXT_SPACING;
	sprintf( Text_String,
				"Bank: %d houses, %d hotels, $infinite      ",
				Bank.Get_Houses(),
				Bank.Get_Hotels() );
	TextOut( Screen_DC, 
				x, 
				y,
				Text_String, 
				strlen( Text_String ) );
}
#endif


/***************************************************************************
 * DEBUG_ADJUST_PLAYERS_CASH -- Changes the current players money          *
 *                                                                         *
 * INPUT: parent window handle                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Adjust_Players_Cash( WindowHandle window_handle )
{
	if ( ! Game_Status.Is_Game_In_Progress() ) {
		Debug_Error_Window_Message( "Game not in progress!" );
		return;
	}

	DialogBox( Global_Instance_Handle, 
				  "DebugSetCashDlgBox", 
				  window_handle, 
				  (DLGPROC) Debug_Adjust_Cash_Dialog_Procedure );
	
}

#pragma argsused

/***************************************************************************
 * DEBUG_ADJUST_CASH_DIALOG_PROC -- Handles dialog messages for this       *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: TRUE if cash modified, FALSE if not                             *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
PRIVATE BOOL Debug_Adjust_Cash_Dialog_Procedure( WindowHandle window_handle,
															 UINT message,
															 WPARAM w_param,
															 LPARAM l_param )
{
	INT cash;
	PlayerType player;

	switch( message ) {
	
		case WM_COMMAND:

			if ( LOWORD( w_param ) == IDOK ) {

				GetDlgItemText( window_handle, 
									 CASH_EDIT1, 
									 Text_String, 
									 SIZE_OF_TEXT_STRING );
				cash = atoi( Text_String );
				if ( cash < 0 ) {
					cash = 0;
				}
				if ( cash > 100000 ) {
					cash = 100000;
				}

				player = Game_Status.Get_Whos_Turn_Is_It_Now();
//				Players[ player ].Set_Money( cash );
				// FALSE = not incoming, so outgoing to other systems
				Send_Game_Command( FALSE, CMD_SET_CASH, player, cash );

				sprintf( Text_String,
							"%s now has $%d.\r\n",
							Players[ player ].Get_Name(), cash );
				Debug_Mono_Message( Text_String );
				Refresh_Player_Interface( player, TRUE );

				EndDialog( window_handle, IDOK );
				return( TRUE );
			}
			break;

		case WM_INITDIALOG:
				/*
					Default cash for player
				*/
				player = Game_Status.Get_Whos_Turn_Is_It_Now();
				itoa( Players[ player ].Get_Cash(), Text_String, 10 );
				SetDlgItemText( window_handle, 
									 CASH_EDIT1, 
									 Text_String );
				SendDlgItemMessage( window_handle, 
										  CASH_EDIT1,
										  EM_SETSEL,  
										  (WPARAM) 0,
										  (LPARAM) -1 );
				return( TRUE );

		default: break;

	}
	return( FALSE );
}

// TC 
extern BYTE *Debug_Chance_Card_Text[];

VOID Debug_Show_Chance_Deck( VOID )
{
	ChanceCardType card;
	INT i;

	for ( i = 0; i < TOTAL_CHANCE_CARDS_IN_MAX_DECK; i ++ ) {
		card = Game_Cards.Query_Chance_Card( i );
		if ( card > CHANCE_NO_CARD ) {
			sprintf( Text_String,
						"Chance card[ %d ] = %s\r\n",
						i,
						Debug_Chance_Card_Text[ card ] );
		}
		else {
			sprintf( Text_String,
						"Chance card[ %d ] = -1\r\n",
						i );
		}
		Debug_Mono_Message( Text_String );
	}
}

// TC 
extern BYTE *Debug_CC_Card_Text[];

VOID Debug_Show_CC_Deck( VOID )
{
	CommunityChestCardType card;
	INT i;

	for ( i = 0; i < TOTAL_COMMUNITY_CHEST_CARDS_IN_MAX_DECK; i ++ ) {
		card = Game_Cards.Query_CC_Card( i );
		if ( card > CC_NO_CARD ) {
			sprintf( Text_String,
						"C. Chest card[ %d ] = %s\r\n",
						i,
						Debug_CC_Card_Text[ card ] );
		}
		else {
			sprintf( Text_String,
						"C. Chest card[ %d ] = -1\r\n",
						i );
		}
		Debug_Mono_Message( Text_String );
	}
}

/***************************************************************************
 * DEBUG_MONO_PRINT_WHOSE_TURN -- Displays current turn on MONO display    *
 *                                                                         *
 * INPUT: player whos turn it is                                           *
 *                                                                         *
 * OUTPUT: a message to the MONO display                                   *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Mono_Print_Whose_Turn( PlayerType player )
{
	Debug_Mono_Message( "--------------------------------------------------------------------------\r\n" );
	sprintf( Text_String, "--- %s's turn...\r\n", Players[ player ].Get_Name() );
	Debug_Mono_Message( Text_String );
	Debug_Mono_Message( "--------------------------------------------------------------------------\r\n" );
}

VOID Debug_Display_Bank_Status( VOID )
{
	sprintf( Text_String,
				"Hotels in bank = %d, Houses in bank = %d",
				Bank.Get_Hotels(),
				Bank.Get_Houses() );
	Standard_Window_Message( Text_String, "DEBUG" );
}

VOID Debug_Show_Player_Info( VOID )
{
	BYTE *tokens[ TOTAL_TOKENS ] = {
		"CANNON ",
		"CAR    ",
		"DOG    ",
		"HAT    ",
		"IRON   ",
		"HORSE  ",
		"SHIP   ",
		"SHOE   ",
		"THIMBLE",
		"WBARROW",
	};
	BYTE *ais[ TOTAL_AI_TYPES ] = {
		"LOCAL HUMAN ",
		"LOCAL AI    ",
		"REMOTE HUMAN",
		"REMOTE AI   ",
	};
	BYTE *status[ TOTAL_ACTIVE_STATUSES ] = {
		"INACTIVE",
		"ACTIVE  ",
		"BANKRUPT",
	};
	INT i;

	Debug_Mono_Message( "****************************************************\r\n" );
	sprintf( Text_String,
				"Game_Is_Now_Currently_Interrupted = %d\r\n",
				Game_Is_Now_Currently_Interrupted );
	Debug_Mono_Message( Text_String );
	for ( i = FIRST_PLAYER; i <= LAST_PLAYER; i ++ ) {
		if ( Players[ i ].Get_Active_Status() != PLAYER_INACTIVE ) {
			sprintf( Text_String,
						"Player[ %d ] - %s | %s | %s | %s | %s\r\n",
						i,
						tokens[ Players[ i ].Get_Token() ],
						ais[ Players[ i ].Get_AI_Type() ],
						Players[ i ].Get_IP_Address(),
						status[ Players[ i ].Get_Active_Status() ],
						Players[ i ].Get_Name() );
		}
		else {
			sprintf( Text_String,
						"Player[ %d ] INACTIVE\r\n",
						i );

		}
		Debug_Mono_Message( Text_String );
	}
	Debug_Mono_Message( "****************************************************\r\n" );

}

VOID Debug_Give_All_Properties( PlayerType player )
{
	INT i;

	if ( player >= FIRST_PLAYER ) {
		for ( i = PROP_FIRST; i <= PROP_LAST; i ++ ) {
//			Property_Data[ i ].Set_Owner( player );
			Send_Game_Command( FALSE, CMD_SET_OWNER, player, i );
		}
//		Refresh_Player_Interface( player, TRUE );
		Send_Game_Command( FALSE, CMD_FULLY_REFRESH_SCREEN );
	}
}

#endif /* DEBUG_CODE */

#if( DEBUG_CHECKSUM_ALL_SITES_DATA )
#if( COMPILE_WINSOCK )
VOID Debug_Broadcast_Save_Game_Checksum_Other_Sites( VOID )
{
	ULONG file_size;
	INT fh;
	INT i;
	ULONG check_sum;
	BYTE *buffer;
//	SOCKET temp_socket;
//	INT status;
	INT low_int;
	INT high_int;
	UBYTE add_byte;
	BYTE *file_name;

	/*
		don't do this unless we are multi-site
	*/
	if ( ! Multiple_Site_Game_In_Progress ) {
		return;
	}

	file_name = Text_String_3;
	sprintf( file_name,
				"%s%s",
				Executable_Path,
				"TEMPSEND.TMP" );

	/*
		first save out the current game data
	*/
	DOS_Save_A_Game( file_name, TRUE ); // TRUE = site-to-site verification
	/*
		now allocate a buffer and load the save data back up
	*/
	fh = Open_File( file_name, READ );
	if ( fh != -1 ) {
		file_size = File_Size( fh );
		buffer = (BYTE *) Alloc( (ULONG) file_size + 10, MEM_NORMAL );
		if ( buffer == NULL ) {
			Close_File( fh );
			#if ( DEBUG_CODE )
				Debug_Error_Window_Message( "Unable to alloc buffer in Debug_Broadcast_Save_Game_Data_To_Other_Sites()" );
			#endif
			return;
		}
		Read_File( fh, buffer, file_size );
		Close_File( fh );
	}

	/*
		now checksum the buffer
	*/
	check_sum = 0L;
	for ( i = 0; i < file_size; i ++ ) {
		add_byte = (UBYTE) *(buffer + i);
		check_sum += (add_byte * (i+1));
	}
	low_int = LOWORD( check_sum );
	high_int = HIWORD( check_sum );

	#if( DEBUG_CODE )
		sprintf( Text_String,
					"Local checksum of %s is %ld, sending %d (low) & %d (high)...\r\n",
					file_name,
					check_sum,
					low_int,
					high_int );
		Debug_Mono_Message( Text_String );
	#endif

	/*
		send a system command with the checksum game data
	*/
	WinSock_Broadcast_Command( CMD_SENDING_CHECKSUM_DATA, 3, (INT) file_size, low_int, high_int );

	if ( buffer ) {
		Free( buffer );
//		buffer = NULL;
	}
//	Delete_File( file_name );
}
#endif
#endif

#if( DEBUG_CHECKSUM_ALL_SITES_DATA )
#if( COMPILE_WINSOCK )
VOID Debug_Compare_Local_Checksum_With_Received_Checksum( INT received_file_size, INT low_int, INT high_int )
{
	INT fh;
	ULONG received_check_sum;
	ULONG local_check_sum;
	BYTE *buffer = NULL;
	INT local_file_size;
	INT i;
	UBYTE add_byte;
	BYTE *file_name;
	static BOOL _errored_already = FALSE;

	if ( _errored_already ) {
		return;
	}

	/*
		don't do this unless we are multi-site
	*/
	if ( ! Multiple_Site_Game_In_Progress ) {
		return;
	}

	received_check_sum = high_int;
	received_check_sum <<= 16;
	received_check_sum += low_int;

	#if( DEBUG_CODE )
		sprintf( Text_String,
					"Getting ready to compare other sites file, size = %d, checksum = %ld\r\n",
					received_file_size,
					received_check_sum );
		Debug_Mono_Message( Text_String );
	#endif

	file_name = Text_String_3;

	sprintf( file_name,
				"%s%s",
				Executable_Path,
				"TEMPSAVE.TMP" );

	/*
		save out out current game right now!
	*/
	DOS_Save_A_Game( file_name, TRUE ); // TRUE = site-to-site verification
	/*
		now load it, and check sum it
	*/
	/*
		now allocate a buffer and load the save data back up
	*/
	fh = Open_File( file_name, READ );
	if ( fh != -1 ) {
		local_file_size = File_Size( fh );
		buffer = (BYTE *) Alloc( (ULONG) local_file_size + 10, MEM_NORMAL );
		if ( buffer == NULL ) {
			Close_File( fh );
			#if ( DEBUG_CODE )
				Debug_Error_Window_Message( "Unable to alloc buffer in Debug_Broadcast_Save_Game_Data_To_Other_Sites()" );
			#endif
			return;
		}
		Read_File( fh, buffer, local_file_size );
		Close_File( fh );
	}
	/*
		now checksum the buffer
	*/
	local_check_sum = 0L;
	for ( i = 0; i < local_file_size; i ++ ) {
		add_byte = (UBYTE) *(buffer + i);
		local_check_sum += (add_byte * (i+1));
	}
	/*
		free the buffer
	*/		
	if( buffer ) {
		Free( buffer );
	}

	/*
		now compare files sizes and check sum!
	*/
	if ( local_file_size != received_file_size ) {
		sprintf( Text_String,
					"ERROR! TEMPSAVE.TMP (local, %d) & TEMPSEND.TMP (remote, %d) file sizes don't match!\r\n",
					local_file_size, received_file_size );
		#if( DEBUG_CODE )
			Debug_Mono_Message( Text_String );
// 		don't post anything!
			Debug_Error_Window_Message( Text_String );
		#endif

		return;
	}
	if ( local_check_sum != received_check_sum ) {

		LOCAL_RESET_SITE_OPTION( SITE_OPTION_COMPUTER_ROLLS_FOR_ITSELF );
		Send_Game_Command( FALSE, CMD_SET_GAME_OVER_FLAG, TRUE );
		_errored_already = TRUE;

		#if( DEBUG_CODE )
			sprintf( Text_String,
						"ERROR! TEMPSAVE.TMP (local, %ld) & TEMPSEND.TMP (remote, %ld) checksums don't match!\r\n",
						local_check_sum, received_check_sum );
// 		Give_To_The_Mikes();
			Debug_Mono_Message( Text_String );
			Debug_Error_Window_Message( Text_String );
		#endif

		return;
	}
	/*
		okay! everything matches!
	*/
	#if( DEBUG_CODE )
		sprintf( Text_String,
					"TEMPSAVE.TMP (local, %ld) & TEMPSEND.TMP (remote, %ld) checksums match!\r\n",
					local_check_sum, received_check_sum );
		Debug_Mono_Message( Text_String );
	#endif
}
#endif
#endif

#if( DEBUG_CHECKSUM_ALL_SITES_DATA )
PRIVATE VOID Give_To_The_Mikes( VOID )
{
	Real_Error_Window_Message( "Put TEMPSAVE.TMP from your system on a floppy..." );
	Real_Error_Window_Message( "and put TEMPSEND.TMP from your oppenent systems on the floppy..." );
	Real_Error_Window_Message( "...and then give it to the Mike's for error checking!" );
}
#endif

#if( DEBUG_WRITE_IDS_IN_SAVES )
LONG Debug_Write_ID_Save_Game_File( INT file_handle, BYTE *three_byte_id )
{
	LONG bytes_read_or_written = 0L;

	if ( file_handle > -1 ) {
		bytes_read_or_written += Write_File( file_handle, three_byte_id, 3 );
	}

	return( bytes_read_or_written );
}
#endif

#if( DEBUG_WRITE_IDS_IN_SAVES )
LONG Debug_Read_ID_Save_Game_File( INT file_handle )
{
	LONG bytes_read_or_written = 0L;
	BYTE junk[ 4 ];

	if ( file_handle > -1 ) {
		bytes_read_or_written += Read_File( file_handle, &junk, 3 );
	}

	return( bytes_read_or_written );
}
#endif

#if( DEBUG_WRITE_IDS_IN_SAVES )
LONG Debug_Write_ID_Save_Game_Memory( MemorySaveBufferType buffer_num, BYTE *three_byte_id )
{
	LONG bytes_read_or_written = 0L;

	bytes_read_or_written += Memory_Save_Games[ buffer_num ].Write_Data( (UBYTE *) three_byte_id, 3 );

	return( bytes_read_or_written );
}
#endif

#if( DEBUG_WRITE_IDS_IN_SAVES )
LONG Debug_Read_ID_Save_Game_Memory( MemorySaveBufferType buffer_num )
{
	LONG bytes_read_or_written = 0L;
	BYTE junk[ 4 ];

	bytes_read_or_written += Memory_Save_Games[ buffer_num ].Read_Data( (UBYTE *) &junk, 3 );

	return( bytes_read_or_written );
}
#endif

/***************************************************************************
 * BUILD_DEBUG_LOG_FILE_NAME -- Based on the date and time of system       *
 *                                                                         *
 * INPUT: buffer to put file name in                                       *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: the buffer had better be at least 13 characters for filename  *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
#if( DEBUG_LOG_TO_FILE )
VOID Build_Debug_Log_File_Name( BYTE *name_string_buffer, BYTE *system_id_string_buffer )
{
	SYSTEMTIME data;
	BYTE *ptr;
	INT fh;
	BYTE *file_name;
		
	/*
		build file in following format:

		AA BB CC DD . 0EE -> AABBCCDD.0EE

		AA = month 01-12
		BB = day 01-31
		CC = hour 00-23
		DD = minute 00-59
		EE = second 00-59
	*/

	/*
		get system time and data information and build a file name
	*/
	GetSystemTime( &data );
//	sprintf( name_string,
//				"%2d%2d%2d%2d.%2d",
//				data.wMonth,
//				data.wDay,
//				data.wHour,
//				data.wMinute,
//				data.wSecond );
	sprintf( name_string_buffer,
				"%2d%2d%2d%2d.%3d",
				data.wMonth,
				data.wDay,
				data.wHour,
				data.wMinute,
				0 );

	/*
		replace spaces w/ 0's in file name
	*/			
	ptr = name_string_buffer;
	while ( *ptr != '\0' ) {
		if ( *ptr == ' ' ) {
			*ptr = '0';
		}
		ptr ++;
	}

//	#if( DEBUG_CODE )
//		sprintf( Text_String,
//					"Log file name for this session: %s\r\n",
//					name_string );
//		Debug_Mono_Message( Text_String );
//	#endif

	/*
		build .INI file name (with directory path) in Text_String_2
	*/
	sprintf( Text_String_2,
				"%sMONOPOLY.INI",
				Executable_Path );

	/*
		now get the system id from "monopoly.ini" in Text_String_3, error if not in there
	*/
	if ( ! Find_File( Text_String_2 ) ) {
		sprintf( Text_String,
					"%s not found!",
					Text_String_2 );
		Debug_Error_Window_Message( Text_String );
		return;
	}

	/*
		get the DebugSystemName in Text_String_3 
	*/
	GetPrivateProfileString( "Monopoly",
									 "DebugSystemName",
									 "No DebugSystemName found!",
									 Text_String_3,
									 SIZE_OF_TEXT_STRING,
									 Text_String_2 );

	/*
		Now store the system name
   */
	if( strlen( Text_String_3 ) >= SIZE_OF_DEBUG_SYSTEM_ID_NAME ) {
		*( Text_String_3 + SIZE_OF_DEBUG_SYSTEM_ID_NAME - 1 ) = '\0';
	}
	strcpy( system_id_string_buffer, Text_String_3 );

//	#if( DEBUG_CODE )
//		sprintf( Text_String,
//					"Legal DebugSystemName for this session: %s\r\n",
//					Text_String_3 );
//		Debug_Mono_Message( Text_String );
//	#endif

	/*
		open and write header to the log file
	*/
	strcpy( Text_String_2,
			  "----------------------------------------------------------------\r\n" );
	sprintf( Text_String,
				"---File: %s \r\n---Running on %02d/%02d/%02d at %02d:%02d \r\n---System: %s \r\n",
				name_string_buffer,
				data.wMonth, data.wDay, data.wYear,
				data.wHour, data.wMinute,
				Text_String_3 );

//	#if( DEBUG_CODE )
//	Debug_Mono_Message( Text_String );
// #endif

	/*
		open the file and write out the header info!
	*/

	file_name = Text_String_3;
	sprintf( file_name,
				"%s%s",
				Executable_Path,
				name_string_buffer );

	fh = Open_File( file_name, WRITE );
	Write_File( (INT)fh, (BYTE *)Text_String_2, (ULONG)(strlen(Text_String_2)) );
	Write_File( (INT)fh, (BYTE *)Text_String,   (ULONG)(strlen(Text_String)) );
	Write_File( (INT)fh, (BYTE *)Text_String_2, (ULONG)(strlen(Text_String_2)) );
	Close_File( fh );
}

#endif

#if( DEBUG_LOG_TO_FILE )
VOID Debug_Print_Log_File_Name_On_Board_Hid( VOID )
{
#if( 0 )
	SetTextAlign( WinG_DC, TA_LEFT ); 
	SelectObject( WinG_DC, GetStockObject( ANSI_VAR_FONT ) );
	SetTextColor( WinG_DC, BLACK_RGB_COLOR_REF );
	SetTextCharacterExtra( WinG_DC, 0 );
	SetBkMode( WinG_DC, TRANSPARENT );

	sprintf( Text_String,
				"Debug file: %s",
				Debug_Log_File_Name );

	TextOut( WinG_DC, 
				VQ_MOVIE_X+2, 
				VQ_MOVIE_Y-2,
				Text_String, 
				strlen( Text_String ) );

	sprintf( Text_String,
				"System name: %s",
				Debug_System_ID_Name );

	TextOut( WinG_DC, 
				VQ_MOVIE_X+2, 
				VQ_MOVIE_Y-2+10,
				Text_String, 
				strlen( Text_String ) );

	sprintf( Text_String,
				"Vers: %s",
				VERSION_NUMBER_STRING );

	TextOut( WinG_DC, 
				VQ_MOVIE_X+2, 
				VQ_MOVIE_Y-2+20,
				Text_String, 
				strlen( Text_String ) );
#endif
}
#endif // DEBUG_CODE

/*
	This needs to be outside DEBUG_CODE
*/
/***************************************************************************
 * GET_AND_DISPLAY_WINDOWS_DEBUG -- GetWinDebugInfo() is called for checkin*
 *                                                                         *
 * INPUT: none                                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: avoid the raptor pit on Jurassic Park                         *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
BOOL Get_Windows_System_Info( VOID )
{
	OSVERSIONINFO version_info;	
	DWORD major;
	DWORD minor;
	FLOAT float_version;

//#if( 0 )
//	WINDEBUGINFO current_windows_debug_info;
//	GetWinDebugInfo( &current_windows_debug_info,
//						  WDI_OPTIONS | WDI_FILTER | WDI_ALLOC_BREAK );
//	sprintf( Text_String,
//				"Debug info:\r\nflags = %d, options = %d, filter = %d, alloc module = %s, \r\nalloc break = %ld, alloc count = %ld.\r\n",
//				current_windows_debug_info.flags,
//				current_windows_debug_info.dwOptions,
//				current_windows_debug_info.dwFilter,
//				current_windows_debug_info.achAllocModule,
//				current_windows_debug_info.dwAllocBreak,
//				current_windows_debug_info.dwAllocCount );
//	Debug_Mono_Message( Text_String );
//#endif

	/*------------------------------------------------------------------------*/

	Windows_95_Detected_Flag = FALSE;

	version_info.dwOSVersionInfoSize = sizeof( OSVERSIONINFO );
	if ( GetVersionEx( &version_info ) ) {
		sprintf( Text_String,
					"Windows OS version: %ld.%ld, build #%ld, %s\r\n",
					version_info.dwMajorVersion,	
					version_info.dwMinorVersion,	
					version_info.dwBuildNumber,
					version_info.szCSDVersion );
		Debug_Mono_Message( Text_String );

		if ( version_info.dwPlatformId == VER_PLATFORM_WIN32s ) {  // 0
			#if( DEBUG_CODE )
				Debug_Mono_Message( "Windows OS Platform: Win32s on Windows 3.1\r\n" );
         #endif

			Windows_95_Detected_Flag = FALSE;
			/*
				if Win32s, make sure that we have version 1.25 or greater
			*/
			major = version_info.dwMajorVersion;
			minor = version_info.dwMinorVersion;
			sprintf( Text_String,
						"%ld.%ld",
						major, minor );
			sscanf( Text_String, "%f", &float_version );
//			if ( major < REQUIRED_WIN32S_MAJOR_VERSION || 
//				( major == REQUIRED_WIN32S_MAJOR_VERSION && minor < REQUIRED_WIN32S_MINOR_VERSION ) ) {
//							Real_Error_Window_Message( "Win32s version 1.25 or greater is required. Run SETUP.EXE from the Monopoly CD-ROM CD." );	
//							return( FALSE );
//			}
			if ( float_version < REQUIRED_WIN32S_FLOAT_VERSION ) {
				/*
					do both in case TRR not set up
				*/
				Real_Error_Window_Message_String( "Win32s version 1.25 or greater is required. Run SETUP.EXE from the Monopoly CD-ROM CD." );	
				Real_Error_Window_Message( STR_TRR_SYSTEM_ERROR_76 );	
				return( FALSE );
			}

		}
//		else if ( version_info.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS ) { // 1
		else if ( version_info.dwPlatformId == 1 ) { // 1
			#if( DEBUG_CODE )
				Debug_Mono_Message( "Windows OS Platform: Win32 on Chicago\r\n" );
			#endif
			Windows_95_Detected_Flag = TRUE;
		}
		else if ( version_info.dwPlatformId == VER_PLATFORM_WIN32_NT ) {  // 2
			#if( DEBUG_CODE )
				Debug_Mono_Message( "Windows OS Platform: Win32 NT\r\n" );
			#endif
			Windows_95_Detected_Flag = FALSE;
		}
		else {
			#if( DEBUG_CODE )
				Debug_Mono_Message( "Windows OS Platform: Unknown!\r\n" );
			#endif
			Windows_95_Detected_Flag = TRUE; // just to be safe! future versions!
		}
	}
	else {
		Debug_Mono_Message( "Unable to GetVersionEx()!\r\n" );
	}

	/*------------------------------------------------------------------------*/

//	/*
//		display command line string, if any
//	*/
//	sprintf( Text_String,
//				"WinMain() command line string = %s\r\n",
//				command_line_string );
//	Debug_Mono_Message( Text_String );

	/*
		Show the current directory
	*/
//	GetCurrentDirectory( SIZE_OF_TEXT_STRING, Text_String_3 );
//	sprintf( Text_String,
//				"GetCurrentDirectory() = %s\r\n",
//				Text_String_3 );
//	Debug_Mono_Message( Text_String );

	sprintf( Text_String,
				"Executable_Path[] = %s\r\n",
				Executable_Path );
	Debug_Mono_Message( Text_String );

	sprintf( Text_String,
				"CD_Root_Path[] = %s\r\n",
				CD_Root_Path );
	Debug_Mono_Message( Text_String );

	/*
		display argv arguments
	*/
//	for ( i = 0; i < _argc; i ++ ) {
//		sprintf( Text_String,
//					"WinMain() argv[ %d ] = %s\r\n",
//					i,
//					_argv[ i ] );
//		Debug_Mono_Message( Text_String );
//	}

	return( TRUE );
}

//#if( DEBUG_VERIFY_ALL_SITES_DATA )
//VOID Debug_Broadcast_Save_Game_Data_To_Other_Sites( VOID )
//{
//	BYTE *file_name = "TEMPSEND.TMP";
//	ULONG file_size;
//	INT fh;
//	INT i;
//	BYTE *buffer;
//	SOCKET temp_socket;
//	INT status;
//
//	/*
//		first save out the current game data
//	*/
//	DOS_Save_Game( file_name, TRUE ); // TRUE = site-to-site verification
//	/*
//		now allocate a buffer and load the save data back up
//	*/
//	fh = Open_File( file_name, READ );
//	if ( fh != -1 ) {
//		file_size = File_Size( fh );
//		buffer = (BYTE *) Alloc( (ULONG) file_size + 10, MEM_NORMAL );
//		if ( buffer == NULL ) {
//			Close_File( fh );
//			Generic_Window_Message( "Unable to alloc buffer in Debug_Broadcast_Save_Game_Data_To_Other_Sites()", " " );
//			return;
//		}
//		Read_File( fh, buffer, file_size );
//		Close_File( fh );
//	}
//
//	#if( COMPILE_WINSOCK )
//		/*
//			send a system command that the save game data is coming over
//		*/
//		WinSock_Broadcast_Command( CMD_HERE_COMES_MY_GAME_STATUS_BUFFER, 1, (INT) file_size );
//		/*
//			now blast the data over!
//		*/
//		/* if this system was the original host */
//		if ( Waiting_Socket_Index > -1 ) {
//			/* send the command to all the "waiter links" */
//			for ( i = 0; i <= Waiting_Socket_Index; i ++ ) {
//				temp_socket = Hosts_Waiting_Sockets[ i ].accepted_connection_waiting_socket;
//				if ( temp_socket != INVALID_SOCKET ) {
//					status = WINSOCK_SEND( temp_socket, buffer, file_size, 0 );
//					if ( status == SOCKET_ERROR ) {
//						Generic_Window_Message( "Bad send() of save game data", " " );
//					}
//					else {
//						sprintf( Text_String, "%d size save game data buffer sent\r\n", status );
//						Debug_Mono_Message( Text_String );
//					}
//				}
//			}
//		}
//		/* else this system is a webbee */
//		else {
//			/* send the command to the original host */
//			if ( WC_Temp_Waiter_Socket != INVALID_SOCKET ) {
//				status = WINSOCK_SEND( WC_Temp_Waiter_Socket, buffer, file_size, 0 );
//				if ( status == SOCKET_ERROR ) {
//					Generic_Window_Message( "Bad send() of save game data", " " );
//				}
//				else {
//					sprintf( Text_String, "%d size save game data buffer sent\r\n", status );
//					Debug_Mono_Message( Text_String );
//				}
//			}
//			/* then send the command to all other connected webbees */
//			for ( i = 0; i <= Web_Accepted_Socket_Index; i ++ ) {
//				temp_socket = Web_Accepted_Sockets[ i ];
//				if ( temp_socket != INVALID_SOCKET ) {
//					status = WINSOCK_SEND( temp_socket, buffer, file_size, 0 );
//					if ( status == SOCKET_ERROR ) {
//						Generic_Window_Message( "Bad send() of save game data", " " );
//					}
//					else {
//						sprintf( Text_String, "%d size save game data buffer sent\r\n", status );
//						Debug_Mono_Message( Text_String );
//					}
//				}
//			}
//		}
//	#endif
//
//	if ( buffer ) {
//		Free( buffer );
////		buffer = NULL;
//	}
////	Delete_File( file_name );
//}
//#endif /* DEBUG_VERIFY_ALL_SITE_DATA */

//#if( DEBUG_VERIFY_ALL_SITES_DATA )
//VOID Debug_Prepare_To_Receive_Other_Site_Save_Game_Data( INT buffer_size )
//{
//	if ( Incoming_Save_Game_Data ) {
//		Generic_Window_Message( "Incoming_Save_Game_Data already allocated!", " " );
//		Free( Incoming_Save_Game_Data );
//		Incoming_Save_Game_Data = NULL;
//	}
//
//	Incoming_Save_Game_Data = (BYTE *) Alloc( (buffer_size) + 10, MEM_NORMAL );
//	Incoming_Save_Game_Data_Size = buffer_size;
//	if ( ! Incoming_Save_Game_Data ) {
//		Generic_Window_Message( "Unable to allocate Incoming_Save_Game_Data\r\n", " " );
//		Incoming_Save_Game_Data_Size = 0;
//	}	
//	else {
//		Debug_Mono_Message( "Incoming_Save_Game_Data allocated and ready for receive...\r\n" );
//	}
//}
//#endif /* DEBUG_VERIFY_ALL_SITE_DATA */
//
//#if( DEBUG_VERIFY_ALL_SITES_DATA )
//VOID Debug_Verify_Incoming_Save_Data( INT bytes_actually_received )
//{
//	INT fh;
//	BYTE *buffer = NULL;
//	BYTE *file_name = "TEMPSAVE.TMP";
//	LONG file_compare;
//
//	if ( ! Incoming_Save_Game_Data || ! Incoming_Save_Game_Data_Size ) {
//		return;
//	}
//
//	sprintf( Text_String,
//				"Save game data rec'd for verify, expected %d, actual %d\r\n",
//				Incoming_Save_Game_Data_Size,
//				bytes_actually_received );
//	Debug_Mono_Message( Text_String );								
//
//	/*
//		temp save the "just received save game" buffer out
//	*/
//	fh = Open_File( "TEMPRECV.MNO", WRITE );
//	if ( fh != -1 ) {
//		Write_File( fh, (BYTE *) Incoming_Save_Game_Data, Incoming_Save_Game_Data_Size );
//		Close_File( fh );
//	}
//	else {
//		Generic_Window_Message( "Unable to save out temporary rec'd save game", " " );
//	}
//
//	/*
//		now compare the data just rec'd with our current save game
//	*/
//	/*
//		first save out the local current game data on this system
//	*/
//	DOS_Save_Game( file_name, TRUE ); // TRUE = site-to-site verification
//
//	/*
//		do file compare here between file_name (local) and
//		temprecv.mno (rec'd from remote)
//	*/
//	file_compare = Debug_Compare_Two_Files( file_name, "TEMPRECV.MNO" );
//	switch( file_compare ) {
//		case -4L: Debug_Mono_Message( "Received game status data fine!\r\n" ); break;
//		case -3L: Debug_Mono_Message( "Memory error occured w/ file compare!\r\n" ); break;
//		case -2L: Debug_Mono_Message( "File error occured w/ file compare!\r\n" ); break;
//		case -1L: Generic_Window_Message( "Error! Data verification file sizes different!", " " );
//		default:	
//			sprintf( Text_String,
//						"Error! Data verification files differ at byte %ld",
//						file_compare );
//			Generic_Window_Message( Text_String, " " );			
//			sprintf( Text_String,
//						"Compare %s (our system) and TEMPRECV.MNO (rec'd)!",
//						file_name );
//			Generic_Window_Message( Text_String, " " );			
//	}
//
//	/*
//		free the temporary buffer
//	*/
//	if( buffer ) {
//		Free( buffer );
////		buffer = NULL;
//	}
//	/*
//		free it all up for next time
//	*/
//	if( Incoming_Save_Game_Data ) {
//		Free( Incoming_Save_Game_Data );
//		Incoming_Save_Game_Data = NULL;	
//	}
//	Incoming_Save_Game_Data_Size = 0;
//}
//#endif /* DEBUG_VERIFY_ALL_SITE_DATA */

///*
//	0+ = different at byte 0+
//	-1	= size different
//	-2 = file / DOS error
//	-3	= allocation / memory error
//	-4 = files are the same!
//*/
//#if( DEBUG_VERIFY_ALL_SITES_DATA )
//LONG Debug_Compare_Two_Files( BYTE *file_name_1, BYTE *file_name_2 )
//{
//	INT fh_1;
//	INT fh_2;
//	LONG file_size_1;
//	LONG file_size_2;
//	UBYTE *buffer_1;
//	UBYTE *buffer_2;
//	UBYTE *ptr_1;
//	UBYTE *ptr_2;
//	LONG bytes_read_1;
//	LONG bytes_read_2;
//	LONG i;
//	LONG error_byte_index;
//
//	fh_1 = Open_File( file_name_1, READ );
//	if ( fh_1 == -1 ) {
//		sprintf( Text_String,
//					"File %s could not be opened\r\n",
//					file_name_1 );
//		Debug_Mono_Message( Text_String );
//		return( -2L ); // ERROR!
//
//	}
//	fh_2 = Open_File( file_name_2, READ );
//	if ( fh_2 == -1 ) {
//		sprintf( Text_String,
//					"File %s could not be opened\r\n",
//					file_name_2 );
//		Debug_Mono_Message( Text_String );
//		Close_File( fh_1 );
//		return( -2L );  // ERROR!
//
//	}
//
//	file_size_1 = File_Size( fh_1 );
//	file_size_2 = File_Size( fh_2 );
////	file_size_1 = 662;
////	file_size_2 = 662;
//
//	sprintf( Text_String,
//				"File_Size() of %s = %d bytes, File_Size() of %s = %d bytes\r\n",
//				file_name_1,
//				file_size_1,
//				file_name_2,
//				file_size_2 );
//	Debug_Mono_Message( Text_String );
//
//	if ( file_size_1 != file_size_2 ) {
////		Debug_Mono_Message( "About to call Close_File()\r\n" );
//		Close_File( fh_1 );
////		Debug_Mono_Message( "About to call Close_File()\r\n" );
//		Close_File( fh_2 );
//		return( -1L );  // ERROR!
//	}
//
////	Debug_Mono_Message( "About to call Alloc()\r\n" );
//	buffer_1 = (UBYTE *) Alloc( (ULONG) (file_size_1 + 10L), MEM_NORMAL );
////	Debug_Mono_Message( "About to call Alloc()\r\n" );
//	buffer_2 = (UBYTE *) Alloc( (ULONG) (file_size_2 + 10L), MEM_NORMAL );
//	if ( ! buffer_1 || ! buffer_2 ) {
//		if ( buffer_1 ) {
////			Debug_Mono_Message( "error, About to call Free()\r\n" );
//			Free( buffer_1 );
//		}
//		if ( buffer_2 ) {
////			Debug_Mono_Message( "error, About to call Free()\r\n" );
//			Free( buffer_2 );
//		}
////		Debug_Mono_Message( "error, About to call Close_File()\r\n" );
//		Close_File( fh_1 );
////		Debug_Mono_Message( "error, About to call Close_File()\r\n" );
//		Close_File( fh_2 );
//		return( -3L );  // ERROR!
//	}
//
////	Debug_Mono_Message( "About to call Read_File()\r\n" );
//	bytes_read_1 = Read_File( fh_1, buffer_1, file_size_1 );
////	Debug_Mono_Message( "About to call Read_File()\r\n" );
//	bytes_read_2 = Read_File( fh_2, buffer_2, file_size_2 );
////	Debug_Mono_Message( "About to call Close_File()\r\n" );
//	Close_File( fh_1 );
////	Debug_Mono_Message( "About to call Close_File()\r\n" );
//	Close_File( fh_2 );
//
//	sprintf( Text_String,
//				"Bytes read of %s = %d bytes, bytes read of %s = %d bytes\r\n",
//				file_name_1,
//				bytes_read_1,
//				file_name_2,
//				bytes_read_2 );
//	Debug_Mono_Message( Text_String );
//
//	if ( bytes_read_1 != bytes_read_2 ) {
////		Debug_Mono_Message( "Error, About to call Free()\r\n" );
//		Free( buffer_1 );
////		Debug_Mono_Message( "Error, About to call Free()\r\n" );
//		Free( buffer_2 );
//		return( -2L ); // ERROR!
//	}
//
////	Debug_Mono_Message( "About to call memcmp()\r\n" );
//	if ( memcmp( buffer_1, buffer_2, file_size_1 ) ) {
//
//		Debug_Mono_Message( "Error: Files are different\r\n" );
//
//		ptr_1 = (UBYTE *) buffer_1;
//		ptr_2 = (UBYTE *) buffer_2;
//		/*
//			scan the data and find which byte # the error occured on
//		*/
//		error_byte_index = 0L;
//		for ( i = 0; i < file_size_1; i ++ ) {
//			if ( *ptr_1 != *ptr_2 ) {
//				error_byte_index = i;
//				i = file_size_1;
//			}
//			ptr_1 += 1;
//			ptr_2 += 1;
//		}
//
////		Debug_Mono_Message( "Error, About to call Free()\r\n" );
//		Free( buffer_1 );
////		Debug_Mono_Message( "Error, About to call Free()\r\n" );
//		Free( buffer_2 );
//
//		sprintf( Text_String,
//					"Error, files are different at byte #%d\r\n",
//					error_byte_index );
//		Debug_Mono_Message( Text_String );
//
//		return( (LONG) error_byte_index ); // ERROR!
//	}
//
////	Debug_Mono_Message( "About to call Free()\r\n" );
//	Free( buffer_1 );
////	Debug_Mono_Message( "About to call Free()\r\n" );
//	Free( buffer_2 );
//
//	Debug_Mono_Message( "Both files match!\r\n" );
//	return( -4L ); // SUCCESS!
//}
//#endif

BYTE *Debug_Get_Time_String( VOID )
{
	SYSTEMTIME data;
	static BYTE _time_string[ 20 ];
		
	/*
		build file in following format:

		AA BB CC DD . 0EE -> AABBCCDD.0EE

		AA = month 01-12
		BB = day 01-31
		CC = hour 00-23
		DD = minute 00-59
		EE = second 00-59
	*/

	/*
		get system time and data information and build a file name
	*/
	GetSystemTime( &data );
//	sprintf( _time_string,
//				"%2d%2d%2d%2d.%2d",
//				data.wMonth,
//				data.wDay,
//				data.wHour,
//				data.wMinute,
//				data.wSecond );
	sprintf( _time_string,
				"%2d:%2d",
				data.wHour,
				data.wMinute );

	return( _time_string );
}


VOID Check_For_Duplicate_Tokens_Bug( VOID )
{
#if( DEBUG_CODE )
	INT i, j;
	GameTokenType token;

	for ( i = FIRST_PLAYER; i < Game_Status.Get_Total_Players(); i ++ ) {
		token = Players[ i ].Get_Token();
		for ( j = FIRST_PLAYER; j < Game_Status.Get_Total_Players(); j ++ ) {
			if ( j != i ) {
				if ( Players[ j ].Get_Token() == token ) {
					/*
						Sound the alarm!
					*/
					Play_Sound( SND_GOTOJAIL, PLAY_KILL_PREVIOUS_SOUND, BROADCAST_SOUND );
					Debug_Error_Window_Message( "Emergency! The annoying Double-token bug has been encountered!\r\n" );
					Debug_Error_Window_Message( "Give the .000 log file from this system/game to the Mikes!" );
					Debug_Error_Window_Message( "Get the .000 log files from the other systems in this game, too." );
					Debug_Error_Window_Message( "Other data may be hosed, so this game is probably now invalid." );
					Debug_Error_Window_Message( "With the log file, we should be able to find the stinkin' bug." );
					Debug_Error_Window_Message( "Excellent work, Mr. Bond!" );
				}
			}
		}
	}
#endif
}

#if( RIG_ROLL_FOR_PLAYTEST )
/***************************************************************************
 * DEBUG_RIG_ROLL -- Pops up dialog to fix the next dice roll              *
 *                                                                         *
 * INPUT: parent window handle                                             *
 *                                                                         *
 * OUTPUT: none                                                            *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
VOID Debug_Rig_Roll( WindowHandle window_handle )
{
	if ( ! Game_Status.Is_Game_In_Progress() ) {
		#if( DEBUG_CODE )
			Debug_Error_Window_Message( "Game not in progress!" );
		#endif
		return;
	}

	DialogBox( Global_Instance_Handle, 
				  "DebugDiceDlgBox", 
				  window_handle, 
				  (DLGPROC) Debug_Rig_Roll_Dialog_Procedure );

	#if( DEBUG_CODE )
		Debug_Mono_Message( "***** The next roll has been rigged! *****\r\n" );
	#endif

	#if( COMPILE_WINSOCK )
//	if ( Multiple_Site_Game_In_Progress ) {	
//		WinSock_Broadcast_Cmd_String( CMD_SEND_YELL_MESSAGE_STRING, 
//												Game_Status.Get_Whos_Turn_Is_It_Now(), 
//												"The next dice roll has been rigged!\r\n" );
// }
   #endif
}

#pragma argsused
/***************************************************************************
 * DEBUG_RIG_ROLL_DIALOG_PROCEDURE -- Handles commands to dialog           *
 *                                                                         *
 * INPUT: standard windows dialog command parameters                       *
 *                                                                         *
 * OUTPUT: TRUE if dice rigged, FALSE if not                               *
 *                                                                         *
 * WARNINGS: none                                                          *
 *                                                                         *
 * HISTORY: see PVCS log                                                   *
 *=========================================================================*/
PRIVATE BOOL Debug_Rig_Roll_Dialog_Procedure( WindowHandle window_handle,
															 UINT message,
															 WPARAM w_param,
															 LPARAM l_param )
{
	INT die1, die2;

	switch( message ) {
	
		case WM_COMMAND:

			if ( LOWORD( w_param ) == IDOK ) {

				GetDlgItemText( window_handle, 
									 DIE_EDIT1, 
									 Text_String, 
									 SIZE_OF_TEXT_STRING );
				die1 = atoi( Text_String );

				GetDlgItemText( window_handle, 
									 DIE_EDIT2, 
									 Text_String, 
									 SIZE_OF_TEXT_STRING );
				die2 = atoi( Text_String );

				if ( die1 < 1 || die1 > 6 || die2 < 1 || die2 > 6 ) {
					#if( DEBUG_CODE )
						Debug_Error_Window_Message( "Illegal values, defaulting to 1 & 1.\r\n" );
               #endif
					die1 = 1;
					die2 = 1;
				}

				Dice.Set_Debug_Die( 1, die1 );
				Dice.Set_Debug_Die( 2, die2 );

				sprintf( Text_String,
							"The next dice roll is rigged for a %d and a %d.\r\n",
							die1, die2 );
				Debug_Mono_Message( Text_String );

				EndDialog( window_handle, TRUE );
				return( TRUE );
			}
			break;

		default: break;

	}
	return( FALSE );
}
#endif



