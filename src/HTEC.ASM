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

.load:
    mov ah, 0x06                        ; Clear screen
    int 0x7E

    mov ah, 0x11                        ; Draw block
    mov al, 0x20                        ; Spaces
    mov bl, 0b10010000                  ; Blinking, blue background, black foreground
    mov cx, 0x0050                      ; The length of one row
    mov dx, 0x0000                      ; Uppermost row, leftmost col
    int 0x7E

    mov ah, 0x02                        ; Print line
    mov si, header                      ; Our message
    int 0x7E

    mov cx, 0x17                        ; Get and print 23 lines
    mov di, dest_buffer                 ; Copy into buffer

.print:
    push cx                             ; Store line counter
    push di                             ; Store buffer pointer

    mov ah, 0x64                        ; Get line
    neg cx                              ; Negate cx
    add cx, 0x17                        ; Add 23 to get line index
    add cx, word [linecounter]          ; Add what line we're on
    int 0x7E

    jc .edit                            ; Everything is loaded

    pop cx                              ; Get what buffer pointer was
    push cx                             ; Re-push the buffer pointer
    sub cx, di                          ; Find how much it advanced
    neg cx                              ; Get positive difference
    cmp cx, 0x50                        ; Is it more than 80 characters?
    jg .print80                         ; Only print 80 characters

    mov ah, 0x10                        ; Print bytes
    pop si                              ; Print from the beginning of the line
    int 0x7E

.nextline:
    pop cx                              ; Restore line counter
    loop .print                         ; Go to next line

.print80:
    mov ah, 0x10                        ; Print bytes
    mov cx, 0x50                        ; Print 80 characters
    pop si                              ; Print from the beginning of the line
    int 0x7E

    jmp .nextline                       ; Go to next line

.edit:
    mov ah, 0x0D                        ; Get cursor position
    int 0x7E

    mov ah, 0x12                        ; Get keypress
    int 0x7E

    mov ah, 0xC0                        ; Sleep milliseconds
    mov cx, 0x0020                      ; 32
    int 0x7E

    jc .edit                            ; Loop if no keypress

    ;cmp ah, 0x01                        ; Is it an escape?
    ;je .escape_menu

    ; cmp
    ; If they press enter, insert a newline
    ; F1: Cut
    ; F2: Copy
    ; F3: Paste
    ; F4: Delete

    ; Display cursor
    ; Check keyboard input
    ; If arrow keys, move cursor
    ; If normal keys, add to file where cursor is
    ; If backspace/delete, remove from file
    ; If enter, insert new line
    ; If escape character, display special options/prompts
    ; If quit character, leave

.done:
    mov ah, 0xFF                            ; End command
    int 0x7E

data:

header          db "House-DOS Text Editor", 0x00

fname           dq 0x0000000000000000
                dd 0x00000000
fsize           dw 0x0000
linecounter     dw 0x0000

dest_buffer: