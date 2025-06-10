; Fix for variations of themes not showing a correct playlist length.

; The theory behind this change is to add an extra "VariationDuration" field on
; ThemeClass for the alternate version's length, and use that when IsVariation
; is true. However, this is not the only tweak that needs to be done; the game
; contains no system to figure out whether a found track is the original or
; the alternate.

; To amend this, an extra field "VariationAvailable" must be added too,
; and the ThemeClass::Theme_File_Name function is split into two; one that
; explicitly receives a second argument to make it return either the .var or
; the .aud, and the current version with one argument, which just takes that
; "VariationAvailable" field and then uses that as second argument when calling
; the two-argument version of ThemeClass::Theme_File_Name.
;
; Finally, ThemeClass::Scan should check Special.IsVariation and the theme's
; Variation variable, and if they are both true, explicitly call the alternate
; two-argument version of Theme_File_Name to fetch the .var theme, and check
; if that exists. If it does, both .Available and .VariationAvailable are set to
; "true", otherwise the .aud name is fetched and checked.
;
; With this set up, ThemeClass::Track_Length can accurately check on the
; "VariationAvailable" field to switch to fetching "VariationDuration".
;
; Note that since the "Available" and "Duration" fields are 32-bit ints, which
; is pretty huge for these small values, the asm code simply uses them as a
; pair of 16-bit ints, which gives space to store the data of the new
; "VariationAvailable" and "VariationDuration" fields.

; ===========================================================
; Source code equivalent:
; ===========================================================

; THEME.H -> typedef struct { ... } ThemeControl
; After "int Duration;", add "int VariationDuration;"
; After "int Available;", add "int VariationAvailable;"

