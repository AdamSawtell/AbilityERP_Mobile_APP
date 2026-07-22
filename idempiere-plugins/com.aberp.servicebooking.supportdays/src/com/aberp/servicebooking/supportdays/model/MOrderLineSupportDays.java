package com.aberp.servicebooking.supportdays.model;

import java.sql.ResultSet;
import java.util.Properties;
import java.util.logging.Level;

import com.aberp.servicebooking.generator.model.MOrderLineAbERP;

/**
 * SAW031 — undo Flamingo {@code MOrderLineAbERP.beforeSave} overwriting
 * {@code AbERP_Support_Start_Day}/{@code AbERP_Support_End_Day} with
 * {@code SimpleDateFormat("EEEE")} weekday names (Monday, Tuesday, …).
 * <p>
 * After SAW009 those columns are List <b>14 Day Roster Period</b> (values
 * {@code 1}..{@code 15}). Weekday text is not a valid list value, so Validate/Save
 * clears the fields in the WebUI and the save fails.
 * <p>
 * Also nulls any pre-existing weekday text so the SAW009 pattern-day trigger can
 * refill from {@code AbERP_ServicePattern} when linked.
 */
public class MOrderLineSupportDays extends MOrderLineAbERP {

	private static final long serialVersionUID = 2026072201L;

	public MOrderLineSupportDays(Properties ctx, int C_OrderLine_ID, String trxName) {
		super(ctx, C_OrderLine_ID, trxName);
	}

	public MOrderLineSupportDays(Properties ctx, ResultSet rs, String trxName) {
		super(ctx, rs, trxName);
	}

	@Override
	protected boolean beforeSave(boolean newRecord) {
		Object startDay = sanitizeDay(get_Value(COLUMNNAME_AbERP_Support_Start_Day));
		Object endDay = sanitizeDay(get_Value(COLUMNNAME_AbERP_Support_End_Day));

		if (!super.beforeSave(newRecord)) {
			return false;
		}

		// Flamingo beforeSave always rewrites these from StartDate/EndDate via EEEE
		// when both dates are set on an SO line. Restore the pre-super (sanitized) values.
		set_Value(COLUMNNAME_AbERP_Support_Start_Day, startDay);
		set_Value(COLUMNNAME_AbERP_Support_End_Day, endDay);
		if (log.isLoggable(Level.FINE)) {
			log.fine("SAW031: kept Support Start/End Day start=" + startDay + " end=" + endDay);
		}
		return true;
	}

	/** Null weekday names left from the old String column / EEEE overwrite. */
	private static Object sanitizeDay(Object v) {
		if (isWeekdayName(v)) {
			return null;
		}
		return v;
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
}
