format PE64 NX GUI 6.0
entry start

include 'win64_helpers.inc'
include 'qbx_insn_helpers.inc'

HelloStr db "Hello, World!", 0

section '.code' code readable executable
        start:
                call64 [MessageBoxA], 0, HelloStr, HelloStr, 0
                call64 [ExitProcess], 0

section '.idata' import readable writeable
        import_directory_table KERNEL32, USER32
        import_functions KERNEL32, ExitProcess
        import_functions USER32, MessageBoxA


