.DEFAULT_GOAL := run
include mk/tools.mk
include mk/common.mk

include libs/libs.mk

include bootloader/bootloader.mk
include mk/image.mk
include mk/qemu.mk
.PHONY: image run clean