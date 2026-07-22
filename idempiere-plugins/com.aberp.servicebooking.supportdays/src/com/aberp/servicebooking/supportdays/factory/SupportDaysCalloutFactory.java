package com.aberp.servicebooking.supportdays.factory;

import org.adempiere.base.IColumnCallout;
import org.adempiere.base.IColumnCalloutFactory;

import com.aberp.servicebooking.supportdays.callout.SupportDayValidateCallout;

/** SAW031 — clear weekday ghosts / restore numeric Support days on Validate. */
public class SupportDaysCalloutFactory implements IColumnCalloutFactory {

	@Override
	public IColumnCallout[] getColumnCallouts(String tableName, String columnName) {
		if (!"C_OrderLine".equalsIgnoreCase(tableName)) {
			return null;
		}
		if ("AbERP_IsValidated".equalsIgnoreCase(columnName)
				|| "AbERP_Support_Start_Day".equalsIgnoreCase(columnName)
				|| "AbERP_Support_End_Day".equalsIgnoreCase(columnName)) {
			return new IColumnCallout[] { new SupportDayValidateCallout() };
		}
		return null;
	}
}
