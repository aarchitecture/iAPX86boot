NASM      = nasm
NASMFLAGS = -f bin

.PHONY: all clean run hexdump disk

all: boot.bin

boot.bin: boot.S
	$(NASM) $(NASMFLAGS) -o $@ $<
	@test `wc -c < $@` -eq 512 || (echo "$@ is not 512 bytes!" && false)

disk.img: boot.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=$< of=$@ bs=512 count=1 conv=notrunc 2>/dev/null

disk: disk.img

run: disk.img
	qemu-system-i386 -drive format=raw,file=disk.img,if=floppy -nographic

hexdump: boot.bin
	@xxd boot.bin

clean:
	rm -f boot.bin disk.img
