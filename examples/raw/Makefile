# Raw 6809 examples: programs that run on the bare Jr2/K2, without NitrOS-9.
# Each example is one .asm file that builds to a .bin image.

LWASM ?= lwasm
LWASMFLAGS = --6809 --format=raw

PROGRAMS = skeleton.bin

all: $(PROGRAMS)

%.bin: %.asm
	$(LWASM) $(LWASMFLAGS) --list=$*.lst -o $@ $<

clean:
	rm -f *.bin *.lst

.PHONY: all clean
