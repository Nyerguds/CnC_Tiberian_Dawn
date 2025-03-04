IDEAL
P386
MODEL USE32 FLAT

INCLUDE "gbuffer.inc"

CODESEG

GLOBAL C Buffer_Texture_Fill_Rect : NEAR

LOCALS ??

    PROC Buffer_Texture_Fill_Rect C
    
    USES eax,ebx,ecx,edx,esi,edi
    
    LOCAL bufferwidth:dword
    LOCAL x_pixel    :dword
    LOCAL y_pixel    :dword
    
    ARG thisptr      :dword
    ARG x0_pixel     :dword
    ARG y0_pixel     :dword
    ARG x1_pixel     :dword
    ARG y1_pixel     :dword
    ARG shape_pointer:dword
    ARG source_width :dword
    ARG source_height:dword

                mov     ebx, [thisptr]
                mov     edx, [ebx+GraphicViewPort.GVPWidth]
                mov     eax, [x0_pixel]
                mov     ecx, [y0_pixel]
                add     eax, [x1_pixel]
                add     ecx, [y1_pixel]
                sub     eax, [ebx+GraphicViewPort.GVPWidth]
                jl      short adjust_1

                sub     [x1_pixel], eax


adjust_1:
                sub     ecx, [ebx+GraphicViewPort.GVPHeight]
                jl      short adjust_2

                sub     [y1_pixel], ecx


adjust_2:
                mov     eax, [x0_pixel]
                mov     ecx, [y0_pixel]
                test    eax, eax
                jge     short adjust_3

                sub     [x1_pixel], eax
                mov     [x0_pixel], 0


adjust_3:
                test    ecx, ecx
                jge     short doit

                sub     [x1_pixel], ecx
                mov     [y0_pixel], 0


doit:
                cmp     [x1_pixel], 0
                jle     ??exit

                cmp     [y1_pixel], 0
                jle     ??exit

                mov     edi, [ebx+GraphicViewPort.GVPOffset]
                mov     eax, [ebx+GraphicViewPort.GVPXAdd]
                add     eax, [ebx+GraphicViewPort.GVPPitch]
                add     eax, [ebx+GraphicViewPort.GVPWidth]
                mov     [bufferwidth], eax
                
                imul    eax, [y0_pixel]
                add     edi, [x0_pixel]
                lea     edi, [edi+eax]
                mov     esi, [shape_pointer]
                mov     eax, [x1_pixel]
                sub     [bufferwidth], eax
                mov     [x_pixel], esi
                mov     edx, [y1_pixel]
                mov     eax, [source_height]
                mov     [y_pixel], eax


    process:
                mov     ebx, [x1_pixel]
                mov     esi, [x_pixel]
                test    edi, 3
                jz      short aligned

                movsb
                dec     ebx
                jz      short next

                test    edi, 3
                jz      short aligned

                movsb
                dec     ebx
                jz      short next

                test    edi, 3
                jz      short aligned

                movsb
                dec     ebx
                jz      short next


    aligned:
                mov     ecx, ebx
                shr     ecx, 2
                rep movsd
                mov     ecx, ebx
                and     ecx, 3
                rep movsb


    next:
                mov     ebx, [source_width]
                add     edi, [bufferwidth]
                add     [x_pixel], ebx
                dec     [y_pixel]
                jnz     short skip

                mov     esi, [shape_pointer]
                mov     [x_pixel], esi
                mov     eax, [source_height]
                mov     [y_pixel], eax


    skip:
                dec     edx
                jnz     short process


    ??exit:
                ret

    ENDP Buffer_Texture_Fill_Rect
    
END
END