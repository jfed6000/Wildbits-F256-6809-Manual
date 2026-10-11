# Wildbits F256 6809 Reference Manual: rewrite plan

This file is the source of truth for the rewrite. The PPM project "wildbits-manual" points here.

## Goal

Rewrite the manual for the Wildbits Jr2 and K2 running the FNX6809 core. Keep the existing chapter structure. Every register the manual documents is checked against the RTL.

## Decisions

- **D1 Baseline core:** RC24 "Longview" (2,016 KB RAM with FLASHDIS set), as committed to the staging RTL on 2026-10-09.
- **D2 Machines:** the Jr2 and K2 are the main subject. The F256Jr and F256K get short notes: the core will be backported to them, but they stay at 6 MHz instead of 20 MHz.
- **D3 Sources of truth, in order:** the RTL, then https://nitrobotics.github.io/Wildbits/, then the old manual. Where the site and the RTL disagree, the RTL wins and the difference is recorded under Findings.
- **D4 RTL location (read only, never modified):** `~/projects/wild/fpga/fpga-6809-cores-staging`. Jr2 = `FNX6809_Jr2_Core2X`, K2 = `FNX6809_K2_Core2X_B0C`. The Verilog is shared in `source/`; each `.xpr` lists the files that core uses. Tops: `source/CFP95139AJR2_Top.v`, `source/CFP95139K2_Top.v`.
- **D5 Assembler:** lwtools (`lwasm`) for all examples. The user's native assembler, `las`, may replace it later.
- **D6 Two example sets:** `examples/raw/` (bare 6809, no OS) and `examples/nos9/` (NitrOS-9 programs). Most readers will use NitrOS-9, so chapters include NitrOS-9 notes where they apply.
- **D7 Raw skeleton:** a minimal raw 6809 starter program that readers copy to begin a project. It is based on the user's hardware-tested DMA tests in `~/projects/f256/jfed/dma`, cleaned up for the current map.
- **D8 Voice:** active voice, addressed to the reader ("Write `$81` to start the transfer"). No first person.
- **D9 Unverified facts:** marked with `\verify{}` in the source. Draft builds show them in red. The release build fails if any remain.
- **D10 Register data in one place:** register tables are generated from structured data, so Phase 2 (HTML and an on-machine text reference) can reuse it.

## Roadmap

### P0 Setup
- Macros for the Jr2 and K2, and `\verify{}`.
- Example layout (`examples/raw`, `examples/nos9`), with a makefile using lwasm.
- Register-data format and the generator for the LaTeX tables.
- Raw skeleton program (D7) that assembles and runs on a Jr2 and a K2.
- Retire the 6502 material: `kernel.tex`, the 6502 examples, the duplicate `f256jr_ref.tex`.

### P1 Foundations
- Introduction: the 6809, the Jr2/K2, NitrOS-9, lwasm notation, how to use the examples.
- Memory: MMU slots and LUTs, LUT entry encoding, FLASHDIS, constant RAM at `$FD00`, vector RAM, device blocks `$FC–$FF`, fixed I/O `$FE00–$FFFF`, the NitrOS-9 system map.
- Interrupts: the four groups, including the new group 3.

### P2 Existing chapters
For each chapter: check against the RTL, rewrite in active voice, add a raw example and a NitrOS-9 example, and have the user review it.

Text, Graphics, Bitmap (640×240×16), Sprites, Tiles, VICKY misc (line drawing, mouse pointer), Sound, Time, VIA, Controllers, SD card, Keyboard and mouse, UART, DMA, System control, IEC, Math (with the FPU), Debug, Expansion, Connectors (needs Jr2/K2 photos), Memory map appendix, References.

### P3 New chapters
Networking (WizFi360, W6100), VS1053b and MIDI, K2 RP2040 supervisor, HDMI I2C and the logo LCD, the boot process, programming under NitrOS-9.

### P4 Release
- No `\verify{}` left; every example builds; a final read-through.
- Tag v1.0 and publish the PDF.

### Phase 2 (later)
- HTML version.
- A small text-based reference to use on the machine.

## Findings

Differences between the site, the RTL and the old manual go here as they turn up.

- **F1 Loading raw programs (2026-10-10, from the RTL):** FoenixMgr `--boot ram` sends debug command $90, which makes the MMU reset slot 7 of LUT 0 to RAM block 7 instead of flash block $7F (`TyVKy2K2x1_MMU_Register.v`, `DebugModuleK2.v`/`DebugModuleJr.v`). It persists until a full system reset or `--boot flash`. Entering debug mode holds the CPU in reset; leaving it resets the CPU and MMU, so an upload restarts the CPU. With `$FFA1` bit 1 clear, the vectors at `$FFF0-$FFFF` come from the mapped block, so a raw program supplies its own reset vector at physical `$00FFFE`. Run `--boot ram` before uploading: the other order lets the flash boot run first, and it overwrites block 7.
- **F2 Reset state (RTL):** all interrupt sources masked, nothing pending, all edge-triggered (`IRQ_Controller_Jr.v`). `$FFC0` = $01 (text on), `$FFC1` = $00, border on at 16x16 and black (`TinyVickyControl_Registers.v`). The text color LUTs are loaded with the OS-9 palette at power-up.
- **F3 lwasm wrapper:** the `lwasm` in coco-shelf is a wrapper that always writes `.map`/`.list` files to the current directory. Stock lwtools does not do this. The examples' makefile takes `LWASM=` to choose which one runs.
- **F4 NitrOS-9 trees (2026-10-10):** the Longview core moved the device blocks from `$C0`–`$C4` to `$FC`–`$FF` (`TyVKy2K2x1_MMU_Register.v`: `MMU_Entry[7:2] == 6'b111111`). NitrOS-9 `main` (`~/projects/wild/main/nitros9`) has the new map: `VICKY_BLK` $FC, `FONT_BLK` $FD, `TEXT_RAM_BLK` $FE, `COLOR_RAM_BLK` $FF. The coco-shelf tree (branch `wizlink`) still uses `$C0`/`$C1`. The NitrOS-9 examples build against `NITROS9DIR`, and `examples/nos9/Makefile` refuses a tree without `VICKY_BLK`. Readers will need a released NitrOS-9 built for Longview, so the manual should name the minimum version once one exists.
- **F5 MMU details for the Memory chapter (2026-10-10, RTL and NitrOS-9 main):** physical RAM is blocks `$00`–`$FB` with FLASHDIS set (2,016 KB); with it clear, `$40`–`$7F` is flash and `$80`–`$9F` expansion, and `$A0`–`$FB` stay RAM. VICKY and DMA bypass the MMU. Device blocks: `$FC` (gamma `$0000`, mouse `$0C00`, bitmap `$1000`, tile `$1100`, memory-text `$1200`, sprites `$1300`–`$16FF`, text LUTs `$1700`/`$1740`), `$FD` (fonts `$0000`, graphics CLUTs `$1000`), `$FE`/`$FF` (text, 4,800 bytes each). Constant RAM (`$FD00`, 256 bytes) and vector RAM (16 bytes) are internal FPGA RAM shared by all LUTs. Reset sets only LUT 0 and clears `$FFA0`/`$FFA1`. The debug RAM-boot flag is cleared by the system reset request (cold-reset pin or software reset), not by a FoenixMgr upload. NitrOS-9 L2: LUT 0 = system, LUT 1 = running process (reloaded on task switch); the kernel sets FLASHDIS (read-modify-write after testing bit 7), CONST_RAM and VEC_RAM.
