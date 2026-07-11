package com.aberp.rostering.staffinfo.factory;

import org.adempiere.base.IColumnCallout;
import org.adempiere.base.IColumnCalloutFactory;

import com.aberp.rostering.staffinfo.callout.CalloutShiftStaffContact;

/**
 * Registers {@link CalloutShiftStaffContact} for ShiftStaff contact field.
 */
public class StaffRosteringCalloutFactory implements IColumnCalloutFactory {

	private static final String TABLE = "AbERP_Rostered_ShiftStaff";
	private static final String COLUMN = "AbERP_User_Contact_ID";

	@Override
	public IColumnCallout[] getColumnCallouts(String tableName, String columnName) {
		if (TABLE.equalsIgnoreCase(tableName) && COLUMN.equalsIgnoreCase(columnName)) {
			return new IColumnCallout[] { new CalloutShiftStaffContact() };
		}
		return null;
	}
}
