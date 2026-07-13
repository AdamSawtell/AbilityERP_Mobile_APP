package com.aberp.bookinggenerator.bulk.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.bookinggenerator.bulk.BulkGenerateBookings;

public class BulkGenerateBookingsProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (BulkGenerateBookings.class.getName().equals(className)) {
			return new BulkGenerateBookings();
		}
		return null;
	}
}
