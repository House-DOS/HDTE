; ========================================================================
; House-DOS Text Editor
;
; Written by The House-DOS Developers
; ========================================================================

    BITS 16

; ========================================================================
; Header
; ========================================================================

header:
    jmp main                            ; Don't execute the header

h_creator       dw creator              ; Creator string
h_desc          dw desc                 ; Description string
h_usage         dw usage                ; Usage string


; ========================================================================
; MAIN ROUTINE
; ========================================================================

main:
    mov ah, 0x0F
    mov al, 0x03                            ; Turn off error messages and commentary
    int 0x7E

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

.print:
    push cx                             ; Store line counter

    mov ah, 0x64                        ; Get line
    neg cx                              ; Negate cx
    add cx, 0x17                        ; Add 23 to get line index
    add cx, word [linecounter]          ; Add what line we're on
    mov di, dest_buffer                 ; Copy into buffer
    int 0x7E

    jc .set_cursor                      ; Everything is loaded

    mov ah, 0x10                        ; Print bytes
    mov si, dest_buffer                 ; Print from our buffer
    mov cx, di
    sub cx, si                          ; How many bytes in this line
    int 0x7E

.nextline:
    pop cx                              ; Restore line counter
    loop .print                         ; Go to next line

.set_cursor:
    mov ah, 0x08                        ; Set cursor position
    mov dx, 0x0100                      ; The upper-left corner (avoid the header)
    int 0x7E

    mov ah, 0x62                        ; Get bytes
    mov si, 0x00                        ; Start at the beginning of the file
    mov cx, word [address]              ; Print bytes of how far into the file
    mov di, dest_buffer
    int 0x7E

    mov ah, 0x10                        ; Print bytes
    mov si, dest_buffer                 ; Print from our buffer
    int 0x7E

.edit:
    mov ah, 0x0D                        ; Get cursor position
    int 0x7E

    mov ah, 0x12                        ; Get keypress
    int 0x7E

    ;mov ah, 0xC0                        ; Sleep milliseconds
    ;mov cx, 0x0020                      ; 32
    ;int 0x7E

    jc .edit                            ; Loop if no keypress

    cmp ah, 0x01                        ; Is it an escape?
    je .escape_menu

    cmp ah, 0x4B                        ; Left arrow
    je .left_arrow

    cmp ah, 0x4D                        ; Right arrow
    je .right_arrow

    cmp ah, 0x48                        ; Up arrow
    je .up_arrow

    cmp ah, 0x50                        ; Down arrow
    je .down_arrow

    cmp ah, 0x1C                        ; Is it enter?
    je .newline                         ; If so, newline

    cmp ah, 0x42                        ; F8 to save
    je .save

    cmp al, 0x00                        ; Is there no ASCII code?
    je .edit                            ; If so, loop

    mov byte [char_write], al           ; Otherwise, save the character to write

    mov di, word [address]              ; Get position in di
    mov ah, 0x6B                        ; Insert bytes
    mov cx, 0x01                        ; Write 1 byte
    mov si, char_write                  ; Address of where our character code is
    int 0x7E

    inc word [address]                  ; Move 1 character forward
    inc word [fsize]                    ; Increase file size by 1 character

    jmp .load


    ;cmp
    ; If they press enter, insert a newline
    ; F1: Cut
    ; F2: Copy
    ; F3: Paste
    ; F4: Delete
    ; F8: Save

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
    mov di, word [address]              ; Get our address
    mov ah, 0x6B                        ; Insert bytes
    mov cx, 0x01                        ; Write 1 byte
    mov si, newline_char                ; We want to write a newline
    int 0x7E

    inc word [address]                  ; Move 1 character forward
    inc word [fsize]                    ; Increase file size by 1 character

    jmp .load                           ; Print edited version

.left_arrow:
    cmp word [address], 0x0000          ; Are we at the beginning of the file?
    je .edit                            ; Do nothing

    dec word [address]                  ; Move address back 1
    jmp .set_cursor                     ; Update cursor position

.right_arrow:
    mov ax, word [address]              ; Our position in the file

    cmp ax, word [fsize]                ; Are we at the end of the file?
    jnb .edit                           ; Do nothing

    inc word [address]                  ; Move address forward 1
    jmp .set_cursor                     ; Update cursor position

