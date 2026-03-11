; boot.asm - A simple placeholder for testing the bootloader setup
bits 64
default rel

section .rodata
hello_msg:
dw 'H','e','l','l','o',',',' ','W','o','r','l','d','!',13,10,0

section .text
global efi_main:function

extern InitializeLib
extern Print

; UEFI x64 entry args:
; rdi = ImageHandle
; rsi = SystemTable pointer?
efi_main:
    sub rsp, 8 ; Align stack for external C calls

    ; InitializeLib(ImageHandle, SystemTable)
    call InitializeLib

    ; Print("Hello, World!\n")
    lea rdi, [hello_msg] ; lead string pointer
    xor rax, rax
    call Print

    ; return EFI_SUCCESS
    xor rax, rax ; Clear rax, EFI_SUCCESS = 0
    add rsp, 8; Restore stack
    ret