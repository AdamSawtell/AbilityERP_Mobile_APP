package com.aberp.compliance;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.process.SvrProcess;

/**
 * SAW023 — Refresh Compliance.
 * Phase 3: evaluates Employee credential rules and refreshes organisation snapshots.
 */
public class RefreshCompliance extends SvrProcess {

	public static final String TABLE_DASHBOARD = "AbERP_ComplianceDashboard";

	@Override
	protected void prepare() {
		// As At Date parameter reserved for later
	}

	@Override
	protected String doIt() throws Exception {
		int tableId = MTable.getTable_ID(TABLE_DASHBOARD);
		if (tableId <= 0) {
			throw new AdempiereException("SAW023: AbERP_ComplianceDashboard table missing");
		}
		if (getTable_ID() > 0 && getTable_ID() != tableId) {
			throw new AdempiereException("Run Refresh Compliance from the Organisation Audit tab");
		}
		if (getRecord_ID() <= 0) {
			throw new AdempiereException("Select an organisation audit row first");
		}

		ComplianceEngine engine = new ComplianceEngine(getCtx(), get_TrxName());
		String summary = engine.refresh();
		for (String line : engine.getLogs()) {
			addLog(0, null, null, line);
		}
		return summary;
	}
}
