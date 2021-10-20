# asmlib

I/O and library function implementations in x86 assembly

For 32-bit compatible systems with the System V ABI and a `syscall` implementation.

## Features

- Implementations of
    - `read` (GNU)
    - `puts` (C)
    - `strlen` (C)
    - `strcpy` (C)
    - `strcat` (C)
- `Hello, world!` to stdout without includes
- Assembler/linker Makefile
- Comments

Most functions are not full standard implementations and could be optimised.

## Prerequisites

- `nasm` 2.15+
- `binutils` 2.36+
- `gdb` 11.1+ (Optional)

## Building

`make`

## Running

`make run`

## Debugging

Requires GDB. A script is provided to display primary registers.

`make debug`

## Known issues

- Buffer overflow with input over a certain length due to static allocation
