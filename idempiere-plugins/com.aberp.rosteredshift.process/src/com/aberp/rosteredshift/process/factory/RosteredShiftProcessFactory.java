package com.aberp.rosteredshift.process.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.rosteredshift.process.AcceptShiftRequest;

public class RosteredShiftProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (AcceptShiftRequest.class.getName().equals(className)) {
			return new AcceptShiftRequest();
		}
		return null;
	}
}
