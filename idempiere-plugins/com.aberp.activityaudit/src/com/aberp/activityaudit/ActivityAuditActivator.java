package com.aberp.activityaudit;

import org.compiere.model.ModelValidationEngine;

import com.aberp.activityaudit.model.ActivityAuditReviewValidator;

/**
 * Registers Reviewed stamping at OSGi start. Do not activate AD_ModelValidator for this
 * class — core Class.forName cannot see the plugin and breaks login ("Missing class … global").
 */
public class ActivityAuditActivator {

	private ActivityAuditReviewValidator validator;

	public void activate() {
		validator = new ActivityAuditReviewValidator();
		validator.initialize(ModelValidationEngine.get(), null);
	}

	public void deactivate() {
		if (validator != null) {
			ModelValidationEngine.get().removeModelChange("AbERP_ActivityAuditReview", validator);
			validator = null;
		}
	}
}
