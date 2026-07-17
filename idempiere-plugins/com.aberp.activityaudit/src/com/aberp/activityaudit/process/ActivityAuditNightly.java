package com.aberp.activityaudit.process;

import org.compiere.process.SvrProcess;

import com.aberp.activityaudit.engine.ActivityAuditEngine;

public class ActivityAuditNightly extends SvrProcess {
	@Override
	protected void prepare() {
		// no parameters — last 24 hours
	}

	@Override
	protected String doIt() throws Exception {
		ActivityAuditEngine engine = new ActivityAuditEngine(getCtx(), get_TrxName());
		String summary = engine.runNightly();
		for (String line : engine.getLogs()) {
			addLog(0, null, null, line);
		}
		return summary;
	}
}
