#!/usr/bin/env python3
"""SAW031: neutralize EEEE Support Day overwrite without breaking StackMapTable.

Changes ifeq->goto breaks verification (Inconsistent stackmap frames at 708).
Instead, replace the two setAbERPSupportStartDay/EndDay invokevirtuals with
pop; pop; nop so the formatted weekday strings are discarded and days are left unchanged.
"""
import glob
import os
import shutil
import struct
import zipfile
from io import BytesIO

ORIG = "/opt/idempiere-server/plugins/com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar"
BAK = "/tmp/com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar.bak-pre-saw031"
OUT = "/tmp/com.aberp.servicebooking.generator_7.1.12.2026072203-saw031.jar"
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
    return cp


def find_methodref(cp, name_utf8: bytes):
    # Find NameAndType for name, then Methodref pointing to it
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


def main():
    src = BAK if os.path.exists(BAK) else ORIG
    if not os.path.exists(BAK) and os.path.exists(ORIG):
        shutil.copy2(ORIG, BAK)
        print("backed up to", BAK)
        src = BAK
    print("SRC=", src)

    with zipfile.ZipFile(src, "r") as z:
        data = bytearray(z.read(CLS))
        mf = z.read("META-INF/MANIFEST.MF").decode("utf-8")
        others = [(i, z.read(i.filename)) for i in z.infolist()]

    cp = parse_cp(data)
    start_refs = find_methodref(cp, b"setAbERPSupportStartDay")
    end_refs = find_methodref(cp, b"setAbERPSupportEndDay")
    print("setStart refs", start_refs, "setEnd refs", end_refs)
    if not start_refs or not end_refs:
        raise SystemExit("methodrefs not found")

    def patch_invokevirtual(ref_idx: int, label: str):
        pat = bytes([0xB6, (ref_idx >> 8) & 0xFF, ref_idx & 0xFF])  # invokevirtual
        # Only patch occurrences after EEEE ldc
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
            # already patched?
            if data[eeee_pos : eeee_pos + 80].find(b"\x57\x57\x00") >= 0:
                print(label, "already neutralized near EEEE")
                return
            raise SystemExit(f"{label} invokevirtual not found after EEEE")
        old = bytes(data[pos : pos + 3])
        # pop string, pop this, nop — stack-neutral vs invokevirtual void
        data[pos : pos + 3] = bytes([0x57, 0x57, 0x00])
        print(f"patched {label} at {pos}: {old.hex()} -> 575700")

    patch_invokevirtual(start_refs[0], "setAbERPSupportStartDay")
    patch_invokevirtual(end_refs[0], "setAbERPSupportEndDay")

    # Ensure any previous broken ifeq->goto patch is reverted if present in this buffer
    # (we read from BAK so should be clean)

    mf2 = mf.replace(
        "Bundle-Version: 7.1.12.202602251048",
        "Bundle-Version: 7.1.12.2026072203",
    )
    if "SAW031" not in mf2:
        mf2 = "AbERP-Note: SAW031 neutralize EEEE Support Day setters in beforeSave\n" + mf2

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
