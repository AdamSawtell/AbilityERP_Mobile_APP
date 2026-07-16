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
 * SAW023 Phase 3 — evaluate Employee (W) credential rules and write snapshots.
 */
public class ComplianceEngine {

	private static final CLogger log = CLogger.getCLogger(ComplianceEngine.class);

	public static final String RULE_UU_EXPIRED = "23a02350-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_30D = "23a02351-c0d4-4f01-8e15-000000000001";
	public static final String RULE_UU_SCREENING = "23a02352-c0d4-4f01-8e15-000000000001";

	public static final String TABLE_ASSIGNMENT = "AbERP_CredentialAssignment";
	public static final String CAT_EMPLOYEE = "W";

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

		int assignmentTableId = MTable.getTable_ID(TABLE_ASSIGNMENT);
		if (assignmentTableId <= 0) {
			throw new IllegalStateException("SAW023: AbERP_CredentialAssignment table missing");
		}

		int ruleExpired = ruleId(RULE_UU_EXPIRED);
		int rule30d = ruleId(RULE_UU_30D);
		int ruleScreen = ruleId(RULE_UU_SCREENING);
		int days = daysBefore(rule30d, 30);

		deactivateOpenResults(ruleExpired, rule30d, ruleScreen);

		Timestamp asAt = new Timestamp(System.currentTimeMillis());
		int nExpired = insertExpiredFindings(ruleExpired, assignmentTableId, asAt);
		int n30 = insertExpiringFindings(rule30d, assignmentTableId, asAt, days);
		int nScreen = insertScreeningFindings(ruleScreen, assignmentTableId, asAt);

		SnapshotStats stats = computeEmployeeStats(days);
		carryForwardOtherCategories(asAt);
		writeEmployeeSnapshot(asAt, stats);

