# GEMU related
QEMU_FLAGS := -machine q35 -enable-kvm -m 512 -smp 2 \
		      -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
			  -drive if=pflash,format=raw,file=$(OVMF_VARS) \
			  -drive if=none,id=disk0,format=raw,file=${DISK_IMAGE} \
			  -device virtio-blk-pci,drive=disk0,bootindex=0\
			  -global isa-debugcon.iobase=0x402 -debugcon file:footeros.ovmf.log \
			  -monitor stdio -netdev id=net0,type=user -device virtio-net-pci,netdev=net0,romfile= \
			  -device qxl-vga

run : image
	$(QEMU) $(QEMU_FLAGS)