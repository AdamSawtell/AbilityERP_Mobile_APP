package com.aberp.rostering.chat.webui;

import org.adempiere.webui.adwindow.ADTabpanel;
import org.adempiere.webui.adwindow.AbstractADWindowContent;
import org.adempiere.webui.adwindow.DetailPane;
import org.compiere.model.DataStatusEvent;
import org.compiere.model.GridTab;
import org.compiere.model.MQuery;
import org.compiere.util.CLogger;
import org.zkoss.zk.ui.event.Event;
import org.zkoss.zk.ui.event.Events;
import org.zkoss.zul.Timer;

/**
 * Rostering Chat header tab that re-reads R_Request from the database when the
 * officer navigates records and on a short timer while the tab is active.
 * <p>
 * Worker replies update the DB (and the Updates detail tab) immediately, but
 * iDempiere keeps parent GridTab rows in a query snapshot — without this,
 * Chat Assigned / Last Message stay stale until a full ReQuery.
 * <p>
 * Also applies the shared "Response required" inbox filter on first activate.
 * AD_UserQuery IsDefault is skipped when the menu opens the window with a
 * non-null MQuery; this keeps Lookup (Awaiting worker / Closed) working
 * because the tab WhereClause stays type-only.
 */
public class RosteringChatTabPanel extends ADTabpanel {

	public static final String TAB_TYPE = "ROSTERING_CHAT";

	private static final String INBOX_RESTRICTION =
			"R_Request.AbERP_ChatAwaitingReply='Response required'";

	private static final int REFRESH_MS = 4000;
	private static final CLogger log = CLogger.getCLogger(RosteringChatTabPanel.class);

	private Timer timer;
	private boolean refreshing;
	private boolean inboxDefaultApplied;
	private int lastRecordId = -1;

	@Override
	public void init(AbstractADWindowContent winContent, GridTab gridTab) {
		super.init(winContent, gridTab);
		ensureTimer();
	}

	@Override
	public void activate(boolean activate) {
		super.activate(activate);
		if (activate) {
			applyInboxDefaultIfNeeded();
			refreshLiveHeader();
			startTimer();
		} else {
			stopTimer();
		}
	}

	@Override
	public void dataStatusChanged(DataStatusEvent e) {
		super.dataStatusChanged(e);
		if (refreshing) {
			return;
		}
		GridTab gt = getGridTab();
		if (gt == null) {
			return;
		}
		int id = gt.getRecord_ID();
		if (id > 0 && id != lastRecordId) {
			lastRecordId = id;
			refreshLiveHeader();
		}
	}

	@Override
	public void onEvent(Event event) {
		if (Events.ON_TIMER.equals(event.getName())) {
			refreshLiveHeader();
			return;
		}
		super.onEvent(event);
	}

	@Override
	public void onPageDetached(org.zkoss.zk.ui.Page page) {
		stopTimer();
		super.onPageDetached(page);
	}

	/**
	 * Default inbox = Chat Assigned = Response required. Runs once per open
	 * window so toolbar Lookup can still switch to Awaiting worker / Closed.
	 */
	private void applyInboxDefaultIfNeeded() {
		if (inboxDefaultApplied) {
			return;
		}
		inboxDefaultApplied = true;
		GridTab gt = getGridTab();
		if (gt == null) {
			return;
		}
		MQuery q = gt.getQuery();
		String existing = q != null ? q.getWhereClause() : null;
		if (existing != null && existing.contains("AbERP_ChatAwaitingReply")) {
			return;
		}
		if (q == null) {
			q = new MQuery(gt.getTableName());
		}
		q.addRestriction(INBOX_RESTRICTION);
		gt.setQuery(q);
		try {
			query(false, 0, 0);
		} catch (Exception ex) {
			log.warning("Rostering Chat inbox default filter skipped: " + ex.getMessage());
		}
	}

	private void ensureTimer() {
		if (timer != null) {
			return;
		}
		timer = new Timer(REFRESH_MS);
		timer.setRepeats(true);
		timer.setRunning(false);
		timer.addEventListener(Events.ON_TIMER, this);
		appendChild(timer);
	}

	private void startTimer() {
		ensureTimer();
		if (!timer.isRunning()) {
			timer.start();
		}
	}

	private void stopTimer() {
		if (timer != null && timer.isRunning()) {
			timer.stop();
		}
	}

	private void refreshLiveHeader() {
		if (refreshing || !isActivated()) {
			return;
		}
		GridTab gt = getGridTab();
		if (gt == null || gt.getRecord_ID() <= 0) {
			return;
		}
		if (gt.isNew()) {
			return;
		}
		// Do not wipe an in-progress Reply draft the officer is typing.
		if (needSave(true, false)) {
			return;
		}

		refreshing = true;
		try {
			gt.dataRefresh();
			lastRecordId = gt.getRecord_ID();
			DetailPane detail = getDetailPane();
			if (detail != null) {
				detail.refresh();
			}
		} catch (Exception ex) {
			log.warning("Rostering Chat live refresh skipped: " + ex.getMessage());
		} finally {
			refreshing = false;
		}
	}
}
