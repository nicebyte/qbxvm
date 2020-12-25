include '../qbx_assembler.asm'

qj u, start ; jump to entrypoint

; constants and variables
SCR_W_CHARS     equ 80
CHAR_SIZE_BYTES equ 4
SCR_W_BYTES     equ SCR_W_CHARS*CHAR_SIZE_BYTES
msg             db  "MARQUEE!!!"
MSG_LEN         =   $ - msg
                db (80 - MSG_LEN) dup '-'
CHAR_ATTRS      equ 0x001e

start:  ; execution starts here
        qxor w, q2, q2
step_msg:
        qmov w, q3, screen_content
        fill_line_loop:
                ; loop must be terminated if we've reached the end of 1st line.
                qmov w, q0, SCR_W_BYTES
                qmov w, q1, screen_content
                qadd w, q0, q1
                qsub w, q0, q3
                qj   z, loop_end
                ; get the index of char within the line into q1.
                qmov w, q1, q3
                qmov w, q0, screen_content
                qsub w, q1, q0
                qmov w, q0, 2
                qshr w, q1, q0
                ; add position in line to position of msg start
                qadd w, q1, q2
                ; get modulo 80
                qpush w, q2
                qmov  w, q2, SCR_W_CHARS
                qmov  w, q0, q1
                qxor  w, q1, q1
                qsdiv w, q2
                qpop  w, q2
                qmov  w, q0, q1
                qmov  w, q1, msg
                qadd  w, q0, q1    ; compute address of byte in the message.
                qxor  w, q1, q1
                qload b, [q0], q1  ; load char code from message into q1.
                qmov  w, q0, q3
                qstor w, [q0], q1  ; store char code into screen memory.
                qmov  w, q0, CHAR_SIZE_BYTES/2
                qadd  w, q3, q0  ; compute address of attrs.
                qmov  w, q0, q3
                qmov  w, q1, CHAR_ATTRS
                qstor w, [q0], q1 ; set attrs.
        ; advance loop counter
                qmov w, q0, CHAR_SIZE_BYTES/2
                qadd w, q3, q0
                qj   u, fill_line_loop
        loop_end:
; trigger dpy refresh
qmov b, q1, 80
qmov w, q0, 8
qshl w, q1, q0
qmov b, q1, 1
qpush w, q2
qmov w, q2, 0
qmov w, q0, screen_content
qyld 0x01
qpop w, q2
; animation delay
qmov w, q0, 100
qyld 0x02
; advance msg forward
qmov w, q0, 1
qadd w, q2, q0
qj u, step_msg

screen_content:
