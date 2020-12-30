include 'qbx_insn_helpers.asm'
include 'qbx_insn_list.asm'

qbx_insns define_icodes, 0

macro qnop { dw noop }
macro qhalt { dw halt }

macro _check_reg r {
      if ~((r eq q0)|(r eq q1)|(r eq q2)|(r eq q3))
         err "invalid register", r
       end if
}

macro _check_opsize opsize {
      if ~(opsize eq b) & ~(opsize eq w)
         err "invalid operand size"
      end if
}

macro _mem_insn name* {
      macro q#name opsize*, addr*, r* \{
            _check_opsize opsize
            _check_reg r
            local matched
            define matched 0
            match =0 [target], matched addr \\{
                  if target eq q0
                     dw (#name\#opsize\#i\#r)
                  else if ((target eq q1)|(target eq q2)|(target eq q3))
                     err "addr for indirect memop must be held in q0"
                  else
                     dw (#name\#opsize\#d\#r)
                     dw target
                  end if
                  define matched 1
            \\}
            match =0 any, matched addr
            \\{
                err "invalid address. must be [q0] or imm. value."
            \\}
      \}
}

_mem_insn stor
_mem_insn load

macro qmov opsize*, r1*, r2* {
      _check_opsize opsize
      _check_reg r1

      if ((r2 eq q0)|(r2 eq q1)|(r2 eq q2)|(r2 eq q3))
         dw mov#opsize#r1#r2
      else
        dw movi#opsize#r1
        if opsize eq b
           db r2
        else if opsize eq w
           dw r2
        else
           err
        end if
      end if
}

macro _binop_alu_insn name {
      macro q#name opsize*, r1*, r2* \{
            _check_reg (#r1)
            _check_reg (#r2)
            _check_opsize (#opsize)
            dw name\#opsize\#r1\#r2
      \}
}

_binop_alu_insn add
_binop_alu_insn sub
_binop_alu_insn and
_binop_alu_insn or
_binop_alu_insn xor
_binop_alu_insn shr
_binop_alu_insn shl
_binop_alu_insn mul
_binop_alu_insn smul

macro _unop_alu_insn name {
      macro q#name opsize*, r* \{
            if ((name eq mul)|(name eq smul)|(name eq div)|(name eq sdiv)) & \
               ((r eq q0)|(r eq q1))
               err "invalid instruction"
            end if
            _check_reg (#r)
            _check_opsize (#opsize)
            dw name\#opsize\#r
      \}
}

_unop_alu_insn div
_unop_alu_insn sdiv
_unop_alu_insn inv
_unop_alu_insn push
_unop_alu_insn pop

macro qsleep r* {
      _check_reg r
      dw sleep#r
}

macro qj cond*, target* {
      if (target eq q0)
         dw j#cond#i
      else if ((target eq q1)|(target eq q2)|(target eq q3))
         err "indirect jump or call address must be held in q0"
      else
         dw j#cond#d
         dw target
      end if
}

macro qret { dw return }

macro qyld code {
      dw yld
      dw code
}

format binary