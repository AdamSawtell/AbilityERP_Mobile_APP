package com.aberp.compliance.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.compliance.RefreshCompliance;

public class ComplianceProcessFactory implements IProcessFactory {

	@Override
	public ProcessCall newProcessInstance(String className) {
		if (RefreshCompliance.class.getName().equals(className)) {
			return new RefreshCompliance();
		}
		return null;
	}
}
