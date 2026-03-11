# GNU-EFI related
GNU-EFI := $(CURDIR)/libs/gnu-efi
EFI_LIB := $(GNU-EFI)/x86_64/lib
EFI_GNUEFI := $(GNU-EFI)/x86_64/gnuefi
EFI_CRT_LDS := $(GNU-EFI)/gnuefi/elf_x86_64_efi.lds
EFI_CRT_O := $(GNU-EFI)/x86_64/gnuefi/crt0-efi-x86_64.o

# OVMF
OVMF := $(CURDIR)/libs/ovmf
OVMF_CODE := $(OVMF)/OVMF_CODE.fd
OVMF_VARS_SRC := $(OVMF)/OVMF_VARS.fd
OVMF_VARS := $(BUILD_DIR)/OVMF_VARS.fd

$(OVMF_VARS) : $(BUILD_DIR)
	cp $(OVMF_VARS_SRC) $(OVMF_VARS)