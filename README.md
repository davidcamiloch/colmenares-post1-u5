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

## Parte 1: DOSBox y ensamblador

`dosbox.conf` fija `core=normal`, `cycles=8000`, `memsize=16` y el escalado `normal2x`. Su sección `[autoexec]` monta la carpeta del laboratorio como C:, cambia a esa unidad y carga CWSDPMI, que NASM 3.02 necesita como servidor DPMI. DOSBox se inicia con `dosbox.exe -conf dosbox.conf`.

```
C:\> cd src
C:\SRC> nasm -f bin saludo.asm -o ..\bin\saludo.com
C:\SRC> nasm -f bin entrada.asm -o ..\bin\entrada.com
C:\SRC> nasm -f bin ciclos.asm -o ..\bin\ciclos.com
C:\SRC> cd ..
C:\> bin\saludo
```

| Programa | Servicios DOS | Resultado |
|----------|---------------|-----------|
| `saludo.asm` | INT 21h/09h y 4Ch | Imprime tres líneas con el nombre del laboratorio y del estudiante |
| `entrada.asm` | INT 21h/07h, 02h y 09h | Lee una tecla sin eco y muestra el carácter y su código ASCII en hexadecimal |
| `ciclos.asm` | INT 21h/2Ch | Lee la hora antes y después de un bucle fijo e imprime ambas marcas hh:mm:ss:cc |

### Sesión de DEBUG con saludo.com

```
C:\> debug bin\saludo.com
-r
-u 100 10b
-t
-t
-p
-q
```

NASM coloca la sección `.text` al inicio del binario plano y la sección `.data` después, alineada a 4 bytes. Por eso el código ocupa 0100h a 010Bh y la cadena empieza en 010Ch. El desensamblado esperado con `-u 100 10b` es el siguiente.

```
0100 B409      MOV  AH,09
0102 BA0C01    MOV  DX,010C
0105 CD21      INT  21
0107 B8004C    MOV  AX,4C00
010A CD21      INT  21
```

| Paso | Instrucción ejecutada | AX | DX | IP siguiente |
|------|-----------------------|----|----|--------------|
| Inicio (`-r`) | ninguna | 0000 | 0000 | 0100 |
| `-t` | `MOV AH,09` | 0900 | 0000 | 0102 |
| `-t` | `MOV DX,010C` | 0900 | 010C | 0105 |
| `-p` | `INT 21` | 0924 | 010C | 0107 |

El primer `-t` solo cambia el byte alto de AX; el segundo carga en DX el desplazamiento de la cadena. Ninguna instrucción MOV modifica las banderas. La interrupción se ejecuta con `-p` para que DEBUG la recorra completa sin entrar en el código de DOS; DOSBox devuelve AL = 24h, el código del carácter `$`, igual que MS-DOS.

### Desviaciones respecto a la guía

- Los textos de `saludo.asm` usan guion simple en lugar del guion largo de la guía. DOS imprime cada byte como un carácter de la página de códigos 437 y el guion largo en UTF-8 ocupa tres bytes que aparecen como símbolos extraños.
- `ciclos.asm` usa 200 vueltas externas en lugar de 2 000. Con 2 000 vueltas el bucle ejecuta 2 000 × 65 535 = 131 070 000 iteraciones y la corrida con `cycles=1000` tardaría varios minutos. Con 200 vueltas son 13 107 000 iteraciones y las tres corridas quedan en segundos sin cambiar la lógica del programa. La guía autoriza ajustar ese valor según el equipo.
- `ciclos.asm` imprime las dos marcas de tiempo con una subrutina `print_hora` que recorre los cuatro bytes con LODSB en lugar de repetir dieciséis bloques de código. El formato de salida es el mismo.
- DEBUG.COM se toma del proyecto DOS-debug 2.51 porque la imagen de DOSBox 0.74 no lo trae.

### Decisión técnica 1: qué valor de cycles usar

El valor correcto para este laboratorio es un número fijo, `cycles=8000`. `ciclos.com` es un bucle de espera por trabajo: su duración real depende solo de cuántas instrucciones emula DOSBox por milisegundo. Con `cycles=max` DOSBox emula tan rápido como lo permite el procesador anfitrión; en un equipo moderno el bucle de 13 107 000 iteraciones termina en una fracción de segundo y las centésimas leídas con la función 2Ch casi no cambian. La medición deja de reflejar la velocidad emulada de referencia y pasa a medir el procesador de cada estudiante, que es justo lo que el programa no debe medir. `cycles=auto` es peor para comparar porque ajusta el valor de forma dinámica según la carga y puede variar entre dos corridas del mismo programa. Un valor fijo produce el mismo número de instrucciones emuladas por unidad de tiempo virtual en cualquier anfitrión capaz de sostenerlo; dos estudiantes con equipos distintos obtienen duraciones comparables y la tabla de la guía tiene sentido. `cycles=max` o `cycles=auto` sí son la elección correcta fuera del laboratorio, por ejemplo al ejecutar un compilador, un editor o un juego de 32 bits en modo protegido que no depende del reloj del procesador para temporizar y solo se beneficia de terminar antes. La regla es fijar cycles cuando se mide y liberarlo cuando solo importa la rapidez.

### Decisión técnica 2: cycles frente a ciclos de reloj reales

Comparar `cycles=8000` con los varios GHz del procesador anfitrión es un error de categoría. El valor de DOSBox cuenta instrucciones x86 de 16 bits emuladas por milisegundo de tiempo virtual; la frecuencia del procesador cuenta ciclos de reloj físicos por segundo de tiempo real. Con 8000 el bucle de `ciclos.com` debería durar del orden de 13 107 000 × 2 ÷ 8 000 000 ≈ 3.3 s de tiempo virtual, mientras que el mismo bucle nativo en el anfitrión tomaría milisegundos. Las dos cifras no se pueden dividir entre sí porque cada instrucción emulada exige que DOSBox la decodifique y la ejecute por software con un número variable de instrucciones nativas: un INC es barato de interpretar y una interrupción de DOS es costosa. Por eso el proceso DOSBox.exe consume muchos más ciclos reales de los que sugiere el valor configurado, y ese consumo crece con cycles hasta que el anfitrión ya no puede sostenerlo. Las centésimas que lee la función 2Ch vienen del reloj emulado y no del contador del procesador. Para estimar los ciclos reales que gasta la ejecución de `ciclos.com` hay que medir en el anfitrión: el Administrador de tareas o el Monitor de rendimiento de Windows muestran el uso de CPU del proceso DOSBox.exe, y un perfilador como Windows Performance Recorder o Intel VTune cuenta ciclos y tiempo de CPU por proceso. La regla es medir el emulador desde afuera y el programa emulado desde adentro.

