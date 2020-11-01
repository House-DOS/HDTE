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

    mov dh, 0x01                        ; Cursor on second row

.load:
    call draw_header                    ; Print header
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

    jc .set_cursor                      ; Everything is loaded

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

.set_cursor:
    call set_cursor_our_variables

.edit:
    mov ah, 0x0D                        ; Get cursor position
    int 0x7E

    mov ah, 0x12                        ; Get keypress
    int 0x7E

    mov ah, 0xC0                        ; Sleep milliseconds
    mov cx, 0x0020                      ; 32
    int 0x7E

    jc .edit                            ; Loop if no keypress

    cmp ah, 0x01                        ; Is it an escape?
    je .escape_menu

    cmp ah, 0x4B                        ; Left arrow
    je .left_arrow

    cmp ah, 0x4D                        ; Right arrow
    je .right_arrow

    cmp ah, 0x1C                        ; Is it enter?
    je .newline                         ; If so, newline

    cmp al, 0x00                        ; Is there no ASCII code?
    je .edit                            ; If so, loop

    ;cmp
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

.escape_menu:
    call draw_header                    ; Print header
    mov ah, 0x02                        ; Print line
    mov si, menu_text                   ; Escape menu text
    int 0x7E

.escape_loop:
    mov ah, 0x12                        ; Get keypress
    int 0x7E

    jc .escape_loop                     ; Loop if no keypress

    cmp ah, 0x01                        ; Is it escape again?
    je .done                            ; If so, quit

    jmp .load                           ; Print file again, then resume editing

.newline:
    call absolute_position              ; Get position
    mov ah, 0x6B                        ; Insert bytes
    mov cx, 0x01                        ; Write 1 byte
    mov si, newline_char                ; We want to write a newline
    int 0x7E

    mov word [lineoffset], 0x0000       ; Far left column
    mov ah, 0x0D                        ; Get cursor position
    int 0x7E

    inc dh                              ; Move cursor down one row

    jmp .load                           ; Print edited version

.left_arrow:
    cmp byte [lineoffset], 0x00         ; Are we at the beginning of a line?
    je .edit                            ; Do nothing

    dec byte [lineoffset]               ; Move one to the left
    jmp .set_cursor                     ; Update cursor position

.right_arrow:
    call absolute_position              ; Get our absolute position
    mov si, di                          ; Move into si
    mov cx, 0x0001                      ; Copy 1 byte
    mov ah, 0x62                        ; Get bytes
    mov di, dest_buffer                 ; Copy into here
    int 0x7E

    cmp byte [dest_buffer], 0x0A        ; Are we on a newline?
    je .edit                            ; Do nothing

    inc byte [lineoffset]               ; Move one to the right
    jmp .set_cursor                     ; Update cursor position

.done:
    mov ah, 0xFF                        ; End command
    int 0x7E

set_cursor_our_variables:
    mov ax, word [lineoffset]           ; Set column
    mov dl, 0x50                        ; Set up to divide by 80
    div dl                              ; Divide ax by this

    mov dl, ah                          ; Remainder is cursor column
    mov dh, byte [row]                  ; Setting cursor row
    inc dh                              ; Start at 2nd row
    mov ah, 0x08                        ; Setting cursor position
    int 0x7E
    ret

absolute_position:                      ; What is the address of where we are in the file?
    pusha                               ; Save register states
    mov cx, word [linecounter]          ; Nearest 23 lines

    mov dl, byte [row]                  ; Move row number into dl
    mov dh, 0x00                        ; Fill dh with 0s
    add cx, dx                          ; Get line number

    mov ah, 0x65                        ; Get address of line
    int 0x7E

    add si, word [lineoffset]           ; Add how far into the line we are
    mov word [absolute_address], si     ; Store address
    popa                                ; Restore register states
    mov di, word [absolute_address]     ; Store in di
    ret

draw_header:
    pusha                               ; Save register states
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
    popa                                ; Restore register states
    ret

data:

header          db "House-DOS Text Editor", 0x00

fname           dq 0x0000000000000000
                dd 0x00000000
fsize           dw 0x0000
linecounter     dw 0x0000               ; Nearest 23 lines
row             db 0x00
lineoffset      dw 0x0000               ; How far into the line are we
absolute_address dw 0x0000              ; Address of where we are

newline_char    db 0x0A

menu_text       db "Commands:", 0x0A, "F1: Cut line", 0x0A, "F2: Copy line", 0x0A, "F3: Paste", 0x0A, "F4: Delete line", 0x0A, 0x0A
                db "Press ESC to exit, any other key to return...", 0x00

dest_buffer: