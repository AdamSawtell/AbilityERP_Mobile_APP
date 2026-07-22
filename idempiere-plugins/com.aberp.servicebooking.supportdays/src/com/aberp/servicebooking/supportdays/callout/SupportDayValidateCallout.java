package com.aberp.servicebooking.supportdays.callout;

import java.util.Properties;

import org.adempiere.base.IColumnCallout;
import org.compiere.model.GridField;
import org.compiere.model.GridTab;
import org.compiere.util.DB;

import com.aberp.servicebooking.supportdays.model.MOrderLineSupportDays;

/**
 * SAW031 — when Validated is toggled, WebUI may receive weekday names for
 * Support Start/End Day (invalid List values). Re-apply numeric days from DB.
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
		if (!MOrderLineSupportDays.isWeekdayName(dbStart) && dbStart != null && !dbStart.trim().isEmpty()) {
			mTab.setValue("AbERP_Support_Start_Day", dbStart);
		}
		if (!MOrderLineSupportDays.isWeekdayName(dbEnd) && dbEnd != null && !dbEnd.trim().isEmpty()) {
			mTab.setValue("AbERP_Support_End_Day", dbEnd);
		}
		return null;
	}
}
