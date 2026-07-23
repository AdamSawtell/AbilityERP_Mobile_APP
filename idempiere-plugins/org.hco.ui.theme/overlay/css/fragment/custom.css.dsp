<%@ page contentType="text/css;charset=UTF-8" %>
<%@ taglib uri="http://www.zkoss.org/dsp/web/core" prefix="c" %>

<%-- SAW033 HCO brand overrides — loaded after default fragments via custom.css.dsp hook --%>

@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

:root {
	--hco-primary: #25cad2;
	--hco-secondary: #00c3b3;
	--hco-heading: #00a2bd;
	--hco-text: #0f2554;
	--hco-dark: #151515;
	--hco-light: #eaeaea;
	--hco-danger: #e63946;
	--hco-radius: 6px;
	--hco-radius-lg: 8px;
	--hco-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

html, body {
	background-color: var(--hco-light) !important;
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
}

[class*="z-"]:not([class*="z-icon-"]):not([class*="z-group-icon-"]) {
	font-family: 'Poppins', sans-serif !important;
	color: inherit;
}

/* ===== Windows / panels ===== */
.z-window-header,
.z-panel-header,
.z-window-modal-header,
.z-window-highlighted-header {
	background: var(--hco-primary) !important;
	background-image: none !important;
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
	font-weight: 600 !important;
	border: none !important;
	box-shadow: none !important;
}

.z-window-content,
.z-panel-body,
.z-panel,
.z-groupbox {
	background: #fff !important;
	box-shadow: 0 1px 3px rgba(0,0,0,0.08);
	border-radius: var(--hco-radius);
}

.z-window,
.z-window-modal,
.z-window-highlighted,
.z-window-overlapped {
	border-radius: 12px !important;
	overflow: hidden;
	box-shadow: 0 8px 24px rgba(15, 37, 84, 0.18) !important;
	border: none !important;
}

/* ===== Buttons ===== */
.z-button {
	background: var(--hco-primary) !important;
	background-image: none !important;
	color: var(--hco-text) !important;
	border-radius: var(--hco-radius) !important;
	border: none !important;
	font-family: 'Poppins', sans-serif !important;
	font-weight: 500 !important;
	box-shadow: var(--hco-shadow);
	transition: background 0.15s ease, box-shadow 0.15s ease, transform 0.15s ease;
}
.z-button:hover {
	background: var(--hco-secondary) !important;
	background-image: none !important;
}
.z-button-primary,
.z-button.btn-ok,
button.z-button.btn-ok {
	background: var(--hco-dark) !important;
	color: #fff !important;
}

/* ===== Inputs ===== */
.z-textbox,
.z-combobox-input,
.z-datebox-input,
.z-timebox-input,
.z-bandbox-input,
.z-decimalbox,
.z-intbox,
.z-longbox,
.z-doublebox {
	border: 1px solid #ccc !important;
	border-radius: var(--hco-radius) !important;
	box-shadow: none !important;
	background-image: none !important;
}
.z-textbox:focus,
.z-combobox-input:focus,
.z-datebox-input:focus,
.z-timebox-input:focus,
.z-bandbox-input:focus {
	border-color: var(--hco-primary) !important;
	box-shadow: 0 0 0 2px rgba(37, 202, 210, 0.25) !important;
}

/* ===== Menus ===== */
.z-menubar,
.z-menubar-horizontal,
.desktop-header,
.desktop-header-left,
.desktop-header-right,
.desktop-header-center {
	background: var(--hco-dark) !important;
	background-image: none !important;
	color: #fff !important;
	font-family: 'Poppins', sans-serif !important;
}
.z-menubar .z-menu-text,
.z-menubar .z-menuitem-text,
.z-menu-text,
.z-menuitem-text {
	color: #fff !important;
}
.z-menupopup {
	border-radius: var(--hco-radius) !important;
	box-shadow: var(--hco-shadow) !important;
	border: 1px solid #ddd !important;
}

/* ===== Grids ===== */
.z-grid-header,
.z-columns,
.z-column,
.z-listheader,
.z-listbox-header {
	background: var(--hco-heading) !important;
	background-image: none !important;
	color: #fff !important;
}
.z-column-content,
.z-listheader-content {
	color: #fff !important;
	font-weight: 500 !important;
}
.z-grid,
.z-row,
.z-listbox {
	border-color: #e0e0e0 !important;
}
.z-grid-odd > .z-row-inner,
.z-grid-odd > .z-cell,
.z-row.z-grid-odd {
	background: transparent !important;
}
.z-listitem:hover,
.z-row:hover > .z-row-inner,
.z-row:hover > .z-cell {
	background: rgba(37, 202, 210, 0.06) !important;
}
.z-label,
.z-cell,
.z-row-content {
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
}

/* ===== Grid row Select (Edit Record indicator) =====
   Default column is ~22px with a tiny/broken pencil glyph — hard to hit.
   Widen to a clear Select chip on every row. */
.z-grid:has(td.z-cell[title="Edit Record"]) colgroup col:nth-child(2),
.z-grid:has(td.z-cell[title="Edit Record"]) .z-columns .z-column:nth-child(2) {
	width: 88px !important;
	min-width: 88px !important;
}
.z-grid td.z-cell[title="Edit Record"] {
	width: 88px !important;
	min-width: 88px !important;
	max-width: 88px !important;
	padding: 2px 4px !important;
	text-align: center !important;
	vertical-align: middle !important;
	cursor: pointer !important;
}
.z-grid td.z-cell[title="Edit Record"] > .z-label {
	display: inline-flex !important;
	align-items: center !important;
	justify-content: center !important;
	box-sizing: border-box !important;
	min-width: 76px !important;
	width: 76px !important;
	height: 28px !important;
	margin: 0 auto !important;
	padding: 0 8px !important;
	border-radius: 5px !important;
	font-family: 'Poppins', sans-serif !important;
	font-size: 11px !important;
	font-weight: 600 !important;
	line-height: 1 !important;
	white-space: nowrap !important;
	cursor: pointer !important;
}
/* Current / highlighted row */
.z-grid td.z-cell[title="Edit Record"] > .z-label.z-icon-Edit,
.z-grid td.z-cell[title="Edit Record"] > .row-indicator-selected {
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08) !important;
	border: 1px solid transparent !important;
}
/* Other rows — outlined Select affordance */
.z-grid td.z-cell[title="Edit Record"] > .z-label:not(.z-icon-Edit):not(.row-indicator-selected) {
	background: #fff !important;
	color: var(--hco-text) !important;
	border: 1px solid var(--hco-heading) !important;
}
.z-grid td.z-cell[title="Edit Record"] > .z-label:not(.z-icon-Edit):not(.row-indicator-selected):hover {
	background: rgba(37, 202, 210, 0.15) !important;
	border-color: var(--hco-primary) !important;
}
/* Replace pencil / empty glyph with checkbox + Select label */
.z-grid td.z-cell[title="Edit Record"] > .z-label.z-icon-Edit::before,
.z-grid td.z-cell[title="Edit Record"] > .row-indicator-selected::before {
	content: "☑" !important;
	font-family: 'Segoe UI Symbol', 'Noto Sans Symbols', 'Poppins', sans-serif !important;
	font-size: 13px !important;
	font-weight: 400 !important;
	color: var(--hco-text) !important;
	margin-right: 5px !important;
}
.z-grid td.z-cell[title="Edit Record"] > .z-label:not(.z-icon-Edit):not(.row-indicator-selected)::before {
	content: "☐" !important;
	font-family: 'Segoe UI Symbol', 'Noto Sans Symbols', 'Poppins', sans-serif !important;
	font-size: 13px !important;
	font-weight: 400 !important;
	color: var(--hco-heading) !important;
	margin-right: 5px !important;
}
.z-grid td.z-cell[title="Edit Record"] > .z-label::after {
	content: "Select";
	font-family: 'Poppins', sans-serif !important;
	font-size: 11px !important;
	font-weight: 600 !important;
	color: inherit !important;
}

