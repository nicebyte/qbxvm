; QBX <--> x64 REGISTER MAPPING

; general-purpose registers
qr0 equ r12w
qr1 equ r13w
qr2 equ r14w
qr3 equ r15w

qr0b equ r12b
qr1b equ r13b
qr2b equ r14b
qr3b equ r15b

; stack ptr
qsp  equ  bx
qspb equ bl

; insn ptr
qip equ rsi

; flags
qflags equ r11