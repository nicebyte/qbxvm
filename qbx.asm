format PE64 NX GUI 6.0
entry start

include 'win64_helpers.inc'
include 'qbx_insn_helpers.inc'
include 'qbx_registers.inc'

qbx_mem dw 0
        dw 1
        db 1024 dup ?

section '.code' code readable executable
        define_jmp_table qbx_jmp_table, noop, halt
        start:
                int3
                xor qip, qip ; zero out instruction pointer
                xor rdi, rdi

        advance:
                mov di, word [qbx_mem + qip]               ; read the next instruction
                add qip, 2                                 ; advance instruction pointer
                movzx r10, word [qbx_jmp_table + rdi * 2]  ; read offset from jump table
                add r10, insn_base                         ; compute address of insn implementation
                jmp r10                                    ; jump to insn implementation


        insn_base:

        insn noop
             nop
        endinsn

        insn halt
             call64 [ExitProcess], 0
        endinsn

        update_flags_advance:
                lahf
                mov qflags, rax
                jmp advance

section '.idata' import readable writeable
        import_directory_table KERNEL32, USER32
        import_functions KERNEL32, \
                         AllocConsole, \
                         WriteConsoleOutputA, \
                         GetStdHandle, \
                         ExitProcess
        import_functions USER32, MessageBoxA