/* Field labels */
.adwindow-form .z-label,
.form-label,
td.form-label .z-label {
	color: var(--hco-text) !important;
	font-weight: 400 !important;
	font-size: 13px !important;
}

/* ===== Toolbar tiles — compact (rarely used chrome) ===== */
.z-toolbar .z-toolbarbutton,
.desktop-toolbar .z-toolbarbutton,
.adwindow-toolbar .z-toolbarbutton,
.font-icon-toolbar-button.toolbar-button,
.adwindow-detail-toolbar .z-toolbarbutton,
.adtab-toolbar .z-toolbarbutton {
	border-radius: 6px !important;
	padding: 2px 6px !important;
	margin: 1px 2px !important;
	background: var(--hco-primary) !important;
	background-image: none !important;
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
	font-weight: 500 !important;
	font-size: 12px !important;
	border: none !important;
	box-shadow: 0 1px 2px rgba(0,0,0,0.08);
	transition: all 0.15s ease;
	width: auto !important;
	height: auto !important;
	min-height: 24px !important;
	min-width: 24px !important;
}
.z-toolbar .z-toolbarbutton:hover,
.desktop-toolbar .z-toolbarbutton:hover,
.adwindow-toolbar .z-toolbarbutton:hover,
.font-icon-toolbar-button.toolbar-button:hover,
.adwindow-detail-toolbar .z-toolbarbutton:hover,
.adtab-toolbar .z-toolbarbutton:hover {
	background: var(--hco-secondary) !important;
	color: var(--hco-text) !important;
	box-shadow: 0 1px 4px rgba(0,0,0,0.12);
	transform: none;
}
.z-toolbar .z-toolbarbutton .z-toolbarbutton-content,
.font-icon-toolbar-button.toolbar-button .z-toolbarbutton-content {
	color: inherit !important;
	padding: 0 !important;
}
.font-icon-toolbar-button.toolbar-button [class^="z-icon-"],
.adwindow-toolbar .z-toolbarbutton [class^="z-icon-"],
.adwindow-detail-toolbar .z-toolbarbutton [class^="z-icon-"],
.z-toolbar .z-toolbarbutton [class^="z-icon-"] {
	color: inherit !important;
	font-size: 14px !important;
}
/* Icon-only toolbar buttons — equal-width rectangles */
.font-icon-toolbar-button.toolbar-button {
	width: 40px !important;
	height: 26px !important;
	min-width: 40px !important;
	min-height: 26px !important;
	padding: 2px 8px !important;
	border-radius: 5px !important;
}

