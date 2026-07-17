package com.aberp.activityaudit.callout;

import java.util.Properties;

import org.compiere.model.CalloutEngine;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.util.Env;
import org.compiere.util.TimeUtil;

/**
 * SAW027 — when Reviewed is checked, stamp Reviewed By / Date and set status.
 */
public class CalloutActivityAuditReview extends CalloutEngine {

	public String reviewed(Properties ctx, int WindowNo, GridTab mTab, GridField mField,
			Object value) {
		if (isCalloutActive() || value == null) {
			return "";
		}
		String reviewed = value.toString();
		if ("Y".equals(reviewed)) {
			mTab.setValue("ReviewedBy", Integer.valueOf(Env.getAD_User_ID(ctx)));
			mTab.setValue("ReviewedDate", TimeUtil.getDay(System.currentTimeMillis()));
			Object status = mTab.getValue("ReviewStatus");
			String st = status == null ? "NW" : status.toString();
			if ("NW".equals(st) || "UR".equals(st)) {
				mTab.setValue("ReviewStatus", "NF");
			}
		}
		return "";
	}
}
