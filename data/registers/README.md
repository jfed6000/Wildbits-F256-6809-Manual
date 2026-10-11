# Register data

Each `.toml` file here describes the registers of one device. `tools/regs.py` turns these files into the manual's register tables and the assembler equates, so a register's address and bit layout are written down in one place only. The HTML version and the on-machine reference will be generated from the same files later.

Run `make regs` (or `python3 tools/regs.py`) after changing a file. `python3 tools/regs.py --check` only validates.

## Outputs

| File | Contents |
|---|---|
| `tex/gen/<device>.tex` | The register table. `\input` it in a chapter. |
| `tex/gen/<device>_fields.tex` | A description list: each register's address, access and reset value, then its bit fields. |
| `examples/include/wildbits_regs.inc` | `equ` lines for every register, for lwasm. |

The generated files are committed so that readers can use them without running Python. Don't edit them by hand.

## Format

```toml
title    = "MMU registers"          # table caption
label    = "tab:mmu_registers"      # LaTeX label
machines = ["Jr2", "K2"]            # which boards have this device
rtl      = "TyVKy2K2x1_MMU_Register.v"   # where the registers were checked
# block  = 0xFC                     # only for registers inside an MMU block:
                                    # addresses are then offsets in that block

[[reg]]
addr     = 0xFFA1                   # CPU address, or offset if `block` is set
name     = "MMU_IO_CTRL"            # also the equate name
access   = "RW"                     # R, W or RW
reset    = 0x00                     # optional
size     = 1                        # optional, bytes (default 1)
# numbered = true                   # with size > 1 and a name ending in _0: one register
                                    # per byte, NAME_0 ... NAME_<size-1>
verified = true                     # checked against the RTL? false shows in red
cell     = "Block number"           # optional: text for a register without fields
desc     = "Plain-text description."
fields = [
  { bits = "7", name = "FLASHDIS_OK", access = "R", desc = "..." },
  { bits = "2:0", name = "MODE", desc = "..." },
]
```

- **Descriptions are plain text, not LaTeX.** Write `$FFA0`, `EDIT_LUT` and `0–3` (with an en dash). The generator escapes them for LaTeX, and the HTML and text outputs will use them as they are.
- **`verified`:** set it to `true` only after checking the register against the RTL. Anything unverified is wrapped in `\verify{}`, so it shows in red in drafts and stops a release build. A field can override its register's value.
- **`fields`:** only for one-byte registers. Bits must be 7–0 and must not overlap. Unused bits show as "---".
- **Multi-byte values** (counters, addresses): one entry with `size`, and the byte order stated in `desc`.
- **Runs of identical registers** (the MMU slots, the interrupt masks): one entry with `size` and `numbered = true`. The table shows `NAME_0–7`, and the equates file gets `NAME_0` to `NAME_7`.
