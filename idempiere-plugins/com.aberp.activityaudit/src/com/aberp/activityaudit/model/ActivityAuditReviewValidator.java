package com.aberp.activityaudit.model;

import java.sql.Timestamp;
import java.util.Properties;

import org.compiere.model.MClient;
import org.compiere.model.ModelValidationEngine;
import org.compiere.model.ModelValidator;
import org.compiere.model.PO;
import org.compiere.util.Env;
import org.compiere.util.TimeUtil;

/**
 * SAW027 — stamp Reviewed By / Date and advance status when IsReviewed is set.
 * Preferred over classic AD_Column.Callout (OSGi ClassNotFound under org.adempiere.base).
 */
public class ActivityAuditReviewValidator implements ModelValidator {

	public static final String CLASSNAME = ActivityAuditReviewValidator.class.getName();
	private static final String TABLE = "AbERP_ActivityAuditReview";

	private int m_AD_Client_ID = -1;

	@Override
	public void initialize(ModelValidationEngine engine, MClient client) {
		m_AD_Client_ID = client != null ? client.getAD_Client_ID() : -1;
		engine.addModelChange(TABLE, this);
	}

	@Override
	public int getAD_Client_ID() {
		return m_AD_Client_ID;
	}

	@Override
	public String login(int AD_Org_ID, int AD_Role_ID, int AD_User_ID) {
		return null;
	}

	@Override
	public String modelChange(PO po, int type) throws Exception {
		if (po == null || !TABLE.equalsIgnoreCase(po.get_TableName())) {
			return null;
		}
		if (type != TYPE_BEFORE_CHANGE && type != TYPE_BEFORE_NEW) {
			return null;
		}
		if (!po.is_ValueChanged("IsReviewed")) {
			return null;
		}
		boolean reviewed = po.get_ValueAsBoolean("IsReviewed");
		if (!reviewed) {
			return null;
		}
		Properties ctx = po.getCtx();
		if (po.get_Value("ReviewedBy") == null) {
			po.set_ValueOfColumn("ReviewedBy", Integer.valueOf(Env.getAD_User_ID(ctx)));
		}
		if (po.get_Value("ReviewedDate") == null) {
			Timestamp day = TimeUtil.getDay(System.currentTimeMillis());
			po.set_ValueOfColumn("ReviewedDate", day);
		}
		String st = po.get_ValueAsString("ReviewStatus");
		if (st == null || st.isEmpty() || "NW".equals(st) || "UR".equals(st)) {
			po.set_ValueOfColumn("ReviewStatus", "NF");
		}
		return null;
	}

	@Override
	public String docValidate(PO po, int timing) {
		return null;
	}
}