/* Hide unavailable window-toolbar actions (disabled = not usable right now).
   Save/Ignore/Print reappear when enabled — cleaner than grey stubs.
   Role-denied buttons should be removed via AD_ToolBarButtonRestrict (not CSS). */
.adwindow-toolbar .z-toolbarbutton.z-toolbarbutton-disd,
.adwindow-toolbar .z-toolbarbutton[disabled],
.adwindow-toolbar .font-icon-toolbar-button.z-toolbarbutton-disd {
	display: none !important;
}
/* Empty More-menu rows left after Restrict */
.adwindow-toolbar .z-menupopup .z-menuitem-disd,
.adwindow-toolbar .z-menupopup .z-menuitem[disabled] {
	display: none !important;
}

/* Destructive toolbar actions */
.z-toolbarbutton .z-icon-trash,
.z-toolbarbutton .z-icon-times,
.z-toolbarbutton .z-icon-delete,
.z-toolbarbutton[title*="Delete"] ,
.z-toolbarbutton[tooltiptext*="Delete"] {
	/* color hint on icon; parent tile below */
}
.adwindow-toolbar .z-toolbarbutton:has(.z-icon-trash),
.adwindow-toolbar .z-toolbarbutton:has(.z-icon-times),
.desktop-toolbar .z-toolbarbutton:has(.z-icon-trash),
.z-toolbar .z-toolbarbutton:has(.z-icon-trash) {
	background: var(--hco-danger) !important;
	color: #fff !important;
}

