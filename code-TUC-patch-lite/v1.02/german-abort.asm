; Fix for the fact the German mission abort has the German word for "abort" as "cancel" option.

; ===========================================================
; Source code equivalent:
; ===========================================================

; GOPTIONS.CPP -> void GameOptionsClass::Process(void)
; Find "switch (CCMessageBox().Process(TXT_CONFIRM_EXIT"
; In the #else case, add an "#ifdef GERMAN" with this call:
; switch (CCMessageBox().Process(TXT_CONFIRM_EXIT, TXT_ABORT, TXT_NO, TXT_RESTART))

; ===========================================================
; German
; ===========================================================

#eip=0044694B ; 36D4B
mov     ecx, 13h        ; No
