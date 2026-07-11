package com.aberp.rostering.staffinfo.info;

import java.sql.Timestamp;
import java.text.SimpleDateFormat;
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
 *   <li>Context banner showing shift Start/End used for leave/overlap filters</li>
 *   <li>When opened from Shift Employee with Start/End dates, exclude staff on
 *       approved leave overlapping the shift window and staff already rostered
 *       on an overlapping non-template shift — without {@code @StartDate@} in
 *       AD WhereClause</li>
 * </ul>
 */
public class StaffRosteringInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "2b4ab146-0809-47c6-96f3-8b841d60a6bf";

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
	 * so officers can see which shift dates drive leave/overlap filtering.
	 * Prefer this over AD read-only {@code @StartDate@} criteria (those break loadInfoDefinition).
	 */
	@Override
	protected void renderParameterPane(org.zkoss.zul.North north) {
		super.renderParameterPane(north);
		ensureContextBanner(north);
	}

	@Override
	protected void executeQuery() {
		autoWrapLikeCriteria();
		super.executeQuery();
	}

	@Override
	protected String getSQLWhere() {
		String where = super.getSQLWhere();
		String extra = buildShiftDateEligibilitySql();
		if (Util.isEmpty(extra, true)) {
			return where;
		}
		if (Util.isEmpty(where, true)) {
			return extra;
		}
		return where + " AND " + extra;
	}

	private void ensureContextBanner(org.zkoss.zul.North north) {
		if (north == null) {
			return;
		}
		// Borderlayout North allows only one child — wrap banner + existing pane.
		Component existing = north.getFirstChild();
		if (existing == null) {
			return;
		}
		if (contextBanner != null && contextBanner.getParent() != null) {
			contextBanner.setValue(buildContextBannerText());
			return;
		}
		// Already wrapped from a prior call
		if (existing instanceof Vbox && contextBanner != null) {
			contextBanner.setValue(buildContextBannerText());
			return;
		}

		contextBanner = new Label(buildContextBannerText());
		contextBanner.setStyle(
				"display:block;width:100%;box-sizing:border-box;"
						+ "padding:8px 10px;margin:0;"
						+ "background:#EEF3F8;border:1px solid #C5D0DC;color:#1F2A37;"
						+ "font-size:12px;line-height:1.35;white-space:normal;");

		Vbox wrap = new Vbox();
		wrap.setWidth("100%");
		wrap.setSpacing("6px");
		existing.detach();
		wrap.appendChild(contextBanner);
		wrap.appendChild(existing);
		north.appendChild(wrap);
	}

	private String buildContextBannerText() {
		Timestamp[] range = resolveShiftDateRange();
		Integer shiftId = resolveCurrentShiftId();
		String docNo = null;
		if (shiftId != null && shiftId.intValue() > 0) {
			docNo = DB.getSQLValueString(null,
					"SELECT DocumentNo FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?",
					shiftId.intValue());
		}

		if (range != null && range[0] != null && range[1] != null) {
			StringBuilder sb = new StringBuilder();
			sb.append("Shift filter active");
			if (!Util.isEmpty(docNo, true)) {
				sb.append(" (").append(docNo).append(')');
			}
			sb.append(": ").append(formatDate(range[0])).append(" – ").append(formatDate(range[1]));
			sb.append(". Hiding staff on approved leave or already rostered on an overlapping shift for these dates.");
			return sb.toString();
		}

		return "No shift Start/End in context. Only the On Approved Leave (today) filter applies — "
				+ "open from Shift → Employee to use shift-date leave/overlap checks.";
	}

	private String formatDate(Timestamp ts) {
		Language lang = Env.getLanguage(Env.getCtx());
		SimpleDateFormat df = DisplayType.getDateFormat(DisplayType.Date, lang);
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
	 * Uses TO_DATE literals so we do not disturb InfoWindow parameter binding.
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

	private Timestamp[] resolveShiftDateRange() {
		Properties ctx = Env.getCtx();
		int windowNo = getWindowNo();

		Timestamp start = Env.getContextAsDate(ctx, windowNo, "StartDate");
		Timestamp end = Env.getContextAsDate(ctx, windowNo, "EndDate");
		if (start != null && end != null) {
			return new Timestamp[] { start, end };
		}

		GridTab staffTab = launchField != null ? launchField.getGridTab() : null;
		if (staffTab != null) {
			Object s = staffTab.getValue("StartDate");
			Object e = staffTab.getValue("EndDate");
			if (s instanceof Timestamp && e instanceof Timestamp) {
				return new Timestamp[] { (Timestamp) s, (Timestamp) e };
			}
			GridTab parent = staffTab.getParentTab();
			if (parent != null) {
				s = parent.getValue("StartDate");
				e = parent.getValue("EndDate");
				if (s instanceof Timestamp && e instanceof Timestamp) {
					return new Timestamp[] { (Timestamp) s, (Timestamp) e };
				}
			}
		}

		Integer shiftId = resolveCurrentShiftId();
		if (shiftId != null && shiftId.intValue() > 0) {
			Timestamp startDb = DB.getSQLValueTS(null,
					"SELECT StartDate FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			Timestamp endDb = DB.getSQLValueTS(null,
					"SELECT EndDate FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
			if (startDb != null && endDb != null) {
				return new Timestamp[] { startDb, endDb };
			}
		}
		return null;
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
}
