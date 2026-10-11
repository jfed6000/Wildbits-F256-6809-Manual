# NitrOS-9 Level 2 examples for the Wildbits Jr2/K2.
# Each example is one .asm file that builds to a command module in build/.
#
#   make NITROS9DIR=/path/to/nitros9            build the modules
#   make install DISK=l2_wildbitsjr2.dsk         copy them into CMDS on a disk image
#
# NITROS9DIR must be a NitrOS-9 tree for the Longview core (device blocks
# $FC-$FF). Older trees map VICKY at $C0 and will build programs that
# don't work on the current core.

LWASM ?= lwasm
OS9 ?= os9
PLATFORM ?= jr2

# The same assembler settings the NitrOS-9 build uses, so code copied
# from the NitrOS-9 sources assembles here unchanged. --6809 rejects
# 6309-only instructions.
LWASMFLAGS = --6809 --format=os9 --no-warn=ifp1 \
	--pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax \
	--includedir=$(NITROS9DIR)/defs -Dwildbits=1 -D$(PLATFORM)

PROGRAMS = hello bgcolor
MODULES = $(addprefix build/,$(PROGRAMS))

all: check-tree $(MODULES)

build/%: %.asm defsfile | build
	$(LWASM) $(LWASMFLAGS) --list=build/$*.lst -o $@ $<

build:
	mkdir -p build

check-tree:
	@test -n "$(NITROS9DIR)" || { echo "Set NITROS9DIR to your NitrOS-9 tree"; exit 1; }
	@grep -q '^VICKY_BLK' $(NITROS9DIR)/defs/wildbits.d || \
		{ echo "$(NITROS9DIR) predates the Longview memory map (no VICKY_BLK in defs/wildbits.d)"; exit 1; }

# Copy each module into CMDS and make it executable.
install: all
	@test -n "$(DISK)" || { echo "Usage: make install DISK=image.dsk"; exit 1; }
	for p in $(PROGRAMS); do \
		$(OS9) copy -r build/$$p $(DISK),CMDS/$$p && \
		$(OS9) attr -q -e -pe -r -w -pr $(DISK),CMDS/$$p || exit 1; \
	done

clean:
	rm -rf build

.PHONY: all check-tree install clean
