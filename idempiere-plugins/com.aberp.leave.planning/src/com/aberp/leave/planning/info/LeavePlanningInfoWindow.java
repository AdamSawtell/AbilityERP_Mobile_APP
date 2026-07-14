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
import org.compiere.util.DisplayType;
import org.compiere.util.Env;
import org.compiere.util.KeyNamePair;
import org.compiere.util.Util;
import org.compiere.util.ValueNamePair;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.HtmlBasedComponent;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zk.ui.util.Clients;
import org.zkoss.zul.A;
import org.zkoss.zul.Checkbox;
import org.zkoss.zul.Div;
import org.zkoss.zul.Filedownload;
import org.zkoss.zul.Hlayout;
import org.zkoss.zul.Intbox;
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
		// ZK client validates Intbox "no negative" before onUserQuery ΓÇö clear -1 early.
		sanitizeIdEditors();
		hideAllAnyCheckboxes();
		ensureSummaryBanner(north);
		Events.echoEvent("onSanitizeIdEditors", this, null);
	}

	/** Echoed after layout so late-created Intboxes are cleaned. */
	public void onSanitizeIdEditors() {
		sanitizeIdEditors();
		hideAllAnyCheckboxes();
		attachCriteriaChangeListeners();
	}

	/**
	 * ReQuery path: InfoPanel.onUserQuery ΓåÆ validateParameters ΓåÆ query.
	 * Must sanitize here ΓÇö executeQuery is too late (client may already reject -1).
	 */
	@Override
	public void onUserQuery() {
		ensureCriteriaEditorsWritable();
		sanitizeIdEditors();
		hideAllAnyCheckboxes();
		super.onUserQuery();
	}

	@Override
	public boolean validateParameters() {
		sanitizeIdEditors();
		hideAllAnyCheckboxes();
		coercePlanningDatesFromUi();
		Timestamp start = readPlanningDate("AbERP_PlanningStart");
		Timestamp end = readPlanningDate("AbERP_PlanningEnd");
		if (start == null || end == null) {
			setStatusLine("Planning Start and Planning End are required", true);
			return false;
		}
		return super.validateParameters();
	}

	/**
	 * Datebox often holds display text while WEditor/GridField value is still null or a
	 * raw String — which fails InfoWindow date validation and made grid ignore dates.
	 * Coerce visible text into Timestamp on every editor instance before Search.
	 */
	private void coercePlanningDatesFromUi() {
		for (String col : new String[] { "AbERP_PlanningStart", "AbERP_PlanningEnd" }) {
			Timestamp ts = readPlanningDate(col);
			if (ts == null) {
				continue;
			}
			for (WEditor ed : allEditorsFor(col)) {
				Object cur = ed.getValue();
				if (!(cur instanceof Timestamp) && !(cur instanceof Date)) {
					setEditorValueQuiet(ed, ts);
				} else if (cur instanceof Date && !(cur instanceof Timestamp)) {
					setEditorValueQuiet(ed, new Timestamp(((Date) cur).getTime()));
				}
			}
		}
	}

	/**
	 * Planning dates are applied as DATE literals taken from the criteria editors.
	 * AD Match-Any (OR) and virtual column binding are unreliable — banner already
	 * proves the editors hold values while the grid SQL was ignoring them.
	 */
	@Override
	protected String getSQLWhere() {
		Timestamp start = readPlanningDate("AbERP_PlanningStart");
		Timestamp end = readPlanningDate("AbERP_PlanningEnd");
		final Timestamp[] snap = new Timestamp[] { start, end };
		return withPlanningDatesCleared(snap, (s, e) -> {
			String where = super.getSQLWhere();
			where = stripPlanningDatePredicates(where);
			where = rewriteSupportLocationExists(where);
			if (s == null || e == null) {
				log.warning("LeavePlanning getSQLWhere missing dates start=" + s + " end=" + e + " — blocking unfiltered grid");
				where = appendAnd(where, "1=0");
			} else {
				where = appendAnd(where, "ul.EndDate::date >= DATE '" + toSqlDate(s) + "'");
				where = appendAnd(where, "ul.StartDate::date <= DATE '" + toSqlDate(e) + "'");
			}
			log.warning("LeavePlanning getSQLWhere start=" + s + " end=" + e + " where=" + where);
			return where;
		});
	}

	@Override
	protected void setParameters(PreparedStatement pstmt, boolean forCount) throws java.sql.SQLException {
		final java.sql.SQLException[] held = new java.sql.SQLException[1];
		Timestamp start = readPlanningDate("AbERP_PlanningStart");
		Timestamp end = readPlanningDate("AbERP_PlanningEnd");
		withPlanningDatesCleared(new Timestamp[] { start, end }, (s, e) -> {
			try {
				super.setParameters(pstmt, forCount);
			} catch (java.sql.SQLException ex) {
				held[0] = ex;
			}
			return null;
		});
		if (held[0] != null) {
			throw held[0];
		}
	}

	@FunctionalInterface
	private interface PlanningDateWork<T> {
		T apply(Timestamp start, Timestamp end);
	}

	/**
	 * Clear Planning Start/End so AD does not emit/bind orphan {@code ?} after we
	 * strip those predicates. Snapshots are passed in (already read).
	 * Clears every editor instance for the column (editors list + editorMap), because
	 * banner uses findEditor while AD can bind a different map entry.
	 */
	private <T> T withPlanningDatesCleared(Timestamp[] snap, PlanningDateWork<T> work) {
		java.util.List<WEditor> startEds = allEditorsFor("AbERP_PlanningStart");
		java.util.List<WEditor> endEds = allEditorsFor("AbERP_PlanningEnd");
		java.util.List<Object[]> saved = new java.util.ArrayList<>();
		for (WEditor ed : startEds) {
			saved.add(new Object[] { ed, ed.getValue(), gridFieldValue(ed) });
		}
		for (WEditor ed : endEds) {
			saved.add(new Object[] { ed, ed.getValue(), gridFieldValue(ed) });
		}
		try {
			for (WEditor ed : startEds) {
				setEditorValueQuiet(ed, null);
			}
			for (WEditor ed : endEds) {
				setEditorValueQuiet(ed, null);
			}
			return work.apply(snap[0], snap[1]);
		} finally {
			for (Object[] row : saved) {
				WEditor ed = (WEditor) row[0];
				Object v = row[1] != null ? row[1] : row[2];
				setEditorValueQuiet(ed, v);
			}
		}
	}

	/** All editor instances for a column (deduped), covering editors list and editorMap. */
	private java.util.List<WEditor> allEditorsFor(String columnName) {
		java.util.LinkedHashSet<WEditor> set = new java.util.LinkedHashSet<>();
		WEditor fromList = findEditor(columnName);
		if (fromList != null) {
			set.add(fromList);
		}
		if (editorMap != null) {
			WEditor mapped = editorMap.get(columnName);
			if (mapped != null) {
				set.add(mapped);
			}
			for (Map.Entry<String, WEditor> e : editorMap.entrySet()) {
				if (e.getKey() != null && e.getKey().equalsIgnoreCase(columnName) && e.getValue() != null) {
					set.add(e.getValue());
				}
			}
		}
		if (editors != null) {
			for (WEditor editor : editors) {
				if (editor == null || editor.getGridField() == null) {
					continue;
				}
				if (columnName.equalsIgnoreCase(editor.getGridField().getColumnName())) {
					set.add(editor);
				}
			}
		}
		return new java.util.ArrayList<>(set);
	}

	private static Object gridFieldValue(WEditor editor) {
		try {
			return editor != null && editor.getGridField() != null ? editor.getGridField().getValue() : null;
		} catch (Exception e) {
			return null;
		}
	}

	private void setEditorValueQuiet(WEditor editor, Object value) {
		if (editor == null) {
			return;
		}
		try {
			editor.setValue(value);
		} catch (Exception ignore) {
		}
		try {
			if (editor.getGridField() != null) {
				editor.getGridField().setValue(value, false);
			}
		} catch (Exception ignore) {
		}
	}

	/**
	 * Prefer the same editor as the banner ({@link #findEditor} / editors list).
	 * editorMap alone can point at a stale/empty instance while the visible Datebox
	 * still holds Planning Start/End — that mismatch caused banner=46 vs grid=1228.
	 */
	private WEditor findPlanningEditor(String columnName) {
		WEditor fromList = findEditor(columnName);
		if (fromList != null) {
			return fromList;
		}
		if (editorMap != null) {
			WEditor mapped = editorMap.get(columnName);
			if (mapped != null) {
				return mapped;
			}
		}
		return null;
	}

	private Timestamp readPlanningDate(String columnName) {
		// Same path as banner/export (editorValue -> findEditor).
		Timestamp ts = toTimestamp(editorValue(columnName));
		if (ts != null) {
			return ts;
		}
		for (WEditor ed : allEditorsFor(columnName)) {
			ts = toTimestamp(ed.getValue());
			if (ts == null) {
				ts = toTimestamp(gridFieldValue(ed));
			}
			if (ts == null) {
				try {
					ts = parseDisplayDate(ed.getDisplay());
				} catch (Exception ignore) {
				}
			}
			if (ts == null) {
				try {
					Component c = ed.getComponent();
					if (c instanceof org.zkoss.zul.Datebox) {
						org.zkoss.zul.Datebox db = (org.zkoss.zul.Datebox) c;
						ts = toTimestamp(db.getValue());
						if (ts == null) {
							ts = parseDisplayDate(db.getText());
						}
					}
				} catch (Exception ignore) {
				}
			}
			if (ts != null) {
				return ts;
			}
		}
		log.warning("LeavePlanning missing date value for " + columnName);
		return null;
	}

	private static Timestamp parseDisplayDate(String display) {
		if (Util.isEmpty(display, true)) {
			return null;
		}
		String s = display.trim();
		String[] patterns = { "dd/MM/yyyy", "dd/MM/yy", "yyyy-MM-dd", "MM/dd/yyyy" };
		for (String ptn : patterns) {
			try {
				java.text.SimpleDateFormat df = new java.text.SimpleDateFormat(ptn);
				df.setLenient(false);
				return new Timestamp(df.parse(s).getTime());
			} catch (Exception ignore) {
			}
		}
		return null;
	}

	private String rewriteSupportLocationExists(String where) {
		WEditor locEditor = findPlanningEditor("C_BPartner_Location_ID");
		BigDecimal loc = locEditor != null ? toId(locEditor.getValue()) : null;
		if (loc == null && locEditor != null) {
			loc = toId(gridFieldValue(locEditor));
		}
		if (loc == null) {
			return where;
		}
		String exists = sqlExistsRosteredAtSupportLocationParam();
		if (Util.isEmpty(where, true)) {
			return " AND " + exists;
		}
		String rewritten = where
				.replaceAll("(?i)\\(\\s*u\\.C_BPartner_Location_ID\\s*=\\s*\\?\\s*\\)", "(" + exists + ")")
				.replaceAll("(?i)u\\.C_BPartner_Location_ID\\s*=\\s*\\?", exists);
		if (!rewritten.equals(where)) {
			return rewritten;
		}
		String trimmed = where.trim();
		if (trimmed.regionMatches(true, 0, "AND", 0, 3)) {
			return where + " AND " + exists;
		}
		return " AND " + trimmed + " AND " + exists;
	}

	/** Remove AD-generated planning overlap fragments (literals or ?). */
	private static String stripPlanningDatePredicates(String where) {
		if (Util.isEmpty(where, true)) {
			return where;
		}
		String w = where;
		w = w.replaceAll("(?i)\\(\\s*ul\\.EndDate(?:::date)?\\s*>=\\s*(?:\\?|DATE\\s+'[^']+')\\s+OR\\s+ul\\.StartDate(?:::date)?\\s*<=\\s*(?:\\?|DATE\\s+'[^']+')\\s*\\)", "");
		w = w.replaceAll("(?i)\\(\\s*ul\\.StartDate(?:::date)?\\s*<=\\s*(?:\\?|DATE\\s+'[^']+')\\s+OR\\s+ul\\.EndDate(?:::date)?\\s*>=\\s*(?:\\?|DATE\\s+'[^']+')\\s*\\)", "");
		w = w.replaceAll("(?i)(?:AND\\s+)?ul\\.EndDate(?:::date)?\\s*>=\\s*(?:\\?|DATE\\s+'[^']+')", "");
		w = w.replaceAll("(?i)(?:AND\\s+)?ul\\.StartDate(?:::date)?\\s*<=\\s*(?:\\?|DATE\\s+'[^']+')", "");
		w = w.replaceAll("(?i)\\(\\s*\\)", "");
		w = w.replaceAll("(?i)AND\\s+AND", "AND");
		return w;
	}

	private static String appendAnd(String where, String clause) {
		if (Util.isEmpty(where, true)) {
			return " AND " + clause;
		}
		String trimmed = where.trim();
		if (trimmed.regionMatches(true, 0, "AND", 0, 3)) {
			return where + " AND " + clause;
		}
		return " AND " + trimmed + " AND " + clause;
	}

	private static String toSqlDate(Timestamp ts) {
		return new SimpleDateFormat("yyyy-MM-dd").format(new Date(ts.getTime()));
	}

	/** Roster EXISTS using {@code ?} - must stay in sync with Support Location editor binding. */
	private static String sqlExistsRosteredAtSupportLocationParam() {
		return "EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff ss"
				+ " INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive='Y')"
				+ " INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)"
				+ " WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive='Y'"
				+ " AND ml.C_BPartner_Location_ID=?)";
	}

	/** Matches AD selectclause ΓÇö scalar fn avoids AccessSqlParser nested-SELECT breakage. */
	private static final String SQL_SUPPORT_LOC_NAMES =
			"aberp_lp_primary_support_location(u.AD_User_ID)";

	@Override
	protected void executeQuery() {
		ensureCriteriaEditorsWritable();
		sanitizeIdEditors();
		coercePlanningDatesFromUi();
		refreshSummaryBanner();
		super.executeQuery();
	}

	/**
	 * Table Direct / Search criteria often hold -1 when blank. ZK Intbox "no negative"
	 * then throws "Only non-negative number is allowed" on ReQuery (Support Location).
	 * Same harden pattern as Staff Rostering Info ΓÇö server + client strip.
	 */
	private void sanitizeIdEditors() {
		clearInvalidIdCriteria();
		neutralizeIdEditorConstraints();
		stripIntboxConstraints(this);
		stripClientIntboxConstraints();
	}

	/** Client validates Intbox constraints before server AU ΓÇö strip in-browser too. */
	private void stripClientIntboxConstraints() {
		String js = "setTimeout(function(){"
				+ "try{"
				+ "jq('.z-window:visible .z-intbox, .z-north .z-intbox').each(function(){"
				+ "  var w=zk.Widget.$(this);"
				+ "  if(!w) return;"
				+ "  try{ w.setConstraint(null); }catch(e){}"
				+ "  try{"
				+ "    var v=w.getValue();"
				+ "    if(v!=null && v<=0){ w.setValue(null); }"
				+ "  }catch(e){}"
				+ "});"
				+ "}catch(e){}"
				+ "}, 30);";
		try {
			org.zkoss.zk.ui.util.Clients.evalJavaScript(js);
		} catch (Exception ignore) {
		}
	}

	/** All/Any next to Support Location still injects -1 semantics in some builds ΓÇö hide it. */
	private void hideAllAnyCheckboxes() {
		if (parameterGrid != null) {
			hideAllAnyUnder(parameterGrid);
			Component p = parameterGrid.getParent();
			int depth = 0;
			while (p != null && depth < 5) {
				hideAllAnyUnder(p);
				p = p.getParent();
				depth++;
			}
		}
		String js = "setTimeout(function(){"
				+ "jq('.z-window:visible label, .z-window:visible .z-label, .z-north label').each(function(){"
				+ "  var t=(jq(this).text()||'').replace(/\\s+/g,' ').trim();"
				+ "  if(t==='All / Any' || t==='All/Any'){"
				+ "    var row=jq(this).closest('td,tr,div,span');"
				+ "    row.hide(); jq(this).hide();"
				+ "    row.find('input[type=checkbox]').prop('checked',false).hide();"
				+ "  }"
				+ "});"
				+ "}, 20);";
		try {
			org.zkoss.zk.ui.util.Clients.evalJavaScript(js);
		} catch (Exception ignore) {
		}
	}

	private static void hideAllAnyUnder(Component root) {
		if (root == null) {
			return;
		}
		if (root instanceof org.zkoss.zul.Checkbox) {
			org.zkoss.zul.Checkbox cb = (org.zkoss.zul.Checkbox) root;
			String label = cb.getLabel();
			if (label != null && label.replace(" ", "").equalsIgnoreCase("All/Any")) {
				cb.setChecked(false);
				cb.setVisible(false);
			}
		}
		if (root instanceof Label) {
			String t = ((Label) root).getValue();
			if (t != null && t.replace(" ", "").equalsIgnoreCase("All/Any")) {
				((Label) root).setVisible(false);
			}
		}
		java.util.List<Component> children = root.getChildren();
		if (children != null) {
			for (Component child : children) {
				hideAllAnyUnder(child);
			}
		}
	}

	private boolean criteriaListenersAttached;

	private void attachCriteriaChangeListeners() {
		if (criteriaListenersAttached || editors == null) {
			return;
		}
		criteriaListenersAttached = true;
		for (WEditor editor : editors) {
			if (editor == null || editor.getComponent() == null) {
				continue;
			}
			editor.getComponent().addEventListener(Events.ON_CHANGE, event -> {
				sanitizeIdEditors();
				hideAllAnyCheckboxes();
			});
			editor.getComponent().addEventListener(Events.ON_BLUR, event -> {
				sanitizeIdEditors();
			});
		}
	}

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

	private void neutralizeIdEditorConstraints() {
		if (editors != null) {
			for (WEditor editor : editors) {
				if (editor == null) {
					continue;
				}
				stripIntboxConstraints(editor.getComponent());
			}
		}
		if (parameterGrid != null) {
			stripIntboxConstraints(parameterGrid);
			Component northish = parameterGrid.getParent();
			int depth = 0;
			while (northish != null && depth < 6) {
				stripIntboxConstraints(northish);
				northish = northish.getParent();
				depth++;
			}
		}
	}

	private static void stripIntboxConstraints(Component root) {
		if (root == null) {
			return;
		}
		if (root instanceof Intbox) {
			Intbox box = (Intbox) root;
			box.setConstraint((String) null);
			Integer val = box.getValue();
			if (val != null && val.intValue() <= 0) {
				box.setValue(null);
			}
		}
		if (root instanceof org.zkoss.zul.Bandbox) {
			org.zkoss.zul.Bandbox band = (org.zkoss.zul.Bandbox) root;
			String raw = band.getValue();
			if (raw != null) {
				String t = raw.trim();
				if (t.isEmpty() || "-1".equals(t) || "0".equals(t)) {
					band.setValue(null);
				}
			}
		}
		java.util.List<Component> children = root.getChildren();
		if (children != null) {
			for (Component child : children) {
				stripIntboxConstraints(child);
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

	@Override
	protected void renderItems() {
		super.renderItems();
		ensureColourListeners();
		colourApproverStatusCells();
		// Renderer finishes after renderItems ΓÇö re-apply on next AU round-trip
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

		periodLabel = new Label("Leave Planning summary ΓÇö set Planning Start and Planning End, then Search.");
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

		typeLabel = new Label("By status / type: ΓÇö");
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
		Timestamp start = readPlanningDate("AbERP_PlanningStart");
		Timestamp end = readPlanningDate("AbERP_PlanningEnd");
		if (start == null || end == null) {
			periodLabel.setValue("Leave Planning summary ΓÇö set Planning Start and Planning End, then Search.");
			setStatusCounts(null);
			typeLabel.setValue("By status / type: ΓÇö");
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
			String period = df.format(new Date(start.getTime())) + " ΓåÆ " + df.format(new Date(end.getTime()));
			String locLabel = " ┬╖ All support locations";
			if (loc != null) {
				WEditor locEd = findEditor("C_BPartner_Location_ID");
				String disp = locEd != null ? toText(locEd.getDisplay()) : null;
				locLabel = !Util.isEmpty(disp, true)
						? (" ┬╖ " + disp)
						: (" ┬╖ Support Location #" + loc.intValue());
			}
			String filterNote = Util.isEmpty(approver, true) ? "" : (" ┬╖ filtered: " + statusName(approver));

			periodLabel.setValue("Period " + period + locLabel + filterNote);
			setStatusCounts(parseStatusCounts(byStatus));
			typeLabel.setValue("By status / type: " + (Util.isEmpty(byType, true) ? "ΓÇö" : byType));
		} catch (Exception ex) {
			periodLabel.setValue("Leave Planning summary unavailable: " + ex.getMessage());
			setStatusCounts(null);
			typeLabel.setValue("By status / type: ΓÇö");
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
		Timestamp start = readPlanningDate("AbERP_PlanningStart");
		Timestamp end = readPlanningDate("AbERP_PlanningEnd");
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
				+ " COALESCE(" + SQL_SUPPORT_LOC_NAMES + ",'') AS service_location,"
				+ " COALESCE(sup.Name,'') AS supervisor,"
				+ " ul.StartDate::date AS leave_start,"
				+ " ul.EndDate::date AS leave_end,"
				+ " ((ul.EndDate::date - ul.StartDate::date) + 1) AS calendar_days,"
				+ " COALESCE(ul.Note,'') AS note,"
				+ " ul.Created AS created"
				+ " FROM AbERP_Unavailability_Leave ul"
				+ " INNER JOIN AD_User u ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)"
				+ " LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)"
				+ " LEFT JOIN AD_User sup ON (sup.AD_User_ID=bp.Supervisor_ID)"
				+ " LEFT JOIN AbERP_Unavailability_Type ut ON (ut.AbERP_Unavailability_Type_ID=ul.AbERP_Unavailability_Type_ID)"
				+ " WHERE ul.IsActive='Y'"
				+ " AND ul.EndDate::date >= ?::date"
				+ " AND ul.StartDate::date <= ?::date"
				+ " AND (?::numeric IS NULL OR EXISTS ("
				+ "   SELECT 1 FROM AbERP_Rostered_ShiftStaff ss"
				+ "   INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive='Y')"
				+ "   INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)"
				+ "   WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive='Y'"
				+ "     AND ml.C_BPartner_Location_ID = ?::numeric))"
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
