package com.aberp.activityaudit.engine;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.UUID;
import java.util.logging.Level;
import java.util.regex.Pattern;

import org.compiere.util.CLogger;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Trx;

/**
 * SAW027 — incremental Contact Activity keyword audit engine.
 */
public class ActivityAuditEngine {

	private static final CLogger log = CLogger.getCLogger(ActivityAuditEngine.class);

	private final Properties ctx;
	private final String trxName;
	private final List<String> logs = new ArrayList<>();

	private int identified;
	private int skipped;
	private int processed;
	private int noMatch;
	private int reviewsCreated;
	private int reviewsReopened;
	private int errors;
	private int termsAppliedCount;

	public ActivityAuditEngine(Properties ctx, String trxName) {
		this.ctx = ctx;
		this.trxName = trxName;
	}

	public List<String> getLogs() {
		return logs;
	}

	public String runNightly() {
		Timestamp to = new Timestamp(System.currentTimeMillis());
		Timestamp from = new Timestamp(to.getTime() - 24L * 60L * 60L * 1000L);
		return run(from, to, 0, null, null, false, false, true, "NT");
	}

	public String runHistorical(Timestamp from, Timestamp to, int orgId, String activityType,
			String category, boolean includePreviouslyProcessed, boolean onlyNewTerms,
			boolean reopenExisting) {
		return run(from, to, orgId, activityType, category, includePreviouslyProcessed,
				onlyNewTerms, reopenExisting, "HI");
	}

	public String run(Timestamp from, Timestamp to, int orgId, String activityType,
			String category, boolean includePreviouslyProcessed, boolean onlyNewTerms,
			boolean reopenExisting, String triggerType) {

		int clientId = Env.getAD_Client_ID(ctx);
		int userId = Env.getAD_User_ID(ctx);
		Timestamp start = new Timestamp(System.currentTimeMillis());
		List<Term> terms = loadTerms(clientId, orgId, category, onlyNewTerms);
		termsAppliedCount = terms.size();
		addLog("Terms loaded: " + terms.size());

		StringBuilder sql = new StringBuilder();
		sql.append("SELECT a.C_ContactActivity_ID, a.AD_Client_ID, a.AD_Org_ID, a.Updated,")
				.append(" a.StartDate, a.C_BPartner_ID, a.AD_User_ID, a.ContactActivityType,")
				.append(" COALESCE(a.Description,'') AS Description, COALESCE(a.Comments,'') AS Comments")
				.append(" FROM C_ContactActivity a")
				.append(" WHERE a.AD_Client_ID=? AND a.IsActive='Y'")
				.append(" AND a.Updated >= ? AND a.Updated < ?");
		if (orgId > 0) {
			sql.append(" AND a.AD_Org_ID=?");
		}
		if (activityType != null && activityType.trim().length() > 0) {
			sql.append(" AND a.ContactActivityType=?");
		}
		sql.append(" ORDER BY a.Updated");

		List<Integer> activityIds = new ArrayList<>();
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(sql.toString(), trxName);
			int i = 1;
			pstmt.setInt(i++, clientId);
			pstmt.setTimestamp(i++, from);
			pstmt.setTimestamp(i++, to);
			if (orgId > 0) {
				pstmt.setInt(i++, orgId);
			}
			if (activityType != null && activityType.trim().length() > 0) {
				pstmt.setString(i++, activityType.trim());
			}
			rs = pstmt.executeQuery();
			while (rs.next()) {
				activityIds.add(Integer.valueOf(rs.getInt(1)));
			}
		} catch (Exception e) {
			log.log(Level.SEVERE, "ActivityAuditEngine.load", e);
			throw new RuntimeException(e);
		} finally {
			DB.close(rs, pstmt);
		}

