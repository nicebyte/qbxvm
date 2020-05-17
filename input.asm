include 'qbx_insn_helpers.inc'
include 'qbx_instructions.inc'

qbx_insns define_icodes, 0

dw moviwq0, 0xbeef, \
   moviwq1, 0xfeed, \
   movbq2q1,        \
   movwq2q0,        \
   storbdq1, 1023,  \
   loadbdq2, 1023,  \
   moviwq0, 1022,   \
   storbiq1,        \
   pushwq0,         \
   pushwq1,         \
   popwq2,          \
   popwq3,          \
   halt