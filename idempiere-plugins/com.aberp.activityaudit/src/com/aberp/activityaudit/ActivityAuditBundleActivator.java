package com.aberp.activityaudit;

import org.compiere.model.ModelValidationEngine;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

import com.aberp.activityaudit.model.ActivityAuditReviewValidator;

/**
 * Registers Reviewed stamping when the bundle starts.
 * Do not activate AD_ModelValidator for plugin classes (login "Missing class … global").
 */
public class ActivityAuditBundleActivator implements BundleActivator {

	private ActivityAuditReviewValidator validator;

	@Override
	public void start(BundleContext context) throws Exception {
		validator = new ActivityAuditReviewValidator();
		validator.initialize(ModelValidationEngine.get(), null);
	}

	@Override
	public void stop(BundleContext context) throws Exception {
		if (validator != null) {
			ModelValidationEngine.get().removeModelChange("AbERP_ActivityAuditReview", validator);
			validator = null;
		}
	}
}
