; QBX <--> x64 REGISTER MAPPING

; general-purpose registers
q0 equ r12w
q1 equ r13w
q2 equ r14w
q3 equ r15w
q0w equ r12w
q1w equ r13w
q2w equ r14w
q3w equ r15w
qaddr equ r12
QBX_NUM_REGISTERS equ 4

q0b equ r12b
q1b equ r13b
q2b equ r14b
q3b equ r15b

; stack ptr
qsp  equ rbx
qspw equ bx
qspb equ bl

; insn ptr
qip equ rsi
qipw equ si

; flags
qflags equ r11
qflagsw equ r11w