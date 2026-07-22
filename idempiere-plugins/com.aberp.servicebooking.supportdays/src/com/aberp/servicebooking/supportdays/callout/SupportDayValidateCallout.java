package com.aberp.servicebooking.supportdays.callout;

import java.util.Properties;

import org.adempiere.base.IColumnCallout;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.util.DB;

/**
 * SAW031 — when Validated is toggled, re-apply numeric Support Start/End Day
 * from DB so weekday names never stick in the GridTab.
 * <p>
 * Deliberately does <b>not</b> reference {@code MOrderLineSupportDays} /
 * {@code MOrderLineAbERP} so this callout stays loadable even if the generator
 * model package is not exported to this bundle.
 */
public class SupportDayValidateCallout implements IColumnCallout {

	@Override
	public String start(Properties ctx, int WindowNo, GridTab mTab, GridField mField, Object value, Object oldValue) {
		int id = mTab.getRecord_ID();
		if (id <= 0) {
			return null;
		}
		String dbStart = DB.getSQLValueString(null,
				"SELECT aberp_support_start_day FROM c_orderline WHERE c_orderline_id=?", id);
		String dbEnd = DB.getSQLValueString(null,
				"SELECT aberp_support_end_day FROM c_orderline WHERE c_orderline_id=?", id);
		if (isNumericDay(dbStart)) {
			mTab.setValue("AbERP_Support_Start_Day", dbStart);
		}
		if (isNumericDay(dbEnd)) {
			mTab.setValue("AbERP_Support_End_Day", dbEnd);
		}
		return null;
	}

	private static boolean isNumericDay(String v) {
		if (v == null) {
			return false;
		}
		String s = v.trim();
		if (s.isEmpty()) {
			return false;
		}
		for (int i = 0; i < s.length(); i++) {
			if (!Character.isDigit(s.charAt(i))) {
				return false;
			}
		}
		return true;
	}
}
