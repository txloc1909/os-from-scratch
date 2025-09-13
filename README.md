# Operating System from scratch

[Tutorial](https://wiki.osdev.org/Bare_Bones)

## Development system & toolchain
- OS: Debian 12 bookworm
- System compiler: gcc 12.2.0
- binutils: 2.40

## Build cross-compiling toolchain

```
# install dependency
bison flex m4
libgmp-dev libmpfr-dev libmpc-dev
texinfo

```

```
export PREFIX=/path/to/os-from-scratch/opt/cross
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

cd toolchains
mkdir build-binutils && cd build-binutils
../binutils-gdb/configure \
    --target=$TARGET \
    --prefix=$PREFIX \
    --with-sysroot \
    --disable-nls \
    --disable-werror 
make && make install

cd .. && mkdir build-gdb && cd build-gdb
../binutils-gdb/configure --target=$TARGET --prefix="$PREFIX" --disable-werror
make all-gdb && make install-gdb

cd .. && mkdir build-gcc && cd build-gcc 
../gcc/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
make all-gcc
make all-target-libgcc
make all-target-libstdc++-v3
make install-gcc
make install-target-libgcc
make install-target-libstdc++-v3
```

## Build kernel & OS & image

Dependencies:
```
xorriso mtools grub-pc-bin
libncurses5 libncursesw5
```

Build bootstrap asm
```
$TARGET-as boot.s -o boot.o
```

Build and link the kernel 
```
$TARGET-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
$TARGET-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o

# Verify multiboot
grub-file --is-x86-multiboot myos.bin
```

Build image 
```
mkdir -p isodir/boot/grub 
cp myos.bin isodir/boot/myos.bin 
cp grub.cfg isodir/boot/grub/grub.cfg
grub-mkrescue -o myos.iso isodir
```

Boot with QEMU, in text-based VGA mode in terminal
```
qemu-system-i386 \
    -nographic -serial mon:stdio -display curses \
    -cdrom myos.iso
```
