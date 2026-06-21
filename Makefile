all: build clean
build:
	nasm -f bin boot.asm -o boot.bin
	cat boot.bin frames.bin > os.img

qemu:
	qemu-system-x86_64 -drive format=raw,file=os.img

clean:
	rm -f boot.bin
