# Tools
ASM := nasm
LD := ld
QEMU := qemu-system-x86_64
DD := dd
FD := fdisk
LS := losetup
VFAT := mkfs.vfat

# EFI related
GNU-EFI := $(CURDIR)/libs/gnu-efi
EFI_LIB := $(GNU-EFI)/x86_64/lib
EFI_GNUEFI := $(GNU-EFI)/x86_64/gnuefi
EFI_CRT_LDS := $(GNU-EFI)/gnuefi/elf_x86_64_efi.lds
EFI_CRT_O := $(GNU-EFI)/x86_64/gnuefi/crt0-efi-x86_64.o

# Build configuration
BUILD_DIR := build
LD_FLAGS := -shared -Bsymbolic -L$(EFI_LIB) -L$(EFI_GNUEFI) -T$(EFI_CRT_LDS)
OBJCOPY_FLAGS := -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc -O pei-x86-64 --subsystem=10

# OVMF
OVMF := $(CURDIR)/libs/ovmf
OVMF_CODE := $(OVMF)/OVMF_CODE.fd
OVMF_VARS_SRC := $(OVMF)/OVMF_VARS.fd
OVMF_VARS := $(BUILD_DIR)/OVMF_VARS.fd

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

# GEMU related
QEMU_FLAGS := -machine q35 -enable-kvm -m 512 -smp 2 \
		      -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
			  -drive if=pflash,format=raw,file=$(OVMF_VARS) \
			  -drive if=none,id=disk0,format=raw,file=${DISK_IMAGE} \
			  -device virtio-blk-pci,drive=disk0,bootindex=0\
			  -global isa-debugcon.iobase=0x402 -debugcon file:footeros.ovmf.log \
			  -monitor stdio -netdev id=net0,type=user -device virtio-net-pci,netdev=net0,romfile= \
			  -device qxl-vga

.PHONY: image run clean

image : $(DISK_IMAGE) $(OVMF_VARS)

run : image
	$(QEMU) $(QEMU_FLAGS)

clean :
	rm -rf $(BUILD_DIR)

$(OVMF_VARS) :
	cp $(OVMF_VARS_SRC) $(OVMF_VARS)

$(DISK_IMAGE) : $(BOOTLOADER_BUILD_DIR)/BOOTX64.EFI $(BUILD_DIR) $(OS_DIR)
	$(DD) if=/dev/zero of=$(DISK_IMAGE) bs=$(MB_SIZE) count=$(DISK_SIZE)
	printf $(FDISK_COMMANDS) | $(FD) $(DISK_IMAGE)
	@set -e; \
    loop_dev="$$( sudo $(LS) -o $$(($(OFFSET)*512)) --sizelimit $$(($(FS_SIZE)*1024*1024)) -f $(DISK_IMAGE) --show )"; \
    cleanup() { \
        sudo umount "$(OS_DIR)" 2>/dev/null || true; \
        sudo $(LS) -d "$$loop_dev" 2>/dev/null || true; \
		rm -rf "$(OS_DIR)"; \
    }; \
    trap cleanup EXIT INT TERM; \
    sudo $(VFAT) -F 32 -n "EFI System" "$$loop_dev"; \
    sudo mount "$$loop_dev" "$(OS_DIR)"; \
    sudo mkdir -p "$(OS_DIR)/EFI/" "$(OS_DIR)/EFI/BOOT"; \
    sudo cp "$<" "$(OS_DIR)/EFI/BOOT/BOOTX64.EFI";

$(BOOTLOADER_BUILD_DIR)/BOOTX64.EFI : $(BOOTLOADER_BUILD_DIR)/bootx64.so
	objcopy $(OBJCOPY_FLAGS) $< $@

$(BOOTLOADER_BUILD_DIR)/bootx64.so : $(BOOTLOADER_BUILD_DIR)/boot.o
	$(LD) $(LD_FLAGS) $(EFI_CRT_O) $< -o $@ -lgnuefi -lefi

$(BOOTLOADER_BUILD_DIR)/boot.o : $(BOOTLOADER_SRC)/boot.asm $(BOOTLOADER_BUILD_DIR)
	$(ASM) -f elf64 $< -o $@

$(OS_DIR) :
	mkdir -p $(OS_DIR)

$(BOOTLOADER_BUILD_DIR) : $(BUILD_DIR)
	mkdir -p $(BOOTLOADER_BUILD_DIR)

$(BUILD_DIR) : 
	mkdir -p $(BUILD_DIR)