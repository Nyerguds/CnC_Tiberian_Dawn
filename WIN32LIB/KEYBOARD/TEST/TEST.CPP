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
 *                 Project Name : GraphicBufferClass Test Program                              *
 *                                                                                             *
 *                    File Name : DRAWTEST.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : September 25, 1995                                           *
 *                                                                                             *
 *                  Last Update : September 27, 1995 [ST]                                      *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Functions:                                                                                  *
 *  WinMain 		-- Program entry point                                                     *
 *  WndProc			-- Callback procedure for main window                                      *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */



#define WIN32
#define WIN32_LEAN_AND_MEAN
#include <wwlib32.h>
#include	<direct.h>
#include "..\mouse.h"
#define NAME "KEYBOARD/MOUSE test"
#define TITLE "KEYBOARD/MOUSE library test"


//
// Misc globals for testing
//
BOOL			AllDone = FALSE;					// Flag that we should exit

#define	MODE_WIDTH	640						// Width in pixels of required video mode
#define	MODE_HEIGHT	400						// Height in pixels of required video mode

int				ScreenWidth=MODE_WIDTH;



GraphicBufferClass	*ScreenBuffer=NULL;		// Global pointer to screen GraphicBufferClass
GraphicBufferClass   *HidBuffer = NULL;
GraphicBufferClass	SysMemPage(320,200);		// page in real memory
WWMouseClass			*Mouse=NULL;				// Global pointer to mouse information
WinTimerClass			*WindowsTimer=NULL;
PALETTEENTRY			pe[256];						// DD Palette entries
unsigned char			Palette[256*3];			// Place to load palette to
extern LPDIRECTDRAWPALETTE	PalettePtr;			// Pointer to direct draw palette object

//
// Prototypes
//
long FAR PASCAL _export WndProc (HWND, UINT, UINT, LONG) ;

