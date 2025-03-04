;
;	Command & Conquer Red Alert(tm)
;	Copyright 2025 Electronic Arts Inc.
;
;	This program is free software: you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation, either version 3 of the License, or
;	(at your option) any later version.
;
;	This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

;***************************************************************************
;**     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
;***************************************************************************
;*                                                                         *
;*                 Project Name : Mono Screen system                       *
;*                                                                         *
;*                    File Name : MONO.ASM                                 *
;*                                                                         *
;*                   Programmer : Jeff Wilson                              *
;*                                                                         *
;*                   Start Date : March 28, 1994                           *
;*                                                                         *
;*                  Last Update : September 8, 1994   [IML]                *
;*                                                                         *
;*-------------------------------------------------------------------------*
;* Functions:                                                              *
;GLOBAL              MonoScreen           :DWORD
;GLOBAL              MonoEnabled          :DWORD
;
;GLOBAL C            Mono_Set_Cursor      :NEAR
;GLOBAL C            Mono_Clear_Screen    :NEAR
;GLOBAL C            Mono_Scroll          :NEAR
;GLOBAL C            Mono_Put_Char        :NEAR
;GLOBAL C            Mono_Draw_Rect       :NEAR
;
;GLOBAL C            _Mono_Text_Print     :NEAR
;GLOBAL C            Mono_Text_Print      :NEAR
;
;GLOBAL C            Mono_Print           :NEAR
;
;GLOBAL C            Mono_View_Page       :NEAR
;* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - *


IDEAL
P386
MODEL USE32 FLAT

LOCALS ??


;
; External declares so these functions can be called
;
GLOBAL          MonoScreen              :DWORD
GLOBAL          MonoEnabled             :DWORD  

GLOBAL         Mono_Set_Cursor         :NEAR	; done
GLOBAL         Mono_Clear_Screen       :NEAR	; done
GLOBAL         Mono_Scroll             :NEAR	; done
GLOBAL         Mono_Put_Char           :NEAR	; done
GLOBAL         Mono_Draw_Rect          :NEAR	; done
GLOBAL        _Mono_Text_Print         :NEAR	; done
GLOBAL         Mono_Text_Print         :NEAR	; done
GLOBAL         Mono_Print              :NEAR 	; done
GLOBAL         Mono_View_Page          :NEAR	; done

;
; Equates used in this file
;
NULL =  0       ; null code
CR   =  13      ; carriage return code
CPL  =  80      ; characters per line
LPS  =  25      ; lines per screen


DATASEG

MonoX           DD      0
MonoY           DD      0
MonoOff         DD      0
MonoScreen      DD      0b0000h                 ;Deffault to Real mode!
MonoEnabled     DD      0                       ; Is mono printing enabled?

;====================================================================

CharData        DB      0DAh,0C4h,0BFh,0B3h,0D9h,0C4h,0C0h,0B3h ; Single line
                DB      0D5h,0CDh,0B8h,0B3h,0BEh,0CDh,0D4h,0B3h ; Double horz.
                DB      0D6h,0C4h,0B7h,0BAh,0BDh,0C4h,0D3h,0BAh ; Double vert.
                DB      0C9h,0CDh,0BBh,0BAh,0BCh,0CDh,0C8h,0BAh ; Double line.


;               x,y,dist
BoxData DB      1,0,0           ; Upper left corner.
        DB      1,0,1           ; Top edge.
        DB      0,1,0           ; Upper right corner.
        DB      0,1,2           ; Right edge.
        DB      -1,0,0          ; Bottom right corner.
        DB      -1,0,1          ; Bottom edge.
        DB      0,-1,0          ; Bottom left corner.
        DB      0,-1,2          ; Left edge.
        DB      0,0,-1          ; End of list.

; Mono page segment layout array.
PageMap DD      0,1,2,3,4,5,6,7

;===================================================================

CODESEG


;***************************************************************************
;* Map_Segment_To_Address_ -- Translate a 16bit Seg:Offset address to a    *
;*                            Linear address.                              *                            
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; int Map_Segment_To_Address ( unsigned seg , unsigned offset );



;***************************************************************************
;* MONO_SET_CURSOR -- Sets the mono cursor to specified coordinates.       *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Set_Cursor(int x, int y);


PROC Mono_Set_Cursor    C near 

        USES eax , ebx , edx 

        ARG     xpos : DWORD
        ARG     ypos : DWORD

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

;       sub     eax,eax

        mov     eax,[ypos]