.up_arrow:
    mov ah, 0x67                        ; Get line and col
    mov si, word [address]              ; Our address in the file
    int 0x7E

    cmp cx, 0x0000                      ; Are we on the first line?
    je .edit                            ; Do nothing

    mov bx, word [address]              ; Our address
    sub bx, dx                          ; Subtract col number to get address of our line
    dec bx                              ; Avoid those O.B.O.Es
    push bx                             ; Save the address of the start of our line

    mov ah, 0x65                        ; Get address of a line
    dec cx                              ; Line above us
    int 0x7E

    mov word [address], si              ; Go to start of line above us
    add word [address], dx              ; Add our column number

    sub bx, si                          ; Subtract to get length of line above us
    inc dx                              ;
    cmp bx, dx                          ; Is the line above us shorter than our col?

    pop bx                              ; Restore address of start of our line
    jae .set_cursor                     ; If not, proceed

    mov word [address], bx              ; Otherwise, set our address to this
    jmp .set_cursor                     ; Proceed

.down_arrow:
    mov ah, 0x67                        ; Get line and col
    mov si, word [fsize]                ; Get the address of the file size
    dec si                              ; Avoid an O.B.O.E
    int 0x7E

    push cx                             ; Preserve the row number

    mov si, word [address]              ; Our address in the file
    int 0x7E

    pop bx                              ; Restore the last row
    cmp cx, bx                          ; Are we on the last row?
    jnb .edit                           ; If so, do nothing

    mov bx, word [address]              ; Our address
    sub bx, dx                          ; Subtract col number to get address of our line
    dec bx                              ; Avoid those O.B.O.Es

    mov ah, 0x65                        ; Get address of a line
    inc cx                              ; Line below us
    int 0x7E

    mov word [address], si              ; Go to start of line below us
    add word [address], dx              ; Add our column number (go straight down)

    push cx                             ; Preserve line number

    mov ah, 0x67                        ; Convert address to line/col numbers
    mov si, word [address]              ; Our current address
    int 0x7E

    pop bx                              ; Restore line below us
    cmp cx, bx                          ; Is our address on the next line?
    je .set_cursor

    mov ah, 0x65                        ; Get address of line
    mov cx, bx                          ; Line number
    inc cx                              ; 2 lines below us
    int 0x7E

    dec si                              ; Go one character back
    mov word [address], si              ; Go to this address
    jmp .set_cursor

.save:
    mov ah, 0x6F                        ; Write file to disk
    mov si, fname                       ; File name
    mov cx, word [fsize]                ; File size
    int 0x7E

    jc .done                            ; Done if there's an error

    ;mov si, save_message                ; The message we print at the bottom after saving
    ;call print_bottom_line              ; Print this to the bottom of the screen

    jmp .load                           ; Return to editing

.done:
    mov ah, 0xFF                        ; End command
    int 0x7E

absolute_position:                      ; What is the address of where we are in the file?
    pusha                               ; Save register states
    mov cx, word [linecounter]          ; Nearest 23 lines

    mov dl, byte [row]                  ; Move row number into dl
    mov dh, 0x00                        ; Fill dh with 0s
    add cx, dx                          ; Get line number

    mov ah, 0x65                        ; Get address of line
    int 0x7E

    add si, word [lineoffset]           ; Add how far into the line we are
    ;mov word [absolute_address], si     ; Store address
    popa                                ; Restore register states
    ;mov di, word [absolute_address]     ; Store in di
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
    mov si, headermsg                   ; Our message
    int 0x7E
    popa                                ; Restore register states
    ret

print_bottom_line:                      ; Si is address of message to print
    pusha                               ; Save register states

    mov dx, 0x1800                      ; Print message on bottom left
    mov ah, 0x08                        ; Set cursor position
    int 0x7E

    mov ah, 0x01                        ; Print
    int 0x7E

    popa                                ; Restore register states
    ret

print_editing_message:
    mov si, editing_message             ; The message we print at the bottom while editing
    call print_bottom_line              ; Print this to the bottom of the screen
    ret

data:

headermsg       db "House-DOS Text Editor", 0x00

fname           dq 0x0000000000000000
                dd 0x00000000
fsize           dw 0x0000
linecounter     dw 0x0000               ; Nearest 23 lines
lineoffset      dw 0x0000
row             dw 0x0000
address         dw 0x0000              ; Address of where we are

newline_char    db 0x0A
char_write      db 0x00

menu_text       db "Commands:", 0x0A, "F1: Cut line", 0x0A, "F2: Copy line", 0x0A, "F3: Paste", 0x0A, "F4: Delete line", 0x0A, "F8: Save", 0x0A
                db "Press ESC to exit, any other key to return...", 0x00
save_message    db "File saved!", 0x00
editing_message db "Editing file", 0x00

creator         db "Ben and Jacob", 0x00
desc            db "A text editor in the House-DOS operating system", 0x00
usage           db "HTEC <FILENAME>", 0x00

dest_buffer: