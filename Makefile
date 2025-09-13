# === Config ===
TARGET = i686-elf
BUILD_DIR = build
SRC_DIR = src
ISO_DIR = $(BUILD_DIR)/isodir
ISO = $(BUILD_DIR)/myos.iso
KERNEL = myos.bin

AS = $(TARGET)-as
CC = $(TARGET)-gcc
LD = $(CC)
OBJCOPY = $(TARGET)-objcopy

CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS = -T $(SRC_DIR)/linker.ld -nostdlib -ffreestanding

# === Files ===
BOOT_OBJ = $(BUILD_DIR)/boot.o
KERNEL_OBJ = $(BUILD_DIR)/kernel.o
KERNEL_BIN = $(BUILD_DIR)/$(KERNEL)
GRUB_CFG = $(SRC_DIR)/grub.cfg

# === Default Target ===
all: $(ISO)

# === Assemble boot.s ===
$(BOOT_OBJ): $(SRC_DIR)/boot.s | $(BUILD_DIR)
	$(AS) $< -o $@

# === Compile kernel.c ===
$(KERNEL_OBJ): $(SRC_DIR)/kernel.c | $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

# === Link kernel ===
$(KERNEL_BIN): $(BOOT_OBJ) $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

# === Check multiboot compliance ===
check: $(KERNEL_BIN)
	grub-file --is-x86-multiboot $^

# === Build ISO directory structure ===
$(ISO): $(KERNEL_BIN) $(GRUB_CFG)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_BIN) $(ISO_DIR)/boot/$(KERNEL)
	cp $(GRUB_CFG) $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $@ $(ISO_DIR)

# === Run with QEMU (text mode) ===
run: $(ISO)
	qemu-system-i386 \
		-nographic -serial mon:stdio -display curses \
		-cdrom $<

# === Create build dir ===
$(BUILD_DIR):
	mkdir -p $@

# === Clean ===
clean:
	rm -rf $(BUILD_DIR) $(ISO)

.PHONY: all clean run check
