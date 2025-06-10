; Fix for multiplayer names getting abbreviated if they are more
; than 9 characters, only for the 10th to get replaced by a dot.
; This logic should only execute if the length actually exceeds 10.

; For example, this abbreviates the computer player name in French
; from "Ordinateur" to "Ordinateu.", which is exactly the same length.

; ===========================================================
; Source code equivalent:
; ===========================================================

; RADAR.CPP -> void RadarClass::Draw_Names(void)
; Find "if (strlen(txt) > 9)"
; Replace with  "if (strlen(txt) > 10)"

; ===========================================================
; English
; ===========================================================

#eip=0049853B ; 8893B
cmp     ecx, 0Ah

; ===========================================================
; German
; ===========================================================

#eip=00498E6B ; 8926B
cmp     ecx, 0Ah

; ===========================================================
; French
; ===========================================================

#eip=00498F7B ; 8937B
cmp     ecx, 0Ah

; ===========================================================
; Japanese
; ===========================================================

#eip=0049993B ; 89D3B
cmp     ecx, 0Ah