/* ===== Record navigation (breadcrumb) — equal rectangles + word labels ===== */
.adwindow-breadcrumb-toolbar .breadcrumb-toolbar-button,
.adwindow-breadcrumb .breadcrumb-toolbar-button,
.z-toolbarbutton.breadcrumb-toolbar-button,
.z-toolbarbutton:has(.z-icon-FirstRecord),
.z-toolbarbutton:has(.z-icon-PreviousRecord),
.z-toolbarbutton:has(.z-icon-NextRecord),
.z-toolbarbutton:has(.z-icon-LastRecord),
.z-toolbarbutton[title*="First record"],
.z-toolbarbutton[title*="Previous record"],
.z-toolbarbutton[title*="Next record"],
.z-toolbarbutton[title*="Last record"] {
	display: inline-flex !important;
	align-items: center !important;
	justify-content: center !important;
	min-width: 84px !important;
	width: auto !important;
	height: 28px !important;
	min-height: 28px !important;
	padding: 3px 14px !important;
	margin: 0 3px !important;
	border-radius: 5px !important;
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	box-shadow: 0 1px 2px rgba(0,0,0,0.08) !important;
}
.adwindow-breadcrumb-toolbar .breadcrumb-record-info,
.z-toolbarbutton.breadcrumb-record-info {
	display: inline-flex !important;
	align-items: center !important;
	justify-content: center !important;
	min-width: 72px !important;
	height: 28px !important;
	min-height: 28px !important;
	padding: 3px 14px !important;
	margin: 0 3px !important;
	border-radius: 5px !important;
	background: var(--hco-heading) !important;
	color: #fff !important;
	font-family: 'Poppins', sans-serif !important;
	font-size: 12px !important;
	font-weight: 500 !important;
	box-shadow: 0 1px 2px rgba(0,0,0,0.08) !important;
}
.adwindow-breadcrumb-toolbar .breadcrumb-record-info .z-toolbarbutton-content,
.z-toolbarbutton.breadcrumb-record-info .z-toolbarbutton-content {
	color: #fff !important;
	white-space: nowrap !important;
}
.z-toolbarbutton.breadcrumb-toolbar-button .z-toolbarbutton-content,
.z-toolbarbutton:has(.z-icon-FirstRecord) .z-toolbarbutton-content,
.z-toolbarbutton:has(.z-icon-PreviousRecord) .z-toolbarbutton-content,
.z-toolbarbutton:has(.z-icon-NextRecord) .z-toolbarbutton-content,
.z-toolbarbutton:has(.z-icon-LastRecord) .z-toolbarbutton-content {
	white-space: nowrap !important;
}
/* Hide icon glyphs; show word labels */
.z-toolbarbutton.breadcrumb-toolbar-button .z-toolbarbutton-content [class^="z-icon-"],
.z-toolbarbutton:has(.z-icon-FirstRecord) .z-toolbarbutton-content [class^="z-icon-"],
.z-toolbarbutton:has(.z-icon-PreviousRecord) .z-toolbarbutton-content [class^="z-icon-"],
.z-toolbarbutton:has(.z-icon-NextRecord) .z-toolbarbutton-content [class^="z-icon-"],
.z-toolbarbutton:has(.z-icon-LastRecord) .z-toolbarbutton-content [class^="z-icon-"] {
	display: none !important;
	font-size: 0 !important;
}
.z-toolbarbutton:has(.z-icon-FirstRecord) .z-toolbarbutton-content::before,
.z-toolbarbutton[title*="First record"] .z-toolbarbutton-content::before {
	content: "First";
	font-family: 'Poppins', sans-serif !important;
	font-size: 12px !important;
	font-weight: 500 !important;
	color: var(--hco-text) !important;
}
.z-toolbarbutton:has(.z-icon-PreviousRecord) .z-toolbarbutton-content::before,
.z-toolbarbutton[title*="Previous record"] .z-toolbarbutton-content::before {
	content: "Previous";
	font-family: 'Poppins', sans-serif !important;
	font-size: 12px !important;
	font-weight: 500 !important;
	color: var(--hco-text) !important;
}
.z-toolbarbutton:has(.z-icon-NextRecord) .z-toolbarbutton-content::before,
.z-toolbarbutton[title*="Next record"] .z-toolbarbutton-content::before {
	content: "Next";
	font-family: 'Poppins', sans-serif !important;
	font-size: 12px !important;
	font-weight: 500 !important;
	color: var(--hco-text) !important;
}
.z-toolbarbutton:has(.z-icon-LastRecord) .z-toolbarbutton-content::before,
.z-toolbarbutton[title*="Last record"] .z-toolbarbutton-content::before {
	content: "Last";
	font-family: 'Poppins', sans-serif !important;
	font-size: 12px !important;
	font-weight: 500 !important;
	color: var(--hco-text) !important;
}
/* Hide disabled record-nav chips (e.g. Previous on record 1).
   ZK often sets the disabled attribute without z-toolbarbutton-disd;
   must beat the display:inline-flex rule above. */
