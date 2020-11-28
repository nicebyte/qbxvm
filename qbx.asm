format PE64 NX GUI 6.0

QBX_BUILD_MODE_DEBUG = 1

entry start

include 'win64_helpers.asm'
include 'qbx_insn_list.asm'
include 'qbx_insn_helpers.asm'
include 'qbx_registers.asm'

; import tables.
section '.idata' import readable writeable
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
                         GetLastError
        import_functions USER32, MessageBoxA
        import_functions SHELL32, CommandLineToArgvW

; define constants for all QBX instruction codes.
qbx_insns define_icodes, 0

section '.strings' data readable
        err_msg_title   db "Error", 0
        file_err_msg    db "Failed to open the input file.", 0
        noinput_err_msg db "Input file name not specified.", 0
        dump_err_msg    db "Failed to open dump file for writing.",0
        dump_file_name  db "qbx_dump.bin", 0
        window_title    db "QBX Bytecode Xecutor", 0
        ; jump table that maps insn codes to insn implementations.
        qbx_insns define_jmp_table, qbx_jmp_table

SCR_CHAR_WIDTH  equ 80
SCR_CHAR_HEIGHT equ 25
SCR_MEM_SIZE = SCR_CHAR_WIDTH * SCR_CHAR_HEIGHT * 4

section '.mem' data readable writeable
        ; QBX memory.
        QBX_MEM_SIZE = 1024
        qbx_mem db QBX_MEM_SIZE dup ?
        screen dd SCR_CHAR_WIDTH * SCR_CHAR_HEIGHT dup ?

section '.vars' data readable writeable
        screen_rect  dd 0
                     dw SCR_CHAR_WIDTH
                     dw SCR_CHAR_HEIGHT
        con_bbuf dq ?
        con_fbuf dq ?
        num_args  dw ?
        args_ptr  dq ?
        prog_size dq ?

