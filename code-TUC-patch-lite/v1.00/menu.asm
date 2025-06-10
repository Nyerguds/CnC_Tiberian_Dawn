; Fix for the main menu order being wrong when using arrow keys.

; ===========================================================
; Source code equivalent:
; ===========================================================

; INIT.CPP -> bool Select_Game(bool fade)
; Change the order of the enum items:
; from SEL_INTERNET, SEL_LOAD_MISSION, SEL_MULTIPLAYER_GAME
; to SEL_LOAD_MISSION, SEL_MULTIPLAYER_GAME, SEL_INTERNET
; The other changes use the enum values, so they should be automatic.

; MENUS.CPP -> int Main_Menu(unsigned long timeout)
; redefine the enum at the start so the order is correct:
; enum {
; #ifdef NEWMENU
;   BUTTON_EXPAND=100*2,
;   BUTTON_START,
; #ifdef BONUS_MISSIONS
;   BUTTON_BONUS,
; #endif //BONUS_MISSIONS
;   BUTTON_LOAD,
;   BUTTON_MULTI,
;   BUTTON_INTERNET,
; #else
;   BUTTON_START=100*2,
;   BUTTON_LOAD,
;   BUTTON_MULTI,
; #endif
;   BUTTON_INTRO,
;   BUTTON_EXIT,
; };
; Further down where the buttons are filled up, change the order too:
; buttons[butt++] = &loadbtn;
; buttons[butt++] = &multibtn;
; buttons[butt++] = &internetbutton;

; INIT.CPP -> bool Select_Game(bool fade)
; Same deal; commands need to match the buttons enum:
; enum {
;   SEL_TIMEOUT = -1,			// main menu timeout--go into attract mode
; #ifdef NEWMENU
;   SEL_NEW_SCENARIO,			// Expansion scenario to play.
;   SEL_START_NEW_GAME,			// start a new game
; #ifdef BONUS_MISSIONS
;   SEL_BONUS_MISSIONS,
; #endif	//BONUS_MISSIONS
;   SEL_LOAD_MISSION,
;   SEL_MULTIPLAYER_GAME,		// load a saved game
;   SEL_INTERNET,			// play modem/null-modem/network game
; #else
;   SEL_START_NEW_GAME,			// start a new game
;   SEL_LOAD_MISSION,
;   SEL_MULTIPLAYER_GAME,		// load a saved game
; #endif
;   SEL_INTRO,				// replay the intro
;   SEL_EXIT,				// exit to DOS
;   SEL_FAME,				// view the hall of fame
;   SEL_NONE,				// placeholder default value
; };

; ===========================================================
; English
; ===========================================================

#eip=00454FD4 ; 453D4
dd 456F78 ; default
dd 455AAE ; newmiss
dd 455AF1 ; newgame
dd 455B6B ; load
dd 455F4F ; multi
dd 455A1D ; internet
dd 45600D ; sneakpeek
dd 456F49 ; exit
dd 45538D ; execute

#eip=004552C3 ; 456C3
; mov dword ptr [ebp-2A], 3 ; was '4'
db C7
db 45
db D6 ; equals '-2A'
dd 03
#eip=0045536C ; 4576C
mov     ecx, 4 ; was '2'
#eip=0045562F ; 45A2F
mov     ecx, 3 ; was '4'
#eip=00455A51 ; 45E51
mov     ecx, 3 ; was '4'
#eip=00455A8D ; 45E8D
mov     edi, 3 ; was '4'

#eip=00470791 ; 60B91
mov     edx, CAh ; Set button id for "Load Mission" to 202 (was CBh)
#eip=004707BC ; 60BBC
mov     edx, CBh ; Set button id for "Multiplayer" to 203 (was CCh)
#eip=004707E4 ; 60BE4
mov     edx, CCh ; Set button id for "Internet game" to 204 (was CAh)

#eip=004708D8 ; 60CD8
mov     [ebp+56], edx ; was 4E
#eip=004708E1 ; 60CE1
mov     [ebp+4E], edx ; was 52
#eip=004708E7 ; 60CE7
mov     [ebp+52], edx ; was 56

; ===========================================================
; German
; ===========================================================

