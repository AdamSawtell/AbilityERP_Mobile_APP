package com.aberp.activityaudit.factory;

import org.adempiere.base.IColumnCallout;
import org.adempiere.base.IColumnCalloutFactory;
import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.activityaudit.callout.CalloutActivityAuditReview;
import com.aberp.activityaudit.process.ActivityAuditHistorical;
import com.aberp.activityaudit.process.ActivityAuditNightly;
import com.aberp.activityaudit.process.OpenActivity;
import com.aberp.activityaudit.process.OpenActivityClient;
import com.aberp.activityaudit.process.OpenActivityEmployee;
import com.aberp.activityaudit.process.OpenActivitySupportLocation;

public class ActivityAuditProcessFactory implements IProcessFactory, IColumnCalloutFactory {

	@Override
	public ProcessCall newProcessInstance(String className) {
		if (ActivityAuditNightly.class.getName().equals(className)) {
			return new ActivityAuditNightly();
		}
		if (ActivityAuditHistorical.class.getName().equals(className)) {
			return new ActivityAuditHistorical();
		}
		if (OpenActivity.class.getName().equals(className)) {
			return new OpenActivity();
		}
		if (OpenActivityClient.class.getName().equals(className)) {
			return new OpenActivityClient();
		}
		if (OpenActivityEmployee.class.getName().equals(className)) {
			return new OpenActivityEmployee();
		}
		if (OpenActivitySupportLocation.class.getName().equals(className)) {
			return new OpenActivitySupportLocation();
		}
		return null;
	}

	@Override
	public IColumnCallout[] getColumnCallouts(String tableName, String columnName) {
		if ("AbERP_ActivityAuditReview".equalsIgnoreCase(tableName)
				&& "IsReviewed".equalsIgnoreCase(columnName)) {
			return new IColumnCallout[] { new CalloutActivityAuditReviewAdapter() };
		}
		return null;
	}

	/** Bridge classic CalloutEngine method to IColumnCallout. */
	private static class CalloutActivityAuditReviewAdapter implements IColumnCallout {
		private final CalloutActivityAuditReview delegate = new CalloutActivityAuditReview();

		@Override
		public String start(java.util.Properties ctx, int WindowNo, org.compiere.model.GridTab mTab,
				org.compiere.model.GridField mField, Object value, Object oldValue) {
			return delegate.reviewed(ctx, WindowNo, mTab, mField, value);
		}
	}
}
