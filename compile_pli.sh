#!/bin/bash
FILENAME=$(echo "$1" | tr '[:lower:]' '[:upper:]')
cd /home/buga
/root/pli-1.4.0a/plic -C -dELF -lsiaxgo -ew -cn\(^\) -i/root/pli-1.4.0a/lib/include /home/buga/${FILENAME}.PL1 -o /home/buga/${FILENAME}.o
ld -z muldefs -Bstatic -M -o /home/buga/${FILENAME} --oformat=elf32-i386 -melf_i386 -e main /home/buga/${FILENAME}.o --start-group /root/pli-1.4.0a/lib/libprf.a --end-group

echo 
echo "=== EXECUTANDO PROGRAMA ==="
echo
./${FILENAME}