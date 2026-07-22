package com.aberp.servicebooking.supportdays.callout;

import java.util.Properties;

import org.adempiere.base.IColumnCallout;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.util.DB;

/**
 * SAW031 — when Validated is toggled:
 * <ul>
 *   <li>clear weekday-name ghosts from Support Start/End Day (invalid List values
 *       that show blank but still block Save)</li>
 *   <li>re-apply numeric days from DB when present</li>
 *   <li>leave blank when blank — Validate must not require Support days</li>
 * </ul>
 */
public class SupportDayValidateCallout implements IColumnCallout {

	@Override
	public String start(Properties ctx, int WindowNo, GridTab mTab, GridField mField, Object value, Object oldValue) {
		clearWeekdayGhost(mTab, "AbERP_Support_Start_Day");
		clearWeekdayGhost(mTab, "AbERP_Support_End_Day");

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

	private static void clearWeekdayGhost(GridTab mTab, String column) {
		Object cur = mTab.getValue(column);
		if (isWeekdayName(cur)) {
			mTab.setValue(column, null);
		}
	}

	private static boolean isWeekdayName(Object v) {
		if (!(v instanceof String)) {
			return false;
		}
		String s = ((String) v).trim();
		return "Monday".equalsIgnoreCase(s)
				|| "Tuesday".equalsIgnoreCase(s)
				|| "Wednesday".equalsIgnoreCase(s)
				|| "Thursday".equalsIgnoreCase(s)
				|| "Friday".equalsIgnoreCase(s)
				|| "Saturday".equalsIgnoreCase(s)
				|| "Sunday".equalsIgnoreCase(s);
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