;        mov     ah,CPL
;        imul    ah
  lea  eax , [ eax + 4 * eax ]   ; multiply by CPL
  shl  eax , 4

;       sub     ebx,ebx
        mov     ebx,[xpos]
        add     ebx,eax

        ; Update cursor position.
        mov     edx,03B4h

        mov     al,0Eh                  ; High byte register set.
        out     dx,al
        inc     edx
        mov     al,bh
        out     dx,al                   ; Set high byte.

        dec     edx
        mov     al,0Fh                  ; Low byte register set.
        out     dx,al
        inc     edx
        mov     al,bl
        out     dx,al                   ; Set low byte.

        ; Update the globals.
        add     ebx,ebx
        mov     [MonoOff],ebx
        mov     eax,[xpos]
        mov     [MonoX],eax
        mov     eax,[ypos]
        mov     [MonoY],eax

??exit:
        ret

ENDP    Mono_Set_Cursor


;***************************************************************************
;* MONO_CLEAR_SCREEN -- Clears the mono screen and homes cursor.           *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Clear_Screen(void);

PROC Mono_Clear_Screen  C near 
        
        USES eax , ecx , edi

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

;       mov     eax,[MonoScreen]        ; ES:DI = Mono RAM address.
;       mov     es,ax
;       sub     edi,edi
   mov  edi , [ MonoScreen ]
        mov     eax,02000200h           ; Clear leave attrib bit normal.
        mov     ecx,8000h/4             ; Number of longs to clear.
        rep     stosd                       ; Clear the mono screen.

        push    0
        push    0

        call    Mono_Set_Cursor
        add     esp , 8

??exit:
        ret

ENDP    Mono_Clear_Screen


;***************************************************************************
;* MONO_SCROLL -- Scroll the mono screen up specified lines.               *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Scroll(DWORD lines);
PROC Mono_Scroll        C near 

        USES 	eax , ebx , ecx , edx , edi , esi
        ARG     lines : DWORD

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

;       xor     eax,eax                 ; clear eax so no need for sign extend
        mov     eax, [lines]             ; get lines available
        or      eax,eax                 ; any lines  to scroll?
        je      short ??fini            ; =>NO

        mov     ebx,eax                 ; set line counter
                                                    
        mov     edx,[MonoY]             ; get row count
        ror     edx,16                  ; store it in high half of register
        mov     dx,[WORD PTR MonoOff]   ; get column offset
        ror     edx,16
                     
;        mov     eax,[MonoScreen]        ; get selector for mono screen
;        push    ds                      ; save off data seg for later
;        mov     ds,ax                   ; set data source register
;        mov     es,ax                   ;  and extra source register

        sub     eax,eax                 ; set to clear clear line
        
??looper:
        mov     ecx,(80*24)             ; Number of words to move.

 ;      xor     edi,edi                 ; dst start at top of screen area
 ;      mov     esi,80*2                ; src start at next line down
    mov edi , [ MonoScreen ]
    lea esi , [ 80 * 2 + edi ]       
        rep     movsw                   ; Scroll the screen upward.

        dec     dx                      ; decrement Y counter
        ror     edx,16                  ; switch to mono offset
        sub     dx,80*2                 ; fix MonoOffset
        ror     edx,16                  ; switch to y counter

        mov     ecx,40                  ; Clear out the last line.
        rep     stosd                   ;   by storing words across it
        dec     ebx                     ; last line?

        jne     ??looper                ; =>NO

        ; reset data values
  ;     pop     ds                      ; restore the ds segment
        mov     [WORD PTR MonoY],dx     ; store of the mono y position
        ror     edx,16                  ; switch to screen offset
        mov     [WORD PTR MonoOff],dx   ; store of the mono offset
                
??fini:
??exit:
        ret

ENDP    Mono_Scroll


;***************************************************************************
;* MONO_PUT_CHAR -- Output a character to the mono screen.                 *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Put_Char(char character, int attrib=2);

PROC Mono_Put_Char      C near 

        USES    eax , edi

        ARG     character : BYTE
        ARG     attrib    : DWORD

        cmp     [MonoEnabled],0
        je      ??exit
                       
;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax

        mov     edi,[MonoOff]
;        mov     eax,[MonoScreen]
;        mov     es,ax                   ; ES:DI = First character output pointer.
   add edi , [ MonoScreen ]

        ; Output character to monochrome monitor.
        mov     al,[character]
        mov     ah,[BYTE PTR attrib]
