; Adding mouse wheel support to scroll through the sidebar.

; ===========================================================
; Source code equivalent:
; ===========================================================

; WINSTUB.CPP -> long FAR PASCAL _export Windows_Procedure (HWND hwnd, UINT message, UINT wParam, LONG lParam)
; In the big "switch ( message )", add a case for "WM_MOUSEWHEEL:"
; In there, evaluate wParam to see if the scrolling is up or down (not entirely sure on the details),
; and call  "Map.Scroll(bool up, int column)" with the appropriate bool arg, and once for each column.
; This function seems to currently be private, so it might need to be made public.
; I dunno enough C++ to evaluate that in detail.

; ===========================================================
; English
; ===========================================================

; top usage of SidebarClass::StripClass::Scroll
#eip=004A5608 ; int SidebarClass::Scroll(int, int)
Sidebar_Scroll:
; find from "dec     dword ptr [eax+30h]"
#eip=004A633C ; SidebarClass::StripClass::Scroll(int)
StripClass_Scroll:
#eip=0053DDC0 ; MouseClass Map
Map_data:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E5CA8 ; D60A8
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
do_sidebar_scroll:
push    ecx
push    edi
push    ebp
mov     edi, :PlayerPtr, 0
test    edi, edi
jz     .end_scroll
xor     edi, edi
shr     ecx, 10h
test    cx, cx
jl     .do_scroll
inc     edi
do_scroll:
xor     ecx, ecx
loop:
mov     ebp, .Map_data
mov     eax, ebp
mov     edx, edi ; scroll direction
mov     ebx, ecx
call   .Sidebar_Scroll
test    ecx, ecx
jnz    .end_scroll
inc     ecx
jmp    .loop
end_scroll:
pop     ebp
pop     edi
pop     ecx
retn

; original length is 3F
#eip=00410FA8 ; 13A8
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
; ebx = [esp+4+lParam]
cmp     eax, 20Ah
jnz    .not_scroll
call   .do_sidebar_scroll
pop ebx
retn  10h
not_scroll:
cmp     eax, 112h
jb      loc_411001
jbe     loc_410F70
cmp     eax, 204h
jb      loc_410FE7
cmp     eax, 206h
jbe     short loc_410FEE
cmp     eax, 209h
jbe     loc_410FEE
cmp     eax, 465h
jb      loc_411040
cmp     eax, 469h
jbe     loc_410F95
db      90       ; NOP padding
jmp     00411028 ; call __imp_DefWindowProcA

; ===========================================================
; German
; ===========================================================

; top usage of SidebarClass::StripClass::Scroll
#eip=004A5F28 ; int SidebarClass::Scroll(int, int)
Sidebar_Scroll:
; find from "dec     dword ptr [eax+30h]"
#eip=004A6C5C ; SidebarClass::StripClass::Scroll(int)
StripClass_Scroll:
#eip=0053DDC0 ; MouseClass Map
Map_data:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E6698 ; D6A98
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
do_sidebar_scroll:
push    ecx
push    edi
push    ebp
mov     edi, :PlayerPtr, 0
test    edi, edi
jz     .end_scroll
xor     edi, edi
shr     ecx, 10h
test    cx, cx
jl     .do_scroll
inc     edi
do_scroll:
xor     ecx, ecx
loop:
mov     ebp, .Map_data
mov     eax, ebp
mov     edx, edi ; scroll direction
mov     ebx, ecx
call   .Sidebar_Scroll
test    ecx, ecx
jnz    .end_scroll
inc     ecx
jmp    .loop
end_scroll:
pop     ebp
pop     edi
pop     ecx
retn

; original length is 3F
#eip=00410FA8 ; 13A8
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
; ebx = [esp+4+lParam]
cmp     eax, 20Ah
jnz    .not_scroll
call   .do_sidebar_scroll
pop     ebx
retn    10
not_scroll:
cmp     eax, 112h
jb      loc_411001
jbe     loc_410F70
cmp     eax, 204h
jb      loc_410FE7
cmp     eax, 206h
jbe     short loc_410FEE
cmp     eax, 209h
jbe     loc_410FEE
cmp     eax, 465h
jb      loc_411040
cmp     eax, 469h
jbe     loc_410F95
db      90       ; NOP padding
jmp     00411028 ; call __imp_DefWindowProcA