section '.code' code readable executable
        start:               ; entry point - program starts here
                if defined(QBX_BUILD_MODE_DEBUG)
                   int3         ; breakpoint for the debugger
                end if
                ; parse the command line to extract the input file name.
                call64 [GetCommandLineW]
                call64 [CommandLineToArgvW], rax, num_args
                mov [args_ptr], rax
                cmp [num_args], 2
                jge open_input
                ; if an input file name is not provided, display error message and exit.
                call64 [MessageBoxA], 0, noinput_err_msg, err_msg_title, MB_ICONERROR
                call64 [ExitProcess], 1
        open_input:
                ; attempt to open the image file.
                call64 [CreateFileW], [rax + 8], GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0
                cmp rax, INVALID_HANDLE
                jne read_input
                ; if the image could not be opened, display error message and exit.
                call64 [MessageBoxA], 0, file_err_msg, err_msg_title, MB_ICONERROR
                call64 [ExitProcess], 1
        read_input:
                ; read the contents of the image into the qbx memory region.
                mov r12, rax
                call64 [ReadFile], r12, qbx_mem, QBX_MEM_SIZE, prog_size, 0
                call64 [CloseHandle], r12
        setup_console:
                ; allocate console, front and back screen buffers.
                call64 [AllocConsole]
                call64 [CreateConsoleScreenBuffer], GENERIC_WRITE, 0, 0, 1, 0
                mov [con_bbuf], rax
                call64 [CreateConsoleScreenBuffer], GENERIC_WRITE, 0, 0, 1, 0
                mov [con_fbuf], rax
                ; set up screen buffers.
                call64 [SetConsoleScreenBufferSize], [con_bbuf], ((SCR_CHAR_WIDTH shl 16) + SCR_CHAR_HEIGHT)
                call64 [SetConsoleScreenBufferSize], [con_fbuf], ((SCR_CHAR_WIDTH shl 16) + SCR_CHAR_HEIGHT)
                call64 [SetConsoleCursorInfo], [con_bbuf], empty_cursor_info
                call64 [SetConsoleCursorInfo], [con_fbuf], empty_cursor_info
                ; set console title.
                call64 [SetConsoleTitleA], window_title
        begin_execution:
                ; prep qbx for execution.
                xor qip, qip ; zero out instruction pointer
                xor rdi, rdi ; rdi will hold the next instruction code
                mov qsp, QBX_MEM_SIZE - 1 ; initialize the stack pointer
        advance: ; main qbx loop.
                call64 [WriteConsoleOutputA], [con_bbuf], screen, ((SCR_CHAR_WIDTH shl 16) + SCR_CHAR_HEIGHT), 0, screen_rect
                call64 [SetConsoleActiveScreenBuffer], [con_bbuf]
                mov r10, [con_bbuf]
                mov r11, [con_fbuf]
                mov [con_bbuf], r11
                mov [con_fbuf], r10
                mov di, word [qbx_mem + qip]               ; read the next instruction
                add qip, 2                                 ; advance instruction pointer
                movzx r10, word [qbx_jmp_table + rdi * 2]  ; read offset from jump table
                add r10, insn_base                         ; compute address of insn implementation
                mov rax, qflags                            ; prepare to set flags
                sahf                                       ; set flags
                jmp r10                                    ; jump to insn implementation
        empty_cursor_info dd 1, 0

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
             call64 [MessageBoxA], 0, err_msg_title, dump_err_msg, MB_ICONERROR
             call64 [ExitProcess], 1
        dump:
             push rax
             ; first, write all memory to the file.
             call64 [WriteFile], rax, qbx_mem, QBX_MEM_SIZE + SCR_MEM_SIZE, prog_size, 0
             pop rax
             ; next, dump registers
             mov word  [qbx_mem + 0], q0
             mov word  [qbx_mem + 2], q1
             mov word  [qbx_mem + 4], q2
             mov word  [qbx_mem + 6], q3
             mov word  [qbx_mem + 8], qipw
             mov word  [qbx_mem + 10], qspw
             mov qword [qbx_mem + 12], qflags
             push rax
             call64 [WriteFile], rax, qbx_mem, 20, prog_size, 0
             pop rax
             call64 [CloseHandle], rax
        quit:
             call64 [ExitProcess], 0
        endinsn

        ; move immediate word-sized value into register.
         rept 4 reg:0 {
              insn moviwq#reg
                   mov q#reg, word [qbx_mem + qip]
                   add qip, 2
              endinsn
        }

        ; move immediate byte-sized value into register.
         rept 4 reg:0 {
              insn movibq#reg
                   mov q#reg#b, byte [qbx_mem + qip]
                   add qip, 1
              endinsn
        }

        ; move word-sized value between registers.
        rept 4 tgt:0 {
             rept 4 src:0 \{
                  if ~(tgt eq \src)
                       insn movwq#tgt#q\#src
                            mov q#tgt, q\#src
                       endinsn
                  end if
             \}
        }

        ; move byte-sized value between registers.
        rept 4 tgt:0 {
             rept 4 src:0 \{
                  if ~(tgt eq \src)
                       insn movbq#tgt#q\#src
                            mov q#tgt#b, q\#src\#b
                       endinsn
                  end if
             \}
        }

        ; store word-sized value to direct address.
        rept 4 reg:0 {
             insn storwdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov word [qbx_mem +  rcx], q#reg
             endinsn
        }

        ; store byte-sized value to direct address.
        rept 4 reg:0 {
             insn storbdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov byte [qbx_mem +  rcx], q#reg#b
             endinsn
        }

        ; store word-sized value to address in q0.
        rept 3 reg {
             insn storwiq#reg
                mov word [qbx_mem + qaddr], q#reg
             endinsn
        }

        ; store byte-sized value to address in q0.
        rept 3 reg {
             insn storbiq#reg
                mov byte [qbx_mem + qaddr], q#reg#b
             endinsn
        }

        ; load word-sized value from direct address.
        rept 4 reg:0 {
             insn loadwdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov q#reg, word [qbx_mem +  rcx]
             endinsn
        }

        ; load byte-sized value from direct address.
        rept 4 reg:0 {
             insn loadbdq#reg
                movzx rcx, word [qbx_mem + qip]
                add qip, 2
                mov q#reg#b, byte [qbx_mem +  rcx]
             endinsn
        }

        ; load word-sized value from address in q0.
        rept 3 reg {
             insn loadwiq#reg
                mov q#reg, word [qbx_mem + qaddr]
             endinsn
        }

        ; load byte-sized value from address in q0.
        rept 3 reg {
             insn loadbiq#reg
                mov q#reg#b, byte [qbx_mem + qaddr]
             endinsn
        }

        ; push word-sized value onto the stack
        rept 4 reg:0 {
             insn pushwq#reg
                  sub qsp, 2
                  mov word [qbx_mem + qsp + 1], q#reg
             endinsn
        }

        ; push byte-sized value onto the stack
        rept 4 reg:0 {
             insn pushbq#reg
                  sub qsp, 1
                  mov byte [qbx_mem + qsp + 1], q#reg#b
             endinsn
        }

        ; pop word-sized value from the stack.
        rept 4 reg:0 {
             insn popwq#reg
                mov q#reg, word [qbx_mem + qsp + 1]
                add qsp, 2
             endinsn
        }

        ; pop byte-sized value from the stack.
        rept 4 reg:0 {
             insn popbq#reg
                mov q#reg#b, byte [qbx_mem + qsp + 1]
                add qsp, 1
             endinsn
        }

        ; addition instructions
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
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
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
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
        rept 2 sreg:2 {
             ; byte-sized operands
             insn mulbq#sreg
                  mov al, q0b
                  mul q#sreg#b
                  mov q0, ax
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn mulwq#sreg
                  mov ax, q0w
                  mul q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }

        ; signed multiplication
        rept 2 sreg:2 {
             ; byte-sized operands
             insn smulbq#sreg
                  mov al, q0b
                  imul q#sreg#b
                  mov q0, ax
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn smulwq#sreg
                  mov ax, q0w
                  imul q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }

        ; unsigned division
        rept 2 sreg:2 {
             ; byte-sized operands
             insn divbq#sreg
                  mov ax, q0w
                  div q#sreg#b
                  mov q0, ax
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn divwq#sreg
                  mov dx, q1w
                  mov ax, q0w
                  div q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }

        ; signed division
        rept 2 sreg:2 {
             ; byte-sized operands
             insn sdivbq#sreg
                  mov ax, q0w
                  idiv q#sreg#b
                  mov q0, ax
                  update_qbx_flags = 1
             endinsn

             ; word-sized operands
             insn sdivwq#sreg
                  mov dx, q1w
                  mov ax, q0w
                  idiv q#sreg#w
                  mov q0, ax
                  mov q1, dx
                  update_qbx_flags = 1
             endinsn
        }


        ; bitwise and instructions
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
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
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
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
        rept 4 dreg:0 {
                  ; byte-sized operands
                  insn notbq#dreg
                       not q#dreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized operands
                  insn notwq#dreg
                       not q#dreg#w
                       update_qbx_flags = 1
                  endinsn

        }

        ; bitwise xor instructions
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
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

        update_flags_advance:
                lahf
                mov qflags, rax
                jmp advance



