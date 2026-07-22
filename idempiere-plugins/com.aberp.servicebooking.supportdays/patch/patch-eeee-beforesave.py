#!/usr/bin/env python3
"""SAW031: neutralize EEEE Support Day overwrite without breaking StackMapTable.

1) In beforeSave: replace setAbERPSupportStartDay/EndDay invokevirtuals after EEEE
   with pop; pop; nop (stack-neutral).
2) Replace setAbERPSupportStartDay/EndDay method bodies with a single return
   so any remaining callers cannot write weekday names through the typed setters.
"""
import os
import shutil
import struct
import zipfile
from io import BytesIO

ORIG = "/opt/idempiere-server/plugins/com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar"
BAK = "/tmp/com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar.bak-pre-saw031"
# Prefer backup; also allow patching from current saw031 jar if bak missing
OUT = "/tmp/com.aberp.servicebooking.generator_7.1.12.2026072204-saw031.jar"
CLS = "com/aberp/servicebooking/generator/model/MOrderLineAbERP.class"


def parse_cp(buf: bytes):
    b = BytesIO(buf)
    b.read(8)
    cp_count = struct.unpack(">H", b.read(2))[0]
    cp = [None]
    i = 1
    while i < cp_count:
        tag = b.read(1)[0]
        if tag == 1:
            ln = struct.unpack(">H", b.read(2))[0]
            cp.append(("Utf8", b.read(ln)))
        elif tag in (7, 8, 16, 19, 20):
            cp.append((tag, b.read(2)))
        elif tag in (3, 4, 9, 10, 11, 12, 17, 18):
            cp.append((tag, b.read(4)))
        elif tag in (5, 6):
            cp.append((tag, b.read(8)))
            i += 1
            cp.append(None)
        elif tag == 15:
            cp.append((tag, b.read(3)))
        else:
            raise SystemExit(f"unknown cp tag {tag} at {i}")
        i += 1
    return cp, b.tell()


def find_methodref(cp, name_utf8: bytes):
    nat_idxs = []
    for i, e in enumerate(cp):
        if e and e[0] == 12:  # NameAndType
            name_i = struct.unpack(">H", e[1][:2])[0]
            if cp[name_i] and cp[name_i][0] == "Utf8" and cp[name_i][1] == name_utf8:
                nat_idxs.append(i)
    refs = []
    for i, e in enumerate(cp):
        if e and e[0] == 10:  # Methodref
            nat = struct.unpack(">H", e[1][2:4])[0]
            if nat in nat_idxs:
                refs.append(i)
    return refs


def find_methods(data: bytearray, cp, cp_end: int):
    """Return list of (name, code_abs_start, code_length_offset, code_bytes_offset)."""
    b = BytesIO(data)
    b.seek(cp_end)
    b.read(2)  # access
    b.read(2)  # this
    b.read(2)  # super
    iface_count = struct.unpack(">H", b.read(2))[0]
    b.read(2 * iface_count)
    field_count = struct.unpack(">H", b.read(2))[0]
    for _ in range(field_count):
        b.read(6)
        attr_count = struct.unpack(">H", b.read(2))[0]
        for _ in range(attr_count):
            b.read(2)
            ln = struct.unpack(">I", b.read(4))[0]
            b.read(ln)
    method_count = struct.unpack(">H", b.read(2))[0]
    methods = []
    for _ in range(method_count):
        b.read(2)  # access
        name_i = struct.unpack(">H", b.read(2))[0]
        desc_i = struct.unpack(">H", b.read(2))[0]
        name = cp[name_i][1] if cp[name_i] and cp[name_i][0] == "Utf8" else b"?"
        attr_count = struct.unpack(">H", b.read(2))[0]
        for _ in range(attr_count):
            an_i = struct.unpack(">H", b.read(2))[0]
            an = cp[an_i][1] if cp[an_i] and cp[an_i][0] == "Utf8" else b""
            alen = struct.unpack(">I", b.read(4))[0]
            attr_start = b.tell()
            if an == b"Code":
                # max_stack u2, max_locals u2, code_length u4, code[], ...
                code_len_off = attr_start + 4
                code_off = attr_start + 8
                code_len = struct.unpack(">I", data[code_len_off : code_len_off + 4])[0]
                methods.append((name, code_off, code_len_off, code_len))
            b.read(alen)
    return methods


