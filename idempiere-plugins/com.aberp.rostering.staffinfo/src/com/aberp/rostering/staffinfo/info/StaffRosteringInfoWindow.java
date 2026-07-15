package com.aberp.rostering.staffinfo.info;

import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;
import java.util.Properties;
import java.util.Set;

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
import org.zkoss.zk.ui.event.Event;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zk.ui.event.InputEvent;
import org.zkoss.zk.ui.util.Clients;
import org.zkoss.zul.A;
import org.zkoss.zul.Div;
import org.zkoss.zul.Intbox;
import org.zkoss.zul.Listbox;
import org.zkoss.zul.Listitem;
import org.zkoss.zul.Row;
import org.zkoss.zul.Space;
import org.zkoss.zul.Textbox;
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
 *   <li>When Show Unmatched is ticked, optional multi-select credentials (AND) —
 *       shift needs ignored; Find filters the list; Selected summary shows the set</li>
 * </ul>
 */
public class StaffRosteringInfoWindow extends InfoWindow {

	public static final String INFO_WINDOW_UU = "2b4ab146-0809-47c6-96f3-8b841d60a6bf";
	public static final String COL_SHOW_UNMATCHED = "AbERP_ShowUnmatchedStaff";

	private final GridField launchField;
	private Label contextBanner;
	private Checkbox showUnmatchedCheckbox;
	private Checkbox showUnavailableCheckbox;
	/** Visible only when Show Unmatched is ticked. */
	private Div credentialFilterBox;
	private Listbox credentialFilterList;
	private Textbox credentialFilterSearch;
	private Label credentialSelectionSummary;
	private A credentialClearLink;
	/** Criteria North from renderParameterPane — never expand a page-global .z-north. */
	private org.zkoss.zul.North parameterNorth;
	private String savedParameterNorthHeight;
	private boolean northLayoutListenersAttached;
	/**
	 * Server-side cache — Listbox selection AU is unreliable when the list was ever disabled.
	 * Lazily created: InfoWindow super() renders before subclass field initializers run.
	 */
	private List<Integer> selectedCredentialFilterIds;

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
		this.parameterNorth = north;
		super.renderParameterPane(north);
		// Criteria stay editable even when AD_InfoColumn.IsReadOnly=Y (needed so the
		// result grid does not paint dropdown editors on the selected row).
		ensureCriteriaEditorsWritable();
		// ZK client validates Intbox "no negative" *before* onUserQuery/executeQuery.
		// Strip constraints + clear -1 as soon as criteria exist, then again after attach.
		sanitizeIdEditors();
		ensureContextBanner(north);
		ensureNorthLayoutCleanupListeners();
		// Editors / Related panes may finish attaching after North render.
		Events.echoEvent("onSanitizeIdEditors", this, null);
	}

	/**
	 * Dragging the Info criteria splitter (or our expand for credentials) must not
	 * leave height styles on the parent Shift window. Restore on close/cancel/detach.
	 */
	private void ensureNorthLayoutCleanupListeners() {
		if (northLayoutListenersAttached) {
			return;
		}
		northLayoutListenersAttached = true;
		addEventListener(Events.ON_CLOSE, event -> restoreParameterNorthLayout());
		addEventListener(Events.ON_CANCEL, event -> restoreParameterNorthLayout());
	}

	@Override
	public void onPageDetached(org.zkoss.zk.ui.Page page) {
		restoreParameterNorthLayout();
		super.onPageDetached(page);
	}

	@Override
	public void detach() {
		restoreParameterNorthLayout();
		super.detach();
	}

	/** Echoed after layout so late-created Intboxes (Search embeds, Related) are cleaned. */
	public void onSanitizeIdEditors() {
		sanitizeIdEditors();
		syncCredentialFilterVisibility();
	}

	/**
	 * ReQuery path: InfoPanel.onUserQuery → validateParameters → query.
	 * Must sanitize here — executeQuery is too late (and client may already reject -1).
	 */
	@Override
	public void onUserQuery() {
		sanitizeIdEditors();
		super.onUserQuery();
	}

	@Override
	public boolean validateParameters() {
		sanitizeIdEditors();
		return super.validateParameters();
	}

	private void sanitizeIdEditors() {
		clearInvalidIdCriteria();
		neutralizeIdEditorConstraints();
		stripIntboxConstraints(this);
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
		sanitizeIdEditors();
		syncCredentialFilterVisibility();
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
				// Matched mode: full Related Rostering Needs (CRD + GDR + EMP).
				appendClause(extra, buildNeedsMatchSql());
			} else {
				// Unmatched mode: ignore shift needs. Optional AND credential multi-select.
				List<Integer> selectedCreds = getSelectedCredentialFilterIds();
				if (!selectedCreds.isEmpty()) {
					appendClause(extra, buildCredentialAndSql(selectedCreds));
				}
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

	/**
	 * ZK attaches constraint "no negative" to ID Intboxes. Validation runs on
	 * ReQuery <em>before</em> {@link #executeQuery()}, so clearing -1 there is
	 * too late. Strip the constraint and null any non-positive Intbox values on
	 * the criteria pane (and nested children).
	 */
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
		// Search / Table editors often wrap an Intbox; also clear Bandbox raw "-1"
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
			placeFilterCheckboxes();
			return;
		}

		contextBanner = new Label(buildContextBannerText());
		contextBanner.setStyle(
				"display:block;width:100%;box-sizing:border-box;"
						+ "padding:8px 10px;margin:0;"
						+ "background:#EEF3F8;border:1px solid #C5D0DC;color:#1F2A37;"
						+ "font-size:12px;line-height:1.45;white-space:pre-line;");

		ensureFilterCheckboxes();

		Vbox header = new Vbox();
		header.setWidth("100%");
		header.setSpacing("4px");
		header.appendChild(contextBanner);

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
			placeFilterCheckboxes();
			return;
		}

		if (northChild instanceof Vbox) {
			northChild.insertBefore(header, northChild.getFirstChild());
			placeFilterCheckboxes();
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
			placeFilterCheckboxes();
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
		placeFilterCheckboxes();
	}

	/** Create the two filter checkboxes once (placement is separate). */
	private void ensureFilterCheckboxes() {
		if (showUnavailableCheckbox == null) {
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
		}
		if (showUnmatchedCheckbox == null) {
			showUnmatchedCheckbox = new Checkbox();
			showUnmatchedCheckbox.setText("Show Unmatched Staff");
			showUnmatchedCheckbox.setTooltiptext(
					"When unticked (default), only staff matching Related Rostering Needs are listed. "
							+ "Credentials must be active and valid for the shift Start/End. "
							+ "Tick to ignore those needs and optionally require selected credentials (AND).");
			showUnmatchedCheckbox.setChecked(false);
			showUnmatchedCheckbox.addEventListener(Events.ON_CHECK, event -> {
				syncCredentialFilterVisibility();
				if (contextBanner != null) {
					contextBanner.setValue(buildContextBannerText());
				}
			});
		}
		ensureCredentialFilter();
	}

	/**
	 * Multi-select credentials (AND). Shown only when Show Unmatched is ticked.
	 * Options = all active AbERP_Credentials (shift-required ones are among them).
	 * Uses zul Listbox (not Chosenbox) so the OSGi bundle stays on Require-Bundle zul/zk.
	 * Presentation: search filter + selected summary strip (AND logic unchanged).
	 */
	private void ensureCredentialFilter() {
		if (credentialFilterList != null) {
			return;
		}
		credentialFilterList = new Listbox();
		credentialFilterList.setMultiple(true);
		credentialFilterList.setCheckmark(true);
		credentialFilterList.setWidth("100%");
		credentialFilterList.setHeight("140px");
		credentialFilterList.setStyle("max-width:100%;box-sizing:border-box;");
		// Never disable: ZK ignores SelectEvent on disabled Listbox, so AND filter never applied.
		credentialFilterList.addEventListener(Events.ON_SELECT, event -> {
			refreshSelectedCredentialFilterIds();
			updateCredentialSelectionSummary();
			if (contextBanner != null) {
				contextBanner.setValue(buildContextBannerText());
			}
		});
		loadCredentialFilterOptions();

		Label credLabel = new Label("Must have all of these credentials");
		credLabel.setTooltiptext(
				"Staff must hold every selected credential (AND). "
						+ "Leave empty to show the full unmatched pool. "
						+ "Use Find to narrow the list.");
		credLabel.setStyle("display:block;font-size:11px;color:#555;margin-bottom:4px;font-weight:bold;");

		credentialFilterSearch = new Textbox();
		credentialFilterSearch.setPlaceholder("Find credential…");
		credentialFilterSearch.setWidth("100%");
		credentialFilterSearch.setStyle("box-sizing:border-box;margin-bottom:4px;");
		credentialFilterSearch.setTooltiptext(
				"Type to filter the list. Selected credentials stay applied even if hidden by Find.");
		credentialFilterSearch.addEventListener(Events.ON_CHANGING, this::onCredentialFilterSearch);
		credentialFilterSearch.addEventListener(Events.ON_CHANGE, this::onCredentialFilterSearch);

		credentialSelectionSummary = new Label("Selected (0): none — full unmatched pool");
		credentialSelectionSummary.setStyle("display:block;font-size:11px;color:#333;margin-top:4px;line-height:1.3;");

		credentialClearLink = new A("Clear");
		credentialClearLink.setTooltiptext("Clear all selected credentials");
		credentialClearLink.setStyle("font-size:11px;margin-left:8px;");
		credentialClearLink.addEventListener(Events.ON_CLICK, event -> clearCredentialFilterSelection());

		Div summaryRow = new Div();
		summaryRow.setStyle("margin-top:2px;");
		summaryRow.appendChild(credentialSelectionSummary);
		summaryRow.appendChild(credentialClearLink);

		Label listLabel = new Label("Select (AND)");
		listLabel.setStyle("display:block;font-size:11px;color:#555;margin-bottom:4px;font-weight:bold;");

		// Two columns lined up under Staff Name (left) and Employee (right).
		Div leftCol = new Div();
		leftCol.setSclass("aberp-cred-col-left");
		leftCol.setStyle(
				"display:inline-block;vertical-align:top;width:48%;max-width:48%;"
						+ "padding-right:12px;box-sizing:border-box;");
		leftCol.appendChild(credLabel);
		leftCol.appendChild(credentialFilterSearch);
		leftCol.appendChild(summaryRow);

		Div rightCol = new Div();
		rightCol.setSclass("aberp-cred-col-right");
		rightCol.setStyle(
				"display:inline-block;vertical-align:top;width:48%;max-width:48%;"
						+ "box-sizing:border-box;");
		rightCol.appendChild(listLabel);
		rightCol.appendChild(credentialFilterList);

		Div columns = new Div();
		columns.setStyle("width:100%;white-space:normal;");
		columns.appendChild(leftCol);
		columns.appendChild(rightCol);

		credentialFilterBox = new Div();
		credentialFilterBox.setStyle(
				"padding:6px 8px 8px 8px;border-top:1px solid #ddd;background:#fafafa;");
		credentialFilterBox.setVisible(false);
		credentialFilterBox.appendChild(columns);
		updateCredentialSelectionSummary();
	}

	private void onCredentialFilterSearch(Event event) {
		String q = null;
		if (event instanceof InputEvent) {
			q = ((InputEvent) event).getValue();
		} else if (credentialFilterSearch != null) {
			q = credentialFilterSearch.getValue();
		}
		applyCredentialListFilter(q);
	}

	private void applyCredentialListFilter(String query) {
		if (credentialFilterList == null) {
			return;
		}
		String needle = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
		@SuppressWarnings("unchecked")
		List<Listitem> items = credentialFilterList.getItems();
		if (items == null) {
			return;
		}
		for (Listitem item : items) {
			String label = item.getLabel();
			if (label == null) {
				label = "";
			}
			boolean match = needle.isEmpty() || label.toLowerCase(Locale.ROOT).contains(needle);
			item.setVisible(match);
		}
	}

	private void clearCredentialFilterSelection() {
		if (credentialFilterList != null) {
			credentialFilterList.clearSelection();
		}
		credentialIdCache().clear();
		updateCredentialSelectionSummary();
		if (contextBanner != null) {
			contextBanner.setValue(buildContextBannerText());
		}
	}

	private void updateCredentialSelectionSummary() {
		if (credentialSelectionSummary == null) {
			return;
		}
		List<String> names = new ArrayList<>();
		if (credentialFilterList != null) {
			@SuppressWarnings("unchecked")
			Set<Listitem> selected = credentialFilterList.getSelectedItems();
			if (selected != null) {
				for (Listitem item : selected) {
					String label = item.getLabel();
					if (!Util.isEmpty(label, true) && !names.contains(label.trim())) {
						names.add(label.trim());
					}
				}
			}
		}
		// Prefer live selection labels; if AU lagged, fall back to count from cache.
		int count = names.isEmpty() ? credentialIdCache().size() : names.size();
		if (count <= 0) {
			credentialSelectionSummary.setValue("Selected (0): none — full unmatched pool");
			if (credentialClearLink != null) {
				credentialClearLink.setVisible(false);
			}
			return;
		}
		StringBuilder sb = new StringBuilder();
		sb.append("Selected (").append(count).append("): ");
		if (!names.isEmpty()) {
			for (int i = 0; i < names.size(); i++) {
				if (i > 0) {
					sb.append(" · ");
				}
				sb.append(names.get(i));
			}
		} else {
			sb.append(count).append(" credential").append(count == 1 ? "" : "s");
		}
		credentialSelectionSummary.setValue(sb.toString());
		if (credentialClearLink != null) {
			credentialClearLink.setVisible(true);
		}
	}

	private void loadCredentialFilterOptions() {
		credentialFilterList.getItems().clear();
		java.sql.PreparedStatement pstmt = null;
		java.sql.ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT AbERP_Credentials_ID, Name FROM AbERP_Credentials "
							+ "WHERE IsActive='Y' AND COALESCE(AbERP_Credentials_ID,0)>0 "
							+ "ORDER BY Name",
					null);
			rs = pstmt.executeQuery();
			while (rs.next()) {
				int id = rs.getInt(1);
				String name = rs.getString(2);
				if (id <= 0 || Util.isEmpty(name, true)) {
					continue;
				}
				Listitem item = new Listitem(name.trim());
				item.setValue(Integer.valueOf(id));
				credentialFilterList.appendChild(item);
			}
		} catch (Exception e) {
			log.log(java.util.logging.Level.WARNING, "credential filter options", e);
		} finally {
			DB.close(rs, pstmt);
		}
	}

	private List<Integer> credentialIdCache() {
		if (selectedCredentialFilterIds == null) {
			selectedCredentialFilterIds = new ArrayList<>();
		}
		return selectedCredentialFilterIds;
	}

	private void syncCredentialFilterVisibility() {
		boolean unmatched = isShowUnmatchedSelected();
		if (credentialFilterBox != null) {
			credentialFilterBox.setVisible(unmatched);
			credentialFilterBox.setStyle(unmatched
					? "padding:6px 8px 8px 8px;border-top:1px solid #ddd;background:#fafafa;"
					: "padding:6px 8px 8px 8px;");
			// Vbox parents wrap Divs in a TR (-chdex). setVisible(false) leaves that TR as
			// display:none; force both leaf + wrapper visible when unmatched is on.
			if (unmatched) {
				expandInfoParameterNorth();
			} else {
				restoreParameterNorthLayout();
			}
		}
		if (!unmatched) {
			if (credentialFilterList != null) {
				credentialFilterList.clearSelection();
			}
			credentialIdCache().clear();
			if (credentialFilterSearch != null) {
				credentialFilterSearch.setValue("");
				applyCredentialListFilter("");
			}
			updateCredentialSelectionSummary();
		} else if (credentialFilterSearch != null) {
			applyCredentialListFilter(credentialFilterSearch.getValue());
		}
	}

	/**
	 * Grow only this Info Window's criteria North so the credential picker is
	 * visible. Never use page-global {@code jq('.z-north').get(0)} — that hits
	 * the parent Shift (Rostered) layout and leaves a white gap after close.
	 */
	private void expandInfoParameterNorth() {
		if (parameterNorth != null) {
			if (savedParameterNorthHeight == null) {
				savedParameterNorthHeight = parameterNorth.getHeight();
			}
			parameterNorth.setHeight("280px");
		}
		String boxUuid = credentialFilterBox != null ? credentialFilterBox.getUuid() : "";
		String northUuid = parameterNorth != null ? parameterNorth.getUuid() : "";
		Clients.evalJavaScript(
				"setTimeout(function(){try{"
						+ "var id='" + boxUuid + "', nid='" + northUuid + "';"
						+ "var n=id?jq('#'+id)[0]:null;if(n){n.style.display='block';n.style.visibility='visible';}"
						+ "var tr=id?jq('#'+id+'-chdex')[0]:null;"
						+ "if(tr){tr.style.display='table-row';tr.style.visibility='visible';}"
						+ "var north=nid?jq('#'+nid)[0]:null;"
						+ "if(!north){var el=n||tr;while(el){"
						+ "if(el.classList&&el.classList.contains('z-north')){north=el;break;}"
						+ "el=el.parentElement;}}"
						+ "if(!north){return;}"
						+ "var nb=north.querySelector?north.querySelector('.z-north-body'):null;"
						+ "if(nb){nb.style.overflow='auto';nb.style.height='auto';nb.style.maxHeight='340px';}"
						+ "north.style.height='280px';north.style.minHeight='260px';"
						+ "try{var nw=zk.Widget.$(north);if(nw&&nw.setHeight){nw.setHeight('280px');}}catch(e2){}"
						+ "}catch(e){}},80);");
	}

	/**
	 * Clear heights we set on the Info North, and defensively strip leftover
	 * 280px/260px styles from any .z-north (repairs parent Shift layout if an
	 * older build mutated it, or if the user dragged the criteria splitter).
	 */
	private void restoreParameterNorthLayout() {
		if (parameterNorth != null) {
			String restore = savedParameterNorthHeight != null ? savedParameterNorthHeight : "";
			parameterNorth.setHeight(restore);
			savedParameterNorthHeight = null;
		}
		String northUuid = parameterNorth != null ? parameterNorth.getUuid() : "";
		Clients.evalJavaScript(
				"try{"
						+ "function clearNorth(el){if(!el){return;}"
						+ "el.style.height='';el.style.minHeight='';"
						+ "var nb=el.querySelector?el.querySelector('.z-north-body'):null;"
						+ "if(nb){nb.style.overflow='';nb.style.height='';nb.style.maxHeight='';}"
						+ "try{var nw=zk.Widget.$(el);if(nw&&nw.setHeight){nw.setHeight('');}}catch(e2){}}"
						+ "var nid='" + northUuid + "';"
						+ "if(nid){clearNorth(jq('#'+nid)[0]);}"
						+ "jq('.z-north').each(function(){"
						+ "var h=this.style.height||'', mh=this.style.minHeight||'';"
						+ "if(h==='280px'||mh==='260px'){clearNorth(this);}"
						+ "});"
						+ "try{zUtl.fireSized(zk.Desktop.$().firstChild);}catch(e3){}"
						+ "try{jq(window).trigger('resize');}catch(e4){}"
						+ "}catch(e){}");
	}

	private void refreshSelectedCredentialFilterIds() {
		List<Integer> cache = credentialIdCache();
		cache.clear();
		if (credentialFilterList == null) {
			return;
		}
		@SuppressWarnings("unchecked")
		Set<Listitem> selected = credentialFilterList.getSelectedItems();
		if (selected == null || selected.isEmpty()) {
			return;
		}
		for (Listitem item : selected) {
			Object value = item.getValue();
			int id = 0;
			if (value instanceof Number) {
				id = ((Number) value).intValue();
			}
			if (id > 0 && !cache.contains(Integer.valueOf(id))) {
				cache.add(Integer.valueOf(id));
			}
		}
	}

	private List<Integer> getSelectedCredentialFilterIds() {
		if (!isShowUnmatchedSelected()) {
			return new ArrayList<>();
		}
		List<Integer> cache = credentialIdCache();
		// Prefer cache filled by ON_SELECT; fall back to live list selection.
		if (!cache.isEmpty()) {
			return new ArrayList<>(cache);
		}
		refreshSelectedCredentialFilterIds();
		return new ArrayList<>(credentialIdCache());
	}

	/**
	 * Sit filter ticks under criteria columns:
	 * Show Unmatched under Staff Name, Show Unavailable under Employee.
	 * Credential multi-select sits <em>below</em> the criteria grid (not inside a
	 * row) so z-grid-body overflow cannot hide it when the tick expands the UI.
	 */
	private void placeFilterCheckboxes() {
		ensureFilterCheckboxes();
		if (parameterGrid == null || parameterGrid.getRows() == null) {
			return;
		}
		if (showUnmatchedCheckbox.getParent() != null
				|| showUnavailableCheckbox.getParent() != null) {
			return;
		}

		Row flagRow = new Row();
		// Criteria layout is label+editor pairs: Name | Employee | Agency | All/Any
		flagRow.appendChild(new Space()); // under Staff Name label
		flagRow.appendChild(wrapCheckbox(showUnmatchedCheckbox));
		flagRow.appendChild(new Space()); // under Employee label
		flagRow.appendChild(wrapCheckbox(showUnavailableCheckbox));
		flagRow.appendChild(new Space()); // under Agency label
		flagRow.appendChild(new Space()); // under Agency editor
		flagRow.appendChild(new Space()); // under All/Any
		parameterGrid.getRows().appendChild(flagRow);

		// Below criteria grid (avoids z-grid-body clipping the list). Two columns:
		// left ≈ Staff Name, right ≈ Employee.
		if (credentialFilterBox != null && credentialFilterBox.getParent() == null) {
			Component parent = parameterGrid.getParent();
			if (parent != null) {
				Component next = parameterGrid.getNextSibling();
				if (next != null) {
					parent.insertBefore(credentialFilterBox, next);
				} else {
					parent.appendChild(credentialFilterBox);
				}
			}
		}
		syncCredentialFilterVisibility();
	}

	private static Div wrapCheckbox(Checkbox checkbox) {
		Div wrap = new Div();
		wrap.setStyle("padding-top:2px;");
		wrap.appendChild(checkbox);
		return wrap;
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
		List<Integer> manualCreds = getSelectedCredentialFilterIds();

		if (range == null || range[0] == null || range[1] == null) {
			if (shiftId != null && shiftId.intValue() > 0) {
				StringBuilder sb = new StringBuilder();
				sb.append("Shift: #").append(Util.isEmpty(docNo, true) ? shiftId : docNo);
				sb.append(" | (no Start/End times in context)\n");
				sb.append("Required: ").append(needs.requiredLine()).append('\n');
				sb.append(buildFiltersLine(showUnavailable, showUnmatched, needs.hasCredentials(),
						manualCreds.size()));
				return sb.toString();
			}
			StringBuilder sb = new StringBuilder();
			sb.append("No shift in context. Open from Shift → Employee to apply leave/overlap")
					.append(" filters.\n");
			sb.append("Required: (none)\n");
			sb.append(buildFiltersLine(showUnavailable, showUnmatched, false, manualCreds.size()));
			return sb.toString();
		}

		StringBuilder sb = new StringBuilder();
		sb.append("Shift: #").append(Util.isEmpty(docNo, true) ? "?" : docNo);
		sb.append(" | ").append(formatBannerRange(range[0], range[1])).append('\n');
		sb.append("Required: ").append(needs.requiredLine()).append('\n');
		sb.append(buildFiltersLine(showUnavailable, showUnmatched, needs.hasCredentials(),
				manualCreds.size()));
		return sb.toString();
	}

	private static String buildFiltersLine(boolean showUnavailable, boolean showUnmatched,
			boolean hasCredentials, int manualCredentialCount) {
		StringBuilder sb = new StringBuilder("Filters: ");
		if (showUnavailable) {
			sb.append("Including unavailable staff and overlapping shifts");
		} else {
			sb.append("Excluding unavailable staff and overlapping shifts")
					.append(" (tick \"Show Unavailable Staff\" to include)");
		}
		sb.append("; ");
		if (showUnmatched) {
			sb.append("shift needs ignored");
			if (manualCredentialCount > 0) {
				sb.append("; requiring ").append(manualCredentialCount)
						.append(" selected credential")
						.append(manualCredentialCount == 1 ? "" : "s")
						.append(" (AND)");
			} else {
				sb.append("; no manual credential filter");
			}
		} else if (!hasCredentials) {
			sb.append("no required credentials on this shift");
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
		// Status values on HCO/AbilityERP are uppercase AP/DC/RV — avoid UPPER()
		// so the leave date/user indexes can be used.
		sql.append("NOT EXISTS (")
				.append("SELECT 1 FROM AbERP_Unavailability_Leave ul ")
				.append("WHERE ul.AbERP_User_Contact_ID = au.AD_User_ID AND ul.IsActive = 'Y' ")
				.append("AND ul.AbERP_ApproverStatus = 'AP' ")
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

		if (needs.crdCount > 0 && !needs.credentialIds.isEmpty()) {
			// Prefetch credential IDs in Java so we do NOT evaluate
			// AbERP_Related_Rostering_Needs_V per staff row.
			appendClause(sql, buildCredentialAndSql(needs.credentialIds, shiftStartSql, shiftEndSql));
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

	/**
	 * AND-match selected credentials via assignment COUNT(DISTINCT)=N.
	 * Uses shift Start/End when available, else CURRENT_DATE validity.
	 */
	private String buildCredentialAndSql(List<Integer> credentialIds) {
		if (credentialIds == null || credentialIds.isEmpty()) {
			return null;
		}
		Timestamp[] range = resolveShiftDateRange();
		String shiftStartSql = null;
		String shiftEndSql = null;
		if (range != null && range[0] != null && range[1] != null) {
			shiftStartSql = DB.TO_DATE(range[0]);
			shiftEndSql = DB.TO_DATE(range[1]);
		}
		return buildCredentialAndSql(credentialIds, shiftStartSql, shiftEndSql);
	}

	/**
	 * Staff must hold every credential in {@code credentialIds} (AND), with
	 * active assignment covering the shift window (or today when no shift dates).
	 */
	private String buildCredentialAndSql(List<Integer> credentialIds, String shiftStartSql,
			String shiftEndSql) {
		if (credentialIds == null || credentialIds.isEmpty()) {
			return null;
		}
		StringBuilder inList = new StringBuilder();
		int count = 0;
		for (Integer credentialId : credentialIds) {
			if (credentialId == null || credentialId.intValue() <= 0) {
				continue;
			}
			if (count > 0) {
				inList.append(',');
			}
			inList.append(credentialId.intValue());
			count++;
		}
		if (count == 0) {
			return null;
		}

		StringBuilder sql = new StringBuilder();
		sql.append('(')
				.append("SELECT COUNT(DISTINCT ca.AbERP_Credentials_ID) ")
				.append("FROM AbERP_CredentialAssignment ca ")
				.append("WHERE ca.IsActive = 'Y' ")
				.append("AND ca.AbERP_Credentials_ID IN (").append(inList).append(") ");
		// HCO CredentialAssignment has AbERP_User_Contact_ID only — referencing
		// missing C_BPartner_Staff_ID aborts the query and surfaces as ZK
		// "non-negative only" when opened from Shift with CRD needs.
		if (hasCredentialAssignmentBpStaffColumn()) {
			sql.append("AND (ca.AbERP_User_Contact_ID = au.AD_User_ID ")
					.append("OR ca.C_BPartner_Staff_ID = bp.C_BPartner_ID) ");
		} else {
			sql.append("AND ca.AbERP_User_Contact_ID = au.AD_User_ID ");
		}
		if (shiftStartSql != null && shiftEndSql != null) {
			sql.append("AND (ca.StartDate IS NULL OR ca.StartDate <= ").append(shiftStartSql).append(") ")
					.append("AND (ca.AbERP_ExpiryDate IS NULL OR ca.AbERP_ExpiryDate >= ")
					.append(shiftEndSql).append(')');
		} else {
			sql.append("AND (ca.StartDate IS NULL OR ca.StartDate <= CURRENT_DATE) ")
					.append("AND (ca.AbERP_ExpiryDate IS NULL OR ca.AbERP_ExpiryDate >= CURRENT_DATE)");
		}
		sql.append(") = ").append(count);
		return sql.toString();
	}

	/** Cached: AbilityERP seed may have BP staff link; HCO CredentialAssignment does not. */
	private static Boolean credentialAssignmentHasBpStaffCol;

	private static boolean hasCredentialAssignmentBpStaffColumn() {
		if (credentialAssignmentHasBpStaffCol == null) {
			int n = DB.getSQLValue(null,
					"SELECT COUNT(*) FROM information_schema.columns "
							+ "WHERE table_schema = 'adempiere' "
							+ "AND table_name = 'aberp_credentialassignment' "
							+ "AND column_name = 'c_bpartner_staff_id'");
			credentialAssignmentHasBpStaffCol = Boolean.valueOf(n > 0);
		}
		return credentialAssignmentHasBpStaffCol.booleanValue();
	}

	private NeedsSummary summarizeRelatedNeeds(Integer shiftId) {
		if (shiftId == null || shiftId.intValue() <= 0) {
			return NeedsSummary.EMPTY;
		}
		int id = shiftId.intValue();
		List<String> required = new ArrayList<>();

		List<Integer> credentialIds = new ArrayList<>();
		java.sql.PreparedStatement pstmtCred = null;
		java.sql.ResultSet rsCred = null;
		try {
			pstmtCred = DB.prepareStatement(
					"SELECT DISTINCT rv.AbERP_Credentials_ID, c.Name "
							+ "FROM AbERP_Related_Rostering_Needs_V rv "
							+ "INNER JOIN AbERP_Credentials c ON (c.AbERP_Credentials_ID = rv.AbERP_Credentials_ID) "
							+ "WHERE rv.AbERP_Rostered_Shift_ID=? AND rv.IsActive='Y' "
							+ "AND rv.AbERP_NeedType='CRD' AND COALESCE(rv.AbERP_Credentials_ID,0)>0 "
							+ "ORDER BY c.Name",
					null);
			pstmtCred.setInt(1, id);
			rsCred = pstmtCred.executeQuery();
			while (rsCred.next()) {
				int credId = rsCred.getInt(1);
				if (credId > 0) {
					credentialIds.add(Integer.valueOf(credId));
				}
				String name = rsCred.getString(2);
				if (!Util.isEmpty(name, true)) {
					required.add(name.trim());
				}
			}
		} catch (Exception e) {
			log.log(java.util.logging.Level.WARNING, "needs credential prefetch", e);
		} finally {
			DB.close(rsCred, pstmtCred);
		}
		int crd = credentialIds.size();

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

		return new NeedsSummary(crd, gdr, emp, required, credentialIds);
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
			java.sql.PreparedStatement pstmt = null;
			java.sql.ResultSet rs = null;
			try {
				pstmt = DB.prepareStatement(
						"SELECT StartDate, EndDate, StartTime, EndTime "
								+ "FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?",
						null);
				pstmt.setInt(1, shiftId.intValue());
				rs = pstmt.executeQuery();
				if (rs.next()) {
					ShiftTimes fromDb = new ShiftTimes(
							rs.getTimestamp(1), rs.getTimestamp(2),
							rs.getTimestamp(3), rs.getTimestamp(4));
					if (fromDb.hasDateOrTime()) {
						return fromDb;
					}
				}
			} catch (Exception e) {
				log.log(java.util.logging.Level.WARNING, "shift times", e);
			} finally {
				DB.close(rs, pstmt);
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
		static final NeedsSummary EMPTY = new NeedsSummary(0, 0, 0, new ArrayList<String>(),
				new ArrayList<Integer>());
		final int crdCount;
		final int gdrCount;
		final int empCount;
		final List<String> requiredLabels;
		final List<Integer> credentialIds;

		NeedsSummary(int crdCount, int gdrCount, int empCount, List<String> requiredLabels,
				List<Integer> credentialIds) {
			this.crdCount = crdCount;
			this.gdrCount = gdrCount;
			this.empCount = empCount;
			this.requiredLabels = requiredLabels != null ? requiredLabels : new ArrayList<String>();
			this.credentialIds = credentialIds != null ? credentialIds : new ArrayList<Integer>();
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
