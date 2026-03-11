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

image : $(DISK_IMAGE) $(OVMF_VARS)

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
    sudo $(MKDIR) -p "$(OS_DIR)/EFI/" "$(OS_DIR)/EFI/BOOT"; \
    sudo cp "$<" "$(OS_DIR)/EFI/BOOT/BOOTX64.EFI";

$(OS_DIR) : $(BUILD_DIR)
	$(MKDIR) -p $(OS_DIR)