; THEME.CPP -> ThemeClass::ThemeControl ThemeClass::_themes[THEME_COUNT]
; Replace contents by this:
;//	Name,		Fullname,		Scen,	Dur,	VarDur,	Normal,	Var,	Rept,	Avlb,	VarAvl
;	{"AIRSTRIK",	TXT_THEME_AIRSTRIKE,	0,	200,	0,	true,	false,	false,	true,	false},
;	{"80MX226M",	TXT_THEME_80MX,		0,	248,	0,	true,	false,	false,	true,	false},
;	{"CHRG226M",	TXT_THEME_CHRG,		0,	256,	0,	true,	false,	false,	true,	false},
;	{"CREP226M",	TXT_THEME_CREP,		0,	222,	0,	true,	false,	false,	true,	false},
;	{"DRIL226M",	TXT_THEME_DRIL,		0,	272,	0,	true,	false,	false,	true,	false},
;	{"DRON226M",	TXT_THEME_DRON,		0,	275,	0,	true,	false,	false,	true,	false},
;	{"FIST226M",	TXT_THEME_FIST,		0,	212,	0,	true,	false,	false,	true,	false},
;	{"RECN226M",	TXT_THEME_RECON,	0,	261,	0,	true,	false,	false,	true,	false},
;	{"VOIC226M",	TXT_THEME_VOICE,	0,	306,	0,	true,	false,	false,	true,	false},
;	{"HEAVYG",	TXT_THEME_HEAVYG,	0,	180,	0,	true,	false,	false,	true,	false},
;	{"J1",		TXT_THEME_J1,		4,	187,	0,	true,	false,	false,	true,	false},
;	{"JDI_V2",	TXT_THEME_JDI_V2,	5,	183,	0,	true,	false,	false,	true,	false},
;	{"RADIO",	TXT_THEME_RADIO,	6,	183,	0,	true,	false,	false,	true,	false},
;	{"RAIN",	TXT_THEME_RAIN,		7,	156,	0,	true,	false,	false,	true,	false},
;	{"AOI",		TXT_THEME_AOI,		0,	168,	172,	true,	true,	false,	true,	false},
;	{"CCTHANG",	TXT_THEME_CCTHANG,	12,	193,	0,	true,	false,	false,	true,	false},
;	{"DIE",		TXT_THEME_DIE,		11,	162,	0,	true,	false,	false,	true,	false},
;	{"FWP",		TXT_THEME_FWP,		10,	53,	0,	true,	false,	false,	true,	false},
;	{"IND",		TXT_THEME_IND,		1,	175,	0,	true,	false,	false,	true,	false},
;	{"IND2",	TXT_THEME_IND2,		1,	38,	0,	true,	false,	false,	true,	false},
;	{"JUSTDOIT",	TXT_THEME_JUSTDOIT,	9,	142,	144,	true,	true,	false,	true,	false},
;	{"LINEFIRE",	TXT_THEME_LINEFIRE,	8,	125,	0,	true,	false,	false,	true,	false},
;	{"MARCH",	TXT_THEME_MARCH,	7,	157,	0,	true,	false,	false,	true,	false},
;	{"TARGET",	TXT_THEME_TARGET,	0,	173,	0,	true,	false,	false,	true,	false},
;	{"NOMERCY",	TXT_THEME_NOMERCY,	2,	204,	197,	true,	true,	false,	true,	false},
;	{"OTP",		TXT_THEME_OTP,		3,	182,	0,	true,	false,	false,	true,	false},
;	{"PRP",		TXT_THEME_PRP,		4,	211,	0,	true,	false,	false,	true,	false},
;	{"ROUT",	TXT_THEME_ROUT,		12,	0,	121,	false,	true,	false,	true,	false},
;	{"HEART",	TXT_THEME_HEART,	5,	0,	206,	false,	true,	false,	true,	false},
;	{"STOPTHEM",	TXT_THEME_STOPTHEM,	0,	190,	189,	true,	true,	false,	true,	false},
;	{"TROUBLE",	TXT_THEME_TROUBLE,	6,	191,	132,	true,	true,	false,	true,	false},
;	{"WARFARE",	TXT_THEME_WARFARE,	0,	182,	0,	true,	false,	false,	true,	false},
;	{"BEFEARED",	TXT_THEME_BEFEARED,	13,	164,	101,	true,	true,	false,	true,	false},
;	{"I_AM",	TXT_THEME_IAM,		6,	161,	0,	true,	false,	false,	true,	false},
;	{"WIN1",	TXT_THEME_WIN1,		0,	41,	56,	false,	true,	true,	true,	false},
;	{"MAP1",	TXT_THEME_WIN1,		0,	61,	0,	false,	false,	true,	true,	false},
;	{"VALKYRIE",	TXT_THEME_VALK,		0,	306,	0,	true,	false,	false,	true,	false},
; Note that this enables the tracks "AIRSTRIK", "80MX226M", "DIE", "VALKYRIE",
; and disables the "Loop" status on "VALKYRIE". It also enables the Variation
; on JUSTDOIT, NOMERCY and STOPTHEM, with their added variation length, since
; they exist on the soundtrack and could be added.

; THEME.CPP -> char const * ThemeClass::Theme_File_Name(ThemeType theme)
; Replace the entire function contents by this:
;	return ThemeClass::Theme_File_Name(theme, _themes[theme].VariationAvailable);

; THEME.CPP -> Add the new function called in the previous one:
;	char const * ThemeClass::Theme_File_Name(ThemeType theme, bool variation)
;	{
;		static char name[_MAX_FNAME+_MAX_EXT];
;		if (variation) {
;			_makepath(name, NULL, NULL, _themes[theme].Name, ".VAR");
;		}
;		_makepath(name, NULL, NULL, _themes[theme].Name, ".AUD");
;		return ((char const *)(&name[0]));
;	}

; THEME.CPP -> void ThemeClass::Scan(void)
; Replace the entire function contents by this:
;	for (ThemeType theme = THEME_FIRST; theme < THEME_COUNT; theme++) {
;		if (Special.IsVariation && _themes[theme].Variation && CCFileClass(Theme_File_Name(theme, true)).Is_Available()) {
;			_themes[theme].Available = true;
;			_themes[theme].VariationAvailable = true;
;		} else {
;			_themes[theme].Available = CCFileClass(Theme_File_Name(theme, false)).Is_Available();
;			_themes[theme].VariationAvailable = false;
;		}
;	}
; Note that there is a "CCFileClass::Find_File(char *)" which exactly contains
; the "CCFileClass(char *).Is_Available()" call. This is actually the function
; I ended up using in the asm code, since it saved a ton of space.

