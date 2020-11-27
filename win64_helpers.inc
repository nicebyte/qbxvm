; Gegenerates IDT for the listed libs.
macro import_directory_table [lib*] {
forward
        dd rva IAT__#lib
        dd 0
        dd 0
        dd rva NAME__#lib 
        dd rva IAT__#lib

common
        dd 5 dup(0)

forward
        NAME__#lib db `lib, ".DLL", 0
}

; Generates IAT for the functions from a given lib.
macro import_functions libname, [funcnames*] {
forward
      if $ & 1
         db 0
      end if
      IMPORTNAME__#funcnames dw 0
                             db `funcnames, 0
common
        IAT__#libname:
forward
        funcnames dq rva IMPORTNAME__#funcnames

common
        dq 0
}

; Helper macro, puts parameter into a registers (if needed).
macro call64_putreg param*, reg*
{
        if ~ (reg eqtype rax)
           display "target must be a register"
           err
        end if
        if ~ param eq reg
            mov reg, param
        end if
}

; (Partial) implementation of the Win64 calling convention
macro call64 fn*, [arg]
{
common
        ; The `local' directive declares the following names
        ; a "local" to the macro - this is done so that each
        ; macro invocation gets its very own instance of those variables.
        local nargs, arg_idx, stack_space

        ; nargs is the number of arguments passed to the function.
        ; note that below we're simply forward-referencing nargs and relying
        ; on fasm to infer the actual value (see the section above on forward-referencing).

        ; align the stack on 16-byte boundary, and reserve space for arguments.
        ; we make the assumption that at the time of macro invocation, the stack
        ; is "16+8"-aligned (due to the return address having been pushed onto it
        ; by the current function's caller).
        if nargs <= 4
                 ; even when the number of arguments is less than 4,
                 ; the calling convention mandates that we reserve the
                 ; so-called "shadow space" on the stack for 4 parameters.
           stack_space = 5 * 8 ; subtracting 40 from rsp will make it 16-byte aligned
        else if nargs & 1
                 ; if we have an odd number of arguments, reserve just enough space for them,
                 ; and the stack will become 16-byte aligned:
                 ; rsp_old = 16 * K - 8
                 ; rsp_new = 16 * K - 8 - 8 * (2 * Q + 1) = 16 * K - 16 * Q - 16 = 16 * (K - Q - 1)
           stack_space = nargs * 8
        else
                 ; if we have an even number of arguments, we need 8 more bytes of padding to
                 ; achieve alignment.
           stack_space = (nargs + 1) * 8
        end if

        if stack_space
                 ; allocate space on the stack.
           sub rsp, stack_space
        end if

        arg_idx = 0

forward
        match ,arg
        \{
                ; this matches an empty argument list.
                ; unfortunately, when no variadic arugments are provided at the macro
                ; invocation site, the forward blocks are still processed once (with all groupargs empty).
        \}
        match any,arg
        \{
                 ; pass the first 4 arguments in registers and the rest on the stack.
           arg_idx = arg_idx + 1
           if arg_idx = 1
               call64_putreg arg, rcx
           else if arg_idx = 2
               call64_putreg arg, rdx
           else if arg_idx = 3
               call64_putreg arg, r8
           else if arg_idx = 4
               call64_putreg arg, r9
           else
               mov qword [rsp + (arg_idx-1)*8], arg
           end if

        \}
common
        ; set value of the nargs assembly-time variable (and fasm will magically know to use
        ; this value up above...)
        nargs = arg_idx

        ; perform the call
        call fn

        ; clean up the stack as required by the calling convention
        if stack_space
           add rsp, stack_space
        end if
}

; WIN32 API constants

MB_ICONERROR   equ  0x00000010
GENERIC_READ   equ  0x80000000
GENERIC_WRITE  equ  0x40000000
OPEN_EXISTING  equ  3
CREATE_ALWAYS  equ  2
INVALID_HANDLE equ -1
