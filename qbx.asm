format PE64 NX GUI 6.0
entry start

include 'win64_helpers.inc'
include 'qbx_instructions.inc'
include 'qbx_insn_helpers.inc'
include 'qbx_registers.inc'

; import tables.
section '.idata' import readable writeable
        import_directory_table KERNEL32, USER32
        import_functions KERNEL32, \
                         AllocConsole, \
                         WriteConsoleOutputA, \
                         GetStdHandle, \
                         ExitProcess
        import_functions USER32, MessageBoxA

; define constants for all QBX instruction codes.
qbx_insns define_icodes, 0

section '.data' data readable writeable
        ; jump table mapping insn codes to insn implementations.
        qbx_insns define_jmp_table, qbx_jmp_table
        ; QBX memory.
        QBX_MEM_SIZE = 1024
        qbx_mem file 'input.bin'
                CODE_SIZE = $ - qbx_mem
                dw QBX_MEM_SIZE - CODE_SIZE dup ?

section '.code' code readable executable
        start:               ; entry point - program starts here
                int3         ; breakpoint for the debugger
                xor qip, qip ; zero out instruction pointer
                xor rdi, rdi ; rdi will hold the next instruction code
                mov qsp, QBX_MEM_SIZE - 1 ; initialize the stack pointer
        advance:
                mov di, word [qbx_mem + qip]               ; read the next instruction
                add qip, 2                                 ; advance instruction pointer
                movzx r10, word [qbx_jmp_table + rdi * 2]  ; read offset from jump table
                add r10, insn_base                         ; compute address of insn implementation
                mov rax, qflags                            ; prepare to set flags
                sahf                                       ; set flags
                jmp r10                                    ; jump to insn implementation


        insn_base:   ; implementations of QBX instructions.

        ; do nothing.
        insn noop
             nop
        endinsn

        ; stop execution.
        insn halt
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
                  ; byte-sized registers
                  insn addbq\#dreg#q#sreg
                       add q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized registers
                  insn addwq\#dreg#q#sreg
                       add q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }

        ; subtraction instructions
        rept 4 sreg:0 {
             rept 4 dreg:0 \{
                  ; byte-sized registers
                  insn subbq\#dreg#q#sreg
                       sub q\#dreg\#b, q#sreg#b
                       update_qbx_flags = 1
                  endinsn

                  ; word-sized registers
                  insn subwq\#dreg#q#sreg
                       sub q\#dreg\#w, q#sreg#w
                       update_qbx_flags = 1
                  endinsn

             \}
        }


        update_flags_advance:
                lahf
                mov qflags, rax
                jmp advance