; THEME.CPP -> int const ThemeClass::Track_Length(ThemeType)
; Change the single line inside the "if" by this block:
;	if (Special.IsVariation && _themes[theme].VariationAvailable) {
;		return _themes[theme].VariationDuration;
; 	} else {
;		return _themes[theme].Duration;
;	}

; ===========================================================
; English
; ===========================================================

; DATA OFFSETS - IGNORE ANY ACTUAL DATA PRODUCED BY THIS.
; This section only exists to get the labels assigned for use in the code below.
#eip=00423BFC ; int find_file(char *)
find_file:
#eip=004C676F ; _makepath_
_makepath_:

#eip=004F8745 ; str_var
str_var:
#eip=004F874A ; str_aud
str_aud:
#eip=0050AEC8 ; ThemeClass::_themes[]
ThemeClass_Name:
dd 0
ThemeClass_Fullname:
dd 0
ThemeClass_Scenario:
dd 0
ThemeClass_Duration:
dd 0
ThemeClass_Normal:
dd 0
ThemeClass_Variation:
dd 0
ThemeClass_Repeat:
dd 0
ThemeClass_Available:
dd 0
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00561B84 ; theme_name_buffer
theme_name_buffer:

; -----------------------------------------------------------------------------
; Track data: add alt lengths, enable hidden themes
; -----------------------------------------------------------------------------

; AIRSTRIK: enable in the playlist
#eip=0050AED8 ; F2CD8
dd      1
; 80MX226M: enable in the playlist
#eip=0050AEF8 ; F2CF8
dd      1
; AOI: variation length (orig is 0A8h)
#eip=0050B096 ; F2E96
dw      0ACh
; DIE: enable in the playlist
#eip=0050B0D8 ; F2ED8
dd      1
; JUSTDOIT: variation length (orig is 08Eh)
#eip=0050B156 ; F2F56
dw      90
; JUSTDOIT: enable variation
#eip=0050B15C ; F2F5C
dd      1
; NOMERCY: variation length (orig is 0CCh)
#eip=0050B1D6 ; F2FD6
dw      C5
; NOMERCY: enable variation
#eip=0050B1DC ; F2FDC
dd      1
; ROUT: move length to variation length (orig is 79h, but should be 0)
#eip=0050B234 ; F3034
dd      790000h
; HEART: move length to variation length (orig is 0CEh, but should be 0)
#eip=0050B254 ; F3054
dd      0CE0000h
; STOPTHEM: variation length (orig is 0BEh)
#eip=0050B276 ; F3076
dw      0BDh
; STOPTHEM: enable variation
#eip=0050B27C ; F307C
dd      1
; TROUBLE: variation length (orig is 0BFh)
#eip=0050B296 ; F3096
dw      084h
; BEFEARED: variation length (orig is 0A4h)
#eip=0050B2D6 ; F30D6
dw      65h
; BEFEARED: enable in playlist
#eip=0050B2D8 ; F30D8
dd      1
; I_AM: enable in playlist
#eip=0050B2F8 ; F30F8
dd      1
; WIN1: variation length (orig is 29h)
#eip=0050B316 ; F3116
dw      38h
; VALKYRIE: enable in playlist
#eip=0050B358 ; F3158
dd      1
; VALKYRIE: disable looping
#eip=0050B360 ; F3160
dd      0

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType, int)
; Version of theme_file_name with two arguments, the second of which is
; a boolean to give the .var version.
; -----------------------------------------------------------------------------
; This address should be 1Ch bytes behind the "theme_file_name_normal" start.
#eip=4B4958 ; A4D58 ; theme_file_name_ext(eax=theme, edx=var)
theme_file_name_ext:
push    ebx
push    ecx
mov     ecx, eax
test    edx, edx
jnz    .var
push    offset .str_aud                ; _makepath_ arg ext
jmp    .makename
var:
push    offset .str_var                ; _makepath_ arg ext
makename:
mov     eax, offset .theme_name_buffer ; _makepath_ arg path (destination buffer)
xor     ebx, ebx                       ; _makepath_ arg directory (empty)
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
xor     edx, edx                       ; _makepath_ arg drive (empty)
mov     ecx, [ecx+.ThemeClass_Name]    ; _makepath_ arg name
call   ._makepath_
mov     eax, .theme_name_buffer
pop     ecx
pop     ebx
retn
db      00 ; padding

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType)
; Version of theme_file_name with one argument, which uses the 3rd byte in the
; "Available" value to switch to .var
; -----------------------------------------------------------------------------
#eip=004B493C ; A4D3C
theme_file_name_normal:
push    edx
mov     edx, eax ; eax = theme id
shl     edx, 5 ; multiply theme number by 20h to act as theme offset in list
mov     edx, [edx+.ThemeClass_Available]      ; _makepath_ arg name
shr     edx, 10h ; edx = upper word of .Available is used for "var theme was found"
call   .theme_file_name_ext
pop     edx
retn
dd      00 ; padding
db      00
db      00

