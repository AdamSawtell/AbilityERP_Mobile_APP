package com.aberp.compliance;

import org.adempiere.exceptions.AdempiereException;
import org.compiere.model.MTable;
import org.compiere.process.SvrProcess;

/**
 * SAW023 Phase 2 — Refresh Compliance (stub).
 * Button on NDIS Audit Tool → Organisation Audit.
 * Later phases: evaluate rules, write AbERP_ComplianceResult, refresh snapshots.
 */
public class RefreshCompliance extends SvrProcess {

	public static final String TABLE_DASHBOARD = "AbERP_ComplianceDashboard";

	@Override
	protected void prepare() {
		// Phase 2 stub: no parameters yet (As At Date comes later)
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

		addLog(0, null, null,
				"Compliance refresh stub OK for dashboard record " + getRecord_ID()
						+ " (rule evaluation not wired yet)");
		return "Compliance refresh completed (stub). Rule evaluation comes in Phase 3.";
	}
}
