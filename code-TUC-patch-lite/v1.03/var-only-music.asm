; Fix for the fact .var only music is missing even if "Scores=remix" is enabled.
; This builds on the v1.02 code in "\v1.02\fix-zounds.txt"

; ===========================================================
; Source code equivalent:
; ===========================================================

; INIT.CPP -> bool Init_Game(int , char *[])
; Find "OptionsClass::Load_Settings(void)"
; Put the following code somewhere below it:
; if (Special.IsVariation) ThemeClass::Scan();

; ===========================================================
; English
; ===========================================================

#eip=004B4BF8 ; void ThemeClass::Scan(void) proc near 
ThemeClass_Scan:
#eip=0053E4A3
SpecialOpts_4:

; jump to audio mix files init after loading settings
#eip=00454F86
jumpback_options:

; end of the zounds code, replacing the final jump at label "skip_audio"
#eip=004546AB ; 44AAB
skip_audio:
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
; -----------------------------------------------------------
jmp    .jumpback_options

; ===========================================================
; German
; ===========================================================

#eip=004B5528 ; void ThemeClass::Scan(void) proc near 
ThemeClass_Scan:
#eip=0053E4A3
SpecialOpts_4:

; jump to audio mix files init after loading settings
#eip=00455126
jumpback_options:

; end of the zounds code, replacing the final jump at label "skip_audio"
#eip=0045484B ; 44C4B
skip_audio:
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
jmp    .jumpback_options

; ===========================================================
; French
; ===========================================================

#eip=004B5638
ThemeClass_Scan:
#eip=0053E4A3
SpecialOpts_4:

; jump to audio mix files init after loading settings
#eip=00455196 ; 45596
jumpback_options:

; end of the zounds code, replacing the final jump at label "skip_audio"
#eip=004548BB ; 44CBB
skip_audio:
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
jmp    .jumpback_options

; ===========================================================
; Japanese
; ===========================================================

#eip=004B5E18
ThemeClass_Scan:
#eip=0053E4A7
SpecialOpts_4:

; jump to audio mix files init after loading settings
#eip=00455A70 ; 45E70
jumpback_options:

; end of the zounds code, replacing the final jump at label "skip_audio"
#eip=0045517F ; 4557F
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
jmp    .jumpback_options