; -----------------------------------------------------------------------------
; New ThemeClass::Scan(void)
; If Special.IsVariations enabled, and theme has Variation, this checks existence
; of the .var version, otherwise it checks existence of normal version.
; This is just a full rewrite since all complex logic is removed.
; -----------------------------------------------------------------------------
#eip=004B4BF8 ; A4FF8
push    ebx
push    ecx
push    edx
push    ebp
xor     ebp, ebp ; loop variable for theme id
scan_loopstart:
mov     eax, ebp ; theme id
mov     ecx, eax ; theme id to transform to offset
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
test    byte :SpecialOpts_4, 2
jz     .scan_not_var
mov     edx, [ecx+.ThemeClass_Variation]
test    edx, edx
jz     .scan_not_var
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
test    eax, eax
jz     .scan_not_var
mov     ebx, 10001 ; theme available, and found as var.
jmp    .scan_write_result
scan_not_var:
mov     eax, ebp ; theme id
xor     edx, edx ; should still be 0 actually
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
mov     ebx, eax
scan_write_result:
mov     ecx, ebp ; find_file destroys ecx, so we need to do this again.
shl     ecx, 5
mov     [ecx+.ThemeClass_Available], ebx
inc     ebp
cmp     ebp, 25h
jl     .scan_loopstart
pop     ebp
pop     edx
pop     ecx
pop     ebx
retn
db      00 ; padding

; ----------------------------------------------------------------------------
; const ThemeClass::Track_Length(ThemeType)
; ----------------------------------------------------------------------------

; extra code to check for .var
; This address should be 50h bytes behind the "theme_file_name_normal" start.
#eip=004B498C ; A4D8C
track_length_var:
test    byte :SpecialOpts_4, 2
jz     .normalname
shl     eax, 5
; mov     eax, [eax+.ThemeClass_Available]
db      8B ; mov eax, .ThemeClass_Available[eax]
db      80
dd     .ThemeClass_Available
shr     eax, 10 ; shift to "is alternate available?"
test    eax, eax
jz     .normalname
shr     edx, 10h
jmp    .end
normalname:
and     edx, FFFFh
end:
mov     eax, edx
retn
db      00 ; padding

; int const ThemeClass::Track_Length(ThemeType)
#eip=004B4A5C ; A4E5C
movsx   eax, dl
cmp     eax, 25
jb     .continue
xor     eax, eax
retn
continue:
mov     edx, eax
shl     edx, 5
mov     edx, [edx+.ThemeClass_Duration] ; both durations together
jmp    .track_length_var

; ===========================================================
; German
; ===========================================================

; DATA OFFSETS - IGNORE ANY ACTUAL DATA PRODUCED BY THIS.
; This section only exists to get the labels assigned for use in the code below.
#eip=00423BFC ; int find_file(char *)
find_file:
#eip=004C714F ; _makepath_
_makepath_:

