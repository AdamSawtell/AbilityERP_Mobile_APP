package com.aberp.leave.planning.info;

import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;

import org.adempiere.webui.component.Button;
import org.adempiere.webui.editor.WEditor;
import org.adempiere.webui.info.InfoWindow;
import org.compiere.model.GridField;
import org.compiere.model.MInfoWindow;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Util;
import org.zkoss.util.media.AMedia;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zul.A;
import org.zkoss.zul.Div;
import org.zkoss.zul.Filedownload;
import org.zkoss.zul.Hlayout;
import org.zkoss.zul.Label;
import org.zkoss.zul.Listbox;
import org.zkoss.zul.Listcell;
import org.zkoss.zul.Listhead;
import org.zkoss.zul.Listheader;
import org.zkoss.zul.Listitem;
import org.zkoss.zul.North;
import org.zkoss.zul.Space;
import org.zkoss.zul.Vbox;

/**
 * Leave Planning Info Window:
 * <ul>
 *   <li>Summary banner with clickable Approver Status filters</li>
 *   <li>Export CSV of the current query (all matching rows)</li>
 *   <li>Risk cues: Declined/Reviewing first + status cell colour</li>
 *   <li>Criteria stay editable when result columns are AD IsReadOnly=Y</li>
 * </ul>
 */