;       stosw       
        mov     [ edi ] , ax

        ; Update cursor position.
        inc     [MonoX]         ; X position moves.

        mov     eax,[MonoY]
        push    eax
        mov     eax,[MonoX]
        push    eax

        call    Mono_Set_Cursor 
        add     esp,8

??exit:
        ret

ENDP    Mono_Put_Char


;***************************************************************************
;* MONO_DRAW_RECT -- Draw a rectangle using mono characters.               *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Draw_Rect(int x, int y, int w, int h, int attrib=2, int thick=0);

PROC Mono_Draw_Rect     C near 

        USES eax , ebx , ecx , esi , edi

        ARG     xpos:DWORD
        ARG     ypos:DWORD
        ARG     width:DWORD
        ARG     height:DWORD
        ARG     attrib:DWORD
        ARG     thick:DWORD

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

        mov     esi,OFFSET BoxData
        mov     edi,OFFSET CharData

;       mov     cl,3
;       sub     eax,eax
        mov     eax,[thick]
        and     eax,011b
        shl     eax,3
        add     edi,eax

        ; Prep width and height.
        cmp     [width],2
        jb      ??fini

        cmp     [height],2
        jb      ??fini

        sub     [width],2
        sub     [height],2

        ; Preserve cursor position for later restore.
        mov     ecx,[MonoX]
        push    ecx
        mov     ecx,[MonoY]
        push    ecx

        ; Cursor starts at upper left corner.
        mov     ecx,[ypos]
        push    ecx
        mov     ecx,[xpos]
        push    ecx
        call    Mono_Set_Cursor 
        add     esp,8

??drawloop:
        ; Determine the number of characters to output.
        mov     ecx,[width]
        cmp     [BYTE PTR esi+2],1
        je      short ??gotlen

        mov     ecx,[height]
        cmp     [BYTE PTR esi+2],2
        je      short ??gotlen

        mov     ecx,1
??gotlen:

        jecxz   ??donerun

??runloop:
        sub     ebx,ebx
        mov     bl,[BYTE PTR edi]

;       mov     ebx,eax
        sub     eax,eax
        mov     al,[BYTE PTR attrib]
        push    eax
        push    ebx

        call    Mono_Put_Char 
        add     esp,8

        movsx   eax,[BYTE PTR esi+1]
;       cbw
        add     eax,[MonoY]
        push    eax
        movsx   eax,[BYTE PTR esi]
;       cbw
        add     eax,[MonoX]
        dec     eax                     ; Undo cursor advance.
        push    eax

        call    Mono_Set_Cursor         ; Properly advance cursor.
        add     esp,8

        loop    ??runloop

??donerun:

        ; Advance to next control entry.
        add     esi,3
        inc     edi
        cmp     [BYTE PTR esi+2],-1
        jne     ??drawloop

        ; Restore cursor to original position.
        call    Mono_Set_Cursor
        add     esp,8

??fini:
??exit:
        ret

ENDP    Mono_Draw_Rect


;***************************************************************************
;* MONO_TEXT_PRINT -- Prints text to the mono screen at coordinates.       *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Text_Print(void *text, int x, int y, int attrib, int update);

PROC _Mono_Text_Print   C near 

        USES eax,ebx,ecx,edx,edi,esi

        ARG     text:DWORD
        ARG     xpos:DWORD
        ARG     ypos:DWORD
        ARG     attrib:DWORD
        ARG     update:DWORD

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

        ; Preserve cursor coordinates for later restoration.
        mov     eax,[MonoY]
        push    eax
        mov     eax,[MonoX]
        push    eax

        cmp     [text],NULL
        je      ??fini

        mov     eax,[ypos]
        push    eax
        mov     eax,[xpos]
        push    eax
        call    Mono_Set_Cursor 
        add     esp,8

        mov     esi,[text]

??charloop:
        xor     eax,eax
        mov     al,[BYTE PTR esi]               ; Fetch character to output.
        inc     esi

        ; Stop processing on a NULL character.
        or      eax,eax
        je      short ??fini

        ; Special processing for a '\r' characters.
        cmp     eax,CR
        je      short ??cr

        ; Output character to monochrome monitor.
??normal:
;       xor     ah,ah

        mov     ebx,eax
        mov     eax,[attrib]
        push    eax
        push    ebx
        call    Mono_Put_Char 
        add     esp,8

        ; Perform adjustments if wrapping past right margin.
        cmp     [WORD PTR MonoX],CPL
        jb      short ??nowrap

        inc     [ypos]

        mov     eax,[ypos]
        push    eax
;       sub     eax,eax
        push    0
        call    Mono_Set_Cursor 
        add     esp,8

        jmp short ??nowrap

        ; Move to start of next line.
