package com.aberp.servicebooking.supportdays.factory;

import java.sql.ResultSet;

import org.adempiere.base.IModelFactory;
import org.compiere.model.PO;
import org.compiere.util.Env;

import com.aberp.servicebooking.supportdays.model.MOrderLineSupportDays;

/**
 * Prefer {@link MOrderLineSupportDays} over Flamingo {@code MOrderLineAbERP}
 * (generator ModelFactory ranking 10).
 */
public class SupportDaysModelFactory implements IModelFactory {

	@Override
	public Class<?> getClass(String tableName) {
		if ("C_OrderLine".equals(tableName)) {
			return MOrderLineSupportDays.class;
		}
		return null;
	}

	@Override
	public PO getPO(String tableName, int Record_ID, String trxName) {
		if ("C_OrderLine".equals(tableName)) {
			return new MOrderLineSupportDays(Env.getCtx(), Record_ID, trxName);
		}
		return null;
	}

	@Override
	public PO getPO(String tableName, ResultSet rs, String trxName) {
		if ("C_OrderLine".equals(tableName)) {
			return new MOrderLineSupportDays(Env.getCtx(), rs, trxName);
		}
		return null;
	}
}
