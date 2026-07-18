package com.aberp.rostering.staffinfo.process;

import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.adempiere.webui.adwindow.ADWindow;
import org.adempiere.webui.apps.AEnv;
import org.adempiere.webui.component.Window;
import org.adempiere.webui.session.SessionManager;
import org.compiere.model.MTable;
import org.compiere.model.MUser;
import org.compiere.model.PO;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.compiere.util.Util;
import org.zkoss.zk.ui.Component;
import org.zkoss.zk.ui.event.Events;

import com.aberp.rostering.staffinfo.info.StaffRosteringInfoWindow;

/**
 * SAW030 — Response Log → Find and Fill.
 * Opens Staff Rostering Info with the response worker prefilled and shift context
 * for leave/overlap/familiar/matched checks. OK on the Info fills a vacant Employee line.
 */
public class ResponseLogFindFill extends SvrProcess {

	public static final String CTX_RESPONSE_LOG_ID = "AbERP_FindFill_ResponseLog_ID";

	private static final String TABLE_RESPONSE_LOG = "AbERP_RosteredResponseLog";

	@Override
	protected void prepare() {
		// Record context from Response Log button.
	}

	@Override
	protected String doIt() throws Exception {
		final int responseLogTableId = MTable.getTable_ID(TABLE_RESPONSE_LOG);
		if (getTable_ID() != responseLogTableId) {
			throw new AdempiereException("Run Find and Fill from a Response Log record");
		}

		final int responseLogId = getRecord_ID();
		if (responseLogId <= 0) {
			throw new AdempiereException("Select a response log row first");
		}

		final PO responseLog = MTable.get(getCtx(), TABLE_RESPONSE_LOG).getPO(responseLogId, get_TrxName());
		if (responseLog == null || responseLog.get_ID() <= 0) {
			throw new AdempiereException("Response log record not found");
		}

		if (isYes(responseLog.get_Value("IsReviewed"))) {
			throw new AdempiereException("This response has already been reviewed");
		}

		final int shiftId = getInt(responseLog.get_Value("AbERP_Rostered_Shift_ID"));
		if (shiftId <= 0) {
			throw new AdempiereException("Response log is missing a shift");
		}

		final int userContactId = getInt(responseLog.get_Value("AbERP_User_Contact_ID"));
		if (userContactId <= 0) {
			throw new AdempiereException("Response log is missing the worker to review");
		}

		final MUser user = MUser.get(getCtx(), userContactId);
		if (user == null || user.get_ID() <= 0) {
			throw new AdempiereException("Worker user not found");
		}

		final String staffName = Util.isEmpty(user.getName()) ? "" : user.getName().trim();
		final int infoWindowId = resolveInfoWindowId();
		if (infoWindowId <= 0) {
			throw new AdempiereException("Staff Rostering Info Window not found");
		}

		final int logId = responseLogId;
		final int shift = shiftId;
		final int infoId = infoWindowId;
		final String queryValue = staffName;
		try {
			AEnv.executeAsyncDesktopTask(new Runnable() {
				@Override
				public void run() {
					try {
						int windowNo = resolveActiveWindowNo();
						if (windowNo <= 0) {
							throw new AdempiereException(
									"Open Find and Fill from Shift (Rostered) → Response Log");
						}
						Env.setContext(Env.getCtx(), windowNo, "AbERP_Rostered_Shift_ID", shift);
						Env.setContext(Env.getCtx(), windowNo, CTX_RESPONSE_LOG_ID, logId);

						StaffRosteringInfoWindow info = new StaffRosteringInfoWindow(
								windowNo, "AD_User", "AD_User_ID", queryValue,
								false, "", infoId, false, null);
						info.setAttribute(Window.MODE_KEY, Window.MODE_HIGHLIGHTED);
						info.setTitle("Find and Fill — "
								+ (Util.isEmpty(queryValue) ? "Staff" : queryValue));
						SessionManager.getAppDesktop().showWindow(info);
						Events.echoEvent("onUserQuery", info, null);
					} catch (Exception e) {
						log.log(Level.SEVERE, "Open Find and Fill", e);
						throw new RuntimeException(e.getMessage(), e);
					}
				}
			});
		} catch (Exception e) {
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open Find and Fill: " + cause.getMessage());
		}

		return "@OK@ Review the worker against the shift, then OK to fill a vacant Employee slot";
	}

	/** WindowNo of the active Shift (Rostered) AD window (iDempiere 7.1 ProcessInfo has no getWindowNo). */
	private static int resolveActiveWindowNo() {
		Component active = SessionManager.getAppDesktop().getActiveWindow();
		if (active instanceof ADWindow) {
			ADWindow adw = (ADWindow) active;
			if (adw.getADWindowContent() != null) {
				return adw.getADWindowContent().getWindowNo();
			}
		}
		return 0;
	}

	private int resolveInfoWindowId() {
		return DB.getSQLValue(get_TrxName(),
				"SELECT AD_InfoWindow_ID FROM AD_InfoWindow WHERE AD_InfoWindow_UU=? AND IsActive='Y'",
				StaffRosteringInfoWindow.INFO_WINDOW_UU);
	}

	private static boolean isYes(Object value) {
		if (value == null) {
			return false;
		}
		if (value instanceof Boolean) {
			return ((Boolean) value).booleanValue();
		}
		final String s = String.valueOf(value);
		return "Y".equalsIgnoreCase(s) || "true".equalsIgnoreCase(s);
	}

	private static int getInt(Object value) {
		if (value == null) {
			return 0;
		}
		if (value instanceof Number) {
			return ((Number) value).intValue();
		}
		try {
			return Integer.parseInt(String.valueOf(value));
		} catch (NumberFormatException ex) {
			return 0;
		}
	}
}
