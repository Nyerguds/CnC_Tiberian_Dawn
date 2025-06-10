/*
**	Command & Conquer(tm)
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
// Nyerguds 2025-06-10: converted to enum, because otherwise it can't dynamically
// increment the numbers including exceptions for specific languages.
typedef enum TextType {
	TXT_NONE=0,                   	// 
	TXT_CREDIT_FORMAT,        	// %3d.%02d
	TXT_BUTTON_UPGRADE,       	// Upgrade
	TXT_UPGRADE,              	// Upgrade Structure
	TXT_UPGRADE_BUTTON,       	// Upgrade
	TXT_BUTTON_SELL,          	// Sell
	TXT_SELL,                 	// Sell Structure
	TXT_DEMOLISH,             	// Demolish Structure
	TXT_BUTTON_REPAIR,        	// Repair
	TXT_REPAIR,               	// Repair Structure
	TXT_REPAIR_BUTTON,        	// Repair
	TXT_YOU,                  	// You:
	TXT_ENEMY,                	// Enemy:
	TXT_BUILD_DEST,           	// Buildings Destroyed By
	TXT_UNIT_DEST,            	// Units Destroyed By
	TXT_TIB_HARV,             	// Tiberium Harvested By
	TXT_SCORE_1,              	// Score: %d
	TXT_RANK_OF,              	// You have attained the rank
	TXT_YES,                  	// Yes
	TXT_NO,                   	// No
	TXT_READY,                	// Ready
	TXT_HOLDING,              	// Holding
	TXT_SCENARIO_WON,         	// Accomplished
	TXT_SCENARIO_LOST,        	// Failed
	TXT_CHOOSE_SIDE,          	// Choose Your Side
	TXT_START_NEW_GAME,       	// Start New Game
	TXT_INTRO,                	// Intro & Sneak Peek
	TXT_CANCEL,               	// Cancel
	TXT_ROCK,                 	// Rock
	TXT_CHOAM_RESUME,         	// Resume Game
	TXT_CHOAM_BUILD_THIS,     	// Build This
	TXT_THANK_YOU,            	// Thank you for playing
	TXT_FAME,                 	// Hall of Fame
	TXT_GDI,                  	// Global Defense Initiative
	TXT_NOD,                  	// Brotherhood of Nod
	TXT_CIVILIAN,             	// Civilian
	TXT_JP,                   	// Containment Team
	TXT_OK,                   	// OK
	TXT_TREE,                 	// Tree
	TXT_LEFT,                 	// 
	TXT_RIGHT,                	// 
	TXT_UP,                   	// 
	TXT_DOWN,                 	// 
	TXT_CLEAR_MAP,            	// Clear the map
	TXT_INHERIT_MAP,          	// Inherit previous map
	TXT_CLEAR,                	// Clear
	TXT_WATER,                	// Water
	TXT_ROAD,                 	// Road
	TXT_TILE,                 	// Tile Object
	TXT_SLOPE,                	// Slope
	TXT_BRUSH,                	// Brush
	TXT_PATCH,                	// Patch
	TXT_RIVER,                	// River
	TXT_LOAD_MISSION,         	// Load Mission
	TXT_SAVE_MISSION,         	// Save Mission
	TXT_DELETE_MISSION,       	// Delete Mission
	TXT_LOAD_BUTTON,          	// Load
	TXT_SAVE_BUTTON,          	// Save
	TXT_DELETE_BUTTON,        	// Delete
	TXT_GAME_CONTROLS,        	// Game Controls
	TXT_SOUND_CONTROLS,       	// Sound Controls
	TXT_RESUME_MISSION,       	// Resume Mission
	TXT_VISUAL_CONTROLS,      	// Visual Controls
	TXT_QUIT_MISSION,         	// Abort Mission
	TXT_EXIT_GAME,            	// Exit Game
	TXT_OPTIONS,              	// Options
	TXT_TIBERIUM,             	// Tiberium
	TXT_TIBERIUM_ON,          	// Tiberium On
	TXT_TIBERIUM_OFF,         	// Tiberium Off
	TXT_SQUISH,               	// Squish mark
	TXT_CRATER,               	// Crater
	TXT_SCORCH,               	// Scorch Mark
	TXT_BRIGHTNESS,           	// BRIGHTNESS:
	TXT_MUSIC,                	// MUSIC VOLUME
	TXT_VOLUME,               	// SOUND VOLUME
	TXT_TINT,                 	// TINT:
	TXT_CONTRAST,             	// CONTRAST:
	TXT_SPEED,                	// GAME SPEED:
	TXT_SCROLLRATE,           	// SCROLL RATE:
	TXT_COLOR,                	// COLOR:
	TXT_RETURN_TO_GAME,       	// Return to game
	TXT_ENEMY_SOLDIER,        	// Enemy Soldier
	TXT_ENEMY_VEHICLE,        	// Enemy Vehicle
	TXT_ENEMY_STRUCTURE,      	// Enemy Structure
	TXT_FTANK,                	// Flame Tank
	TXT_STANK,                	// Stealth Tank
	TXT_LTANK,                	// Light Tank
	TXT_MTANK,                	// Med. Tank
	TXT_HTANK,                	// Mammoth Tank
	TXT_DUNE_BUGGY,           	// Nod Buggy
	TXT_SAM,                  	// SAM Site
	TXT_EYE,                  	// Advanced Com. Center
	TXT_MLRS,                 	// Rocket Launcher
	TXT_MHQ,                  	// Mobile HQ
	TXT_JEEP,                 	// Hum-vee
	TXT_TRANS,                	// Transport Helicopter
	TXT_A10,                  	// A10
	TXT_C17,                  	// C17
	TXT_HARVESTER,            	// Harvester
	TXT_ARTY,                 	// Artillery
	TXT_MSAM,                 	// S.S.M. Launcher
	TXT_E1,                   	// Minigunner
	TXT_E2,                   	// Grenadier
	TXT_E3,                   	// Bazooka
	TXT_E4,                   	// Flamethrower
	TXT_E5,                   	// Chem-warrior
	TXT_RAMBO,                	// Commando
	TXT_HOVER,                	// Hovercraft
	TXT_HELI,                 	// Attack Helicopter
	TXT_ORCA,                 	// Orca
	TXT_APC,                  	// APC
	TXT_GUARD_TOWER,          	// Guard Tower
	TXT_COMMAND,              	// Communications Center
	TXT_HELIPAD,              	// Helicopter Pad
	TXT_AIRSTRIP,             	// Airstrip
	TXT_STORAGE,              	// Tiberium Silo
	TXT_CONST_YARD,           	// Construction Yard
	TXT_REFINERY,             	// Tiberium Refinery
	TXT_CIV1,                 	// Church
	TXT_CIV2,                 	// Han's and Gretel's
	TXT_CIV3,                 	// Hewitt's Manor
	TXT_CIV4,                 	// Ricktor's House
	TXT_CIV5,                 	// Gretchin's House
	TXT_CIV6,                 	// The Barn
	TXT_CIV7,                 	// Damon's pub
	TXT_CIV8,                 	// Fran's House
	TXT_CIV9,                 	// Music Factory
	TXT_CIV10,                	// Toymaker's
	TXT_CIV11,                	// Ludwig's House
	TXT_CIV12,                	// Haystacks
	TXT_CIV13,                	// Haystack
	TXT_CIV14,                	// Wheat Field
	TXT_CIV15,                	// Fallow Field
	TXT_CIV16,                	// Corn Field
	TXT_CIV17,                	// Celery Field
	TXT_CIV18,                	// Potato Field
	TXT_CIV20,                	// Sala's House
	TXT_CIV21,                	// Abdul's House
	TXT_CIV22,                	// Pablo's Wicked Pub
	TXT_CIV23,                	// Village Well
	TXT_CIV24,                	// Camel Trader
	TXT_CIV25,                	// Church
	TXT_CIV26,                	// Ali's House
	TXT_CIV27,                	// Trader Ted's
	TXT_CIV28,                	// Menelik's House
	TXT_CIV29,                	// Prestor John's House
	TXT_CIV30,                	// Village Well
	TXT_CIV31,                	// Witch Doctor's Hut
	TXT_CIV32,                	// Rikitikitembo's Hut
	TXT_CIV33,                	// Roarke's Hut
	TXT_CIV34,                	// Mubasa's Hut
	TXT_CIV35,                	// Aksum's Hut
	TXT_CIV36,                	// Mambo's Hut
	TXT_CIV37,                	// The Studio
	TXT_CIVMISS,              	// Technology Center
	TXT_TURRET,               	// Gun Turret
	TXT_GUNBOAT,              	// Gun Boat
	TXT_MCV,                  	// Mobile Construction Yard
	TXT_BIKE,                 	// Recon Bike
	TXT_POWER,                	// Power Plant
	TXT_ADVANCED_POWER,       	// Advanced Power Plant
	TXT_HOSPITAL,             	// Hospital
	TXT_BARRACKS,             	// Barracks
	TXT_CONCRETE,             	// Concrete
	TXT_PUMP,                 	// Oil Pump
	TXT_TANKER,               	// Oil Tanker
	TXT_SANDBAG_WALL,         	// Sandbag Wall
	TXT_CYCLONE_WALL,         	// Chain Link Fence
	TXT_BRICK_WALL,           	// Concrete Wall
	TXT_BARBWIRE_WALL,        	// Barbwire Fence
	TXT_WOOD_WALL,            	// Wood Fence
	TXT_WEAPON_FACTORY,       	// Weapons Factory
	TXT_AGUARD_TOWER,         	// Advanced Guard Tower
	TXT_OBELISK,              	// Obelisk Guard Tower
	TXT_BIO_LAB,              	// Bio-Research Laboratory
	TXT_HAND,                 	// Hand of Nod
	TXT_TEMPLE,               	// Temple of Nod
	TXT_FIX_IT,               	// Repair Bay
	TXT_TAB_SIDEBAR,          	// Sidebar
	TXT_TAB_BUTTON_CONTROLS,  	// Options
	TXT_TAB_BUTTON_DATABASE,  	// Database
	TXT_SHADOW,               	// Unrevealed Terrain
	TXT_OPTIONS_MENU,         	// Options Menu
	TXT_STOP,                 	// STOP
	TXT_PLAY,                 	// PLAY
	TXT_SHUFFLE,              	// SHUFFLE
	TXT_REPEAT,               	// REPEAT
	TXT_MUSIC_VOLUME,         	// Music volume:
	TXT_SOUND_VOLUME,         	// Sound volume:
	TXT_ON,                   	// On
	TXT_OFF,                  	// Off
	TXT_THEME_AOI,            	// Act On Instinct
	TXT_THEME_TROUBLE,        	// Looks Like Trouble
	TXT_THEME_IND,            	// Industrial
	TXT_THEME_ROUT,           	// Reaching Out
	TXT_THEME_OTP,            	// On The Prowl
	TXT_THEME_PRP,            	// Prepare For Battle
	TXT_THEME_JUSTDOIT,       	// Just Do It!
	TXT_THEME_LINEFIRE,       	// In The Line Of Fire
	TXT_THEME_MARCH,          	// March To Doom
	TXT_THEME_STOPTHEM,       	// Deception
	TXT_THEME_CCTHANG,        	// C&C Thang
	TXT_THEME_BEFEARED,       	// Enemies To Be Feared
	TXT_THEME_WARFARE,        	// Warfare
	TXT_THEME_FWP,            	// Fight, Win, Prevail
	TXT_THEME_DIE,            	// Die!!
	TXT_THEME_NOMERCY,        	// No Mercy
	TXT_THEME_TARGET,         	// Mechanical Man
	TXT_THEME_IAM,            	// I Am
	TXT_THEME_WIN1,           	// Great Shot!
	TXT_MULTIPLAYER_GAME,     	// Multiplayer Game
	TXT_NO_FILES,             	// No files available
	TXT_DELETE_SINGLE_FILE,   	// Do you want to delete this
	TXT_DELETE_MULTIPLE_FILES,	// Do you want to delete %d
	TXT_RESET_MENU,           	// Reset Values
	TXT_CONFIRMATION,         	// Confirmation
	TXT_CONFIRM_EXIT,         	// Do you want to abort the
	TXT_MISSION_DESCRIPTION,  	// Mission Description
	TXT_C1,                   	// Joe
	TXT_C2,                   	// Bill
	TXT_C3,                   	// Shelly
	TXT_C4,                   	// Maria
	TXT_C5,                   	// Eydie
	TXT_C6,                   	// Dave
	TXT_C7,                   	// Phil
	TXT_C8,                   	// Dwight
	TXT_C9,                   	// Erik
	TXT_MOEBIUS,              	// Dr. Moebius
	TXT_BIB,                  	// Road Bib
	TXT_FASTER,               	// Faster
	TXT_SLOWER,               	// Slower
	TXT_ION_CANNON,           	// Ion Cannon
	TXT_NUKE_STRIKE,          	// Nuclear Strike
	TXT_AIR_STRIKE,           	// Air Strike
	TXT_TREX,                 	// Tyrannosaurus Rex
	TXT_TRIC,                 	// Triceratops
	TXT_RAPT,                 	// Velociraptor
	TXT_STEG,                 	// Stegasaurus
	TXT_STEEL_CRATE,          	// Steel Crate
	TXT_WOOD_CRATE,           	// Wood Crate
	TXT_FLAG_SPOT,            	// Flag Location
	TXT_G_D_I,                	// GDI
	TXT_N_O_D,                	// NOD
	TXT_UNABLE_READ_SCENARIO, 	// Unable to read scenario!
	TXT_ERROR_LOADING_GAME,   	// Error loading game!
	TXT_OBSOLETE_SAVEGAME,    	// Obsolete saved game.
	TXT_MUSTENTER_DESCRIPTION,	// You must enter a
	TXT_ERROR_SAVING_GAME,    	// Error saving game!
	TXT_DELETE_FILE_QUERY,    	// Delete this file?
	TXT_EMPTY_SLOT,           	// [EMPTY SLOT]
	TXT_SELECT_MPLAYER_GAME,  	// Select Multiplayer Game
	TXT_MODEM_SERIAL,         	// Modem/Serial
	TXT_NETWORK,              	// Network
	TXT_INIT_NET_ERROR,       	// Unable to initialize
	TXT_JOIN_NETWORK_GAME,    	// Join Network Game
	TXT_NEW,                  	// New
	TXT_JOIN,                 	// Join
	TXT_SEND_MESSAGE,         	// Send Message
	TXT_YOUR_NAME,            	// Your Name:
	TXT_SIDE_COLON,           	// Side:
	TXT_COLOR_COLON,          	// Color:
	TXT_GAMES,                	// Games
	TXT_PLAYERS,              	// Players
	TXT_SCENARIO_COLON,       	// Scenario:
	TXT_NOT_FOUND,            	// >> NOT FOUND <<
	TXT_START_CREDITS_COLON,  	// Starting Credits:
	TXT_BASES_COLON,          	// Bases:
	TXT_TIBERIUM_COLON,       	// Tiberium:
	TXT_CRATES_COLON,         	// Crates:
	TXT_AI_PLAYERS_COLON,     	// AI Players:
	TXT_REQUEST_DENIED,       	// Request denied.
	TXT_UNABLE_PLAY_WAAUGH,   	// Unable to play; scenario
	TXT_NOTHING_TO_JOIN,      	// Nothing to join!
	TXT_NAME_ERROR,           	// You must enter a name!
	TXT_DUPENAMES_NOTALLOWED, 	// Duplicate names are not
	TXT_YOURGAME_OUTDATED,    	// Your game version is
	TXT_DESTGAME_OUTDATED,    	// Destination game version is
	TXT_THATGUYS_GAME,        	// %s's Game
	TXT_THATGUYS_GAME_BRACKET,	// [%s's Game]
	TXT_NETGAME_SETUP,        	// Network Game Setup
	TXT_REJECT,               	// Reject
	TXT_CANT_REJECT_SELF,     	// You can't reject yourself! 
	TXT_SELECT_PLAYER_REJECT, 	// You must select a player to
	TXT_BASES_ON,             	// Bases On
	TXT_BASES_OFF,            	// Bases Off
	TXT_CRATES_ON,            	// Crates On
	TXT_CRATES_OFF,           	// Crates Off
	TXT_AI_PLAYERS_ON,        	// AI Players On
	TXT_AI_PLAYERS_OFF,       	// AI Players Off
	TXT_SCENARIOS,            	// Scenarios
	TXT_START_CREDITS,        	// Starting Credits
	TXT_ONLY_ONE,             	// Only one player?
	TXT_OOPS,                 	// Oops!
	TXT_TO,                   	// To %s:
	TXT_TO_ALL,               	// To All:
	TXT_MESSAGE,              	// Message:
	TXT_CONNECTION_LOST,      	// Connection to %s lost!
	TXT_LEFT_GAME,            	// %s has left the game.
	TXT_PLAYER_DEFEATED,      	// %s has been defeated!
	TXT_WAITING_CONNECT,      	// Waiting to Connect...
	TXT_NULL_CONNERR_CHECK_CABLES,	// Connection error! Check
	TXT_MODEM_CONNERR_REDIALING,	// Connection
	TXT_MODEM_CONNERR_WAITING,	// Connection error! Waiting
	TXT_SELECT_SERIAL_GAME,   	// Select Serial Game
	TXT_DIAL_MODEM,           	// Dial Modem
	TXT_ANSWER_MODEM,         	// Answer Modem
	TXT_NULL_MODEM,           	// Null Modem
	TXT_SETTINGS,             	// Settings
	TXT_PORT_COLON,           	// Port:
	TXT_IRQ_COLON,            	// IRQ:
	TXT_BAUD_COLON,           	// Baud:
	TXT_INIT_STRING,          	// Init String:
	TXT_CWAIT_STRING,         	// Call Waiting String:
	TXT_TONE_BUTTON,          	// Tone Dialing
	TXT_PULSE_BUTTON,         	// Pulse Dialing
	TXT_HOST_SERIAL_GAME,     	// Host Serial Game
	TXT_OPPONENT_COLON,       	// Opponent:
	TXT_USER_SIGNED_OFF,      	// User signed off!
	TXT_JOIN_SERIAL_GAME,     	// Join Serial Game
	TXT_PHONE_LIST,           	// Phone List
	TXT_ADD,                  	// Add
	TXT_EDIT,                 	// Edit
	TXT_DIAL,                 	// Dial
	TXT_DEFAULT,              	// Default
	TXT_DEFAULT_SETTINGS,     	// Default Settings
	TXT_CUSTOM_SETTINGS,      	// Custom Settings
	TXT_PHONE_LISTING,        	// Phone Listing
	TXT_NAME_COLON,           	// Name:
	TXT_NUMBER_COLON,         	// Number:
	TXT_UNABLE_FIND_MODEM,    	// Unable to find modem. Check
	TXT_NO_CARRIER,           	// No carrier.
	TXT_LINE_BUSY,            	// Line busy.
	TXT_NUMBER_INVALID,       	// Number invalid.
	TXT_SYSTEM_NOT_RESPONDING,	// Other system not
	TXT_OUT_OF_SYNC,          	// Games are out of sync!
	TXT_PACKET_TOO_LATE,      	// Packet received too late!
	TXT_PLAYER_LEFT_GAME,     	// Other player has left the
	TXT_FROM,                 	// From %s:%s
	TXT_MAP_P01,              	// 2,728,000
	TXT_MAP_P02,              	// 38,385,000
	TXT_MAP_P03,              	// 10,373,000
	TXT_MAP_P04,              	// 51,994,000
	TXT_MAP_P05,              	// 80,387,000
	TXT_MAP_P06,              	// 10,400,000
	TXT_MAP_P07,              	// 5,300,000
	TXT_MAP_P08,              	// 7,867,000
	TXT_MAP_P09,              	// 10,333,000
	TXT_MAP_P10,              	// 1,974,000
	TXT_MAP_P11,              	// 23,169,000
	TXT_MAP_P12,              	// 10,064,000
	TXT_MAP_P13,              	// 3,285,000
	TXT_MAP_P14,              	// 8,868,000
	TXT_MAP_P15,              	// 10,337,000
	TXT_MAP_P16,              	// 4,365,000
	TXT_MAP_P17,              	// 1,607,000
	TXT_MAP_P18,              	// 4,485,000
	TXT_MAP_P19,              	// 56,386,000
	TXT_MAP_P20,              	// 28,305,000
	TXT_MAP_P21,              	// 5,238,000
	TXT_MAP_P22,              	// 2,059,000
	TXT_MAP_P23,              	// 13,497,000
	TXT_MAP_P24,              	// 4,997,000
	TXT_MAP_P25,              	// 88,500,000
	TXT_MAP_P26,              	// 1,106,000
	TXT_MAP_P27,              	// 12,658,000
	TXT_MAP_P28,              	// 3,029,000
	TXT_MAP_P29,              	// 39,084,000
	TXT_MAP_P30,              	// 23,154,000
	TXT_MAP_P31,              	// 8,902,000
	TXT_MAP_P32,              	// 27,791,000
	TXT_MAP_P33,              	// 1,574,000
	TXT_MAP_P34,              	// 15,469,000
	TXT_MAP_P35,              	// 1,300,000
	TXT_MAP_P36,              	// 41,688,000
	TXT_MAP_A00,              	// 24,900 SQ. MI.
	TXT_MAP_A01,              	// 120,727 SQ. MI.
	TXT_MAP_A02,              	// 80,134 SQ. MI.
	TXT_MAP_A03,              	// 233,100 SQ. MI.
	TXT_MAP_A04,              	// 137,838 SQ. MI.
	TXT_MAP_A05,              	// 30,449 SQ. MI.
	TXT_MAP_A06,              	// 18,932 SQ. MI.
	TXT_MAP_A07,              	// 32,377 SQ. MI.
	TXT_MAP_A08,              	// 35,919 SQ. MI.
	TXT_MAP_A09,              	// 7,819 SQ. MI.
	TXT_MAP_A10,              	// 91,699 SQ. MI.
	TXT_MAP_A11,              	// 51,146 SQ. MI.
	TXT_MAP_A12,              	// 11,100 SQ. MI.
	TXT_MAP_A13,              	// 44,365 SQ. MI.
	TXT_MAP_A14,              	// 39,449 SQ. MI.
	TXT_MAP_A15,              	// 19,741 SQ. MI.
	TXT_MAP_A16,              	// 17,413 SQ. MI.
	TXT_MAP_C00,              	// RIGA
	TXT_MAP_C01,              	// WARSAW
	TXT_MAP_C02,              	// MINSK
	TXT_MAP_C03,              	// KIEV
	TXT_MAP_C04,              	// BERLIN
	TXT_MAP_C05,              	// PRAGUE
	TXT_MAP_C06,              	// BRATISLAVA
	TXT_MAP_C07,              	// VIENNA
	TXT_MAP_C08,              	// BUDAPEST
	TXT_MAP_C09,              	// LJUBLJANA
	TXT_MAP_C10,              	// BUCHAREST
	TXT_MAP_C11,              	// ATHENS
	TXT_MAP_C12,              	// TIRANA
	TXT_MAP_C13,              	// SOFIA
	TXT_MAP_C14,              	// BELGRADE
	TXT_MAP_C15,              	// SARAJEVO
	TXT_MAP_C16,              	// TALLINN
	TXT_MAP_C17,              	// TRIPOLI
	TXT_MAP_C18,              	// CAIRO
	TXT_MAP_C19,              	// KHARTOUM
	TXT_MAP_C20,              	// N'DJAMENA
	TXT_MAP_C21,              	// NOUAKCHOTT
	TXT_MAP_C22,              	// YAMOUSSOUKRO
	TXT_MAP_C23,              	// PORTO-NOVO
	TXT_MAP_C24,              	// ABUJA
	TXT_MAP_C25,              	// LIBREVILLE
	TXT_MAP_C26,              	// YAOUNDE
	TXT_MAP_C27,              	// BANGUI
	TXT_MAP_C28,              	// KINSHASA
	TXT_MAP_C29,              	// CAIRO
	TXT_MAP_C30,              	// LUANDA
	TXT_MAP_C31,              	// DAR-ES-SALAAM
	TXT_MAP_C32,              	// WINDHOEK
	TXT_MAP_C33,              	// MAPUTO
	TXT_MAP_C34,              	// GABARONE
	TXT_MAP_C35,              	// CAPE TOWN
	TXT_MAP_GDP00,            	// NEGLIGIBLE
	TXT_MAP_GDP01,            	// $162.7 BLN
	TXT_MAP_GDP02,            	// $47.6 BLN
	TXT_MAP_GDP03,            	// $1,131 BLN
	TXT_MAP_GDP04,            	// $120 BLN
	TXT_MAP_GDP05,            	// $164 BLN
	TXT_MAP_GDP06,            	// $60.1 BLN
	TXT_MAP_GDP07,            	// $21 BLN
	TXT_MAP_GDP08,            	// $71.9 BLN
	TXT_MAP_GDP09,            	// $77 BLN
	TXT_MAP_GDP10,            	// $4.0 BLN
	TXT_MAP_GDP11,            	// $47.3 BLN
	TXT_MAP_GDP12,            	// $120.1 BLN
	TXT_MAP_GDP13,            	// $14.0 BLN
	TXT_MAP_GDP14,            	// $28.9 BLN
	TXT_MAP_GDP15,            	// $39.2 BLN
	TXT_MAP_GDP16,            	// $12.1 BLN
	TXT_MAP_GDP17,            	// $1.0 BLN
	TXT_MAP_GDP18,            	// $10.0 BLN
	TXT_MAP_GDP19,            	// $1.7 BLN
	TXT_MAP_GDP20,            	// $28.0 BLN
	TXT_MAP_GDP21,            	// $5.3 BLN
	TXT_MAP_GDP22,            	// $11.6 BLN
	TXT_MAP_GDP23,            	// $1.3 BLN
	TXT_MAP_GDP24,            	// $6.6 BLN
	TXT_MAP_GDP25,            	// $8.3 BLN
	TXT_MAP_GDP26,            	// $6.9 BLN
	TXT_MAP_GDP27,            	// $2.0 BLN
	TXT_MAP_GDP28,            	// $3.1 BLN
	TXT_MAP_GDP29,            	// $104.0 BLN
	TXT_MAP_PC00,             	// JELGAVA
	TXT_MAP_PC01,             	// GDANSK
	TXT_MAP_PC02,             	// BYELISTOK
	TXT_MAP_PC03,             	// BOBYRUSK
	TXT_MAP_PC04,             	// IVANO-FRANKOVSK
	TXT_MAP_PC05,             	// HANOVER
	TXT_MAP_PC06,             	// DRESDEN
	TXT_MAP_PC07,             	// OSTRAVA
	TXT_MAP_PC08,             	// BRATISLAVA
	TXT_MAP_PC09,             	// SALZBURG
	TXT_MAP_PC10,             	// BUDAPEST
	TXT_MAP_PC11,             	// TRIESTE
	TXT_MAP_PC12,             	// ARAD
	TXT_MAP_PC13,             	// CORINTH
	TXT_MAP_PC14,             	// SHKODER
	TXT_MAP_PC15,             	// SOFIA
	TXT_MAP_PC16,             	// NIS
	TXT_MAP_PC17,             	// BELGRADE
	TXT_MAP_PC18,             	// ?
	TXT_MAP_PC19,             	// PARNU
	TXT_MAP_PC20,             	// TMASSAH
	TXT_MAP_PC21,             	// AL-ALAMYN
	TXT_MAP_PC22,             	// AL-KHARIJAH
	TXT_MAP_PC23,             	// AL-UBAYYID
	TXT_MAP_PC24,             	// KAFIA-KINGI
	TXT_MAP_PC25,             	// OUM HADJER
	TXT_MAP_PC26,             	// MAO
	TXT_MAP_PC27,             	// TIDJIKDJA
	TXT_MAP_PC28,             	// ABIDJAN
	TXT_MAP_PC29,             	// PORTO-NOVO
	TXT_MAP_PC30,             	// ABUJA
	TXT_MAP_PC31,             	// KOULA-MOUTOU
	TXT_MAP_PC32,             	// BERTOUA
	TXT_MAP_PC33,             	// BANGASSOU
	TXT_MAP_PC34,             	// LODJA
	TXT_MAP_PC35,             	// KINSHASA
	TXT_MAP_PC36,             	// LUXOR
	TXT_MAP_PC37,             	// CAIUNDO
	TXT_MAP_PC38,             	// MZUZU
	TXT_MAP_PC39,             	// KEETMANSHOOP
	TXT_MAP_PC40,             	// XAI-XAI
	TXT_MAP_PC41,             	// GHANZI
	TXT_MAP_PC42,             	// CAPE TOWN
	TXT_MAP_GDI,              	// GDI PROGRESSION
	TXT_MAP_NOD,              	// NOD PROGRESSION
	TXT_MAP_LOCATE,           	// LOCATING COORDINATES
	TXT_MAP_NEXT_MISSION,     	// OF NEXT MISSION
#if (GERMAN | FRENCH)
	TXT_MAP_NEXT_MISS2,       	// MISSION
#endif
	TXT_MAP_SELECT,           	// SELECT TERRITORY
	TXT_MAP_TO_ATTACK,        	// TO ATTACK
	TXT_MAP_GDISTAT0,         	// POPULATION:
	TXT_MAP_GDISTAT1,         	// GEOGRAPHIC AREA:
	TXT_MAP_GDISTAT2,         	// CAPITAL:
	TXT_MAP_GDISTAT3,         	// GOVERNMENT:
	TXT_MAP_GDISTAT4,         	// GROSS DOMESTIC PRODUCT:
	TXT_MAP_GDISTAT5,         	// POINT OF CONFLICT:
	TXT_MAP_GDISTAT6,         	// MILITARY POWER:
	TXT_MAP_NODSTAT0,         	// EXPENDABILITY:
	TXT_MAP_NODSTAT1,         	// GOVT CORRUPTABILITY:
	TXT_MAP_NODSTAT2,         	// NET WORTH:
	TXT_MAP_NODSTAT3,         	// MILITARY STRENGTH:
	TXT_MAP_NODSTAT4,         	// MILITARY RESISTANCE:
	TXT_MAP_COUNTRYNAME0,     	// LATVIA
	TXT_MAP_COUNTRYNAME1,     	// POLAND
	TXT_MAP_COUNTRYNAME2,     	// BELARUS
	TXT_MAP_COUNTRYNAME3,     	// UKRAINE
	TXT_MAP_COUNTRYNAME4,     	// GERMANY
	TXT_MAP_COUNTRYNAME5,     	// CZECH REPUBLIC
	TXT_MAP_COUNTRYNAME6,     	// SLOVAKIA
	TXT_MAP_COUNTRYNAME7,     	// AUSTRIA
	TXT_MAP_COUNTRYNAME8,     	// HUNGARY
	TXT_MAP_COUNTRYNAME9,     	// SLOVENIA
	TXT_MAP_COUNTRYNAME10,    	// ROMANIA
	TXT_MAP_COUNTRYNAME11,    	// GREECE
	TXT_MAP_COUNTRYNAME12,    	// ALBANIA
	TXT_MAP_COUNTRYNAME13,    	// BULGARIA
	TXT_MAP_COUNTRYNAME14,    	// YUGOSLAVIA
	TXT_MAP_COUNTRYNAME15,    	// BOSNIA/HERZOGOVINA
	TXT_MAP_COUNTRYNAME16,    	// LIBYA
	TXT_MAP_COUNTRYNAME17,    	// EGYPT
	TXT_MAP_COUNTRYNAME18,    	// SUDAN
	TXT_MAP_COUNTRYNAME19,    	// CHAD
	TXT_MAP_COUNTRYNAME20,    	// MAURITANIA
	TXT_MAP_COUNTRYNAME21,    	// IVORY COAST
	TXT_MAP_COUNTRYNAME22,    	// BENIN
	TXT_MAP_COUNTRYNAME23,    	// NIGERIA
	TXT_MAP_COUNTRYNAME24,    	// GABON
	TXT_MAP_COUNTRYNAME25,    	// CAMEROON
	TXT_MAP_COUNTRYNAME26,    	// CENTRAL AFRICAN REPUBLIC
	TXT_MAP_COUNTRYNAME27,    	// ZAIRE
	TXT_MAP_COUNTRYNAME28,    	// ANGOLA
	TXT_MAP_COUNTRYNAME29,    	// TANZANIA
	TXT_MAP_COUNTRYNAME30,    	// NAMIBIA
	TXT_MAP_COUNTRYNAME31,    	// MOZAMBIQUE
	TXT_MAP_COUNTRYNAME32,    	// BOTSWANA
	TXT_MAP_COUNTRYNAME33,    	// SOUTH AFRICA
	TXT_MAP_COUNTRYNAME34,    	// ESTONIA
	TXT_MAP_GOVT0,            	// REPUBLIC
	TXT_MAP_GOVT1,            	// DEMOCRATIC STATE
	TXT_MAP_GOVT2,            	// FEDERAL REPUBLIC
	TXT_MAP_GOVT3,            	// CONST. REPUBLIC
	TXT_MAP_GOVT4,            	// PARL. DEMOCRACY
	TXT_MAP_GOVT5,            	// PRES. PARL. REPUBLIC
	TXT_MAP_GOVT6,            	// DEMOCRACY
	TXT_MAP_GOVT7,            	// IN TRANSITION
	TXT_MAP_GOVT8,            	// ISLAMIC SOCIALIST
	TXT_MAP_GOVT9,            	// MILITARY
	TXT_MAP_GOVT10,           	// ISLAMIC REPUBLIC
	TXT_MAP_GOVT11,           	// PARL. REPUBLIC
	TXT_MAP_ARMY0,            	// LOCAL MILITIA
	TXT_MAP_ARMY1,            	// STATE MILITIA
	TXT_MAP_ARMY2,            	// NATIONAL GUARD
	TXT_MAP_ARMY3,            	// FREE STANDING ARMY
	TXT_MAP_ARMY4,            	// ?
	TXT_MAP_ARMY5,            	// NATIONAL POWER
	TXT_MAP_MILITARY0,        	// RESPECTABLE
	TXT_MAP_MILITARY1,        	// FORMIDABLE
	TXT_MAP_MILITARY2,        	// LAUGHABLE
	TXT_MAP_MILITARY3,        	// REASONABLE
	TXT_MAP_MILITARY4,        	// INSIGNIFICANT
	TXT_MAP_CLICK2,           	// CLICK TO CONTINUE
	TXT_MAP_LMH0,             	// LOW
	TXT_MAP_LMH1,             	// MEDIUM
	TXT_MAP_LMH2,             	// HIGH
	TXT_SCORE_TIME,           	// TIME:
	TXT_SCORE_LEAD,           	// LEADERSHIP:
	TXT_SCORE_EFFI,           	// EFFICIENCY:
	TXT_SCORE_TOTA,           	// TOTAL SCORE:
	TXT_SCORE_CASU,           	// CASUALTIES:
	TXT_SCORE_NEUT,           	// NEUTRAL:
	TXT_SCORE_GDI,            	// GDI:
	TXT_SCORE_BUIL,           	// BUILDINGS LOST
	TXT_SCORE_BUIL1,          	// BUILDINGS
	TXT_SCORE_BUIL2,          	// LOST:
	TXT_SCORE_TOP,            	// TOP SCORES
	TXT_SCORE_ENDCRED,        	// ENDING CREDITS:
	TXT_SCORE_TIMEFORMAT1,    	// %dh %dm
	TXT_SCORE_TIMEFORMAT2,    	// %dm
	TXT_SCORE_NOD,            	// NOD:
	TXT_DIALING,              	// Dialing...
	TXT_DIALING_CANCELED,     	// Dialing Canceled
	TXT_WAITING_FOR_CALL,     	// Waiting for Call...
	TXT_ANSWERING_CANCELED,   	// Answering Canceled
	TXT_E7,                   	// Engineer
	TXT_SPECIAL_OPTIONS,      	// Special Options
	TXT_VISIBLE_TARGET,       	// Targeting flash visible to
	TXT_TREE_TARGET,          	// Allow targeting of trees.
	TXT_MCV_DEPLOY,           	// Allow undeploy of
	TXT_SMART_DEFENCE,        	// Employ smarter self defense
	TXT_SLOW_BUILD,           	// Moderate production speed.
	TXT_THREE_POINT,          	// Use three point turn logic.
	TXT_TIBERIUM_GROWTH,      	// Tiberium will grow.
	TXT_TIBERIUM_SPREAD,      	// Tiberium will spread.
	TXT_ROAD_PIECES,          	// Disable building "bib"
	TXT_SCATTER,              	// Allow running from
	TXT_MODEM_OR_LOOPBACK,    	// Not a Null Modem Cable
	TXT_MAP,                  	// Map
	TXT_FROM_COMPUTER,        	// From Computer:
	TXT_COMP_MSG1,            	// Prepare to die!
	TXT_COMP_MSG2,            	// How about a bullet
	TXT_COMP_MSG3,            	// Incoming!
	TXT_COMP_MSG4,            	// I see you!
	TXT_COMP_MSG5,            	// Hey, I'm over here!
	TXT_COMP_MSG6,            	// Come get some!
	TXT_COMP_MSG7,            	// I got you!
	TXT_COMP_MSG8,            	// You humans are never a
	TXT_COMP_MSG9,            	// Abort, Retry, Ignore? (Ha
	TXT_COMP_MSG10,           	// Format another? (Just
	TXT_COMP_MSG11,           	// Beat me and I'll reboot!
	TXT_COMP_MSG12,           	// You're artificial
	TXT_COMP_MSG13,           	// My AI is better than your
	TXT_THEME_AIRSTRIKE,      	// Air Strike
	TXT_THEME_HEAVYG,         	// Demolition
	TXT_THEME_J1,             	// Untamed Land
	TXT_THEME_JDI_V2,         	// Take 'em Out
	TXT_THEME_RADIO,          	// Radio
	TXT_THEME_RAIN,           	// Rain In The Night
	TXT_THEME_IND2,           	// Canyon Chase
	TXT_THEME_HEART,          	// Heartbreak
	TXT_BLOSSOM_TREE,         	// Blossom Tree
	TXT_RESTATE_MISSION,      	// Restate
	TXT_COMPUTER,             	// Computer
	TXT_COUNT,                	// Unit Count:
	TXT_LEVEL,                	// Tech Level:
	TXT_OPPONENT,             	// Opponent
	TXT_KILLS_COLON,          	// Kills:
	TXT_VIDEO,                	// Video
	TXT_C10,                  	// Nikoomba
	TXT_CAPTURE_THE_FLAG,     	// Capture The Flag
	TXT_THEME_VALK,           	// Ride of the Valkyries
	TXT_OBJECTIVE,            	// Mission Objective
	TXT_MISSION,              	// Mission
	TXT_NO_SAVES,             	// No saved games available.
	TXT_CIVILIAN_BUILDING,    	// Civilian Building
	TXT_TECHNICIAN,           	// Technician
	TXT_VISCEROID,            	// Visceroid
	TXT_NO_SAVELOAD,          	// Save game options are not
	TXT_DEFENDER_ADVANTAGE,   	// Defender has the advantage.
	TXT_SHOW_NAMES,           	// Show true object names.
	TXT_DELPHI,               	// Agent Delphi
	TXT_TO_REPLAY,            	// Would you like to replay
	TXT_RECONN_TO,            	// Reconnecting to %s.
	TXT_PLEASE_WAIT,          	// Please wait %02d seconds.
	TXT_SURRENDER,            	// Do you wish to surrender?
	TXT_GDI_NAME,             	// GLOBAL DEFENSE INITIATIVE
#if (GERMAN | FRENCH)
	TXT_GDI_NAME2,            	// INITIATIVE
#endif
	TXT_NOD_NAME,             	// BROTHERHOOD OF NOD
	TXT_SEL_TRANS,            	// SELECT TRANSMISSION
	TXT_GAMENAME_MUSTBE_UNIQUE,	// Your game name must be
	TXT_GAME_IS_CLOSED,       	// Game is closed.
	TXT_NAME_MUSTBE_UNIQUE,   	// Your name must be unique.
	TXT_RECONNECTING_TO,      	// Reconnecting to %s
	TXT_WAITING_FOR_CONNECTIONS,	// Waiting for connections...
	TXT_TIME_ALLOWED,         	// Time allowed: %02d seconds
	TXT_PRESS_ESC,            	// Press ESC to cancel.
	TXT_JUST_YOU_AND_ME,      	// From Computer: It's just
	TXT_CAPTURE_THE_FLAG_COLON,	// Capture the Flag:
	TXT_CHAN,                 	// Dr. Chan
	TXT_HAS_ALLIED,           	// %s has allied with %s
	TXT_AT_WAR,               	// %s declares war on %s
	TXT_SEL_TARGET,           	// Select a target
	TXT_SEPARATE_HELIPAD,     	// Allow separate helipad
	TXT_RESIGN,               	// Resign Game
	TXT_TIBERIUM_FAST,        	// Tiberium grows quickly.
	TXT_ANSWERING,            	// Answering...
	TXT_INITIALIZING_MODEM,   	// Initializing Modem...
	TXT_SCENARIOS_DO_NOT_MATCH,	// Scenarios don't match.
	TXT_POWER_OUTPUT,         	// Power Output
	TXT_POWER_OUTPUT_LOW,     	// Power Output (low)
	TXT_CONTINUE,             	// Continue
	TXT_QUEUE_FULL,           	// Data Queue Overflow
	TXT_SPECIAL_WARNING,      	// %s changed game options!
	TXT_CD_DIALOG_1,          	// Please insert a Command &
	TXT_CD_DIALOG_2,          	// Please insert CD %d (%s)
	TXT_CD_ERROR1,            	// Command & Conquer is unable
	TXT_NO_SOUND_CARD,        	// No Sound Card Detected
	TXT_UNKNOWN,              	// UNKNOWN
	TXT_OLD_GAME,             	// (old)
	TXT_NO_SPACE,             	// Insufficient Disk Space to
	TXT_MUST_HAVE_SPACE,      	// You must have %d megabytes
	TXT_RUN_SETUP,            	// Run SETUP program first.
	TXT_WAITING_FOR_OPPONENT, 	// Waiting for Opponent
	TXT_SELECT_SETTINGS,      	// Please select 'Settings' to
	TXT_PRISON,               	// Prison
	TXT_GAME_WAS_SAVED,       	// Game Saved
	TXT_SPACE_CANT_SAVE,      	// Insufficient disk space to
	TXT_INVALID_PORT_ADDRESS, 	// Invalid Port/Address. COM
	TXT_INVALID_SETTINGS,     	// Invalid Port and/or IRQ
	TXT_IRQ_ALREADY_IN_USE,   	// IRQ already in use
	TXT_ABORT,                	// Abort
	TXT_RESTART,              	// Restart
	TXT_RESTARTING,           	// Mission is
	TXT_LOADING,              	// Mission is loading. Please
	TXT_ERROR_IN_INITSTRING,  	// Error in the InitString
	TXT_ORDER_INFO,           	// Order Info
	TXT_SCENES,               	// Scenes
	TXT_NEW_MISSIONS,         	// New Missions
	TXT_THEME_CHRG,           	// Depth Charge
	TXT_THEME_DRON,           	// Drone
	TXT_THEME_FIST,           	// Iron Fist
	TXT_THEME_CREP,           	// Creeping Upon
	TXT_THEME_80MX,           	// C&C 80's Mix
	TXT_THEME_DRIL,           	// Drill
	TXT_CD_DIALOG_3,          	// Please insert the Covert
	TXT_THEME_RECON,          	// Recon
	TXT_THEME_VOICE,          	// Voice Rhythm
	TXT_ERROR_NO_INIT,        	// Error - modem did not
	TXT_NO_FLOW_CONTROL_RESPONSE,	// Error - Modem failed to
	TXT_NO_COMPRESSION_RESPONSE,	// Error - Modem failed to
	TXT_NO_ERROR_CORRECTION_RESPONSE,	// Error - Modem failed to
	TXT_ERROR_NO_DISABLE,     	// Error - unable to disable
	TXT_ERROR_TOO_MANY,       	// Error - Too many errors
	TXT_IGNORE,               	// Ignore
	TXT_CONNECTING,           	// Connecting... Please Wait.
	TXT_EXPLAIN_REGISTRATION, 	// To play Command & Conquer
	TXT_REGISTER,             	// Register
	TXT_ERROR_UNABLE_TO_RUN_WCHAT,	// Wchat not installed. Please
	TXT_INTERNET,             	// Internet Game
	TXT_UNABLE_TO_SET_VIDEO_MODE,	// Error - Unable to set the
	TXT_UNABLE_TO_ALLOCATE_PRIMARY_VIDEO_BUFFER,	// Error - Unable to allocate
	TXT_NO_DIAL_TONE,         	// No dial tone. Ensure your
	TXT_MODEM_INITIALISATION, 	// Modem Initialization
	TXT_DATA_COMPRESSION,     	// Data Compression
	TXT_ERROR_CORRECTION,     	// Error Correction
	TXT_HARDWARE_FLOW_CONTROL,	// Hardware Flow Control
	TXT_ADVANCED,             	// Advanced
	TXT_JUST_INTRO,           	// Intro
#if (GERMAN | FRENCH | JAPANESE | EXPANDED_STRINGS)
	TXT_READING_IMAGE_DATA,   	// READING IMAGE DATA
	TXT_ANALYZING,            	// ANALYZING
	TXT_ENHANCING_IMAGE_DATA, 	// ENHANCING IMAGE DATA
	TXT_ISOLATING_OPERATIONAL_THEATER,	// ISOLATING OPERATIONAL
	TXT_ESTABLISHING_TRADITIONAL_BOUNDARIES,	// ESTABLISHING TRADITIONAL
	TXT_FOR_VISUAL_REFERENCE, 	// FOR VISUAL REFERENCE
	TXT_ENHANCING_IMAGE,      	// ENHANCING IMAGE
#endif
#ifdef BONUS_MISSIONS
	TXT_BONUS_MISSIONS,       	// Bonus Missions
	TXT_BONUS_MISSION_1,      	// Bonus Mission 1
	TXT_BONUS_MISSION_2,      	// Bonus Mission 2
	TXT_BONUS_MISSION_3,      	// Bonus Mission 3
	TXT_BONUS_MISSION_4,      	// Bonus Mission 4
	TXT_BONUS_MISSION_5,      	// Bonus Mission 5
#endif
} TextType;