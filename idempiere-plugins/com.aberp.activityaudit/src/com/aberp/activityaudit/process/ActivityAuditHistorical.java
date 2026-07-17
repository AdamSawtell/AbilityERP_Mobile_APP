package com.aberp.activityaudit.process;

import java.sql.Timestamp;

import org.compiere.process.ProcessInfoParameter;
import org.compiere.process.SvrProcess;

import com.aberp.activityaudit.engine.ActivityAuditEngine;

public class ActivityAuditHistorical extends SvrProcess {

	private Timestamp dateFrom;
	private Timestamp dateTo;
	private int orgId;
	private String activityType;
	private String category;
	private boolean includePreviouslyProcessed;
	private boolean onlyNewTerms;
	private boolean reopenExisting = true;

	@Override
	protected void prepare() {
		for (ProcessInfoParameter para : getParameter()) {
			String name = para.getParameterName();
			if (para.getParameter() == null && !"IncludePreviouslyProcessed".equals(name)
					&& !"OnlyNewTerms".equals(name) && !"ReopenExistingReviews".equals(name)) {
				continue;
			}
			if ("DateFrom".equals(name)) {
				dateFrom = para.getParameterAsTimestamp();
			} else if ("DateTo".equals(name)) {
				dateTo = para.getParameterAsTimestamp();
			} else if ("AD_Org_ID".equals(name)) {
				orgId = para.getParameterAsInt();
			} else if ("ContactActivityType".equals(name)) {
				activityType = para.getParameterAsString();
			} else if ("Category".equals(name)) {
				category = para.getParameterAsString();
			} else if ("IncludePreviouslyProcessed".equals(name)) {
				includePreviouslyProcessed = "Y".equals(para.getParameterAsString())
						|| para.getParameterAsBoolean();
			} else if ("OnlyNewTerms".equals(name)) {
				onlyNewTerms = "Y".equals(para.getParameterAsString())
						|| para.getParameterAsBoolean();
			} else if ("ReopenExistingReviews".equals(name)) {
				reopenExisting = para.getParameter() == null
						|| "Y".equals(para.getParameterAsString())
						|| para.getParameterAsBoolean();
			}
		}
	}

	@Override
	protected String doIt() throws Exception {
		if (dateFrom == null || dateTo == null) {
			return "Start Date and End Date are required";
		}
		// inclusive end-of-day
		Timestamp to = new Timestamp(dateTo.getTime() + 24L * 60L * 60L * 1000L);
		ActivityAuditEngine engine = new ActivityAuditEngine(getCtx(), get_TrxName());
		String summary = engine.runHistorical(dateFrom, to, orgId, activityType, category,
				includePreviouslyProcessed, onlyNewTerms, reopenExisting);
		for (String line : engine.getLogs()) {
			addLog(0, null, null, line);
		}
		return summary;
	}
}
