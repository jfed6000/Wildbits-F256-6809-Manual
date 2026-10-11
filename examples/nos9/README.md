# NitrOS-9 examples

6809 programs that run under NitrOS-9 Level 2 on the Wildbits Jr2 and K2. Each `.asm` file builds to one command module.

| Program | Shows |
|---|---|
| [hello.asm](hello.asm) | The module header, the data area, writing a line with `I$WritLn`, and exiting with `F$Exit`. Copy it to start a new program. |
| [bgcolor.asm](bgcolor.asm) | Reaching a hardware register: `F$MapBlk` maps the VICKY block (`$FC`) into the program, and `F$ClrBlk` releases it. |

## What you need

- lwtools (`lwasm`) and ToolShed (`os9`) on your `PATH`.
- A NitrOS-9 source tree for the Longview core, for its `defs` folder. The core moved the device blocks to `$FC`–`$FF`; older trees still use `$C0` and `$C1`, and the Makefile refuses them.
- A NitrOS-9 Level 2 disk image for your machine, built from the same tree.

## Build and install

```sh
make NITROS9DIR=/path/to/nitros9                    # writes build/hello, build/bgcolor
make install NITROS9DIR=/path/to/nitros9 DISK=l2_wildbitsjr2.dsk
```

`install` copies each module into `CMDS` on the image and sets its execute attributes. Write the image to the SD card, boot it, and type the program's name at the shell prompt.

`PLATFORM=k2` passes `-Dk2` instead of `-Djr2`; these examples don't depend on it. `LWASM=` and `OS9=` pick other tools.

## How the examples are set up

- `defsfile` sets `Level equ 2` and brings in `os9.d`, `scf.d`, `rbf.d` and `wildbits.d`. Each program includes it with `use defsfile`.
- Use the names from `wildbits.d` (`TEXT_LUT_BLK`, `TEXT_LUT_BG` and so on) rather than numbers, so a program follows the tree when the hardware changes.
- The Makefile uses the same lwasm pragmas as the NitrOS-9 build, so code copied from the NitrOS-9 sources assembles here unchanged. `--6809` keeps 6309-only instructions out.