#eip=004F8835 ; str_var
str_var:
#eip=004F883A ; str_aud
str_aud:
#eip=0050B000 ; ThemeClass::_themes[]
ThemeClass_Name:
dd 0
ThemeClass_Fullname:
dd 0
ThemeClass_Scenario:
dd 0
ThemeClass_Duration:
dd 0
ThemeClass_Normal:
dd 0
ThemeClass_Variation:
dd 0
ThemeClass_Repeat:
dd 0
ThemeClass_Available:
dd 0
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00561B84 ; theme_name_buffer
theme_name_buffer:

; -----------------------------------------------------------------------------
; Track data: add alt lengths, enable hidden themes
; -----------------------------------------------------------------------------
; Not gonna redo this for all languages... it's just manual edits on the
; ThemeClass::_themes[] array data.

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType, int)
; Version of theme_file_name with two arguments, the second of which is
; a boolean to give the .var version.
; -----------------------------------------------------------------------------
; This address should be 1C bytes behind the "theme_file_name_normal" start.
#eip=004B5288 ; A5688 ; theme_file_name_ext(eax=theme, edx=var)
theme_file_name_ext:
push    ebx
push    ecx
mov     ecx, eax
test    edx, edx
jnz    .var
push    offset .str_aud                ; _makepath_ arg ext
jmp    .makename
var:
push    offset .str_var                ; _makepath_ arg ext
makename:
mov     eax, offset .theme_name_buffer ; _makepath_ arg path (destination buffer)
xor     ebx, ebx                       ; _makepath_ arg directory (empty)
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
xor     edx, edx                       ; _makepath_ arg drive (empty)
mov     ecx, [ecx+.ThemeClass_Name]    ; _makepath_ arg name
call   ._makepath_
mov     eax, .theme_name_buffer
pop     ecx
pop     ebx
retn
db      00 ; padding

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType)
; Version of theme_file_name with one argument, which uses the 3rd byte in the
; "Available" value to switch to .var
; -----------------------------------------------------------------------------
#eip=004B526C ; A566C
theme_file_name_normal:
push    edx
mov     edx, eax ; eax = theme id
shl     edx, 5 ; multiply theme number by 20h to act as theme offset in list
mov     edx, [edx+.ThemeClass_Available]      ; _makepath_ arg name
shr     edx, 10h ; edx = upper word of .Available is used for "var theme was found"
call   .theme_file_name_ext
pop     edx
retn
dd      00 ; padding
db      00
db      00

; -----------------------------------------------------------------------------
; New ThemeClass::Scan(void)
; If Special.IsVariations enabled, and theme has Variation, this checks existence
; of the .var version, otherwise it checks existence of normal version.
; This is just a full rewrite since all complex logic is removed.
; -----------------------------------------------------------------------------
#eip=004B5528 ; A5928
push    ebx
push    ecx
push    edx
push    ebp
xor     ebp, ebp ; loop variable for theme id
scan_loopstart:
mov     eax, ebp ; theme id
mov     ecx, eax ; theme id to transform to offset
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
test    byte :SpecialOpts_4, 2
jz     .scan_not_var
mov     edx, [ecx+.ThemeClass_Variation]
test    edx, edx
jz     .scan_not_var
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
test    eax, eax
jz     .scan_not_var
mov     ebx, 10001 ; theme available, and found as var.
jmp    .scan_write_result
scan_not_var:
mov     eax, ebp ; theme id
xor     edx, edx ; should still be 0 actually
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
mov     ebx, eax
scan_write_result:
mov     ecx, ebp ; find_file destroys ecx, so we need to do this again.
shl     ecx, 5
mov     [ecx+.ThemeClass_Available], ebx
inc     ebp
cmp     ebp, 25h
jl     .scan_loopstart
pop     ebp
pop     edx
pop     ecx
pop     ebx
retn
db      00 ; padding

; ----------------------------------------------------------------------------
; const ThemeClass::Track_Length(ThemeType)
; ----------------------------------------------------------------------------