#eip=00455174 ; 45574
dd 457118 ; default
dd 455C4E ; newmiss
dd 455C91 ; newgame
dd 455D0B ; load
dd 4560EF ; multi
dd 455BBD ; internet
dd 4561AD ; sneakpeek
dd 4570E9 ; exit
dd 45552D ; execute

#eip=00455463 ; 45863
; mov dword ptr [ebp-2A], 3 ; was '4'
db C7
db 45
db D6 ; equals '-2A'
dd 03
#eip=0045550C ; 4590C
mov     ecx, 4 ; was '2'
#eip=004557CF ; 45BCF
mov     ecx, 3 ; was '4'
#eip=00455BF1 ; 45FF1
mov     ecx, 3 ; was '4'
#eip=00455C2D ; 4602D
mov     edi, 3 ; was '4'

#eip=00470EF1 ; 612F1
mov     edx, CAh ; Set button id for "Load Mission" to 202 (was CBh)
#eip=00470F1C ; 6131C
mov     edx, CBh ; Set button id for "Multiplayer" to 203 (was CCh)
#eip=00470F44 ; 61344
mov     edx, CCh ; Set button id for "Internet game" to 204 (was CAh)

#eip=0047103B ; 6143B
mov     [ebp+56], edx ; was 4E
#eip=00471044 ; 61444
mov     [ebp+4E], edx ; was 52
#eip=0047104A ; 6144A
mov     [ebp+52], edx ; was 56

; ===========================================================
; French
; ===========================================================
#eip=004551E4 ; 455E4
dd 457188 ; default
dd 455CBE ; newmiss
dd 455D01 ; newgame
dd 455D7B ; load
dd 45615F ; multi
dd 455C2D ; internet
dd 45621D ; sneakpeek
dd 457159 ; exit
dd 45559D ; execute

#eip=004554D3 ; 458D3
; A bit below "mov [ebp-2A], 8"
; mov dword ptr [ebp-2A], 3 ; was '4'
db C7
db 45
db D6 ; equals '-2A'
dd 03
#eip=0045557C ; 4597C
mov     ecx, 4 ; was '2'
#eip=0045583F ; 45C3F
mov     ecx, 3 ; was '4'
#eip=00455C61 ; 46061
mov     ecx, 3 ; was '4'
#eip=00455C9D ; 4609D
mov     edi, 3 ; was '4'

#eip=00470F61 ; 61361
mov     edx, CAh ; Set button id for "Load Mission" to 202 (was CBh)
#eip=00470F8C ; 6138C
mov     edx, CBh ; Set button id for "Multiplayer" to 203 (was CCh)
#eip=00470FB4 ; 613B4
mov     edx, CCh ; Set button id for "Internet game" to 204 (was CAh)

#eip=004710AB ; 614AB
mov     [ebp+56], edx ; was 4E
#eip=004710B4 ; 614B4
mov     [ebp+4E], edx ; was 52
#eip=004710BA ; 614BA
mov     [ebp+52], edx ; was 56
; ===========================================================
; Japanese
; ===========================================================
; this one is a bit different; the order progression is correct on the Japanese version,
; but they "fixed" it simply by putting the internet button between "new game" and "load game".
; This is the proper fix that reorders them to their normal order and fixes the navigation.
#eip=00455AB0 ; 45EB0
dd 457B02 ; default
dd 456591 ; newmiss
dd 4565D3 ; newgame
dd 45664A ; load
dd 456A2E ; multi
dd 456500 ; internet
dd 456AEC ; sneakpeek
dd 457A34 ; exit
dd 455E69 ; execute

#eip=00455D9F ; 4619F
mov dword ptr [ebp+42], 3 ; was '4'
#eip=00455E48 ; 46248
mov     ecx, 4 ; was '2'
#eip=0045610B ; 4650B
mov     ebx, 3 ; was '4'
#eip=00456534 ; 46934
mov     ebx, 3 ; was '4'
#eip=00456570 ; 46970
mov     ecx, 3 ; was '4'

#eip=0047144A ; 6184A
mov     ebx,  35h ; set label for third button to "Load Game"
#eip=00471472 ; 61872
mov     ebx, 0D2h ; set label for fourth button to "multiplay"
#eip=0047149D ; 6189D
mov     ebx, 2DCh ; set label for fifth button to "internet"
