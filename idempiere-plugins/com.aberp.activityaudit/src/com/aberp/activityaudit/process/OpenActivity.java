package com.aberp.activityaudit.process;

import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;

/**
 * SAW027 — Zoom to the Contact Activity linked from an Activity Audit Review row.
 */
public class OpenActivity extends SvrProcess {

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		int reviewId = getRecord_ID();
		if (reviewId <= 0) {
			throw new AdempiereException("Select an Activity Audit Review row first");
		}

		int activityId = 0;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT C_ContactActivity_ID FROM AbERP_ActivityAuditReview WHERE AbERP_ActivityAuditReview_ID=?",
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

		int tableId = DB.getSQLValue(get_TrxName(),
				"SELECT AD_Table_ID FROM AD_Table WHERE TableName='C_ContactActivity'");
		if (tableId <= 0) {
			throw new AdempiereException("C_ContactActivity table not found");
		}

		final int zoomTable = tableId;
		final int zoomRecord = activityId;
		try {
			Class<?> aenv = Class.forName("org.adempiere.webui.apps.AEnv");
			Method async = aenv.getMethod("executeAsyncDesktopTask", Runnable.class);
			Runnable task = new Runnable() {
				@Override
				public void run() {
					try {
						Method zoom = aenv.getMethod("zoom", int.class, int.class);
						zoom.invoke(null, Integer.valueOf(zoomTable), Integer.valueOf(zoomRecord));
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
					"WebUI zoom unavailable. Open Contact Activity manually — ID=" + activityId);
		} catch (Exception e) {
			log.log(Level.SEVERE, "AEnv.zoom", e);
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open Activity: " + cause.getMessage());
		}
	}
}
