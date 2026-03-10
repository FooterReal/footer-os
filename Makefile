# Tools
ASM := nasm
LD := ld
QEMU := qemu-system-x86_64
DD := dd
FD := fdisk
LS := losetup
VFAT := mkfs.vfat

# EFI related
EFI_LIB := /usr/lib
LD_EFI_LDS := $(EFI_LIB)/elf_x86_64_efi.lds
LD_EFI_CRT := $(EFI_LIB)/crt0-efi-x86_64.o

# Build configuration
BUILD_DIR := build
LD_FLAGS := -nostdlib -znocombreloc -T $(LD_EFI_LDS) -shared -Bsymbolic
OBJCOPY_FLAGS := -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc -O pei-x86-64 --subsystem=10

# Bootloader
BOOTLOADER_SRC := bootloader
BOOTLOADER_BUILD_DIR := $(BUILD_DIR)/bootloader

# Adding files
OS_DIR = $(BUILD_DIR)/os

# File system creation
OFFSET=2048
FS_SIZE=64
LOOP_DEVICE = /dev/loop_fos

# Disk creation 
DISK_IMAGE := $(BUILD_DIR)/disk_image
MB_SIZE := 1048576
DISK_SIZE := 128
FDISK_COMMANDS="g\nn p\n1\n$(OFFSET)\n+$(FS_SIZE)M\nt 1\n1\nw"

image : $(OS_DIR)/EFI/BOOT/BOOTX64.EFI

run : $(DISK_IMAGE)
	$(QEMU) -hda $(DISK_IMAGE)

clean :
	rm -rf $(BUILD_DIR)

$(OS_DIR)/EFI/BOOT/BOOTX64.EFI : $(BOOTLOADER_BUILD_DIR)/BOOTX64.EFI $(DISK_IMAGE) $(OS_DIR)
	@set -e; \
    loop_dev="$$( sudo $(LS) -o $$(($(OFFSET)*512)) --sizelimit $$(($(FS_SIZE)*1024*1024)) -f $(DISK_IMAGE) --show )"; \
    cleanup() { \
        sudo umount "$(OS_DIR)" 2>/dev/null || true; \
        sudo $(LS) -d "$$loop_dev" 2>/dev/null || true; \
    }; \
    trap cleanup EXIT INT TERM; \
    sudo $(VFAT) -F 32 -n "EFI System" "$$loop_dev"; \
    sudo mount "$$loop_dev" "$(OS_DIR)"; \
    sudo mkdir "$(OS_DIR)/EFI/" "$(OS_DIR)/EFI/BOOT"; \
    sudo cp "$<" "$@"

$(DISK_IMAGE) : $(BUILD_DIR)
	$(DD) if=/dev/zero of=$(DISK_IMAGE) bs=$(MB_SIZE) count=$(DISK_SIZE)
	printf $(FDISK_COMMANDS) | $(FD) $(DISK_IMAGE)

$(BOOTLOADER_BUILD_DIR)/BOOTX64.EFI : $(BOOTLOADER_BUILD_DIR)/bootx64.so
	objcopy $(OBJCOPY_FLAGS) $< $@

$(BOOTLOADER_BUILD_DIR)/bootx64.so : $(BOOTLOADER_BUILD_DIR)/boot.o
	$(LD) $(LD_FLAGS) $(LD_EFI_CRT) $< -L $(EFI_LIB) -lefi -lgnuefi -o $@

$(BOOTLOADER_BUILD_DIR)/boot.o : $(BOOTLOADER_SRC)/boot.asm $(BOOTLOADER_BUILD_DIR)
	$(ASM) -f elf64 $< -o $@

$(OS_DIR) :
	mkdir $(OS_DIR)

$(BOOTLOADER_BUILD_DIR) : $(BUILD_DIR)
	mkdir $(BOOTLOADER_BUILD_DIR)

$(BUILD_DIR) : 
	mkdir $(BUILD_DIR)