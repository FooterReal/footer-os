# Common Makefile variables and rules
BUILD_DIR := build

BOOTLOADER_SRC := bootloader
BOOTLOADER_BUILD_DIR := $(BUILD_DIR)/bootloader

clean :
	rm -rf $(BUILD_DIR)