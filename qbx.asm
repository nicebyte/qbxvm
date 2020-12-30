format PE64 NX GUI 6.0

;QBX_BUILD_MODE_DEBUG = 1

entry start

include 'win64_helpers.asm'
include 'qbx_insn_list.asm'
include 'qbx_insn_helpers.asm'
include 'qbx_registers.asm'

; define constants for all QBX instruction codes.
qbx_insns define_icodes, 0

; screen dimension constants.
SCR_CHAR_WIDTH  equ 80
SCR_CHAR_HEIGHT equ 25

; this data section contains import tables and some
; other global data structures that qbx uses.
section '.data' import readable writeable executable
        import_directory_table KERNEL32, USER32, SHELL32
        import_functions KERNEL32, \
                         AllocConsole, \
                         CreateConsoleScreenBuffer, \
                         SetConsoleActiveScreenBuffer, \
                         SetConsoleTitleA, \
                         SetConsoleScreenBufferSize, \
                         SetConsoleCursorInfo, \
                         WriteConsoleOutputA, \
                         ExitProcess, \
                         CreateFileW, \
                         CreateFileA, \
                         ReadFile, \
                         WriteFile, \
                         CloseHandle, \
                         GetCommandLineW, \
                         GetLastError, \
                         Sleep, \
                         GetFileSize
        import_functions USER32, MessageBoxA
        import_functions SHELL32, CommandLineToArgvW
        ; string constants.
        err_msg_title   db "Error", 0
        file_err_msg    db "Failed to open the input file.", 0
        size_err_msg    db "Image too big to fit in QBX memory.", 0
        noinput_err_msg db "Input file name not specified.", 0
        dump_err_msg    db "Failed to open dump file for writing.",0
        dump_file_name  db "qbx.dump", 0
        window_title    db "QBX Bytecode Xecutor", 0
        ; the jump table that maps insn codes to insn implementations.
        qbx_insns define_jmp_table, qbx_jmp_table
        ; some variables.
        screen_rect SMALL_RECT ; defines target rect for screen updates.
        con_bbuf    dq ?       ; console back buffer handle.
        con_fbuf    dq ?       ; console front buffer handle.
        num_args    dw ?       ; stores the number of command line arguments.
        args_ptr    dq ?       ; pointer to the command line argument string.
        tmp_space   dq ?       ; temporary space for miscellaneous small data.

; this section contains the memory seen by programs executed by qbx.
; splitting it into a separate section reduces the final executable size.
section '.mem' data readable writeable
        QBX_MEM_SIZE = 1024 * 16  ; 16 K
        qbx_mem db QBX_MEM_SIZE dup ?