; extra code to check for .var
; This address should be 50h bytes behind the "theme_file_name_normal" start.
#eip=004B52BC ; A56BC
track_length_var:
test    byte :SpecialOpts_4, 2
jz     .normalname
shl     eax, 5
; mov     eax, [eax+.ThemeClass_Available]
db      8B ; mov eax, .ThemeClass_Available[eax]
db      80
dd     .ThemeClass_Available
shr     eax, 10 ; shift to "is alternate available?"
test    eax, eax
jz     .normalname
shr     edx, 10h
jmp    .end
normalname:
and     edx, FFFFh
end:
mov     eax, edx
retn
db      00 ; padding

; int const ThemeClass::Track_Length(ThemeType)
#eip=004B538C ; A578C
movsx   eax, dl
cmp     eax, 25
jb     .continue
xor     eax, eax
retn
continue:
mov     edx, eax
shl     edx, 5
mov     edx, [edx+.ThemeClass_Duration] ; both durations together
jmp    .track_length_var

; ===========================================================
; French
; ===========================================================

; DATA OFFSETS - IGNORE ANY ACTUAL DATA PRODUCED BY THIS.
; This section only exists to get the labels assigned for use in the code below.
#eip=00423BFC ; int find_file(char *)
find_file:
#eip=004C725F ; _makepath_
_makepath_:

#eip=004F8891 ; str_var
str_var:
#eip=004F8896 ; str_aud
str_aud:
#eip=0050B018 ; ThemeClass::_themes[]
ThemeClass_Name:
dd 0
ThemeClass_Fullname:
dd 0
ThemeClass_Scenario:
dd 0
ThemeClass_Duration:
dd 0
ThemeClass_Normal:
dd 0
ThemeClass_Variation:
dd 0
ThemeClass_Repeat:
dd 0
ThemeClass_Available:
dd 0
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00561B84 ; theme_name_buffer
theme_name_buffer:

; -----------------------------------------------------------------------------
; Track data: add alt lengths, enable hidden themes
; -----------------------------------------------------------------------------
; Not gonna redo this for all languages... it's just manual edits on the
; ThemeClass::_themes[] array data.

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType, int)
; Version of theme_file_name with two arguments, the second of which is
; a boolean to give the .var version.
; -----------------------------------------------------------------------------
; This address should be 1C bytes behind the "theme_file_name_normal" start.
#eip=004B5398 ; A5798 ; theme_file_name_ext(eax=theme, edx=var)
theme_file_name_ext:
push    ebx
push    ecx
mov     ecx, eax
test    edx, edx
jnz    .var
push    offset .str_aud                ; _makepath_ arg ext
jmp    .makename
var:
push    offset .str_var                ; _makepath_ arg ext
makename:
mov     eax, offset .theme_name_buffer ; _makepath_ arg path (destination buffer)
xor     ebx, ebx                       ; _makepath_ arg directory (empty)
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
xor     edx, edx                       ; _makepath_ arg drive (empty)
mov     ecx, [ecx+.ThemeClass_Name]    ; _makepath_ arg name
call   ._makepath_
mov     eax, .theme_name_buffer
pop     ecx
pop     ebx
retn
db      00 ; padding

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType)
; Version of theme_file_name with one argument, which uses the 3rd byte in the
; "Available" value to switch to .var
; -----------------------------------------------------------------------------
#eip=004B537C ; A577C
theme_file_name_normal:
push    edx
mov     edx, eax ; eax = theme id
shl     edx, 5 ; multiply theme number by 20h to act as theme offset in list
mov     edx, [edx+.ThemeClass_Available]      ; _makepath_ arg name
shr     edx, 10h ; edx = upper word of .Available is used for "var theme was found"
call   .theme_file_name_ext
pop     edx
retn
dd      00 ; padding
db      00
db      00

