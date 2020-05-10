; QBX <--> x64 REGISTER MAPPING

; general-purpose registers
qr0 equ r12
qr1 equ r13
qr2 equ r14
qr3 equ r15

qr0w equ r12w
qr1w equ r13w
qr2w equ r14w
qr3w equ r15w

qr0b equ r12b
qr1b equ r13b
qr2b equ r14b
qr3b equ r15b

; stack ptr
qsp equ rbx
qspw equ bx
qspb equ bl

; insn ptr
qip equ rsi

; flags
qflags equ r11