package com.aberp.leave.planning.info;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.adempiere.webui.editor.WEditor;
import org.adempiere.webui.info.InfoWindow;
import org.compiere.model.GridField;
import org.compiere.model.MInfoWindow;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Util;
import org.zkoss.zk.ui.Component;
import org.zkoss.zul.Label;
import org.zkoss.zul.North;
import org.zkoss.zul.Vbox;

/**
 * Leave Planning Info Window:
 * <ul>
 *   <li>Summary banner (approver status + status/type) refreshed on Search</li>
 *   <li>Criteria stay editable when result columns are AD IsReadOnly=Y</li>
 * </ul>
 */
public class LeavePlanningInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "16a016iw-c0d4-4f01-8e15-000000000001";

	private Label summaryBanner;

	public LeavePlanningInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID) {
		this(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, true, null);
	}

	public LeavePlanningInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup) {
		this(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, lookup, null);
	}

	public LeavePlanningInfoWindow(int windowNo, String tableName, String keyColumn, String queryValue,
			boolean multipleSelection, String whereClause, int AD_InfoWindow_ID, boolean lookup, GridField field) {
		super(windowNo, tableName, keyColumn, queryValue, multipleSelection, whereClause, AD_InfoWindow_ID, lookup, field);
	}

	public static boolean matchesInfoWindow(int adInfoWindowId) {
		if (adInfoWindowId <= 0) {
			return false;
		}
		MInfoWindow iw = MInfoWindow.getInfoWindow(adInfoWindowId);
		return iw != null && INFO_WINDOW_UU.equalsIgnoreCase(iw.getAD_InfoWindow_UU());
	}

	@Override
	protected void renderParameterPane(North north) {
		super.renderParameterPane(north);
		ensureCriteriaEditorsWritable();
		ensureSummaryBanner(north);
	}

	@Override
	public void onUserQuery() {
		ensureCriteriaEditorsWritable();
		super.onUserQuery();
	}

	@Override
	protected void executeQuery() {
		ensureCriteriaEditorsWritable();
		refreshSummaryBanner();
		super.executeQuery();
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

	private void ensureSummaryBanner(North north) {
		if (summaryBanner != null && summaryBanner.getParent() != null) {
			refreshSummaryBanner();
			return;
		}

		summaryBanner = new Label(buildSummaryText());
		summaryBanner.setStyle(
				"display:block;width:100%;box-sizing:border-box;"
						+ "padding:8px 10px;margin:0;"
						+ "background:#EEF3F8;border:1px solid #C5D0DC;color:#1F2A37;"
						+ "font-size:12px;line-height:1.45;white-space:pre-line;");

		Vbox header = new Vbox();
		header.setWidth("100%");
		header.setSpacing("4px");
		header.appendChild(summaryBanner);

		Component northChild = north != null ? north.getFirstChild() : null;
		if (northChild == null && parameterGrid != null) {
			Component p = parameterGrid.getParent();
			while (p != null && p.getParent() != null && !(p.getParent() instanceof North)) {
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

	private void refreshSummaryBanner() {
		if (summaryBanner != null) {
			summaryBanner.setValue(buildSummaryText());
		}
	}

	private String buildSummaryText() {
		Timestamp start = toTimestamp(editorValue("AbERP_PlanningStart"));
		Timestamp end = toTimestamp(editorValue("AbERP_PlanningEnd"));
		if (start == null || end == null) {
			return "Leave Planning summary — set Planning Start and Planning End, then Search.";
		}

		try {
			BigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
			String approver = toText(editorValue("AbERP_ApproverStatus"));
			BigDecimal typeId = toId(editorValue("AbERP_Unavailability_Type_ID"));
			BigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

			String byStatus = DB.getSQLValueStringEx(null,
					"SELECT aberp_lp_info_summary_by_status(?, ?, ?, ?, ?, ?)",
					start, end, loc, approver, typeId, userId);
			String byType = DB.getSQLValueStringEx(null,
					"SELECT aberp_lp_info_summary_by_type(?, ?, ?, ?, ?, ?)",
					start, end, loc, approver, typeId, userId);

			SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy", Env.getLanguage(Env.getCtx()).getLocale());
			String period = df.format(new Date(start.getTime())) + " → " + df.format(new Date(end.getTime()));
			String locLabel = loc != null ? (" · Location ID " + loc.intValue()) : " · All locations";

			StringBuilder sb = new StringBuilder();
			sb.append("Period ").append(period).append(locLabel).append('\n');
			sb.append("By status: ").append(Util.isEmpty(byStatus, true) ? "—" : byStatus).append('\n');
			sb.append("By status / type: ").append(Util.isEmpty(byType, true) ? "—" : byType);
			return sb.toString();
		} catch (Exception ex) {
			return "Leave Planning summary unavailable: " + ex.getMessage();
		}
	}

	private Object editorValue(String columnName) {
		WEditor ed = findEditor(columnName);
		return ed != null ? ed.getValue() : null;
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

	private static Timestamp toTimestamp(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof Timestamp) {
			return (Timestamp) value;
		}
		if (value instanceof Date) {
			return new Timestamp(((Date) value).getTime());
		}
		return null;
	}

	private static BigDecimal toId(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof BigDecimal) {
			BigDecimal bd = (BigDecimal) value;
			return bd.signum() <= 0 ? null : bd;
		}
		if (value instanceof Number) {
			long n = ((Number) value).longValue();
			return n <= 0 ? null : BigDecimal.valueOf(n);
		}
		if (value instanceof String) {
			String s = ((String) value).trim();
			if (s.isEmpty() || "-1".equals(s)) {
				return null;
			}
			try {
				BigDecimal bd = new BigDecimal(s);
				return bd.signum() <= 0 ? null : bd;
			} catch (NumberFormatException e) {
				return null;
			}
		}
		return null;
	}

	private static String toText(Object value) {
		if (value == null) {
			return null;
		}
		String s = value.toString().trim();
		return s.isEmpty() ? null : s;
	}
}
