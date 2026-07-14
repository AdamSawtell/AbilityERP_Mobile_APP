#!/usr/bin/env python3
"""Post-clone fixes for UnavailabilityPlanningInfoWindow.java."""
from pathlib import Path

JAVA = Path(
    r"C:\Users\sawte\Documents\Development\AbilityERP Mobile APP"
    r"\idempiere-plugins\com.aberp.unavailability.planning"
    r"\src\com\aberp\unavailability\planning\info"
    r"\UnavailabilityPlanningInfoWindow.java"
)

text = JAVA.read_text(encoding="utf-8")

# Catastrophic: zul became zou via ul→ou replace
text = text.replace("org.zkoss.zou", "org.zkoss.zul")

# Date-strip regexes must match AD alias ou (fromclause)
text = text.replace("ul\\.EndDate", "ou\\.EndDate")
text = text.replace("ul\\.StartDate", "ou\\.StartDate")

# Mojibake from leave source already-crunched punctuation
text = text.replace("ΓÇö", " - ")
text = text.replace("ΓåÆ", " to ")
text = text.replace("┬╖", "|")

# Remove Unavailability Type from summary (param unused → NULL)
old_sum = """\t\ttry {
\t\t\tBigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
\t\t\tString approver = toText(editorValue("AbERP_ApproverStatus"));
\t\t\tBigDecimal typeId = toId(editorValue("AbERP_Unavailability_Type_ID"));
\t\t\tBigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

\t\t\tString byStatus = DB.getSQLValueStringEx(null,
\t\t\t\t\t"SELECT aberp_up_info_summary_by_status(?, ?, ?, ?, ?, ?)",
\t\t\t\t\tstart, end, loc, approver, typeId, userId);
\t\t\tString byType = DB.getSQLValueStringEx(null,
\t\t\t\t\t"SELECT aberp_up_info_summary_by_type(?, ?, ?, ?, ?, ?)",
\t\t\t\t\tstart, end, loc, approver, typeId, userId);"""

new_sum = """\t\ttry {
\t\t\tBigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
\t\t\tString approver = toText(editorValue("AbERP_ApproverStatus"));
\t\t\tBigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

\t\t\tString byStatus = DB.getSQLValueStringEx(null,
\t\t\t\t\t"SELECT aberp_up_info_summary_by_status(?, ?, ?, ?, ?)",
\t\t\t\t\tstart, end, loc, approver, userId);
\t\t\tString byType = DB.getSQLValueStringEx(null,
\t\t\t\t\t"SELECT aberp_up_info_summary_day_lines(?, ?, ?, ?, ?)",
\t\t\t\t\tstart, end, loc, approver, userId);"""

if old_sum not in text:
    raise SystemExit("summary block not found")
text = text.replace(old_sum, new_sum)

old_exp = """\t\tBigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
\t\tString approver = toText(editorValue("AbERP_ApproverStatus"));
\t\tBigDecimal typeId = toId(editorValue("AbERP_Unavailability_Type_ID"));
\t\tBigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

\t\tString sql = "SELECT "
\t\t\t\t+ " CASE ou.AbERP_ApproverStatus WHEN 'RV' THEN 'Reviewing' WHEN 'AP' THEN 'Approved' WHEN 'DC' THEN 'Declined' ELSE COALESCE(ou.AbERP_ApproverStatus,'') END AS approver_status,"
\t\t\t\t+ " COALESCE(ut.Name,'') AS unavailability_type,"
\t\t\t\t+ " COALESCE(u.Name,'') AS employee,"
\t\t\t\t+ " COALESCE(" + SQL_SUPPORT_LOC_NAMES + ",'') AS service_location,"
\t\t\t\t+ " COALESCE(sup.Name,'') AS supervisor,"
\t\t\t\t+ " ou.StartDate::date AS start_date,"
\t\t\t\t+ " ou.EndDate::date AS end_date,"
\t\t\t\t+ " ((ou.EndDate::date - ou.StartDate::date) + 1) AS calendar_days,"
\t\t\t\t+ " COALESCE(ou.Note,'') AS note,"
\t\t\t\t+ " ou.Created AS created"
\t\t\t\t+ " FROM AbERP_OngoingUnavailability ou"
\t\t\t\t+ " INNER JOIN AD_User u ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)"
\t\t\t\t+ " LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)"
\t\t\t\t+ " LEFT JOIN AD_User sup ON (sup.AD_User_ID=bp.Supervisor_ID)"
\t\t\t\t+ " LEFT JOIN AbERP_Unavailability_Type ut ON (ut.AbERP_Unavailability_Type_ID=ou.AbERP_OngoingUnavailability_ID)"
\t\t\t\t+ " WHERE ou.IsActive='Y'"
\t\t\t\t+ " AND ou.EndDate::date >= ?::date"
\t\t\t\t+ " AND ou.StartDate::date <= ?::date"
\t\t\t\t+ " AND (?::numeric IS NULL OR EXISTS ("
\t\t\t\t+ "   SELECT 1 FROM AbERP_Rostered_ShiftStaff ss"
\t\t\t\t+ "   INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive='Y')"
\t\t\t\t+ "   INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)"
\t\t\t\t+ "   WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive='Y'"
\t\t\t\t+ "     AND ml.C_BPartner_Location_ID = ?::numeric))"
\t\t\t\t+ " AND (?::text IS NULL OR ?::text = '' OR ou.AbERP_ApproverStatus = ?::text)"
\t\t\t\t+ " AND (?::numeric IS NULL OR ou.AbERP_OngoingUnavailability_ID = ?::numeric)"
\t\t\t\t+ " AND (?::numeric IS NULL OR ou.AbERP_User_Contact_ID = ?::numeric)"
\t\t\t\t+ " ORDER BY CASE ou.AbERP_ApproverStatus WHEN 'DC' THEN 1 WHEN 'RV' THEN 2 WHEN 'AP' THEN 3 ELSE 9 END, ou.StartDate, u.Name";"""

