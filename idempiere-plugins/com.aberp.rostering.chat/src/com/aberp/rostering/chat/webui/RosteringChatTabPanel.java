package com.aberp.rostering.chat.webui;

import org.adempiere.webui.adwindow.ADTabpanel;
import org.adempiere.webui.adwindow.AbstractADWindowContent;
import org.adempiere.webui.adwindow.DetailPane;
import org.compiere.model.DataStatusEvent;
import org.compiere.model.GridTab;
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
 */
public class RosteringChatTabPanel extends ADTabpanel {

	public static final String TAB_TYPE = "ROSTERING_CHAT";

	private static final int REFRESH_MS = 4000;
	private static final CLogger log = CLogger.getCLogger(RosteringChatTabPanel.class);

	private Timer timer;
	private boolean refreshing;
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
