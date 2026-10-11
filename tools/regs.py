#!/usr/bin/env python3
"""Generate register tables and assembler equates from data/registers/*.toml.

Each TOML file describes one device: a title, a LaTeX label, and a list of
[[reg]] entries. A register has an address (or, with `block`, an offset into
that MMU block), a name, an access code, and optionally a size in bytes, a
reset value and bit fields. See data/registers/README.md for the format.

Outputs:
  tex/gen/<device>.tex                 register table for the manual
  tex/gen/<device>_fields.tex          description list of the bit fields
  examples/include/wildbits_regs.inc   lwasm equates for every register

Usage: python3 tools/regs.py [--check]   (--check validates without writing)
"""

import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "registers"
TEX_OUT = ROOT / "tex" / "gen"
INC_OUT = ROOT / "examples" / "include" / "wildbits_regs.inc"

ACCESS = {"R", "W", "RW"}


class DataError(Exception):
    pass


def parse_bits(spec, where):
    """Turn "5:4" or "7" into (high, low)."""
    parts = str(spec).split(":")
    try:
        nums = [int(p) for p in parts]
    except ValueError:
        raise DataError(f"{where}: bad bit range {spec!r}")
    high, low = (nums[0], nums[0]) if len(nums) == 1 else nums
    if not 0 <= low <= high <= 7:
        raise DataError(f"{where}: bit range {spec!r} is outside 7..0")
    return high, low


def load(path):
    with open(path, "rb") as f:
        dev = tomllib.load(f)
    name = path.stem
    for key in ("title", "label", "reg"):
        if key not in dev:
            raise DataError(f"{path.name}: missing {key!r}")
    block = dev.get("block")
    used = {}
    for reg in dev["reg"]:
        where = f"{path.name}: {reg.get('name', '?')}"
        for key in ("addr", "name", "access"):
            if key not in reg:
                raise DataError(f"{where}: missing {key!r}")
        if reg["access"] not in ACCESS:
            raise DataError(f"{where}: access must be one of {sorted(ACCESS)}")
        size = reg.get("size", 1)
        if reg.get("numbered") and (size < 2 or not reg["name"].endswith("_0")):
            raise DataError(f"{where}: numbered needs size > 1 and a name ending in _0")
        limit = 0x2000 if block is not None else 0x10000
        if not (0 <= reg["addr"] and reg["addr"] + size <= limit):
            raise DataError(f"{where}: address out of range")
        for a in range(reg["addr"], reg["addr"] + size):
            if a in used:
                raise DataError(f"{where}: overlaps {used[a]} at {a:#06x}")
            used[a] = reg["name"]
        taken = set()
        for field in reg.get("fields", []):
            fwhere = f"{where}.{field.get('name', '?')}"
            if size != 1:
                raise DataError(f"{fwhere}: bit fields need a one-byte register")
            high, low = parse_bits(field["bits"], fwhere)
            field["_range"] = (high, low)
            bits = set(range(low, high + 1))
            if bits & taken:
                raise DataError(f"{fwhere}: bits overlap another field")
            taken |= bits
            if field.get("access", reg["access"]) not in ACCESS:
                raise DataError(f"{fwhere}: bad access code")
    dev["reg"].sort(key=lambda r: r["addr"])
    dev["_name"] = name
    return dev


def tex_escape(text):
    out = []
    for ch in str(text):
        if ch in "_&%#":
            out.append("\\" + ch)
        elif ch == "$":
            out.append("\\$")
        else:
            out.append(ch)
    return "".join(out)


def hexaddr(value, digits=4):
    return f"${value:0{digits}X}"


def addr_text(dev, reg):
    size = reg.get("size", 1)
    first = hexaddr(reg["addr"])
    if size == 1:
        return f"\\verb+{first}+"
    last = hexaddr(reg["addr"] + size - 1)
    return f"\\verb+{first}+--\\verb+{last}+"


def display_name(reg):
    """NAME_0 of a numbered register shows as NAME_0–n (one register per byte)."""
    if reg.get("numbered"):
        return f"{reg['name']}–{reg['size'] - 1}"
    return reg["name"]


def equate_names(reg):
    """(name, address) for each equate: one per byte for a numbered register."""
    if reg.get("numbered"):
        base = reg["name"][:-1]
        return [(f"{base}{i}", reg["addr"] + i) for i in range(reg["size"])]
    return [(reg["name"], reg["addr"])]


def mark(text, verified):
    return text if verified else f"\\verify{{{text}}}"


def bit_cells(reg):
    """The eight bit cells for one register, from bit 7 down to bit 0."""
    fields = sorted(reg.get("fields", []), key=lambda f: -f["_range"][0])
    cells = []
    bit = 7
    for field in fields + [None]:
        high = field["_range"][0] if field else -1
        if bit > high:  # unused bits before this field
            span = bit - high
            cells.append(span_cell(span, "---"))
            bit = high
        if field:
            high, low = field["_range"]
            name = breakable(tex_escape(field["name"]))
            name = mark(name, field.get("verified", reg.get("verified", False)))
            cells.append(span_cell(high - low + 1, name))
            bit = low - 1
    return cells


