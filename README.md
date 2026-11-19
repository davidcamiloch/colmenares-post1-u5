# colmenares-post1-u5

Laboratorio del Post-contenido de la Unidad 5 (Emuladores y Virtualización) de Arquitectura de Computadores, UFPS. Autor: David Camilo Colmenares Hernández.

La Parte 1 usa DOSBox, un emulador que recrea por software un PC x86 de 16 bits con DOS, para ensamblar y ejecutar tres programas NASM y medir el efecto del parámetro `cycles`. La Parte 2 usa VirtualBox, un virtualizador que ejecuta un sistema operativo completo sobre el hardware real, para crear y administrar la máquina virtual Lab5-Alpine.

## Entorno

| Elemento | Versión o valor |
|----------|-----------------|
| Anfitrión | Windows 11 x64 |
| DOSBox | 0.74-3 |
| NASM | 3.02 para DOS, con CWSDPMI como servidor DPMI |
| DEBUG | 2.51 (clon libre de DEBUG.COM, proyecto DOS-debug), porque DOSBox 0.74 no incluye DEBUG |
| VirtualBox | 7.2.22 |
| Huésped | Alpine Linux 3.19.9 standard x86_64; 1 GB de RAM; disco VDI dinámico de 10 GB |

## Estructura

```
colmenares-post1-u5/
├── README.md
├── dosbox.conf               configuración del laboratorio (cycles=8000)
├── src/                      saludo.asm, entrada.asm, ciclos.asm
├── bin/                      saludo.com, entrada.com, ciclos.com
├── VBoxManage_commands.sh    comandos de la Parte 2
└── capturas/                 evidencia de ambas partes
```