def nop_setter(data: bytearray, code_off: int, code_len: int, label: str):
    """No-op typed setter by replacing invokevirtual set_Value; pop with pop;pop;pop;nop."""
    code = bytes(data[code_off : code_off + code_len])
    pos = code.find(b"\xb6")
    if pos < 0 or pos + 5 > code_len:
        raise SystemExit(f"{label}: invokevirtual not found in setter")
    if code[pos : pos + 4] == b"\x57\x57\x57\x00":
        print(label, "setter already no-op")
        return
    if code[pos + 3] != 0x57 or code[pos + 4] != 0xB1:
        raise SystemExit(f"{label}: unexpected setter pattern {code[pos:pos+5].hex()}")
    abs_pos = code_off + pos
    data[abs_pos : abs_pos + 4] = bytes([0x57, 0x57, 0x57, 0x00])
    print(f"{label}: no-op setter at {abs_pos}")


def main():
    src = BAK if os.path.exists(BAK) else ORIG
    if not os.path.exists(src):
        # fall back to current plugins jar
        cands = [
            "/opt/idempiere-server/plugins/com.aberp.servicebooking.generator_7.1.12.2026072203-saw031.jar",
            "/opt/idempiere-server/customization-jar/com.aberp.servicebooking.generator_7.1.12.2026072203-saw031.jar",
        ]
        for c in cands:
            if os.path.exists(c):
                src = c
                break
    if not os.path.exists(BAK) and os.path.exists(ORIG):
        shutil.copy2(ORIG, BAK)
        print("backed up to", BAK)
        src = BAK
    print("SRC=", src)

    with zipfile.ZipFile(src, "r") as z:
        data = bytearray(z.read(CLS))
        mf = z.read("META-INF/MANIFEST.MF").decode("utf-8")
        others = [(i, z.read(i.filename)) for i in z.infolist()]

    cp, cp_end = parse_cp(data)
    start_refs = find_methodref(cp, b"setAbERPSupportStartDay")
    end_refs = find_methodref(cp, b"setAbERPSupportEndDay")
    print("setStart refs", start_refs, "setEnd refs", end_refs)
    if not start_refs or not end_refs:
        raise SystemExit("methodrefs not found")

    def patch_invokevirtual(ref_idx: int, label: str):
        pat = bytes([0xB6, (ref_idx >> 8) & 0xFF, ref_idx & 0xFF])
        eeee_idx = next(i for i, e in enumerate(cp) if e and e[0] == "Utf8" and e[1] == b"EEEE")
        string_idx = next(
            i for i, e in enumerate(cp) if e and e[0] == 8 and struct.unpack(">H", e[1])[0] == eeee_idx
        )
        ldc = bytes([0x13, (string_idx >> 8) & 0xFF, string_idx & 0xFF])
        eeee_pos = data.find(ldc)
        if eeee_pos < 0:
            raise SystemExit("EEEE ldc not found")
        pos = data.find(pat, eeee_pos)
        if pos < 0:
            if data[eeee_pos : eeee_pos + 80].find(b"\x57\x57\x00") >= 0:
                print(label, "already neutralized near EEEE")
                return
            raise SystemExit(f"{label} invokevirtual not found after EEEE")
        old = bytes(data[pos : pos + 3])
        data[pos : pos + 3] = bytes([0x57, 0x57, 0x00])
        print(f"patched {label} at {pos}: {old.hex()} -> 575700")

    patch_invokevirtual(start_refs[0], "setAbERPSupportStartDay")
    patch_invokevirtual(end_refs[0], "setAbERPSupportEndDay")

    # No-op typed setters (GridTab uses set_Value; beforeSave used these)
    methods = find_methods(data, cp, cp_end)
    for name, code_off, code_len_off, code_len in methods:
        if name in (b"setAbERPSupportStartDay", b"setAbERPSupportEndDay"):
            nop_setter(data, code_off, code_len, name.decode())

    mf2 = mf
    for oldv, newv in [
        ("Bundle-Version: 7.1.12.202602251048", "Bundle-Version: 7.1.12.2026072204"),
        ("Bundle-Version: 7.1.12.2026072203", "Bundle-Version: 7.1.12.2026072204"),
    ]:
        mf2 = mf2.replace(oldv, newv)
    if "SAW031" not in mf2:
        mf2 = "AbERP-Note: SAW031 neutralize EEEE Support Day setters in beforeSave\n" + mf2
    elif "2026072204" not in mf2:
        mf2 = "AbERP-Note: SAW031 also no-op Support Day typed setters\n" + mf2

    with zipfile.ZipFile(OUT, "w") as zout:
        for info, content in others:
            if info.filename == CLS:
                content = bytes(data)
            elif info.filename == "META-INF/MANIFEST.MF":
                content = mf2.encode("utf-8")
            zout.writestr(info, content)
    print("Wrote", OUT)


if __name__ == "__main__":
    main()
