package com.aberp.servicebooking.supportdays.factory;

import org.adempiere.base.IColumnCallout;
import org.adempiere.base.IColumnCalloutFactory;

import com.aberp.servicebooking.supportdays.callout.SupportDayValidateCallout;

/** SAW031 — bind restore-days callout on C_OrderLine.AbERP_IsValidated. */
public class SupportDaysCalloutFactory implements IColumnCalloutFactory {

	@Override
	public IColumnCallout[] getColumnCallouts(String tableName, String columnName) {
		if ("C_OrderLine".equalsIgnoreCase(tableName) && "AbERP_IsValidated".equalsIgnoreCase(columnName)) {
			return new IColumnCallout[] { new SupportDayValidateCallout() };
		}
		return null;
	}
}
