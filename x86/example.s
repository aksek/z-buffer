section .text

global f
f:
    push rbp
    mov rbp, rsp

    ; rdi       , rsi       , rdx        , rcx       , r8       , r9
    ; pBuffer   , W         , H          , X         , Y        , dummy0,  period
    ;           , [rbp - 32], [rbp - 24] , [rbp - 16], [rbp - 8],       , [rbp + 16]

    sub rsp, 40             ; alloc 5 stack variables

    mov [rbp - 8], r8       ; Y
    mov [rbp - 16], rcx     ; X
    mov [rbp - 24], rdx     ; H
    mov [rbp - 32], rsi     ; W

    mov r10, 0              ; y (row iterator)
loop_y:
    mov r11, 0              ; x (column iterator)

    mov [rbp - 40], r10
    fild QWORD [rbp - 40]   ; load y
    fild QWORD [rbp - 8]    ; load Y
    fsub                    ; y - Y
    fld st0
    fmul                    ; (y - Y)^2

loop_x:
    mov rax, r10            ; y
    mul QWORD [rbp - 32]    ; y * W (destroys RDX)
    add rax, r11            ; y * W + x

    fld st0
    mov [rbp - 40], r11
    fild QWORD [rbp - 40]   ; load x
    fild QWORD [rbp - 16]   ; load X
    fsub                    ; x - X
    fld st0
    fmul                    ; (x - X)^2
    fadd                    ; dx^2 + dy^2
    fsqrt                   ; dist
    mov QWORD [rbp - 40], 2
    fild QWORD [rbp - 40]
    fmul                    ; 2 * dist
    fldpi
    fmul                    ; 2 * PI * dist
    fild QWORD [rbp + 16]
    fdiv                    ; 2 * PI * dist / period
    fsin
    fld1
    fadd                    ; sin + 1
    mov QWORD [rbp - 40], 127
    fild QWORD [rbp - 40]
    fmul
    fistp QWORD [rbp - 40]

    mov dl, [rbp - 40]
    mov [rdi + rax * 4 + 1], dl

    add r11, 1
    cmp r11, rsi            ; x < W
    jl loop_x

    fstp st0

    add r10, 1
    cmp r10, [rbp - 24]     ; y < H
    jl loop_y
end:
    mov rsp, rbp
    pop rbp
    ret
    
    