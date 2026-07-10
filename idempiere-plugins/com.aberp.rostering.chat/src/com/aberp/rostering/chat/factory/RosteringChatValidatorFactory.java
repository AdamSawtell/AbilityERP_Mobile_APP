package com.aberp.rostering.chat.factory;

import org.adempiere.base.IModelValidatorFactory;
import org.compiere.model.ModelValidator;

import com.aberp.rostering.chat.model.RosteringChatValidator;

/**
 * OSGi registration for RosteringChatValidator.
 * AD_ModelValidator class loading cannot see plugin classes — use this factory instead.
 */
public class RosteringChatValidatorFactory implements IModelValidatorFactory {

	@Override
	public ModelValidator newModelValidatorInstance(String className) {
		if (RosteringChatValidator.class.getName().equals(className)) {
			return new RosteringChatValidator();
		}
		return null;
	}
}
