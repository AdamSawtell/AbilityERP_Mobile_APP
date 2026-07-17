package com.aberp.activityaudit.process;

import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Enumeration;
import java.util.Properties;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MQuery;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

/**
 * SAW027 — Open the Contact Activity linked from an Activity Audit Review row.
 * Same pattern as SAW024 OpenComplianceSource: Button → process → AEnv.zoom(window, MQuery).
 * Prefer Activity Viewer (C_ContactActivity is tab 10); Contact window puts Activity on tab 20.
 */
public class OpenActivity extends SvrProcess {

	private static final String ACTIVITY_VIEWER_UU = "e5e62a4b-bd38-49d6-b2e7-e5a44e194b0e";

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		int reviewId = resolveReviewId();
		if (reviewId <= 0) {
			throw new AdempiereException("Select an Activity Audit Review row first");
		}

		int activityId = 0;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT C_ContactActivity_ID FROM AbERP_ActivityAuditReview "
							+ "WHERE AbERP_ActivityAuditReview_ID=?",
					get_TrxName());
			pstmt.setInt(1, reviewId);
			rs = pstmt.executeQuery();
			if (!rs.next()) {
				throw new AdempiereException("Review not found: " + reviewId);
			}
			activityId = rs.getInt(1);
		} finally {
			DB.close(rs, pstmt);
		}
		if (activityId <= 0) {
			throw new AdempiereException("Review has no linked Activity");
		}

		final int zoomRecord = activityId;
		try {
			Class<?> aenv = loadAEnv();
			Method async = aenv.getMethod("executeAsyncDesktopTask", Runnable.class);
			Runnable task = new Runnable() {
				@Override
				public void run() {
					try {
						zoomActivity(aenv, zoomRecord);
					} catch (AdempiereException e) {
						throw e;
					} catch (Exception e) {
						Throwable cause = e.getCause() != null ? e.getCause() : e;
						throw new RuntimeException(cause);
					}
				}
			};
			async.invoke(null, task);
			return "@OK@ Opened Activity " + activityId;
		} catch (ClassNotFoundException e) {
			throw new AdempiereException(
					"WebUI zoom unavailable. Open Activity Viewer manually — ID=" + activityId);
		} catch (Exception e) {
			log.log(Level.SEVERE, "AEnv.zoom", e);
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open Activity: " + cause.getMessage()
					+ " (C_ContactActivity_ID=" + activityId + ")");
		}
	}

	/** Zoom Activity Viewer (or any window whose first tab is C_ContactActivity) via MQuery. */
	private void zoomActivity(Class<?> aenv, int activityId) throws Exception {
		int windowId = resolveActivityWindowId();
		MQuery query = MQuery.getEqualQuery("C_ContactActivity_ID", activityId);
		query.setRecordCount(1);

		if (windowId > 0) {
			try {
				Method zoomWin = aenv.getMethod("zoom", int.class, MQuery.class);
				zoomWin.invoke(null, Integer.valueOf(windowId), query);
				return;
			} catch (NoSuchMethodException ignored) {
				// try other signatures
			}
			try {
				Method zoomQ = aenv.getMethod("zoom", MQuery.class);
				zoomQ.invoke(null, query);
				return;
			} catch (NoSuchMethodException ignored) {
				// fall through
			}
		}

		int tableId = DB.getSQLValue(null,
				"SELECT AD_Table_ID FROM AD_Table WHERE TableName='C_ContactActivity'");
		if (tableId <= 0) {
			throw new AdempiereException("C_ContactActivity table not found");
		}
		Method zoom = aenv.getMethod("zoom", int.class, int.class);
		zoom.invoke(null, Integer.valueOf(tableId), Integer.valueOf(activityId));
	}

	/**
	 * Prefer Activity Viewer by UU/name; else any window whose SeqNo=10 tab is C_ContactActivity.
	 * Do not use AD_Table.AD_Window_ID alone — on HCO it points at Contact (User first).
	 */
	private int resolveActivityWindowId() {
		int windowId = DB.getSQLValue(null,
				"SELECT AD_Window_ID FROM AD_Window WHERE AD_Window_UU=? OR Name=?",
				ACTIVITY_VIEWER_UU, "Activity Viewer");
		if (windowId > 0) {
			return windowId;
		}
		windowId = DB.getSQLValue(null,
				"SELECT COALESCE(MIN(w.AD_Window_ID),0) FROM AD_Window w"
						+ " INNER JOIN AD_Tab t ON t.AD_Window_ID=w.AD_Window_ID AND t.SeqNo=10 AND t.IsActive='Y'"
						+ " INNER JOIN AD_Table tb ON tb.AD_Table_ID=t.AD_Table_ID"
						+ " WHERE tb.TableName='C_ContactActivity' AND w.IsActive='Y'");
		return windowId > 0 ? windowId : 0;
	}

	private static Class<?> loadAEnv() throws ClassNotFoundException {
		try {
			return Class.forName("org.adempiere.webui.apps.AEnv");
		} catch (ClassNotFoundException ignored) {
			// OSGi
		}
		Bundle self = FrameworkUtil.getBundle(OpenActivity.class);
		if (self != null && self.getBundleContext() != null) {
			for (Bundle b : self.getBundleContext().getBundles()) {
				String sn = b.getSymbolicName();
				if (sn == null) {
					continue;
				}
				if (sn.contains("adempiere.ui.zk") || sn.equals("org.adempiere.ui.zk")
						|| sn.contains("webui")) {
					try {
						return b.loadClass("org.adempiere.webui.apps.AEnv");
					} catch (ClassNotFoundException ignored) {
						// next
					}
				}
			}
		}
		throw new ClassNotFoundException("org.adempiere.webui.apps.AEnv");
	}

	/** Process Record_ID first; then scan Env for AbERP_ActivityAuditReview_ID. */
	private int resolveReviewId() {
		int id = getRecord_ID();
		if (isReview(id)) {
			return id;
		}

		Properties ctx = getCtx();
		int ctxId = Env.getContextAsInt(ctx, "AbERP_ActivityAuditReview_ID");
		if (isReview(ctxId)) {
			return ctxId;
		}
		for (int w = 0; w < 20; w++) {
			ctxId = Env.getContextAsInt(ctx, w, "AbERP_ActivityAuditReview_ID");
			if (isReview(ctxId)) {
				return ctxId;
			}
		}

		Enumeration<?> keys = ctx.keys();
		while (keys.hasMoreElements()) {
			Object key = keys.nextElement();
			if (key == null) {
				continue;
			}
			String k = key.toString();
			if (k.endsWith("|AbERP_ActivityAuditReview_ID") || k.equals("AbERP_ActivityAuditReview_ID")) {
				try {
					int v = Integer.parseInt(String.valueOf(ctx.get(key)));
					if (isReview(v)) {
						return v;
					}
				} catch (Exception ignored) {
					// next
				}
			}
		}
		return id > 0 ? id : 0;
	}

	private boolean isReview(int id) {
		if (id <= 0) {
			return false;
		}
		Integer exists = DB.getSQLValue(get_TrxName(),
				"SELECT AbERP_ActivityAuditReview_ID FROM AbERP_ActivityAuditReview "
						+ "WHERE AbERP_ActivityAuditReview_ID=?",
				id);
		return exists != null && exists.intValue() > 0;
	}
}