def span_cell(span, text):
    """A cell covering `span` bit columns (\\bitspan is defined in the manual's preamble)."""
    return f"\\bitspan{{{span}}}{{{text}}}"


def breakable(text):
    """Let LaTeX wrap long field names after underscores in the narrow bit columns."""
    return text.replace("\\_", "\\_\\allowbreak{}")


ACCESS_TEXT = {"R": "read-only", "W": "write-only", "RW": "read/write"}


def write_table(dev, out):
    block = dev.get("block")
    head = "Offset" if block is not None else "Address"
    lines = [
        "% Generated by tools/regs.py from data/registers/"
        f"{dev['_name']}.toml. Do not edit.",
        "\\begin{table}[ht]",
        "    \\begin{center}",
        "        \\setlength{\\tabcolsep}{3pt}",
        "        \\begin{tabular}{|c|l|" + "B" * 8 + "} \\hline",
        f"            {head} & Name & " + " & ".join(str(b) for b in range(7, -1, -1))
        + " \\\\ \\hline\\hline",
    ]
    for reg in dev["reg"]:
        verified = reg.get("verified", False)
        row = [addr_text(dev, reg), mark(breakable(tex_escape(display_name(reg))), verified)]
        if reg.get("fields"):
            row += bit_cells(reg)
        else:
            row.append(span_cell(8, tex_escape(reg.get("cell", reg["name"]))))
        lines.append("            " + " & ".join(row) + " \\\\ \\hline")
    caption = tex_escape(dev["title"])
    if block is not None:
        caption += f" (offsets in block \\verb+{hexaddr(block, 2)}+)"
    lines += [
        "        \\end{tabular}",
        "    \\end{center}",
        f"    \\caption{{{caption}}}",
        f"    \\label{{{dev['label']}}}",
        "\\end{table}",
    ]
    out.write_text("\n".join(lines) + "\n")


def write_fields(dev, out):
    """One entry per register (address, access, reset value, purpose), then its fields."""
    lines = [
        "% Generated by tools/regs.py from data/registers/"
        f"{dev['_name']}.toml. Do not edit.",
        "\\begin{description}",
    ]
    for reg in dev["reg"]:
        verified = reg.get("verified", False)
        facts = [addr_text(dev, reg), ACCESS_TEXT[reg["access"]]]
        if "reset" in reg:
            facts.append(f"reset \\verb+{hexaddr(reg['reset'], 2)}+")
        name = mark(tex_escape(display_name(reg)), verified)
        lines.append(f"    \\item[{name}] ({', '.join(facts)}) {tex_escape(reg.get('desc', ''))}")
        if reg.get("fields"):
            lines.append("    \\begin{description}")
            for field in reg["fields"]:
                high, low = field["_range"]
                bits = f"bit {high}" if high == low else f"bits {high}--{low}"
                fname = mark(tex_escape(field["name"]), field.get("verified", verified))
                access = field.get("access", reg["access"])
                extra = f", {ACCESS_TEXT[access]}" if access != reg["access"] else ""
                lines.append(f"        \\item[{fname}] ({bits}{extra}) {tex_escape(field.get('desc', ''))}")
            lines.append("    \\end{description}")
    lines.append("\\end{description}")
    out.write_text("\n".join(lines) + "\n")


def write_equates(devices, out):
    lines = [
        "* wildbits_regs.inc - register addresses for the Wildbits Jr2 and K2",
        "* Generated by tools/regs.py from data/registers/*.toml. Do not edit.",
    ]
    for dev in devices:
        block = dev.get("block")
        lines.append("")
        where = f" (offsets in block {hexaddr(block, 2)})" if block is not None else ""
        lines.append(f"* {dev['title']}{where}")
        for reg in dev["reg"]:
            note = "" if reg.get("verified", False) else "  ; not yet checked against the RTL"
            for name, addr in equate_names(reg):
                lines.append(f"{name:<20}equ     {hexaddr(addr)}{note}")
    out.write_text("\n".join(lines) + "\n")


def main():
    check_only = "--check" in sys.argv[1:]
    try:
        devices = [load(p) for p in sorted(DATA.glob("*.toml"))]
    except (DataError, tomllib.TOMLDecodeError) as err:
        sys.exit(f"regs.py: {err}")
    if check_only:
        print(f"regs.py: {len(devices)} device file(s) OK")
        return
    TEX_OUT.mkdir(parents=True, exist_ok=True)
    INC_OUT.parent.mkdir(parents=True, exist_ok=True)
    for dev in devices:
        write_table(dev, TEX_OUT / f"{dev['_name']}.tex")
        write_fields(dev, TEX_OUT / f"{dev['_name']}_fields.tex")
    write_equates(devices, INC_OUT)
    print(f"regs.py: wrote tables for {len(devices)} device file(s) and {INC_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
