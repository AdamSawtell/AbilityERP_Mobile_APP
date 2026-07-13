#!/usr/bin/env python3
import os, zipfile
needles = (
    "GenerateBookings",
    "GenerateTimesheets",
    "GenerateShifts",
    "servicebooking/generator",
    "com/aberp/process/",
)
for d in ["/opt/idempiere-server/customization-jar", "/opt/idempiere-server/plugins"]:
    if not os.path.isdir(d):
        continue
    for name in sorted(os.listdir(d)):
        if not name.endswith(".jar"):
            continue
        path = os.path.join(d, name)
        try:
            z = zipfile.ZipFile(path)
        except Exception:
            continue
        matched = [n for n in z.namelist() if any(x in n for x in needles)]
        if matched:
            print("JAR", path)
            for n in matched[:50]:
                print(" ", n)
print("DONE")
