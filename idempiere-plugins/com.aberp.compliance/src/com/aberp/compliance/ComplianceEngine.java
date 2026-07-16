package com.aberp.compliance;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.UUID;
import java.util.logging.Level;

import org.compiere.model.MSequence;
import org.compiere.model.MTable;
import org.compiere.util.CLogger;
import org.compiere.util.DB;
import org.compiere.util.Env;

/**
 * SAW023 — evaluate compliance rules and write results + category snapshots.
 */
public class ComplianceEngine {

	private static final CLogger log = CLogger.getCLogger(ComplianceEngine.class);

	// Employee (W)
	public static final String RULE_UU_EXPIRED = "23a02350-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_30D = "23a02351-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_SCREENING = "23a02352-c0d4-4f01-8e15-000000000001";
	// Client (P)
	public static final String RULE_UU_RISK = "23a02353-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_SA = "23a02354-c0d4-4f01-8e15-000000000001";
	// Incidents (I)
	public static final String RULE_UU_INC_OVERDUE = "23a02355-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_INC_ACTIONS = "23a02356-c0d4-4f01-8e15-000000000001";
	// Rostering (R)
	public static final String RULE_UU_UNFILLED = "23a02357-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_CRED_NEED = "23a02358-c0d4-4f01-8e15-000000000001";
	// Documentation (D)
	public static final String RULE_UU_ONBOARD_DOC = "23a02359-c0d4-4f01-8e15-000000000001";

	private static final String[] ALL_RULE_UUS = {
			RULE_UU_EXPIRED, RULE_UU_30D, RULE_UU_SCREENING,
			RULE_UU_RISK, RULE_UU_SA,
			RULE_UU_INC_OVERDUE, RULE_UU_INC_ACTIONS,
			RULE_UU_UNFILLED, RULE_UU_CRED_NEED,
			RULE_UU_ONBOARD_DOC
	};

	private final Properties ctx;
	private final String trxName;
	private final int clientId;
	private final int userId;
	private final List<String> logs = new ArrayList<>();

	public ComplianceEngine(Properties ctx, String trxName) {
		this.ctx = ctx;
		this.trxName = trxName;
		this.clientId = Env.getAD_Client_ID(ctx);
		this.userId = Env.getAD_User_ID(ctx);
	}

	public List<String> getLogs() {
		return logs;
	}

	public String refresh() {
		if (clientId <= 0) {
			throw new IllegalStateException("SAW023: Refresh requires a client context");
		}
		ensureRulesPresent();
		deactivateOpenResults(allRuleIds());

		Timestamp asAt = new Timestamp(System.currentTimeMillis());
		StringBuilder summary = new StringBuilder();

		summary.append(evalEmployee(asAt)).append("; ");
		summary.append(evalClient(asAt)).append("; ");
		summary.append(evalIncidents(asAt)).append("; ");
		summary.append(evalRostering(asAt)).append("; ");
		summary.append(evalDocumentation(asAt));

		logs.add(0, summary.toString());
		return summary.toString();
	}

