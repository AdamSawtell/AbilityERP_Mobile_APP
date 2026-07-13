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
import org.adempiere.webui.component.ZkCssHelper;
import org.adempiere.webui.editor.WEditor;
import org.adempiere.webui.info.InfoWindow;
import org.compiere.model.GridField;
import org.compiere.model.MInfoWindow;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.KeyNamePair;
import org.compiere.util.Util;
import org.compiere.util.ValueNamePair;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.HtmlBasedComponent;
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
	private boolean colourListenersAttached;

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
		ensureColourListeners();
		colourApproverStatusCells();
		// Renderer finishes after renderItems — re-apply on next AU round-trip
		Events.echoEvent("onLeavePlanningColour", this, null);
	}

	private void ensureColourListeners() {
		if (colourListenersAttached || contentPanel == null) {
			return;
		}
		colourListenersAttached = true;
		addEventListener("onLeavePlanningColour", event -> colourApproverStatusCells());
		contentPanel.addEventListener("onPaging", event -> {
			colourApproverStatusCells();
			Events.echoEvent("onLeavePlanningColour", this, null);
		});
	}

	/**
	 * Soft tint on Approver Status: Declined rose, Reviewing amber, Approved green.
	 * Applies via client JS (survives WListItemRenderer) and mirrors on ZK components.
	 */
	private void colourApproverStatusCells() {
		colourApproverStatusCellsJs();
		colourApproverStatusCellsZk();
	}

	private void colourApproverStatusCellsJs() {
		String js = "setTimeout(function(){(function(){"
				+ "var root=jq('.z-window:visible').filter(function(){"
				+ "  return (jq(this).text()||'').indexOf('Leave Planning summary')>=0;"
				+ "}).last();"
				+ "if(!root.length){ root=jq(document); }"
				+ "var heads=root.find('.z-listheader');"
				+ "var col=-1;"
				+ "heads.each(function(i){"
				+ "  var t=(jq(this).text()||'').toLowerCase().replace(/\\s+/g,' ').trim();"
				+ "  if(t.indexOf('approver status')>=0 || t==='approver'){ col=i; }"
				+ "});"
				+ "if(col<0){ return; }"
				+ "root.find('.z-listbox-body tr.z-listitem').each(function(){"
				+ "  var cells=jq(this).children('td.z-listcell,td');"
				+ "  if(col>=cells.length){ return; }"
				+ "  var cell=cells.eq(col);"
				+ "  var t=(cell.text()||'').replace(/\\s+/g,' ').trim();"
				+ "  var bg=null, fg=null;"
				+ "  if(/^Declined$/i.test(t)||t==='DC'){ bg='#FDE8E8'; fg='#8B1A1A'; }"
				+ "  else if(/^Reviewing$/i.test(t)||t==='RV'){ bg='#FFF4D6'; fg='#7A5A00'; }"
				+ "  else if(/^Approved$/i.test(t)||t==='AP'){ bg='#E6F5EA'; fg='#1B5E2A'; }"
				+ "  if(!bg){ return; }"
				+ "  jq(this).css('background-color', bg);"
				+ "  cell.css({'background-color':bg,'color':fg,'font-weight':'600'});"
				+ "  cell.find('*').css({'background-color':bg,'color':fg});"
				+ "});"
				+ "})();}, 50);";
		try {
			org.zkoss.zk.ui.util.Clients.evalJavaScript(js);
		} catch (Exception ignore) {
			// ZK colour path still attempted below
		}
	}

	private void colourApproverStatusCellsZk() {
		if (contentPanel == null) {
			return;
		}
		Listbox box = contentPanel;
		int statusCell = findApproverStatusCellIndex(box);
		if (statusCell < 0) {
			return;
		}
		int modelCol = statusCell;
		try {
			java.lang.reflect.Method m = box.getClass().getMethod("convertColumnIndexToModel", int.class);
			Object converted = m.invoke(box, statusCell);
			if (converted instanceof Integer) {
				modelCol = ((Integer) converted).intValue();
			}
		} catch (Exception ignore) {
			modelCol = statusCell;
		}
		java.util.List<Listitem> items = box.getItems();
		if (items == null || items.isEmpty()) {
			return;
		}
		int row = 0;
		for (Listitem item : items) {
			if (item == null) {
				row++;
				continue;
			}
			String text = readStatusText(box, item, statusCell, modelCol, row);
			String cellStyle = statusCellStyle(text);
			String rowStyle = statusRowStyle(text);
			if (cellStyle != null || rowStyle != null) {
				if (rowStyle != null) {
					appendStyle(item, rowStyle);
				}
				Listcell cell = listcellAt(item, statusCell);
				if (cell != null && cellStyle != null) {
					appendStyle(cell, cellStyle);
					for (Component child : cell.getChildren()) {
						if (child instanceof HtmlBasedComponent) {
							appendStyle((HtmlBasedComponent) child, cellStyle);
						}
					}
				}
			}
			row++;
		}
	}

	private static void appendStyle(HtmlBasedComponent comp, String style) {
		if (comp == null || Util.isEmpty(style, true)) {
			return;
		}
		ZkCssHelper.appendStyle(comp, style);
	}

	private static Listcell listcellAt(Listitem item, int index) {
		java.util.List<Component> cells = item.getChildren();
		if (cells == null || index < 0 || index >= cells.size()) {
			return null;
		}
		Component cellComp = cells.get(index);
		return cellComp instanceof Listcell ? (Listcell) cellComp : null;
	}

	private static String readStatusText(Listbox box, Listitem item, int statusCell, int modelCol, int row) {
		Listcell cell = listcellAt(item, statusCell);
		String text = null;
		if (cell != null) {
			text = cell.getLabel();
			if (Util.isEmpty(text, true)) {
				for (Component child : cell.getChildren()) {
					if (child instanceof Label) {
						text = ((Label) child).getValue();
						break;
					}
					if (child instanceof org.zkoss.zul.impl.XulElement) {
						String t = ((org.zkoss.zul.impl.XulElement) child).getTooltiptext();
						if (!Util.isEmpty(t, true)) {
							text = t;
							break;
						}
					}
				}
			}
		}
		if (Util.isEmpty(text, true)) {
			try {
				java.lang.reflect.Method m = box.getClass().getMethod("getValueAt", int.class, int.class);
				Object v = m.invoke(box, row, modelCol);
				text = valueToStatusText(v);
			} catch (Exception ignore) {
				// keep null
			}
		}
		return text;
	}

	private static String valueToStatusText(Object v) {
		if (v == null) {
			return null;
		}
		if (v instanceof ValueNamePair) {
			ValueNamePair p = (ValueNamePair) v;
			return Util.isEmpty(p.getName(), true) ? p.getValue() : p.getName();
		}
		if (v instanceof KeyNamePair) {
			return ((KeyNamePair) v).getName();
		}
		return String.valueOf(v);
	}

	private static int findApproverStatusCellIndex(Listbox box) {
		Listhead head = box.getListhead();
		if (head == null) {
			return -1;
		}
		int idx = 0;
		for (Component c : head.getChildren()) {
			String label = headerLabel(c);
			if (label != null) {
				String lower = label.toLowerCase();
				if (lower.contains("approver status") || lower.equals("approver")
						|| lower.contains("approverstatus")) {
					return idx;
				}
			}
			idx++;
		}
		return -1;
	}

	private static String headerLabel(Component c) {
		if (c instanceof Listheader) {
			Listheader h = (Listheader) c;
			if (!Util.isEmpty(h.getLabel(), true)) {
				return h.getLabel();
			}
			for (Component child : h.getChildren()) {
				if (child instanceof Label && !Util.isEmpty(((Label) child).getValue(), true)) {
					return ((Label) child).getValue();
				}
			}
			return h.getTooltiptext();
		}
		if (c instanceof Label) {
			return ((Label) c).getValue();
		}
		return c != null ? c.toString() : null;
	}

	private static String statusCellStyle(String text) {
		String tone = statusTone(text);
		if ("DC".equals(tone)) {
			return "background-color:#FDE8E8 !important;color:#8B1A1A !important;font-weight:600;";
		}
		if ("RV".equals(tone)) {
			return "background-color:#FFF4D6 !important;color:#7A5A00 !important;font-weight:600;";
		}
		if ("AP".equals(tone)) {
			return "background-color:#E6F5EA !important;color:#1B5E2A !important;font-weight:600;";
		}
		return null;
	}

	private static String statusRowStyle(String text) {
		String tone = statusTone(text);
		if ("DC".equals(tone)) {
			return "background-color:#FDE8E8 !important;";
		}
		if ("RV".equals(tone)) {
			return "background-color:#FFF4D6 !important;";
		}
		if ("AP".equals(tone)) {
			return "background-color:#E6F5EA !important;";
		}
		return null;
	}

	private static String statusTone(String text) {
		if (Util.isEmpty(text, true)) {
			return null;
		}
		String t = text.trim();
		if (t.equalsIgnoreCase("Declined") || STATUS_DC.equalsIgnoreCase(t)) {
			return "DC";
		}
		if (t.equalsIgnoreCase("Reviewing") || STATUS_RV.equalsIgnoreCase(t)) {
			return "RV";
		}
		if (t.equalsIgnoreCase("Approved") || STATUS_AP.equalsIgnoreCase(t)) {
			return "AP";
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
			// byte[] overload avoids OSGi ClassNotFound on org.zkoss.util.media.Media/AMedia
			Filedownload.save(bos.toByteArray(), "text/csv;charset=UTF-8", name);
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
