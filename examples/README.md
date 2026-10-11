# Examples

Complete, runnable 6809 programs for the Wildbits F256 Jr2 and K2, based on the examples in the manual. Assemble them with [lwtools](http://www.lwtools.ca/) (`lwasm`).

* [raw](raw) -- programs that run on the bare machine, without an operating system. Start with [skeleton.asm](raw/skeleton.asm), which sets up the machine, clears the text screen and prints a message. Its header explains how to build it and load it with FoenixMgr.
* [include](include) -- shared include files. `wildbits_regs.inc` holds the register addresses. It is generated from `data/registers` by `tools/regs.py`, so don't edit it by hand.

NitrOS-9 versions of the examples will go in `nos9`.

Run `make examples` in the top folder to assemble everything. `make examples LWASM=/path/to/lwasm` picks a different assembler.

The 6502 examples from the old Foenix manual were removed. They are still in the git history, under the `foenix-final` tag.
