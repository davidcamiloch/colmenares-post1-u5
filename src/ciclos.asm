; src/ciclos.asm - Programa 3: medir el tiempo real de un bucle de trabajo fijo
; Ensamble: nasm -f bin ciclos.asm -o ..\bin\ciclos.com
; Desviacion de la guia: el bucle externo usa CX = 200 y no 2000. Con 2000 la corrida
; con cycles=1000 tardaria varios minutos; con 200 las tres corridas quedan en segundos.

org 0x100

section .data
    msg_inicio  db "Midiendo bucle de trabajo fijo...", 0Dh, 0Ah, "$"
    msg_t1      db "Hora inicial (hh:mm:ss:cc): $"
    msg_t2      db 0Dh, 0Ah, "Hora final   (hh:mm:ss:cc): $"
    msg_fin     db 0Dh, 0Ah, "Medicion completa. Compare el campo cc (centesimas).", 0Dh, 0Ah, "$"
    sep         db ":$"

    hora1   db 0
    min1    db 0
    seg1    db 0
    cc1     db 0
    hora2   db 0
    min2    db 0
    seg2    db 0
    cc2     db 0

section .text
    mov  ah, 09h
    mov  dx, msg_inicio
    int  21h

    ; Hora inicial (INT 21h funcion 2Ch): CH = horas, CL = minutos, DH = segundos, DL = centesimas
    mov  ah, 2Ch
    int  21h
    mov  [hora1], ch
    mov  [min1], cl
    mov  [seg1], dh
    mov  [cc1], dl

    ; Bucle de trabajo fijo: su duracion real depende del valor cycles de DOSBox
    mov  cx, 200             ; bucle externo
trabajo_ext:
    push cx
    mov  cx, 0FFFFh          ; bucle interno: 65 535 iteraciones
trabajo_int:
    inc  ax                  ; operacion trivial sin efecto util
    loop trabajo_int
    pop  cx
    loop trabajo_ext

    ; Hora final
    mov  ah, 2Ch
    int  21h
    mov  [hora2], ch
    mov  [min2], cl
    mov  [seg2], dh
    mov  [cc2], dl

    mov  ah, 09h
    mov  dx, msg_t1
    int  21h
    mov  si, hora1
    call print_hora

    mov  ah, 09h
    mov  dx, msg_t2
    int  21h
    mov  si, hora2
    call print_hora

    mov  ah, 09h
    mov  dx, msg_fin
    int  21h

    mov  ax, 4C00h
    int  21h

; Subrutina: imprime hh:mm:ss:cc a partir de 4 bytes consecutivos en DS:SI
print_hora:
    mov  cx, 4
.campo:
    lodsb
    call print_dec2
    cmp  cx, 1
    je   .sin_sep
    mov  ah, 09h
    mov  dx, sep
    int  21h
.sin_sep:
    loop .campo
    ret

; Subrutina: imprime AL (0-99) como dos digitos decimales usando AAM
print_dec2:
    aam                       ; AH = AL / 10, AL = AL mod 10
    xchg ah, al               ; AL = decena, AH = unidad
    push ax
    add  al, 30h
    mov  dl, al
    mov  ah, 02h
    int  21h
    pop  ax
    mov  al, ah
    add  al, 30h
    mov  dl, al
    mov  ah, 02h
    int  21h
    ret
