#!/usr/bin/env python3
"""Clone SAW016 leave.planning plugin into SAW021 unavailability.planning."""
from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "idempiere-plugins" / "com.aberp.leave.planning"
DST = ROOT / "idempiere-plugins" / "com.aberp.unavailability.planning"

KEEP = [
    "build.sh",
    "deploy.sh",
    "META-INF/MANIFEST.MF",
    "leaveplanning-info.xml",
    "src/com/aberp/leave/planning/factory/LeavePlanningInfoFactory.java",
    "src/com/aberp/leave/planning/info/LeavePlanningInfoWindow.java",
]


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    if len(raw) > 3 and raw[1] == 0 and raw[3] == 0:
        return raw.decode("utf-16-le")
    return raw.decode("utf-8")


def dest_rel(rel: str) -> str:
    return (
        rel.replace("leave/planning", "unavailability/planning")
        .replace("LeavePlanning", "UnavailabilityPlanning")
        .replace("leaveplanning-info.xml", "unavailabilityplanning-info.xml")
    )


def transform(text: str) -> str:
    reps = [
        ("com.aberp.leave.planning", "com.aberp.unavailability.planning"),
        ("LeavePlanningInfoWindow", "UnavailabilityPlanningInfoWindow"),
        ("LeavePlanningInfoFactory", "UnavailabilityPlanningInfoFactory"),
        ("Leave Planning", "Unavailability Planning"),
        ("leave planning", "unavailability planning"),
        ("LeavePlanning", "UnavailabilityPlanning"),
        ("leaveplanning-info.xml", "unavailabilityplanning-info.xml"),
        ("16a016iw-c0d4-4f01-8e15-000000000001", "21a021iw-c0d4-4f01-8e15-000000000001"),
        ("AbERP_Unavailability_Leave_ID", "AbERP_OngoingUnavailability_ID"),
        ("AbERP_Unavailability_Leave", "AbERP_OngoingUnavailability"),
        ("aberp_unavailability_leave", "aberp_ongoingunavailability"),
        (" JOIN AD_User u ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)",
         " JOIN AD_User u ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)"),
        (" JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id",
         " JOIN ad_user u ON u.ad_user_id = ou.aberp_user_contact_id"),
        (" ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)",
         " ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)"),
        (" FROM AbERP_OngoingUnavailability ul", " FROM AbERP_OngoingUnavailability ou"),
        (" FROM aberp_ongoingunavailability ul", " FROM aberp_ongoingunavailability ou"),
        ("ul.AbERP_ApproverStatus", "ou.AbERP_ApproverStatus"),
        ("ul.AbERP_User_Contact_ID", "ou.AbERP_User_Contact_ID"),
        ("ul.AbERP_SubmitterStatus", "ou.AbERP_SubmitterStatus"),
        ("ul.AbERP_Unavailability_Type_ID", "ou.AbERP_OngoingUnavailability_ID"),
        ("ul.StartDate", "ou.StartDate"),
        ("ul.EndDate", "ou.EndDate"),
        ("ul.Note", "ou.Note"),
        ("ul.Created", "ou.Created"),
        ("ul.Updated", "ou.Updated"),
        ("ul.IsActive", "ou.IsActive"),
        ("ul.aberp_approverstatus", "ou.aberp_approverstatus"),
        ("ul.aberp_user_contact_id", "ou.aberp_user_contact_id"),
        ("ul.aberp_unavailability_type_id", "NULL"),
        ("ul.aberp_submitterstatus", "ou.aberp_submitterstatus"),
        ("ul.startdate", "ou.startdate"),
        ("ul.enddate", "ou.enddate"),
        ("ul.note", "ou.note"),
        ("ul.created", "ou.created"),
        ("ul.updated", "ou.updated"),
        ("ul.isactive", "ou.isactive"),
        # leftover ul. alias in SQL fragments
        (" ul ", " ou "),
        ("(ul.", "(ou."),
        ("ul.", "ou."),
        ("aberp_lp_", "aberp_up_"),
        ("Leave Start", "Start"),
        ("Leave End", "End"),
        ("leave_start", "start_date"),
        ("leave_end", "end_date"),
        ("leave rows", "unavailability rows"),
        ("leave row", "unavailability row"),
        ("matching leave", "matching unavailability"),
        ("No matching leave", "No matching unavailability"),
        ("By status / type:", "Day lines:"),
        ("OnLeavePlanningColour", "OnUnavailabilityPlanningColour"),
        ("onLeavePlanningColour", "onUnavailabilityPlanningColour"),
        ("AbERP Leave Planning", "AbERP Unavailability Planning"),
        ('SYMBOLIC="com.aberp.leave.planning"',
         'SYMBOLIC="com.aberp.unavailability.planning"'),
        ("/opt/idempiere-server/AbERP/com.aberp.leave.planning",
         "/opt/idempiere-server/AbERP/com.aberp.unavailability.planning"),
        ("1.0.0.2026071408", "1.0.0.2026071401"),
        ("1.0.0.2026071402", "1.0.0.2026071401"),
    ]
    for a, b in reps:
        text = text.replace(a, b)
    # Repair over-aggressive ul→ou replacements on English words if any
    text = text.replace("resoourt", "result")  # safety no-op unlikely
    return text


def main() -> None:
    if DST.exists():
        shutil.rmtree(DST)
    DST.mkdir(parents=True)
    for rel in KEEP:
        s = SRC / rel
        if not s.exists():
            raise SystemExit(f"missing source file: {rel}")
        d = DST / dest_rel(rel)
        d.parent.mkdir(parents=True, exist_ok=True)
        text = transform(read_text(s))
        d.write_text(text, encoding="utf-8", newline="\n")
        print(f"wrote {d.relative_to(DST)} ({len(text)} chars)")
    print("OK", DST)


if __name__ == "__main__":
    main()