.adwindow-breadcrumb-toolbar .z-toolbarbutton.z-toolbarbutton-disd,
.adwindow-breadcrumb-toolbar .z-toolbarbutton[disabled],
.adwindow-breadcrumb .breadcrumb-toolbar-button.z-toolbarbutton-disd,
.adwindow-breadcrumb .breadcrumb-toolbar-button[disabled],
.z-toolbarbutton.breadcrumb-toolbar-button.z-toolbarbutton-disd,
.z-toolbarbutton.breadcrumb-toolbar-button[disabled],
.z-toolbarbutton:has(.z-icon-FirstRecord).z-toolbarbutton-disd,
.z-toolbarbutton:has(.z-icon-FirstRecord)[disabled],
.z-toolbarbutton:has(.z-icon-PreviousRecord).z-toolbarbutton-disd,
.z-toolbarbutton:has(.z-icon-PreviousRecord)[disabled],
.z-toolbarbutton:has(.z-icon-NextRecord).z-toolbarbutton-disd,
.z-toolbarbutton:has(.z-icon-NextRecord)[disabled],
.z-toolbarbutton:has(.z-icon-LastRecord).z-toolbarbutton-disd,
.z-toolbarbutton:has(.z-icon-LastRecord)[disabled],
.z-toolbarbutton[title*="First record"][disabled],
.z-toolbarbutton[title*="Previous record"][disabled],
.z-toolbarbutton[title*="Next record"][disabled],
.z-toolbarbutton[title*="Last record"][disabled] {
	display: none !important;
}

/* Detail / tab toolbar: hide grey Save stubs when not editable */
.adwindow-detailpane .z-toolbarbutton.z-toolbarbutton-disd,
.adwindow-detailpane .z-toolbarbutton[disabled],
.adtab-content .z-toolbar .z-toolbarbutton.z-toolbarbutton-disd,
.adtab-content .z-toolbar .z-toolbarbutton[disabled] {
	display: none !important;
}

/* ===== Tabs — flat underline, tighter spacing ===== */
.z-tab,
.z-tab-content {
	background: transparent !important;
	background-image: none !important;
	border: none !important;
	border-radius: 0 !important;
	box-shadow: none !important;
	padding: 4px 10px 6px 10px !important;
	margin: 0 2px !important;
	height: auto !important;
	min-height: 0 !important;
}
.z-tabs,
.z-tabbox-tabs,
.z-tabs-header,
.adwindow-tabbox > .z-tabbox-tabs {
	padding: 0 !important;
	margin: 0 !important;
	min-height: 0 !important;
}
.z-tab .z-tab-text {
	color: var(--hco-text) !important;
	font-weight: 400 !important;
	font-size: 13px !important;
	line-height: 1.25 !important;
	padding: 0 !important;
}
.z-tab:hover .z-tab-text {
	color: var(--hco-heading) !important;
}
.z-tab-selected {
	border-bottom: 2px solid var(--hco-primary) !important;
	background: transparent !important;
	padding-bottom: 4px !important;
}
.z-tab-selected .z-tab-text {
	color: var(--hco-heading) !important;
	font-weight: 600 !important;
}
.z-tabs-content,
.z-tabbox-content,
.z-tabpanel,
.z-tabpanels {
	border-bottom: none !important;
	padding-top: 4px !important;
}
.z-tabbox {
	margin-bottom: 0 !important;
}
/* Gap between tab strip and detail toolbar / grid */
.adwindow-tabbox .z-tabpanels,
.adwindow-detail .z-tabpanels,
.adtab-content {
	padding-top: 2px !important;
	margin-top: 0 !important;
}
.adwindow-detail-toolbar,
.adtab-toolbar,
.z-toolbar.adwindow-toolbar {
	padding: 2px 4px !important;
	margin: 0 0 4px 0 !important;
	min-height: 0 !important;
}

