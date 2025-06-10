; Fix for the fact giving a Briefing video to a Covert Ops mission makes its music not start to play.

; ===========================================================
; Source code equivalent:
; ===========================================================

; SCENARIO.CPP -> bool Start_Scenario(char *root, bool briefing)
; Find "if (GameToPlay == GAME_NORMAL && !file.Is_Available())"
; Replace by "if (GameToPlay == GAME_NORMAL)", and add an extra "if" block for the check on "!file.Is_Available()",
; which does not include the three last lines (the music check).

; The code (comments left out for brevity) should become this:

; if (GameToPlay == GAME_NORMAL) {
;   if (!file.Is_Available()) {
;     VisiblePage.Clear();
;     Set_Palette(GamePalette);
;     bool oldinmain = InMainLoop;
;     InMainLoop = true;
;     Restate_Mission(ScenarioName, TXT_OK, TXT_NONE);
;     InMainLoop = oldinmain;
;   }
;   if (TransitTheme == THEME_NONE) {
;     Theme.Queue_Song(THEME_AOI);
;   }
; }

; ===========================================================
; English
; ===========================================================

#eip=0049B0E3 ; 8B4E3
jnz 0049B1B4

; ===========================================================
; German
; ===========================================================

#eip=0049BA13 ; 8BE13
jnz 0049BAE4

; ===========================================================
; French
; ===========================================================

#eip=0049BB23 ; 8BF23
jnz 0049BBF4

; ===========================================================
; Japanese
; ===========================================================

#eip=0049C503 ; 8C903
jnz 0049C5D4
