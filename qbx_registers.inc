; QBX <--> x64 REGISTER MAPPING

; general-purpose registers
qbx_r0 equ r12
qbx_r1 equ r13
qbx_r2 equ r14
qbx_r3 equ r15

qbx_r0w equ r12w
qbx_r1w equ r13w
qbx_r2w equ r14w
qbx_r3w equ r15w

qbx_r0b equ r12b
qbx_r1b equ r13b
qbx_r2b equ r14b
qbx_r3b equ r15b

; stack ptr
qbx_sp equ rbx
qbx_spw equ bx
qbx_spb equ bl

; insn ptr
qbx_ip equ rsi

; flags
qbx_flags equ r11