/* ===== Process / report dialogs ===== */
.z-window-modal .z-window-header,
.process-modal-panel .z-window-header,
.popup-dialog .z-window-header {
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	border-radius: 12px 12px 0 0 !important;
}
.z-window-modal,
.popup-dialog {
	border-radius: 12px !important;
	box-shadow: 0 8px 24px rgba(15, 37, 84, 0.2) !important;
}

/* ===== Status bar ===== */
.desktop-bottom,
.desktop-layout > .z-south,
.adwindow-status,
.statusBar {
	background: #fff !important;
	border-left: 4px solid var(--hco-primary) !important;
	padding: 6px 12px !important;
	font-family: 'Poppins', sans-serif !important;
	color: var(--hco-text) !important;
	box-shadow: 0 -1px 3px rgba(0,0,0,0.06);
}

/* ===== Document Status indicators (Home gadget: activities-box) =====
   Core renders Name + Count with AD PrintFont/Color (often Monospaced + harsh pink).
   Restyle as modern rows with teal count chips — same plugin, CSS only. */
.activities-box {
	width: calc(100% - 8px) !important;
	margin: 4px 4px !important;
	padding: 6px 10px !important;
	border-radius: 8px !important;
	background: #fff !important;
	border: 1px solid #e3eef0 !important;
	border-left: 4px solid var(--hco-primary) !important;
	box-shadow: 0 1px 2px rgba(15, 37, 84, 0.05) !important;
	cursor: pointer !important;
	box-sizing: border-box !important;
	transition: background 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
}
.activities-box:hover {
	background: rgba(37, 202, 210, 0.08) !important;
	border-color: var(--hco-primary) !important;
	box-shadow: 0 2px 6px rgba(37, 202, 210, 0.18) !important;
}
.activities-box > .z-div {
	display: flex !important;
	align-items: center !important;
	justify-content: space-between !important;
	gap: 10px !important;
	width: 100% !important;
	flex-wrap: nowrap !important;
}
.activities-box .z-label {
	font-family: 'Poppins', sans-serif !important;
	font-style: normal !important;
	line-height: 1.3 !important;
}
/* Status name — override inline PrintColor/PrintFont */
.activities-box .z-label:first-child {
	flex: 1 1 auto !important;
	min-width: 0 !important;
	color: var(--hco-text) !important;
	font-size: 13px !important;
	font-weight: 500 !important;
	white-space: nowrap !important;
	overflow: hidden !important;
	text-overflow: ellipsis !important;
}
/* Count chip */
.activities-box .z-label:last-of-type {
	flex: 0 0 auto !important;
	display: inline-flex !important;
	align-items: center !important;
	justify-content: center !important;
	min-width: 32px !important;
	height: 26px !important;
	padding: 0 10px !important;
	margin-left: auto !important;
	border-radius: 13px !important;
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	font-size: 12px !important;
	font-weight: 600 !important;
	box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08) !important;
}
/* Help control — keep compact and on-brand */
.activities-box .z-toolbarbutton {
	flex: 0 0 auto !important;
	min-height: 26px !important;
	height: 26px !important;
	padding: 0 4px !important;
	margin: 0 !important;
	background: transparent !important;
	border: none !important;
	box-shadow: none !important;
}
.activities-box .z-toolbarbutton,
.activities-box .z-toolbarbutton [class^="z-icon-"] {
	color: var(--hco-heading) !important;
	font-size: 13px !important;
}
.activities-box img[src*="Help"] {
	width: 14px !important;
	height: 14px !important;
	opacity: 0.75;
	filter: sepia(1) saturate(3) hue-rotate(140deg);
}

