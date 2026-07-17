bits 16
org 0x7C00

section .text

_start:
    xor  ax, ax
    mov  ds, ax      ; data segment
    mov  es, ax      ; extra segment
    mov  ss, ax      ; stack segment
    mov  sp, 0x7C00  ; stack pointer grows down from 0x7C00

    ; save boot drive number passed by BIOS in DL
    mov  [boot_drive], dl

    ; boot banner thru teletype
    lea  si, [msg_boot]
    call print_string

    ; load kernel
    mov  ah, 0x02    ; read sectors
    mov  al, 0x01    ; number of contiguous sectors to read
    mov  ch, 0x00    ; cylinder number (low 8 bits)
    mov  cl, 0x02
    mov  dh, 0x00    ; head number
    mov  dl, [boot_drive] ; drive number (0x00=floppy, 0x80=hard disk)
    mov  bx, 0x7E00  ; ES:BX = 0x0000:0x7E00 (right after)
    int  0x13

    jc   disk_error  ; carry set => BIOS reported an error

    db   0xEA        ; far jump: opcode EA followed by offset:segment
    dw   0x7E00
    dw   0x0000

disk_error:
    lea  si, [msg_error]
    call print_string

    cli              ; disable interrupts
.halt:
    hlt
    jmp  .halt       ; in case of nmi / wake, halt again

; si = addr, clobbers ax, si
print_string:
    mov  ah, 0x0e    ; teletype output function
.lods:
    lodsb            ; al = ds:[si]; si++
    or   al, al      ; null terminator?
    jz   .done
    int  0x10        ; bios video interrupt, print char in al
    jmp  .lods
.done:
    ret

msg_boot:
    db   "iAPX86 bootloader", 13, 10
    db   "loading kernel from disk...", 13, 10, 0

msg_error:
    db   "disk read failed!", 13, 10
    db   "system halted.", 13, 10, 0

boot_drive:
    db   0

    times 510 - ($ - _start) db 0 
    dw   0xAA55 ; boot signature
