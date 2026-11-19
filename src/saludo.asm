; src/saludo.asm - Programa 1: salida de texto en DOS con INT 21h, funcion 09h
; Ensamble: nasm -f bin saludo.asm -o ..\bin\saludo.com

org 0x100          ; formato .COM: el codigo inicia en CS:0100h

section .data
    nombre  db  "Laboratorio 5 - DOSBox y Ensamblador", 0Dh, 0Ah
            db  "Estudiante: Colmenares", 0Dh, 0Ah
            db  "Unidad 5 - Arquitectura de Computadores", 0Dh, 0Ah, "$"

section .text
    ; Mostrar el mensaje con la funcion 09h de INT 21h
    mov  ah, 09h       ; funcion: imprimir cadena terminada en "$"
    mov  dx, nombre    ; DX = direccion de inicio de la cadena
    int  21h           ; llamada al sistema operativo DOS

    ; Terminar el programa correctamente
    mov  ax, 4C00h     ; funcion 4Ch: terminar; AL = 00h codigo de salida
    int  21h
