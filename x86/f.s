section .data
    plane_parameters:   times 16    dd      0
    edges:              times 12    dd      0
    vectors:            times 12    dd      0

section .text

global f
extern printf
f:
    push rbp
    mov rbp, rsp

    ; rdi       , rsi       , rdx        , rcx       , r8       , r9            , r10
    ; pBuffer   , W         , H          , alpha     , betha    , coordinates[] , translated_coors  , output     , z_buffer
    ;           , [rbp - 24], [rbp - 32] , [rbp - 8] , [rbp - 16]               , [rbp + 16]        , [rbp + 24] , [rbp + 32]

; coordinate translation
    sub rsp, 88
    mov[rbp - 8], rcx
    mov[rbp - 16], r8
    mov QWORD [rbp - 24], 180
    mov [rbp - 32], rsi      ; W
    mov [rbp - 40], rdx      ; H


    mov r10, [rbp + 16]

    mov ecx, 4
coordinate_translation_loop:

    ; rotation around x axis
    ; y' = ycos - zsin
    ; z' = ysin + zcos

    finit
    fild DWORD [rbp - 8]          ; alpha
    fldpi                         ; pi
    fmul                          ; pi * alpha
    fild DWORD [rbp - 24]         ; 180
    fdiv                          ; pi * alpha / 180
    fsincos                       ; cos, sin   
    fld st1                       ; cos, sin, cos, sin   
    fld st1   
    fild DWORD [r9 + 4]           ; y
    fmul st3, st0                 ; y, cos, sin, ycos, sin
    fmulp st4, st0                ; cos, sin, ycos, ysin
    fild DWORD [r9 + 8]           ; z
    fmul st2, st0                 ; z, cos, zsin
    fmulp                         ; zcos, zsin, ycos, ysin
    faddp st3, st0                ; zsin, ycos, ysin + zsin
    fsub                          ; ycos - zsin, ysin + zcos               

    fistp DWORD [r10 + 4]         ; save y
    fistp DWORD [r10 + 8]         ; save z

    ; rotation around y axis
    ; z' = zcos - xsin
    ; x' = zsin + xcos

    finit
    fild DWORD [rbp - 16]         ; betha
    fldpi                         ; pi
    fmul                          ; pi * betha
    fild DWORD [rbp - 24]         ; 180
    fdiv                          ; pi * betha / 180
    fsincos                       ; cos, sin   
    times 2 fld st1               ; cos, sin, cos, sin      
    fild DWORD [r10 + 8]          ; z
    fmul st4, st0                 ; z, cos, sin, cos, zsin
    fmulp st3, st0                ; z, cos, sin, ycos, zsin
    fild DWORD [r9 + 0]           ; x
    fmul st2, st0                 ; x, cos, xsin
    fmul                          ; xcos, xsin, zcos, zsin
    faddp st3, st0                ; xsin, zcos, zsin + xsin
    fsub                          ; zcos - xsin, zsin + xcos               

    fistp DWORD [r10 + 8]         ; save z
    fistp DWORD [r10 + 0]         ; save x

    add r9, 12
    add r10, 12

    loop coordinate_translation_loop

    sub r10, 48                   ; beginning of the array
    

    mov ecx, 4
displace:                         ; move the coordinates, so that the tetrahedron
    add dword [r10], 200          ; rotates around the middle, and does not disappear too often 
    add dword [r10 + 4], 200      ; the origin of the coordinate system is now in the middle of the window
    sub dword [r10 + 8], 200
    add r10, 12
    loop displace

    sub r10, 48


; preprocessing (vector calculation)
;   Xab = Bx - Ax

    mov r11, 0
    mov ecx, 9
consecutive_points_vector_calc_loop:
    mov eax, [r10 + 12]
    sub eax, [r10]
    mov [vectors + r11], eax
    add r10, 4
    add r11, 4
    loop consecutive_points_vector_calc_loop

    sub r10, 36


    mov ecx, 3
vector_AD_loop:
    mov eax, [r10 + 36]
    sub eax, [r10]
    mov [vectors + r11], eax
    add r10, 4
    add r11, 4
    loop vector_AD_loop

    sub r10, 12