; all executable code lives in this section.
section '.code' code readable executable
        start:  ; entry point - program starts here.
                ; parse the command line to extract the input file name.
                call64 [GetCommandLineW]
                call64 [CommandLineToArgvW], rax, num_args
                mov [args_ptr], rax
                cmp [num_args], 2
                jge open_input
                ; if an input file name is not provided, display an error message and exit.
                call64 [MessageBoxA], 0, noinput_err_msg, err_msg_title, MB_ICONERROR
                call64 [ExitProcess], 1
        open_input:
                ; attempt to open the image file.
                call64 [CreateFileW], [rax + 8], GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0
                cmp rax, INVALID_HANDLE
                jne check_size
                ; if the image could not be opened, display error message and exit.
                call64 [MessageBoxA], 0, file_err_msg, err_msg_title, MB_ICONERROR
                call64 [ExitProcess], 1
        check_size:
                ; check that the input file is small enough to fit into qbx memory.
                mov r12, rax
                call64 [GetFileSize], r12, tmp_space
                cmp [tmp_space], 0
                jnz file_size_error
                cmp rax, QBX_MEM_SIZE
                jl read_input
        file_size_error:
                ; exit if requested image is too large.
                call64 [MessageBoxA], 0, size_err_msg, err_msg_title, MB_ICONERROR
                call64 [ExitProcess], 1
        read_input:
                ; read the contents of the image into the qbx memory region.
                call64 [ReadFile], r12, qbx_mem, QBX_MEM_SIZE, tmp_space, 0
                call64 [CloseHandle], r12
        setup_console:
                ; allocate console, front and back screen buffers.
                call64 [AllocConsole]
                call64 [CreateConsoleScreenBuffer], GENERIC_WRITE, 0, 0, 1, 0
                mov [con_bbuf], rax
                call64 [CreateConsoleScreenBuffer], GENERIC_WRITE, 0, 0, 1, 0
                mov [con_fbuf], rax
                ; set up screen buffers.
                call64 [SetConsoleScreenBufferSize], [con_bbuf], ((SCR_CHAR_HEIGHT shl 16) or SCR_CHAR_WIDTH)
                call64 [SetConsoleScreenBufferSize], [con_fbuf], ((SCR_CHAR_HEIGHT shl 16) or SCR_CHAR_WIDTH)
                jmp set_cursor_info
                empty_cursor_info dq 0x01
                set_cursor_info:
                call64 [SetConsoleCursorInfo], [con_bbuf], empty_cursor_info
                call64 [SetConsoleCursorInfo], [con_fbuf], empty_cursor_info
                ; set console title.
                call64 [SetConsoleTitleA], window_title
        begin_execution:
                ; prep qbx for execution.
                xor q0, q0
                xor q1, q1
                xor q2, q2
                xor q3, q3
                xor qip, qip
                xor rdi, rdi
                mov qsp, QBX_MEM_SIZE - 1 ; initialize the stack pointer
                mov word [screen_rect.Left], 0
                mov word [screen_rect.Top], 0
                mov word [screen_rect.Right], SCR_CHAR_WIDTH
                mov word [screen_rect.Bottom], SCR_CHAR_HEIGHT
                if defined(QBX_BUILD_MODE_DEBUG)
                   int3         ; breakpoint for the debugger
                end if
        advance: ; main qbx loop.
                mov di, word [qbx_mem + qip]               ; read the next instruction.
                add qip, 2                                 ; advance instruction pointer.
                movzx r10, word [qbx_jmp_table + rdi * 2]  ; read offset from jump table.
                add r10, insn_base                         ; compute address of insn implementation.
                mov rax, qflags                            ; prepare to set flags.
                sahf                                       ; set flags.
                jmp r10                                    ; jump to insn implementation.

        insn_base:   ; implementations of qbx instructions.

        ; do nothing.
        insn noop
             nop
        endinsn

        ; stop execution.
        insn halt
             ; check if state dump was requested.
             cmp [args_ptr], 3
             jl quit
             mov r10, [args_ptr]
             mov rdx, qword [r10 + 16]
             cmp byte [rdx], 'd'
             jne quit
             ; dump memory and registers to a file.
             call64 [CreateFileA], dump_file_name, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0
             cmp rax, INVALID_HANDLE
             jne dump
             ; couldn't open dump file for writing, report error and exit.
             call64 [MessageBoxA], 0, err_msg_title, dump_err_msg, MB_ICONERROR
             call64 [ExitProcess], 1
        dump:
             push rax
             ; first, write all memory to the file.
             call64 [WriteFile], rax, qbx_mem, QBX_MEM_SIZE, tmp_space, 0
             pop rax
             ; next, dump registers
             mov word [qbx_mem + 0],  q0
             mov word [qbx_mem + 2],  q1
             mov word [qbx_mem + 4],  q2
             mov word [qbx_mem + 6],  q3
             mov word [qbx_mem + 8],  qipw
             mov word [qbx_mem + 10], qspw
             mov word [qbx_mem + 12], qflagsw
             push rax
             call64 [WriteFile], rax, qbx_mem, 13, tmp_space, 0
             pop rax
             call64 [CloseHandle], rax
        quit:
             call64 [ExitProcess], 0
        endinsn

        ; move immediate value into register.
         rept QBX_NUM_REGISTERS reg:0 {
              ; word-sized operands.
              insn moviwq#reg
                   mov q#reg, word [qbx_mem + qip]
                   add qip, 2
              endinsn

              ; byte-sized operands.
              insn movibq#reg
                   mov q#reg#b, byte [qbx_mem + qip]
                   add qip, 1
              endinsn
        }

        ; move value between registers.
        rept QBX_NUM_REGISTERS tgt:0 {
             rept 4 src:0 \{
                  if ~(tgt eq \src) ; src and dst must be different.
                       ; word-sized operands.
                       insn movwq#tgt#q\#src
                            mov q#tgt, q\#src
                       endinsn

                       ; byte-sized operands.
                       insn movbq#tgt#q\#src
                            mov q#tgt#b, q\#src\#b
                       endinsn

                  end if
             \}
        }

        ; store value to direct address.
        rept QBX_NUM_REGISTERS reg:0 {
             ; word-sized operand.
             insn storwdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov word [qbx_mem +  rcx], q#reg
             endinsn

             ; byte-sized operand.
             insn storbdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov byte [qbx_mem +  rcx], q#reg#b
             endinsn
        }

        ; store value to address in q0.
        rept 3 reg {
             ; word-sized operand.
             insn storwiq#reg
                mov word [qbx_mem + qaddr], q#reg
             endinsn

             ; byte-sized operand.
             insn storbiq#reg
                mov byte [qbx_mem + qaddr], q#reg#b
             endinsn
        }

        ; load value from direct address.
        rept QBX_NUM_REGISTERS reg:0 {
             ; word-sized operand.
             insn loadwdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov q#reg, word [qbx_mem +  rcx]
             endinsn

             ; byte-sized operand.
             insn loadbdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov q#reg#b, byte [qbx_mem +  rcx]
             endinsn

        }

        ; load value from address in q0.
        rept 3 reg {
             insn loadwiq#reg
                mov q#reg, word [qbx_mem + qaddr]
             endinsn

             insn loadbiq#reg
                mov q#reg#b, byte [qbx_mem + qaddr]
             endinsn

        }

        ; push value onto the stack
        rept QBX_NUM_REGISTERS reg:0 {
             insn pushwq#reg
                  sub qsp, 2
                  mov word [qbx_mem + qsp + 1], q#reg
             endinsn

             insn pushbq#reg
                  sub qsp, 1
                  mov byte [qbx_mem + qsp + 1], q#reg#b
             endinsn
        }

        ; pop word-sized value from the stack.
        rept QBX_NUM_REGISTERS reg:0 {
             insn popwq#reg
                mov q#reg, word [qbx_mem + qsp + 1]
                add qsp, 2
             endinsn

             insn popbq#reg
                mov q#reg#b, byte [qbx_mem + qsp + 1]
                add qsp, 1
             endinsn
        }

        ; addition instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn addbq\#dreg\#q#sreg
                       add q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn addwq\#dreg\#q#sreg
                       add q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; subtraction instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn subbq\#dreg\#q#sreg
                       sub q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn subwq\#dreg\#q#sreg
                       sub q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; unsigned multiplication
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn mulbq\#dreg\#q#sreg
                       xor rax, rax
                       mov al, q\#dreg\#b
                       mul q#sreg#b
                       mov q\#dreg\#b, al
                       update_qbx_flags = 1
                  endinsn

                 ; word-sized operands
                 insn mulwq\#dreg\#q#sreg
                      xor rax, rax
                      mov ax, q\#dreg\#w
                      mul q#sreg#w
                      mov q\#dreg\#w, ax
                      update_qbx_flags = 1
                  endinsn
             \}
        }

        ; signed multiplication
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn smulbq\#dreg\#q#sreg
                       xor rax, rax
                       mov al, q\#dreg\#b
                       imul q#sreg#b
                       mov q\#dreg\#b, al
                       update_qbx_flags = 1
                  endinsn

                 ; word-sized operands
                 insn smulwq\#dreg\#q#sreg
                      imul q\#dreg\#w, q#sreg#w
                      update_qbx_flags = 1
                  endinsn
             \}
        }

        ; unsigned division
        rept 3 sreg {
             ; byte-sized operands
             insn divbq#sreg
                  xor dx, dx
                  xor ax, ax
                  mov ax, q0w
                  movzx cx, q#sreg#b
                  div cx
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn divwq#sreg
                  xor rax, rax
                  xor rdx, rdx
                  mov ax, q0w
                  div q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }

        ; signed division
        rept 3 sreg {
             ; byte-sized operands
             insn sdivbq#sreg
                  xor dx, dx
                  xor ax, ax
                  mov ax, q0w
                  movzx cx, q#sreg#b
                  idiv cx
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn sdivwq#sreg
                  xor rax, rax
                  xor rdx, rdx
                  mov ax, q0w
                  idiv q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }


        ; bitwise and instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn andbq\#dreg\#q#sreg
                       and q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn andwq\#dreg\#q#sreg
                       and q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; bitwise or instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn orbq\#dreg\#q#sreg
                       or q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn orwq\#dreg\#q#sreg
                       or q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; bitwise not instructions
        rept QBX_NUM_REGISTERS dreg:0 {
                  ; byte-sized operands
                  insn invbq#dreg
                       not q#dreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn invwq#dreg
                       not q#dreg#w
                       update_qbx_flags = 1
                  endinsn

        }

        ; bitwise xor instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn xorbq\#dreg\#q#sreg
                       xor q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn xorwq\#dreg\#q#sreg
                       xor q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; shift left instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn shlbq\#dreg\#q#sreg
                       movzx rcx, q#sreg
                       shl q\#dreg\#b, cl
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn shlwq\#dreg\#q#sreg
                       movzx rcx, q#sreg
                       shl q\#dreg\#w, cl
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; shift right instructions
        rept QBX_NUM_REGISTERS sreg:0 {
             rept QBX_NUM_REGISTERS dreg:0 \{
                  ; byte-sized operands
                  insn shrbq\#dreg\#q#sreg
                       movzx rcx, q#sreg
                       shr q\#dreg\#b, cl
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn shrwq\#dreg\#q#sreg
                       movzx rcx, q#sreg
                       shr q\#dreg\#w, cl
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; unconditional jump to indirect address.
        insn jui
             mov qipw, q0
        endinsn

        ; unconditional jump to direct address.
        insn jud
             movzx rcx, word [qbx_mem + qip]
             mov qipw, cx
        endinsn

        ; convenience macro for defining conditional jump insn impls.
        macro _define_cond_jump cc* {
              insn j#cc#i
                   cmov#cc qipw, q0
              endinsn

              ; note that the impl for conditional jump to direct address
              ; needs to advance the insn ptr ONLY if the condition is not
              ; fulfilled. to do this, we use x86 setCC with a negated
              ; condition, multiply result by 2 and add it to the insn ptr
              ; at the end.
              insn j#cc#d
                   movzx rcx, word [qbx_mem + qip]
                   setn#cc dl
                   cmov#cc qipw, cx
                   shl     dl, 1
                   add     qipw, dx
              endinsn

              ; analogous implementations for the negative case.

              insn jn#cc#i
                   cmovn#cc qipw, q0
              endinsn

              insn jn#cc#d
                   movzx rcx, word [qbx_mem + qip]
                   set#cc dl
                   cmovn#cc qipw, cx
                   shl     dl, 1
                   add     qipw, dx
              endinsn
        }

        _define_cond_jump z
        _define_cond_jump a
        _define_cond_jump b
        _define_cond_jump g
        _define_cond_jump l
        _define_cond_jump ae
        _define_cond_jump be
        _define_cond_jump ge
        _define_cond_jump le

        ; call procedure at indirect address.
        insn jcalli
             sub qsp, 2
             mov word [qbx_mem + qsp], qipw
             mov qipw, q0
        endinsn

        ; call procedure at direct address.
        insn jcalld
             sub qsp, 2
             mov word [qbx_mem + qsp], qipw
             movzx rcx, word [qbx_mem + qip]
             mov qipw, cx
        endinsn

        ; return
        insn return
             mov qipw, word [qbx_mem + qsp]
             add qsp, 2
        endinsn

        insn yld
             ; save QBX state before handling yield event.
             pushfq   ; save flags that haven't been committed to qflags yet.
             push q0
             push q1
             push q2
             push q3
             movzx rcx, word [qbx_mem + qip]  ; read yield code into rcx.
             add qip, 2                       ; advance ip.
             push qip                         ; save ip.
             push qsp
             push qflags
             ; find appropriate handler.
             cmp rcx, 0x01
             je yld_screenupd
             cmp rcx, 0x02
             je yld_sleep
        yld_debugbreak:
             ; YIELD CODE 0x00 -- debug break.
             ; this is also triggered when no other matching handler is found.
             int3
             jmp yld_return
        yld_screenupd:
            ; YIELD CODE 0x01 -- screen update.
            ; q0 has pointer to screen area in memory;
            ; q1 has width/height of updated rect;
            ; q2 has X/Y coords of upper left corner of updated rect.
            add r12, qbx_mem
            xor rax, rax
            mov bx, r13w
            mov ah, bl
            shl rax, 8
            mov al, bh
            mov bx, q2
            and bx, 0xff00
            shr bx, 8
            mov word [screen_rect.Left], bx
            and q2, 0x00ff
            mov word [screen_rect.Top], q2
            call64 [WriteConsoleOutputA], [con_bbuf], r12, rax, 0, screen_rect
            call64 [SetConsoleActiveScreenBuffer], [con_bbuf]
            mov r10, [con_bbuf]
            mov r11, [con_fbuf]
            mov [con_bbuf], r11
            mov [con_fbuf], r10
            xor r12, r12
            jmp yld_return
        yld_sleep:
            ; YIELD CODE 0x02 -- sleep.
            ; q0 contains the number of milliseconds to sleep.
            movzx rcx, q0
            call64 [Sleep], rcx
            jmp yld_return
        yld_return:
             ; restore QBX state.
             pop qflags
             pop qsp
             pop qip
             pop q3
             pop q2
             pop q1
             pop q0
             popfq
        endinsn

        update_flags_advance:
                ; commit the current set of flags to the qflags register and
                ; proceed to the next insn.
                lahf
                mov qflags, rax
                jmp advance