		String msg = String.format(
				"Employee refresh: expired=%d, due_in_%dd=%d, screening_expired=%d; "
						+ "snapshot total=%d compliant=%d warn=%d nc=%d crit=%d score=%s %s",
				nExpired, days, n30, nScreen,
				stats.total, stats.compliant, stats.warning, stats.nonCompliant, stats.critical,
				stats.score.toPlainString(), stats.trafficLight);
		logs.add(msg);
		return msg;
	}

	private void ensureRulesPresent() {
		int n = DB.getSQLValue(trxName,
				"SELECT COUNT(*) FROM aberp_compliancerule WHERE aberp_compliancerule_uu IN (?,?,?) AND isactive='Y'",
				RULE_UU_EXPIRED, RULE_UU_30D, RULE_UU_SCREENING);
		if (n < 3) {
			throw new IllegalStateException(
					"SAW023: Employee rules missing — run sql/15-seed-employee-rules.sql");
		}
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

	private void deactivateOpenResults(int... ruleIds) {
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
		logs.add("Deactivated prior open Employee results: " + n);
	}

	private int insertExpiredFindings(int ruleId, int tableId, Timestamp asAt) {
		String sql =
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL"
						+ " AND ca.aberp_expirydate::date < CURRENT_DATE"
						// screening findings handled by dedicated rule
						+ " AND NOT ("
						+ "   c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%'"
						+ " )";
		return insertFindings(ruleId, tableId, asAt, "NC", "HIGH", sql,
				"Credential expired: %s (expiry %s)");
	}

	private int insertExpiringFindings(int ruleId, int tableId, Timestamp asAt, int days) {
		String sql =
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL"
						+ " AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days;
		return insertFindings(ruleId, tableId, asAt, "WARN", "MED", sql,
				"Credential expires within " + days + " days: %s (expiry %s)");
	}

	private int insertScreeningFindings(int ruleId, int tableId, Timestamp asAt) {
		String sql =
				"SELECT ca.aberp_credentialassignment_id, ca.ad_org_id, ca.aberp_user_contact_id,"
						+ " ca.aberp_expirydate, c.name"
						+ " FROM aberp_credentialassignment ca"
						+ " JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ " WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " AND ca.aberp_expirydate IS NOT NULL"
						+ " AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ " AND (c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%')";
		return insertFindings(ruleId, tableId, asAt, "CRIT", "CRIT", sql,
				"Worker screening expired: %s (expiry %s)");
	}

	private int insertFindings(int ruleId, int tableId, Timestamp asAt, String status, String severity,
			String selectSql, String msgFmt) {
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
				Timestamp expiry = rs.getTimestamp(4);
				String credName = rs.getString(5);
				String message = String.format(msgFmt,
						credName != null ? credName : "?",
						expiry != null ? expiry.toString() : "?");
				insertResult(ruleId, tableId, recordId, orgId, userContactId, asAt, expiry, status, severity,
						message);
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
		String sql =
				"INSERT INTO aberp_complianceresult ("
						+ "aberp_complianceresult_id, ad_client_id, ad_org_id, isactive,"
						+ "created, createdby, updated, updatedby, aberp_complianceresult_uu,"
						+ "aberp_compliancerule_id, ad_table_id, record_id, ad_user_id,"
						+ "datedetected, datechecked, duedate, compliancestatus, severity,"
						+ "resultmessage, isresolved"
						+ ") VALUES (?,?,?, 'Y', NOW(),?, NOW(),?, ?, ?,?,?,?, ?,?,?,?,?,?, 'N')";
		Object userVal = userContactId > 0 ? Integer.valueOf(userContactId) : null;
		DB.executeUpdateEx(sql, new Object[] {
				id, clientId, orgId, userId, userId, UUID.randomUUID().toString(),
				ruleId, tableId, recordId, userVal,
				asAt, asAt, dueDate, status, severity, truncate(message, 2000)
		}, trxName);
	}

	private static String truncate(String s, int max) {
		if (s == null) {
			return null;
		}
		return s.length() <= max ? s : s.substring(0, max);
	}

	private SnapshotStats computeEmployeeStats(int days) {
		String sql =
				"SELECT COUNT(*) AS total,"
						+ " COUNT(*) FILTER (WHERE bucket='C') AS compliant,"
						+ " COUNT(*) FILTER (WHERE bucket='WARN') AS warning,"
						+ " COUNT(*) FILTER (WHERE bucket='NC') AS noncompliant,"
						+ " COUNT(*) FILTER (WHERE bucket='CRIT') AS critical"
						+ " FROM ("
						+ "  SELECT CASE"
						+ "    WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ "         AND (c.name ILIKE '%Worker Screening%' OR c.name ILIKE '%Working with Child%')"
						+ "      THEN 'CRIT'"
						+ "    WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate::date < CURRENT_DATE"
						+ "      THEN 'NC'"
						+ "    WHEN ca.aberp_expirydate IS NOT NULL"
						+ "         AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE + " + days
						+ "      THEN 'WARN'"
						+ "    ELSE 'C'"
						+ "  END AS bucket"
						+ "  FROM aberp_credentialassignment ca"
						+ "  JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id"
						+ "  WHERE ca.ad_client_id=? AND ca.isactive='Y'"
						+ " ) x";
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
			s.overdue = s.nonCompliant + s.critical;
			s.atRisk = s.warning;
			s.onTrack = s.compliant;
			if (s.total <= 0) {
				s.score = BigDecimal.valueOf(100).setScale(2);
				s.trafficLight = "G";
			} else {
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
			return s;
		} catch (Exception e) {
			throw new RuntimeException("SAW023: snapshot stats failed: " + e.getMessage(), e);
		} finally {
			DB.close(rs, pstmt);
		}
	}

	private void carryForwardOtherCategories(Timestamp asAt) {
		String select =
				"SELECT ad_org_id, compliancecategory, totalitems, compliant, warning, noncompliant,"
						+ " critical, overdue, atrisk, ontrack, auditreadinessscore, trafficlight"
						+ " FROM aberp_compliancesnapshot s"
						+ " WHERE s.ad_client_id=? AND s.isactive='Y'"
						+ " AND s.aberp_support_location_id IS NULL"
						+ " AND s.compliancecategory <> 'W'"
						+ " AND s.snapshotdate = ("
						+ "   SELECT MAX(s2.snapshotdate) FROM aberp_compliancesnapshot s2"
						+ "   WHERE s2.ad_client_id=s.ad_client_id AND s2.isactive='Y'"
						+ "     AND s2.aberp_support_location_id IS NULL"
						+ "     AND s2.compliancecategory=s.compliancecategory"
						+ " )"
						+ " AND NOT EXISTS ("
						+ "   SELECT 1 FROM aberp_compliancesnapshot x"
						+ "   WHERE x.ad_client_id=s.ad_client_id AND x.isactive='Y'"
						+ "     AND x.aberp_support_location_id IS NULL"
						+ "     AND x.compliancecategory=s.compliancecategory"
						+ "     AND x.snapshotdate::date = ?::date"
						+ " )";
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		int n = 0;
		try {
			pstmt = DB.prepareStatement(select, trxName);
			pstmt.setInt(1, clientId);
			pstmt.setTimestamp(2, asAt);
			rs = pstmt.executeQuery();
			while (rs.next()) {
				insertSnapshot(asAt, rs.getInt(1), rs.getString(2),
						rs.getBigDecimal(3), rs.getBigDecimal(4), rs.getBigDecimal(5),
						rs.getBigDecimal(6), rs.getBigDecimal(7), rs.getBigDecimal(8),
						rs.getBigDecimal(9), rs.getBigDecimal(10), rs.getBigDecimal(11),
						rs.getString(12));
				n++;
			}
		} catch (Exception e) {
			throw new RuntimeException("SAW023: carry-forward failed: " + e.getMessage(), e);
		} finally {
			DB.close(rs, pstmt);
		}
		logs.add("Carried forward other category snapshots: " + n);
	}

	private void writeEmployeeSnapshot(Timestamp asAt, SnapshotStats s) {
		// deactivate same-day W snapshot if re-run
		DB.executeUpdateEx(
				"UPDATE aberp_compliancesnapshot SET isactive='N', updated=NOW(), updatedby=?"
						+ " WHERE ad_client_id=? AND compliancecategory='W'"
						+ " AND aberp_support_location_id IS NULL AND snapshotdate::date = ?::date",
				new Object[] { userId, clientId, asAt }, trxName);
		insertSnapshot(asAt, 0, CAT_EMPLOYEE,
				BigDecimal.valueOf(s.total), BigDecimal.valueOf(s.compliant),
				BigDecimal.valueOf(s.warning), BigDecimal.valueOf(s.nonCompliant),
				BigDecimal.valueOf(s.critical), BigDecimal.valueOf(s.overdue),
				BigDecimal.valueOf(s.atRisk), BigDecimal.valueOf(s.onTrack),
				s.score, s.trafficLight);
	}

	private void insertSnapshot(Timestamp asAt, int orgId, String category,
			BigDecimal total, BigDecimal compliant, BigDecimal warning, BigDecimal nc,
			BigDecimal critical, BigDecimal overdue, BigDecimal atRisk, BigDecimal onTrack,
			BigDecimal score, String traffic) {
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
						+ "overdue, atrisk, ontrack, auditreadinessscore, trafficlight, lastcalculated"
						+ ") VALUES (?,?,?, 'Y', NOW(),?, NOW(),?, ?, ?, NULL, ?, ?,?,?,?,?, ?,?,?,?,?, ?)";
		DB.executeUpdateEx(sql, new Object[] {
				id, clientId, orgId, userId, userId, UUID.randomUUID().toString(),
				asAt, category,
				nz(total), nz(compliant), nz(warning), nz(nc), nz(critical),
				nz(overdue), nz(atRisk), nz(onTrack), nz(score), traffic, asAt
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
		int overdue;
		int atRisk;
		int onTrack;
		BigDecimal score;
		String trafficLight;
	}
}