; preprocessing (plane parameter calculation)
;
;   p1ABC = Yab * Zbc - Zab * Ybc
;   p2ABC = Zab * Xbc - Xab * Zbc
;   p3ABC = Xab * Ybc - Yab * Xbc
;   p4ABC = -p1 * Cx - p2 * Cy - p3 * Cz

    ; ABD
    finit
    ; p1
    fild DWORD [vectors + 4]
    fimul DWORD [vectors + 44]
    fild DWORD [vectors + 8]
    fimul DWORD [vectors + 40]
    fsub
    fistp DWORD [plane_parameters]
    ; p2
    fild DWORD [vectors + 8]
    fimul DWORD [vectors + 36]
    fild DWORD [vectors + 0]
    fimul DWORD [vectors + 44]
    fsub
    fistp DWORD [plane_parameters + 4]
    ; p3
    fild DWORD [vectors + 0]
    fimul DWORD [vectors + 40]
    fild DWORD [vectors + 4]
    fimul DWORD [vectors + 36]
    fsub
    fistp DWORD [plane_parameters + 8]
    ; p4
    fldz
    fisub DWORD [plane_parameters + 0]
    fimul DWORD [r10 + 0]
    fild DWORD [plane_parameters + 4]
    fimul DWORD [r10 + 4]
    fsub
    fild DWORD [plane_parameters + 8]
    fimul DWORD [r10 + 8]
    fsub
    fistp DWORD [plane_parameters + 12]


    ; ABC, BCD, ABD
    mov r11, 0
    mov r14, 0
    mov ecx, 3
consecutive_vectors_pparam_calc_loop:
    ; p1
    fild DWORD [vectors + r11 + 4]
    fimul DWORD [vectors + r11 + 20]
    fild DWORD [vectors + r11 + 8]
    fimul DWORD [vectors + r11 + 16]
    fsub
    fistp DWORD [plane_parameters + r14 + 16]
    ; p2
    fild DWORD [vectors + r11 + 8]
    fimul DWORD [vectors + r11 + 12]
    fild DWORD [vectors + r11 + 0]
    fimul DWORD [vectors + r11 + 20]
    fsub
    fistp DWORD [plane_parameters + r14 + 20]
    ; p3
    fild DWORD [vectors + r11 + 0]
    fimul DWORD [vectors + r11 + 16]
    fild DWORD [vectors + r11 + 4]
    fimul DWORD [vectors + r11 + 12]
    fsub
    fistp DWORD [plane_parameters + r14 + 24]
    ; p4
    fldz
    fisub DWORD [plane_parameters + r14 + 16]
    fimul DWORD [r10 + 24]
    fild DWORD [plane_parameters + r14 + 20]
    fimul DWORD [r10 + 28]
    fsub
    fild DWORD [plane_parameters + r14 + 24]
    fimul DWORD [r10 + 32]
    fsub
    fistp DWORD [plane_parameters + r14 + 28]

    add r11, 12
    add r14, 16

    dec ecx;
    jnz consecutive_vectors_pparam_calc_loop
    
; preprocessing (edge parameters calculation)
;
;   a = (y2 - y1) / (x2 - x1)
;   b = y1 - ax1

    ;AD
    fild DWORD [r10 + 40]       ; y2
    fisub DWORD [r10 + 4]       ; y2 - y1
    fild DWORD [r10 + 36]       ; x2
    fisub DWORD [r10 + 0]       ; x2 - x1
    fdiv                        ; (y2 - y1) / (x2 - x1)
    fst DWORD [edges + 24]      ; a
    fild DWORD [r10 + 4]        ; y1
    fild DWORD [r10 + 0]        ; x1
    fmul st2                    ; a * x1
    fsub                        ; y1 - a*x1
    fstp DWORD [edges + 28]     ; b

    ;AB, BC, CD

    mov r14, 0
    mov r15, 0
    mov ecx, 3
AB_BC_CD_edge_calc_loop:
    fild DWORD [r10 + r14 + 16]       ; y2
    fisub DWORD [r10 + r14 + 4]       ; y2 - y1
    fild DWORD [r10 + r14 + 12]       ; x2
    fisub DWORD [r10 + r14 + 0]       ; x2 - x1
    fdiv                              ; (y2 - y1) / (x2 - x1)
    fst DWORD [edges + r15 + 0]       ; a
    fild DWORD [r10 + r14 + 4]        ; y1
    fild DWORD [r10 + r14 + 0]        ; x1
    fmul st2                          ; a * x1
    fsub                              ; y1 - a*x1
    fstp DWORD [edges + r15 + 4]      ; b

    add r14, 12
    add r15, 8
    loop AB_BC_CD_edge_calc_loop

    mov r14, 0
    mov r15, 0
    mov ecx, 2
