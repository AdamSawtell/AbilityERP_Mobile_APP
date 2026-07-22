package com.aberp.servicebooking.supportdays.model;

import java.sql.ResultSet;
import java.util.Properties;
import java.util.logging.Level;

import com.aberp.servicebooking.generator.model.MOrderLineAbERP;

/**
 * SAW031 — stop Support Start/End Day being overwritten with
 * {@code SimpleDateFormat("EEEE")} weekday names (Monday…Sunday).
 * <p>
 * After SAW009 those columns are List <b>14 Day Roster Period</b> (values
 * {@code 1}..{@code 15}). Weekday text is invalid, so Validate/Save clears the
 * fields in the WebUI and fails with {@code Invalid value - Thursday}.
 */
public class MOrderLineSupportDays extends MOrderLineAbERP {

	private static final long serialVersionUID = 2026072202L;

	public MOrderLineSupportDays(Properties ctx, int C_OrderLine_ID, String trxName) {
		super(ctx, C_OrderLine_ID, trxName);
	}

	public MOrderLineSupportDays(Properties ctx, ResultSet rs, String trxName) {
		super(ctx, rs, trxName);
	}

	@Override
	public void setAbERPSupportStartDay(String day) {
		if (isWeekdayName(day)) {
			return;
		}
		super.setAbERPSupportStartDay(day);
	}

	@Override
	public void setAbERPSupportEndDay(String day) {
		if (isWeekdayName(day)) {
			return;
		}
		super.setAbERPSupportEndDay(day);
	}

	@Override
	protected boolean beforeSave(boolean newRecord) {
		Object startDay = sanitizeDay(get_Value(COLUMNNAME_AbERP_Support_Start_Day));
		Object endDay = sanitizeDay(get_Value(COLUMNNAME_AbERP_Support_End_Day));

		super.beforeSave(newRecord);

		// Restore even if super logged Invalid value while setting EEEE names.
		set_ValueNoCheck(COLUMNNAME_AbERP_Support_Start_Day, startDay);
		set_ValueNoCheck(COLUMNNAME_AbERP_Support_End_Day, endDay);
		if (log.isLoggable(Level.FINE)) {
			log.fine("SAW031: kept Support Start/End Day start=" + startDay + " end=" + endDay);
		}
		return true;
	}

	private static Object sanitizeDay(Object v) {
		if (isWeekdayName(v)) {
			return null;
		}
		return v;
	}

	public static boolean isWeekdayName(Object v) {
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
}