	private String evalEmployee(Timestamp asAt) {
		int tableId = tableId("AbERP_CredentialAssignment");
		int days = daysBefore(ruleId(RULE_UU_30D), 30);
		int nExpired = insertFindings(ruleId(RULE_UU_EXPIRED), tableId, asAt, "NC", "HIGH",
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ " AND NOT (c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%')",
				"Credential expired: %s (expiry %s)");
		int n30 = insertFindings(ruleId(RULE_UU_30D), tableId, asAt, "WARN", "MED",
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL"
						+ " AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days,
				"Credential expires within " + days + " days: %s (expiry %s)");
		int nScreen = insertFindings(ruleId(RULE_UU_SCREENING), tableId, asAt, "CRIT", "CRIT",
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ " AND (c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%')",
				"Worker screening expired: %s (expiry %s)");

		SnapshotStats stats = computeBucketStats(
				"SELECT CASE"
						+ " WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ "      AND (c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%') THEN 'CRIT'"
						+ " WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE THEN 'NC'"
						+ " WHEN ca.aberp_expirydate IS NOT NULL"
						+ "      AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days + " THEN 'WARN'"
						+ " ELSE 'C' END"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'");
		stats.population = countActiveEmployees();
		writeCategorySnapshot(asAt, "W", stats);
		String msg = String.format("W expired=%d 30d=%d screening=%d score=%s %s",
				nExpired, n30, nScreen, stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private String evalClient(Timestamp asAt) {
		int riskTable = tableId("AbERP_Risks");
		int nRisk = insertFindings(ruleId(RULE_UU_RISK), riskTable, asAt, "NC", "HIGH",
				"SELECT r.aberp_risks_id, r.ad_org_id, NULL::numeric, r.validto,"
						+ " COALESCE(r.aberp_risk_description, 'Risk '||r.aberp_risks_id::text)"
						+ " FROM aberp_risks r"
						+ " WHERE r.ad_client_id=? AND r.isactive='Y'"
						+ " AND r.validto IS NOT NULL AND r.validto::date < CURRENT_DATE",
				"Risk assessment overdue: %s (valid to %s)",
				true);

		int saCount = DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_service_agreement WHERE ad_client_id=? AND isactive='Y'",
				clientId);
		int nSa = 0;
		if (saCount <= 0) {
			logs.add("P Missing Service Agreement skipped (no active agreements for client)");
		} else {
			logs.add("P Missing Service Agreement: date model incomplete — skipped (" + saCount + " rows)");
		}

		SnapshotStats stats = computeBucketStats(
				"SELECT CASE WHEN r.validto IS NOT NULL AND r.validto::date < CURRENT_DATE THEN 'NC' ELSE 'C' END"
						+ " FROM aberp_risks r WHERE r.ad_client_id=? AND r.isactive='Y'");
		stats.population = countActiveClients();
		writeCategorySnapshot(asAt, "P", stats);
		String msg = String.format("P risk_overdue=%d sa_skipped=%d score=%s %s",
				nRisk, nSa, stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private String evalIncidents(Timestamp asAt) {
		int incTable = tableId("AbERP_Incident");
		int nOverdue = insertFindings(ruleId(RULE_UU_INC_OVERDUE), incTable, asAt, "NC", "HIGH",
				"SELECT i.aberp_incident_id, i.ad_org_id, NULL::numeric, i.aberp_duedate,"
						+ " COALESCE(i.documentno, i.description, 'Incident '||i.aberp_incident_id::text)"
						+ " FROM aberp_incident i"
						+ " LEFT JOIN aberp_incident_status s ON s.aberp_incident_status_id = i.aberp_incident_status_id"
						+ " WHERE i.ad_client_id=? AND i.isactive='Y'"
						+ " AND i.aberp_duedate IS NOT NULL AND i.aberp_duedate::date < CURRENT_DATE"
						+ " AND COALESCE(s.name,'') NOT ILIKE '%closed%'",
				"Incident investigation overdue: %s (due %s)",
				true);

		int actTable = tableIdOptional("HCO_Incident_Actions");
		int nAct = 0;
		if (actTable > 0) {
			nAct = insertFindings(ruleId(RULE_UU_INC_ACTIONS), actTable, asAt, "WARN", "MED",
					"SELECT a.hco_incident_actions_id, a.ad_org_id, NULL::numeric, a.enddate,"
							+ " COALESCE(a.name, a.description, 'Action '||a.hco_incident_actions_id::text)"
							+ " FROM hco_incident_actions a"
							+ " WHERE a.ad_client_id=? AND a.isactive='Y'"
							+ " AND COALESCE(a.iscomplete,'N')='N'",
					"Outstanding incident action: %s (end %s)",
					true);
		} else {
			logs.add("I Outstanding actions skipped (HCO_Incident_Actions missing)");
		}

		SnapshotStats stats = new SnapshotStats();
		stats.total = Math.max(1, nOverdue + nAct);
		stats.nonCompliant = nOverdue;
		stats.warning = nAct;
		stats.critical = 0;
		stats.compliant = Math.max(0, stats.total - stats.nonCompliant - stats.warning);
		finalizeStats(stats);
		stats.population = countActiveIncidents();
		writeCategorySnapshot(asAt, "I", stats);
		String msg = String.format("I overdue=%d open_actions=%d score=%s %s",
				nOverdue, nAct, stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private String evalRostering(Timestamp asAt) {
		int days = daysBefore(ruleId(RULE_UU_UNFILLED), 14);
		int shiftTable = tableId("AbERP_Rostered_Shift");
		int nUnfilled = insertFindings(ruleId(RULE_UU_UNFILLED), shiftTable, asAt, "CRIT", "CRIT",
				"SELECT s.aberp_rostered_shift_id, s.ad_org_id, NULL::numeric, s.startdate,"
						+ " COALESCE(s.documentno, 'Shift '||s.aberp_rostered_shift_id::text)"
						+ " FROM aberp_rostered_shift s"
						+ " WHERE s.ad_client_id=? AND s.isactive='Y'"
						+ " AND s.startdate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days
						+ " AND NOT EXISTS ("
						+ "   SELECT 1 FROM aberp_rostered_shiftstaff ss"
						+ "   WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id"
						+ "     AND ss.isactive='Y' AND COALESCE(ss.aberp_user_contact_id,0) > 0"
						+ " )",
				"Upcoming shift unfilled: %s (start %s)",
				true);

		int staffTable = tableId("AbERP_Rostered_ShiftStaff");
		int nCred = insertFindings(ruleId(RULE_UU_CRED_NEED), staffTable, asAt, "NC", "HIGH",
				"SELECT ss.aberp_rostered_shiftstaff_id, ss.ad_org_id, ss.aberp_user_contact_id, s.startdate,"
						+ " COALESCE(c.name, 'Credential '||rv.aberp_credentials_id::text)"
						+ " FROM aberp_rostered_shiftstaff ss"
						+ " JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id"
						+ " JOIN aberp_related_rostering_needs_v rv ON rv.aberp_rostered_shift_id = s.aberp_rostered_shift_id"
						+ " LEFT JOIN aberp_credentials c ON c.aberp_credentials_id = rv.aberp_credentials_id"
						+ " WHERE s.ad_client_id=? AND s.isactive='Y' AND ss.isactive='Y'"
						+ " AND s.startdate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days
						+ " AND rv.aberp_needtype='CRD' AND COALESCE(rv.aberp_credentials_id,0) > 0"
						+ " AND COALESCE(ss.aberp_user_contact_id,0) > 0"
						+ " AND NOT EXISTS ("
						+ "   SELECT 1 FROM aberp_credentialassignment ca"
						+ "   WHERE ca.isactive='Y' AND ca.aberp_credentials_id = rv.aberp_credentials_id"
						+ "     AND ca.aberp_user_contact_id = ss.aberp_user_contact_id"
						+ "     AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate::date >= s.enddate::date)"
						+ " )",
				"Staff missing required credential: %s (shift %s)");

		int upcoming = DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_rostered_shift s WHERE s.ad_client_id=? AND s.isactive='Y'"
						+ " AND s.startdate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days,
				clientId);
		SnapshotStats stats = new SnapshotStats();
		stats.total = Math.max(upcoming, nUnfilled + nCred);
		stats.critical = nUnfilled;
		stats.nonCompliant = nCred;
		stats.warning = 0;
		stats.compliant = Math.max(0, stats.total - stats.critical - stats.nonCompliant);
		finalizeStats(stats);
		stats.population = countCurrentPeriodShifts();
		writeCategorySnapshot(asAt, "R", stats);
		String msg = String.format("R unfilled=%d missing_cred=%d score=%s %s",
				nUnfilled, nCred, stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private String evalDocumentation(Timestamp asAt) {
		int tableId = tableId("AbERP_CredentialAssignment");
		int nDoc = insertFindings(ruleId(RULE_UU_ONBOARD_DOC), tableId, asAt, "WARN", "MED",
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " LEFT JOIN aberp_credentialscategory cat"
						+ "   ON cat.aberp_credentialscategory_id = c.aberp_credentialscategory_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ " AND COALESCE(cat.name,'') ILIKE '%Onboarding Documentation%'",
				"Onboarding documentation expired: %s (expiry %s)");

		SnapshotStats stats = computeBucketStats(
				"SELECT CASE"
						+ " WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ "      AND COALESCE(cat.name,'') ILIKE '%Onboarding Documentation%' THEN 'WARN'"
						+ " ELSE 'C' END"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " LEFT JOIN aberp_credentialscategory cat"
						+ "   ON cat.aberp_credentialscategory_id = c.aberp_credentialscategory_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND COALESCE(cat.name,'') ILIKE '%Onboarding Documentation%'");
		if (stats.total == 0) {
			stats.total = Math.max(1, nDoc);
			stats.warning = nDoc;
			stats.compliant = Math.max(0, stats.total - nDoc);
			finalizeStats(stats);
		}
		stats.population = countTotalDocuments();
		writeCategorySnapshot(asAt, "D", stats);
		String msg = String.format("D onboard_doc_expired=%d score=%s %s",
				nDoc, stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private void ensureRulesPresent() {
		int n = DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_compliancerule WHERE isactive='Y'"
						+ " AND aberp_compliancerule_uu IN ("
						+ "'23a02350-c0d4-4f01-8e15-000000000001',"
						+ "'23a02351-c0d4-4f01-8e15-000000000001',"
						+ "'23a02352-c0d4-4f01-8e15-000000000001',"
						+ "'23a02353-c0d4-4f01-8e15-000000000001',"
						+ "'23a02355-c0d4-4f01-8e15-000000000001',"
						+ "'23a02356-c0d4-4f01-8e15-000000000001',"
						+ "'23a02357-c0d4-4f01-8e15-000000000001',"
						+ "'23a02358-c0d4-4f01-8e15-000000000001',"
						+ "'23a02359-c0d4-4f01-8e15-000000000001'"
						+ ")");
		if (n < 9) {
			throw new IllegalStateException(
					"SAW023: rules missing — run sql/15 and sql/16 seed scripts (found " + n + ")");
		}
	}

	private int[] allRuleIds() {
		List<Integer> ids = new ArrayList<>();
		for (String uu : ALL_RULE_UUS) {
			int id = DB.getSQLValue(trxName,
					"SELECT aberp_compliancerule_id FROM aberp_compliancerule WHERE aberp_compliancerule_uu=? AND isactive='Y'",
					uu);
			if (id > 0) {
				ids.add(id);
			}
		}
		int[] arr = new int[ids.size()];
		for (int i = 0; i < ids.size(); i++) {
			arr[i] = ids.get(i);
		}
		return arr;
	}

	private int ruleId(String uu) {
		int id = DB.getSQLValue(trxName,
				"SELECT aberp_compliancerule_id FROM aberp_compliancerule WHERE aberp_compliancerule_uu=? AND isactive='Y'",
				uu);
		if (id <= 0) {
			throw new IllegalStateException("SAW023: rule missing " + uu);
		}
		return id;
	}

	private int daysBefore(int ruleId, int defaultDays) {
		BigDecimal d = DB.getSQLValueBD(trxName,
				"SELECT daysbeforeexpiry FROM aberp_compliancerule WHERE aberp_compliancerule_id=?",
				ruleId);
		if (d == null || d.intValue() <= 0) {
			return defaultDays;
		}
		return d.intValue();
	}

	private int tableId(String tableName) {
		int id = MTable.getTable_ID(tableName);
		if (id <= 0) {
			throw new IllegalStateException("SAW023: table missing " + tableName);
		}
		return id;
	}

	private int tableIdOptional(String tableName) {
		return MTable.getTable_ID(tableName);
	}

	private void deactivateOpenResults(int... ruleIds) {
		if (ruleIds.length == 0) {
			return;
		}
		StringBuilder in = new StringBuilder();
		for (int i = 0; i < ruleIds.length; i++) {
			if (i > 0) {
				in.append(',');
			}
			in.append(ruleIds[i]);
		}
		int n = DB.executeUpdateEx(
				"UPDATE aberp_complianceresult SET isactive='N', isresolved='Y', resolveddate=NOW(),"
						+ " updated=NOW(), updatedby=? "
						+ "WHERE ad_client_id=? AND isactive='Y' AND isresolved='N'"
						+ " AND aberp_compliancerule_id IN (" + in + ")",
				new Object[] { userId, clientId }, trxName);
		logs.add("Deactivated prior open results: " + n);
	}

	private int insertFindings(int ruleId, int tableId, Timestamp asAt, String status, String severity,
			String selectSql, String msgFmt) {
		return insertFindings(ruleId, tableId, asAt, status, severity, selectSql, msgFmt, false);
	}

	private int insertFindings(int ruleId, int tableId, Timestamp asAt, String status, String severity,
			String selectSql, String msgFmt, boolean nameIsLabel) {
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		int count = 0;
		try {
			pstmt = DB.prepareStatement(selectSql, trxName);
			pstmt.setInt(1, clientId);
			rs = pstmt.executeQuery();
			while (rs.next()) {
				int recordId = rs.getInt(1);
				int orgId = rs.getInt(2);
				int userContactId = rs.getInt(3);
				Timestamp due = rs.getTimestamp(4);
				String label = rs.getString(5);
				String message;
				if (nameIsLabel) {
					message = String.format(msgFmt,
							label != null ? label : "?",
							due != null ? due.toString() : "n/a");
				} else {
					message = String.format(msgFmt,
							label != null ? label : "?",
							due != null ? due.toString() : "?");
				}
				insertResult(ruleId, tableId, recordId, orgId, userContactId, asAt, due, status, severity, message);
				count++;
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "insertFindings", e);
			throw new RuntimeException("SAW023: failed inserting findings: " + e.getMessage(), e);
		} finally {
			DB.close(rs, pstmt);
		}
		return count;
	}

	private void insertResult(int ruleId, int tableId, int recordId, int orgId, int userContactId,
			Timestamp asAt, Timestamp dueDate, String status, String severity, String message) {
		int id = MSequence.getNextID(clientId, "AbERP_ComplianceResult", trxName);
		if (id <= 0) {
			throw new RuntimeException("SAW023: nextid AbERP_ComplianceResult failed");
		}
		Integer openAssignmentId = null;
		int credTableId = tableId("AbERP_CredentialAssignment");
		if (credTableId > 0 && tableId == credTableId && recordId > 0) {
			openAssignmentId = Integer.valueOf(recordId);
		}
		String sql =
				"INSERT INTO aberp_complianceresult ("
						+ "aberp_complianceresult_id, ad_client_id, ad_org_id, isactive,"
						+ "created, createdby, updated, updatedby, aberp_complianceresult_uu,"
						+ "aberp_compliancerule_id, ad_table_id, record_id, ad_user_id,"
						+ "datedetected, datechecked, duedate, compliancestatus, severity,"
						+ "resultmessage, isresolved, aberp_compliancedashboard_id,"
						+ "aberp_openassignment_id, aberp_sourceassignment_id"
						+ ") VALUES (?,?,?, 'Y', NOW(),?, NOW(),?, ?, ?,?,?,?, ?,?,?,?,?,?, 'N', ?, ?, ?)";
		Object userVal = userContactId > 0 ? Integer.valueOf(userContactId) : null;
		DB.executeUpdateEx(sql, new Object[] {
				id, clientId, orgId, userId, userId, UUID.randomUUID().toString(),
				ruleId, tableId, recordId, userVal,
				asAt, asAt, dueDate, status, severity, truncate(message, 2000),
				clientId, openAssignmentId, openAssignmentId
		}, trxName);
	}

	private static String truncate(String s, int max) {
		if (s == null) {
			return null;
		}
		return s.length() <= max ? s : s.substring(0, max);
	}

	private SnapshotStats computeBucketStats(String bucketSelectSql) {
		String sql =
				"SELECT COUNT(*) AS total,"
						+ " COUNT(*) FILTER (WHERE bucket='C') AS compliant,"
						+ " COUNT(*) FILTER (WHERE bucket='WARN') AS warning,"
						+ " COUNT(*) FILTER (WHERE bucket='NC') AS noncompliant,"
						+ " COUNT(*) FILTER (WHERE bucket='CRIT') AS critical"
						+ " FROM (" + bucketSelectSql + ") x(bucket)";
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(sql, trxName);
			pstmt.setInt(1, clientId);
			rs = pstmt.executeQuery();
			rs.next();
			SnapshotStats s = new SnapshotStats();
			s.total = rs.getInt(1);
			s.compliant = rs.getInt(2);
			s.warning = rs.getInt(3);
			s.nonCompliant = rs.getInt(4);
			s.critical = rs.getInt(5);
			finalizeStats(s);
			return s;
		} catch (Exception e) {
			throw new RuntimeException("SAW023: snapshot stats failed: " + e.getMessage(), e);
		} finally {
			DB.close(rs, pstmt);
		}
	}

	private void finalizeStats(SnapshotStats s) {
		s.overdue = s.nonCompliant + s.critical;
		s.atRisk = s.warning;
		s.onTrack = s.compliant;
		if (s.total <= 0) {
			s.score = BigDecimal.valueOf(100).setScale(2);
			s.trafficLight = "G";
			return;
		}
		double raw = 100.0 * (s.compliant + 0.5 * s.warning) / s.total;
		s.score = BigDecimal.valueOf(raw).setScale(2, RoundingMode.HALF_UP);
		double ncRate = (double) (s.nonCompliant + s.critical) / s.total;
		double warnRate = (double) s.warning / s.total;
		if (s.critical > 0 || ncRate >= 0.02) {
			s.trafficLight = "R";
		} else if (warnRate >= 0.02 || ncRate > 0) {
			s.trafficLight = "A";
		} else {
			s.trafficLight = "G";
		}
	}

	private int countActiveEmployees() {
		return Math.max(0, DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM ad_user u"
						+ " JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id"
						+ " WHERE u.ad_client_id=? AND u.isactive='Y' AND bp.isactive='Y' AND bp.isemployee='Y'",
				clientId));
	}

	private int countActiveClients() {
		return Math.max(0, DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM c_bpartner bp"
						+ " WHERE bp.ad_client_id=? AND bp.isactive='Y'"
						+ " AND COALESCE(bp.aberp_issupport_receiver,'N')='Y'",
				clientId));
	}

	private int countActiveIncidents() {
		return Math.max(0, DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_incident i"
						+ " LEFT JOIN aberp_incident_status s ON s.aberp_incident_status_id = i.aberp_incident_status_id"
						+ " WHERE i.ad_client_id=? AND i.isactive='Y'"
						+ " AND COALESCE(s.name,'') NOT ILIKE '%closed%'",
				clientId));
	}

	private int countCurrentPeriodShifts() {
		return Math.max(0, DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_rostered_shift rs"
						+ " JOIN aberp_pr_period p ON p.ad_client_id = rs.ad_client_id AND p.isactive='Y'"
						+ "  AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date"
						+ " WHERE rs.ad_client_id=? AND rs.isactive='Y'"
						+ " AND COALESCE(rs.aberp_isshiftrosteredtemplate,'N')='N'"
						+ " AND rs.startdate::date BETWEEN p.startdate::date AND p.enddate::date",
				clientId));
	}

	private int countTotalDocuments() {
		return Math.max(0, DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_credentialassignment ca"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'",
				clientId));
	}

	private void writeCategorySnapshot(Timestamp asAt, String category, SnapshotStats s) {
		DB.executeUpdateEx(
				"UPDATE aberp_compliancesnapshot SET isactive='N', updated=NOW(), updatedby=?"
						+ " WHERE ad_client_id=? AND compliancecategory=?"
						+ " AND aberp_support_location_id IS NULL AND snapshotdate::date = ?::date",
				new Object[] { userId, clientId, category, asAt }, trxName);
		insertSnapshot(asAt, 0, category,
				BigDecimal.valueOf(s.total), BigDecimal.valueOf(s.compliant),
				BigDecimal.valueOf(s.warning), BigDecimal.valueOf(s.nonCompliant),
				BigDecimal.valueOf(s.critical), BigDecimal.valueOf(s.overdue),
				BigDecimal.valueOf(s.atRisk), BigDecimal.valueOf(s.onTrack),
				s.score, s.trafficLight, BigDecimal.valueOf(s.population));
	}

	private void insertSnapshot(Timestamp asAt, int orgId, String category,
			BigDecimal total, BigDecimal compliant, BigDecimal warning, BigDecimal nc,
			BigDecimal critical, BigDecimal overdue, BigDecimal atRisk, BigDecimal onTrack,
			BigDecimal score, String traffic, BigDecimal population) {
		int id = MSequence.getNextID(clientId, "AbERP_ComplianceSnapshot", trxName);
		if (id <= 0) {
			throw new RuntimeException("SAW023: nextid AbERP_ComplianceSnapshot failed");
		}
		String sql =
				"INSERT INTO aberp_compliancesnapshot ("
						+ "aberp_compliancesnapshot_id, ad_client_id, ad_org_id, isactive,"
						+ "created, createdby, updated, updatedby, aberp_compliancesnapshot_uu,"
						+ "snapshotdate, aberp_support_location_id, compliancecategory,"
						+ "totalitems, compliant, warning, noncompliant, critical,"
						+ "overdue, atrisk, ontrack, auditreadinessscore, trafficlight, lastcalculated,"
						+ "populationcount"
						+ ") VALUES (?,?,?, 'Y', NOW(),?, NOW(),?, ?, ?, NULL, ?, ?,?,?,?,?, ?,?,?,?,?, ?, ?)";
		DB.executeUpdateEx(sql, new Object[] {
				id, clientId, orgId, userId, userId, UUID.randomUUID().toString(),
				asAt, category,
				nz(total), nz(compliant), nz(warning), nz(nc), nz(critical),
				nz(overdue), nz(atRisk), nz(onTrack), nz(score), traffic, asAt,
				nz(population)
		}, trxName);
	}

	private static BigDecimal nz(BigDecimal v) {
		return v != null ? v : BigDecimal.ZERO;
	}

	private static final class SnapshotStats {
		int total;
		int compliant;
		int warning;
		int nonCompliant;
		int critical;
		int population;
		int overdue;
		int atRisk;
		int onTrack;
		BigDecimal score;
		String trafficLight;
	}
}
