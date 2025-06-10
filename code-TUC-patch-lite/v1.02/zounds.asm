; Fix for the fact the "Sounds=7th Grade" option (to load zounds.mix)
; doesn't work because the option is checked before the settings are read.

; NOTE: an extra v1.03 fix was added to this to make sure themes that only
; exist as .var are properly identified as existing.
; See "\v1.03\fix-var-only-music.txt"

; ===========================================================
; Source code equivalent:
; ===========================================================

; INIT.CPP -> bool Init_Game(int , char *[])
; Find "MixFileClass::Cache("CONQUER.MIX");"
; Take the entire "if" block that follows it, and move it behind "Options.Load_Settings();"

; ===========================================================
; English
; ===========================================================

#eip=0042C454
Call_Back:
#eip=004715B0
MixFileClass_MixFileClass:
#eip=0048E9B4
OptionsClass_Load_Settings:
#eip=004717C8
MixFileClass_Cache:
#eip=004B4BF8 ; void ThemeClass::Scan(void) proc near 
ThemeClass_Scan:
#eip=004C6980
operator_new:

#eip=004FBBE0
vtable_RawFileClass:
#eip=0053CB44
Debug_Quiet:
#eip=0053E4A1
SpecialOpts_2:
#eip=0053E4A3
SpecialOpts_4:
#eip=0056259C
SoundType:

; skip audio mix files init
#eip=00454DFE ; 451FE
mov    eax, 0
nop
nop
nop

; jump to audio mix files init after loading settings
#eip=00454F7A ; 4537A
test    eax, eax
jnz     00454650
nop
nop
nop
nop
jumpback_options:

#eip=00454650 ; 44A50
mov     edi, offset .vtable_RawFileClass
call   .OptionsClass_Load_Settings
mov     ecx, edx
mov     eax, :SoundType
sar     eax, 10h
test    eax, eax
jz     .skip_audio
cmp     :Debug_Quiet, 0
jnz    .skip_audio
mov     eax, 004F3EFE ; "SOUNDS.MIX"
call   .MixFileClass_Cache
test    byte :SpecialOpts_2, 4
jz     .skip_audio
mov     eax, 20h
call   .operator_new
test    eax, eax
jz     .skip_zounds_init
mov     edx, 004F3F09 ; "ZOUNDS.MIX"
call   .MixFileClass_MixFileClass
skip_zounds_init:
mov     eax, 004F3F09 ; "ZOUNDS.MIX"
call   .MixFileClass_Cache
call   .Call_Back
skip_audio:
; -----------------------------------------------------------
; [V1.03] ADDITION FOR FIXING .VAR MUSIC - SEE "\v1.03\fix-var-only-music.txt"
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
; -----------------------------------------------------------
jmp    .jumpback_options

; ===========================================================
; German
; ===========================================================

#eip=0042C454
Call_Back:
#eip=00471D20
MixFileClass_MixFileClass:
#eip=0048F1B4
OptionsClass_Load_Settings:
#eip=00471F38
MixFileClass_Cache:
#eip=004B5528 ; void ThemeClass::Scan(void) proc near 
ThemeClass_Scan:
#eip=004C7360
operator_new:

#eip=004FBCD0
vtable_RawFileClass:
#eip=0053CB44
Debug_Quiet:
#eip=0053E4A1
SpecialOpts_2:
#eip=0053E4A3
SpecialOpts_4:
#eip=0056259C
SoundType:

; skip audio mix files init
#eip=00454F9E ; 4539E
mov    eax, 0
nop
nop
nop

; jump to audio mix files init after loading settings
#eip=0045511A ; 4551A
test    eax, eax
jnz     004547F0
nop
nop
nop
nop
jumpback_options:

#eip=004547F0 ; 44BF0
mov     edi, offset .vtable_RawFileClass
call   .OptionsClass_Load_Settings
mov     ecx, edx
mov     eax, :SoundType
sar     eax, 10h
test    eax, eax
jz     .skip_audio
cmp     :Debug_Quiet, 0
jnz    .skip_audio
mov     eax, 004F4111 ; "SOUNDS.MIX"
call   .MixFileClass_Cache
test    byte :SpecialOpts_2, 4
jz     .skip_audio
mov     eax, 20h
call   .operator_new
test    eax, eax
jz     .skip_zounds_init
mov     edx, 004F411C ; "ZOUNDS.MIX"
call   .MixFileClass_MixFileClass
skip_zounds_init:
mov     eax, 004F411C ; "ZOUNDS.MIX"
call   .MixFileClass_Cache
call   .Call_Back
skip_audio:
; -----------------------------------------------------------
; [V1.03] ADDITION FOR FIXING .VAR MUSIC - SEE "\v1.03\fix-var-only-music.txt"
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
; -----------------------------------------------------------
jmp    .jumpback_options

