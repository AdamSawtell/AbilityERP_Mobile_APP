package com.aberp.rostering.staffinfo.info;

import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Properties;

import org.adempiere.webui.component.Label;
import org.adempiere.webui.editor.WEditor;
import org.adempiere.webui.info.InfoWindow;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.model.MInfoColumn;
import org.compiere.model.MInfoWindow;
import org.compiere.util.DB;
import org.compiere.util.DisplayType;
import org.compiere.util.Env;
import org.compiere.util.Language;
import org.compiere.util.Util;
import org.zkoss.zk.ui.Component;
import org.zkoss.zul.Vbox;

/**
 * Staff Rostering Info Window enhancements:
 * <ul>
 *   <li>Auto-wrap {@code %} on Like criteria</li>
 *   <li>Context banner with shift document, dates and times</li>
 *   <li>Shift-window leave / overlap exclusions (no {@code @StartDate@} in AD WhereClause)</li>
 *   <li>Related Rostering Needs match (credentials / gender / restricted employee)
 *       with AD tickbox {@code Show Unmatched Staff} to include non-matches;
 *       credentials must be active and valid for the shift Start/End dates</li>
 * </ul>
 */
public class StaffRosteringInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "2b4ab146-0809-47c6-96f3-8b841d60a6bf";
	public static final String COL_SHOW_UNMATCHED = "AbERP_ShowUnmatchedStaff";

	private final GridField launchField;
	private Label contextBanner;

	public StaffRosteringInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID) {
		this(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, true, null);
	}

	public StaffRosteringInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup) {
		this(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, lookup, null);
	}

	public StaffRosteringInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup, GridField field) {
		super(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, lookup, field);
		this.launchField = field;
	}

	public static boolean matchesInfoWindow(int adInfoWindowId) {
		if (adInfoWindowId <= 0) {
			return false;
		}
		MInfoWindow iw = MInfoWindow.getInfoWindow(adInfoWindowId);
		return iw != null && INFO_WINDOW_UU.equalsIgnoreCase(iw.getAD_InfoWindow_UU());
	}

	/**
	 * After the criteria pane is attached to North, insert a read-only status line
	 * so officers can see which shift dates/times and needs filters apply.
	 */
	@Override
	protected void renderParameterPane(org.zkoss.zul.North north) {
		super.renderParameterPane(north);
		ensureContextBanner(north);
	}

	@Override
	protected void executeQuery() {
		autoWrapLikeCriteria();
		if (contextBanner != null) {
			contextBanner.setValue(buildContextBannerText());
		}
		super.executeQuery();
	}

	@Override
	protected String getSQLWhere() {
		// AD "Show Unmatched Staff" is a UI flag only (SelectClause 0). Never let it
		// become SQL — a leaked constant like 'N'='Y' returns 0 rows under AND mode.
		WEditor showUnmatchedEditor = findEditor(COL_SHOW_UNMATCHED);
		Object savedShowUnmatched = null;
		boolean cleared = false;
		if (showUnmatchedEditor != null) {
			savedShowUnmatched = showUnmatchedEditor.getValue();
			showUnmatchedEditor.setValue(null);
			cleared = true;
		}

		try {
			String where = stripShowUnmatchedSql(super.getSQLWhere());
			StringBuilder extra = new StringBuilder();
			appendClause(extra, buildShiftDateEligibilitySql());

			boolean showUnmatched = isYes(savedShowUnmatched);
			if (!showUnmatched) {
				appendClause(extra, buildNeedsMatchSql());
			}

			if (extra.length() == 0) {
				return where;
			}
			if (Util.isEmpty(where, true)) {
				return extra.toString();
			}
			return where + " AND " + extra;
		} finally {
			if (cleared) {
				showUnmatchedEditor.setValue(savedShowUnmatched);
			}
			if (contextBanner != null) {
				contextBanner.setValue(buildContextBannerText());
			}
		}
	}

	/**
	 * Remove any Show-Unmatched flag fragments that InfoWindow may still emit
	 * (legacy SelectClause {@code 'N'} / {@code 0}, which break Yes-No criteria).
	 */
	private static String stripShowUnmatchedSql(String where) {
		if (Util.isEmpty(where, true)) {
			return where;
		}
		String cleaned = where;
		cleaned = cleaned.replaceAll("(?i)\\(\\s*'N'\\s*=\\s*'[YN]'\\s*\\)", " ");
		cleaned = cleaned.replaceAll("(?i)\\(\\s*0\\s*=\\s*'[YN]'\\s*\\)", " ");
		cleaned = cleaned.replaceAll("(?i)(?<!\\w)'N'\\s*=\\s*'[YN]'", " ");
		cleaned = cleaned.replaceAll("(?i)(?<!\\w)0\\s*=\\s*'[YN]'", " ");
		cleaned = cleaned.replaceAll("(?i)\\bAND\\s+AND\\b", " AND ");
		cleaned = cleaned.replaceAll("(?i)^\\s*AND\\s+", "");
		cleaned = cleaned.replaceAll("(?i)\\s+AND\\s*$", "");
		cleaned = cleaned.replaceAll("\\s{2,}", " ").trim();
		return cleaned;
	}

	private static void appendClause(StringBuilder sb, String clause) {
		if (Util.isEmpty(clause, true)) {
			return;
		}
		if (sb.length() > 0) {
			sb.append(" AND ");
		}
		sb.append(clause);
	}

	private static boolean isYes(Object value) {
		if (value == null) {
			return false;
		}
		if (value instanceof Boolean) {
			return ((Boolean) value).booleanValue();
		}
		String s = value.toString().trim();
		return "Y".equalsIgnoreCase(s) || "true".equalsIgnoreCase(s);
	}

	private WEditor findEditor(String columnName) {
		if (editors == null || Util.isEmpty(columnName, true)) {
			return null;
		}
		for (WEditor editor : editors) {
			if (editor == null || editor.getGridField() == null) {
				continue;
			}
			if (columnName.equalsIgnoreCase(editor.getGridField().getColumnName())) {
				return editor;
			}
		}
		return null;
	}

	private void ensureContextBanner(org.zkoss.zul.North north) {
		if (contextBanner != null && contextBanner.getParent() != null) {
			contextBanner.setValue(buildContextBannerText());
			return;
		}

		contextBanner = new Label(buildContextBannerText());
		contextBanner.setStyle(
				"display:block;width:100%;box-sizing:border-box;"
						+ "padding:8px 10px;margin:0;"
						+ "background:#EEF3F8;border:1px solid #C5D0DC;color:#1F2A37;"
						+ "font-size:12px;line-height:1.35;white-space:normal;");

		// North allows only ONE child. Prefer wrapping inside that child (often
		// ZK north-body). Never insertBefore onto North itself.
		Component northChild = north != null ? north.getFirstChild() : null;
		if (northChild == null && parameterGrid != null) {
			// Walk up from criteria grid to the North child container
			Component p = parameterGrid.getParent();
			while (p != null && p.getParent() != null && !(p.getParent() instanceof org.zkoss.zul.North)) {
				p = p.getParent();
			}
			northChild = p;
		}
		if (northChild == null) {
			return;
		}

		if (northChild instanceof Vbox) {
			northChild.insertBefore(contextBanner, northChild.getFirstChild());
			return;
		}

		// Single content under north-body (or similar): wrap content in Vbox
		if (northChild.getChildren().size() == 1 && northChild.getFirstChild() != null) {
			Component content = northChild.getFirstChild();
			Vbox wrap = new Vbox();
			wrap.setWidth("100%");
			wrap.setSpacing("6px");
			content.detach();
			wrap.appendChild(contextBanner);
			wrap.appendChild(content);
			northChild.appendChild(wrap);
			return;
		}

		// northChild itself is the criteria pane — replace North's only child with Vbox
		if (north != null && northChild.getParent() == north) {
			Vbox wrap = new Vbox();
			wrap.setWidth("100%");
			wrap.setSpacing("6px");
			northChild.detach();
			wrap.appendChild(contextBanner);
			wrap.appendChild(northChild);
			north.appendChild(wrap);
		}
	}

	private String buildContextBannerText() {
		Integer shiftId = resolveCurrentShiftId();
		String docNo = null;
		if (shiftId != null && shiftId.intValue() > 0) {
			docNo = DB.getSQLValueString(null,
					"SELECT DocumentNo FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?",
					shiftId.intValue());
		}

		Timestamp[] range = resolveShiftDisplayRange();
		NeedsSummary needs = summarizeRelatedNeeds(shiftId);
		boolean showUnmatched = isShowUnmatchedSelected();

		if (range != null && range[0] != null && range[1] != null) {
			StringBuilder sb = new StringBuilder();
			sb.append("Shift filter active");
			if (!Util.isEmpty(docNo, true)) {
				sb.append(" (").append(docNo).append(')');
			}
			sb.append(": ").append(formatDateTime(range[0])).append(" – ").append(formatDateTime(range[1]));
			sb.append(". Hiding staff on approved leave or already rostered on an overlapping shift.");
			appendNeedsBanner(sb, needs, showUnmatched);
			return sb.toString();
		}

		if (shiftId != null && shiftId.intValue() > 0) {
			StringBuilder sb = new StringBuilder();
			sb.append("Shift context");
			if (!Util.isEmpty(docNo, true)) {
				sb.append(" (").append(docNo).append(')');
			}
			sb.append(" — no Start/End dates for leave/overlap.");
			appendNeedsBanner(sb, needs, showUnmatched);
			return sb.toString();
		}

		return "No shift Start/End in context. Only the On Approved Leave (today) filter applies — "
				+ "open from Shift → Employee to use shift-date leave/overlap and related needs matching.";
	}

	private void appendNeedsBanner(StringBuilder sb, NeedsSummary needs, boolean showUnmatched) {
		if (needs == null || !needs.hasAny()) {
			sb.append(" No related rostering needs on this shift.");
			return;
		}
		sb.append(' ').append(needs.describe());
		if (showUnmatched) {
			sb.append(" Show Unmatched Staff is Y — including staff who do not meet these needs.");
		} else {
			sb.append(" Showing staff who match these needs only (credentials must be active and valid for the shift dates; tick Show Unmatched Staff to include others).");
		}
	}

	private boolean isShowUnmatchedSelected() {
		WEditor ed = findEditor(COL_SHOW_UNMATCHED);
		return ed != null && isYes(ed.getValue());
	}

	private String formatDateTime(Timestamp ts) {
		Language lang = Env.getLanguage(Env.getCtx());
		SimpleDateFormat df = DisplayType.getDateFormat(DisplayType.DateTime, lang);
		return df.format(ts);
	}

	/**
	 * Prefix/suffix {@code %} for Like query criteria that have no wildcard yet.
	 */
	private void autoWrapLikeCriteria() {
		if (editors == null || editors.isEmpty()) {
			return;
		}
		for (WEditor editor : editors) {
			if (editor == null || editor.getGridField() == null) {
				continue;
			}
			MInfoColumn infoCol = findInfoColumn(editor.getGridField());
			if (infoCol == null) {
				continue;
			}
			String op = infoCol.getQueryOperator();
			if (op == null || !op.equalsIgnoreCase("Like")) {
				continue;
			}
			Object value = editor.getValue();
			if (!(value instanceof String)) {
				continue;
			}
			String text = ((String) value).trim();
			if (text.isEmpty() || text.indexOf('%') >= 0) {
				continue;
			}
			editor.setValue("%" + text + "%");
		}
	}

	/**
	 * Append leave + overlap exclusions using parent shift Start/End when available.
	 */
	private String buildShiftDateEligibilitySql() {
		Timestamp[] range = resolveShiftDateRange();
		if (range == null || range[0] == null || range[1] == null) {
			return null;
		}
		String startSql = DB.TO_DATE(range[0]);
		String endSql = DB.TO_DATE(range[1]);

		StringBuilder sql = new StringBuilder();
		sql.append("NOT EXISTS (")
				.append("SELECT 1 FROM AbERP_Unavailability_Leave ul ")
				.append("WHERE ul.AbERP_User_Contact_ID = au.AD_User_ID AND ul.IsActive = 'Y' ")
				.append("AND UPPER(COALESCE(ul.AbERP_ApproverStatus,'')) = 'AP' ")
				.append("AND ul.StartDate <= ").append(endSql).append(' ')
				.append("AND ul.EndDate >= ").append(startSql)
				.append(')');

		sql.append(" AND NOT EXISTS (")
				.append("SELECT 1 FROM AbERP_Rostered_ShiftStaff rss ")
				.append("INNER JOIN AbERP_Rostered_Shift rs ON (")
				.append("rs.AbERP_Rostered_Shift_ID = rss.AbERP_Rostered_Shift_ID ")
				.append("AND rs.IsActive = 'Y' AND COALESCE(rs.AbERP_isShiftRosteredTemplate,'N') = 'N') ")
				.append("WHERE rss.AbERP_User_Contact_ID = au.AD_User_ID AND rss.IsActive = 'Y' ")
				.append("AND rs.StartDate <= ").append(endSql).append(' ')
				.append("AND rs.EndDate >= ").append(startSql);

		Integer currentShiftId = resolveCurrentShiftId();
		if (currentShiftId != null && currentShiftId.intValue() > 0) {
			sql.append(" AND rs.AbERP_Rostered_Shift_ID <> ").append(currentShiftId.intValue());
		}
		sql.append(')');

		return sql.toString();
	}

	/**
	 * Staff must satisfy every Related Rostering Need (SR/LOC/RS view): credentials,
	 * gender, and must not be a restricted employee. Uses EXISTS — not FROM joins.
	 * <p>
	 * Credentials must be active and <em>in date for the whole shift window</em>:
	 * StartDate null or on/before shift start; ExpiryDate null or on/after shift end
	 * (not merely CURRENT_DATE).
	 */
	private String buildNeedsMatchSql() {
		Integer shiftId = resolveCurrentShiftId();
		if (shiftId == null || shiftId.intValue() <= 0) {
			return null;
		}
		NeedsSummary needs = summarizeRelatedNeeds(shiftId);
		if (needs == null || !needs.hasAny()) {
			return null;
		}

		int id = shiftId.intValue();
		Timestamp[] range = resolveShiftDateRange();
		String shiftStartSql = null;
		String shiftEndSql = null;
		if (range != null && range[0] != null && range[1] != null) {
			shiftStartSql = DB.TO_DATE(range[0]);
			shiftEndSql = DB.TO_DATE(range[1]);
		}

		StringBuilder sql = new StringBuilder();

		if (needs.crdCount > 0) {
			sql.append("NOT EXISTS (")
					.append("SELECT 1 FROM AbERP_Related_Rostering_Needs_V rv ")
					.append("WHERE rv.AbERP_Rostered_Shift_ID = ").append(id).append(' ')
					.append("AND rv.IsActive = 'Y' AND rv.AbERP_NeedType = 'CRD' ")
					.append("AND COALESCE(rv.AbERP_Credentials_ID,0) > 0 ")
					.append("AND NOT EXISTS (")
					.append("SELECT 1 FROM AbERP_CredentialAssignment ca ")
					.append("WHERE ca.IsActive = 'Y' ")
					.append("AND ca.AbERP_Credentials_ID = rv.AbERP_Credentials_ID ")
					.append("AND (ca.AbERP_User_Contact_ID = au.AD_User_ID ")
					.append("OR ca.C_BPartner_Staff_ID = bp.C_BPartner_ID) ");
			if (shiftStartSql != null && shiftEndSql != null) {
				// Valid for the whole shift window (not CURRENT_DATE):
				// started on/before shift start; expires on/after shift end (or never).
				sql.append("AND (ca.StartDate IS NULL OR ca.StartDate <= ").append(shiftStartSql).append(") ")
						.append("AND (ca.AbERP_ExpiryDate IS NULL OR ca.AbERP_ExpiryDate >= ")
						.append(shiftEndSql).append(')');
			} else {
				sql.append("AND (ca.StartDate IS NULL OR ca.StartDate <= CURRENT_DATE) ")
						.append("AND (ca.AbERP_ExpiryDate IS NULL OR ca.AbERP_ExpiryDate >= CURRENT_DATE)");
			}
			sql.append("))");
		}

		if (needs.gdrCount > 0) {
			if (sql.length() > 0) {
				sql.append(" AND ");
			}
			sql.append("NOT EXISTS (")
					.append("SELECT 1 FROM AbERP_Related_Rostering_Needs_V rv ")
					.append("WHERE rv.AbERP_Rostered_Shift_ID = ").append(id).append(' ')
					.append("AND rv.IsActive = 'Y' AND rv.AbERP_NeedType = 'GDR' ")
					.append("AND COALESCE(rv.AbERP_Gender_ID,0) > 0 ")
					.append("AND COALESCE(bp.AbERP_Gender_ID,0) <> rv.AbERP_Gender_ID")
					.append(')');
		}

		if (needs.empCount > 0) {
			if (sql.length() > 0) {
				sql.append(" AND ");
			}
			sql.append("NOT EXISTS (")
					.append("SELECT 1 FROM AbERP_Related_Rostering_Needs_V rv ")
					.append("WHERE rv.AbERP_Rostered_Shift_ID = ").append(id).append(' ')
					.append("AND rv.IsActive = 'Y' AND rv.AbERP_NeedType = 'EMP' ")
					.append("AND rv.AbERP_User_Contact_ID = au.AD_User_ID")
					.append(')');
		}

		return sql.length() > 0 ? sql.toString() : null;
	}

	private NeedsSummary summarizeRelatedNeeds(Integer shiftId) {
		if (shiftId == null || shiftId.intValue() <= 0) {
			return NeedsSummary.EMPTY;
		}
		int id = shiftId.intValue();
		int crd = DB.getSQLValue(null,
				"SELECT COUNT(*) FROM AbERP_Related_Rostering_Needs_V rv "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='CRD' AND COALESCE(rv.AbERP_Credentials_ID,0)>0",
				id);
		int gdr = DB.getSQLValue(null,
				"SELECT COUNT(*) FROM AbERP_Related_Rostering_Needs_V rv "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='GDR' AND COALESCE(rv.AbERP_Gender_ID,0)>0",
				id);
		int emp = DB.getSQLValue(null,
				"SELECT COUNT(*) FROM AbERP_Related_Rostering_Needs_V rv "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='EMP' AND COALESCE(rv.AbERP_User_Contact_ID,0)>0",
				id);
		if (crd < 0) {
			crd = 0;
		}
		if (gdr < 0) {
			gdr = 0;
		}
		if (emp < 0) {
			emp = 0;
		}
		return new NeedsSummary(crd, gdr, emp);
	}

	/**
	 * Display range prefers StartTime/EndTime when set; otherwise StartDate/EndDate.
	 * When date and time are split (time on 1970-01-01), merge calendar date + clock.
	 */
	private Timestamp[] resolveShiftDisplayRange() {
		ShiftTimes times = resolveShiftTimes();
		if (times == null) {
			return null;
		}
		Timestamp start = combineDateAndTime(times.startDate, times.startTime);
		Timestamp end = combineDateAndTime(times.endDate, times.endTime);
		if (start == null) {
			start = times.startTime != null ? times.startTime : times.startDate;
		}
		if (end == null) {
			end = times.endTime != null ? times.endTime : times.endDate;
		}
		if (start == null || end == null) {
			return null;
		}
		return new Timestamp[] { start, end };
	}

	private Timestamp[] resolveShiftDateRange() {
		ShiftTimes times = resolveShiftTimes();
		if (times == null) {
			return null;
		}
		Timestamp start = times.startDate != null ? times.startDate : times.startTime;
		Timestamp end = times.endDate != null ? times.endDate : times.endTime;
		if (start == null || end == null) {
			return null;
		}
		return new Timestamp[] { start, end };
	}

	private ShiftTimes resolveShiftTimes() {
		// Prefer the launching Shift / Employee tab and DB — do not trust bare
		// window context StartDate/EndDate (other windows pollute those names).
		GridTab staffTab = launchField != null ? launchField.getGridTab() : null;
		if (staffTab != null) {
			ShiftTimes fromStaff = readTimesFromTab(staffTab);
			if (fromStaff.hasDateOrTime()) {
				return fromStaff;
			}
			GridTab parent = staffTab.getParentTab();
			if (parent != null) {
				ShiftTimes fromParent = readTimesFromTab(parent);
				if (fromParent.hasDateOrTime()) {
					return fromParent;
				}
			}
		}

		Integer shiftId = resolveCurrentShiftId();
		if (shiftId != null && shiftId.intValue() > 0) {
			Timestamp startDate = DB.getSQLValueTS(null,
					"SELECT StartDate FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			Timestamp endDate = DB.getSQLValueTS(null,
					"SELECT EndDate FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			Timestamp startTime = DB.getSQLValueTS(null,
					"SELECT StartTime FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			Timestamp endTime = DB.getSQLValueTS(null,
					"SELECT EndTime FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			ShiftTimes fromDb = new ShiftTimes(startDate, endDate, startTime, endTime);
			if (fromDb.hasDateOrTime()) {
				return fromDb;
			}
		}

		// Only use window context dates when this Info is tied to a real shift id
		if (shiftId != null && shiftId.intValue() > 0) {
			Properties ctx = Env.getCtx();
			int windowNo = getWindowNo();
			ShiftTimes fromCtx = new ShiftTimes(
					Env.getContextAsDate(ctx, windowNo, "StartDate"),
					Env.getContextAsDate(ctx, windowNo, "EndDate"),
					Env.getContextAsDate(ctx, windowNo, "StartTime"),
					Env.getContextAsDate(ctx, windowNo, "EndTime"));
			if (fromCtx.hasDateOrTime()) {
				return fromCtx;
			}
		}
		return null;
	}

	private ShiftTimes readTimesFromTab(GridTab tab) {
		return new ShiftTimes(
				asTimestamp(tab.getValue("StartDate")),
				asTimestamp(tab.getValue("EndDate")),
				asTimestamp(tab.getValue("StartTime")),
				asTimestamp(tab.getValue("EndTime")));
	}

	private static Timestamp asTimestamp(Object v) {
		return v instanceof Timestamp ? (Timestamp) v : null;
	}

	/**
	 * Merge calendar day from {@code datePart} with clock from {@code timePart}.
	 * If {@code timePart} is null, return {@code datePart}. If date is null, return time.
	 */
	private static Timestamp combineDateAndTime(Timestamp datePart, Timestamp timePart) {
		if (datePart == null && timePart == null) {
			return null;
		}
		if (timePart == null) {
			return datePart;
		}
		if (datePart == null) {
			return timePart;
		}
		// If datePart already carries a non-midnight time and timePart equals datePart, keep datePart
		Calendar dateCal = Calendar.getInstance();
		dateCal.setTimeInMillis(datePart.getTime());
		Calendar timeCal = Calendar.getInstance();
		timeCal.setTimeInMillis(timePart.getTime());

		boolean dateHasClock = dateCal.get(Calendar.HOUR_OF_DAY) != 0
				|| dateCal.get(Calendar.MINUTE) != 0
				|| dateCal.get(Calendar.SECOND) != 0;
		boolean timeIsEpochDay = timeCal.get(Calendar.YEAR) <= 1971;

		if (dateHasClock && !timeIsEpochDay
				&& datePart.getTime() == timePart.getTime()) {
			return datePart;
		}

		dateCal.set(Calendar.HOUR_OF_DAY, timeCal.get(Calendar.HOUR_OF_DAY));
		dateCal.set(Calendar.MINUTE, timeCal.get(Calendar.MINUTE));
		dateCal.set(Calendar.SECOND, timeCal.get(Calendar.SECOND));
		dateCal.set(Calendar.MILLISECOND, 0);
		return new Timestamp(dateCal.getTimeInMillis());
	}

	private Integer resolveCurrentShiftId() {
		Properties ctx = Env.getCtx();
		int windowNo = getWindowNo();
		int fromCtx = Env.getContextAsInt(ctx, windowNo, "AbERP_Rostered_Shift_ID");
		if (fromCtx > 0) {
			return Integer.valueOf(fromCtx);
		}
		if (launchField != null && launchField.getGridTab() != null) {
			Object v = launchField.getGridTab().getValue("AbERP_Rostered_Shift_ID");
			if (v instanceof Number) {
				return Integer.valueOf(((Number) v).intValue());
			}
			GridTab parent = launchField.getGridTab().getParentTab();
			if (parent != null) {
				v = parent.getValue("AbERP_Rostered_Shift_ID");
				if (v instanceof Number) {
					return Integer.valueOf(((Number) v).intValue());
				}
			}
		}
		return null;
	}

	private static final class ShiftTimes {
		final Timestamp startDate;
		final Timestamp endDate;
		final Timestamp startTime;
		final Timestamp endTime;

		ShiftTimes(Timestamp startDate, Timestamp endDate, Timestamp startTime, Timestamp endTime) {
			this.startDate = startDate;
			this.endDate = endDate;
			this.startTime = startTime;
			this.endTime = endTime;
		}

		boolean hasDateOrTime() {
			return startDate != null || endDate != null || startTime != null || endTime != null;
		}
	}

	private static final class NeedsSummary {
		static final NeedsSummary EMPTY = new NeedsSummary(0, 0, 0);
		final int crdCount;
		final int gdrCount;
		final int empCount;

		NeedsSummary(int crdCount, int gdrCount, int empCount) {
			this.crdCount = crdCount;
			this.gdrCount = gdrCount;
			this.empCount = empCount;
		}

		boolean hasAny() {
			return crdCount > 0 || gdrCount > 0 || empCount > 0;
		}

		String describe() {
			StringBuilder sb = new StringBuilder("Related needs:");
			boolean first = true;
			if (crdCount > 0) {
				sb.append(' ').append(crdCount).append(" credential");
				if (crdCount != 1) {
					sb.append('s');
				}
				first = false;
			}
			if (gdrCount > 0) {
				if (!first) {
					sb.append(',');
				}
				sb.append(' ').append(gdrCount).append(" gender");
				first = false;
			}
			if (empCount > 0) {
				if (!first) {
					sb.append(',');
				}
				sb.append(' ').append(empCount).append(" restricted employee");
				if (empCount != 1) {
					sb.append('s');
				}
			}
			sb.append('.');
			return sb.toString();
		}
	}
}
