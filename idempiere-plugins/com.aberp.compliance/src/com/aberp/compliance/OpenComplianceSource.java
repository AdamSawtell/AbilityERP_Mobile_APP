package com.aberp.compliance;

import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.logging.Level;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.process.SvrProcess;
import org.compiere.util.DB;
import org.compiere.util.Env;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

/**
 * SAW024 — Open the source record for a compliance finding (Credential Assignment).
 * Resolves finding ID from process Record_ID or tab context, then zooms on the UI thread.
 */
public class OpenComplianceSource extends SvrProcess {

	@Override
	protected void prepare() {
		// no parameters
	}

	@Override
	protected String doIt() throws Exception {
		int findingId = resolveFindingId();
		if (findingId <= 0) {
			throw new AdempiereException("Select an Open Findings row first");
		}

		int sourceTableId = 0;
		int sourceRecordId = 0;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = DB.prepareStatement(
					"SELECT AD_Table_ID, Record_ID, COALESCE(AbERP_SourceAssignment_ID, AbERP_OpenAssignment_ID, Record_ID) "
							+ "FROM AbERP_ComplianceResult WHERE AbERP_ComplianceResult_ID=?",
					get_TrxName());
			pstmt.setInt(1, findingId);
			rs = pstmt.executeQuery();
			if (!rs.next()) {
				throw new AdempiereException("Compliance finding not found: " + findingId);
			}
			sourceTableId = rs.getInt(1);
			sourceRecordId = rs.getInt(3);
			if (sourceRecordId <= 0) {
				sourceRecordId = rs.getInt(2);
			}
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
			Class<?> aenv = loadAEnv();
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
			return "@OK@ Opened Credential Assignment " + recordId
					+ ". Update expiry, Save, then Refresh Compliance.";
		} catch (ClassNotFoundException e) {
			throw new AdempiereException(
					"WebUI zoom unavailable. Open Credential Assignment manually — ID=" + recordId);
		} catch (Exception e) {
			log.log(Level.SEVERE, "AEnv.zoom", e);
			Throwable cause = e.getCause() != null ? e.getCause() : e;
			throw new AdempiereException("Could not open source: " + cause.getMessage()
					+ " (Assignment ID=" + recordId + ")");
		}
	}

	/** Load WebUI AEnv via OSGi (plain Class.forName fails from process bundles). */
	private static Class<?> loadAEnv() throws ClassNotFoundException {
		try {
			return Class.forName("org.adempiere.webui.apps.AEnv");
		} catch (ClassNotFoundException ignored) {
			// fall through to OSGi bundle lookup
		}
		Bundle self = FrameworkUtil.getBundle(OpenComplianceSource.class);
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
						// try next bundle
					}
				}
			}
		}
		throw new ClassNotFoundException("org.adempiere.webui.apps.AEnv");
	}

	/** Prefer process Record_ID; fall back to Open Findings tab context. */
	private int resolveFindingId() {
		int id = getRecord_ID();
		if (id > 0) {
			Integer exists = DB.getSQLValue(get_TrxName(),
					"SELECT AbERP_ComplianceResult_ID FROM AbERP_ComplianceResult WHERE AbERP_ComplianceResult_ID=?",
					id);
			if (exists != null && exists.intValue() > 0) {
				return id;
			}
		}
		int ctxId = Env.getContextAsInt(getCtx(), "AbERP_ComplianceResult_ID");
		if (ctxId <= 0) {
			ctxId = Env.getContextAsInt(getCtx(), 0, "AbERP_ComplianceResult_ID");
		}
		if (ctxId > 0) {
			return ctxId;
		}
		return id;
	}
}
