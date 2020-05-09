macro define_jmp_table jmp_table_name*, [op*] {
common
        next_opcode = 0x00
forward
        ; define constants for each opcode.
        op = next_opcode
        next_opcode = next_opcode + 1
common
        jmp_table_name:
forward
        ; IMPL_* labels are defined by the `insn` macro.
        dw IMPL_#op
}

macro insn name {
      IMPL_#name = $ - insn_base
      update_qbx_flags = 0
}

macro endinsn {
      if update_qbx_flags
         jmp update_flags_advance
      else
         jmp advance
      end if
}