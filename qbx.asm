format PE64 NX GUI 6.0
entry start

include 'win64_helpers.inc'
include 'qbx_instructions.inc'
include 'qbx_insn_helpers.inc'
include 'qbx_registers.inc'

section '.idata' import readable writeable
        import_directory_table KERNEL32, USER32
        import_functions KERNEL32, \
                         AllocConsole, \
                         WriteConsoleOutputA, \
                         GetStdHandle, \
                         ExitProcess
        import_functions USER32, MessageBoxA

qbx_insns define_icodes, 0

section '.data' data readable writeable
        qbx_insns define_jmp_table, qbx_jmp_table
        qbx_mem dw noop
                dw halt
                db 1024 dup ?

section '.code' code readable executable
        start:               ; entry point - program starts here
                int3         ; breakpoint for the debugger
                xor qip, qip ; zero out instruction pointer
                xor rdi, rdi ; rdi will hold the next instruction code

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

        macro moviw [reg*] {
              insn moviw#reg
                   mov reg, word [qbx_mem + qip]
                   add qip, 2
              endinsn
        }
        moviw q0, q1, q2, q3

        update_flags_advance:
                lahf
                mov qflags, rax
                jmp advance



