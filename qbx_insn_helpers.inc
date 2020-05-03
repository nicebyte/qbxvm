macro define_jmp_table jmp_table_name*, [op*] {
common
        next_opcode = 0x00
forward
        op = next_opcode
        next_opcode = next_opcode + 1
common
        jmp_table_name:
forward
        dw IMPL_#op
}

begin_insn_impls equ insn_base = $

macro insn name {
      IMPL_#name = $ - insn_base
}

macro endinsn {

}