; ===========================================================
; French
; ===========================================================

; top usage of SidebarClass::StripClass::Scroll
#eip=004A6038 ; int SidebarClass::Scroll(int, int)
Sidebar_Scroll:
; find from "dec     dword ptr [eax+30h]"
#eip=004A6D6C ; SidebarClass::StripClass::Scroll(int)
StripClass_Scroll:
#eip=0053DDC0 ; MouseClass Map
Map_data:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E6798 ; D6B98
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
do_sidebar_scroll:
push    ecx
push    edi
push    ebp
mov     edi, :PlayerPtr, 0
test    edi, edi
jz     .end_scroll
xor     edi, edi
shr     ecx, 10h
test    cx, cx
jl     .do_scroll
inc     edi
do_scroll:
xor     ecx, ecx
loop:
mov     ebp, .Map_data
mov     eax, ebp
mov     edx, edi ; scroll direction
mov     ebx, ecx
call   .Sidebar_Scroll
test    ecx, ecx
jnz    .end_scroll
inc     ecx
jmp    .loop
end_scroll:
pop     ebp
pop     edi
pop     ecx
retn

; original length is 3F
#eip=00410FA8 ; 13A8
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
; ebx = [esp+4+lParam]
cmp     eax, 20Ah
jnz    .not_scroll
call   .do_sidebar_scroll
pop ebx
retn  10h
not_scroll:
cmp     eax, 112h
jb      loc_411001
jbe     loc_410F70
cmp     eax, 204h
jb      loc_410FE7
cmp     eax, 206h
jbe     short loc_410FEE
cmp     eax, 209h
jbe     loc_410FEE
cmp     eax, 465h
jb      loc_411040
cmp     eax, 469h
jbe     loc_410F95
db      90       ; NOP padding
jmp     00411028 ; call __imp_DefWindowProcA

; ===========================================================
; Japanese
; ===========================================================

; top usage of SidebarClass::StripClass::Scroll
#eip=004A67F8 ; int SidebarClass::Scroll(int, int)
Sidebar_Scroll:
; find from "dec     dword ptr [eax+30h]"
#eip=004A752C ; SidebarClass::StripClass::Scroll(int)
StripClass_Scroll:
#eip=0053DDC4 ; MouseClass Map
Map_data:
#eip=0053E700 ; HouseClass *PlayerPtr
PlayerPtr:

; Sadly won't fit behind the commando voice code in this version,
; so another big open block below it is used.
#eip=004E71A0 ; D75A0
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
do_sidebar_scroll:
push    ecx
push    edi
push    ebp
mov     edi, :PlayerPtr, 0
test    edi, edi
jz     .end_scroll
xor     edi, edi
shr     ecx, 10h
test    cx, cx
jl     .do_scroll
inc     edi
do_scroll:
xor     ecx, ecx
loop:
mov     ebp, .Map_data
mov     eax, ebp
mov     edx, edi ; scroll direction
mov     ebx, ecx
call   .Sidebar_Scroll
test    ecx, ecx
jnz    .end_scroll
inc     ecx
jmp    .loop
end_scroll:
pop     ebp
pop     edi
pop     ecx
retn

; original length is 3F
#eip=00410FA8 ; 13A8
; edx = [esp+4+hWnd]
; eax = [esp+4+Msg]
; ecx = [esp+4+wParam]
; ebx = [esp+4+lParam]
cmp     eax, 20Ah
jnz    .not_scroll
call   .do_sidebar_scroll
pop ebx
retn  10h
not_scroll:
cmp     eax, 112h
jb      loc_411001
jbe     loc_410F70
cmp     eax, 204h
jb      loc_410FE7
cmp     eax, 206h
jbe     short loc_410FEE
cmp     eax, 209h
jbe     loc_410FEE
cmp     eax, 465h
jb      loc_411040
cmp     eax, 469h
jbe     loc_410F95
db      90       ; NOP padding
jmp     00411028 ; call __imp_DefWindowProcA