public class LeavePlanningInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "16a016iw-c0d4-4f01-8e15-000000000001";

	private static final String STATUS_RV = "RV";
	private static final String STATUS_AP = "AP";
	private static final String STATUS_DC = "DC";

	private Div summaryBanner;
	private Label periodLabel;
	private Label typeLabel;
	private Label statusHint;
	private A linkReviewing;
	private A linkApproved;
	private A linkDeclined;
	private A linkAll;
	private Button exportButton;

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

	@Override
	protected void renderItems() {
		super.renderItems();
		colourApproverStatusCells();
	}

	/**
	 * Soft tint on Approver Status cells after each render/page.
	 * Declined = rose, Reviewing = amber, Approved = green.
	 * Resolves column via list header label (no MiniTable / ColumnInfo dependency).
	 */
	private void colourApproverStatusCells() {
		if (contentPanel == null) {
			return;
		}
		Listbox box = contentPanel;
		int statusCell = findApproverStatusCellIndex(box);
		if (statusCell < 0) {
			return;
		}
		for (Listitem item : box.getItems()) {
			if (item == null) {
				continue;
			}
			java.util.List<Component> cells = item.getChildren();
			if (cells == null || statusCell >= cells.size()) {
				continue;
			}
			Component cellComp = cells.get(statusCell);
			if (!(cellComp instanceof Listcell)) {
				continue;
			}
			Listcell cell = (Listcell) cellComp;
			String text = cell.getLabel();
			if (Util.isEmpty(text, true) && cell.getFirstChild() instanceof Label) {
				text = ((Label) cell.getFirstChild()).getValue();
			}
			String style = statusCellStyle(text);
			if (style != null) {
				cell.setStyle(style);
			}
		}
	}

	private static int findApproverStatusCellIndex(Listbox box) {
		Listhead head = box.getListhead();
		if (head == null) {
			return -1;
		}
		int idx = 0;
		for (Component c : head.getChildren()) {
			String label = null;
			if (c instanceof Listheader) {
				label = ((Listheader) c).getLabel();
			} else if (c instanceof Label) {
				label = ((Label) c).getValue();
			} else {
				label = c.toString();
			}
			if (label != null && label.toLowerCase().contains("approver status")) {
				return idx;
			}
			idx++;
		}
		return -1;
	}

	private static String statusCellStyle(String text) {
		if (Util.isEmpty(text, true)) {
			return null;
		}
		String t = text.trim();
		if (t.equalsIgnoreCase("Declined") || STATUS_DC.equalsIgnoreCase(t)) {
			return "background:#FDE8E8;color:#8B1A1A;font-weight:600;";
		}
		if (t.equalsIgnoreCase("Reviewing") || STATUS_RV.equalsIgnoreCase(t)) {
			return "background:#FFF4D6;color:#7A5A00;font-weight:600;";
		}
		if (t.equalsIgnoreCase("Approved") || STATUS_AP.equalsIgnoreCase(t)) {
			return "background:#E6F5EA;color:#1B5E2A;font-weight:600;";
		}
		return null;
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

		summaryBanner = new Div();
		summaryBanner.setStyle(
				"display:block;width:100%;box-sizing:border-box;"
						+ "padding:8px 10px;margin:0;"
						+ "background:#EEF3F8;border:1px solid #C5D0DC;color:#1F2A37;"
						+ "font-size:12px;line-height:1.45;");

		periodLabel = new Label("Leave Planning summary — set Planning Start and Planning End, then Search.");
		periodLabel.setStyle("display:block;margin-bottom:4px;");

		statusHint = new Label("By status (click to filter): ");
		statusHint.setStyle("white-space:nowrap;");

		linkReviewing = statusLink("Reviewing", STATUS_RV);
		linkApproved = statusLink("Approved", STATUS_AP);
		linkDeclined = statusLink("Declined", STATUS_DC);
		linkAll = statusLink("All", null);

		Hlayout statusRow = new Hlayout();
		statusRow.setSpacing("4px");
		statusRow.appendChild(statusHint);
		statusRow.appendChild(linkReviewing);
		statusRow.appendChild(sep());
		statusRow.appendChild(linkApproved);
		statusRow.appendChild(sep());
		statusRow.appendChild(linkDeclined);
		statusRow.appendChild(sep());
		statusRow.appendChild(linkAll);
		statusRow.appendChild(new Space());
		exportButton = new Button("Export CSV");
		exportButton.setTooltiptext("Download all rows matching the current Search as CSV");
		exportButton.addEventListener(Events.ON_CLICK, event -> exportCsv());
		statusRow.appendChild(exportButton);

		typeLabel = new Label("By status / type: —");
		typeLabel.setStyle("display:block;margin-top:4px;white-space:pre-line;");

		summaryBanner.appendChild(periodLabel);
		summaryBanner.appendChild(statusRow);
		summaryBanner.appendChild(typeLabel);

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

	private static Label sep() {
		Label s = new Label("|");
		s.setStyle("color:#8A94A6;");
		return s;
	}

	private A statusLink(String label, String statusCode) {
		A a = new A(label);
		a.setStyle("cursor:pointer;text-decoration:underline;color:#0B5CAD;");
		a.setAttribute("lpStatus", statusCode);
		a.addEventListener(Events.ON_CLICK, event -> applyApproverFilter(statusCode));
		return a;
	}

	private void applyApproverFilter(String statusCode) {
		WEditor ed = findEditor("AbERP_ApproverStatus");
		if (ed == null) {
			return;
		}
		ed.setValue(Util.isEmpty(statusCode, true) ? null : statusCode);
		try {
			ed.getGridField().setValue(Util.isEmpty(statusCode, true) ? null : statusCode, false);
		} catch (Exception ignore) {
			// Field update is best-effort; editor value drives the query.
		}
		onUserQuery();
	}

	private void refreshSummaryBanner() {
		if (summaryBanner == null) {
			return;
		}
		Timestamp start = toTimestamp(editorValue("AbERP_PlanningStart"));
		Timestamp end = toTimestamp(editorValue("AbERP_PlanningEnd"));
		if (start == null || end == null) {
			periodLabel.setValue("Leave Planning summary — set Planning Start and Planning End, then Search.");
			setStatusCounts(null);
			typeLabel.setValue("By status / type: —");
			return;
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
			String filterNote = Util.isEmpty(approver, true) ? "" : (" · filtered: " + statusName(approver));

			periodLabel.setValue("Period " + period + locLabel + filterNote);
			setStatusCounts(parseStatusCounts(byStatus));
			typeLabel.setValue("By status / type: " + (Util.isEmpty(byType, true) ? "—" : byType));
		} catch (Exception ex) {
			periodLabel.setValue("Leave Planning summary unavailable: " + ex.getMessage());
			setStatusCounts(null);
			typeLabel.setValue("By status / type: —");
		}
	}

	private void setStatusCounts(Map<String, Integer> counts) {
		int rv = counts == null ? -1 : counts.getOrDefault(STATUS_RV, 0);
		int ap = counts == null ? -1 : counts.getOrDefault(STATUS_AP, 0);
		int dc = counts == null ? -1 : counts.getOrDefault(STATUS_DC, 0);
		int total = counts == null ? -1 : counts.getOrDefault("TOTAL", 0);

		linkReviewing.setLabel(rv < 0 ? "Reviewing" : ("Reviewing: " + rv));
		linkApproved.setLabel(ap < 0 ? "Approved" : ("Approved: " + ap));
		linkDeclined.setLabel(dc < 0 ? "Declined" : ("Declined: " + dc));
		linkAll.setLabel(total < 0 ? "All" : ("All: " + total));

		String active = toText(editorValue("AbERP_ApproverStatus"));
		styleActive(linkReviewing, STATUS_RV.equals(active));
		styleActive(linkApproved, STATUS_AP.equals(active));
		styleActive(linkDeclined, STATUS_DC.equals(active));
		styleActive(linkAll, Util.isEmpty(active, true));
	}

	private static void styleActive(A link, boolean active) {
		if (active) {
			link.setStyle("cursor:pointer;font-weight:700;color:#0B3D6E;text-decoration:none;");
		} else {
			link.setStyle("cursor:pointer;text-decoration:underline;color:#0B5CAD;");
		}
	}

	/**
	 * Parse "Approved: 21 | Declined: 2  |  Total: 23" into map keyed by status code.
	 */
	private static Map<String, Integer> parseStatusCounts(String byStatus) {
		Map<String, Integer> map = new LinkedHashMap<>();
		map.put(STATUS_RV, 0);
		map.put(STATUS_AP, 0);
		map.put(STATUS_DC, 0);
		map.put("TOTAL", 0);
		if (Util.isEmpty(byStatus, true)) {
			return map;
		}
		for (String part : byStatus.split("\\|")) {
			String p = part.trim();
			int colon = p.lastIndexOf(':');
			if (colon <= 0) {
				continue;
			}
			String name = p.substring(0, colon).trim();
			String num = p.substring(colon + 1).trim().replaceAll("[^0-9]", "");
			if (num.isEmpty()) {
				continue;
			}
			int n = Integer.parseInt(num);
			if (name.equalsIgnoreCase("Reviewing")) {
				map.put(STATUS_RV, n);
			} else if (name.equalsIgnoreCase("Approved")) {
				map.put(STATUS_AP, n);
			} else if (name.equalsIgnoreCase("Declined")) {
				map.put(STATUS_DC, n);
			} else if (name.equalsIgnoreCase("Total")) {
				map.put("TOTAL", n);
			}
		}
		if (map.get("TOTAL") == 0) {
			map.put("TOTAL", map.get(STATUS_RV) + map.get(STATUS_AP) + map.get(STATUS_DC));
		}
		return map;
	}

	private static String statusName(String code) {
		if (STATUS_RV.equals(code)) {
			return "Reviewing";
		}
		if (STATUS_AP.equals(code)) {
			return "Approved";
		}
		if (STATUS_DC.equals(code)) {
			return "Declined";
		}
		return code;
	}

	private void exportCsv() {
		Timestamp start = toTimestamp(editorValue("AbERP_PlanningStart"));
		Timestamp end = toTimestamp(editorValue("AbERP_PlanningEnd"));
		if (start == null || end == null) {
			setStatusLine("Set Planning Start and Planning End before Export CSV", true);
			return;
		}

		BigDecimal loc = toId(editorValue("C_BPartner_Location_ID"));
		String approver = toText(editorValue("AbERP_ApproverStatus"));
		BigDecimal typeId = toId(editorValue("AbERP_Unavailability_Type_ID"));
		BigDecimal userId = toId(editorValue("AbERP_User_Contact_ID"));

		String sql = "SELECT "
				+ " CASE ul.AbERP_ApproverStatus WHEN 'RV' THEN 'Reviewing' WHEN 'AP' THEN 'Approved' WHEN 'DC' THEN 'Declined' ELSE COALESCE(ul.AbERP_ApproverStatus,'') END AS approver_status,"
				+ " COALESCE(ut.Name,'') AS unavailability_type,"
				+ " COALESCE(u.Name,'') AS employee,"
				+ " COALESCE(bpl.Name,'') AS service_location,"
				+ " COALESCE(sup.Name,'') AS supervisor,"
				+ " ul.StartDate::date AS leave_start,"
				+ " ul.EndDate::date AS leave_end,"
				+ " ((ul.EndDate::date - ul.StartDate::date) + 1) AS calendar_days,"
				+ " COALESCE(ul.Note,'') AS note,"
				+ " ul.Created AS created"
				+ " FROM AbERP_Unavailability_Leave ul"
				+ " INNER JOIN AD_User u ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)"
				+ " LEFT JOIN C_BPartner_Location bpl ON (bpl.C_BPartner_Location_ID=u.C_BPartner_Location_ID)"
				+ " LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)"
				+ " LEFT JOIN AD_User sup ON (sup.AD_User_ID=bp.Supervisor_ID)"
				+ " LEFT JOIN AbERP_Unavailability_Type ut ON (ut.AbERP_Unavailability_Type_ID=ul.AbERP_Unavailability_Type_ID)"
				+ " WHERE ul.IsActive='Y'"
				+ " AND ul.EndDate::date >= ?::date"
				+ " AND ul.StartDate::date <= ?::date"
				+ " AND (?::numeric IS NULL OR u.C_BPartner_Location_ID = ?::numeric)"
				+ " AND (?::text IS NULL OR ?::text = '' OR ul.AbERP_ApproverStatus = ?::text)"
				+ " AND (?::numeric IS NULL OR ul.AbERP_Unavailability_Type_ID = ?::numeric)"
				+ " AND (?::numeric IS NULL OR ul.AbERP_User_Contact_ID = ?::numeric)"
				+ " ORDER BY CASE ul.AbERP_ApproverStatus WHEN 'DC' THEN 1 WHEN 'RV' THEN 2 WHEN 'AP' THEN 3 ELSE 9 END, ul.StartDate, u.Name";

		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			ByteArrayOutputStream bos = new ByteArrayOutputStream();
			PrintWriter out = new PrintWriter(new OutputStreamWriter(bos, StandardCharsets.UTF_8));
			out.write('\ufeff'); // Excel-friendly BOM

			pstmt = DB.prepareStatement(sql, null);
			int i = 1;
			pstmt.setTimestamp(i++, start);
			pstmt.setTimestamp(i++, end);
			pstmt.setBigDecimal(i++, loc);
			pstmt.setBigDecimal(i++, loc);
			pstmt.setString(i++, approver);
			pstmt.setString(i++, approver);
			pstmt.setString(i++, approver);
			pstmt.setBigDecimal(i++, typeId);
			pstmt.setBigDecimal(i++, typeId);
			pstmt.setBigDecimal(i++, userId);
			pstmt.setBigDecimal(i++, userId);

			rs = pstmt.executeQuery();
			ResultSetMetaData md = rs.getMetaData();
			int cols = md.getColumnCount();
			for (int c = 1; c <= cols; c++) {
				if (c > 1) {
					out.print(',');
				}
				out.print(csv(md.getColumnLabel(c)));
			}
			out.println();

			int rows = 0;
			while (rs.next()) {
				for (int c = 1; c <= cols; c++) {
					if (c > 1) {
						out.print(',');
					}
					Object v = rs.getObject(c);
					out.print(csv(v == null ? "" : String.valueOf(v)));
				}
				out.println();
				rows++;
			}
			out.flush();

			SimpleDateFormat fileDf = new SimpleDateFormat("yyyyMMdd");
			String name = "LeavePlanning_" + fileDf.format(start) + "_" + fileDf.format(end) + ".csv";
			AMedia media = new AMedia(name, "csv", "text/csv", bos.toByteArray());
			Filedownload.save(media);
			setStatusLine("Exported " + rows + " leave row(s) to " + name, false);
		} catch (Exception ex) {
			setStatusLine("Export CSV failed: " + ex.getMessage(), true);
		} finally {
			DB.close(rs, pstmt);
		}
	}

	private static String csv(String raw) {
		String s = raw == null ? "" : raw.replace("\r\n", " ").replace('\n', ' ').replace('\r', ' ');
		if (s.indexOf('"') >= 0 || s.indexOf(',') >= 0) {
			return '"' + s.replace("\"", "\"\"") + '"';
		}
		return s;
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