; -----------------------------------------------------------------------------
; New ThemeClass::Scan(void)
; If Special.IsVariations enabled, and theme has Variation, this checks existence
; of the .var version, otherwise it checks existence of normal version.
; This is just a full rewrite since all complex logic is removed.
; -----------------------------------------------------------------------------
#eip=004B5638 ; A5A38
push    ebx
push    ecx
push    edx
push    ebp
xor     ebp, ebp ; loop variable for theme id
scan_loopstart:
mov     eax, ebp ; theme id
mov     ecx, eax ; theme id to transform to offset
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
test    byte :SpecialOpts_4, 2
jz     .scan_not_var
mov     edx, [ecx+.ThemeClass_Variation]
test    edx, edx
jz     .scan_not_var
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
test    eax, eax
jz     .scan_not_var
mov     ebx, 10001 ; theme available, and found as var.
jmp    .scan_write_result
scan_not_var:
mov     eax, ebp ; theme id
xor     edx, edx ; should still be 0 actually
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
mov     ebx, eax
scan_write_result:
mov     ecx, ebp ; find_file destroys ecx, so we need to do this again.
shl     ecx, 5
mov     [ecx+.ThemeClass_Available], ebx
inc     ebp
cmp     ebp, 25h
jl     .scan_loopstart
pop     ebp
pop     edx
pop     ecx
pop     ebx
retn
db      00 ; padding

; ----------------------------------------------------------------------------
; const ThemeClass::Track_Length(ThemeType)
; ----------------------------------------------------------------------------

; extra code to check for .var
; This address should be 50h bytes behind the "theme_file_name_normal" start.
#eip=004B53CC ; A57CC
track_length_var:
test    byte :SpecialOpts_4, 2
jz     .normalname
shl     eax, 5
; mov     eax, [eax+.ThemeClass_Available]
db      8B ; mov eax, .ThemeClass_Available[eax]
db      80
dd     .ThemeClass_Available
shr     eax, 10 ; shift to "is alternate available?"
test    eax, eax
jz     .normalname
shr     edx, 10h
jmp    .end
normalname:
and     edx, FFFFh
end:
mov     eax, edx
retn
db      00 ; padding

; int const ThemeClass::Track_Length(ThemeType)
#eip=004B549C ; A589C
movsx   eax, dl
cmp     eax, 25
jb     .continue
xor     eax, eax
retn
continue:
mov     edx, eax
shl     edx, 5
mov     edx, [edx+.ThemeClass_Duration] ; both durations together
jmp    .track_length_var

; ===========================================================
; Japanese
; ===========================================================

; DATA OFFSETS - IGNORE ANY ACTUAL DATA PRODUCED BY THIS.
; This section only exists to get the labels assigned for use in the code below.
#eip=00423BFC ; int find_file(char *)
find_file:
#eip=004C7A3F ; _makepath_
_makepath_:

#eip=004F8901 ; str_var
str_var:
#eip=004F8906 ; str_aud
str_aud:
#eip=0050B09C ; ThemeClass::_themes[]
ThemeClass_Name:
dd 0
ThemeClass_Fullname:
dd 0
ThemeClass_Scenario:
dd 0
ThemeClass_Duration:
dd 0
ThemeClass_Normal:
dd 0
ThemeClass_Variation:
dd 0
ThemeClass_Repeat:
dd 0
ThemeClass_Available:
dd 0
#eip=0053E4A7 ; SpecialOpts_4
SpecialOpts_4:
#eip=00561988 ; theme_name_buffer
theme_name_buffer:

; -----------------------------------------------------------------------------
; Track data: add alt lengths, enable hidden themes
; -----------------------------------------------------------------------------
; Not gonna redo this for all languages... it's just manual edits on the
; ThemeClass::_themes[] array data.

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType, int)
; Version of theme_file_name with two arguments, the second of which is
; a boolean to give the .var version.
; -----------------------------------------------------------------------------
; This address should be 1C bytes behind the "theme_file_name_normal" start.
#eip=004B5B78 ; A5F78 ; theme_file_name_ext(eax=theme, edx=var)
theme_file_name_ext:
push    ebx
push    ecx
mov     ecx, eax
test    edx, edx
jnz    .var
push    offset .str_aud                ; _makepath_ arg ext
jmp    .makename
var:
push    offset .str_var                ; _makepath_ arg ext
makename:
mov     eax, offset .theme_name_buffer ; _makepath_ arg path (destination buffer)
xor     ebx, ebx                       ; _makepath_ arg directory (empty)
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
xor     edx, edx                       ; _makepath_ arg drive (empty)
mov     ecx, [ecx+.ThemeClass_Name]    ; _makepath_ arg name
call   ._makepath_
mov     eax, .theme_name_buffer
pop     ecx
pop     ebx
retn
db      00 ; padding

