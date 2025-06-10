; Fix for the multiplayer houses showing up as gray on radar in singleplayer missions.

; ===========================================================
; Source code equivalent:
; ===========================================================

; HDATA.CPP -> HouseMulti1, HouseMulti2, HouseMulti3, HouseMulti4, HouseMulti5, HouseMulti6:
; Change "color" and "bright_color" arguments to match their remap according to
; HOUSE.CPP -> void HouseClass::Init_Data(PlayerColorType color, HousesType house, int credits)
; Alternatively, an actual loop to call HouseClass::Init_Data for each MP house could be added in Read_Scenario_Ini?

; ===========================================================
; English
; ===========================================================

#eip=0044723F ; 3763F ; blue
push    2               ; unit radar color index
push    87h             ; Building radar color index
#eip=00447272 ; 37672 ; orange
push    18h             ; unit radar color index
push    1Ah             ; Building radar color index
#eip=004472A5 ; 376A5 ; green
push    A7h             ; unit radar color index
push    9Fh             ; Building radar color index
#eip=004472D8 ; 376D8 ; gray
push    C9h             ; unit radar color index
push    CBh             ; Building radar color index
#eip=0044730B ; 3770B ; yellow
push    5               ; unit radar color index
push    9Dh             ; Building radar color index
#eip=0044733E ; 3773E ; red
push    7Fh             ; unit radar color index
push    7Bh             ; Building radar color index

; ===========================================================
; German
; ===========================================================

#eip=004473DF ; 377DF ; blue
push    2               ; unit radar color index
push    87h             ; Building radar color index
#eip=00447412 ; 37812 ; orange
push    18h             ; unit radar color index
push    1Ah             ; Building radar color index
#eip=00447445 ; 37845 ; green
push    A7h             ; unit radar color index
push    9Fh             ; Building radar color index
#eip=00447478 ; 37878 ; gray
push    C9h             ; unit radar color index
push    CBh             ; Building radar color index
#eip=004474AB ; 378AB ; yellow
push    5               ; unit radar color index
push    9Dh             ; Building radar color index
#eip=004474DE ; 378DE ; red
push    7Fh             ; unit radar color index
push    7Bh             ; Building radar color index

; ===========================================================
; French
; ===========================================================

#eip=0044744F ; 3784F ; blue
push    2               ; unit radar color index
push    87h             ; Building radar color index
#eip=00447482 ; 37882 ; orange
push    18h             ; unit radar color index
push    1Ah             ; Building radar color index
#eip=004474B5 ; 378B5 ; green
push    A7h             ; unit radar color index
push    9Fh             ; Building radar color index
#eip=004474E8 ; 378E8 ; gray
push    C9h             ; unit radar color index
push    CBh             ; Building radar color index
#eip=0044751B ; 3791B ; yellow
push    5               ; unit radar color index
push    9Dh             ; Building radar color index
#eip=0044754E ; 3794E ; red
push    7Fh             ; unit radar color index
push    7Bh             ; Building radar color index

; ===========================================================
; Japanese
; ===========================================================

#eip=00447C9F ; 3809F ; blue
push    2               ; unit radar color index
push    87h             ; Building radar color index
#eip=00447CD2 ; 380D2 ; orange
push    18h             ; unit radar color index
push    1Ah             ; Building radar color index
#eip=00447D05 ; 38105 ; green
push    A7h             ; unit radar color index
push    9Fh             ; Building radar color index
#eip=00447D38 ; 38138 ; gray
push    C9h             ; unit radar color index
push    CBh             ; Building radar color index
#eip=00447D6B ; 3816B ; yellow
push    5               ; unit radar color index
push    9Dh             ; Building radar color index
#eip=00447D9E ; 3819E ; red
push    7Fh             ; unit radar color index
push    7Bh             ; Building radar color index