; ===========================================================
; French
; ===========================================================

#eip=0042C464
Call_Back:
#eip=00471D90
MixFileClass_MixFileClass:
#eip=0048F2C4
OptionsClass_Load_Settings:
#eip=00471FA8
MixFileClass_Cache:
#eip=004B5638
ThemeClass_Scan:
#eip=004C7470
operator_new:

#eip=004FBD2C
vtable_RawFileClass:
#eip=0053CB44
Debug_Quiet:
#eip=0053E4A1
SpecialOpts_2:
#eip=0053E4A3
SpecialOpts_4:
#eip=0056259C
SoundType:

; skip audio mix files init
#eip=0045500E ; 4540E
mov    eax, 0
nop
nop
nop

; jump to audio mix files init after loading settings
#eip=0045518A ; 4558A
test    eax, eax
jnz     00454860
nop
nop
nop
nop
jumpback_options:

#eip=00454860 ; 44C60
mov     edi, offset .vtable_RawFileClass
call   .OptionsClass_Load_Settings
mov     ecx, edx
mov     eax, :SoundType
sar     eax, 10h
test    eax, eax
jz     .skip_audio
cmp     :Debug_Quiet, 0
jnz    .skip_audio
mov     eax, 004F4196 ; "SOUNDS.MIX"
call   .MixFileClass_Cache
test    byte :SpecialOpts_2, 4
jz     .skip_audio
mov     eax, 20h
call   .operator_new
test    eax, eax
jz     .skip_zounds_init
mov     edx, 004F41A1 ; "ZOUNDS.MIX"
call   .MixFileClass_MixFileClass
skip_zounds_init:
mov     eax, 004F41A1 ; "ZOUNDS.MIX"
call   .MixFileClass_Cache
call   .Call_Back
skip_audio:
; -----------------------------------------------------------
; [V1.03] ADDITION FOR FIXING .VAR MUSIC - SEE "\v1.03\fix-var-only-music.txt"
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
; -----------------------------------------------------------
jmp    .jumpback_options


; ===========================================================
; Japanese
; ===========================================================

#eip=0042C464
Call_Back:
#eip=00472280
MixFileClass_MixFileClass:
#eip=0048FC34
OptionsClass_Load_Settings:
#eip=00472498
MixFileClass_Cache:
#eip=004B5E18
ThemeClass_Scan:
#eip=004C7C50
operator_new:

#eip=004FBD9C
vtable_RawFileClass:
#eip=0053CB48
Debug_Quiet:
#eip=0053E4A5
SpecialOpts_2:
#eip=0053E4A7
SpecialOpts_4:
#eip=005623A0
SoundType:

; skip audio mix files init
#eip=004558E4 ; 45CE4
mov    eax, 0
nop
nop
nop

; jump to audio mix files init after loading settings
#eip=00455A64 ; 45E64
test    eax, eax
jnz     00455124
nop
nop
nop
nop
jumpback_options:

#eip=00455124 ; 45524
mov     edi, offset .vtable_RawFileClass
call   .OptionsClass_Load_Settings
mov     ecx, edx
mov     eax, :SoundType
sar     eax, 10h
test    eax, eax
jz     .skip_audio
cmp     :Debug_Quiet, 0
jnz    .skip_audio
mov     eax, 004F420B ; "SOUNDS.MIX"
call   .MixFileClass_Cache
test    byte :SpecialOpts_2, 4
jz     .skip_audio
mov     eax, 20h
call   .operator_new
test    eax, eax
jz     .skip_zounds_init
mov     edx, 004F4216 ; "ZOUNDS.MIX"
call   .MixFileClass_MixFileClass
skip_zounds_init:
mov     eax, 004F4216 ; "ZOUNDS.MIX"
call   .MixFileClass_Cache
call   .Call_Back
skip_audio:
; -----------------------------------------------------------
; [V1.03] ADDITION FOR FIXING .VAR MUSIC - SEE "\v1.03\fix-var-only-music.txt"
test    byte :SpecialOpts_4, 2
jz     .no_rescan
call   .ThemeClass_Scan
no_rescan:
; -----------------------------------------------------------
jmp    .jumpback_options