; -----------------------------------------------------------------------------
; char * ThemeClass::Theme_File_Name(ThemeType)
; Version of theme_file_name with one argument, which uses the 3rd byte in the
; "Available" value to switch to .var
; -----------------------------------------------------------------------------
#eip=004B5B5C ; A5F5C
theme_file_name_normal:
push    edx
mov     edx, eax ; eax = theme id
shl     edx, 5 ; multiply theme number by 20h to act as theme offset in list
mov     edx, [edx+.ThemeClass_Available]      ; _makepath_ arg name
shr     edx, 10h ; edx = upper word of .Available is used for "var theme was found"
call   .theme_file_name_ext
pop     edx
retn
dd      00 ; padding
db      00
db      00

; -----------------------------------------------------------------------------
; New ThemeClass::Scan(void)
; If Special.IsVariations enabled, and theme has Variation, this checks existence
; of the .var version, otherwise it checks existence of normal version.
; This is just a full rewrite since all complex logic is removed.
; -----------------------------------------------------------------------------
#eip=004B5E18 ; A6218
push    ebx
push    ecx
push    edx
push    ebp
xor     ebp, ebp ; loop variable for theme id
scan_loopstart:
mov     eax, ebp ; theme id
mov     ecx, eax ; theme id to transform to offset
shl     ecx, 5 ; multiply theme number by 20h to act as theme offset in list
test    byte :SpecialOpts_4, 2
jz     .scan_not_var
mov     edx, [ecx+.ThemeClass_Variation]
test    edx, edx
jz     .scan_not_var
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
test    eax, eax
jz     .scan_not_var
mov     ebx, 10001 ; theme available, and found as var.
jmp    .scan_write_result
scan_not_var:
mov     eax, ebp ; theme id
xor     edx, edx ; should still be 0 actually
call   .theme_file_name_ext
push    eax
call   .find_file
add     esp, 4
mov     ebx, eax
scan_write_result:
mov     ecx, ebp ; find_file destroys ecx, so we need to do this again.
shl     ecx, 5
mov     [ecx+.ThemeClass_Available], ebx
inc     ebp
cmp     ebp, 25h
jl     .scan_loopstart
pop     ebp
pop     edx
pop     ecx
pop     ebx
retn
db      00 ; padding

; ----------------------------------------------------------------------------
; const ThemeClass::Track_Length(ThemeType)
; ----------------------------------------------------------------------------

; extra code to check for .var
; This address should be 50h bytes behind the "theme_file_name_normal" start.
#eip=004B5BAC ; A5FAC
track_length_var:
test    byte :SpecialOpts_4, 2
jz     .normalname
shl     eax, 5
; mov     eax, [eax+.ThemeClass_Available]
db      8B ; mov eax, .ThemeClass_Available[eax]
db      80
dd     .ThemeClass_Available
shr     eax, 10 ; shift to "is alternate available?"
test    eax, eax
jz     .normalname
shr     edx, 10h
jmp    .end
normalname:
and     edx, FFFFh
end:
mov     eax, edx
retn
db      00 ; padding

; int const ThemeClass::Track_Length(ThemeType)
#eip=004B5C7C ; A607C
movsx   eax, dl
cmp     eax, 25
jb     .continue
xor     eax, eax
retn
continue:
mov     edx, eax
shl     edx, 5
mov     edx, [edx+.ThemeClass_Duration] ; both durations together
jmp    .track_length_var