		identified = activityIds.size();
		for (Integer activityIdObj : activityIds) {
			int activityId = activityIdObj.intValue();
			Trx trx = trxName != null ? Trx.get(trxName, false) : null;
			java.sql.Savepoint savepoint = null;
			try {
				if (trx != null) {
					savepoint = trx.setSavepoint("aa_" + activityId);
				}
				processActivityId(activityId, terms, includePreviouslyProcessed, reopenExisting, userId);
				if (trx != null && savepoint != null) {
					trx.releaseSavepoint(savepoint);
				}
			} catch (Exception e) {
				errors++;
				if (trx != null && savepoint != null) {
					try {
						trx.rollback(savepoint);
					} catch (Exception rb) {
						log.log(Level.WARNING, "savepoint rollback", rb);
					}
				}
				Throwable root = e;
				while (root.getCause() != null && root.getCause() != root) {
					root = root.getCause();
				}
				log.log(Level.WARNING, "Activity audit failed for " + activityId, e);
				addLog("Error activity " + activityId + ": " + root.getMessage());
			}
		}

		Timestamp end = new Timestamp(System.currentTimeMillis());
		String summary = String.format(
				"identified=%d skipped=%d processed=%d noMatch=%d created=%d reopened=%d errors=%d terms=%d",
				identified, skipped, processed, noMatch, reviewsCreated, reviewsReopened, errors,
				termsAppliedCount);
		try {
			writeRunLog(clientId, userId, start, end, from, to, triggerType, orgId, summary);
		} catch (Exception e) {
			addLog("Run log failed: " + e.getMessage());
			log.log(Level.WARNING, "writeRunLog", e);
		}
		addLog(summary);
		return summary;
	}

	private void processActivityId(int activityId, List<Term> terms, boolean includePreviouslyProcessed,
			boolean reopenExisting, int userId) throws Exception {
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT a.C_ContactActivity_ID, a.AD_Client_ID, a.AD_Org_ID, a.Updated,"
							+ " a.StartDate, a.C_BPartner_ID, a.AD_User_ID, a.ContactActivityType,"
							+ " COALESCE(a.Description,'') AS Description, COALESCE(a.Comments,'') AS Comments"
							+ " FROM C_ContactActivity a WHERE a.C_ContactActivity_ID=?",
					trxName);
			pstmt.setInt(1, activityId);
			rs = pstmt.executeQuery();
			if (!rs.next()) {
				return;
			}
			processOne(rs, terms, includePreviouslyProcessed, reopenExisting, userId);
		} finally {
			DB.close(rs, pstmt);
		}
	}

	private void processOne(ResultSet rs, List<Term> terms, boolean includePreviouslyProcessed,
			boolean reopenExisting, int userId) throws Exception {
		int activityId = rs.getInt("C_ContactActivity_ID");
		int clientId = rs.getInt("AD_Client_ID");
		int orgId = rs.getInt("AD_Org_ID");
		Timestamp updated = rs.getTimestamp("Updated");
		Timestamp activityDate = rs.getTimestamp("StartDate");
		int bpId = rs.getInt("C_BPartner_ID");
		int userEmp = rs.getInt("AD_User_ID");
		String actType = rs.getString("ContactActivityType");
		String text = (rs.getString("Description") + " " + rs.getString("Comments")).trim();

		int procId = DB.getSQLValue(trxName,
				"SELECT AbERP_ActivityAuditProc_ID FROM AbERP_ActivityAuditProc WHERE C_ContactActivity_ID=?",
				activityId);
		Timestamp prevUpdated = null;
		if (procId > 0) {
			prevUpdated = DB.getSQLValueTS(trxName,
					"SELECT ActivityUpdated FROM AbERP_ActivityAuditProc WHERE AbERP_ActivityAuditProc_ID=?",
					procId);
			if (!includePreviouslyProcessed && prevUpdated != null && updated != null
					&& prevUpdated.getTime() == updated.getTime()) {
				skipped++;
				return;
			}
		}

		List<Term> orgTerms = filterTermsForOrg(terms, orgId);
		MatchResult match = matchAll(text, orgTerms);
		String result = match.matched.isEmpty() ? "NM" : "MT";
		String matchedCsv = String.join("; ", match.matched);
		String termsCsv = termsAppliedCsv(orgTerms);
		upsertProc(procId, clientId, orgId, userId, activityId, updated, result, matchedCsv, termsCsv);

		if (match.matched.isEmpty()) {
			processed++;
			noMatch++;
			return;
		}

		int reviewId = DB.getSQLValue(trxName,
				"SELECT COALESCE(MAX(AbERP_ActivityAuditReview_ID),0) FROM AbERP_ActivityAuditReview"
						+ " WHERE C_ContactActivity_ID=? AND IsActive='Y'",
				activityId);

		if (reviewId > 0) {
			String isReviewed = DB.getSQLValueString(trxName,
					"SELECT IsReviewed FROM AbERP_ActivityAuditReview WHERE AbERP_ActivityAuditReview_ID=?",
					reviewId);
			Timestamp auditedTs = DB.getSQLValueTS(trxName,
					"SELECT ActivityUpdatedAudited FROM AbERP_ActivityAuditReview WHERE AbERP_ActivityAuditReview_ID=?",
					reviewId);
			boolean sameTs = auditedTs != null && updated != null && auditedTs.getTime() == updated.getTime();
			if ("Y".equals(isReviewed) && sameTs && !includePreviouslyProcessed) {
				// reviewed and unchanged — already skipped via proc, but safety
				skipped++;
				return;
			}
			if ("Y".equals(isReviewed) && !sameTs && reopenExisting) {
				String notes = DB.getSQLValueString(trxName,
						"SELECT COALESCE(ReviewNotes,'') FROM AbERP_ActivityAuditReview WHERE AbERP_ActivityAuditReview_ID=?",
						reviewId);
				String reopenNote = (notes == null ? "" : notes + "\n")
						+ "Reopened " + new Timestamp(System.currentTimeMillis())
						+ " after Activity update; prior review retained in history.";
				DB.executeUpdateEx(
						"UPDATE AbERP_ActivityAuditReview SET IsReviewed='N', ReviewStatus='NW',"
								+ " MatchedTerms=?, MatchedExtract=?, Category=?, HighestRiskLevel=?,"
								+ " ActivityUpdatedAudited=?, ReviewNotes=?, Updated=NOW(), UpdatedBy=?"
								+ " WHERE AbERP_ActivityAuditReview_ID=?",
						new Object[] { truncate(matchedCsv, 2000), truncate(match.extract, 4000),
								match.topCategory, match.topRisk, updated, truncate(reopenNote, 2000),
								userId, reviewId },
						trxName);
				reviewsReopened++;
			} else if (!"Y".equals(isReviewed)) {
				DB.executeUpdateEx(
						"UPDATE AbERP_ActivityAuditReview SET MatchedTerms=?, MatchedExtract=?,"
								+ " Category=?, HighestRiskLevel=?, ActivityUpdatedAudited=?,"
								+ " Updated=NOW(), UpdatedBy=? WHERE AbERP_ActivityAuditReview_ID=?",
						new Object[] { truncate(matchedCsv, 2000), truncate(match.extract, 4000),
								match.topCategory, match.topRisk, updated, userId, reviewId },
						trxName);
			} else if (!reopenExisting) {
				// create new review cycle
				insertReview(clientId, orgId, userId, activityId, activityDate, bpId, userEmp, actType,
						matchedCsv, match, updated);
				reviewsCreated++;
			}
		} else {
			insertReview(clientId, orgId, userId, activityId, activityDate, bpId, userEmp, actType,
					matchedCsv, match, updated);
			reviewsCreated++;
		}
		processed++;
	}

	private void insertReview(int clientId, int orgId, int userId, int activityId,
			Timestamp activityDate, int bpId, int userEmp, String actType, String matchedCsv,
			MatchResult match, Timestamp activityUpdated) throws Exception {
		int id = DB.getNextID(clientId, "AbERP_ActivityAuditReview", trxName);
		String sql = "INSERT INTO AbERP_ActivityAuditReview ("
				+ "AbERP_ActivityAuditReview_ID, AD_Client_ID, AD_Org_ID, IsActive,"
				+ "Created, CreatedBy, Updated, UpdatedBy, AbERP_ActivityAuditReview_UU,"
				+ "C_ContactActivity_ID, ActivityDate, C_BPartner_ID, AD_User_ID,"
				+ "ContactActivityType, MatchedTerms, MatchedExtract, Category,"
				+ "HighestRiskLevel, ReviewStatus, IsReviewed, IsFollowUpRequired,"
				+ "ActivityUpdatedAudited) VALUES ("
				+ "?,?,?,'Y',NOW(),?,NOW(),?,"
				+ "?,?,?,?,?,?,?,?,?,?,'NW','N','N',?)";
		PreparedStatement ps = null;
		try {
			ps = DB.prepareStatement(sql, trxName);
			int i = 1;
			ps.setInt(i++, id);
			ps.setInt(i++, clientId);
			ps.setInt(i++, orgId);
			ps.setInt(i++, userId);
			ps.setInt(i++, userId);
			ps.setString(i++, UUID.randomUUID().toString());
			ps.setInt(i++, activityId);
			if (activityDate != null) {
				ps.setTimestamp(i++, activityDate);
			} else {
				ps.setNull(i++, java.sql.Types.TIMESTAMP);
			}
			if (bpId > 0) {
				ps.setInt(i++, bpId);
			} else {
				ps.setNull(i++, java.sql.Types.INTEGER);
			}
			if (userEmp > 0) {
				ps.setInt(i++, userEmp);
			} else {
				ps.setNull(i++, java.sql.Types.INTEGER);
			}
			ps.setString(i++, actType);
			ps.setString(i++, truncate(matchedCsv, 2000));
			ps.setString(i++, truncate(match.extract, 4000));
			ps.setString(i++, match.topCategory);
			ps.setString(i++, match.topRisk);
			if (activityUpdated != null) {
				ps.setTimestamp(i++, activityUpdated);
			} else {
				ps.setNull(i++, java.sql.Types.TIMESTAMP);
			}
			ps.executeUpdate();
		} finally {
			DB.close(ps);
		}
	}

	private void upsertProc(int procId, int clientId, int orgId, int userId, int activityId,
			Timestamp updated, String result, String matched, String termsApplied) throws Exception {
		if (procId > 0) {
			PreparedStatement ps = null;
			try {
				ps = DB.prepareStatement(
						"UPDATE AbERP_ActivityAuditProc SET ActivityUpdated=?, LastAudited=NOW(),"
								+ " AuditResult=?, MatchedTerms=?, TermsApplied=?, Updated=NOW(), UpdatedBy=?"
								+ " WHERE AbERP_ActivityAuditProc_ID=?",
						trxName);
				ps.setTimestamp(1, updated);
				ps.setString(2, result);
				ps.setString(3, truncate(matched, 2000));
				ps.setString(4, truncate(termsApplied, 2000));
				ps.setInt(5, userId);
				ps.setInt(6, procId);
				ps.executeUpdate();
			} finally {
				DB.close(ps);
			}
		} else {
			int id = DB.getNextID(clientId, "AbERP_ActivityAuditProc", trxName);
			PreparedStatement ps = null;
			try {
				ps = DB.prepareStatement(
						"INSERT INTO AbERP_ActivityAuditProc ("
								+ "AbERP_ActivityAuditProc_ID, AD_Client_ID, AD_Org_ID, IsActive,"
								+ "Created, CreatedBy, Updated, UpdatedBy, AbERP_ActivityAuditProc_UU,"
								+ "C_ContactActivity_ID, ActivityUpdated, LastAudited, AuditResult,"
								+ "MatchedTerms, TermsApplied) VALUES ("
								+ "?,?,?,'Y',NOW(),?,NOW(),?,"
								+ "?,?,?,NOW(),?,?,?)",
						trxName);
				int i = 1;
				ps.setInt(i++, id);
				ps.setInt(i++, clientId);
				ps.setInt(i++, orgId);
				ps.setInt(i++, userId);
				ps.setInt(i++, userId);
				ps.setString(i++, UUID.randomUUID().toString());
				ps.setInt(i++, activityId);
				ps.setTimestamp(i++, updated);
				ps.setString(i++, result);
				ps.setString(i++, truncate(matched, 2000));
				ps.setString(i++, truncate(termsApplied, 2000));
				ps.executeUpdate();
			} finally {
				DB.close(ps);
			}
		}
	}

	private void writeRunLog(int clientId, int userId, Timestamp start, Timestamp end,
			Timestamp from, Timestamp to, String triggerType, int orgId, String summary) throws Exception {
		int id = DB.getNextID(clientId, "AbERP_ActivityAuditRunt", trxName);
		PreparedStatement ps = null;
		try {
			ps = DB.prepareStatement(
					"INSERT INTO AbERP_ActivityAuditRunt ("
							+ "AbERP_ActivityAuditRunt_ID, AD_Client_ID, AD_Org_ID, IsActive,"
							+ "Created, CreatedBy, Updated, UpdatedBy, AbERP_ActivityAuditRunt_UU,"
							+ "StartTime, EndTime, PeriodFrom, PeriodTo, TriggerType, OrgsProcessed,"
							+ "ActivitiesIdentified, ActivitiesSkipped, ActivitiesProcessed,"
							+ "ActivitiesNoMatch, ReviewsCreated, ReviewsReopened, TermsAppliedCount,"
							+ "ErrorCount, SummaryMsg) VALUES ("
							+ "?,?,0,'Y',NOW(),?,NOW(),?,"
							+ "?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
					trxName);
			int i = 1;
			ps.setInt(i++, id);
			ps.setInt(i++, clientId);
			ps.setInt(i++, userId);
			ps.setInt(i++, userId);
			ps.setString(i++, UUID.randomUUID().toString());
			ps.setTimestamp(i++, start);
			ps.setTimestamp(i++, end);
			ps.setTimestamp(i++, from);
			ps.setTimestamp(i++, to);
			ps.setString(i++, triggerType);
			ps.setString(i++, orgId > 0 ? String.valueOf(orgId) : "ALL");
			ps.setBigDecimal(i++, BigDecimal.valueOf(identified));
			ps.setBigDecimal(i++, BigDecimal.valueOf(skipped));
			ps.setBigDecimal(i++, BigDecimal.valueOf(processed));
			ps.setBigDecimal(i++, BigDecimal.valueOf(noMatch));
			ps.setBigDecimal(i++, BigDecimal.valueOf(reviewsCreated));
			ps.setBigDecimal(i++, BigDecimal.valueOf(reviewsReopened));
			ps.setBigDecimal(i++, BigDecimal.valueOf(termsAppliedCount));
			ps.setBigDecimal(i++, BigDecimal.valueOf(errors));
			ps.setString(i++, truncate(summary, 2000));
			ps.executeUpdate();
		} finally {
			DB.close(ps);
		}
	}

	private List<Term> loadTerms(int clientId, int orgFilter, String category, boolean onlyNewTerms) {
		List<Term> list = new ArrayList<>();
		StringBuilder sql = new StringBuilder();
		sql.append("SELECT AbERP_ActivityAuditTerm_ID, AD_Org_ID, AuditWord, Category, RiskLevel, MatchType,")
				.append(" AbERP_ActivityAuditTerm_UU, Created")
				.append(" FROM AbERP_ActivityAuditTerm")
				.append(" WHERE AD_Client_ID=? AND IsActive='Y'")
				.append(" AND (ValidFrom IS NULL OR ValidFrom <= NOW())")
				.append(" AND (ValidTo IS NULL OR ValidTo >= NOW())");
		if (orgFilter > 0) {
			sql.append(" AND (AD_Org_ID=0 OR AD_Org_ID=?)");
		}
		if (category != null && category.trim().length() > 0) {
			sql.append(" AND Category=?");
		}
		if (onlyNewTerms) {
			sql.append(" AND Created >= NOW() - INTERVAL '7 days'");
		}
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(sql.toString(), trxName);
			int i = 1;
			pstmt.setInt(i++, clientId);
			if (orgFilter > 0) {
				pstmt.setInt(i++, orgFilter);
			}
			if (category != null && category.trim().length() > 0) {
				pstmt.setString(i++, category.trim());
			}
			rs = pstmt.executeQuery();
			while (rs.next()) {
				Term t = new Term();
				t.id = rs.getInt(1);
				t.orgId = rs.getInt(2);
				t.word = rs.getString(3);
				t.category = rs.getString(4);
				t.risk = rs.getString(5);
				t.matchType = rs.getString(6);
				t.uu = rs.getString(7);
				list.add(t);
			}
		} catch (Exception e) {
			throw new RuntimeException(e);
		} finally {
			DB.close(rs, pstmt);
		}
		return list;
	}

	private List<Term> filterTermsForOrg(List<Term> terms, int orgId) {
		List<Term> out = new ArrayList<>();
		for (Term t : terms) {
			if (t.orgId == 0 || t.orgId == orgId) {
				out.add(t);
			}
		}
		return out;
	}

	private MatchResult matchAll(String text, List<Term> terms) {
		MatchResult mr = new MatchResult();
		mr.activityUpdated = null;
		if (text == null || text.length() == 0 || terms.isEmpty()) {
			return mr;
		}
		int bestRisk = -1;
		for (Term t : terms) {
			if (matches(text, t)) {
				mr.matched.add(t.word);
				int riskOrd = riskOrdinal(t.risk);
				if (riskOrd > bestRisk) {
					bestRisk = riskOrd;
					mr.topRisk = t.risk;
					mr.topCategory = t.category;
				}
				if (mr.extract == null) {
					mr.extract = extractAround(text, t.word);
				}
			}
		}
		return mr;
	}

	static boolean matches(String text, Term t) {
		if (t.word == null || t.word.trim().isEmpty()) {
			return false;
		}
		String type = t.matchType == null ? "EW" : t.matchType;
		if ("CT".equals(type)) {
			return text.toLowerCase().contains(t.word.toLowerCase());
		}
		String quoted = Pattern.quote(t.word.trim());
		String pattern = "(?i)(?<![A-Za-z0-9])" + quoted + "(?![A-Za-z0-9])";
		return Pattern.compile(pattern).matcher(text).find();
	}

	private static String extractAround(String text, String word) {
		String lower = text.toLowerCase();
		String w = word.toLowerCase();
		int idx = lower.indexOf(w);
		if (idx < 0) {
			return truncate(text, 400);
		}
		int start = Math.max(0, idx - 80);
		int end = Math.min(text.length(), idx + word.length() + 80);
		return truncate(text.substring(start, end), 400);
	}

	private static int riskOrdinal(String risk) {
		if ("CR".equals(risk)) return 4;
		if ("HI".equals(risk)) return 3;
		if ("MD".equals(risk)) return 2;
		if ("LO".equals(risk)) return 1;
		return 0;
	}

	private static String termsAppliedCsv(List<Term> terms) {
		List<String> ids = new ArrayList<>();
		for (Term t : terms) {
			ids.add(t.uu != null ? t.uu : String.valueOf(t.id));
			if (ids.size() >= 40) {
				break;
			}
		}
		return String.join(",", ids);
	}

	private static String truncate(String s, int max) {
		if (s == null) {
			return null;
		}
		return s.length() <= max ? s : s.substring(0, max);
	}

	private void addLog(String msg) {
		logs.add(msg);
	}

	static class Term {
		int id;
		int orgId;
		String word;
		String category;
		String risk;
		String matchType;
		String uu;
	}

	static class MatchResult {
		List<String> matched = new ArrayList<>();
		String extract;
		String topRisk;
		String topCategory;
		Timestamp activityUpdated;
	}
}
