package com.aberp.rostering.staffinfo.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.rostering.staffinfo.process.ResponseLogFindFill;

public class StaffRosteringProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (ResponseLogFindFill.class.getName().equals(className)) {
			return new ResponseLogFindFill();
		}
		return null;
	}
}
