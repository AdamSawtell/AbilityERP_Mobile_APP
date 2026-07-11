package com.aberp.rostering.staffinfo.callout;

import java.util.Properties;

import org.adempiere.base.IColumnCallout;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.util.DB;
import org.compiere.util.Env;

/**
 * When Employee (User) contact is picked on ShiftStaff:
 * <ul>
 *   <li>Stamp {@code C_BPartner_Staff_ID} from {@code AD_User.C_BPartner_ID} immediately</li>
 *   <li>Copy {@code AD_Org_ID} from parent shift when the line is still on org {@code *}</li>
 * </ul>
 * Complements the SQL BP sync trigger (save-time safety net) and virtual BP ColumnSQL.
 */
public class CalloutShiftStaffContact implements IColumnCallout {

	@Override
	public String start(Properties ctx, int WindowNo, GridTab mTab, GridField mField, Object value, Object oldValue) {
		if (mTab == null) {
			return null;
		}

		if (value == null || (value instanceof Number && ((Number) value).intValue() <= 0)) {
			// Leave BP as-is when contact cleared (officer may still want staff BP history)
			ensureOrgFromParent(mTab);
			return null;
		}

		int userId = ((Number) value).intValue();
		int bpId = DB.getSQLValue(null, "SELECT C_BPartner_ID FROM AD_User WHERE AD_User_ID=?", userId);
		if (bpId > 0) {
			// UI field is virtual C_BPartner_ID (ColumnSQL from contact). Setting it
			// refreshes display immediately; physical c_bpartner_staff_id is stamped on save by trigger.
			mTab.setValue("C_BPartner_ID", Integer.valueOf(bpId));
			Env.setContext(ctx, WindowNo, "C_BPartner_ID", bpId);
		}

		ensureOrgFromParent(mTab);
		return null;
	}

	private void ensureOrgFromParent(GridTab mTab) {
		Object orgVal = mTab.getValue("AD_Org_ID");
		int orgId = orgVal instanceof Number ? ((Number) orgVal).intValue() : 0;
		if (orgId > 0) {
			return;
		}

		int shiftId = 0;
		Object shiftVal = mTab.getValue("AbERP_Rostered_Shift_ID");
		if (shiftVal instanceof Number) {
			shiftId = ((Number) shiftVal).intValue();
		} else if (mTab.getParentTab() != null) {
			Object parentShift = mTab.getParentTab().getValue("AbERP_Rostered_Shift_ID");
			if (parentShift instanceof Number) {
				shiftId = ((Number) parentShift).intValue();
			}
		}
		if (shiftId <= 0) {
			return;
		}

		int shiftOrg = DB.getSQLValue(null,
				"SELECT AD_Org_ID FROM AbERP_Rostered_Shift WHERE AbERP_Rostered_Shift_ID=?", shiftId);
		if (shiftOrg > 0) {
			mTab.setValue("AD_Org_ID", Integer.valueOf(shiftOrg));
		}
	}
}
