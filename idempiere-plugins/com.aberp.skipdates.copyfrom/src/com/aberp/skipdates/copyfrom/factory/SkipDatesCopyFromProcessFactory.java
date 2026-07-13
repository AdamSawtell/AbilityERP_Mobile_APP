package com.aberp.skipdates.copyfrom.factory;

import org.adempiere.base.IProcessFactory;
import org.compiere.process.ProcessCall;

import com.aberp.skipdates.copyfrom.CopyDatesFrom;

public class SkipDatesCopyFromProcessFactory implements IProcessFactory {
	@Override
	public ProcessCall newProcessInstance(String className) {
		if (CopyDatesFrom.class.getName().equals(className)) {
			return new CopyDatesFrom();
		}
		return null;
	}
}