new_exp = """\t\tBigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
\t\tString approver = toText(editorValue("AbERP_ApproverStatus"));
\t\tBigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

\t\tString sql = "SELECT "
\t\t\t\t+ " CASE ou.AbERP_ApproverStatus WHEN 'RV' THEN 'Reviewing' WHEN 'AP' THEN 'Approved' WHEN 'DC' THEN 'Declined' ELSE COALESCE(ou.AbERP_ApproverStatus,'') END AS approver_status,"
\t\t\t\t+ " COALESCE(u.Name,'') AS employee,"
\t\t\t\t+ " COALESCE(" + SQL_SUPPORT_LOC_NAMES + ",'') AS support_location,"
\t\t\t\t+ " COALESCE(sup.Name,'') AS supervisor,"
\t\t\t\t+ " ou.StartDate::date AS start_date,"
\t\t\t\t+ " ou.EndDate::date AS end_date,"
\t\t\t\t+ " ((ou.EndDate::date - ou.StartDate::date) + 1) AS calendar_days,"
\t\t\t\t+ " COALESCE(aberp_up_unavailable_pattern(ou.AbERP_OngoingUnavailability_ID),'') AS unavailable_pattern,"
\t\t\t\t+ " COALESCE(ou.Note,'') AS note,"
\t\t\t\t+ " ou.Created AS created"
\t\t\t\t+ " FROM AbERP_OngoingUnavailability ou"
\t\t\t\t+ " INNER JOIN AD_User u ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)"
\t\t\t\t+ " LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)"
\t\t\t\t+ " LEFT JOIN AD_User sup ON (sup.AD_User_ID=bp.Supervisor_ID)"
\t\t\t\t+ " WHERE ou.IsActive='Y'"
\t\t\t\t+ " AND ou.EndDate::date >= ?::date"
\t\t\t\t+ " AND ou.StartDate::date <= ?::date"
\t\t\t\t+ " AND (?::numeric IS NULL OR EXISTS ("
\t\t\t\t+ "   SELECT 1 FROM AbERP_Rostered_ShiftStaff ss"
\t\t\t\t+ "   INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive='Y')"
\t\t\t\t+ "   INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)"
\t\t\t\t+ "   WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive='Y'"
\t\t\t\t+ "     AND ml.C_BPartner_Location_ID = ?::numeric))"
\t\t\t\t+ " AND (?::text IS NULL OR ?::text = '' OR ou.AbERP_ApproverStatus = ?::text)"
\t\t\t\t+ " AND (?::numeric IS NULL OR ou.AbERP_User_Contact_ID = ?::numeric)"
\t\t\t\t+ " ORDER BY CASE ou.AbERP_ApproverStatus WHEN 'DC' THEN 1 WHEN 'RV' THEN 2 WHEN 'AP' THEN 3 ELSE 9 END, ou.StartDate, u.Name";"""

if old_exp not in text:
    raise SystemExit("export block not found")
text = text.replace(old_exp, new_exp)

old_bind = """\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setBigDecimal(i++, typeId);
\t\t\tpstmt.setBigDecimal(i++, typeId);
\t\t\tpstmt.setBigDecimal(i++, userId);
\t\t\tpstmt.setBigDecimal(i++, userId);"""

new_bind = """\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setString(i++, approver);
\t\t\tpstmt.setBigDecimal(i++, userId);
\t\t\tpstmt.setBigDecimal(i++, userId);"""

if old_bind not in text:
    raise SystemExit("bind block not found")
text = text.replace(old_bind, new_bind)

# Export file name
text = text.replace('UnavailabilityPlanning_"', 'UnavailabilityPlanning_')
# leave may have been LeavePlanning_ already transformed
text = text.replace(
    'String name = "UnavailabilityPlanning_" + fileDf.format(start) + "_" + fileDf.format(end) + ".csv";',
    'String name = "UnavailabilityPlanning_" + fileDf.format(start) + "_" + fileDf.format(end) + ".csv";',
)

JAVA.write_text(text, encoding="utf-8", newline="\n")
print("fixed", JAVA)
print("zou left:", text.count("org.zkoss.zou"))
print("ul\\\\. left:", text.count("ul\\."))
print("type_id editor:", "AbERP_Unavailability_Type_ID" in text)