AC_CD_edge_calc_loop:
    fild DWORD [r10 + r14 + 28]       ; y2
    fisub DWORD [r10 + r14 + 4]       ; y2 - y1
    fild DWORD [r10 + r14 + 24]       ; x2
    fisub DWORD [r10 + r14 + 0]       ; x2 - x1
    fdiv                              ; (y2 - y1) / (x2 - x1)
    fst DWORD [edges + r15 + 32]      ; a
    fild DWORD [r10 + r14 + 4]        ; y1
    fild DWORD [r10 + r14 + 0]        ; x1
    fmul st2                          ; a * x1
    fsub                              ; y1 - a*x1
    fstp DWORD [edges + r15 + 36]     ; b

    add r14, 12
    add r15, 8

    loop AC_CD_edge_calc_loop


; z-buffer

    mov QWORD r15, [rbp + 32]   ; z-buffer

    mov r8, 0                   ; plane parameter offset
    mov ecx, 4
triangles_drawing_loop:

    mov r13, 0              ; y (row iterator)
loop_y:
    mov [rbp - 56], r13     ; y on stack
    mov r11, 0              ; x (column iterator)

loop_x:
    mov [rbp - 48], r11     ; x on stack
    mov rax, r13            ; y
    mul QWORD [rbp - 32]    ; y * W (destroys RDX)
    add rax, r11            ; y * W + x

;   z = (p1 * x + p2 * y + p4) / p3

    finit
    fild DWORD [plane_parameters + r8 + 0]
    fild DWORD [rbp - 48]                       ; p1 * x
    fmul
    fild DWORD [plane_parameters + r8 + 4]
    fild DWORD [rbp - 56]                       ; p2 * y
    fmul
    fadd                                        ; p1*x + p2*y
    fild DWORD [plane_parameters + r8 + 12]     ; p4
    fadd                                        ; p1*x + p2*y + p4
    fild DWORD [plane_parameters + r8 + 8]      ; /p3
    fdiv
    fistp DWORD [rbp - 64]                      ; z

    mov Dword r14d, [rbp - 64]
    mov DWORD r9d, [r15 + 4 * rax]
    cmp r14d, r9d
    jl behind_is_first
    jmp draw
behind_is_first:
    cmp ecx, 4
    je draw_black
    jmp next_pixel

draw:
    cmp ecx, 3
    je check_in_ABC
    cmp ecx, 2
    je check_in_BCD
    cmp ecx, 1
    je check_in_CDA

check_in_ABD:
check_D_AB:
    finit
    fld DWORD [edges + 0]           ; aAB
    fimul DWORD [r10 + 36]          ; * X
    fadd DWORD [edges + 4]          ; + bAB
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 0]           ; a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 4]          ; b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 40]
    cmp r9d, r14d                    
    jl DlAB                         ; if (Dy > a*Dx + b)
DgAB:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl draw_black
    jmp check_A_BD
DlAB:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg draw_black
check_A_BD:
    finit
    fld DWORD [edges + 40]          ; a
    fimul DWORD [r10 + 0]           ; * X
    fadd DWORD [edges + 44]         ; + b
    fistp QWORD [rbp - 72]

    fld DWORD [edges + 40]           ; a
    fimul DWORD [rbp - 48]           ; x
    fadd DWORD [edges + 44]          ; b
    fistp QWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 4]              ; Y
    cmp r9d, r14d                    
    jl AlBD                         ; if (Y > a*X + b)
AgBD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]              ; y
    cmp r9d, r14d
    jl draw_black
    jmp check_B_AD
AlBD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg draw_black

check_B_AD:
    finit
    fld DWORD [edges + 24]          ; a
    fimul DWORD [r10 + 12]           ; * X
    fadd DWORD [edges + 28]         ; + b
    fistp QWORD [rbp - 72]

    fld DWORD [edges + 24]           ; a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 28]          ; b
    fistp QWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 4]              ; Y
    cmp r9d, r14d                     
    jl BlAD                         ; if (Y > a*X + b)
BgAD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]              ; y
    cmp r9d, r14d
    jl draw_black
    jmp draw_ABD
BlAD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg draw_black
draw_ABD:
    mov DWORD [rdi + rax * 4], 0x0057c470
    mov Dword r14d, [rbp - 64]
    mov DWORD [r15 + 4 * rax], r14d

    jmp next_pixel

check_in_ABC:
check_C_AB:
    finit
    fld DWORD [edges + 0]           ;! aAB
    fimul DWORD [r10 + 24]          ;! * X
    fadd DWORD [edges + 4]          ;! + bAB
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 0]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 4]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 28]             ;! Y
    cmp r9d, r14d                    
    jl ClAB                         ;! if (Dy > a*Dx + b)
CgAB:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_A_BC                  ;!
ClAB:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

