# GNU Makefile
# assembler build script for x86 architecture

# requisites:
# 	make
# 	nasm
# 	ld
#	gdb	(optional)

# output:	i386 ELF
# target:	32-bit compatible with System V ABI

# ** Directories **
CD=$(shell pwd)
TOOLSDIR=${CD}/tools

# ** Input **
AS_SRC=main.s

# ** Output **
AS_OUT=main.o
EXEC_OUT=$(CD)/main

# ** Files **
GDB_CONF=${TOOLSDIR}/gdbinit

# ** Constants **
ENTRY=_start
AS_ARCH=elf32
LD_ARCH=elf_i386

# ** Flags **
ASFLAGS=-f$(AS_ARCH) \
	$(AS_SRC) -o $(AS_OUT) -g
LDFLAGS=-m$(LD_ARCH) -e $(ENTRY) \
	$(AS_OUT) -o $(EXEC_OUT)
GDBFLAGS=-x ${GDB_CONF} ${EXEC_OUT}

# ** Targets **
.SILENT:

# Build executable
all:	
	make log -s
	echo "** build"
	nasm $(ASFLAGS) && \
	echo "	AS	\`$(EXEC_OUT)'" && \
	ld ${LDFLAGS}	&& \
	echo "	LD	\`$(EXEC_OUT)'"

# Execute output
run:	
	echo "** run"
	echo "	exec	\`$(EXEC_OUT)'"
	echo
	$(EXEC_OUT)

# Remove output files
clean:
	echo "** clean"
	rm -f $(AS_OUT) $(EXEC_OUT)

# Debug binary
debug:
	echo "** debug"
	gdb ${GDBFLAGS}

# Show flags
log:
	echo "ASFLAGS	\`$(ASFLAGS)'"
	echo "LDFLAGS	\`$(LDFLAGS)'"
