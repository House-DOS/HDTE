; ========================================================================
; House-DOS Text Editor
;
; Written by The House-DOS Developers
; ========================================================================

    BITS 16

; ========================================================================
; MAIN ROUTINE
; ========================================================================

main:
    mov ah, 0x20                            ; Get parameters
    mov cx, 0x0000                          ; First parameter
    mov di, fname                           ; Move memory address
    int 0x7E

    jnc .verify                             ; Successful, so go on

    mov ah, 0x6E                            ; Clear file buffer
    int 0x7E

    jmp .edit                               ; We are editing file

.verify:
    mov ah, 0x60                            ; Verify file
    mov si, fname                           ; Filename goes here
    int 0x7E

    jc .done                                ; is there an error?

    mov ah, 0x61                            ; Load file
    int 0x7E

    jc .done

    mov ah, 0x70                            ; Get size of file
    int 0x7E

    mov word [fsize], ax                    ; Store size here

.edit:


.done:
    mov ah, 0xFF                            ; End command
    int 0x7E

data:

fname           dq 0x0000000000000000
                dd 0x00000000
fsize           dw 0x0000