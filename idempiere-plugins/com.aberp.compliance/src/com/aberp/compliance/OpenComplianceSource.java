package com.aberp.compliance;

import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;

/**
 * SAW024 — Open the source record for a compliance finding (e.g. Credential Assignment).
 * Uses reflection to call WebUI AEnv.executeAsyncDesktopTask + AEnv.zoom so the
 * OSGi bundle stays base-only and zoom runs on the UI thread.
 */
public class OpenComplianceSource extends SvrProcess {

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		if (getRecord_ID() <= 0) {
			throw new AdempiereException("Select an Open Findings row first");
		}

		int sourceTableId = 0;
		int sourceRecordId = 0;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT AD_Table_ID, Record_ID FROM AbERP_ComplianceResult WHERE AbERP_ComplianceResult_ID=?",
					get_TrxName());
			pstmt.setInt(1, getRecord_ID());
			rs = pstmt.executeQuery();
			if (!rs.next()) {
				throw new AdempiereException("Compliance finding not found");
			}
			sourceTableId = rs.getInt(1);
			sourceRecordId = rs.getInt(2);
		} catch (AdempiereException e) {
			throw e;
		} catch (Exception e) {
			log.log(Level.SEVERE, "OpenComplianceSource", e);
			throw new AdempiereException("Could not load finding: " + e.getMessage());
		} finally {
			DB.close(rs, pstmt);
		}

		if (sourceTableId <= 0 || sourceRecordId <= 0) {
			throw new AdempiereException("Finding has no source table/record to open");
		}

		final int tableId = sourceTableId;
		final int recordId = sourceRecordId;

		try {
			Class<?> aenv = Class.forName("org.adempiere.webui.apps.AEnv");
			Method zoom = aenv.getMethod("zoom", int.class, int.class);
			Method async = aenv.getMethod("executeAsyncDesktopTask", Runnable.class);
			Runnable task = new Runnable() {
				@Override
				public void run() {
					try {
						zoom.invoke(null, Integer.valueOf(tableId), Integer.valueOf(recordId));
					} catch (Exception e) {
						throw new RuntimeException(e);
					}
				}
			};
			async.invoke(null, task);
			return "@OK@ Opened source record " + recordId
					+ " (table " + tableId + "). Update the assignment, then Refresh Compliance.";
		} catch (ClassNotFoundException e) {
			throw new AdempiereException(
					"WebUI zoom unavailable. Source Table_ID=" + tableId
							+ " Record_ID=" + recordId
							+ ". Use Open Assignment zoom instead.");
		} catch (Exception e) {
			log.log(Level.SEVERE, "AEnv.zoom", e);
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open source: " + cause.getMessage()
					+ ". Use Open Assignment zoom instead.");
		}
	}
}
