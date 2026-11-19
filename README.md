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
| Huésped | Alpine Linux 3.19.9 standard x86_64 (hostname lab5-vm); 1 GB de RAM y 1 CPU al crearla, 2 GB y 2 CPU tras la reasignación; disco VDI dinámico de 10 GB y disco VDI fijo de 4 GB |
| Equipo anfitrión | Intel Core i5-12450H; adaptador Wi-Fi Intel AX201 para el modo puente |

## Estructura

```
colmenares-post1-u5/
├── README.md
├── dosbox.conf               configuración del laboratorio (cycles=8000)
├── dosbox_1000.conf          misma configuración con cycles=1000
├── dosbox_20000.conf         misma configuración con cycles=20000
├── COMPILA.BAT               ensamblado de los tres programas
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
| Inicio (`-r`) | ninguna | FFFF | 0000 | 0100 |
| `-t` | `MOV AH,09` | 09FF | 0000 | 0102 |
| `-t` | `MOV DX,010C` | 09FF | 010C | 0105 |
| `-p` | `INT 21` | 09FF | 010C | 0107 |

Al cargar el programa DEBUG deja AX = FFFF y CX = 0074h, que es el tamaño del archivo: 116 bytes. El primer `-t` solo cambia el byte alto de AX; el segundo carga en DX el desplazamiento de la cadena. Ninguna instrucción MOV modifica las banderas. La interrupción se ejecuta con `-p` para que DEBUG la recorra completa sin entrar en el código de DOS; las tres líneas aparecen y AX sigue en 09FF. El DOS interno de DOSBox no escribe AL en la función 09h, a diferencia de MS-DOS real, que devuelve AL = 24h.

### Comparación de cycles

| Corrida | cycles | Hora inicial | Hora final | Duración |
|---------|--------|--------------|------------|----------|
| 1 | 8000 | 05:54:04.08 | 05:54:07.32 | 3.24 s |
| 2 | 1000 | 05:54:30.83 | 05:54:57.08 | 26.25 s |
| 3 | 20000 | 05:55:24.60 | 05:55:25.92 | 1.32 s |

El bucle ejecuta 200 × 65 535 = 13 107 000 iteraciones de dos instrucciones (INC y LOOP). La estimación teórica es de 26 214 000 instrucciones divididas entre cycles × 1 000 por segundo.

```
26 214 000 / 8 000 000 = 3.28 s      medido 3.24 s
26 214 000 / 1 000 000 = 26.21 s     medido 26.25 s
26 214 000 / 20 000 000 = 1.31 s     medido 1.32 s
```

Las tres mediciones caen a menos de 0.05 s de la estimación. La duración es inversamente proporcional a cycles: pasar de 8000 a 1000 multiplica el tiempo por 8.1 y pasar a 20000 lo divide entre 2.45. El programa y su resultado no cambian; solo cambia la velocidad a la que DOSBox emula las instrucciones.

### Desviaciones respecto a la guía (Parte 1)

| Punto de la guía | Lo observado | Tratamiento |
|------------------|--------------|-------------|
| Textos de `saludo.asm` con guion largo | DOS imprime cada byte con la página de códigos 437; el guion largo en UTF-8 ocupa tres bytes y sale como símbolos extraños | Se usa guion simple |
| `ciclos.asm` con 2 000 vueltas externas | 2 000 × 65 535 = 131 070 000 iteraciones; con `cycles=1000` la corrida tardaría varios minutos | 200 vueltas (13 107 000 iteraciones); la guía autoriza ajustar el valor |
| Dieciséis bloques para imprimir la hora | Código repetido para cada dígito | Subrutina `print_hora` con LODSB; el formato de salida es el mismo |
| DEBUG disponible en DOSBox | DOSBox 0.74-3 no incluye DEBUG.COM | DEBUG 2.51 del proyecto DOS-debug |
| Reiniciar DOSBox para cada valor de cycles | Tres sesiones distintas con la carpeta montada como D: | `config -set cpu cycles=N` aplica el mismo parámetro sin reiniciar; la barra de título de cada captura muestra el valor activo |
| Ensamblar desde la raíz | DOSBox no tiene la raíz del laboratorio en el PATH | `COMPILA.BAT` llama a `..\nasm` desde `src` |
| `git status` en la captura de estructura | El repositorio se creó y se alimentó con GitHub web | La captura del checkpoint 1 muestra el árbol de archivos del repositorio en GitHub |

### Decisión técnica 1: qué valor de cycles usar

El valor correcto para este laboratorio es un número fijo, `cycles=8000`. `ciclos.com` es un bucle de espera por trabajo: su duración real depende solo de cuántas instrucciones emula DOSBox por milisegundo. Con `cycles=max` DOSBox emula tan rápido como lo permite el procesador anfitrión; en un equipo moderno el bucle de 13 107 000 iteraciones termina en una fracción de segundo y las centésimas leídas con la función 2Ch casi no cambian. La medición deja de reflejar la velocidad emulada de referencia y pasa a medir el procesador de cada estudiante, que es justo lo que el programa no debe medir. `cycles=auto` tampoco sirve para comparar porque usa un valor por defecto en modo real y salta a `max` cuando un programa entra en modo protegido, así que la velocidad depende del programa y del anfitrión. Un valor fijo produce el mismo número de instrucciones emuladas por unidad de tiempo virtual en cualquier anfitrión capaz de sostenerlo; dos estudiantes con equipos distintos obtienen duraciones comparables y la tabla de la guía tiene sentido. `cycles=max` o `cycles=auto` sí son la elección correcta fuera del laboratorio, por ejemplo al ejecutar un compilador, un editor o un juego de 32 bits en modo protegido que no depende del reloj del procesador para temporizar y solo se beneficia de terminar antes. La regla es fijar cycles cuando se mide y liberarlo cuando solo importa la rapidez.

### Decisión técnica 2: cycles frente a ciclos de reloj reales

Comparar `cycles=8000` con los varios GHz del procesador anfitrión es un error de categoría. El valor de DOSBox cuenta instrucciones x86 de 16 bits emuladas por milisegundo de tiempo virtual; la frecuencia del procesador cuenta ciclos de reloj físicos por segundo de tiempo real. Con 8000 el bucle de `ciclos.com` duró 3.24 s de tiempo virtual, muy cerca de los 13 107 000 × 2 ÷ 8 000 000 ≈ 3.28 s previstos, mientras que el mismo bucle nativo en el anfitrión tomaría milisegundos. Las dos cifras no se pueden dividir entre sí porque cada instrucción emulada exige que DOSBox la decodifique y la ejecute por software con un número variable de instrucciones nativas: un INC es barato de interpretar y una interrupción de DOS es costosa. Por eso el proceso DOSBox.exe consume muchos más ciclos reales de los que sugiere el valor configurado, y ese consumo crece con cycles hasta que el anfitrión ya no puede sostenerlo. Las centésimas que lee la función 2Ch vienen del reloj emulado y no del contador del procesador. Para estimar los ciclos reales que gasta la ejecución de `ciclos.com` hay que medir en el anfitrión: el Administrador de tareas o el Monitor de rendimiento de Windows muestran el uso de CPU del proceso DOSBox.exe, y un perfilador como Windows Performance Recorder o Intel VTune cuenta ciclos y tiempo de CPU por proceso. La regla es medir el emulador desde afuera y el programa emulado desde adentro.

### Capturas de la Parte 1

| Checkpoint | Captura | Contenido |
|------------|---------|-----------|
| 1. Estructura | `capturas/p1_cp1_estructura.png` | Árbol del repositorio con src/, bin/, capturas/, configuraciones y README |
| 2. DOSBox con NASM | `capturas/p1_cp2_dosbox_nasm.png` | Prompt C:\ y salida de `nasm -v` |
| 3. saludo.com | `capturas/p1_cp3_compilacion.png` y `p1_cp3_saludo.png` | Ensamblado sin errores y las tres líneas impresas |
| 4. entrada.com | `capturas/p1_cp4_entrada.png` | Prompt, carácter leído y su código ASCII en hexadecimal |
| 5. DEBUG | `capturas/p1_cp5_debug.png` | `-u 100 10b` y los pasos `-t`, `-t` y `-p` con AX y DX |
| 6. ciclos.com con 8000 | `capturas/p1_cp6_ciclos_8000.png` | Hora inicial y final con cycles=8000 |
| 7. Comparación de cycles | `capturas/p1_cp7_ciclos_1000.png` y `p1_cp7_ciclos_20000.png` | Corridas con cycles=1000 y cycles=20000 |
| 8. Decisiones técnicas | Secciones Decisión técnica 1 y 2 de este README | Valor de cycles y cycles frente a ciclos reales |

## Parte 2: VirtualBox y Alpine Linux

La VM Lab5-Alpine se creó con 1 024 MB de RAM; 1 CPU; un disco VDI dinámico de 10 GB en el controlador SATA; la ISO de Alpine 3.19.9 en el controlador IDE y la NIC 1 en NAT. Alpine se instaló en modo sys sobre /dev/sda con hostname lab5-vm, eth0 por DHCP, zona America/Bogota y OpenSSH. La ISO se retiró de la unidad óptica antes del primer arranque desde disco. Los comandos VBoxManage equivalentes a cada paso están en `VBoxManage_commands.sh`.

### Modos de red

| Modo | IP de eth0 | ping 8.8.8.8 desde la VM | Observación |
|------|------------|--------------------------|-------------|
| NAT | 10.0.2.15/24 | 3 de 3 respuestas; 17.3 ms de promedio | La puerta de enlace es 10.0.2.2, el enrutador interno de VirtualBox |
| Host-Only | 192.168.56.101/24 | `Network unreachable` | La red 192.168.56.0/24 solo existe entre la VM y el anfitrión |
| Bridge (Wi-Fi Intel AX201) | 192.168.1.17/24 | 2 de 2 respuestas; 18.5 ms de promedio | La VM recibe una IP del router de la red física |

El cambio de modo se hizo en caliente desde Dispositivos > Red, seguido de `ifdown eth0; ifup eth0` dentro de Alpine para pedir una dirección nueva por DHCP.

### Árbol de snapshots

```
snap_base                 19/11/2026 5:07 p. m.   Alpine 3.19 recién instalado
└── snap_con_herramientas 19/11/2026 5:09 p. m.   Alpine con curl, wget, nano y htop
```

Con `snap_con_herramientas` activo `apk info` listaba curl y htop. Después de apagar la VM y restaurar `snap_base`, `apk info -e curl` no devolvió nada y `curl --version` respondió `curl: not found`. El software instalado desapareció sin desinstalarlo a mano.

### Reasignación de recursos

Con la VM apagada se cambió la memoria base de 1 024 a 2 048 MB y el número de CPU de 1 a 2. Al arrancar, `nproc` devolvió 2 y `free -m` mostró un total de 1 976 MB. Los 72 MB que faltan corresponden a la memoria que el núcleo reserva para sí y para el firmware antes de contarla como disponible.

### Disco fijo frente a dinámico

Se creó `Lab5-Alpine-fixed.vdi` de 4 GB con la opción Reservar completamente y se conectó al puerto SATA 1. Dentro de Alpine se particionó con `parted`, se formateó en ext4 y se montó en /mnt/fijo.

| Tipo de disco | Archivo en el anfitrión | Comando | Tiempo real | Velocidad |
|---------------|-------------------------|---------|-------------|-----------|
| Fijo | Lab5-Alpine-fixed.vdi: 4,00 GB virtuales y 4,00 GB ocupados | `time dd if=/dev/zero of=/mnt/fijo/test.img bs=1M count=200 conv=fsync` | 0.67 s | 297.1 MB/s |
| Dinámico | Lab5-Alpine.vdi: 10,00 GB virtuales y 239 MB ocupados antes de la prueba | `time dd if=/dev/zero of=/root/test.img bs=1M count=200 conv=fsync` | 0.75 s | 265.1 MB/s |

El disco fijo escribió los 200 MB un 11 % más rápido.

```
0.75 s / 0.67 s = 1.12
297.1 MB/s / 265.1 MB/s = 1.12
```

### Exportación OVA

Archivo > Exportar servicio virtualizado generó `Lab5-Alpine-export.ova` en formato OVF 1.0 con manifiesto. El archivo pesa 144 MB porque el OVA guarda los discos comprimidos y los bloques en cero ocupan casi nada. El .ova y `Lab5-Alpine-fixed.vdi` no se suben al repositorio por su tamaño.

### Desviaciones respecto a la guía (Parte 2)

| Punto de la guía | Lo observado | Tratamiento |
|------------------|--------------|-------------|
| ISO alpine-standard 3.19.0 | La rama 3.19 ya publica la revisión 3.19.9 | Se usó 3.19.9 con el mismo instalador |
| `setup-alpine` completo | El paso NTP quedó detenido en `Starting chronyd` más de 4 minutos | Se interrumpió con Ctrl+C y se completaron los pasos restantes con `setup-apkrepos -1`, `setup-sshd -c openssh` y `ERASE_DISKS=/dev/sda setup-disk -m sys /dev/sda`; chronyd se retiró del arranque con `rc-update del chronyd default` |
| Teclear en la consola de la VM | La consola recibía mal la distribución de teclado latinoamericana del anfitrión | Se dejó el teclado del huésped en el valor por defecto (US) y se escribió con el teclado software de VirtualBox |
| Comandos VBoxManage en la terminal | La configuración se aplicó desde la interfaz gráfica de VirtualBox, que ejecuta las mismas operaciones de la API | Equivalencias en `VBoxManage_commands.sh`; las capturas muestran el panel de detalles, el árbol de instantáneas y el asistente de exportación |
| Inicio de sesión en cada arranque | La parte exige cuatro reinicios (snapshots, recursos, disco y exportación) | Tras el primer inicio con la contraseña de root se configuró inicio automático en tty1 (`/bin/login -f root` en /etc/inittab) |
| Host-Only: ping del anfitrión a la VM | El ping de la VM al anfitrión 192.168.56.1 no tuvo respuesta | El Firewall de Windows descarta por defecto el eco ICMP entrante; la IP 192.168.56.101 y el `Network unreachable` hacia 8.8.8.8 confirman el aislamiento |
| `fdisk /dev/sdb` interactivo | Las respuestas de fdisk deben teclearse una por una | `parted -s /dev/sdb mklabel msdos mkpart primary ext4 1MiB 100%` |
| `dd` seguido de `sync` | `time` medía solo la copia a la caché de páginas | `conv=fsync` obliga a escribir en el disco antes de que `dd` termine, así el tiempo incluye la escritura real |
| Interfaz `vboxnet0` | En Windows la interfaz se llama VirtualBox Host-Only Ethernet Adapter | Se eligió por nombre en la configuración de red |

### Decisión técnica 3: modo de red para una VM de laboratorio personal

NAT es el modo por defecto adecuado para Lab5-Alpine. En NAT VirtualBox actúa como un enrutador privado entre la VM y la red del anfitrión: la VM recibió 10.0.2.15 en una red que solo existe dentro del proceso de VirtualBox y salió a internet con la dirección del anfitrión, con 17.3 ms de promedio hacia 8.8.8.8. Las conexiones solo pueden nacer en la VM; ningún equipo de la red local ve la IP 10.0.2.15 ni puede abrir una conexión hacia ella salvo que se configure un reenvío de puertos explícito. Host-Only conviene cuando el ejercicio exige que ningún tráfico salga del equipo: la VM recibió 192.168.56.101 y el ping a 8.8.8.8 falló con `Network unreachable`. Sirve para probar reglas de firewall o un servicio vulnerable a propósito entre la VM y el anfitrión, pero la instalación de paquetes exige volver a NAT. Bridge es la opción de mayor riesgo. La VM tomó 192.168.1.17 del router de la red Wi-Fi, igual que cualquier portátil o teléfono conectado, y quedó alcanzable por todos ellos. Alpine arranca `sshd` en el puerto 22 porque `setup-sshd` lo instaló; en una red universitaria o doméstica compartida cualquier dispositivo puede intentar forzar la contraseña de root o explotar un servicio desactualizado. Bridge solo se justifica cuando otro equipo debe alcanzar la VM. La regla es salir por NAT, aislar con Host-Only y puentear solo cuando un tercero debe entrar.

### Decisión técnica 4: disco fijo frente a dinámico y asignación de CPU y RAM

El disco fijo fue el más rápido en la medición: escribió 200 MB con `conv=fsync` en 0.67 s (297.1 MB/s) frente a 0.75 s (265.1 MB/s) del disco dinámico, un 12 % más de tiempo para el dinámico. La diferencia nace del costo de crecimiento del archivo .vdi. Un VDI dinámico empieza casi vacío; Lab5-Alpine.vdi ocupaba 239 MB para 10 GB virtuales. Cada bloque que el huésped escribe por primera vez obliga a VirtualBox a ampliar el archivo en el anfitrión y a actualizar su tabla de asignación de bloques antes de completar la escritura. El VDI fijo reservó sus 4 GB al crearse, así que cada escritura cae en un espacio que ya existe. El precio del fijo es el espacio: ocupa 4 GB aunque el huésped solo use 200 MB. Para un laboratorio que se exporta y se copia conviene el dinámico; para una base de datos o un servidor de compilación que escribe sin parar conviene el fijo. En recursos el anfitrión tiene un Core i5-12450H de 8 núcleos y 12 hilos. Asignar 2 CPU y 2 048 MB deja la mayor parte del equipo para Windows y el navegador; Alpine arrancó con 75 MB usados de 1 976 disponibles, así que 2 GB sobran para el laboratorio. Asignar todos los núcleos haría que la VM compitiera con el anfitrión y empeorara a ambos. La regla es reservar espacio cuando importa la escritura sostenida y dar a la VM solo lo que su carga demuestra necesitar.

### Capturas de la Parte 2

| Checkpoint | Captura | Contenido |
|------------|---------|-----------|
| 1. VM creada | `capturas/p2_cp1_vm_config.png` | 1 024 MB, ISO 3.19.9 en IDE, disco de 10 GB en SATA y NIC en NAT |
| 2. Alpine instalado | `capturas/p2_cp2_ip_ping.png` | `ip addr show eth0` con 10.0.2.15 y `ping -c 3 8.8.8.8` con 0 % de pérdida |
| 3. Modos de red | `capturas/p2_cp3_hostonly_ip.png` y `p2_cp3_bridge_ip.png` | IP 192.168.56.101 en Host-Only y 192.168.1.17 en Bridge |
| 4. Snapshots | `capturas/p2_cp4_snapshots.png` y `p2_cp4_restaurado.png` | Árbol con las dos instantáneas y `curl: not found` tras restaurar snap_base |
| 5. Recursos | `capturas/p2_cp5_config_recursos.png` y `p2_cp5_nproc_free.png` | 2 048 MB y 2 CPU en la configuración; `nproc` = 2 y 1 976 MB en `free -m` |
| 6. Disco | `capturas/p2_cp6_dd_fijo.png`, `p2_cp6_dd_dinamico.png` y `p2_cp6_tamanos_vdi.png` | Tiempos de `dd` en cada disco y tamaño virtual frente a ocupado de cada VDI |
| 7. Decisiones técnicas | Secciones Decisión técnica 3 y 4 de este README | Modo de red y tipo de disco con CPU y RAM |
| 8. Exportación | `capturas/p2_cp8_export_config.png` y `p2_cp8_ova_tamano.png` | Asistente con formato OVF 1.0 y manifiesto; Lab5-Alpine-export.ova de 144 MB |

## Conclusiones

La diferencia entre emulación y virtualización quedó medida en el mismo equipo. DOSBox interpreta cada instrucción x86 de 16 bits por software y su velocidad la fija el parámetro cycles: el mismo bucle tardó 26.25 s con 1000 y 1.32 s con 20000, y la duración siguió la estimación teórica con menos de 0.05 s de error. VirtualBox no traduce instrucciones de un procesador a otro; ejecuta el código del huésped directamente sobre el procesador anfitrión con la ayuda de VT-x y solo intercepta lo que toca hardware compartido. Por eso Alpine arrancó en segundos, escribió a más de 260 MB/s y respondió a la red real en menos de 20 ms. Los modos de red mostraron que el aislamiento es una decisión de configuración y no una propiedad fija de la VM: la misma tarjeta pasó por tres redes distintas sin reinstalar nada. Los snapshots convirtieron la instalación de paquetes en un cambio reversible en segundos. La reasignación de CPU y RAM y la prueba de disco confirmaron que la VM solo ve los recursos que el anfitrión le cede y que el formato del disco virtual tiene un costo medible.

## Referencias

- DOSBox Team. (s.f.). *Dosbox.conf*. DOSBox Wiki. Recuperado el 19 de noviembre de 2026 de https://www.dosbox.com/wiki/Dosbox.conf
- NASM Development Team. (s.f.). *NASM — The Netwide Assembler: documentación*. https://www.nasm.us/doc/
- Oracle. (s.f.). *Chapter 6. Virtual Networking*. Oracle VirtualBox User Manual. Recuperado el 19 de noviembre de 2026 de https://www.virtualbox.org/manual/ch06.html
- Rey Castillo, J. R. (s.f.). *Emuladores y virtualización: guía de contenido de la Unidad 5*. Universidad Francisco de Paula Santander.
