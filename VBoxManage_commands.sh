#!/bin/sh
# VBoxManage_commands.sh - Comandos de la Parte 2 del laboratorio colmenares-post1-u5
# VirtualBox 7.2.22 sobre Windows 11. En Windows se ejecutan en PowerShell o CMD desde
# "C:\Program Files\Oracle\VirtualBox" o con esa carpeta en el PATH.
VM="Lab5-Alpine"
ISO="C:/Users/Camilo Colmenares/Downloads/alpine-standard-3.19.9-x86_64.iso"
DIR="C:/Users/Camilo Colmenares/VirtualBox VMs/Lab5-Alpine"

# Paso 1: crear la VM (1 GB de RAM, 1 CPU, NAT, disco dinamico de 10 GB, ISO en IDE)
VBoxManage createvm --name "$VM" --ostype "Linux_64" --register
VBoxManage modifyvm "$VM" --memory 1024 --vram 16 --cpus 1 --nic1 nat
VBoxManage createmedium disk --filename "$DIR/Lab5-Alpine.vdi" --size 10240 --format VDI
VBoxManage storagectl "$VM" --name "SATA" --add sata
VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DIR/Lab5-Alpine.vdi"
VBoxManage storagectl "$VM" --name "IDE" --add ide
VBoxManage storageattach "$VM" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO"
VBoxManage startvm "$VM" --type gui
# Dentro de la VM: login root, setup-alpine (teclado us, hostname lab5-vm, eth0 dhcp,
# zona America/Bogota, chrony, openssh, disco sda en modo sys), luego poweroff.

# Retirar la ISO para arrancar desde el disco
VBoxManage storageattach "$VM" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium emptydrive

# Paso 3: modos de red (con la VM apagada)
VBoxManage controlvm "$VM" poweroff
VBoxManage hostonlyif create
VBoxManage modifyvm "$VM" --nic1 hostonly --hostonlyadapter1 "VirtualBox Host-Only Ethernet Adapter"
VBoxManage modifyvm "$VM" --nic1 bridged --bridgeadapter1 "Ethernet"
VBoxManage modifyvm "$VM" --nic1 nat

# Paso 4: snapshots
VBoxManage snapshot "$VM" take "snap_base" --description "Alpine Linux 3.19 recien instalado, sin modificaciones"
# Dentro de la VM: apk update; apk add curl wget nano htop
VBoxManage snapshot "$VM" take "snap_con_herramientas" --description "Alpine con curl, wget, nano y htop instalados"
VBoxManage snapshot "$VM" list
VBoxManage controlvm "$VM" poweroff
VBoxManage snapshot "$VM" restore "snap_base"
VBoxManage startvm "$VM" --type gui

# Paso 5: reasignar recursos (VM apagada)
VBoxManage controlvm "$VM" poweroff
VBoxManage showvminfo "$VM" | findstr /i "memory cpus"
VBoxManage modifyvm "$VM" --cpus 2 --memory 2048
VBoxManage startvm "$VM" --type gui
# Dentro de la VM: nproc; free -m

# Paso 6: segundo disco de 4 GB con asignacion fija
VBoxManage controlvm "$VM" poweroff
VBoxManage createmedium disk --filename "$DIR/Lab5-Alpine-fixed.vdi" --size 4096 --format VDI --variant Fixed
VBoxManage storageattach "$VM" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "$DIR/Lab5-Alpine-fixed.vdi"
VBoxManage startvm "$VM" --type gui
# Dentro de la VM: apk add e2fsprogs; fdisk /dev/sdb; mkfs.ext4 /dev/sdb1; mount /dev/sdb1 /mnt/fijo
# time dd if=/dev/zero of=/mnt/fijo/test.img bs=1M count=200; sync
# time dd if=/dev/zero of=/root/test.img bs=1M count=200; sync

# Paso 9: exportar en formato OVA
VBoxManage controlvm "$VM" poweroff
VBoxManage export "$VM" --output "Lab5-Alpine-export.ova" --manifest
