include 'qbx_insn_helpers.inc'
include 'qbx_instructions.inc'

qbx_insns define_icodes, 0

dw movibq0
db 0xfb
dw movibq2
db 0xfd
dw mulbq2
dw movibq0
db 0xfb
dw movibq3
db 0xfd
dw smulbq3
dw halt