; Fix for the bug that team "0" can't be assigned.

; ===========================================================
; Source code equivalent:
; ===========================================================

; CONQUER.CPP -> void Keyboard_Process(KeyNumType &input)

; Find "Handle_Team(KN_To_VK(plain) - VK_1, action);"
; Change "VK_1" to "VK_0".

; ===========================================================
; English, German
; ===========================================================

#eip=0042B9A4 
sub     eax, 30h

; ===========================================================
; French, Japanese
; ===========================================================

#eip=0042B9B4
sub     eax, 30h