//
// Externs
//
extern	LPDIRECTDRAW	DirectDrawObject;
extern	HWND			MainWindow;
VOID		*ShapeFile;
int	 	CurrentShape;



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
#pragma off(unreferenced)
int PASCAL WinMain (HANDLE hInstance, HANDLE hPrevInstance,
						  LPSTR lpszCmdParam, int nCmdShow)
{
	static char 	szAppName[] = "HelloWin" ;
	HWND        	hwnd ;
	MSG         	msg ;
	WNDCLASS    	wndclass ;
	char				path_to_exe[132];
	char				drive[_MAX_DRIVE];
	char				path[_MAX_PATH];
	unsigned 		drivecount;
	unsigned 		olddrive;
	char				oldpath[PATH_MAX];

	/*
	** Get a path to the executable and make sure that we are pointing
	** at the location our datafiles are located at.
	*/
	GetModuleFileName (hInstance, &path_to_exe[0], 132);
	getcwd(oldpath, sizeof(oldpath));
	_dos_getdrive(&olddrive);


	_splitpath(path_to_exe, drive, path, NULL, NULL);
	if (!drive[0]) {
		drive[0] = (char)(('A' + olddrive)-1);
	}
	if (!path[0]) {
		strcpy(path, ".");
	}
	_dos_setdrive(toupper((drive[0])-'A')+1, &drivecount);
	if (path[strlen(path)-1] == '\\') {
		path[strlen(path)-1] = '\0';
	}
	chdir(path);


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
		wndclass.hbrBackground = NULL;
		wndclass.lpszMenuName  = NULL;
		wndclass.lpszClassName = NAME;

		RegisterClass (&wndclass) ;
	}


	//
	// Create our main window
	//
	hwnd = CreateWindowEx (
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
	MainWindow=hwnd;			//Save the handle to our main window
								// (Dangerous  if Windoze can change the handle)





	// Set the video mode
	Set_Video_Mode( MainWindow , MODE_WIDTH , MODE_HEIGHT , 8 );
	Set_Shape_Buffer(new unsigned char[5000], 5000);
	//
	// Create the GraphicBufferClass that will be the screen buffer
	//
	ScreenBuffer = new GraphicBufferClass ( MODE_WIDTH , MODE_HEIGHT , (GBC_Enum)(GBC_VIDEOMEM | GBC_VISIBLE));
	HidBuffer = new GraphicBufferClass ( MODE_WIDTH , MODE_HEIGHT , (GBC_Enum)(GBC_VIDEOMEM));
	ShowCursor (FALSE);
	Mouse = new WWMouseClass(ScreenBuffer,32,32);

	//
	// Load up the picture and display it on the scene page
	//

	Load_Picture("TITLE.CPS", SysMemPage, SysMemPage, Palette, BM_DEFAULT);
	FontPtr = Load_Font("font.fnt");

	ShapeFile = Load_Alloc_Data("MOUSE.SHP", MEM_NORMAL);
	CurrentShape = 0;
	Mouse->Set_Cursor(0,0,Extract_Shape(ShapeFile,CurrentShape));
	Set_Palette(Palette);
	SysMemPage.Scale(*HidBuffer);
	Mouse->Show_Mouse();
	WindowsTimer = new WinTimerClass(60,FALSE);

	//
	// Get rid of the windows cursor
	//

	AllDone = FALSE;

	//
	// Windows message loop
	//
	int count = 0;
	char temp[100];
	CountDownTimerClass timer(BT_SYSTEM, 0);
	timer.Set(60);
	timer.Start();
	while ( ! AllDone ){
		if (timer.Time() == 0) {
			sprintf(temp,"%d frames per second",count);
			Mouse->Erase_Mouse(HidBuffer, TRUE);
			HidBuffer->Print(temp,0,0,255,1);
			count = 0;
			timer.Set(60);
			timer.Start();
		} else {
			count++;
			Mouse->Erase_Mouse(HidBuffer, TRUE);
		}
		Mouse->Draw_Mouse(HidBuffer);
		HidBuffer->Blit(*ScreenBuffer);
		Mouse->Erase_Mouse(HidBuffer, FALSE);

		if( PeekMessage( &msg, NULL, 0, 0, PM_NOREMOVE ) ){
			if( !GetMessage( &msg, NULL, 0, 0 ) ){
				break;
			}
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

	}
	delete Mouse;
	return msg.wParam;
}

#pragma on(unreferenced)



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

long FAR PASCAL _export WndProc (HWND hwnd, UINT message, UINT wParam,
														  LONG lParam)
 {
	static int condhide = 0;
	switch (message){


//		case WM_MOUSEMOVE:
//			if (Mouse)
//				Mouse->Process_Mouse();
//			break;

		case WM_LBUTTONDOWN:
			if (Mouse) 			{
				Mouse->Set_Cursor(0,0,Extract_Shape(ShapeFile,++CurrentShape));
				if (CurrentShape>160) CurrentShape = 0;
			}
				
			break;

		case WM_RBUTTONDOWN:
			if (condhide) 	{
				Mouse->Show_Mouse();
				Mouse->Conditional_Show_Mouse();
				Mouse->Conditional_Show_Mouse();
				condhide = FALSE;
			} else {
				Mouse->Hide_Mouse();
				Mouse->Conditional_Hide_Mouse(0,0,320,200);
				Mouse->Conditional_Hide_Mouse(0,0,320,200);
				condhide = TRUE;
			}
			break;


		case WM_ACTIVATEAPP:
			if ((BOOL)wParam) {
				if (ScreenBuffer) {
					ScreenBuffer->Get_DD_Surface()->Restore();
				}
			}
			break;

		case WM_DESTROY:
			//
			// Tidy up
			//

			delete ScreenBuffer;
			delete Mouse;

			if ( DirectDrawObject ){
				Reset_Video_Mode();
			}

			AllDone = TRUE;
			PostQuitMessage (0) ;
			return(0);
	}

	return DefWindowProc (hwnd, message, wParam, lParam) ;
}





