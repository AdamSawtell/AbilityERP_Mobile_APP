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

/* Field labels */
.adwindow-form .z-label,
.form-label,
td.form-label .z-label {
	color: var(--hco-text) !important;
	font-weight: 400 !important;
	font-size: 13px !important;
}

/* ===== Toolbar tiles (ribbon) ===== */
.z-toolbar .z-toolbarbutton,
.desktop-toolbar .z-toolbarbutton,
.adwindow-toolbar .z-toolbarbutton,
.font-icon-toolbar-button.toolbar-button {
	border-radius: var(--hco-radius-lg) !important;
	padding: 6px 12px !important;
	margin: 2px 4px !important;
	background: var(--hco-primary) !important;
	background-image: none !important;
	color: var(--hco-text) !important;
	font-family: 'Poppins', sans-serif !important;
	font-weight: 500 !important;
	font-size: 13px !important;
	border: none !important;
	box-shadow: var(--hco-shadow);
	transition: all 0.15s ease;
	width: auto !important;
	height: auto !important;
	min-height: 32px;
}
.z-toolbar .z-toolbarbutton:hover,
.desktop-toolbar .z-toolbarbutton:hover,
.adwindow-toolbar .z-toolbarbutton:hover,
.font-icon-toolbar-button.toolbar-button:hover {
	background: var(--hco-secondary) !important;
	color: var(--hco-text) !important;
	box-shadow: 0 2px 6px rgba(0,0,0,0.15);
	transform: translateY(-1px);
}
.z-toolbar .z-toolbarbutton .z-toolbarbutton-content,
.font-icon-toolbar-button.toolbar-button .z-toolbarbutton-content {
	color: inherit !important;
}
.font-icon-toolbar-button.toolbar-button [class^="z-icon-"] {
	color: inherit !important;
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

/* Record navigation pills */
.adwindow-status-docinfo .z-toolbarbutton,
.adwindow-status .z-toolbarbutton,
.record-nav .z-toolbarbutton,
.adwindow-nav .z-toolbarbutton {
	border-radius: 999px !important;
	background: var(--hco-primary) !important;
	color: var(--hco-text) !important;
	padding: 4px 10px !important;
}

/* ===== Tabs — flat underline ===== */
.z-tab,
.z-tab-content {
	background: transparent !important;
	background-image: none !important;
	border: none !important;
	border-radius: 0 !important;
	box-shadow: none !important;
}
.z-tab .z-tab-text {
	color: var(--hco-text) !important;
	font-weight: 400 !important;
}
.z-tab:hover .z-tab-text {
	color: var(--hco-heading) !important;
}
.z-tab-selected {
	border-bottom: 3px solid var(--hco-primary) !important;
	background: transparent !important;
}
.z-tab-selected .z-tab-text {
	color: var(--hco-heading) !important;
	font-weight: 600 !important;
}
.z-tabs-content,
.z-tabbox-content {
	border-bottom: 1px solid #ddd !important;
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