check_A_BC:
    finit
    fld DWORD [edges + 8]           ;! a
    fimul DWORD [r10 + 0]           ;! * X
    fadd DWORD [edges + 12]         ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 8]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 12]         ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 4]              ;! Y
    cmp r9d, r14d                    
    jl AlBC                         ;! if (Dy > a*Dx + b)
AgBC:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_B_AC                  ;!
AlBC:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

check_B_AC:
    finit
    fld DWORD [edges + 32]           ;! a
    fimul DWORD [r10 + 12]          ;! * X
    fadd DWORD [edges + 36]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 32]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 36]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 16]             ;! Y
    cmp r9d, r14d                    
    jl BlAC                         ;! if (Dy > a*Dx + b)
BgAC:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp draw_ABC
BlAC:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

draw_ABC:
    mov DWORD [rdi + rax * 4], 0x009071ff
    mov Dword r14d, [rbp - 64]
    mov DWORD [r15 + 4 * rax], r14d
    jmp next_pixel

check_in_BCD:
check_D_BC:
    finit
    fld DWORD [edges + 8]           ;! a
    fimul DWORD [r10 + 36]          ;! * X
    fadd DWORD [edges + 12]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 8]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 12]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 40]             ;! Y
    cmp r9d, r14d                    
    jl DlBC                         ;! if (Dy > a*Dx + b)
DgBC:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_B_CD                  ;!
DlBC:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel


check_B_CD:
    finit
    fld DWORD [edges + 16]           ;! a
    fimul DWORD [r10 + 12]          ;! * X
    fadd DWORD [edges + 20]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 16]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 20]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 16]             ;! Y
    cmp r9d, r14d                    
    jl BlCD                         ;! if (Dy > a*Dx + b)
BgCD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_C_BD                  ;!
BlCD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

check_C_BD:
    finit
    fld DWORD [edges + 40]           ;! a
    fimul DWORD [r10 + 24]          ;! * X
    fadd DWORD [edges + 44]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 40]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 44]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 28]             ;! Y
    cmp r9d, r14d                    
    jl ClBD                         ;! if (Dy > a*Dx + b)
CgBD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp draw_BCD                  ;!
ClBD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

draw_BCD:
    mov DWORD [rdi + rax * 4], 0x0071aaff
    mov Dword r14d, [rbp - 64]
    mov DWORD [r15 + 4 * rax], r14d
    jmp next_pixel

check_in_CDA:
check_A_CD:
    finit
    fld DWORD [edges + 16]           ;! a
    fimul DWORD [r10 + 0]          ;! * X
    fadd DWORD [edges + 20]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 16]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 20]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 4]             ;! Y
    cmp r9d, r14d                    
    jl AlCD                         ;! if (Dy > a*Dx + b)
AgCD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_C_AD                  ;!
AlCD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

check_C_AD:
    finit
    fld DWORD [edges + 24]           ;! a
    fimul DWORD [r10 + 24]          ;! * X
    fadd DWORD [edges + 28]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 24]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 28]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 28]             ;! Y
    cmp r9d, r14d                    
    jl ClAD                         ;! if (Dy > a*Dx + b)
CgAD:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp check_D_AC                  ;!
ClAD:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

check_D_AC:
    finit
    fld DWORD [edges + 32]           ;! a
    fimul DWORD [r10 + 36]          ;! * X
    fadd DWORD [edges + 36]          ;! + b
    fistp DWORD [rbp - 72]

    fld DWORD [edges + 32]           ;! a
    fimul DWORD [rbp - 48]          ; x
    fadd DWORD [edges + 36]          ;! b
    fistp DWORD [rbp - 80]

    mov r14d, [rbp - 72]
    mov r9d, [r10 + 40]             ;! Y
    cmp r9d, r14d                    
    jl DlAC                         ;! if (Dy > a*Dx + b)
DgAC:
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jl next_pixel
    jmp draw_ACD                  ;!
DlAC:                               ; else
    mov r14d, [rbp - 80]
    mov r9d, [rbp - 56]
    cmp r9d, r14d
    jg next_pixel

draw_ACD:
    mov DWORD [rdi + rax * 4], 0x00ffac71
    mov Dword r14d, [rbp - 64]
    mov DWORD [r15 + 4 * rax], r14d
    jmp next_pixel
draw_black:
    mov DWORD [rdi + rax * 4], 0

next_pixel:

    add r11, 1
    cmp r11, [rbp - 32]            ; x < W
    jl loop_x

    add r13, 1
    cmp r13, [rbp - 40]     ; y < H
    jl loop_y

    add r8, 16
    sub ecx, 1
    cmp ecx, 0          ; if ecx == 0
    jg triangles_drawing_loop

end:
    mov rsp, rbp
    pop rbp
    ret