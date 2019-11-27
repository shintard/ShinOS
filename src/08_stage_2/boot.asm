;---------------------
; - Configration Start to Boot Program Address.
;---------------------
BOOT_LOAD equ 0x7c00    ; load to start boot program address.
ORG       BOOT_LOAD     ; instruction load address to assembler.

;---------------------
; - Declaration Macro.
;---------------------
%include "../include/macro.asm"

entry:
    ;---------------------
    ; - BPB(BIOS Parameter Block).
    ; - First calling to ipl label.
    ; - BIOS Needs Information.
    ; - 0x90 set to 90bytes.
    ; - NOP(do no something).
    ;---------------------
    jmp   ipl
    times 90 - ($ - $$) db 0x90

ipl:
    cli                 ; disable interrupt.

    ;------------------
    ; - Configuration Segment Register.
    ; - Segment is separate memory blocks.
    ; - Initialize Register.
    ;-------------------
    mov ax, 0x0000      ; AX = 0x0000;

    mov ds, ax          ; DS = 0x0000;
    mov es, ax          ; ES = 0x0000;
    mov ss, ax          ; SS = 0x0000;

    ;---------------------
    ; - Stack the boot program start position on the stack pointer.
    ;---------------------
    mov sp, BOOT_LOAD    ; SP = 0x7c00;

    sti                 ; enable interrupt.

    ;---------------------
    ; - Saving Boot Drive.
    ; - dl register is I/O register.
    ;---------------------
    mov [BOOT.DRIVE], dl

    ;--------------------
    ; - Call putc function, argument is '.s0'.
    ; - Call reboot function, nothing argument.
    ;--------------------
    cdecl putc, .s0

    ;--------------------
    ; - Reading Next 512 bytes.
    ; - CHS
    ;--------------------
    mov ah, 0x02                ; 0x02 is reading order.
    mov al, 1                   ; al = Reading sector number.
    mov cx, 0x0002              ; cx = Cylinder / Sector
    mov dh, 0x00                ; dh = Head position.
    mov dl, [BOOT.DRIVE]        ; dl = Drive Number.
    mov bx, 0x7C00 + 512        ; BX = Offset.
    int 0x13                    ; 0x13 is BIOS Call.
.10Q: jnc .10E                  ; (0x13 == 0x02(ah??))
.10T: cdecl putc, .e0           ; start failure.
    call reboot
.10E:                           ; start succeded.
    jmp stage_2

;--------------------
; - 0x0A is LF(Line Feed).
; - 0x0D is CR(Caridge Return).
;--------------------
.s0 db "Booting...", 0x0A, 0x0D, 0
.e0 db "Error sector read.", 0


;--------------------
; - Place every 2 bytes.
;--------------------
ALIGN 2, db 0
BOOT:
.DRIVE:   dw 0            ; drive number.

;--------------------
; - Declaration Module.
;--------------------
%include "../modules/real_mode/putc.asm"
%include "../modules/real_mode/reboot.asm"

;--------------------
; - Boot Flag.
; - Maybe Reserve the first 512 bytes.
; - Write 0x55 and 0xAA to 510bytes.
;--------------------
times 510 - ($ - $$) db 0x00
db    0x55, 0xAA

stage_2:
    ;---------------------
    ;- second stage.
    ;---------------------
    cdecl putc, .s0             ; putc(.s0)

    jmp $

.s0 db "2nd stage...", 0x0A, 0x0D, 0
    ;---------------------
    ; - second stage.
    ; - configuration boot program size.
    ;---------------------
    times(1024 * 8) - ($ - $$) db 0 ; 8K byte