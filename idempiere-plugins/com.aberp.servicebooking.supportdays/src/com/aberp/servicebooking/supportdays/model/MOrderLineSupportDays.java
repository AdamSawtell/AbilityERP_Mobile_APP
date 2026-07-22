package com.aberp.servicebooking.supportdays.model;

import java.sql.ResultSet;
import java.util.Properties;
import java.util.logging.Level;

import org.compiere.util.CLogger;
import org.compiere.util.ValueNamePair;

import com.aberp.servicebooking.generator.model.MOrderLineAbERP;

/**
 * SAW031 — stop Support Start/End Day being overwritten with
 * {@code SimpleDateFormat("EEEE")} weekday names (Monday…Sunday).
 * <p>
 * After SAW009 those columns are List <b>14 Day Roster Period</b> (values
 * {@code 1}..{@code 15}). Weekday text is invalid, so Validate/Save clears the
 * fields in the WebUI and fails with {@code Invalid value - Thursday}.
 * <p>
 * Blank Support Start/End Day is allowed — Validate must not invent or require
 * a day value.
 */
public class MOrderLineSupportDays extends MOrderLineAbERP {

	private static final long serialVersionUID = 2026072205L;

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

		// Keep blank blank; restore numeric; never persist weekday text.
		set_ValueNoCheck(COLUMNNAME_AbERP_Support_Start_Day, startDay);
		set_ValueNoCheck(COLUMNNAME_AbERP_Support_End_Day, endDay);
		clearSupportDayListValidateError();
		if (log.isLoggable(Level.FINE)) {
			log.fine("SAW031: kept Support Start/End Day start=" + startDay + " end=" + endDay);
		}
		return true;
	}

	/**
	 * GridTab may hold a weekday-name ghost (UI shows blank). {@code PO.set_Value}
	 * then logs Validate/Invalid value before beforeSave. Swallow only that error so
	 * blank Support days can still Validate/Save.
	 */
	private void clearSupportDayListValidateError() {
		ValueNamePair err = CLogger.retrieveError();
		if (err == null) {
			return;
		}
		String combined = String.valueOf(err.getValue()) + " " + String.valueOf(err.getName());
		boolean supportDayInvalid = combined.contains("AbERP_Support_")
				&& combined.contains("Invalid value")
				&& (combined.contains("Monday") || combined.contains("Tuesday")
						|| combined.contains("Wednesday") || combined.contains("Thursday")
						|| combined.contains("Friday") || combined.contains("Saturday")
						|| combined.contains("Sunday"));
		if (!supportDayInvalid) {
			// Put back unrelated errors
			log.saveError(err.getValue(), err.getName());
		}
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
