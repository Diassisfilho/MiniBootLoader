#
# Makefile for the x86 Bootloader Project
# Designed for a MinGW/MSYS2 or Git Bash environment on Windows
#
# Assumes you have:
# 1. 'nasm' in your PATH
# 2. 'make' (from your environment)
# 3. 'dd' (comes with Git Bash/MSYS2)
# 4. An 'i686-elf' cross-compiler toolchain in your PATH
#

# --- Toolchain ---
# We specify the .exe for Windows compatibility, though 'make' often handles it.
AS      = nasm
CC      = i686-elf-gcc
LD      = i686-elf-ld
OBJCOPY = i686-elf-objcopy

# --- C Compiler Flags ---
# -ffreestanding: Don't assume a standard library
# -nostdlib: Don't link standard C library
# -m32: Ensure 32-bit output
# -O2: Optimize
CFLAGS = -ffreestanding -std=gnu99 -m32 -nostdlib -O2 -Wall -Wextra

# --- Linker Flags ---
# -T linker.ld: Use our custom linker script
LDFLAGS = -T linker.ld

# --- Files ---
BOOT_BINS = boot.bin stage2.bin math_sin.bin math_add.bin c_loader.bin
KERNEL_OBJS = kernel_asm.o kernel.o
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
FLOPPY_IMG = floppy.img
LOGO_IMG = logo.img

# --- Build Rules ---

# Default target: build the final floppy image
all: $(FLOPPY_IMG)

# Rule to build the floppy image
$(FLOPPY_IMG): $(BOOT_BINS) $(KERNEL_BIN)
	@echo "--- Building Floppy Image ---"
	dd if=/dev/zero of=$(FLOPPY_IMG) bs=512 count=2880
	dd if=boot.bin of=$(FLOPPY_IMG) conv=notrunc
	dd if=stage2.bin of=$(FLOPPY_IMG) seek=1 conv=notrunc
	dd if=$(LOGO_IMG) of=$(FLOPPY_IMG) seek=4 conv=notrunc
	dd if=math_sin.bin of=$(FLOPPY_IMG) seek=12 conv=notrunc
	dd if=math_add.bin of=$(FLOPPY_IMG) seek=13 conv=notrunc
	dd if=c_loader.bin of=$(FLOPPY_IMG) seek=14 conv=notrunc
	dd if=$(KERNEL_BIN) of=$(FLOPPY_IMG) seek=15 conv=notrunc
	@echo "--- Done! ---"
	@echo "Run with: qemu-system-i386 -fda $(FLOPPY_IMG)"

# --- 16-bit ASM Binaries ---
boot.bin: boot.asm
	$(AS) -f bin boot.asm -o boot.bin

math_sin.bin: math_sin.asm
	$(AS) -f bin math_sin.asm -o math_sin.bin

math_add.bin: math_add.asm
	$(AS) -f bin math_add.asm -o math_add.bin

c_loader.bin: c_loader.asm
	$(AS) -f bin c_loader.asm -o c_loader.bin

stage2.bin: stage2.asm font.asm
	$(AS) -f bin stage2.asm -o stage2.bin

# --- 32-bit Kernel ---
# Convert kernel from ELF to flat binary
$(KERNEL_BIN): $(KERNEL_ELF)
	@echo "--- Converting Kernel to Binary ---"
	$(OBJCOPY) -O binary $(KERNEL_ELF) $(KERNEL_BIN)

# Link the C and ASM kernel objects
$(KERNEL_ELF): $(KERNEL_OBJS) linker.ld
	@echo "--- Linking Kernel ---"
	$(CC) -o $(KERNEL_ELF) $(KERNEL_OBJS) $(LDFLAGS) $(CFLAGS) -lgcc

# Compile C kernel code
kernel.o: kernel.c
	@echo "--- Compiling C Kernel ---"
	$(CC) -c kernel.c -o kernel.o $(CFLAGS)

# Assemble 32-bit ASM kernel code
kernel_asm.o: kernel_asm.asm
	@echo "--- Assembling 32-bit ASM ---"
	$(AS) -f elf32 kernel_asm.asm -o kernel_asm.o

# --- Clean Rule ---
# Removes all built files
clean:
	@echo "--- Cleaning up build files ---"
	rm -f $(FLOPPY_IMG) $(BOOT_BINS) $(KERNEL_OBJS) $(KERNEL_ELF) $(KERNEL_BIN)

.PHONY: all clean