/* ===== Menu tree / sidebar ===== */
.z-treerow:hover > .z-treecell {
	background: rgba(37, 202, 210, 0.12) !important;
	border-radius: var(--hco-radius);
}
.z-treecell-content {
	padding: 4px 8px !important;
}
.menu-panel .z-treerow {
	margin: 2px 0;
}

/* ===== Core logos (HeaderPanel + Login/Role login-box-header-logo) ===== */
/* Note: ZK rewrites zul id="logo" to a generated id — target .desktop-header-left img */
.desktop-header-left img.z-image,
.desktop-header img.z-image[src*="header-logo"],
.login-box-header-logo img.z-image,
.login-box-header-logo .z-image,
div.login-box-header-logo img,
.hco-login-brand img,
.hco-login-brand .z-image {
	border-radius: 12px !important;
	overflow: hidden !important;
	box-shadow: 0 2px 10px rgba(15, 37, 84, 0.18) !important;
	background: #fff !important;
	object-fit: contain !important;
}
.desktop-header-left img.z-image,
.desktop-header img.z-image[src*="header-logo"] {
	max-height: 40px !important;
	height: 40px !important;
	width: auto !important;
	border-radius: 10px !important;
	margin: 4px 10px 4px 6px !important;
	padding: 2px !important;
}
.login-box-header-logo img.z-image,
.login-box-header-logo .z-image,
div.login-box-header-logo img {
	max-height: 72px !important;
	height: auto !important;
	max-width: 280px !important;
	border-radius: 14px !important;
	margin: 8px auto !important;
	display: block !important;
}
.hco-login-brand img,
.hco-login-brand .z-image {
	max-height: 88px !important;
	max-width: 300px !important;
	border-radius: 16px !important;
	padding: 4px !important;
}

/* ===== Login ===== */
.login-window,
.login-window .z-center-body,
body.login-window {
	background: var(--hco-light) !important;
}
.login-box-body,
.login-box,
div.login-box {
	background: #fff !important;
	border-radius: 12px !important;
	border-top: 4px solid var(--hco-primary) !important;
	box-shadow: 0 4px 16px rgba(15, 37, 84, 0.12) !important;
	padding: 24px !important;
}
.login-box-header,
.login-box-header-txt {
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
	font-weight: 600 !important;
}
.login-btn,
.login-box .z-button {
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	border-radius: var(--hco-radius) !important;
}
.login-label {
	color: var(--hco-text) !important;
	font-weight: 400 !important;
}
.hco-login-brand {
	text-align: center;
	padding: 16px 8px 8px 8px;
}
.hco-login-brand .hco-title {
	display: block;
	font-family: 'Poppins', sans-serif;
	font-size: 1.6em;
	font-weight: 700;
	color: #0f2554;
	margin-top: 8px;
}
.hco-login-brand .hco-tagline {
	display: block;
	font-family: 'Poppins', sans-serif;
	font-size: 0.95em;
	font-weight: 400;
	color: #25cad2;
	margin-top: 4px;
}

/* ===== Loading spinner (CSS) ===== */
.z-loading {
	background: rgba(234, 234, 234, 0.65) !important;
}
.z-loading-indicator {
	background: transparent !important;
	border: none !important;
	box-shadow: none !important;
	padding: 24px !important;
}
.z-loading-icon,
.z-loading-indicator .z-loading-icon {
	width: 40px !important;
	height: 40px !important;
	border: 3px solid rgba(37, 202, 210, 0.25) !important;
	border-top-color: var(--hco-primary) !important;
	border-radius: 50% !important;
	background: none !important;
	animation: hco-spin 0.8s linear infinite !important;
}
@keyframes hco-spin {
	to { transform: rotate(360deg); }
}

/* Remove remaining 3D / gradient chrome */
.z-button,
.z-toolbarbutton,
.z-tab,
.z-panel-header,
.z-window-header,
.z-combobox-button,
.z-datebox-button,
.z-bandbox-button {
	background-image: none !important;
	text-shadow: none !important;
}
