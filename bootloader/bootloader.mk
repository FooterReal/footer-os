LD_FLAGS := -shared -Bsymbolic -L$(EFI_LIB) -L$(EFI_GNUEFI) -T$(EFI_CRT_LDS)
OBJCOPY_FLAGS := -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc -O pei-x86-64 --subsystem=10

$(BOOTLOADER_BUILD_DIR)/BOOTX64.EFI : $(BOOTLOADER_BUILD_DIR)/bootx64.so
	$(OBJCPY) $(OBJCOPY_FLAGS) $< $@

$(BOOTLOADER_BUILD_DIR)/bootx64.so : $(BOOTLOADER_BUILD_DIR)/boot.o
	$(LD) $(LD_FLAGS) $(EFI_CRT_O) $< -o $@ -lgnuefi -lefi

$(BOOTLOADER_BUILD_DIR)/boot.o : $(BOOTLOADER_SRC)/boot.asm $(BOOTLOADER_BUILD_DIR)
	$(ASM) -f elf64 $< -o $@

$(BOOTLOADER_BUILD_DIR) : $(BUILD_DIR)
	$(MKDIR) -p $(BOOTLOADER_BUILD_DIR)

$(BUILD_DIR) : 
	$(MKDIR) -p $(BUILD_DIR)