??cr:
        inc     [ypos]

        mov     eax,[ypos]
        push    eax
        mov     eax,[xpos]
        push    eax
        call    Mono_Set_Cursor 
        add     esp,8

        ; Scroll the monochrome screen if necessary.
??nowrap:
        cmp     [MonoY],LPS
        jb      short ??noscroll

        push    1
        call    Mono_Scroll 
        add     esp,4

        dec     [ypos]

??noscroll:
        jmp short ??charloop

??fini:
        cmp     [update],0
        jne     short ??noupdate

        call    Mono_Set_Cursor
??noupdate:
        add     esp,8

??exit:
        ret

ENDP    _Mono_Text_Print

;=====================================================================

PROC Mono_Text_Print    C near 
        USES    eax
        ARG     text:DWORD
        ARG     xpos:DWORD
        ARG     ypos:DWORD
        ARG     attrib:DWORD


        cmp     [MonoEnabled],0
        je      ??exit

;       sub     eax,eax
        push    0
        mov     eax,[attrib]
        push    eax
        mov     eax,[ypos]
        push    eax
        mov     eax,[xpos]
        push    eax
        mov     eax,[text]
        push    eax

        call    _Mono_Text_Print 
        add     esp,20

??exit:
        ret

ENDP    Mono_Text_Print



;***************************************************************************
;* MONO_PRINT -- Prints text to the mono screen at current pos.            *
;*                                                                         *
;*                                                                         *
;*                                                                         *
;* INPUT:                                                                  *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; void Mono_Print(void *text);

PROC Mono_Print         C near 
        
        USES eax

        ARG     text:DWORD

        cmp     [MonoEnabled],0
        je      ??exit

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

;       mov     eax,1
        push    1
;       mov     eax,2
        push    2
        mov     eax,[MonoY]
        push    eax
        mov     eax,[MonoX]
        push    eax
        mov     eax,[text]
        push    eax

        call    _Mono_Text_Print 
        add     esp,20

??exit:
        ret

ENDP    Mono_Print

;***************************************************************************
;* Mono_View_Page -- page in a mono screen                                 *
;*                                                                         *
;*   Displays the specified page in displayable mono memory area.          *
;*                                                                         *
;* INPUT:  WORD page = which page of memory we will use for storage        *
;*                                                                         *
;* OUTPUT: old_page                                                        *
;*                                                                         *
;* WARNINGS:    none.                                                      *
;*                                                                         *
;* HISTORY:                                                                *
;*=========================================================================*
; int cdecl Mono_View_Page(int page);


PROC Mono_View_Page     C near 

        USES eax,ebx,ecx,edx,edi,esi

        ARG     page:DWORD

        LOCAL   oldpage:DWORD

        cmp     [MonoEnabled],0
        je      ??exit

        cld

;       mov     ax,cs
;       and     ax,7
;       or      ax,SS_DATA

;       mov     ds,ax
;       mov     es,ax

        ; Prepare the original page number for return to caller.
        mov     ebx,[PageMap]
        mov     [oldpage],ebx

        ; If the desired page is already displayed, then don't do anything.
        mov     eax,[page]
        cmp     eax,ebx
        je      short ??fini

        ; Verify that page specified is legal.
        cmp     eax,7
        ja      short ??fini

        ; Find where the logical page to display is actually located.
        mov     ecx,8

        mov     edi,OFFSET PageMap
        repne   scasd
        neg     ecx
        add     ecx,7                   ; ECX = where desired page is located.

        ; Swap the page ID bytes in the PageMap array.
        sub     edi,4
        mov     ebx,[PageMap]
        mov     eax,[edi]
        mov     [edi],ebx
        mov     [PageMap],eax

        ; Set DS and ES to point to each page.
;        mov     eax,[MonoScreen]
;        mov     ds,ax
   mov esi , [ MonoScreen ]
;        shl     ecx,8
   shl ecx , 12
;        add     ecx,edi                 ; NO Addition to selectors!
   lea edi , [ esi + ecx ]

;       mov     edi,ecx
;       xor     esi,esi

        ; Exchange the two pages.
        mov     ecx,1000H/4

??looper:
        mov     edx,[edi]
        mov     ebx,[esi]
        mov     [edi],ebx
        mov     [esi],edx
        add     esi,4
        add     edi,4
        loop    ??looper

        ; Return with the original page number.
??fini:
??exit:
        mov     eax,[oldpage]
        ret
        
ENDP    Mono_View_Page

END

