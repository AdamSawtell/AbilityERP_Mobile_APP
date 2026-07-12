package com.aberp.rostering.staffinfo.info;

import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;
import java.util.Properties;

import org.adempiere.webui.component.Checkbox;
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
import org.compiere.util.Util;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zul.Hbox;
import org.zkoss.zul.Vbox;

/**
 * Staff Rostering Info Window enhancements:
 * <ul>
 *   <li>Auto-wrap {@code %} on Like criteria</li>
 *   <li>Context banner (Shift / Required / Filters) with credential names</li>
 *   <li>Shift-window leave / overlap exclusions (toggle via Show Unavailable Staff)</li>
 *   <li>Related Rostering Needs match (credentials / gender / restricted employee)
 *       with Show Unmatched Staff to include non-matches;
 *       credentials must be active and valid for the shift Start/End dates</li>
 * </ul>
 */
public class StaffRosteringInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "2b4ab146-0809-47c6-96f3-8b841d60a6bf";
	public static final String COL_SHOW_UNMATCHED = "AbERP_ShowUnmatchedStaff";

	private final GridField launchField;
	private Label contextBanner;
	private Checkbox showUnmatchedCheckbox;
	private Checkbox showUnavailableCheckbox;

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
		// Always multi-select so toolbar Select All / row checkboxes work for fill UX.
		super(windowNo, tableName, keyColumn, queryValue, true, whereClause, AD_InfoWindow_ID, lookup, field);
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
		// Criteria stay editable even when AD_InfoColumn.IsReadOnly=Y (needed so the
		// result grid does not paint dropdown editors on the selected row).
		ensureCriteriaEditorsWritable();
		ensureContextBanner(north);
	}

	/** Keep north criteria editors writable after grid columns are marked read-only. */
	private void ensureCriteriaEditorsWritable() {
		if (editors == null) {
			return;
		}
		for (WEditor editor : editors) {
			if (editor == null) {
				continue;
			}
			editor.setReadWrite(true);
		}
	}

	@Override
	protected void executeQuery() {
		autoWrapLikeCriteria();
		clearInvalidIdCriteria();
		if (contextBanner != null) {
			contextBanner.setValue(buildContextBannerText());
		}
		super.executeQuery();
	}

	@Override
	protected String getSQLWhere() {
		// Show Unmatched is a Java checkbox. Also clear/strip any leftover AD criterion.
		WEditor showUnmatchedEditor = findEditor(COL_SHOW_UNMATCHED);
		Object savedShowUnmatched = null;
		boolean cleared = false;
		if (showUnmatchedEditor != null) {
			savedShowUnmatched = showUnmatchedEditor.getValue();
			showUnmatchedEditor.setValue(null);
			cleared = true;
		}

		try {
			// InfoWindow appends getSQLWhere() directly after m_sqlMain (which already
			// ends with "WHERE <windowWhere>"). The fragment MUST start with " AND "
			// when non-empty — never strip that leading AND.
			String where = stripShowUnmatchedSql(super.getSQLWhere());
			StringBuilder extra = new StringBuilder();
			if (!isShowUnavailableSelected()) {
				appendClause(extra, buildShiftDateEligibilitySql());
			}

			boolean showUnmatched = isShowUnmatchedSelected() || isYes(savedShowUnmatched);
			if (!showUnmatched) {
				appendClause(extra, buildNeedsMatchSql());
			}

			if (extra.length() == 0) {
				return ensureLeadingAnd(where);
			}
			if (Util.isEmpty(where, true)) {
				return ensureLeadingAnd(extra.toString());
			}
			return ensureLeadingAnd(where + " AND " + extra);
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
	 * Table/Table Direct / Multi-Select criteria often hold -1 (or {-1}) when blank.
	 * ZK Intbox "no negative" then throws "non-negative only" on ReQuery
	 * (esp. with All/Any checked). Hidden query criteria still build editors.
	 */
	private void clearInvalidIdCriteria() {
		if (editors == null || editors.isEmpty()) {
			return;
		}
		for (WEditor editor : editors) {
			if (editor == null || editor.getGridField() == null) {
				continue;
			}
			int displayType = editor.getGridField().getDisplayType();
			boolean idLike = DisplayType.isID(displayType)
					|| displayType == DisplayType.Integer
					|| displayType == DisplayType.Table
					|| displayType == DisplayType.TableDir
					|| displayType == DisplayType.Search
					|| displayType == DisplayType.ChosenMultipleSelectionTable
					|| displayType == DisplayType.ChosenMultipleSelectionSearch
					|| displayType == DisplayType.ChosenMultipleSelectionList;
			if (!idLike) {
				continue;
			}
			Object value = editor.getValue();
			if (value == null) {
				continue;
			}
			if (value instanceof Object[]) {
				Object[] arr = (Object[]) value;
				if (arr.length == 0 || onlyNonPositiveIds(arr)) {
					editor.setValue(null);
				}
				continue;
			}
			if (value instanceof java.util.Collection) {
				java.util.Collection<?> col = (java.util.Collection<?>) value;
				if (col.isEmpty() || onlyNonPositiveIds(col.toArray())) {
					editor.setValue(null);
				}
				continue;
			}
			int id = 0;
			if (value instanceof Number) {
				id = ((Number) value).intValue();
			} else {
				try {
					id = Integer.parseInt(value.toString().trim());
				} catch (Exception ex) {
					continue;
				}
			}
			if (id <= 0) {
				editor.setValue(null);
			}
		}
	}

	private static boolean onlyNonPositiveIds(Object[] values) {
		if (values == null || values.length == 0) {
			return true;
		}
		for (Object v : values) {
			if (v == null) {
				continue;
			}
			int id;
			if (v instanceof Number) {
				id = ((Number) v).intValue();
			} else {
				try {
					id = Integer.parseInt(v.toString().trim());
				} catch (Exception ex) {
					return false;
				}
			}
			if (id > 0) {
				return false;
			}
		}
		return true;
	}

	/**
	 * InfoWindow concatenates getSQLWhere() onto m_sqlMain without inserting AND.
	 * Non-empty fragments must therefore start with {@code AND}.
	 */
	private static String ensureLeadingAnd(String where) {
		if (Util.isEmpty(where, true)) {
			return "";
		}
		String trimmed = where.trim();
		if (trimmed.regionMatches(true, 0, "AND", 0, 3)) {
			return " " + trimmed;
		}
		return " AND " + trimmed;
	}

	/**
	 * Remove Show-Unmatched flag fragments InfoWindow may still emit.
	 * Legacy SelectClauses: constant {@code 'N'}/{@code 'Y'}, {@code 0}, or
	 * {@code au.IsActive} (real column — must not leak into WHERE as a fake criterion).
	 * Preserves a leading {@code AND} so {@link #ensureLeadingAnd} stays idempotent.
	 */
	private static String stripShowUnmatchedSql(String where) {
		if (Util.isEmpty(where, true)) {
			return where;
		}
		boolean hadLeadingAnd = where.trim().regionMatches(true, 0, "AND", 0, 3);
		String cleaned = where;
		cleaned = cleaned.replaceAll("(?i)\\(\\s*'[YN]'\\s*=\\s*'[YN]'\\s*\\)", " ");
		cleaned = cleaned.replaceAll("(?i)\\(\\s*0\\s*=\\s*'[YN]'\\s*\\)", " ");
		cleaned = cleaned.replaceAll("(?i)(?<!\\w)'[YN]'\\s*=\\s*'[YN]'", " ");
		cleaned = cleaned.replaceAll("(?i)(?<!\\w)0\\s*=\\s*'[YN]'", " ");
		// SelectClause au.IsActive (Show Unmatched) — do not leave bare au.IsActive='Y'
		cleaned = cleaned.replaceAll("(?i)\\(\\s*au\\.IsActive\\s*=\\s*'[YN]'\\s*\\)", " ");
		cleaned = cleaned.replaceAll("(?i)(?<!\\w)au\\.IsActive\\s*=\\s*'[YN]'", " ");
		cleaned = cleaned.replaceAll("(?i)\\bAND\\s+AND\\b", " AND ");
		cleaned = cleaned.replaceAll("(?i)^\\s*AND\\s+", "");
		cleaned = cleaned.replaceAll("(?i)\\s+AND\\s*$", "");
		cleaned = cleaned.replaceAll("\\s{2,}", " ").trim();
		if (cleaned.isEmpty()) {
			return "";
		}
		return hadLeadingAnd ? " AND " + cleaned : cleaned;
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
						+ "font-size:12px;line-height:1.45;white-space:pre-line;");

		showUnavailableCheckbox = new Checkbox();
		showUnavailableCheckbox.setText("Show Unavailable Staff");
		showUnavailableCheckbox.setTooltiptext(
				"When unticked (default), staff on approved leave or already rostered on an "
						+ "overlapping shift for this window are hidden. Tick to include them.");
		showUnavailableCheckbox.setChecked(false);
		showUnavailableCheckbox.addEventListener(Events.ON_CHECK, event -> {
			if (contextBanner != null) {
				contextBanner.setValue(buildContextBannerText());
			}
		});

		showUnmatchedCheckbox = new Checkbox();
		showUnmatchedCheckbox.setText("Show Unmatched Staff");
		showUnmatchedCheckbox.setTooltiptext(
				"When unticked (default), only staff matching Related Rostering Needs are listed. "
						+ "Credentials must be active and valid for the shift Start/End. "
						+ "Tick to include staff who do not meet those needs.");
		showUnmatchedCheckbox.setChecked(false);
		showUnmatchedCheckbox.addEventListener(Events.ON_CHECK, event -> {
			if (contextBanner != null) {
				contextBanner.setValue(buildContextBannerText());
			}
		});

		Hbox flagRow = new Hbox();
		flagRow.setWidth("100%");
		flagRow.setSpacing("16px");
		flagRow.appendChild(showUnavailableCheckbox);
		flagRow.appendChild(showUnmatchedCheckbox);

		Vbox header = new Vbox();
		header.setWidth("100%");
		header.setSpacing("4px");
		header.appendChild(contextBanner);
		header.appendChild(flagRow);

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
			northChild.insertBefore(header, northChild.getFirstChild());
			return;
		}

		// Single content under north-body (or similar): wrap content in Vbox
		if (northChild.getChildren().size() == 1 && northChild.getFirstChild() != null) {
			Component content = northChild.getFirstChild();
			Vbox wrap = new Vbox();
			wrap.setWidth("100%");
			wrap.setSpacing("6px");
			content.detach();
			wrap.appendChild(header);
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
			wrap.appendChild(header);
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
		boolean showUnavailable = isShowUnavailableSelected();
		boolean showUnmatched = isShowUnmatchedSelected();

		if (range == null || range[0] == null || range[1] == null) {
			if (shiftId != null && shiftId.intValue() > 0) {
				StringBuilder sb = new StringBuilder();
				sb.append("Shift: #").append(Util.isEmpty(docNo, true) ? shiftId : docNo);
				sb.append(" | (no Start/End times in context)\n");
				sb.append("Required: ").append(needs.requiredLine()).append('\n');
				sb.append(buildFiltersLine(showUnavailable, showUnmatched, needs.hasCredentials()));
				return sb.toString();
			}
			return "No shift in context. Open from Shift → Employee to apply leave/overlap and "
					+ "required-credential filters.\n"
					+ "Required: (none)\n"
					+ "Filters: Reminder: Check employee alerts before assigning.";
		}

		StringBuilder sb = new StringBuilder();
		sb.append("Shift: #").append(Util.isEmpty(docNo, true) ? "?" : docNo);
		sb.append(" | ").append(formatBannerRange(range[0], range[1])).append('\n');
		sb.append("Required: ").append(needs.requiredLine()).append('\n');
		sb.append(buildFiltersLine(showUnavailable, showUnmatched, needs.hasCredentials()));
		return sb.toString();
	}

	private static String buildFiltersLine(boolean showUnavailable, boolean showUnmatched,
			boolean hasCredentials) {
		StringBuilder sb = new StringBuilder("Filters: ");
		if (showUnavailable) {
			sb.append("Including unavailable staff and overlapping shifts");
		} else {
			sb.append("Excluding unavailable staff and overlapping shifts")
					.append(" (tick \"Show Unavailable Staff\" to include)");
		}
		sb.append("; ");
		if (!hasCredentials) {
			sb.append("no required credentials on this shift");
		} else if (showUnmatched) {
			sb.append("including staff without valid required credentials");
		} else {
			sb.append("showing only staff with valid required credentials")
					.append(" (tick \"Show Unmatched Staff\" to include)");
		}
		sb.append(". Reminder: Check employee alerts before assigning.");
		return sb.toString();
	}

	private boolean isShowUnmatchedSelected() {
		if (showUnmatchedCheckbox != null) {
			return showUnmatchedCheckbox.isChecked();
		}
		WEditor ed = findEditor(COL_SHOW_UNMATCHED);
		return ed != null && isYes(ed.getValue());
	}

	private boolean isShowUnavailableSelected() {
		return showUnavailableCheckbox != null && showUnavailableCheckbox.isChecked();
	}

	/** Banner range: {@code 9 Jul 2026, 4:00 PM – 11:00 PM}. */
	private String formatBannerRange(Timestamp start, Timestamp end) {
		SimpleDateFormat day = new SimpleDateFormat("d MMM yyyy", Locale.ENGLISH);
		SimpleDateFormat time = new SimpleDateFormat("h:mm a", Locale.ENGLISH);
		String startDay = day.format(start);
		String endDay = day.format(end);
		if (startDay.equals(endDay)) {
			return startDay + ", " + time.format(start) + " – " + time.format(end);
		}
		return startDay + ", " + time.format(start) + " – " + endDay + ", " + time.format(end);
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
		List<String> required = new ArrayList<>();

		String credNames = DB.getSQLValueString(null,
				"SELECT string_agg(x.name, ', ' ORDER BY x.name) FROM ("
						+ "SELECT DISTINCT c.Name AS name FROM AbERP_Related_Rostering_Needs_V rv "
						+ "INNER JOIN AbERP_Credentials c ON (c.AbERP_Credentials_ID = rv.AbERP_Credentials_ID) "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='CRD' AND COALESCE(rv.AbERP_Credentials_ID,0)>0"
						+ ") x",
				id);
		int crd = 0;
		if (!Util.isEmpty(credNames, true)) {
			for (String part : credNames.split(",")) {
				String name = part.trim();
				if (!name.isEmpty()) {
					required.add(name);
					crd++;
				}
			}
		}

		String genderNames = DB.getSQLValueString(null,
				"SELECT string_agg(x.name, ', ' ORDER BY x.name) FROM ("
						+ "SELECT DISTINCT g.Name AS name FROM AbERP_Related_Rostering_Needs_V rv "
						+ "INNER JOIN AbERP_Gender g ON (g.AbERP_Gender_ID = rv.AbERP_Gender_ID) "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='GDR' AND COALESCE(rv.AbERP_Gender_ID,0)>0"
						+ ") x",
				id);
		int gdr = 0;
		if (!Util.isEmpty(genderNames, true)) {
			for (String part : genderNames.split(",")) {
				String name = part.trim();
				if (!name.isEmpty()) {
					required.add(name);
					gdr++;
				}
			}
		}

		String empNames = DB.getSQLValueString(null,
				"SELECT string_agg(x.name, ', ' ORDER BY x.name) FROM ("
						+ "SELECT DISTINCT u.Name AS name FROM AbERP_Related_Rostering_Needs_V rv "
						+ "INNER JOIN AD_User u ON (u.AD_User_ID = rv.AbERP_User_Contact_ID) "
						+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
						+ "AND rv.AbERP_NeedType='EMP' AND COALESCE(rv.AbERP_User_Contact_ID,0)>0"
						+ ") x",
				id);
		int emp = 0;
		if (!Util.isEmpty(empNames, true)) {
			for (String part : empNames.split(",")) {
				String name = part.trim();
				if (!name.isEmpty()) {
					required.add("Exclude " + name);
					emp++;
				}
			}
		}

		return new NeedsSummary(crd, gdr, emp, required);
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
		static final NeedsSummary EMPTY = new NeedsSummary(0, 0, 0, new ArrayList<String>());
		final int crdCount;
		final int gdrCount;
		final int empCount;
		final List<String> requiredLabels;

		NeedsSummary(int crdCount, int gdrCount, int empCount, List<String> requiredLabels) {
			this.crdCount = crdCount;
			this.gdrCount = gdrCount;
			this.empCount = empCount;
			this.requiredLabels = requiredLabels != null ? requiredLabels : new ArrayList<String>();
		}

		boolean hasAny() {
			return crdCount > 0 || gdrCount > 0 || empCount > 0;
		}

		boolean hasCredentials() {
			return crdCount > 0;
		}

		String requiredLine() {
			if (requiredLabels.isEmpty()) {
				return "(none)";
			}
			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < requiredLabels.size(); i++) {
				if (i > 0) {
					sb.append(", ");
				}
				sb.append(requiredLabels.get(i));
			}
			return sb.toString();
		}
	}
}
